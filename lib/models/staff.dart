/// Staff tiers (design doc §4.3 "Staff"): each trades salary for an
/// efficiency multiplier, hired per building, draining ₹ over time.
enum StaffTier { intern, junior, senior, expert }

extension StaffTierInfo on StaffTier {
  String get title {
    switch (this) {
      case StaffTier.intern:
        return 'Intern';
      case StaffTier.junior:
        return 'Junior';
      case StaffTier.senior:
        return 'Senior';
      case StaffTier.expert:
        return 'Expert';
    }
  }

  int get hireCost {
    switch (this) {
      case StaffTier.intern:
        return 100;
      case StaffTier.junior:
        return 300;
      case StaffTier.senior:
        return 800;
      case StaffTier.expert:
        return 2000;
    }
  }

  int get hourlyCost {
    switch (this) {
      case StaffTier.intern:
        return 10;
      case StaffTier.junior:
        return 30;
      case StaffTier.senior:
        return 70;
      case StaffTier.expert:
        return 150;
    }
  }

  /// Added (not multiplied) into a gig's reward multiplier for every
  /// staff member assigned to the building that ran it -- so hiring is
  /// a real production decision, not just a flat slider (design doc
  /// improvement notes on "Staff").
  double get efficiencyBonus {
    switch (this) {
      case StaffTier.intern:
        return 0.08;
      case StaffTier.junior:
        return 0.18;
      case StaffTier.senior:
        return 0.32;
      case StaffTier.expert:
        return 0.50;
    }
  }
}

class StaffMember {
  final String id;
  final StaffTier tier;
  final String buildingId;
  final DateTime hiredAt;

  const StaffMember({
    required this.id,
    required this.tier,
    required this.buildingId,
    required this.hiredAt,
  });
}
