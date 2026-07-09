import 'dart:math' as math;
import 'dart:ui';

import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';

typedef SubLayout = ({Layout layout, LayoutArea area});

abstract final class LayoutKey {
  static const innerBorder = 'inner-border';
}

enum LayoutAttribute {
  screen,
  rectangular,
  circular,
  triangular,
  linear,
  safeArea,
}

abstract final class LayoutFraction {
  /// Consumes the fraction span left after all fixed fractions are allocated.
  static const fullSpan = double.infinity;
}

abstract final class CoordAlias {
  static const horizontal = 'horizontal';
  static const vertical = 'vertical';
  static const depth = 'depth';
  static const diagonal = 'diagonal';
  static const angle = 'angle';
  static const radius = 'radius';
  static const weight = 'weight';
}

enum CoordUnit { fraction, pixels, track, scalar, degrees, radians }

enum CoordRule { fromStart, fromCenter, fromEnd }

class Coord {
  const Coord(
    this.value, {
    this.unit = CoordUnit.fraction,
    this.rule = CoordRule.fromStart,
  });

  const Coord.fraction(this.value, {this.rule = CoordRule.fromStart})
    : unit = CoordUnit.fraction;

  const Coord.pixels(this.value, {this.rule = CoordRule.fromStart})
    : unit = CoordUnit.pixels;

  const Coord.scalar(this.value)
    : unit = CoordUnit.scalar,
      rule = CoordRule.fromStart;

  final double value;
  final CoordUnit unit;
  final CoordRule rule;

  double resolve({required double extent, int trackCount = 1}) {
    final magnitude = switch (unit) {
      CoordUnit.fraction => extent * value,
      CoordUnit.pixels => value,
      CoordUnit.track => trackCount <= 0 ? 0.0 : extent * value / trackCount,
      CoordUnit.scalar || CoordUnit.degrees || CoordUnit.radians => value,
    };
    return switch (rule) {
      CoordRule.fromStart => magnitude,
      CoordRule.fromCenter => extent / 2 + magnitude,
      CoordRule.fromEnd => extent - magnitude,
    };
  }
}

class Point {
  const Point({required this.id, required this.coordinates});

  final String id;
  final Map<String, Coord> coordinates;

  Coord? operator [](String alias) => coordinates[alias];

  Offset resolve(Rect frame) {
    final horizontal = coordinates[CoordAlias.horizontal];
    final vertical = coordinates[CoordAlias.vertical];
    return Offset(
      frame.left + (horizontal?.resolve(extent: frame.width) ?? 0),
      frame.top + (vertical?.resolve(extent: frame.height) ?? 0),
    );
  }
}

enum PointConnectionKind { straight, curved }

enum PointCurveSide { top, right, bottom, left }

class PointConnection {
  const PointConnection({
    required this.from,
    required this.to,
    this.kind = PointConnectionKind.straight,
    this.curveSide,
  });

  final String from;
  final String to;
  final PointConnectionKind kind;
  final PointCurveSide? curveSide;
}

enum GuideLinePattern { solid, dashed, dotted }

enum GuideGridRenderMode { lines, intersections }

enum GuideGridGeometry { cartesian, radial, radialVirtual }

class LayoutConfig {
  const LayoutConfig({this.backgroundColor = const Color(0x00000000)});

  final Color backgroundColor;
}

class LayoutDefaults {
  const LayoutDefaults({this.padding = 0, this.gap = 0, this.borderWidth = 1});

  final double padding;
  final double gap;
  final double borderWidth;
}

class LayoutColor {
  const LayoutColor.fromHex(this.hex, {this.opacity = 1});

  final String hex;
  final double opacity;

  Color resolve() {
    final normalized = hex
        .trim()
        .replaceFirst(RegExp('^#'), '')
        .replaceFirst(RegExp('^0x', caseSensitive: false), '');
    final expanded = normalized.length == 3
        ? normalized.split('').map((digit) => '$digit$digit').join()
        : normalized;
    final argb = switch (expanded.length) {
      6 => 'FF$expanded',
      8 => expanded,
      _ => 'FF939393',
    };
    final value = int.tryParse(argb, radix: 16) ?? 0xFF939393;
    return Color(value).withValues(alpha: opacity.clamp(0, 1).toDouble());
  }
}

enum LayoutSizeUnit {
  pixels,
  percent,
  viewportWidth,
  viewportHeight,
  viewportMin,
  viewportMax,
  derivativeDistance,
}

class LayoutSize {
  const LayoutSize(this.amount, {this.unit = LayoutSizeUnit.pixels})
    : from = null,
      to = null;

  const LayoutSize.px(this.amount)
    : unit = LayoutSizeUnit.pixels,
      from = null,
      to = null;

  const LayoutSize.percent(this.amount)
    : unit = LayoutSizeUnit.percent,
      from = null,
      to = null;

  const LayoutSize.vw(this.amount)
    : unit = LayoutSizeUnit.viewportWidth,
      from = null,
      to = null;

  const LayoutSize.vh(this.amount)
    : unit = LayoutSizeUnit.viewportHeight,
      from = null,
      to = null;

  const LayoutSize.vmin(this.amount)
    : unit = LayoutSizeUnit.viewportMin,
      from = null,
      to = null;

  const LayoutSize.vmax(this.amount)
    : unit = LayoutSizeUnit.viewportMax,
      from = null,
      to = null;

  const LayoutSize.derivativeDistance({
    required this.from,
    required this.to,
    this.amount = 1,
  }) : unit = LayoutSizeUnit.derivativeDistance;

  final double amount;
  final LayoutSizeUnit unit;
  final LayoutDerivativeReference? from;
  final LayoutDerivativeReference? to;

