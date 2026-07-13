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

enum LayoutShape { rectangle, square, circle }

const randomBlueprintAesthetics = RandomBlueprintAesthetics();

class RandomBlueprintAesthetics {
  const RandomBlueprintAesthetics();

  PlaneLayoutStyle get layoutStyle {
    final random = math.Random();
    Color nextColor({double opacity = 0.82}) {
      return Color.fromARGB(
        (opacity.clamp(0, 1) * 255).round(),
        96 + random.nextInt(160),
        96 + random.nextInt(160),
        96 + random.nextInt(160),
      );
    }

    return PlaneLayoutStyle(
      borderStyle: GuideStyle(
        color: nextColor(),
        strokeWidth: 1,
        pattern: GuideLinePattern.dashed,
        dashLength: 7,
        dashInterval: 5,
      ),
      diagonalStyle: GuideStyle(
        color: nextColor(opacity: 0.68),
        strokeWidth: 0.9,
        pattern: GuideLinePattern.dashed,
        dashLength: 6,
        dashInterval: 6,
      ),
      centerLineStyle: GuideStyle(
        color: nextColor(opacity: 0.72),
        strokeWidth: 0.9,
        pattern: GuideLinePattern.dotted,
        dashInterval: 5,
      ),
      radiusStyle: GuideStyle(
        color: nextColor(opacity: 0.72),
        strokeWidth: 0.9,
        pattern: GuideLinePattern.dashed,
        dashLength: 6,
        dashInterval: 5,
      ),
      centerPointColor: nextColor(opacity: 0.95),
    );
  }
}

class PlaneLayoutStyle {
  const PlaneLayoutStyle({
    required this.borderStyle,
    this.diagonalStyle,
    this.centerLineStyle,
    this.radiusStyle,
    this.centerPointColor,
    this.centerPointRadius = 2.5,
  });

  final GuideStyle borderStyle;
  final GuideStyle? diagonalStyle;
  final GuideStyle? centerLineStyle;
  final GuideStyle? radiusStyle;
  final Color? centerPointColor;
  final double centerPointRadius;
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
    this.backgrounds = const [],
  });

  final String path;
  final LayoutColor color;
  final String? label;
  final int? status;
  final List<LayoutBackground> backgrounds;
}

@Deprecated('Use VaultNodeUiComponent for layout/UI config.')
typedef VaultNode = VaultNodeUiComponent;

class ResolvedVaultNode extends VaultNodeUiComponent {
  const ResolvedVaultNode({
    required super.path,
    super.color,
    super.label,
    super.status,
    super.backgrounds,
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
    super.modes,
  }) : super.fromAxes();

  final GuideStyle style;
  final bool visible;
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
    super.modes,
  });

  final GuideGridGeometry geometry;
  final bool drawColumns;
  final bool drawRows;
  final GuideGridRenderMode renderMode;
  final double intersectionSize;
}

enum LayoutCircleBoundary { inner, outer }

class CirleLayout extends LayoutGuide {
  const CirleLayout({
    required this.boundary,
    required super.style,
    super.visible,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.modes,
  });

  final LayoutCircleBoundary boundary;
}

abstract class LayoutDerivative {
  const LayoutDerivative();

  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]);
}

/// Selects geometry at resolution time using the current layout context.
///
/// This keeps conditional scene geometry in the derivative graph, so layouts
/// that reference the derivative automatically follow the selected branch.
class ConditionalDerivative extends LayoutDerivative {
  const ConditionalDerivative({
    required this.condition,
    required this.whenTrue,
    required this.whenFalse,
  });

  final LayoutCondition condition;
  final LayoutDerivative whenTrue;
  final LayoutDerivative whenFalse;

  @override
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
    final derivative = condition.isActive(context) ? whenTrue : whenFalse;
    return derivative.resolve(layout, size, context);
  }
}

class CircleRayIntersectionDerivative extends LayoutDerivative {
  const CircleRayIntersectionDerivative({
    required this.circle,
    required this.angleDegrees,
  });

  final LayoutCircleBoundary circle;

  /// Standard mathematical angle: 0° points right and positive angles rotate
  /// counterclockwise. The resolver converts the mathematical Y axis to
  /// Flutter's downward-positive screen Y axis.
  final double angleDegrees;

