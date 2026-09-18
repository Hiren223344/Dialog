import 'dart:math';

import 'package:flutter/material.dart';

import '../models/building.dart';
import '../theme/studio_theme.dart';

class _BuildingVisual {
  final IconData badge;
  final Color accent;

  const _BuildingVisual(this.badge, this.accent);
}

const Map<String, _BuildingVisual> _visuals = {
  'producers_office': _BuildingVisual(Icons.business_center, StudioColors.gold),
  'shoot_floor': _BuildingVisual(Icons.videocam, StudioColors.coral),
  'editing_bay': _BuildingVisual(Icons.movie_filter, StudioColors.teal),
  'music_room': _BuildingVisual(Icons.music_note, StudioColors.goldMuted),
  'cast_suite': _BuildingVisual(Icons.theater_comedy, StudioColors.coral),
  'costume_room': _BuildingVisual(Icons.checkroom, StudioColors.teal),
  'marketing_wing': _BuildingVisual(Icons.campaign, StudioColors.gold),
  'mini_theatre': _BuildingVisual(Icons.local_movies, StudioColors.goldMuted),
};

/// A vector-drawn building on the studio lot (design doc §5.2 "buildings
/// that breathe"): no art assets, just a painted silhouette that idles,
/// glows when tappable, and shows a construction overlay while building.
class BuildingIllustration extends StatefulWidget {
  final BuildingState state;
  final double width;
  final double height;
  final bool inProduction;

  const BuildingIllustration({
    super.key,
    required this.state,
    required this.width,
    required this.height,
    this.inProduction = false,
  });

  @override
  State<BuildingIllustration> createState() => _BuildingIllustrationState();
}

class _BuildingIllustrationState extends State<BuildingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.state.def;
    final visual = _visuals[def.id] ?? const _BuildingVisual(Icons.apartment, StudioColors.gold);
    final locked = widget.state.status == BuildingStatus.locked;
    final buildable = widget.state.status == BuildingStatus.buildable;
    final building = widget.state.status == BuildingStatus.building ||
        widget.state.status == BuildingStatus.upgrading;
    final operational = widget.state.status.isOperational;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * 2 * pi;
        final bob = operational ? sin(phase) * 2.5 : 0.0;
        final glow = buildable
            ? 0.35 + 0.35 * (0.5 + 0.5 * sin(phase))
            : (widget.inProduction ? 0.5 + 0.4 * (0.5 + 0.5 * sin(phase * 2)) : 0.0);
        final windowGlow = locked ? 0.0 : (operational ? 0.85 : (buildable ? 0.15 : 0.35));

        return Transform.translate(
          offset: Offset(0, -bob),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (glow > 0)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.inProduction ? StudioColors.teal : StudioColors.gold)
                              .withOpacity(glow),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: ColorFiltered(
                    colorFilter: locked
                        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: CustomPaint(
                      size: Size(widget.width, widget.height),
                      painter: _BuildingPainter(
                        accent: visual.accent,
                        badge: visual.badge,
                        windowGlow: windowGlow,
                        flicker: widget.inProduction ? (0.6 + 0.4 * sin(phase * 6)) : 1,
                      ),
                    ),
                  ),
                ),
                if (locked)
                  const Positioned(
                    top: 6,
                    child: Icon(Icons.lock, color: StudioColors.textSecondary, size: 18),
                  ),
                if (building)
                  Positioned(
                    top: -18,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) => Transform.rotate(
                        angle: sin(value * 2 * pi) * 0.12,
                        child: const Icon(Icons.construction, color: StudioColors.teal, size: 20),
                      ),
                    ),
                  ),
                if (widget.inProduction)
                  Positioned(
                    top: -14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StudioColors.coral.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ON AIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BuildingPainter extends CustomPainter {
  final Color accent;
  final IconData badge;
  final double windowGlow;
  final double flicker;

  _BuildingPainter({
    required this.accent,
    required this.badge,
    required this.windowGlow,
    required this.flicker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyTop = h * 0.32;

    // Roof.
    final roofPaint = Paint()..color = accent.withOpacity(0.9);
    final roofPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.06, bodyTop)
      ..lineTo(w * 0.94, bodyTop)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Facade.
    final facadeRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, bodyTop, w, h - bodyTop),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(facadeRect, Paint()..color = StudioColors.surface);
    canvas.drawRRect(
      facadeRect,
      Paint()
        ..color = accent.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Windows, glowing based on status.
    final windowPaint = Paint()
      ..color = Color.lerp(const Color(0xFF2A2320), StudioColors.gold, windowGlow * flicker)!;
    const cols = 3;
    const rows = 2;
    final winW = w * 0.14;
    final winH = h * 0.11;
    final gridTop = bodyTop + h * 0.1;
    final gridLeft = w * 0.14;
    final gapX = (w * 0.72 - winW * cols) / (cols - 1);
    final gapY = h * 0.14;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = gridLeft + c * (winW + gapX);
        final y = gridTop + r * (winH + gapY);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, winW, winH), const Radius.circular(2)),
          windowPaint,
        );
      }
    }

    // Door.
    final doorRect = Rect.fromLTWH(w * 0.42, h - h * 0.18, w * 0.16, h * 0.18);
    canvas.drawRect(doorRect, Paint()..color = accent.withOpacity(0.7));

    // Icon badge on the roof.
    final iconPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(badge.codePoint),
        style: TextStyle(
          fontSize: 14,
          fontFamily: badge.fontFamily,
          package: badge.fontPackage,
          color: Colors.black.withOpacity(0.75),
        ),
      )
      ..layout();
    iconPainter.paint(canvas, Offset(w / 2 - iconPainter.width / 2, bodyTop * 0.42));
  }

  @override
  bool shouldRepaint(covariant _BuildingPainter oldDelegate) =>
      oldDelegate.windowGlow != windowGlow || oldDelegate.flicker != flicker;
}
