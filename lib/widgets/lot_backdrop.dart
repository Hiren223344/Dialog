import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/studio_theme.dart';

class _Cloud {
  final double y;
  final double speed;
  final double scale;
  final double startX;

  _Cloud(Random random)
      : y = 20 + random.nextDouble() * 90,
        speed = 6 + random.nextDouble() * 10,
        scale = 0.7 + random.nextDouble() * 0.9,
        startX = random.nextDouble() * 1.0;
}

/// The studio lot's sky, drifting clouds, and ground plane (design doc
/// §5.2 "the living world" / §5.1 "warm, premium ... golden-hour"). Pure
/// vector/gradient painting -- no art assets required.
class LotBackdrop extends StatefulWidget {
  final double width;
  final double height;

  const LotBackdrop({super.key, required this.width, required this.height});

  @override
  State<LotBackdrop> createState() => _LotBackdropState();
}

class _LotBackdropState extends State<LotBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Cloud> _clouds;

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _clouds = List.generate(4, (_) => _Cloud(random));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Golden-hour sky.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241A12),
                  StudioColors.background,
                  Color(0xFF1B140F),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _CloudPainter(_clouds, _controller.value),
            ),
          ),
          // Ground plane.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 46,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0B09),
                border: Border(top: BorderSide(color: StudioColors.goldMuted.withOpacity(0.25))),
              ),
              child: CustomPaint(painter: _GroundLinePainter(), size: Size.infinite),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final List<_Cloud> clouds;
  final double t;

  _CloudPainter(this.clouds, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    for (final cloud in clouds) {
      final progress = (cloud.startX + t * (cloud.speed / 10)) % 1.2 - 0.1;
      final cx = progress * size.width;
      final cy = cloud.y;
      final r = 22.0 * cloud.scale;
      canvas.drawCircle(Offset(cx, cy), r, paint);
      canvas.drawCircle(Offset(cx + r * 0.8, cy + 4), r * 0.7, paint);
      canvas.drawCircle(Offset(cx - r * 0.8, cy + 6), r * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => oldDelegate.t != t;
}

class _GroundLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StudioColors.goldMuted.withOpacity(0.12)
      ..strokeWidth = 2;
    const dashWidth = 14.0;
    const gap = 10.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + dashWidth, size.height / 2), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GroundLinePainter oldDelegate) => false;
}
