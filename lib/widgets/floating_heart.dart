import 'dart:math';

import 'package:flutter/material.dart';

import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

class FloatingHeartRequest {
  final int id;
  final Offset origin;

  const FloatingHeartRequest({required this.id, required this.origin});
}

/// A single heart that floats up and fades out when a like arrives
/// (design doc §5.4: "hearts/engagement icons float up in real time").
class FloatingHeart extends StatefulWidget {
  final FloatingHeartRequest request;
  final VoidCallback onComplete;

  const FloatingHeart({super.key, required this.request, required this.onComplete});

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _driftX;

  @override
  void initState() {
    super.initState();
    StudioSfx.play(SfxCue.likePop);
    _driftX = (Random().nextDouble() - 0.5) * 60;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned must sit directly under Stack's parent-data resolution, so
    // AnimatedBuilder (which has no RenderObject of its own) wraps it and
    // IgnorePointer stays inside it rather than around it.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dy = -80 * t;
        final dx = _driftX * t;
        final opacity = 1 - t;
        final scale = 0.8 + 0.4 * (1 - t);
        return Positioned(
          left: widget.request.origin.dx + dx - 10,
          top: widget.request.origin.dy + dy - 10,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: const Icon(Icons.favorite, color: StudioColors.coral, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}
