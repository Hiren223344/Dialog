import 'dart:async';
import 'dart:math';

import '../data/game_registry.dart';
import '../models/active_gig_session.dart';
import '../models/building.dart';
import '../models/gig.dart';
import '../models/resources.dart';
import '../models/staff.dart';
import 'game_events.dart';

/// Owns the economy, buildings, and gig loop (design doc §4). Deliberately
/// UI-agnostic: it mutates state and reports [GameEvent]s through
/// [onEvent], but never touches screen coordinates or overlays -- that
/// wiring belongs to the widget layer that can see [BuildContext].
///
/// This scaffold simulates the gig's incoming likes locally as a stand-in
/// for the real social feed described in the design doc's Tier 3 ("real
/// social likes + leaderboards"), which requires a server and moderation
/// this repo does not yet have.
class GameState {
  GameResources resources = const GameResources();
  final Map<String, BuildingState> buildings = {};
  final List<StaffMember> staff = [];
  ActiveGigSession? activeGig;

  void Function(GameEvent event)? onEvent;
  void Function()? onChanged;

  Timer? _ticker;
  final Random _random = Random();
  int _nextStaffId = 0;

  /// Real-time salary tick, compressed to 60s like the gig timers are
  /// (a real "per hour" cadence would make hiring untestable in a demo).
  static const _salaryInterval = Duration(seconds: 60);
  DateTime _lastSalaryTick = DateTime.now();

