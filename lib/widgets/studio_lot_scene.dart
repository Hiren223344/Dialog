import 'package:flutter/material.dart';

import '../models/building.dart';
import '../theme/studio_theme.dart';
import 'building_illustration.dart';
import 'lot_backdrop.dart';

class _LotSpot {
  final String buildingId;
  final double x;
  final bool backRow;

  const _LotSpot(this.buildingId, this.x, {this.backRow = false});
}

/// Where each building sits on the lot. Back-row buildings render smaller
/// and higher up to fake depth without a real 3D camera (design doc §5.1:
/// curated framing over camera freedom).
const _layout = [
  _LotSpot('music_room', 90, backRow: true),
  _LotSpot('cast_suite', 300, backRow: true),
  _LotSpot('costume_room', 510, backRow: true),
  _LotSpot('mini_theatre', 720, backRow: true),
  _LotSpot('producers_office', 70),
  _LotSpot('shoot_floor', 300),
  _LotSpot('editing_bay', 530),
  _LotSpot('marketing_wing', 760),
];

const double _sceneWidth = 900;
const double _sceneHeight = 340;

/// The studio lot (design doc §5): buildings placed on a golden-hour lot
/// instead of a card grid, so the studio reads as a place, not a form.
class StudioLotScene extends StatelessWidget {
  final Map<String, BuildingState> buildings;
  final String? inProductionBuildingId;
  final void Function(String buildingId) onTapBuilding;

  const StudioLotScene({
    super.key,
    required this.buildings,
    required this.onTapBuilding,
    this.inProductionBuildingId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _sceneWidth,
        height: _sceneHeight,
        child: Stack(
          children: [
            const Positioned.fill(child: LotBackdrop(width: _sceneWidth, height: _sceneHeight)),
            for (final spot in _layout) _placedBuilding(spot),
          ],
        ),
      ),
    );
  }

  Widget _placedBuilding(_LotSpot spot) {
    final state = buildings[spot.buildingId];
    if (state == null) return const SizedBox.shrink();
    final width = spot.backRow ? 92.0 : 128.0;
    final height = spot.backRow ? 100.0 : 140.0;
    // Back-row buildings (plus their labels) sit fully above where the
    // front row starts, so front buildings never paint over a back-row
    // name/status label (they may still overlap the back *illustration*
    // itself slightly, which reads as depth rather than a glitch).
    final top = spot.backRow ? 16.0 : 168.0;

    return Positioned(
      left: spot.x,
      top: top,
      child: GestureDetector(
        onTap: state.status == BuildingStatus.buildable
            ? () => onTapBuilding(spot.buildingId)
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BuildingIllustration(
              state: state,
              width: width,
              height: height,
              inProduction: inProductionBuildingId == spot.buildingId,
            ),
            const SizedBox(height: 4),
            Text(
              state.def.name,
              style: TextStyle(
                color: state.status == BuildingStatus.locked
                    ? StudioColors.textSecondary
                    : StudioColors.textPrimary,
                fontSize: spot.backRow ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            _statusLine(state),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(BuildingState state) {
    String label;
    switch (state.status) {
      case BuildingStatus.locked:
        label = 'Lv ${state.def.unlockLevel}';
      case BuildingStatus.buildable:
        label = '₹${state.def.buildCost} • tap to build';
      case BuildingStatus.building:
      case BuildingStatus.upgrading:
        label = 'Building...';
      case BuildingStatus.idle:
      case BuildingStatus.active:
        label = 'Ready';
    }
    return Text(
      label,
      style: const TextStyle(color: StudioColors.textSecondary, fontSize: 9),
    );
  }
}
