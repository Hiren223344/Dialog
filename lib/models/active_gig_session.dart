import 'gig.dart';

/// The gig currently being written/produced. Likes accrue live while it
/// runs, driving the "likes arriving" juice (design doc §5.4) before the
/// gig resolves into a [GigResult].
class ActiveGigSession {
  final GigDef def;
  final String text;
  final DateTime startedAt;
  final DateTime endsAt;
  int likes;
  bool wentViral;

  ActiveGigSession({
    required this.def,
    required this.text,
    required this.startedAt,
    required this.endsAt,
    this.likes = 0,
    this.wentViral = false,
  });

  double get progress {
    final total = endsAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  bool get isDone => DateTime.now().isAfter(endsAt);
}
