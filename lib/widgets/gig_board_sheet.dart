import 'package:flutter/material.dart';

import '../models/gig.dart';
import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

/// The literal "contract board" (design doc §5.3): a cork-board of pinned
/// notices instead of a settings-style list, so picking a gig feels like
/// picking a job off a board rather than filling out a form.
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
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B2A1C), Color(0xFF2B1F16)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: StudioColors.goldMuted.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, color: StudioColors.gold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Contract Board',
                      style: TextStyle(
                        color: StudioColors.gold,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: gigs.length,
                  itemBuilder: (context, index) => _NoticeCard(
                    def: gigs[index],
                    tilt: index.isEven ? -0.03 : 0.03,
                    unlocked: isUnlocked(gigs[index]),
                    affordable: canAfford(gigs[index]),
                    gigInProgress: gigInProgress,
                    onSelect: onSelect,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final GigDef def;
  final double tilt;
  final bool unlocked;
  final bool affordable;
  final bool gigInProgress;
  final void Function(GigDef) onSelect;

  const _NoticeCard({
    required this.def,
    required this.tilt,
    required this.unlocked,
    required this.affordable,
    required this.gigInProgress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final available = unlocked && affordable && !gigInProgress;

    return Transform.rotate(
      angle: tilt,
      child: GestureDetector(
        onTap: available
            ? () {
                StudioSfx.play(SfxCue.tap);
                onSelect(def);
              }
            : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3E6C8),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 3))],
            ),
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.push_pin,
                      size: 18,
                      color: unlocked ? const Color(0xFFB33A3A) : Colors.grey,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          unlocked ? Icons.edit_note : Icons.lock,
                          size: 16,
                          color: const Color(0xFF3B2A1C),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            def.name,
                            style: const TextStyle(
                              color: Color(0xFF2B1F16),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unlocked ? 'Target ${def.likeTarget} likes' : 'Requires level ${def.requiredLevel}',
                      style: const TextStyle(color: Color(0xFF5A4632), fontSize: 10.5),
                    ),
                    if (unlocked) ...[
                      const SizedBox(height: 2),
                      Text(
                        '₹${def.cost} to post • ₹${def.rewardBoxOffice} reward',
                        style: const TextStyle(color: Color(0xFF5A4632), fontSize: 10.5),
                      ),
                    ],
                    const Spacer(),
                    if (unlocked && !affordable)
                      const Text(
                        'Not enough ₹',
                        style: TextStyle(color: Color(0xFFB33A3A), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