  double resolve({required Size viewport, required Rect bounds}) {
    final value = switch (unit) {
      LayoutSizeUnit.pixels => amount,
      LayoutSizeUnit.percent => bounds.shortestSide * amount / 100,
      LayoutSizeUnit.viewportWidth => viewport.width * amount / 100,
      LayoutSizeUnit.viewportHeight => viewport.height * amount / 100,
      LayoutSizeUnit.viewportMin => viewport.shortestSide * amount / 100,
      LayoutSizeUnit.viewportMax => viewport.longestSide * amount / 100,
      LayoutSizeUnit.derivativeDistance => amount,
    };
    return math.max(value, 0);
  }
}

abstract final class LayoutHttpStatus {
  static const ok = 200;
  static const noContent = 204;
  static const notFound = 404;
}

class VaultNodeUiComponent {
  const VaultNodeUiComponent({
    required this.path,
    this.color = const LayoutColor.fromHex('939393', opacity: 0.32),
    this.label,
    this.status,
  });

  final String path;
  final LayoutColor color;
  final String? label;
  final int? status;
}

@Deprecated('Use VaultNodeUiComponent for layout/UI config.')
typedef VaultNode = VaultNodeUiComponent;

class ResolvedVaultNode extends VaultNodeUiComponent {
  const ResolvedVaultNode({
    required super.path,
    super.color,
    super.label,
    super.status,
    required this.node,
    required this.note,
    required this.resolvedStatus,
  });

  final Node? node;
  final Note? note;
  final int resolvedStatus;

  bool get found => resolvedStatus == LayoutHttpStatus.ok;

  Color? get fillColor => switch (resolvedStatus) {
    LayoutHttpStatus.ok => color.resolve(),
    LayoutHttpStatus.noContent => color.resolve().withValues(alpha: 0.08),
    LayoutHttpStatus.notFound => null,
    _ => null,
  };
}

class LayoutRelativePosition {
  const LayoutRelativePosition.fraction(this.fraction)
    : directionDegrees = null;

  const LayoutRelativePosition.d(this.directionDegrees) : fraction = null;

  static const center = LayoutRelativePosition.fraction(Offset(0.5, 0.5));
  static const top = LayoutRelativePosition.fraction(Offset(0.5, 0));
  static const right = LayoutRelativePosition.fraction(Offset(1, 0.5));
  static const bottom = LayoutRelativePosition.fraction(Offset(0.5, 1));
  static const left = LayoutRelativePosition.fraction(Offset(0, 0.5));

  final Offset? fraction;
  final double? directionDegrees;

  Offset resolve(Rect bounds) {
    final position = fraction;
    if (position != null) {
      return Offset(
        bounds.left + bounds.width * position.dx.clamp(0.0, 1.0),
        bounds.top + bounds.height * position.dy.clamp(0.0, 1.0),
      );
    }

    final radians = (directionDegrees ?? 0) * math.pi / 180;
    final direction = Offset(math.cos(radians), math.sin(radians));
    final center = bounds.center;
    final tx = direction.dx == 0
        ? double.infinity
        : ((direction.dx > 0 ? bounds.right : bounds.left) - center.dx) /
              direction.dx;
    final ty = direction.dy == 0
        ? double.infinity
        : ((direction.dy > 0 ? bounds.bottom : bounds.top) - center.dy) /
              direction.dy;
    final distance = math.min(tx.abs(), ty.abs());
    return center + direction * distance;
  }
}

class GuideStyle {
  const GuideStyle({
    required this.color,
    this.strokeWidth = 1,
    this.pattern = GuideLinePattern.solid,
    this.dashLength = 7,
    this.dashInterval = 5,
    this.strokeCap = StrokeCap.round,
  });

  final Color color;
  final double strokeWidth;
  final GuideLinePattern pattern;
  final double dashLength;
  final double dashInterval;
  final StrokeCap strokeCap;
}

abstract class LayoutGuide extends Layout {
  const LayoutGuide({
    required this.style,
    this.visible = true,
    super.aliases,
    super.attributes,
  }) : super.fromAxes();

  final GuideStyle style;
  final bool visible;
}

abstract class GuidelineDerivative {
  const GuidelineDerivative();

  Offset resolve(Guideline guideline, Size size);
}

class GuidelineFractionDerivative extends GuidelineDerivative {
  const GuidelineFractionDerivative(this.fraction);

  final double fraction;

  @override
  Offset resolve(Guideline guideline, Size size) {
    final start = Offset(
      size.width * guideline.start.dx,
      size.height * guideline.start.dy,
    );
    final end = Offset(
      size.width * guideline.end.dx,
      size.height * guideline.end.dy,
    );
    return Offset.lerp(start, end, fraction.clamp(0, 1))!;
  }
}

class GuidelineMarker {
  const GuidelineMarker({
    required this.derivative,
    required this.label,
    this.fontSize = 18,
    this.color = const Color(0xFFFFFFFF),
    this.offset = Offset.zero,
  });

  final String derivative;
  final String label;
  final double fontSize;
  final Color color;
  final Offset offset;
}

class Guideline extends LayoutGuide {
  const Guideline({
    required this.start,
    required this.end,
    required super.style,
    super.visible,
    this.showArrow = false,
    this.arrowSize = 12,
    this.guidelineDerivatives = const {},
    this.markers = const [],
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
  });

  final Offset start;
  final Offset end;
  final bool showArrow;
  final double arrowSize;
  final Map<String, GuidelineDerivative> guidelineDerivatives;
  final List<GuidelineMarker> markers;
}

