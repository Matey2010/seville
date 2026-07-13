import 'dart:math' as math;
import 'dart:ui';

import 'layout.dart';
import 'meeple_layout.dart';
import 'perceptual_map_layout.dart';

enum CompassMainFigure { layout, circle, triangle, square, star }

enum CompassFigureLineDirection { none, vertical, horizontal }

class CompassFigureConfig {
  const CompassFigureConfig({
    this.sizeFraction = const Size(0.25, 0.15),
    this.rotationDegrees = 0,
    required this.fillColor,
    required this.borderColor,
    required this.lineColor,
    this.borderWidth = 2,
    this.lineWidth = 1,
    this.parallelLineCount = 0,
    this.lineDirection = .none,
    this.paintSurface = true,
    this.paintBorder = true,
  });

  final Size sizeFraction;
  final double rotationDegrees;
  final Color fillColor;
  final Color borderColor;
  final Color lineColor;
  final double borderWidth;
  final double lineWidth;
  final int parallelLineCount;
  final CompassFigureLineDirection lineDirection;
  final bool paintSurface;
  final bool paintBorder;

  Size resolveSize(Rect frame) {
    final baseSize = Size(
      frame.width * sizeFraction.width,
      frame.height * sizeFraction.height,
    );
    final quarterTurns = (rotationDegrees / 90).round().abs();
    return quarterTurns.isOdd
        ? Size(baseSize.height, baseSize.width)
        : baseSize;
  }

  CompassFigureConfig copyWith({
    Size? sizeFraction,
    double? rotationDegrees,
    Color? fillColor,
    Color? borderColor,
    Color? lineColor,
    double? borderWidth,
    double? lineWidth,
    int? parallelLineCount,
    CompassFigureLineDirection? lineDirection,
    bool? paintSurface,
    bool? paintBorder,
  }) {
    return CompassFigureConfig(
      sizeFraction: sizeFraction ?? this.sizeFraction,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      lineColor: lineColor ?? this.lineColor,
      borderWidth: borderWidth ?? this.borderWidth,
      lineWidth: lineWidth ?? this.lineWidth,
      parallelLineCount: parallelLineCount ?? this.parallelLineCount,
      lineDirection: lineDirection ?? this.lineDirection,
      paintSurface: paintSurface ?? this.paintSurface,
      paintBorder: paintBorder ?? this.paintBorder,
    );
  }
}

class CompassFrame {
  const CompassFrame({
    this.leftFraction = 0,
    this.topFraction = 0,
    this.widthFraction = 1,
    this.heightFraction = 1,
  });

  final double leftFraction;
  final double topFraction;
  final double widthFraction;
  final double heightFraction;

  Rect resolve(Size parentSize) {
    return Rect.fromLTWH(
      parentSize.width * leftFraction,
      parentSize.height * topFraction,
      parentSize.width * widthFraction,
      parentSize.height * heightFraction,
    );
  }

  CompassFrame copyWith({
    double? leftFraction,
    double? topFraction,
    double? widthFraction,
    double? heightFraction,
  }) {
    return CompassFrame(
      leftFraction: leftFraction ?? this.leftFraction,
      topFraction: topFraction ?? this.topFraction,
      widthFraction: widthFraction ?? this.widthFraction,
      heightFraction: heightFraction ?? this.heightFraction,
    );
  }
}

class CompassMainSlot {
  const CompassMainSlot({
    required this.slot,
    required this.figure,
    this.subLayout,
    this.figureConfig,
    this.positionFraction = const Offset(0.5, 0.5),
    this.anchorFraction = const Offset(0.5, 0.5),
    this.availableSizeFraction = const Size(1, 1),
    this.translation = Offset.zero,
  });

  final LayoutSlot slot;
  final CompassMainFigure figure;
  final Layout? subLayout;
  final CompassFigureConfig? figureConfig;

  /// Position inside the owning [CompassFrame].
  final Offset positionFraction;

  /// Point inside the figure attached to [positionFraction].
  final Offset anchorFraction;

  /// Fraction of the frame offered to the figure's own sizing rules.
  final Size availableSizeFraction;

  /// Runtime logical-pixel movement for transitions and character animation.
  final Offset translation;

  Rect place(Size contentSize, Rect frame) {
    final position =
        Offset(
          frame.left + frame.width * positionFraction.dx,
          frame.top + frame.height * positionFraction.dy,
        ) +
        translation;
    return Rect.fromLTWH(
      position.dx - contentSize.width * anchorFraction.dx,
      position.dy - contentSize.height * anchorFraction.dy,
      contentSize.width,
      contentSize.height,
    );
  }

  CompassMainSlot copyWith({
    LayoutSlot? slot,
    CompassMainFigure? figure,
    Layout? subLayout,
    CompassFigureConfig? figureConfig,
    Offset? positionFraction,
    Offset? anchorFraction,
    Size? availableSizeFraction,
    Offset? translation,
  }) {
    return CompassMainSlot(
      slot: slot ?? this.slot,
      figure: figure ?? this.figure,
      subLayout: subLayout ?? this.subLayout,
      figureConfig: figureConfig ?? this.figureConfig,
      positionFraction: positionFraction ?? this.positionFraction,
      anchorFraction: anchorFraction ?? this.anchorFraction,
      availableSizeFraction:
          availableSizeFraction ?? this.availableSizeFraction,
      translation: translation ?? this.translation,
    );
  }
}

