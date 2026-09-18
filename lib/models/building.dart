enum BuildingStatus { locked, buildable, building, upgrading, idle, active }

extension BuildingStatusInfo on BuildingStatus {
  /// Whether the building is standing and can host a gig, i.e. not
  /// locked, not merely buildable, and not mid-construction.
  bool get isOperational =>
      this == BuildingStatus.idle ||
      this == BuildingStatus.active ||
      this == BuildingStatus.upgrading;
}

/// A studio building definition (design doc §4.3 "Buildings").
///
/// [BuildingDef] is static registry data; per-save mutable state (status,
/// progress, upgrade level) lives in [BuildingState].
class BuildingDef {
  final String id;
  final String name;
  final int unlockLevel;
  final int buildCost;
  final Duration buildTime;
  final int maxUpgradeLevel;

  const BuildingDef({
    required this.id,
    required this.name,
    required this.unlockLevel,
    required this.buildCost,
    required this.buildTime,
    this.maxUpgradeLevel = 3,
  });
}

class BuildingState {
  final BuildingDef def;
  final BuildingStatus status;
  final int upgradeLevel;

  /// When [status] is `building`/`upgrading`, the wall-clock time the
  /// current job finishes; otherwise null.
  final DateTime? jobEndsAt;

  const BuildingState({
    required this.def,
    this.status = BuildingStatus.locked,
    this.upgradeLevel = 0,
    this.jobEndsAt,
  });

  BuildingState copyWith({
    BuildingStatus? status,
    int? upgradeLevel,
    DateTime? jobEndsAt,
    bool clearJob = false,
  }) {
    return BuildingState(
      def: def,
      status: status ?? this.status,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      jobEndsAt: clearJob ? null : (jobEndsAt ?? this.jobEndsAt),
    );
  }
}