  GameState() {
    for (final def in GameRegistry.buildings) {
      final status = def.buildCost == 0
          ? BuildingStatus.idle
          : (def.unlockLevel <= resources.level
              ? BuildingStatus.buildable
              : BuildingStatus.locked);
      buildings[def.id] = BuildingState(def: def, status: status);
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void dispose() {
    _ticker?.cancel();
  }

  void _emit(GameEvent event) => onEvent?.call(event);
  void _notify() => onChanged?.call();

  bool isGigUnlocked(GigDef def) {
    if (resources.level < def.requiredLevel) return false;
    final requiredBuilding = def.requiredBuildingId;
    if (requiredBuilding == null) return true;
    return buildings[requiredBuilding]?.status.isOperational ?? false;
  }

  bool canStartGig(GigDef def) =>
      activeGig == null && isGigUnlocked(def) && resources.boxOffice >= def.cost;

  /// Posts the player's writing for [def], which starts the gig's timer
  /// and (simulated) likes immediately -- the design doc's "write →
  /// post → likes arrive" loop.
  void startGig(GigDef def, String text) {
    if (!canStartGig(def)) return;
    resources = resources.copyWith(boxOffice: resources.boxOffice - def.cost);
    final now = DateTime.now();
    activeGig = ActiveGigSession(
      def: def,
      text: text,
      startedAt: now,
      endsAt: now.add(def.timer),
    );
    _notify();
  }

  bool canAffordBuild(BuildingDef def) => resources.boxOffice >= def.buildCost;

  void startBuild(String buildingId) {
    final state = buildings[buildingId];
    if (state == null || state.status != BuildingStatus.buildable) return;
    if (!canAffordBuild(state.def)) return;
    resources = resources.copyWith(boxOffice: resources.boxOffice - state.def.buildCost);
    buildings[buildingId] = state.copyWith(
      status: BuildingStatus.building,
      jobEndsAt: DateTime.now().add(state.def.buildTime),
    );
    _emit(BuildingStartedEvent(state.def));
    _notify();
  }

  int hiredCountAt(String buildingId) => staff.where((s) => s.buildingId == buildingId).length;

  bool canHireStaff(String buildingId, StaffTier tier) {
    final state = buildings[buildingId];
    if (state == null || !state.status.isOperational) return false;
    if (hiredCountAt(buildingId) >= state.def.staffSlots) return false;
    return resources.boxOffice >= tier.hireCost;
  }

  void hireStaff(String buildingId, StaffTier tier) {
    if (!canHireStaff(buildingId, tier)) return;
    resources = resources.copyWith(boxOffice: resources.boxOffice - tier.hireCost);
    staff.add(StaffMember(
      id: 'staff_${_nextStaffId++}',
      tier: tier,
      buildingId: buildingId,
      hiredAt: DateTime.now(),
    ));
    _emit(StaffHiredEvent(buildingId: buildingId, tier: tier));
    _notify();
  }

  void fireStaff(String staffId) {
    final countBefore = staff.length;
    staff.removeWhere((s) => s.id == staffId);
    if (staff.length != countBefore) _notify();
  }

  /// Escalating with upgrade level, and with a flat floor added before
  /// scaling -- buildCost alone degenerates to a permanently free
  /// upgrade for Producer's Office, whose buildCost is 0.
  int upgradeCost(BuildingState state) => (state.def.buildCost + 150) * (state.upgradeLevel + 1);

  bool canUpgrade(String buildingId) {
    final state = buildings[buildingId];
    if (state == null) return false;
    if (!state.status.isOperational) return false;
    if (state.upgradeLevel >= state.def.maxUpgradeLevel) return false;
    return resources.boxOffice >= upgradeCost(state);
  }

  void upgradeBuilding(String buildingId) {
    final state = buildings[buildingId];
    if (state == null || !canUpgrade(buildingId)) return;
    resources = resources.copyWith(boxOffice: resources.boxOffice - upgradeCost(state));
    buildings[buildingId] = state.copyWith(
      status: BuildingStatus.upgrading,
      jobEndsAt: DateTime.now().add(state.def.buildTime),
    );
    _notify();
  }

  void _tick() {
    var changed = false;

    final gig = activeGig;
    if (gig != null) {
      _advanceLikes(gig);
      if (gig.isDone) {
        _resolveGig(gig);
      }
      changed = true;
    }

    final now = DateTime.now();
    for (final entry in buildings.entries.toList()) {
      final state = entry.value;
      if (state.jobEndsAt == null || now.isBefore(state.jobEndsAt!)) continue;

      if (state.status == BuildingStatus.building) {
        buildings[entry.key] = state.copyWith(status: BuildingStatus.idle, clearJob: true);
        _emit(BuildingCompletedEvent(state.def));
        changed = true;
      } else if (state.status == BuildingStatus.upgrading) {
        final newLevel = state.upgradeLevel + 1;
        buildings[entry.key] =
            state.copyWith(status: BuildingStatus.idle, upgradeLevel: newLevel, clearJob: true);
        _emit(BuildingUpgradedEvent(def: state.def, newLevel: newLevel));
        changed = true;
      }
    }

    if (staff.isNotEmpty && now.difference(_lastSalaryTick) >= _salaryInterval) {
      _lastSalaryTick = now;
      final totalSalary = staff.fold<int>(0, (sum, member) => sum + member.tier.hourlyCost);
      if (totalSalary > 0) {
        resources = resources.copyWith(
          boxOffice: max(0, resources.boxOffice - totalSalary),
        );
        changed = true;
      }
    }

    if (changed) _notify();
  }

  /// Staff efficiency and building upgrades stack additively into a
  /// bonus applied on top of the likes-driven quality multiplier
  /// (design doc improvement notes: staff should be "a decision, not
  /// just a slider" and buildings should have visible payoff beyond
  /// looking bigger). Gigs with no required building (e.g. Tagline) get
  /// no bonus, same as before this system existed.
  double _productionBonusFor(String? buildingId) {
    if (buildingId == null) return 0;
    final state = buildings[buildingId];
    var bonus = state == null ? 0.0 : state.upgradeLevel * 0.15;
    for (final member in staff.where((s) => s.buildingId == buildingId)) {
      bonus += member.tier.efficiencyBonus;
    }
    return bonus;
  }

  void _advanceLikes(ActiveGigSession gig) {
    final target = gig.def.likeTarget;
    final expectedByNow = (target * gig.progress * 1.3).round();
    if (gig.likes < expectedByNow) {
      final step = 1 + _random.nextInt(3);
      gig.likes = min(gig.likes + step, expectedByNow);
      _emit(LikeArrivedEvent(gig.likes));
    }
    if (!gig.wentViral && gig.likes >= target) {
      gig.wentViral = true;
      _emit(const GigWentViralEvent());
    }
  }

  void _resolveGig(ActiveGigSession gig) {
    final qualityMultiplier = qualityMultiplierForLikes(gig.likes, gig.def.likeTarget);
    final productionBonus = _productionBonusFor(gig.def.requiredBuildingId);
    final result = GigResult(
      def: gig.def,
      text: gig.text,
      likes: gig.likes,
      qualityMultiplier: qualityMultiplier * (1 + productionBonus),
    );

    final beforeRank = resources.rank;
    final applied = resources.applyReward(
      boxOffice: result.rewardBoxOffice,
      fans: result.rewardFans,
      xp: result.rewardXp,
    );
    resources = applied.resources;
    activeGig = null;
    _refreshBuildingUnlocks();

    _emit(GigCompletedEvent(result));

    if (applied.levelsGained > 0) {
      final afterRank = resources.rank;
      _emit(LevelUpEvent(
        newLevel: resources.level,
        newRank: afterRank,
        rankChanged: afterRank != beforeRank,
      ));
    }
  }

  void _refreshBuildingUnlocks() {
    for (final entry in buildings.entries.toList()) {
      final state = entry.value;
      if (state.status == BuildingStatus.locked && state.def.unlockLevel <= resources.level) {
        buildings[entry.key] = state.copyWith(status: BuildingStatus.buildable);
      }
    }
  }
}