  @override
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
    final angle = angleDegrees * math.pi / 180;
    return layout.resolveCircleCenter(size, circle) +
        Offset(math.cos(angle), -math.sin(angle)) *
            layout.resolveCircleRadius(size, circle);
  }
}

class CircleCenterDerivative extends LayoutDerivative {
  const CircleCenterDerivative({required this.circle});

  final LayoutCircleBoundary circle;

  @override
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) => layout.resolveCircleCenter(size, circle);
}

class BoundsPointDerivative extends LayoutDerivative {
  const BoundsPointDerivative(this.position);

  final Offset position;

  @override
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
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
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
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
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
    final derivatives = layout.getDerivatives(snapshot, null, context).values;
    final fromDerivative = derivatives[from];
    final toDerivative = derivatives[to];
    if (fromDerivative == null || toDerivative == null) return Offset.zero;

    return Offset.lerp(
      fromDerivative.resolve(layout, size, context),
      toDerivative.resolve(layout, size, context),
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
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
    final resolved = _resolveShapePoints(
      layout,
      size,
      points,
      snapshot,
      context,
    );
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
  Offset resolve(
    Layout layout,
    Size size, [
    LayoutContext context = LayoutContext.empty,
  ]) {
    final resolved = _resolveShapePoints(
      layout,
      size,
      points,
      snapshot,
      context,
    );
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
  LayoutContext context,
) {
  final derivatives = layout.getDerivatives(snapshot, null, context).values;
  return [
    for (final point in points)
      if (derivatives[point] case final derivative?)
        derivative.resolve(layout, size, context),
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
        angleDegrees: 90,
      ),
      'circleRight': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 0,
      ),
      'circleBottom': CircleRayIntersectionDerivative(
        circle: LayoutCircleBoundary.outer,
        angleDegrees: 270,
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

class LayoutMode {
  const LayoutMode({
    required this.id,
    this.aliases = const [],
    this.activeCondition,
    this.visible = true,
    this.derivativeSnapshot,
    this.derivatives = const {},
  });

  final String id;
  final List<String> aliases;

  /// Modes are inactive by default. A mode applies only when this condition
  /// evaluates true for the current layout context.
  final LayoutCondition? activeCondition;
  final bool visible;
  final String? derivativeSnapshot;
  final Map<String, LayoutDerivative> derivatives;

  bool isActive(LayoutContext context) {
    return activeCondition?.isActive(context) ?? false;
  }
}

class LayoutContext {
  const LayoutContext({
    this.selectedMode,
    this.selectedNodePath,
    this.selectedNodePaths = const [],
    this.highlightedNodePaths = const [],
    this.currentNodePath,
    this.activeNodePaths = const [],
    this.layoutPath = const [],
  });

  static const empty = LayoutContext();

  final String? selectedMode;
  final String? selectedNodePath;
  final List<String> selectedNodePaths;
  final List<String> highlightedNodePaths;
  final String? currentNodePath;
  final List<String> activeNodePaths;
  final List<String> layoutPath;

  List<String> get resolvedActiveNodePaths {
    if (activeNodePaths.isNotEmpty) return activeNodePaths;
    final selected = selectedNodePath;
    return selected == null ? const [] : [selected];
  }

  LayoutContext withSelectedMode(String? mode) {
    return LayoutContext(
      selectedMode: selectedMode ?? mode,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      currentNodePath: currentNodePath,
      activeNodePaths: activeNodePaths,
      layoutPath: layoutPath,
    );
  }

  LayoutContext withCurrentNodePath(String? path) {
    return LayoutContext(
      selectedMode: selectedMode,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      currentNodePath: path,
      activeNodePaths: activeNodePaths,
      layoutPath: layoutPath,
    );
  }
}

abstract class LayoutCondition {
  const LayoutCondition._({this.exclude = const {}});

  factory LayoutCondition(
    bool Function(LayoutContext context) test, {
    Set<String> exclude = const {},
  }) {
    return LayoutPredicateCondition(test, exclude: exclude);
  }

  static const never = LayoutNeverCondition();

  const factory LayoutCondition.noSelectedNode() = NoSelectedNodesCondition;

  const factory LayoutCondition.nodeHighlighted({String? nodePath}) =
      LayoutNodeHighlightedCondition;

  const factory LayoutCondition.modeActive(
    String mode, {
    List<String> aliases,
  }) = LayoutModeActiveCondition;

  final Set<String> exclude;

  Set<String> get normalizedExclude => {
    for (final path in exclude) _normalizeLayoutPath(path),
  };

  bool isActive(LayoutContext context);
}

class LayoutPredicateCondition extends LayoutCondition {
  const LayoutPredicateCondition(this.test, {super.exclude = const {}})
    : super._();

  final bool Function(LayoutContext context) test;

  @override
  bool isActive(LayoutContext context) => test(context);
}

class LayoutNeverCondition extends LayoutCondition {
  const LayoutNeverCondition({super.exclude = const {}}) : super._();

  @override
  bool isActive(LayoutContext context) => false;
}

class LayoutSelectedModeCondition extends LayoutCondition {
  const LayoutSelectedModeCondition({
    required this.mode,
    this.aliases = const [],
    super.exclude = const {},
  }) : super._();

  final String mode;
  final List<String> aliases;

  @override
  bool isActive(LayoutContext context) {
    final selected = context.selectedMode;
    return selected == mode || aliases.contains(selected);
  }
}

class LayoutModeActiveCondition extends LayoutCondition {
  const LayoutModeActiveCondition(this.mode, {this.aliases = const []})
    : super._();

  final String mode;
  final List<String> aliases;

  @override
  bool isActive(LayoutContext context) {
    final selected = context.selectedMode;
    return selected == mode || aliases.contains(selected);
  }
}

class LayoutNodeHighlightedCondition extends LayoutCondition {
  const LayoutNodeHighlightedCondition({this.nodePath}) : super._();

  final String? nodePath;

  @override
  bool isActive(LayoutContext context) {
    final path = nodePath ?? context.currentNodePath;
    if (path == null) return false;
    final normalized = _normalizeLayoutPath(path);
    return context.highlightedNodePaths.any(
      (candidate) => _normalizeLayoutPath(candidate) == normalized,
    );
  }
}

class HasActiveNodesCondition extends LayoutCondition {
  const HasActiveNodesCondition({super.exclude = const {}}) : super._();

  @override
  bool isActive(LayoutContext context) {
    final excluded = normalizedExclude;
    return context.resolvedActiveNodePaths.any(
      (path) => !excluded.contains(_normalizeLayoutPath(path)),
    );
  }
}

class NoSelectedNodesCondition extends LayoutCondition {
  const NoSelectedNodesCondition({super.exclude = const {}}) : super._();

  @override
  bool isActive(LayoutContext context) => context.selectedNodePaths.isEmpty;
}

String _normalizeLayoutPath(String path) {
  return path
      .trim()
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceAll(RegExp(r'/+'), '/')
      .replaceFirst(RegExp(r'\.md$'), '')
      .replaceFirst(RegExp(r'^/+'), '')
      .replaceFirst(RegExp(r'/+$'), '');
}

class LayoutObservable {
  const LayoutObservable({required this.derivatives, this.epsilon = 0.001});

  final Set<String> derivatives;
  final double epsilon;
}

enum LayoutBackgroundFit { cover, contain, fill }

class LayoutBackground {
  const LayoutBackground({this.orderPosition = 0, this.opacity = 1});

  final int orderPosition;
  final double opacity;
}

class ConditionalLayoutBackground extends LayoutBackground {
  const ConditionalLayoutBackground({
    required this.activeCondition,
    required this.background,
    super.orderPosition,
    super.opacity,
  });

  final LayoutCondition activeCondition;
  final LayoutBackground background;
}

class LayoutBorderBackground extends LayoutBackground {
  const LayoutBorderBackground({
    required this.style,
    super.orderPosition,
    super.opacity,
  });

  final GuideStyle style;
}

class LayoutImageBackground extends LayoutBackground {
  const LayoutImageBackground({
    required this.assetPath,
    super.orderPosition,
    super.opacity,
    this.fit = LayoutBackgroundFit.cover,
    this.alignment = const Offset(0.5, 0.5),
  });

  final String assetPath;
  final LayoutBackgroundFit fit;
  final Offset alignment;
}

class LayoutGuidingBackground extends LayoutBackground {
  const LayoutGuidingBackground({
    required this.guides,
    super.orderPosition,
    super.opacity,
  });

  final List<LayoutBackgroundGuide> guides;
}

class LayoutBackgroundGuide {
  const LayoutBackgroundGuide({
    required this.start,
    required this.end,
    required this.style,
  });

  final Offset start;
  final Offset end;
  final GuideStyle style;
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

/// Shared ordered track contract for layouts that present content as a table.
///
/// Concrete layouts keep their own content model: radial areas remain radial,
/// while node-property fields remain node-property fields.
mixin TableLayoutMixin on Layout {
  Map<String, GridAxisVariable> get tableRowsConfig;
  Map<String, GridAxisVariable> get tableColumnsConfig;
  GuideStyle? get tableGuideStyle;
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
    super.modes,
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
    super.modes,
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

class RadialBushArea extends Layout {
  const RadialBushArea({
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
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.modes,
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
}

class RadialBushRoot {
  const RadialBushRoot({
    required this.size,
    required this.node,
    this.backgroundExtractor,
  });

  final GridAxisVariable size;
  final VaultNodeUiComponent node;
  final BackgroundExtractor? backgroundExtractor;
}

class BackgroundExtractor {
  const BackgroundExtractor({
    required this.rootParameter,
    this.colorParameters = const ['hex', 'color', 'background', 'aliases'],
  });

  final String rootParameter;
  final List<String> colorParameters;
}

class RadialBushBranch {
  const RadialBushBranch({required this.size, required this.rootParameter});

  final GridAxisVariable size;
  final String rootParameter;
}

class RadialBushElement {
  const RadialBushElement({required this.size});

  final GridAxisVariable size;
}

class RadialBushStructure {
  const RadialBushStructure({
    required this.root,
    this.branch,
    this.leaves,
    this.flowers,
    this.areas = const {},
  });

  static const rootRow = 'root';
  static const branchRow = 'branch';
  static const leavesRow = 'leaves';
  static const flowersRow = 'flowers';

  final RadialBushRoot root;
  final RadialBushBranch? branch;
  final RadialBushElement? leaves;
  final RadialBushElement? flowers;
  final Map<String, RadialBushArea> areas;

  Map<String, GridAxisVariable> get rowsConfig => {
    rootRow: root.size,
    if (branch case final branch?) branchRow: branch.size,
    if (leaves case final leaves?) leavesRow: leaves.size,
    if (flowers case final flowers?) flowersRow: flowers.size,
  };
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
    super.modes,
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

class RadialBushLayout extends Layout with TableLayoutMixin {
  const RadialBushLayout({
    required this.style,
    required this.bushStructure,
    this.label,
    this.labelColor = const Color(0xFFFFFFFF),
    this.labelSize = 12,
    this.layoutSize = const LayoutSize.px(20),
    this.position = LayoutRelativePosition.top,
    this.growthDirection,
    this.gridStyle,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.modes,
  }) : super.fromAxes();

  final String? label;
  final Color labelColor;
  final double labelSize;
  final LayoutSize layoutSize;
  final LayoutRelativePosition position;
  final LayoutDerivativeReference? growthDirection;
  final RadialBushStructure bushStructure;
  final GuideStyle? gridStyle;
  final GuideStyle style;

  @override
  Map<String, GridAxisVariable> get tableRowsConfig => bushStructure.rowsConfig;

  @override
  Map<String, GridAxisVariable> get tableColumnsConfig => const {};

  @override
  GuideStyle? get tableGuideStyle => gridStyle;

  VaultNodeUiComponent get rootNode => bushStructure.root.node;
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
    super.modes,
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
    super.modes,
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
    super.modes,
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
    super.modes,
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
    this.shape = LayoutShape.circle,
    this.style,
    this.position = const Offset(0.5, 0.5),
    this.radiusFraction = 0.5,
    this.padding = 0,
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
    super.layouts,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.modes,
    super.layoutDefaults,
  }) : super.fromAxes();

  final VaultNodeUiComponent? node;
  final LayoutShape shape;
  final PlaneLayoutStyle? style;
  final Offset position;
  final double radiusFraction;
  final double padding;
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
    super.padding,
    super.style,
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
    super.shape,
    super.modes,
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
    super.modes,
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
    super.modes,
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
    this.backgrounds = const [],
    this.layouts = const {},
    this.derivatives = const {},
    this.derivativeSnapshot,
    this.observables = const {},
    this.modes = const {},
    this.layoutDefaults,
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
  final List<LayoutBackground> backgrounds;

  /// Recursive layout tree. Map keys are the child layouts' identities.
  final Map<String, Layout> layouts;
  final Map<String, LayoutDerivativeSnapshot> derivatives;
  final String? derivativeSnapshot;
  final Map<String, LayoutObservable> observables;
  final Map<String, LayoutMode> modes;
  final LayoutDefaults? layoutDefaults;
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

  Offset get center => const Offset(0.5, 0.5);

  /// The outer circle circumscribes the layout's full rectangular bounds.
  /// The inner circle is inscribed in the bounds remaining after layout
  /// padding and border width are applied.
  Offset resolveCircleCenter(
    Size size,
    LayoutCircleBoundary boundary, {
    bool useLayoutDefaults = false,
  }) {
    final inset = boundary == LayoutCircleBoundary.inner || useLayoutDefaults
        ? _circleInset(size)
        : 0.0;
    return Offset(
      inset + math.max(size.width - inset * 2, 0) / 2,
      inset + math.max(size.height - inset * 2, 0) / 2,
    );
  }

  double resolveCircleRadius(
    Size size,
    LayoutCircleBoundary boundary, {
    bool useLayoutDefaults = false,
  }) {
    final inset = boundary == LayoutCircleBoundary.inner || useLayoutDefaults
        ? _circleInset(size)
        : 0.0;
    final width = math.max(size.width - inset * 2, 0);
    final height = math.max(size.height - inset * 2, 0);
    if (boundary == LayoutCircleBoundary.outer) {
      return math.sqrt(width * width + height * height) / 2;
    }
    return math.min(width, height) / 2;
  }

  Rect resolveCircleBounds(Size size, LayoutCircleBoundary boundary) {
    final radius = resolveCircleRadius(size, boundary);
    return Rect.fromCircle(
      center: resolveCircleCenter(size, boundary),
      radius: radius,
    );
  }

  double _circleInset(Size size) {
    final requestedInset =
        (layoutDefaults?.padding ?? 0) + (layoutDefaults?.borderWidth ?? 0);
    return requestedInset.clamp(0, size.shortestSide / 2).toDouble();
  }

  LayoutMode? getMode(String? mode) {
    if (mode == null) return null;
    final direct = modes[mode];
    if (direct != null) return direct;
    for (final candidate in modes.values) {
      if (candidate.id == mode || candidate.aliases.contains(mode)) {
        return candidate;
      }
    }
    return null;
  }

  LayoutMode? resolveMode(LayoutContext context) {
    final requestedMode = getMode(context.selectedMode);
    if (requestedMode != null) {
      return requestedMode.isActive(context) ? requestedMode : null;
    }
    for (final candidate in modes.values) {
      if (candidate.isActive(context)) return candidate;
    }
    return null;
  }

  bool isVisible(LayoutContext context) =>
      resolveMode(context)?.visible ?? true;

  LayoutDerivativeSnapshot getDerivatives([
    String? snapshot,
    String? mode,
    LayoutContext context = LayoutContext.empty,
  ]) {
    final layoutContext = context.withSelectedMode(mode);
    final selectedMode = resolveMode(layoutContext);
    final selectedSnapshot =
        snapshot ?? selectedMode?.derivativeSnapshot ?? derivativeSnapshot;
    final selected = selectedSnapshot == null
        ? LayoutDerivativeSnapshot.empty
        : derivatives[selectedSnapshot] ?? LayoutDerivativeSnapshot.empty;
    return LayoutDerivativeSnapshot(
      values: {
        for (final attribute in attributes) ...attribute.derivatives,
        ...selected.values,
        ...?selectedMode?.derivatives,
      },
    );
  }

  Map<String, Offset> resolveDerivatives(
    Size size, [
    String? snapshot,
    String? mode,
    LayoutContext context = LayoutContext.empty,
  ]) {
    return {
      for (final entry in getDerivatives(
        snapshot,
        mode,
        context,
      ).values.entries)
        entry.key: entry.value.resolve(this, size, context),
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
    super.modes,
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
    super.modes,
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
    super.modes,
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