class GuideGrid extends LayoutGuide {
  const GuideGrid({
    required super.style,
    super.visible,
    this.geometry = GuideGridGeometry.cartesian,
    this.drawColumns = true,
    this.drawRows = true,
    this.renderMode = GuideGridRenderMode.lines,
    this.intersectionSize = 2,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  });

  final GuideGridGeometry geometry;
  final bool drawColumns;
  final bool drawRows;
  final GuideGridRenderMode renderMode;
  final double intersectionSize;
}

class LayoutCircle {
  const LayoutCircle({
    this.center = const Offset(0.5, 0.5),
    required this.radiusFraction,
  });

  /// Center normalized against the owning layout's current bounds.
  final Offset center;

  /// Radius measured as a fraction of the layout's shortest side.
  final double radiusFraction;

  Offset resolveCenter(Size size, {LayoutDefaults? defaults}) {
    final inset = _resolveInset(size, defaults);
    final availableSize = Size(
      math.max(size.width - inset * 2, 0),
      math.max(size.height - inset * 2, 0),
    );
    return Offset(
      inset + center.dx * availableSize.width,
      inset + center.dy * availableSize.height,
    );
  }

  double resolveRadius(Size size, {LayoutDefaults? defaults}) {
    final inset = _resolveInset(size, defaults);
    return math.max(size.shortestSide - inset * 2, 0) * radiusFraction;
  }

  double _resolveInset(Size size, LayoutDefaults? defaults) {
    final requestedInset =
        (defaults?.padding ?? 0) + (defaults?.borderWidth ?? 0);
    return requestedInset.clamp(0, size.shortestSide / 2).toDouble();
  }
}

enum LayoutCircleBoundary { inner, outer }

class CirleLayout extends LayoutGuide {
  const CirleLayout({
    required this.boundary,
    required super.style,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
  });

  final LayoutCircleBoundary boundary;
}

abstract class LayoutDerivative {
  const LayoutDerivative();

  Offset resolve(Layout layout, Size size);
}

class CircleRayIntersectionDerivative extends LayoutDerivative {
  const CircleRayIntersectionDerivative({
    required this.circle,
    required this.angleDegrees,
  });

  final LayoutCircleBoundary circle;
  final double angleDegrees;

  @override
  Offset resolve(Layout layout, Size size) {
    final geometry = switch (circle) {
      LayoutCircleBoundary.inner => layout.innerCircle,
      LayoutCircleBoundary.outer => layout.outerCircle,
    };
    if (geometry == null) return Offset.zero;
    final defaults = switch (circle) {
      LayoutCircleBoundary.inner => layout.layoutDefaults,
      LayoutCircleBoundary.outer => null,
    };

    final angle = angleDegrees * math.pi / 180;
    return geometry.resolveCenter(size, defaults: defaults) +
        Offset(math.cos(angle), math.sin(angle)) *
            geometry.resolveRadius(size, defaults: defaults);
  }
}

class CircleCenterDerivative extends LayoutDerivative {
  const CircleCenterDerivative({required this.circle});

  final LayoutCircleBoundary circle;

  @override
  Offset resolve(Layout layout, Size size) {
    final geometry = switch (circle) {
      LayoutCircleBoundary.inner => layout.innerCircle,
      LayoutCircleBoundary.outer => layout.outerCircle,
    };
    if (geometry == null) return Offset.zero;
    final defaults = switch (circle) {
      LayoutCircleBoundary.inner => layout.layoutDefaults,
      LayoutCircleBoundary.outer => null,
    };
    return geometry.resolveCenter(size, defaults: defaults);
  }
}

class BoundsPointDerivative extends LayoutDerivative {
  const BoundsPointDerivative(this.position);

  final Offset position;

  @override
  Offset resolve(Layout layout, Size size) {
    return Offset(position.dx * size.width, position.dy * size.height);
  }
}

class PaddedBoundsPointDerivative extends LayoutDerivative {
  const PaddedBoundsPointDerivative({
    required this.position,
    required this.padding,
  });

  final Offset position;
  final double padding;

  @override
  Offset resolve(Layout layout, Size size) {
    final safePadding = padding.clamp(0, size.shortestSide / 2).toDouble();
    final paddedSize = Size(
      math.max(size.width - safePadding * 2, 0),
      math.max(size.height - safePadding * 2, 0),
    );
    return Offset(
      safePadding + position.dx * paddedSize.width,
      safePadding + position.dy * paddedSize.height,
    );
  }
}

class MidpointDerivative extends LayoutDerivative {
  const MidpointDerivative({
    required this.from,
    required this.to,
    this.snapshot,
  });

  final String from;
  final String to;
  final String? snapshot;

  @override
  Offset resolve(Layout layout, Size size) {
    final derivatives = layout.getDerivatives(snapshot).values;
    final fromDerivative = derivatives[from];
    final toDerivative = derivatives[to];
    if (fromDerivative == null || toDerivative == null) return Offset.zero;

    return Offset.lerp(
      fromDerivative.resolve(layout, size),
      toDerivative.resolve(layout, size),
      0.5,
    )!;
  }
}

enum ShapeCircleDerivativePoint { center, top, right, bottom, left }

class ShapeCircleDerivative extends LayoutDerivative {
  const ShapeCircleDerivative({
    required this.points,
    required this.point,
    this.snapshot,
  });

  final List<String> points;
  final ShapeCircleDerivativePoint point;
  final String? snapshot;

