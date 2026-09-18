import '../models/building.dart';
import '../models/gig.dart';
import '../models/rank.dart';
import '../models/staff.dart';

/// Notable things [GameState] does that deserve a visible reaction. The
/// state layer stays UI-agnostic: it reports *what* happened, and the
/// screen decides *how* to show it (screen coordinates, HUD targets,
/// overlay wiring all live in the widget layer).
sealed class GameEvent {
  const GameEvent();
}

class LikeArrivedEvent extends GameEvent {
  final int totalLikes;
  const LikeArrivedEvent(this.totalLikes);
}

class GigWentViralEvent extends GameEvent {
  const GigWentViralEvent();
}

class GigCompletedEvent extends GameEvent {
  final GigResult result;
  const GigCompletedEvent(this.result);
}

class BuildingStartedEvent extends GameEvent {
  final BuildingDef def;
  const BuildingStartedEvent(this.def);
}

class BuildingCompletedEvent extends GameEvent {
  final BuildingDef def;
  const BuildingCompletedEvent(this.def);
}

class LevelUpEvent extends GameEvent {
  final int newLevel;
  final Rank newRank;
  final bool rankChanged;
  const LevelUpEvent({required this.newLevel, required this.newRank, required this.rankChanged});
}

class StaffHiredEvent extends GameEvent {
  final String buildingId;
  final StaffTier tier;
  const StaffHiredEvent({required this.buildingId, required this.tier});
}

class BuildingUpgradedEvent extends GameEvent {
  final BuildingDef def;
  final int newLevel;
  const BuildingUpgradedEvent({required this.def, required this.newLevel});
}
