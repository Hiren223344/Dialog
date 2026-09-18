import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/studio_theme.dart';

class _Particle {
  final double startX;
  final double horizontalDrift;
  final double rotationSpeed;
  final double sizeFactor;
  final double fallDelay;
  final Color color;

  _Particle(Random random)
      : startX = random.nextDouble(),
        horizontalDrift = (random.nextDouble() - 0.5) * 0.4,
        rotationSpeed = (random.nextDouble() - 0.5) * 12,
        sizeFactor = 0.6 + random.nextDouble() * 0.8,
        fallDelay = random.nextDouble() * 0.25,
        color = _palette[random.nextInt(_palette.length)];

  static const _palette = [
    StudioColors.gold,
    StudioColors.goldMuted,
    StudioColors.teal,
    StudioColors.coral,
  ];
}

/// A lightweight, dependency-free confetti burst used for viral moments
/// and celebrations (design doc §5.4 "viral burst (confetti + flash +
/// sound)").
class ConfettiBurst extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiBurst({
    super.key,
    this.particleCount = 40,
    this.duration = const Duration(milliseconds: 1400),
    this.onComplete,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _particles = List.generate(widget.particleCount, (_) => _Particle(random));
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final localT = ((t - particle.fallDelay) / (1 - particle.fallDelay))
          .clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final opacity = (1 - localT).clamp(0.0, 1.0);
      final dx = (particle.startX + particle.horizontalDrift * localT) * size.width;
      final dy = localT * size.height;
      final paint = Paint()..color = particle.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotationSpeed * localT);
      final w = 6.0 * particle.sizeFactor;
      final h = 10.0 * particle.sizeFactor;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