  @override
  Offset resolve(Layout layout, Size size) {
    final resolved = _resolveShapePoints(layout, size, points, snapshot);
    if (resolved.isEmpty) return Offset.zero;
    final bounds = _boundsForPoints(resolved);
    final center = bounds.center;
    final radius = math.max(bounds.width, bounds.height) / 2;
    return switch (point) {
      ShapeCircleDerivativePoint.center => center,
      ShapeCircleDerivativePoint.top => center + Offset(0, -radius),
      ShapeCircleDerivativePoint.right => center + Offset(radius, 0),
      ShapeCircleDerivativePoint.bottom => center + Offset(0, radius),
      ShapeCircleDerivativePoint.left => center + Offset(-radius, 0),
    };
  }
}

enum ShapeSquareDerivativePoint { center, A, B, C, D }

class ShapeSquareDerivative extends LayoutDerivative {
  const ShapeSquareDerivative({
    required this.points,
    required this.point,
    this.snapshot,
  });

  final List<String> points;
  final ShapeSquareDerivativePoint point;
  final String? snapshot;

  @override
  Offset resolve(Layout layout, Size size) {
    final resolved = _resolveShapePoints(layout, size, points, snapshot);
    if (resolved.isEmpty) return Offset.zero;
    final bounds = _boundsForPoints(resolved);
    final center = bounds.center;
    final halfSide = math.max(bounds.width, bounds.height) / 2;
    return switch (point) {
      ShapeSquareDerivativePoint.center => center,
      ShapeSquareDerivativePoint.A => center + Offset(-halfSide, halfSide),
      ShapeSquareDerivativePoint.B => center + Offset(-halfSide, -halfSide),
      ShapeSquareDerivativePoint.C => center + Offset(halfSide, -halfSide),
      ShapeSquareDerivativePoint.D => center + Offset(halfSide, halfSide),
    };
  }
}

List<Offset> _resolveShapePoints(
  Layout layout,
  Size size,
  List<String> points,
  String? snapshot,
) {
  final derivatives = layout.getDerivatives(snapshot).values;
  return [
    for (final point in points)
      if (derivatives[point] case final derivative?)
        derivative.resolve(layout, size),
  ];
}

Rect _boundsForPoints(List<Offset> points) {
  var minX = points.first.dx;
  var maxX = points.first.dx;
  var minY = points.first.dy;
  var maxY = points.first.dy;
  for (final point in points.skip(1)) {
    minX = math.min(minX, point.dx);
    maxX = math.max(maxX, point.dx);
    minY = math.min(minY, point.dy);
    maxY = math.max(maxY, point.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

extension LayoutAttributeDerivatives on LayoutAttribute {
  Map<String, LayoutDerivative> get derivatives => switch (this) {
    LayoutAttribute.screen ||
    LayoutAttribute.rectangular ||
    LayoutAttribute.safeArea => const {
      'center': BoundsPointDerivative(Offset(0.5, 0.5)),
      'topLeft': BoundsPointDerivative(Offset(0, 0)),
      'topRight': BoundsPointDerivative(Offset(1, 0)),
      'bottomRight': BoundsPointDerivative(Offset(1, 1)),
      'bottomLeft': BoundsPointDerivative(Offset(0, 1)),
      'A': BoundsPointDerivative(Offset(0, 1)),
      'B': BoundsPointDerivative(Offset(0, 0)),
      'C': BoundsPointDerivative(Offset(1, 0)),
      'D': BoundsPointDerivative(Offset(1, 1)),
    },
    LayoutAttribute.circular => const {
      'center': BoundsPointDerivative(Offset(0.5, 0.5)),
      'circleTop': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 270,
      ),
      'circleRight': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 0,
      ),
      'circleBottom': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 90,
      ),
      'circleLeft': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 180,
      ),
    },
    LayoutAttribute.triangular => const {
      'center': BoundsPointDerivative(Offset(0.5, 0.5)),
      'triangleTop': BoundsPointDerivative(Offset(0.5, 0)),
      'triangleBottomRight': BoundsPointDerivative(Offset(1, 1)),
      'triangleBottomLeft': BoundsPointDerivative(Offset(0, 1)),
    },
    LayoutAttribute.linear => const {
      'start': BoundsPointDerivative(Offset(0, 0.5)),
      'midpoint': BoundsPointDerivative(Offset(0.5, 0.5)),
      'end': BoundsPointDerivative(Offset(1, 0.5)),
    },
  };
}

class LayoutDerivativeSnapshot {
  const LayoutDerivativeSnapshot({required this.values});

  final Map<String, LayoutDerivative> values;

  static const empty = LayoutDerivativeSnapshot(values: {});
}

class LayoutObservable {
  const LayoutObservable({required this.derivatives, this.epsilon = 0.001});

  final Set<String> derivatives;
  final double epsilon;
}

enum LayoutBackgroundFit { cover, contain, fill }

class LayoutBackgroundElement extends Layout {
  const LayoutBackgroundElement({
    required this.assetPath,
    required this.orderPosition,
    this.fit = LayoutBackgroundFit.cover,
    this.opacity = 1,
    this.alignment = const Offset(0.5, 0.5),
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.innerCircle,
    super.outerCircle,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  }) : super.fromAxes();

  final String assetPath;
  final int orderPosition;
  final LayoutBackgroundFit fit;
  final double opacity;
  final Offset alignment;
}

class LayoutPathStyle {
  const LayoutPathStyle({
    required this.fillColor,
    this.strokeStyle,
    this.close = true,
  });

  final Color fillColor;
  final GuideStyle? strokeStyle;
  final bool close;
}

class LayoutDerivativeReference {
  const LayoutDerivativeReference({
    this.layoutPath = const [],
    required this.derivative,
    this.snapshot,
  });

  final List<String> layoutPath;
  final String derivative;
  final String? snapshot;
}

class LayoutPathTickStyle {
  const LayoutPathTickStyle({
    required this.edgeStartIndex,
    required this.edgeEndIndex,
    required this.count,
    required this.style,
    this.lengthFraction = 0.08,
    this.insetFraction = 0,
  });

