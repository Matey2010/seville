import 'dart:math' as math;
import 'dart:ui';

import '../models/compass_layout.dart';
import '../models/layout.dart';
import 'interface_colors.dart';
import 'layout_axes.dart';
import 'layout_guides.dart';
import 'meeple_defaults.dart';
import 'perceptual_map_defaults.dart';

const defaultTimeCompassLayers = [
  LayoutSlot(id: 'relative', label: 'Relative', fraction: 0.5),
  LayoutSlot(id: 'hour', label: 'Hour', fraction: 1),
  LayoutSlot(id: 'day', label: 'Day', fraction: 1),
  LayoutSlot(id: 'week', label: 'Week', fraction: 1),
  LayoutSlot(id: 'month', label: 'Month', fraction: 1),
  LayoutSlot(id: 'quarter', label: 'Quarter', fraction: 1),
  LayoutSlot(id: 'season', label: 'Season', fraction: 1),
  LayoutSlot(id: 'year', label: 'Year', fraction: 1),
  LayoutSlot(id: 'decade', label: 'Decade', fraction: 1),
  LayoutSlot(id: 'century', label: 'Century', fraction: 1),
  LayoutSlot(id: 'millennia', label: 'Millennia', fraction: 1),
];

const defaultTimeCompassVirtualColumnFractions = [15.25, 15.5];

const defaultTimeCompassSurroundSlotStyle = CompassSlotStyle(
  guideStyle: GuideStyle(color: perceptualMapDiagonalColor, strokeWidth: 1.2),
  fontSize: 11,
);

const defaultTimeCompassSurroundSlots = [
  CompassSlot(
    slot: LayoutSlot(id: 'left-center', label: 'Left center'),
    startDegrees: 225,
    spanDegrees: 90,
  ),
  CompassSlot(
    slot: LayoutSlot(id: 'top-center', label: 'Top center'),
    startDegrees: 315,
    spanDegrees: 90,
  ),
  CompassSlot(
    slot: LayoutSlot(id: 'right-center', label: 'Right center'),
    startDegrees: 45,
    spanDegrees: 90,
  ),
];

const defaultTimeCompassGuides = {
  'scene-intersections': sceneIntersectionGuideGrid,
  ...defaultCardinalGuidelines,
  'time-compass-radial': timeCompassRadialGuideGrid,
  'time-compass-virtual': timeCompassVirtualGuideGrid,
};

final defaultTimeCompassLayout = _createDefaultTimeCompassLayout();

TimeCompassLayout _createDefaultTimeCompassLayout() {
  return TimeCompassLayout.fromAxes(
    axes: CommonRatio.twoDimension.grid120x120,
    layouts: defaultTimeCompassGuides,
    mainSlot: CompassMainSlot(
      slot: LayoutSlot(id: 'meeple', label: 'Meeple'),
      figure: CompassMainFigure.layout,
      subLayout: defaultMeepleLayout,
      positionFraction: Offset(0.5, 0.5),
      anchorFraction: Offset(0.5, 1),
      availableSizeFraction: Size(1, 0.5),
    ),
    compassSlots: defaultTimeCompassSurroundSlots,
    compassGeometry: CompassGeometry(),
    compassSlotStyle: defaultTimeCompassSurroundSlotStyle,
    layers: defaultTimeCompassLayers,
    geometry: TimeCompassGeometry(
      centerXFraction: 0.5,
      centerYFraction: 0.5,
      innerRadiusFraction: 0,
      outerRadiusFraction: 1,
      startAngleRadians: math.pi,
      sweepAngleRadians: -math.pi,
      rotationRadians: 0,
    ),
    slotStyle: TimeCompassSlotStyle(color: timeCompassGridColor, fontSize: 11),
    centerSlot: TimeCompassCenterSlot(
      slot: LayoutSlot(id: 'now', label: 'Now'),
      backgroundColor: interfaceBackgroundColor,
    ),
    virtualColumnFractions: defaultTimeCompassVirtualColumnFractions,
    slots: [
      TimeCompassSlot(
        slot: LayoutSlot(id: 'previous-overflow', label: '…'),
        area: LayoutArea(row: 0, columnSpan: 0.25, rowSpan: 11),
        labelRadialAlignment: TimeCompassSlotLabelRadialAlignment.outermostRow,
      ),
      TimeCompassSlot(
        slot: LayoutSlot(id: 'hours', label: 'Hours'),
        area: LayoutArea(row: 1, columnSpan: 30),
        lineView: LineView(
          segments: [
            LayoutSlot(
              id: 'previous-day-hours',
              label: '21, 22, 23',
              fraction: 3,
            ),
            LayoutSlot(id: 'current-day-hours', label: '0 → 23', fraction: 24),
            LayoutSlot(id: 'next-day-hours', label: '1, 2, 3', fraction: 3),
          ],
        ),
      ),
      TimeCompassSlot(
        slot: LayoutSlot(id: 'days', label: 'Days'),
        area: LayoutArea(row: 2, columnSpan: 30),
        lineView: LineView(
          segments: [
            LayoutSlot(id: 'yesterday', label: 'Yesterday', fraction: 3),
            LayoutSlot(id: 'today', label: 'Today', fraction: 24),
            LayoutSlot(id: 'tomorrow', label: 'Tomorrow', fraction: 3),
          ],
        ),
      ),
      TimeCompassSlot(
        slot: LayoutSlot(id: 'next-overflow', label: '…'),
        area: LayoutArea(row: 0, columnSpan: 0.25, rowSpan: 11),
        labelRadialAlignment: TimeCompassSlotLabelRadialAlignment.outermostRow,
      ),
    ],
  );
}
