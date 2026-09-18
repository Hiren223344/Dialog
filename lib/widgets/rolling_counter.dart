import 'package:flutter/material.dart';

/// A number that animates ("rolls") toward its new value instead of
/// snapping, per design doc §5.3: "Numbers roll/animate on change."
class RollingCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String Function(int)? format;

  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.format,
  });

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  late int _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: _displayed, end: _displayed).animate(_controller);
  }

  @override
  void didUpdateWidget(RollingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final from = _animation.value;
      _animation = IntTween(begin: from, end: widget.value)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(_controller);
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final text =
            widget.format != null ? widget.format!(_animation.value) : '${_animation.value}';
        return Text(text, style: widget.style);
      },
    );
  }
}
