/// A creative-writing gig definition (design doc §4.3 "Gigs").
class GigDef {
  final String id;
  final String name;
  final String type;
  final int charLimit;
  final int likeTarget;
  final Duration timer;
  final int cost;
  final int requiredLevel;
  final String? requiredBuildingId;
  final int rewardBoxOffice;
  final int rewardFans;
  final int rewardXp;

  const GigDef({
    required this.id,
    required this.name,
    required this.type,
    required this.charLimit,
    required this.likeTarget,
    required this.timer,
    required this.cost,
    required this.requiredLevel,
    this.requiredBuildingId,
    required this.rewardBoxOffice,
    required this.rewardFans,
    required this.rewardXp,
  });
}

/// The outcome of a completed gig, before rewards are applied.
class GigResult {
  final GigDef def;
  final String text;
  final int likes;
  final double qualityMultiplier;

  const GigResult({
    required this.def,
    required this.text,
    required this.likes,
    required this.qualityMultiplier,
  });

  int get rewardBoxOffice => (def.rewardBoxOffice * qualityMultiplier).round();
  int get rewardFans => (def.rewardFans * qualityMultiplier).round();
  int get rewardXp => (def.rewardXp * qualityMultiplier).round();

  bool get wentViral => likes >= def.likeTarget;
}

/// Scores likes into the 0.7x-3x quality multiplier described in the
/// design doc (§4.3 "Gigs").
double qualityMultiplierForLikes(int likes, int likeTarget) {
  if (likeTarget <= 0) return 0.7;
  final ratio = likes / likeTarget;
  final multiplier = 0.7 + 2.3 * ratio;
  return multiplier.clamp(0.7, 3.0);
}
