import 'package:flutter/material.dart';

import '../models/building.dart';
import '../theme/studio_theme.dart';

/// A tappable building (design doc §5.2 "Buildings that breathe" / §7:
/// buildings stay tappable objects that open Flutter overlay panels,
/// never walk-in 3D interiors).
class BuildingTile extends StatelessWidget {
  final BuildingState state;
  final VoidCallback onTap;

  const BuildingTile({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final def = state.def;
    final locked = state.status == BuildingStatus.locked;
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: StudioColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor(),
            width: state.status == BuildingStatus.building ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(), color: locked ? StudioColors.textSecondary : StudioColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    def.name,
                    style: TextStyle(
                      color: locked ? StudioColors.textSecondary : StudioColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusLabel(), style: const TextStyle(color: StudioColors.textSecondary, fontSize: 12)),
            if (state.status == BuildingStatus.building) ...[
              const SizedBox(height: 8),
              _buildProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final def = state.def;
    final total = def.buildTime.inMilliseconds;
    return TweenAnimationBuilder<double>(
      key: ValueKey(state.jobEndsAt),
      tween: Tween(begin: 0, end: 1),
      duration: def.buildTime,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : value,
            minHeight: 6,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation(StudioColors.teal),
          ),
        );
      },
    );
  }

  Color _borderColor() {
    switch (state.status) {
      case BuildingStatus.locked:
        return Colors.black26;
      case BuildingStatus.buildable:
        return StudioColors.goldMuted;
      case BuildingStatus.building:
      case BuildingStatus.upgrading:
        return StudioColors.teal;
      case BuildingStatus.idle:
      case BuildingStatus.active:
        return StudioColors.gold.withOpacity(0.4);
    }
  }

  IconData _iconFor() {
    switch (state.status) {
      case BuildingStatus.locked:
        return Icons.lock;
      case BuildingStatus.buildable:
        return Icons.add_business;
      case BuildingStatus.building:
      case BuildingStatus.upgrading:
        return Icons.construction;
      case BuildingStatus.idle:
        return Icons.location_city;
      case BuildingStatus.active:
        return Icons.movie_creation;
    }
  }

  String _statusLabel() {
    switch (state.status) {
      case BuildingStatus.locked:
        return 'Unlocks at level ${state.def.unlockLevel}';
      case BuildingStatus.buildable:
        return 'Tap to build • ₹${state.def.buildCost}';
      case BuildingStatus.building:
        return 'Under construction...';
      case BuildingStatus.upgrading:
        return 'Upgrading...';
      case BuildingStatus.idle:
        return 'Ready';
      case BuildingStatus.active:
        return 'In production';
    }
  }
}
