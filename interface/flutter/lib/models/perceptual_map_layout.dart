import 'dart:ui';

import 'layout.dart';

enum PerceptualMapSlot {
  top,
  bottom,
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  bottomCenter,
  topCenter,
  leftCenter,
  rightCenter,
  center,
}

abstract final class PerceptualMapSlotAlias {
  static const leftBottom = PerceptualMapSlot.bottomLeft;
  static const rightBottom = PerceptualMapSlot.bottomRight;
  static const bottomCenterTriangleSlots = PerceptualMapSlot.bottomCenter;

  static const lb = leftBottom;
  static const rb = rightBottom;
  static const bc = bottomCenterTriangleSlots;

  static const values = <String, PerceptualMapSlot>{
    'lb': lb,
    'leftbottom': leftBottom,
    'rb': rb,
    'rightbottom': rightBottom,
    'bc': bc,
    'bottomcentertriangleslots': bottomCenterTriangleSlots,
  };

  static PerceptualMapSlot? resolve(String alias) {
    return values[alias.trim().toLowerCase()];
  }
}

enum PerceptualMapSlotShape { stack, triangle }

class PerceptualMapSlotStyle {
  const PerceptualMapSlotStyle({
    required this.color,
    this.strokeWidth = 2,
    this.dashLength = 8,
    this.gapLength = 6,
    this.fontSize = 12,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double fontSize;
}

class PerceptualMapSlotConfig {
  const PerceptualMapSlotConfig({
    required this.slots,
    required this.style,
    this.shape = PerceptualMapSlotShape.stack,
    this.apexSlot,
    this.extent = 2,
    this.extentFractions = 8,
    this.widthFractions = 8,
  });

  final List<LayoutSlot> slots;
  final PerceptualMapSlotStyle style;
  final PerceptualMapSlotShape shape;

  /// Optional layer-zero slot placed at the apex before [slots].
  final LayoutSlot? apexSlot;

  /// Main-axis extent measured against [extentFractions].
  final double extent;
  final double extentFractions;

  /// Cross-axis fraction budget used by span/min/max width values.
  final double widthFractions;
}

class PerceptualMapLayout extends GridLayout {
  const PerceptualMapLayout.fromAxes({
    required super.axes,
    super.attributes = const [LayoutAttribute.rectangular],
    this.slotConfigs = const {},
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.columnFractions,
    super.rowFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final Map<PerceptualMapSlot, PerceptualMapSlotConfig> slotConfigs;
}