  /// Point index where the ticked edge starts in [LayoutPath.points].
  final int edgeStartIndex;

  /// Point index where the ticked edge ends in [LayoutPath.points].
  final int edgeEndIndex;
  final int count;
  final GuideStyle style;

  /// Tick length measured as a fraction of the shortest screen side.
  final double lengthFraction;

  /// Moves ticks inward from both edge ends.
  final double insetFraction;
}

class LayoutPathPadding {
  const LayoutPathPadding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  const LayoutPathPadding.all(double value)
    : left = value,
      top = value,
      right = value,
      bottom = value;

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool get isEmpty => left <= 0 && top <= 0 && right <= 0 && bottom <= 0;
}

enum GridTrackUnit { fraction, pixels, calculatedFraction }

class GridTrackSize {
  const GridTrackSize.fr(this.value)
    : unit = GridTrackUnit.fraction,
      derivative = null;

  const GridTrackSize.px(this.value)
    : unit = GridTrackUnit.pixels,
      derivative = null;

  const GridTrackSize.pt(this.value)
    : unit = GridTrackUnit.pixels,
      derivative = null;

  const GridTrackSize.calculatedFr(this.value, {required this.derivative})
    : unit = GridTrackUnit.calculatedFraction;

  final double value;
  final GridTrackUnit unit;
  final String? derivative;
}

class GridAxisVariable {
  const GridAxisVariable({required this.size, this.aliases = const []});

  final GridTrackSize size;
  final List<String> aliases;
}

abstract final class GridSpan {
  static const full = double.infinity;
}

class PerspectiveGridArea extends Layout {
  const PerspectiveGridArea({
    required this.row,
    required this.column,
    this.rowOffset = 0,
    this.columnOffset = 0,
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.node,
    this.defaultPath,
    this.fillColor,
    this.borderStyle,
    this.label,
    this.labelColor = const Color(0xFFFFFFFF),
    this.labelSize = 12,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  }) : super.fromAxes();

  final String row;
  final String column;
  final double rowOffset;
  final double columnOffset;
  final double rowSpan;
  final double columnSpan;
  final VaultNodeUiComponent? node;
  final String? defaultPath;
  final Color? fillColor;
  final GuideStyle? borderStyle;
  final String? label;
  final Color labelColor;
  final double labelSize;
}

class PerspectiveGridLayout extends Layout {
  const PerspectiveGridLayout({
    required this.rowsConfig,
    required this.columnsConfig,
    required this.guideStyle,
    this.areas = const {},
    this.topStartIndex = 1,
    this.topEndIndex = 2,
    this.bottomStartIndex = 0,
    this.bottomEndIndex = 3,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  }) : super.fromAxes();

  final Map<String, GridAxisVariable> rowsConfig;
  final Map<String, GridAxisVariable> columnsConfig;
  final Map<String, PerspectiveGridArea> areas;
  final GuideStyle guideStyle;

  /// Edge used as the spatial top of the perspective grid.
  final int topStartIndex;
  final int topEndIndex;

  /// Edge used as the spatial bottom of the perspective grid.
  final int bottomStartIndex;
  final int bottomEndIndex;
}

enum TableLayoutDataSource { baseNodeInfo }

enum TableOrphanOrdering { asConfigured, keyAlphabetical, valueAlphabetical }

class TablePropertyBuilder {
  const TablePropertyBuilder({
    this.groups = const [],
    this.orphanOrdering = TableOrphanOrdering.valueAlphabetical,
    required this.properties,
  });

  final List<TableGroup> groups;
  final TableOrphanOrdering orphanOrdering;
  final List<TableProperty> properties;
}

class TableGroup {
  const TableGroup({required this.id, required this.label});

  final String id;
  final String label;
}

class TableProperty {
  const TableProperty({
    required this.key,
    required this.size,
    this.label,
    this.groupId,
  });

  final String key;
  final GridAxisVariable size;
  final String? label;
  final String? groupId;
}

class TableCellHighlightConfig {
  const TableCellHighlightConfig({
    this.rows = false,
    this.columns = false,
    this.color = const Color(0x33FFF7D6),
  });

  final bool rows;
  final bool columns;
  final Color color;
}

class TableLayout extends Layout {
  const TableLayout({
    required this.columns,
    required this.dataSource,
    required this.guideStyle,
    this.propertyBuilder,
    this.padding = 12,
    this.cellHighlight,
    this.labelColor = const Color(0xFFE5E7EB),
    this.valueColor = const Color(0xFFFFFFFF),
    this.labelSize = 11,
    this.valueSize = 11,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  }) : super.fromAxes();

  final List<MapEntry<String, GridAxisVariable>> columns;
  final TableLayoutDataSource dataSource;
  final GuideStyle guideStyle;
  final TablePropertyBuilder? propertyBuilder;
  final double padding;
  final TableCellHighlightConfig? cellHighlight;
  final Color labelColor;
  final Color valueColor;
  final double labelSize;
  final double valueSize;
}

class RadialTreeArea extends Layout {
  const RadialTreeArea({
    required this.row,
    required this.column,
    this.rowOffset = 0,
    this.columnOffset = 0,
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.node,
    this.fillColor,
    this.borderStyle,
    this.label,
    this.labelColor = const Color(0xFFFFFFFF),
    this.labelSize = 11,
    this.segments = const {},
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
  }) : super.fromAxes();

  final String row;
  final String column;
  final double rowOffset;
  final double columnOffset;
  final double rowSpan;
  final double columnSpan;
  final VaultNodeUiComponent? node;
  final Color? fillColor;
  final GuideStyle? borderStyle;
  final String? label;
  final Color labelColor;
  final double labelSize;

