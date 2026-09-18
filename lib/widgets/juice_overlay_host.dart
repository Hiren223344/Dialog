import 'dart:collection';

import 'package:flutter/material.dart';

import '../services/studio_sfx.dart';
import 'celebration_overlay.dart';
import 'confetti_overlay.dart';
import 'flying_reward.dart';
import 'floating_heart.dart';

/// Looks up the current center of the widget attached to [key], in global
/// (screen) coordinates. Returns null if the widget isn't laid out yet.
Offset? globalCenterOf(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.attached) return null;
  final topLeft = renderObject.localToGlobal(Offset.zero);
  return topLeft + renderObject.size.center(Offset.zero);
}

/// Central coordinator for every transient "juice" effect (design doc
/// §5.4): reward icons flying into the HUD, hearts floating up from a
/// gig, viral confetti bursts, and full-screen celebrations. Keeping this
/// in one controller means every screen triggers effects the same way
/// instead of re-implementing overlay plumbing per-widget.
class JuiceController extends ChangeNotifier {
  final _flyingRewards = <FlyingRewardRequest>[];
  final _floatingHearts = <FloatingHeartRequest>[];
  bool _confettiActive = false;
  bool _flashActive = false;
  final Queue<CelebrationData> _celebrationQueue = Queue();
  CelebrationData? _activeCelebration;

  List<FlyingRewardRequest> get flyingRewards => List.unmodifiable(_flyingRewards);
  List<FloatingHeartRequest> get floatingHearts => List.unmodifiable(_floatingHearts);
  bool get confettiActive => _confettiActive;
  bool get flashActive => _flashActive;
  CelebrationData? get activeCelebration => _activeCelebration;

  int _nextId = 0;

  void flyReward({
    required Offset from,
    required Offset to,
    required RewardKind kind,
    required int amount,
  }) {
    final request = FlyingRewardRequest(
      id: _nextId++,
      from: from,
      to: to,
      kind: kind,
      amount: amount,
    );
    _flyingRewards.add(request);
    notifyListeners();
  }

  void completeFlyingReward(int id) {
    _flyingRewards.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void spawnFloatingHeart(Offset origin) {
    final request = FloatingHeartRequest(id: _nextId++, origin: origin);
    _floatingHearts.add(request);
    notifyListeners();
  }

  void completeFloatingHeart(int id) {
    _floatingHearts.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void burstConfetti() {
    _confettiActive = true;
    notifyListeners();
  }

  void _stopConfetti() {
    _confettiActive = false;
    notifyListeners();
  }

  void flash() {
    _flashActive = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 180), () {
      _flashActive = false;
      notifyListeners();
    });
  }

  /// The gig-going-viral moment (design doc §5.4: "confetti + flash +
  /// sound"), bundled so call sites don't have to wire the three effects
  /// together themselves.
  void viralBurst() {
    burstConfetti();
    flash();
    StudioSfx.play(SfxCue.viralBurst);
  }

  void celebrate(CelebrationData data) {
    _celebrationQueue.add(data);
    _advanceCelebrationQueue();
  }

  void _advanceCelebrationQueue() {
    if (_activeCelebration != null || _celebrationQueue.isEmpty) return;
    _activeCelebration = _celebrationQueue.removeFirst();
    notifyListeners();
  }

  void dismissCelebration() {
    _activeCelebration = null;
    notifyListeners();
    _advanceCelebrationQueue();
  }
}

class _JuiceScope extends InheritedNotifier<JuiceController> {
  const _JuiceScope({required JuiceController controller, required super.child})
      : super(notifier: controller);
}

/// Wraps [child] with a [Stack] that renders every active juice effect on
/// top of it, and exposes [JuiceOverlayHost.of] so descendants can trigger
/// effects without threading a controller through every constructor.
class JuiceOverlayHost extends StatefulWidget {
  final Widget child;

  const JuiceOverlayHost({super.key, required this.child});

  static JuiceController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_JuiceScope>();
    assert(scope != null, 'No JuiceOverlayHost found in context');
    return scope!.notifier!;
  }

  @override
  State<JuiceOverlayHost> createState() => _JuiceOverlayHostState();
}

class _JuiceOverlayHostState extends State<JuiceOverlayHost> {
  final _controller = JuiceController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _JuiceScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              widget.child,
              ..._controller.floatingHearts.map(
                (request) => FloatingHeart(
                  key: ValueKey('heart-${request.id}'),
                  request: request,
                  onComplete: () => _controller.completeFloatingHeart(request.id),
                ),
              ),
              ..._controller.flyingRewards.map(
                (request) => FlyingReward(
                  key: ValueKey('reward-${request.id}'),
                  request: request,
                  onComplete: () => _controller.completeFlyingReward(request.id),
                ),
              ),
              if (_controller.confettiActive)
                Positioned.fill(
                  child: ConfettiBurst(onComplete: _controller._stopConfetti),
                ),
              if (_controller.flashActive)
                const Positioned.fill(
                  child: IgnorePointer(child: ColoredBox(color: Colors.white)),
                ),
              if (_controller.activeCelebration != null)
                Positioned.fill(
                  child: CelebrationOverlay(
                    data: _controller.activeCelebration!,
                    onDismiss: _controller.dismissCelebration,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
