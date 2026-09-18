import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../data/game_registry.dart';
import '../models/active_gig_session.dart';
import '../models/building.dart';
import '../models/gig.dart';
import '../models/rank.dart';
import '../services/studio_sfx.dart';
import '../services/unity_bridge.dart';
import '../state/game_events.dart';
import '../state/game_state.dart';
import '../theme/studio_theme.dart';
import '../widgets/building_detail_sheet.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/flying_reward.dart';
import '../widgets/gig_board_sheet.dart';
import '../widgets/gig_writer_sheet.dart';
import '../widgets/hud_bar.dart';
import '../widgets/juice_overlay_host.dart';
import '../widgets/rolling_counter.dart';
import '../widgets/studio_lot_scene.dart';
import '../widgets/unity_studio_view.dart';

/// The Studio tab (design doc §4): buildings you can tap into overlay
/// panels, a gig contract board, and the persistent HUD, all wired to the
/// Tier 1 juice effects (§6) on every meaningful action.
class StudioHomeScreen extends StatefulWidget {
  const StudioHomeScreen({super.key});

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> {
  late final GameState _game;

  final _boxOfficeKey = GlobalKey();
  final _fansKey = GlobalKey();
  final _reputationKey = GlobalKey();
  final _xpKey = GlobalKey();
  final _activeGigBannerKey = GlobalKey();

  // Only allocated when the (untested, opt-in) Unity path is enabled --
  // see lib/config/feature_flags.dart.
  final UnityBridge? _unityBridge = kUnity3DStudioEnabled ? UnityBridge() : null;

  @override
  void initState() {
    super.initState();
    _game = GameState();
    _game.onChanged = _onGameChanged;
    _game.onEvent = _handleGameEvent;
  }

  void _onGameChanged() {
    setState(() {});
    if (_unityBridge != null && _unityBridge.isReady) {
      _unityBridge.syncBuildings({
        for (final entry in _game.buildings.entries) entry.key: entry.value.status.name,
      });
    }
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  Offset _effectOrigin(BuildContext context) {
    return globalCenterOf(_activeGigBannerKey) ??
        Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );
  }

  void _handleGameEvent(GameEvent event) {
    if (!mounted) return;
    final juice = JuiceOverlayHost.of(context);

    switch (event) {
      case LikeArrivedEvent():
        juice.spawnFloatingHeart(_effectOrigin(context));
      case GigWentViralEvent():
        juice.viralBurst();
      case GigCompletedEvent(result: final result):
        final origin = _effectOrigin(context);
        _flyRewardIfPositive(juice, origin, _boxOfficeKey, RewardKind.boxOffice, result.rewardBoxOffice);
        _flyRewardIfPositive(juice, origin, _fansKey, RewardKind.fans, result.rewardFans);
        _flyRewardIfPositive(juice, origin, _xpKey, RewardKind.xp, result.rewardXp);
      case BuildingStartedEvent():
        StudioSfx.play(SfxCue.tap);
      case BuildingCompletedEvent(def: final def):
        juice.celebrate(CelebrationData(
          kind: CelebrationKind.buildingComplete,
          title: '${def.name} complete!',
          subtitle: 'Your studio just got bigger.',
        ));
      case StaffHiredEvent():
        StudioSfx.play(SfxCue.coinDrop);
      case BuildingUpgradedEvent(def: final def, newLevel: final newLevel):
        juice.celebrate(CelebrationData(
          kind: CelebrationKind.buildingComplete,
          title: '${def.name} upgraded!',
          subtitle: 'Now level $newLevel.',
        ));
      case LevelUpEvent(newLevel: final level, newRank: final rank, rankChanged: final rankChanged):
        juice.celebrate(CelebrationData(
          kind: CelebrationKind.levelUp,
          title: 'Level $level!',
          subtitle: rankChanged
              ? 'You are now a ${rank.title}!'
              : 'Keep climbing toward ${rank.next?.title ?? 'the top'}.',
        ));
    }
  }

  void _flyRewardIfPositive(
    JuiceController juice,
    Offset from,
    GlobalKey targetKey,
    RewardKind kind,
    int amount,
  ) {
    if (amount <= 0) return;
    final to = globalCenterOf(targetKey) ?? from;
    juice.flyReward(from: from, to: to, kind: kind, amount: amount);
  }

  void _openGigBoard() {
    StudioSfx.play(SfxCue.tap);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GigBoardSheet(
        gigs: GameRegistry.gigs,
        isUnlocked: _game.isGigUnlocked,
        canAfford: (def) => _game.resources.boxOffice >= def.cost,
        gigInProgress: _game.activeGig != null,
        onSelect: _openGigWriter,
      ),
    );
  }

  void _openGigWriter(GigDef def) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GigWriterSheet(
        def: def,
        onPost: (text) => _game.startGig(def, text),
      ),
    );
  }

  void _onBuildingTap(String buildingId) {
    final state = _game.buildings[buildingId]!;
    if (state.status == BuildingStatus.buildable) {
      StudioSfx.play(SfxCue.tap);
      _game.startBuild(buildingId);
    } else if (state.status.isOperational) {
      _openBuildingDetail(buildingId);
    }
  }

  void _openBuildingDetail(String buildingId) {
    StudioSfx.play(SfxCue.tap);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuildingDetailSheet(game: _game, buildingId: buildingId),
    );
  }

  /// Mirrors unity/Assets/Scripts/FlutterBridge.cs's event shapes --
  /// "interacted" reuses the same start-build/open-detail path a 2D tap
  /// would, and "menuAction" opens the same overlays the 2D lot's
  /// FAB/building tap do.
  void _handleUnityEvent(UnityBridgeEvent event) {
    switch (event) {
      case UnityBuildingInteractedEvent(buildingId: final id):
        _onBuildingTap(id);
      case UnityMenuActionEvent(action: 'gigs'):
        _openGigBoard();
      case UnityMenuActionEvent(action: 'hire' || 'shop', buildingId: final id):
        _openBuildingDetail(id);
      case UnityMenuActionEvent():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = _game.resources;
    final activeGig = _game.activeGig;

    return Scaffold(
      body: Column(
        children: [
          HudBar(
            resources: resources,
            boxOfficeKey: _boxOfficeKey,
            fansKey: _fansKey,
            reputationKey: _reputationKey,
            xpKey: _xpKey,
          ),
          Expanded(
            child: Container(
              color: StudioColors.background,
              child: Column(
                children: [
                  if (activeGig != null) _activeGigBanner(activeGig),
                  Expanded(
                    child: kUnity3DStudioEnabled
                        ? UnityStudioView(bridge: _unityBridge!, onEvent: _handleUnityEvent)
                        : Center(
                            child: StudioLotScene(
                              buildings: _game.buildings,
                              inProductionBuildingId: activeGig?.def.requiredBuildingId,
                              onTapBuilding: _onBuildingTap,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGigBoard,
        backgroundColor: StudioColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.edit_note),
        label: const Text('Gigs'),
      ),
    );
  }

  Widget _activeGigBanner(ActiveGigSession gig) {
    return Container(
      key: _activeGigBannerKey,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioColors.teal.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: StudioColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${gig.text}" is live',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: StudioColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.favorite, color: StudioColors.coral, size: 16),
              const SizedBox(width: 4),
              RollingCounter(
                value: gig.likes,
                style: const TextStyle(color: StudioColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              Text(' / ${gig.def.likeTarget}', style: const TextStyle(color: StudioColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: gig.progress,
              minHeight: 6,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation(StudioColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}
