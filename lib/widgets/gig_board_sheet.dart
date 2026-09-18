import 'package:flutter/material.dart';

import '../models/gig.dart';
import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

/// The "contract board" (design doc §5.3) listing every gig and whether
/// it's currently available.
class GigBoardSheet extends StatelessWidget {
  final List<GigDef> gigs;
  final bool Function(GigDef) isUnlocked;
  final bool Function(GigDef) canAfford;
  final bool gigInProgress;
  final void Function(GigDef) onSelect;

  const GigBoardSheet({
    super.key,
    required this.gigs,
    required this.isUnlocked,
    required this.canAfford,
    required this.gigInProgress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: StudioColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: gigs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Contract Board',
                    style: TextStyle(
                      color: StudioColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              final def = gigs[index - 1];
              final unlocked = isUnlocked(def);
              final affordable = canAfford(def);
              final available = unlocked && affordable && !gigInProgress;
              return Card(
                color: Colors.black26,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  enabled: available,
                  leading: Icon(
                    unlocked ? Icons.edit_note : Icons.lock,
                    color: available ? StudioColors.gold : StudioColors.textSecondary,
                  ),
                  title: Text(
                    def.name,
                    style: TextStyle(
                      color: available ? StudioColors.textPrimary : StudioColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    unlocked
                        ? '₹${def.cost} • target ${def.likeTarget} likes • ₹${def.rewardBoxOffice} reward'
                        : 'Requires level ${def.requiredLevel}',
                    style: const TextStyle(color: StudioColors.textSecondary, fontSize: 12),
                  ),
                  onTap: available
                      ? () {
                          StudioSfx.play(SfxCue.tap);
                          onSelect(def);
                        }
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