  /// Optional sub-segments for the next tree depth inside this radial area.
  final Map<String, RadialTreeArea> segments;
}

class LayoutPath extends Layout {
  const LayoutPath({
    required this.points,
    this.style,
    this.ticks,
    this.grid,
    this.padding = 0,
    this.pathPadding,
    this.pointDerivatives = const {'A': 0, 'B': 1, 'C': 2, 'D': 3},
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.innerCircle,
    super.outerCircle,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  }) : super.fromAxes();

  final List<LayoutDerivativeReference> points;
  final LayoutPathStyle? style;
  final LayoutPathTickStyle? ticks;
  final PerspectiveGridLayout? grid;
  final double padding;
  final LayoutPathPadding? pathPadding;
  final Map<String, int> pointDerivatives;

  LayoutPathPadding get resolvedPadding =>
      pathPadding ?? LayoutPathPadding.all(padding);
}

class RadialTreeLayout extends Layout {
  const RadialTreeLayout({
    required this.node,
    required this.style,
    this.label,
    this.labelColor = const Color(0xFFFFFFFF),
    this.labelSize = 12,
    this.layoutSize = const LayoutSize.px(20),
    this.position = LayoutRelativePosition.top,
    this.growthDirection,
    this.rowsConfig = const {},
    this.columnsConfig = const {},
    this.areas = const {},
    this.gridStyle,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
  }) : super.fromAxes();

  final VaultNodeUiComponent node;
  final String? label;
  final Color labelColor;
  final double labelSize;
  final LayoutSize layoutSize;
  final LayoutRelativePosition position;
  final LayoutDerivativeReference? growthDirection;
  final Map<String, GridAxisVariable> rowsConfig;
  final Map<String, GridAxisVariable> columnsConfig;
  final Map<String, RadialTreeArea> areas;
  final GuideStyle? gridStyle;
  final GuideStyle style;
}

class RayLayout extends LayoutGuide {
  const RayLayout({
    required this.start,
    required this.towards,
    required super.style,
    this.showArrow = true,
    this.arrowSize = 10,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
  });

  final LayoutDerivativeReference start;
  final LayoutDerivativeReference towards;
  final bool showArrow;
  final double arrowSize;
}

class LayoutPathAreaReference {
  const LayoutPathAreaReference({
    this.layoutPath = const [],
    required this.path,
    required this.area,
    this.position = LayoutRelativePosition.center,
  });

  final List<String> layoutPath;
  final String path;
  final String area;

  /// Position relative to the resolved target area.
  final LayoutRelativePosition position;
}

class LayoutAreaRayLayout extends LayoutGuide {
  const LayoutAreaRayLayout({
    required this.start,
    required this.towards,
    required super.style,
    this.showArrow = true,
    this.arrowSize = 10,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
  });

  final LayoutDerivativeReference start;
  final LayoutPathAreaReference towards;
  final bool showArrow;
  final double arrowSize;
}

class LayoutAreaToDerivativeRayLayout extends LayoutGuide {
  const LayoutAreaToDerivativeRayLayout({
    required this.start,
    required this.towards,
    required super.style,
    this.showArrow = true,
    this.arrowSize = 10,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
  });

  final LayoutPathAreaReference start;
  final LayoutDerivativeReference towards;
  final bool showArrow;
  final double arrowSize;
}

class StickmanLayout extends Layout {
  const StickmanLayout({
    required this.style,
    this.heightCm = 200,
    this.rangeStart = -0.1,
    this.rangeEnd = 1.1,
    this.centerX = 0.5,
    this.headRadius = 0.08,
    this.shoulderY = 0.28,
    this.hipY = 0.62,
    this.handY = 0.52,
    this.footY = 1,
    this.shoulderHalfWidth = 0.14,
    this.handHalfWidth = 0.24,
    this.footHalfWidth = 0.16,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
  }) : super.fromAxes();

  /// Logical body height. In this layout 1.0 vertical unit equals [heightCm].
  final double heightCm;

  /// Visible vertical range around the body. `0..1` is the actual figure.
  final double rangeStart;
  final double rangeEnd;
  final double centerX;
  final double headRadius;
  final double shoulderY;
  final double hipY;
  final double handY;
  final double footY;
  final double shoulderHalfWidth;
  final double handHalfWidth;
  final double footHalfWidth;
  final GuideStyle style;
}

class PlaneLayout extends Layout {
  const PlaneLayout({
    this.node,
    this.position = const Offset(0.5, 0.5),
    this.radiusFraction = 0.18,
    this.backgroundColor = const Color(0xFFFFFBEA),
    this.borderColor = const Color(0xAA303030),
    this.resolvedBorderColor = const Color(0xAA303030),
    this.borderWidth = 2,
    this.wrapPadding = 8,
    this.showGeometryGuides = true,
    this.geometryGuideStyle = const GuideStyle(
      color: Color(0x88303030),
      strokeWidth: 1,
      pattern: GuideLinePattern.dashed,
      dashLength: 4,
      dashInterval: 4,
    ),
    this.ringGuides = const [],
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
  }) : super.fromAxes();

  final VaultNodeUiComponent? node;
  final Offset position;
  final double radiusFraction;
  final Color backgroundColor;
  final Color borderColor;
  final Color resolvedBorderColor;
  final double borderWidth;
  final double wrapPadding;
  final bool showGeometryGuides;
  final GuideStyle geometryGuideStyle;
  final List<PlaneRingGuide> ringGuides;
}

class PlaneRingGuide {
  const PlaneRingGuide({required this.fraction, required this.style});

