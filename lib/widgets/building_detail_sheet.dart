import 'package:flutter/material.dart';

import '../models/building.dart';
import '../models/staff.dart';
import '../services/studio_sfx.dart';
import '../state/game_state.dart';
import '../theme/studio_theme.dart';

/// Opened for an operational building: who's hired there (and hiring
/// more) plus upgrading it -- the "Hire Staff" and "Shop" actions from
/// both the 2D lot and the Unity building menu (design doc §4.3
/// "Staff"). Holds a direct reference to the shared [GameState] and
/// re-reads it in its own setState after every action, rather than
/// needing GameState to be a ChangeNotifier just for this one sheet.
class BuildingDetailSheet extends StatefulWidget {
  final GameState game;
  final String buildingId;

  const BuildingDetailSheet({super.key, required this.game, required this.buildingId});

  @override
  State<BuildingDetailSheet> createState() => _BuildingDetailSheetState();
}

class _BuildingDetailSheetState extends State<BuildingDetailSheet> {
  GameState get _game => widget.game;

  @override
  Widget build(BuildContext context) {
    final state = _game.buildings[widget.buildingId];
    if (state == null) return const SizedBox.shrink();

    final staffHere = _game.staff.where((s) => s.buildingId == widget.buildingId).toList();
    final slotsLeft = state.def.staffSlots - staffHere.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: StudioColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                state.def.name,
                style: const TextStyle(color: StudioColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${_game.resources.boxOffice} available',
                style: const TextStyle(color: StudioColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Staff ($slotsLeft slot${slotsLeft == 1 ? '' : 's'} open)'),
              const SizedBox(height: 8),
              ...staffHere.map(_staffTile),
              if (staffHere.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nobody hired here yet.', style: TextStyle(color: StudioColors.textSecondary)),
                ),
              const SizedBox(height: 12),
              ...StaffTier.values.map(_hireRow),
              const SizedBox(height: 24),
              _sectionHeader('Upgrade'),
              const SizedBox(height: 8),
              _upgradeSection(state),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: const TextStyle(color: StudioColors.teal, fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _staffTile(StaffMember member) {
    return Card(
      color: Colors.black26,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person, color: StudioColors.gold),
        title: Text(member.tier.title, style: const TextStyle(color: StudioColors.textPrimary)),
        subtitle: Text(
          '₹${member.tier.hourlyCost}/hr • +${(member.tier.efficiencyBonus * 100).round()}% output',
          style: const TextStyle(color: StudioColors.textSecondary, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove, color: StudioColors.coral),
          onPressed: () {
            StudioSfx.play(SfxCue.tap);
            setState(() => _game.fireStaff(member.id));
          },
        ),
      ),
    );
  }

  Widget _hireRow(StaffTier tier) {
    final canHire = _game.canHireStaff(widget.buildingId, tier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: canHire
              ? () {
                  StudioSfx.play(SfxCue.tap);
                  setState(() => _game.hireStaff(widget.buildingId, tier));
                }
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: StudioColors.textPrimary,
            side: BorderSide(color: canHire ? StudioColors.goldMuted : Colors.black26),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('Hire ${tier.title} • ₹${tier.hireCost} • ₹${tier.hourlyCost}/hr'),
        ),
      ),
    );
  }

  Widget _upgradeSection(BuildingState state) {
    if (state.upgradeLevel >= state.def.maxUpgradeLevel) {
      return const Text('Fully upgraded.', style: TextStyle(color: StudioColors.textSecondary));
    }
    if (state.status == BuildingStatus.upgrading) {
      return const Text('Upgrade in progress...', style: TextStyle(color: StudioColors.teal));
    }

    final cost = _game.upgradeCost(state);
    final canUpgrade = _game.canUpgrade(widget.buildingId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level ${state.upgradeLevel} → ${state.upgradeLevel + 1} of ${state.def.maxUpgradeLevel} • +15% output',
          style: const TextStyle(color: StudioColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canUpgrade
                ? () {
                    StudioSfx.play(SfxCue.tap);
                    setState(() => _game.upgradeBuilding(widget.buildingId));
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: StudioColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Upgrade • ₹$cost'),
          ),
        ),
      ],
    );
  }
}
