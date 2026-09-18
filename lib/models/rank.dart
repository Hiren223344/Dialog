/// The producer fame ladder (design doc §4.3 "Progression / Rank").
///
/// Rank is derived from level, not stored independently, so it can never
/// drift out of sync with XP.
enum Rank {
  newcomer,
  workingProducer,
  director,
  executive,
  topProducer,
}

extension RankInfo on Rank {
  String get title {
    switch (this) {
      case Rank.newcomer:
        return 'Newcomer';
      case Rank.workingProducer:
        return 'Working Producer';
      case Rank.director:
        return 'Director';
      case Rank.executive:
        return 'Executive';
      case Rank.topProducer:
        return 'Top Producer';
    }
  }

  /// The minimum level required to hold this rank.
  int get minLevel {
    switch (this) {
      case Rank.newcomer:
        return 1;
      case Rank.workingProducer:
        return 5;
      case Rank.director:
        return 10;
      case Rank.executive:
        return 15;
      case Rank.topProducer:
        return 20;
    }
  }

  static Rank forLevel(int level) {
    Rank result = Rank.newcomer;
    for (final rank in Rank.values) {
      if (level >= rank.minLevel) {
        result = rank;
      }
    }
    return result;
  }

  Rank? get next {
    final index = Rank.values.indexOf(this);
    if (index + 1 >= Rank.values.length) return null;
    return Rank.values[index + 1];
  }
}
