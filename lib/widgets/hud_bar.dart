import 'package:flutter/material.dart';

import '../models/rank.dart';
import '../models/resources.dart';
import '../theme/studio_theme.dart';
import 'rolling_counter.dart';

/// Persistent top HUD (design doc §5.3): resources with rolling counters,
/// and the rank badge with progress toward the next rank front and
/// center. [boxOfficeKey]/[fansKey]/[reputationKey]/[xpKey] are exposed so
/// callers can compute where flying-reward icons should land.
class HudBar extends StatelessWidget {
  final GameResources resources;
  final GlobalKey boxOfficeKey;
  final GlobalKey fansKey;
  final GlobalKey reputationKey;
  final GlobalKey xpKey;

  const HudBar({
    super.key,
    required this.resources,
    required this.boxOfficeKey,
    required this.fansKey,
    required this.reputationKey,
    required this.xpKey,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: StudioColors.surface.withOpacity(0.94),
          border: const Border(bottom: BorderSide(color: Colors.black26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _resourceChip(
                  key: boxOfficeKey,
                  icon: Icons.attach_money,
                  color: StudioColors.gold,
                  value: resources.boxOffice,
                ),
                const SizedBox(width: 10),
                _resourceChip(
                  key: fansKey,
                  icon: Icons.favorite,
                  color: StudioColors.coral,
                  value: resources.fans,
                ),
                const SizedBox(width: 10),
                _resourceChip(
                  key: reputationKey,
                  icon: Icons.star,
                  color: StudioColors.teal,
                  value: resources.reputation,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              key: xpKey,
              children: [
                Text(
                  resources.rank.title,
                  style: const TextStyle(
                    color: StudioColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: resources.levelProgress),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation(StudioColors.goldMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lv ${resources.level}',
                  style: const TextStyle(color: StudioColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceChip({
    required Key key,
    required IconData icon,
    required Color color,
    required int value,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          RollingCounter(
            value: value,
            style: const TextStyle(
              color: StudioColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