  /// 0 means the base plane radius; 1 means the available plane geometry radius.
  /// The plane wrap square is inscribed inside the farthest configured ring,
  /// and the node circle is inscribed inside that square.
  final double fraction;
  final GuideStyle style;
}

class SubjectNodeLayout extends PlaneLayout {
  const SubjectNodeLayout({
    super.node,
    super.position,
    super.radiusFraction,
    super.backgroundColor,
    super.borderColor,
    super.resolvedBorderColor,
    super.borderWidth,
    super.wrapPadding,
    super.showGeometryGuides,
    super.geometryGuideStyle,
    super.ringGuides,
    super.aliases,
    super.attributes,
  });
}

class GraphPreviewNode {
  const GraphPreviewNode({
    required this.id,
    required this.position,
    this.radius = 8,
    this.label,
  });

  /// Normalized position inside the owning scene frame.
  final String id;
  final Offset position;
  final double radius;
  final String? label;
}

class GraphPreviewEdge {
  const GraphPreviewEdge({required this.from, required this.to});

  final String from;
  final String to;
}

class GraphPreviewLayout extends Layout {
  const GraphPreviewLayout({
    required this.nodes,
    this.edges = const [],
    required this.nodeStyle,
    this.edgeStyle,
    this.fillColor = const Color(0xAAFFFFFF),
    this.labelColor = const Color(0xFFFFFFFF),
    this.labelSize = 10,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
  }) : super.fromAxes();

  final List<GraphPreviewNode> nodes;
  final List<GraphPreviewEdge> edges;
  final GuideStyle nodeStyle;
  final GuideStyle? edgeStyle;
  final Color fillColor;
  final Color labelColor;
  final double labelSize;
}

enum LayoutBorderShape { rectangle, square, circle }

enum LayoutBorderReference { bounds, innerCircle, outerCircle }

class LayoutBorderGuide extends LayoutGuide {
  const LayoutBorderGuide({
    required this.shape,
    required this.reference,
    required super.style,
    this.anchors = const [],
    this.derivativeAnchors = const [],
    this.anchorRadius = 2.5,
    this.labelFontSize = 11,
    this.showAnchorDirections = false,
    this.anchorDirectionLength = 14,
    this.useLayoutDefaults = false,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
  });

  final LayoutBorderShape shape;
  final LayoutBorderReference reference;
  final List<Point> anchors;
  final List<String> derivativeAnchors;
  final double anchorRadius;
  final double labelFontSize;
  final bool showAnchorDirections;
  final double anchorDirectionLength;
  final bool useLayoutDefaults;
}

class LayoutSlotStyle {
  const LayoutSlotStyle({
    required this.borderColor,
    this.strokeWidth = 2,
    this.dashLength = 7,
    this.gapLength = 5,
  });

  final Color borderColor;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
}

class LayoutSlot {
  const LayoutSlot({
    required this.id,
    required this.label,
    this.fraction,
    this.span,
    this.minWidth,
    this.maxWidth,
  });

  final String id;
  final String label;

  /// Flex weight on the slot container's main axis.
  final double? fraction;

  /// Preferred cross-axis width in the container's fraction units.
  final double? span;

  /// Minimum cross-axis width in the container's fraction units.
  final double? minWidth;

  /// Maximum cross-axis width in the container's fraction units.
  final double? maxWidth;
}

class LineView {
  const LineView({required this.segments});

  final List<LayoutSlot> segments;
}

class LayoutElement {
  const LayoutElement({
    required this.area,
    this.defaultPath,
    this.defaultLabel,
    this.slotStyle,
    this.borderRadius = 0,
  });

  final LayoutArea area;
  final String? defaultPath;
  final String? defaultLabel;
  final LayoutSlotStyle? slotStyle;
  final double borderRadius;
}

abstract class Layout {
  const Layout.fromAxes({
    this.axes = const [0, 0],
    this.aliases = const [],
    this.attributes = const [],
    this.layouts = const {},
    this.derivatives = const {},
    this.derivativeSnapshot,
    this.observables = const {},
    this.layoutDefaults,
    this.innerCircle,
    this.outerCircle,
    this.columnFractions,
    this.rowFractions,
    this.depthFractions,
    this.fractionSpans,
    this.subLayouts = const {},
    this.elements = const {},
  });

  final List<int> axes;
  final List<String> aliases;
  final List<LayoutAttribute> attributes;

  /// Recursive layout tree. Map keys are the child layouts' identities.
  final Map<String, Layout> layouts;
  final Map<String, LayoutDerivativeSnapshot> derivatives;
  final String? derivativeSnapshot;
  final Map<String, LayoutObservable> observables;
  final LayoutDefaults? layoutDefaults;
  final LayoutCircle? innerCircle;
  final LayoutCircle? outerCircle;
  final List<double>? columnFractions;
  final List<double>? rowFractions;
  final List<double>? depthFractions;
  final List<double>? fractionSpans;
  final Map<String, SubLayout> subLayouts;
  final Map<String, LayoutElement> elements;

  LayoutDimensions get dimensions => LayoutDimensions.fromAxes(
    axes,
    columnFractions: columnFractions,
    rowFractions: rowFractions,
    depthFractions: depthFractions,
    fractionSpans: fractionSpans,
  );

  int get dimensionCount => axes.length;

  /// The inner circle is the most specific center reference when both exist.
  Offset get center =>
      innerCircle?.center ?? outerCircle?.center ?? const Offset(0.5, 0.5);