class CompassSlot {
  const CompassSlot({
    required this.slot,
    this.layout,
    this.startDegrees,
    this.spanDegrees,
  });

  final LayoutSlot slot;
  final Layout? layout;

  /// Clockwise degrees where 0° points toward the top of the viewport.
  ///
  /// When omitted, the slot follows the preceding slot.
  final double? startDegrees;

  /// Fixed angular size. Unrestricted slots flex across remaining degrees.
  final double? spanDegrees;
}

class CompassSlotStyle {
  const CompassSlotStyle({required this.guideStyle, this.fontSize = 11});

  final GuideStyle guideStyle;
  final double fontSize;
}

class CompassGeometry {
  const CompassGeometry({this.startDegrees = 0, this.sweepDegrees = 360});

  final double startDegrees;
  final double sweepDegrees;
}

class CompassLayout extends PerceptualMapLayout {
  const CompassLayout.fromAxes({
    required super.axes,
    super.attributes = const [
      LayoutAttribute.rectangular,
      LayoutAttribute.circular,
    ],
    required this.mainSlot,
    required this.compassSlots,
    required this.compassGeometry,
    required this.compassSlotStyle,
    this.frame = const CompassFrame(),
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.slotConfigs,
    super.columnFractions,
    super.rowFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final CompassMainSlot mainSlot;
  final List<CompassSlot> compassSlots;
  final CompassGeometry compassGeometry;
  final CompassSlotStyle compassSlotStyle;
  final CompassFrame frame;

  CompassLayout copyWith({
    CompassMainSlot? mainSlot,
    List<CompassSlot>? compassSlots,
    CompassGeometry? compassGeometry,
    CompassSlotStyle? compassSlotStyle,
    CompassFrame? frame,
  }) {
    return CompassLayout.fromAxes(
      axes: axes,
      attributes: attributes,
      mainSlot: mainSlot ?? this.mainSlot,
      compassSlots: compassSlots ?? this.compassSlots,
      compassGeometry: compassGeometry ?? this.compassGeometry,
      compassSlotStyle: compassSlotStyle ?? this.compassSlotStyle,
      frame: frame ?? this.frame,
      layouts: layouts,
      derivatives: derivatives,
      derivativeSnapshot: derivativeSnapshot,
      observables: observables,
      modes: modes,
      slotConfigs: slotConfigs,
      columnFractions: columnFractions,
      rowFractions: rowFractions,
      fractionSpans: fractionSpans,
      subLayouts: subLayouts,
      elements: elements,
    );
  }
}

class TimeCompassSlotStyle {
  const TimeCompassSlotStyle({required this.color, this.fontSize = 11});

  final Color color;
  final double fontSize;
}

enum TimeCompassSlotLabelRadialAlignment { center, outermostRow }

class TimeCompassSlot {
  const TimeCompassSlot({
    required this.slot,
    required this.area,
    this.lineView,
    this.labelRadialAlignment = TimeCompassSlotLabelRadialAlignment.center,
    this.reserveSpannedRows = true,
  });

  final LayoutSlot slot;
  final LayoutArea area;
  final LineView? lineView;
  final TimeCompassSlotLabelRadialAlignment labelRadialAlignment;

  /// Whether auto-flow reserves this slot's columns in every spanned row.
  final bool reserveSpannedRows;
}

class TimeCompassCenterSlot {
  const TimeCompassCenterSlot({
    required this.slot,
    required this.backgroundColor,
  });

  final LayoutSlot slot;
  final Color backgroundColor;
}

class TimeCompassGeometry {
  const TimeCompassGeometry({
    this.centerXFraction = 0.5,
    this.centerYFraction = 1,
    this.innerRadiusFraction = 0.12,
    this.outerRadiusFraction = 1,
    this.startAngleRadians = math.pi,
    this.sweepAngleRadians = math.pi,
    this.rotationRadians = 0,
  });

  final double centerXFraction;
  final double centerYFraction;
  final double innerRadiusFraction;
  final double outerRadiusFraction;
  final double startAngleRadians;
  final double sweepAngleRadians;

  /// Runtime rotation can update this value without changing segment topology.
  final double rotationRadians;
}

class TimeCompassLayout extends CompassLayout {
  const TimeCompassLayout.fromAxes({
    required super.axes,
    super.attributes,
    required super.mainSlot,
    required super.compassSlots,
    required super.compassGeometry,
    required super.compassSlotStyle,
    required this.layers,
    this.angularFractionCount = LayoutFraction.fullSpan,
    required this.geometry,
    required this.slotStyle,
    this.centerSlot,
    this.slots = const [],
    this.virtualColumnFractions = const [],
    this.virtualColumnStartRow = 1,
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.frame,
    super.slotConfigs,
    super.columnFractions,
    super.rowFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final List<LayoutSlot> layers;
  final double angularFractionCount;
  final TimeCompassGeometry geometry;
  final TimeCompassSlotStyle slotStyle;
  final TimeCompassCenterSlot? centerSlot;
  final List<TimeCompassSlot> slots;
  final List<double> virtualColumnFractions;
  final double virtualColumnStartRow;

  int get layerCount => layers.length;
  MeepleLayout get meepleLayout => mainSlot.subLayout as MeepleLayout;

  GuideGrid? guideGrid(GuideGridGeometry geometry) {
    for (final guide in layouts.values.whereType<LayoutGuide>()) {
      if (guide is GuideGrid && guide.geometry == geometry) return guide;
    }
    return null;
  }
}
