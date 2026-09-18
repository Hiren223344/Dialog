import 'package:flutter/material.dart';

import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

enum RewardKind { boxOffice, fans, reputation, xp }

extension RewardKindVisuals on RewardKind {
  IconData get icon {
    switch (this) {
      case RewardKind.boxOffice:
        return Icons.attach_money;
      case RewardKind.fans:
        return Icons.favorite;
      case RewardKind.reputation:
        return Icons.star;
      case RewardKind.xp:
        return Icons.bolt;
    }
  }

  Color get color {
    switch (this) {
      case RewardKind.boxOffice:
        return StudioColors.gold;
      case RewardKind.fans:
        return StudioColors.coral;
      case RewardKind.reputation:
        return StudioColors.teal;
      case RewardKind.xp:
        return StudioColors.goldMuted;
    }
  }
}

class FlyingRewardRequest {
  final int id;
  final Offset from;
  final Offset to;
  final RewardKind kind;
  final int amount;

  const FlyingRewardRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.kind,
    required this.amount,
  });
}

/// A reward icon that flies from where it was earned to its HUD counter
/// (design doc §5.4: "coins/fans/XP visibly stream into the HUD").
class FlyingReward extends StatefulWidget {
  final FlyingRewardRequest request;
  final VoidCallback onComplete;

  const FlyingReward({super.key, required this.request, required this.onComplete});

  @override
  State<FlyingReward> createState() => _FlyingRewardState();
}

class _FlyingRewardState extends State<FlyingReward> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    StudioSfx.play(SfxCue.coinDrop);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )
      ..forward().whenComplete(() {
        StudioSfx.play(SfxCue.rewardStream);
        widget.onComplete();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    // Positioned must sit directly under Stack's parent-data resolution, so
    // AnimatedBuilder (which has no RenderObject of its own) wraps it and
    // IgnorePointer stays inside it rather than around it.
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        // Slight upward arc before homing in on the HUD target.
        final arc = -40 * (1 - t) * t * 4;
        final position = Offset.lerp(widget.request.from, widget.request.to, t)! +
            Offset(0, arc);
        final scale = 1.0 - 0.3 * t;
        final opacity = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15);
        return Positioned(
          left: position.dx - 14,
          top: position.dy - 14,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.request.kind.color.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.request.kind.icon, size: 16, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