  LayoutDerivativeSnapshot getDerivatives([String? snapshot]) {
    final selectedSnapshot = snapshot ?? derivativeSnapshot;
    final selected = selectedSnapshot == null
        ? LayoutDerivativeSnapshot.empty
        : derivatives[selectedSnapshot] ?? LayoutDerivativeSnapshot.empty;
    return LayoutDerivativeSnapshot(
      values: {
        for (final attribute in attributes) ...attribute.derivatives,
        ...selected.values,
      },
    );
  }

  Map<String, Offset> resolveDerivatives(Size size, [String? snapshot]) {
    return {
      for (final entry in getDerivatives(snapshot).values.entries)
        entry.key: entry.value.resolve(this, size),
    };
  }
}

class SceneLayout extends Layout {
  const SceneLayout.fromAxes({
    required super.axes,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.innerCircle,
    super.outerCircle,
    super.columnFractions,
    super.rowFractions,
    super.depthFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();
}

class GridLayout extends Layout {
  const GridLayout.fromAxes({
    required super.axes,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
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
}

class TrackLayout extends Layout {
  const TrackLayout.fromAxes({
    required super.axes,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.innerCircle,
    super.outerCircle,
    super.columnFractions,
    super.fractionSpans,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();
}

class LayoutDimensions {
  const LayoutDimensions.fromAxes(
    this.axes, {
    this.columnFractions,
    this.rowFractions,
    this.depthFractions,
    this.fractionSpans,
  });

  final List<int> axes;
  final List<double>? columnFractions;
  final List<double>? rowFractions;
  final List<double>? depthFractions;
  final List<double>? fractionSpans;

  int get dimensionCount => axes.length;

  int axis(int dimension) => axes[dimension];

  int get horizontal => axis(0);

  int get vertical => axis(1);

  int get depth => axis(2);

  double normalizedHorizontalPosition(num track) {
    return normalizedAxisPosition(0, track);
  }

  double normalizedVerticalPosition(num track) {
    return normalizedAxisPosition(1, track);
  }

  double axisWeight(int dimension) {
    final trackCount = axis(dimension);
    final fractions = _validFractionsFor(dimension);
    if (fractions == null) {
      return trackCount.toDouble();
    }
    final fullSpanWeight = _fullSpanWeight(dimension, fractions);
    return fractions.fold<double>(
      0,
      (sum, fraction) =>
          sum + _resolvedFractionWeight(fraction, fullSpanWeight),
    );
  }

  double normalizedAxisPosition(int dimension, num track) {
    final trackCount = axis(dimension);
    if (trackCount <= 0) return 0;
    final clampedTrack = track.clamp(0, trackCount);
    final fractions = _validFractionsFor(dimension);

    if (fractions == null) {
      return clampedTrack / trackCount;
    }

    final fullSpanWeight = _fullSpanWeight(dimension, fractions);
    final total = fractions.fold<double>(
      0,
      (sum, fraction) =>
          sum + _resolvedFractionWeight(fraction, fullSpanWeight),
    );
    if (total <= 0) return clampedTrack / trackCount;

    final wholeTracks = clampedTrack.floor();
    final partialTrack = clampedTrack - wholeTracks;
    var weightedPosition = 0.0;

    for (var index = 0; index < wholeTracks; index += 1) {
      weightedPosition += _resolvedFractionWeight(
        fractions[index],
        fullSpanWeight,
      );
    }
    if (wholeTracks < fractions.length && partialTrack > 0) {
      weightedPosition +=
          _resolvedFractionWeight(fractions[wholeTracks], fullSpanWeight) *
          partialTrack;
    }

    return (weightedPosition / total).clamp(0.0, 1.0);
  }

  List<double>? _fractionsFor(int dimension) {
    return switch (dimension) {
      0 => columnFractions,
      1 => rowFractions,
      2 => depthFractions,
      _ => null,
    };
  }

  List<double>? _validFractionsFor(int dimension) {
    final fractions = _fractionsFor(dimension);
    if (fractions == null || fractions.length != axis(dimension)) return null;
    return fractions;
  }

  double _fullSpanWeight(int dimension, List<double> fractions) {
    var fullSpanCount = 0;
    var fixedWeight = 0.0;
    for (final fraction in fractions) {
      if (fraction == LayoutFraction.fullSpan) {
        fullSpanCount += 1;
      } else {
        fixedWeight += _positiveFraction(fraction);
      }
    }
    if (fullSpanCount == 0) return 0;
    final configuredSpan =
        fractionSpans != null && dimension < fractionSpans!.length
        ? _positiveFraction(fractionSpans![dimension])
        : fixedWeight;
    final remainingWeight = configuredSpan > fixedWeight
        ? configuredSpan - fixedWeight
        : 0.0;
    return remainingWeight / fullSpanCount;
  }

  double _resolvedFractionWeight(double fraction, double fullSpanWeight) =>
      fraction == LayoutFraction.fullSpan
      ? fullSpanWeight
      : _positiveFraction(fraction);

  double _positiveFraction(double fraction) {
    return fraction.clamp(0, double.maxFinite).toDouble();
  }
}

class LayoutArea {
  // Named `column` remains public while its nullable source stays internal.
  const LayoutArea({
    num? column,
    required this.row,
    this.depth = 0,
    this.columnSpan = 1,
    this.rowSpan = 1,
    this.depthSpan = 0,
    // ignore: prefer_initializing_formals
  }) : _column = column;

  final num? _column;
  final num row;
  final num depth;
  final num columnSpan;
  final num rowSpan;
  final num depthSpan;

  /// Defaults to zero for layouts without auto-placement behavior.
  num get column => _column ?? 0;

  bool get hasExplicitColumn => _column != null;
}

class LayoutPoint {
  const LayoutPoint({required this.column, required this.row, this.depth = 0});

  final num column;
  final num row;
  final num depth;
}
