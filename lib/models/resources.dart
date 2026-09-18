import 'dart:math';

import 'rank.dart';

/// XP required to advance from [level] to [level] + 1 (design doc §4.3:
/// `100 * level^1.8`).
int xpToNextLevel(int level) => (100 * pow(level, 1.8)).round();

/// The four core resources tracked by the economy (design doc §4.3).
class GameResources {
  final int boxOffice;
  final int fans;
  final int reputation;
  final int xp;
  final int level;

  const GameResources({
    this.boxOffice = 0,
    this.fans = 0,
    this.reputation = 0,
    this.xp = 0,
    this.level = 1,
  });

  Rank get rank => RankInfo.forLevel(level);

  int get xpForCurrentLevel => xpToNextLevel(level);

  double get levelProgress =>
      (xp / xpForCurrentLevel).clamp(0, 1).toDouble();

  GameResources copyWith({
    int? boxOffice,
    int? fans,
    int? reputation,
    int? xp,
    int? level,
  }) {
    return GameResources(
      boxOffice: boxOffice ?? this.boxOffice,
      fans: fans ?? this.fans,
      reputation: reputation ?? this.reputation,
      xp: xp ?? this.xp,
      level: level ?? this.level,
    );
  }

  /// Applies a reward, rolling XP overflow into level-ups. Returns the
  /// resulting resources plus how many levels were gained, so the caller
  /// can decide whether to trigger a celebration.
  ({GameResources resources, int levelsGained}) applyReward({
    int boxOffice = 0,
    int fans = 0,
    int reputation = 0,
    int xp = 0,
  }) {
    int newLevel = level;
    int remainingXp = this.xp + xp;
    int levelsGained = 0;

    while (remainingXp >= xpToNextLevel(newLevel)) {
      remainingXp -= xpToNextLevel(newLevel);
      newLevel += 1;
      levelsGained += 1;
    }

    final resources = copyWith(
      boxOffice: this.boxOffice + boxOffice,
      fans: this.fans + fans,
      reputation: this.reputation + reputation,
      xp: remainingXp,
      level: newLevel,
    );
    return (resources: resources, levelsGained: levelsGained);
  }
}
