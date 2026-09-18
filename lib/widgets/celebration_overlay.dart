import 'package:flutter/material.dart';

import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';
import 'confetti_overlay.dart';

enum CelebrationKind { levelUp, buildingComplete, viral }

class CelebrationData {
  final CelebrationKind kind;
  final String title;
  final String subtitle;

  const CelebrationData({
    required this.kind,
    required this.title,
    required this.subtitle,
  });
}

/// Full-screen celebration for rank-ups and building completions
/// (design doc §5.4: "full-screen celebration with the new rank/building
/// revealed, not a silent number change").
class CelebrationOverlay extends StatefulWidget {
  final CelebrationData data;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    final cue = switch (widget.data.kind) {
      CelebrationKind.levelUp => SfxCue.levelUp,
      CelebrationKind.buildingComplete => SfxCue.buildingComplete,
      CelebrationKind.viral => SfxCue.viralBurst,
    };
    StudioSfx.play(cue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    return Material(
      color: Colors.black.withOpacity(0.72),
      child: Stack(
        children: [
          const Positioned.fill(child: ConfettiBurst(particleCount: 60)),
          Center(
            child: ScaleTransition(
              scale: scale,
              child: FadeTransition(
                opacity: _controller,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: StudioColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: StudioColors.goldMuted, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconFor(widget.data.kind), color: StudioColors.gold, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        widget.data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: StudioColors.gold,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.data.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: StudioColors.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          StudioSfx.play(SfxCue.tap);
                          widget.onDismiss();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StudioColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(CelebrationKind kind) {
    switch (kind) {
      case CelebrationKind.levelUp:
        return Icons.military_tech;
      case CelebrationKind.buildingComplete:
        return Icons.location_city;
      case CelebrationKind.viral:
        return Icons.local_fire_department;
    }
  }
}
