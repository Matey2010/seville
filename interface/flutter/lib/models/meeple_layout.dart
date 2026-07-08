import 'dart:math' as math;
import 'dart:ui';

import 'layout.dart';

class MeepleLayoutPadding {
  const MeepleLayoutPadding({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  double get horizontal => left + right;
  double get vertical => top + bottom;
}

class MeepleLayoutConfig extends LayoutConfig {
  const MeepleLayoutConfig({
    required this.assetPath,
    required this.bodyColor,
    this.heightFraction = 1,
    this.aspectRatio = 0.5,
    this.padding = const MeepleLayoutPadding(),
    super.backgroundColor,
  });

  final String assetPath;
  final Color bodyColor;
  final double heightFraction;
  final double aspectRatio;
  final MeepleLayoutPadding padding;

  double layoutHeightFor(double availableHeight) {
    return availableHeight * heightFraction.clamp(0, 1);
  }

  double meepleHeightFor(double availableHeight) {
    return math.max(0, layoutHeightFor(availableHeight) - padding.vertical);
  }

  double meepleWidthFor(double availableHeight) {
    return meepleHeightFor(availableHeight) * math.max(0, aspectRatio);
  }

  double layoutWidthFor(double availableHeight) {
    return meepleWidthFor(availableHeight) + padding.horizontal;
  }
}

class MeepleLayout extends Layout {
  const MeepleLayout.fromAxes({
    required super.axes,
    super.attributes = const [LayoutAttribute.rectangular],
    required this.config,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.innerCircle,
    super.outerCircle,
    super.columnFractions,
    super.rowFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final MeepleLayoutConfig config;
}
