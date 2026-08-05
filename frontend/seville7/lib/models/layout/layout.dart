import 'dart:math' as math;
import 'dart:ui';

import 'package:seville_proto/seville_proto.dart'
    hide NodeSearchFilter, NodeSearchParameter;

part 'graph_traverse_type.dart';
part 'default_size.dart';
part 'label.dart';
part 'landscape_xl_layout.dart';
part 'layout_condition.dart';
part 'layout_snapshot.dart';
part 'layout_state.dart';
part 'node_config.dart';
part 'node_search.dart';
part 'panel.dart';
part 'find_layout.dart';
part 'table_config.dart';
part 'table_layout.dart';
part 'text.dart';

abstract class Layout {
  const Layout({
    LayoutSize? size,
    this.slot,
    this.aliases = const [],
    this.label = LabelDefaults.config,
    this.text = const LayoutTextConfig(),
    this.node = const NodeConfig(),
    this.panel = const PanelConfig(),
    this.state = const LayoutState(),
    this.attributes = const [],
    this.background = const [],
    this.children = const {},
    this.derivatives = const {},
    this.derivativeSnapshot,
    this.observables = const {},
    this.inputSources = LayoutInputSource.values,
    this.layoutPadding = 0,
    this.layoutGap = 0,
    this.layoutBorderWidth,
    this.inactiveNodeBackgroundOpacity = NodeDefaults.inactiveBackgroundOpacity,
    this.activeNodeBackgroundOpacity = NodeDefaults.activeBackgroundOpacity,
    this.virtualNodeBackgroundOpacity = NodeDefaults.virtualBackgroundOpacity,
  }) : _configuredSize = size,
       assert(slot == null || slot != ''),
       assert(layoutPadding >= 0),
       assert(layoutGap >= 0),
       assert(layoutBorderWidth == null || layoutBorderWidth >= 0),
       assert(
         inactiveNodeBackgroundOpacity >= 0 &&
             inactiveNodeBackgroundOpacity <= 1,
       ),
       assert(
         activeNodeBackgroundOpacity >= 0 && activeNodeBackgroundOpacity <= 1,
       ),
       assert(
         virtualNodeBackgroundOpacity >= 0 && virtualNodeBackgroundOpacity <= 1,
       );

  /// Size interpreted by the owning renderer.
  ///
  /// Row and column composition use the primary dimension as their main-axis
  /// track. Renderers that support two-dimensional items may additionally use
  /// [LayoutSize.secondary].
  final LayoutSize? _configuredSize;
  LayoutSize get size =>
      LayoutDefaultSize.mergeWith(const LayoutSize.fr(1), _configuredSize);

  /// Named area requested from the parent [GridLayout].
  ///
  /// When the parent defines this name in [GridLayout.slots], the grid places
  /// this layout in that area and does not use [size] for placement.
  final String? slot;
  final List<String> aliases;
  final LabelConfig label;
  final LayoutTextConfig text;
  final NodeConfig node;
  final PanelConfig panel;
  final LayoutState<LayoutConfig> state;
  final List<LayoutAttribute> attributes;
  final List<LayoutBackground> background;

  /// Recursive layout tree. Map keys are the children's identities.
  final Map<String, Layout> children;
  final Map<String, LayoutDerivativeSnapshot> derivatives;
  final String? derivativeSnapshot;
  final Map<String, LayoutObservable> observables;

  /// Input channels allowed to originate interactions with this layout.
  final List<LayoutInputSource> inputSources;
  final double layoutPadding;
  final double layoutGap;
  final double? layoutBorderWidth;
  final double inactiveNodeBackgroundOpacity;
  final double activeNodeBackgroundOpacity;
  final double virtualNodeBackgroundOpacity;

  bool supportsInputSource(LayoutInputSource source) =>
      inputSources.contains(source);

  /// Layout state specializes configuration without replacing tree structure.
  Layout resolve(LayoutContext context) => this;

  Iterable<LayoutConfig> _activeStateOverlays(LayoutContext context) sync* {
    for (final entry in state.values.entries) {
      if (!entry.key.isActive(context)) continue;
      yield entry.value;
      yield* entry.value.activeStateOverlays(context);
    }
  }

  LayoutSize resolveSize(LayoutContext context) {
    var resolved = size;
    for (final overlay in _activeStateOverlays(context)) {
      resolved = LayoutDefaultSize.mergeWith(resolved, overlay.size);
    }
    return resolved;
  }

  LayoutTextConfig resolveTextConfig(LayoutContext context) {
    var resolved = text;
    for (final overlay in _activeStateOverlays(context)) {
      if (overlay.text case final text?) resolved = resolved.merge(text);
    }
    return resolved;
  }

  List<LayoutBackground> resolveBackground(LayoutContext context) {
    var resolved = background;
    for (final overlay in _activeStateOverlays(context)) {
      resolved = overlay.background ?? resolved;
    }
    return resolved;
  }

  NodeConfig resolveNodeConfig(LayoutContext context) {
    var resolved = node.resolve(context);
    for (final overlay in _activeStateOverlays(context)) {
      if (overlay.node case final node?) {
        resolved = resolved.merge(node.resolve(context));
      }
    }
    return resolved;
  }

  Color get slugColor => node.slugColor ?? NodeDefaults.slugColor;
  Color get labelColor => node.labelColor ?? NodeDefaults.labelColor;
  Color get valueColor => node.valueColor ?? NodeDefaults.valueColor;
  LabelConfig resolveLabelConfig(LayoutContext context) {
    var resolved = label;
    for (final overlay in _activeStateOverlays(context)) {
      if (overlay.label case final label?) resolved = resolved.merge(label);
    }
    return resolved.resolve(context);
  }

  PanelConfig resolvePanelConfig(LayoutContext context) {
    var resolved = panel;
    for (final overlay in _activeStateOverlays(context)) {
      if (overlay.panel case final panel?) resolved = resolved.merge(panel);
    }
    return resolved;
  }

  Offset get center => const Offset(0.5, 0.5);

  /// The outer circle circumscribes the layout's full rectangular bounds.
  /// The inner circle is inscribed in the bounds remaining after layout
  /// padding and border width are applied.
  Offset resolveCircleCenter(
    Size size,
    LayoutCircleBoundary boundary, {
    bool useLayoutStyle = false,
  }) {
    final inset = boundary == LayoutCircleBoundary.inner || useLayoutStyle
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
    bool useLayoutStyle = false,
  }) {
    final inset = boundary == LayoutCircleBoundary.inner || useLayoutStyle
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
    final requestedInset = layoutPadding + (layoutBorderWidth ?? 0);
    return requestedInset.clamp(0, size.shortestSide / 2).toDouble();
  }

  bool isVisible(LayoutContext context) {
    final hasVisibilityState = state.values.values.any(
      (config) => config.hasVisibilityState,
    );
    if (!hasVisibilityState) return true;
    var visible = false;
    for (final overlay in _activeStateOverlays(context)) {
      visible = overlay.visible ?? visible;
    }
    return visible;
  }

  String formatNodeSlug(String slug) => node.formatSlug(slug);

  LayoutDerivativeSnapshot getDerivatives([
    String? snapshot,
    LayoutContext context = LayoutContext.empty,
  ]) {
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

  Map<String, Offset> resolveDerivatives(
    Size size, [
    String? snapshot,
    LayoutContext context = LayoutContext.empty,
  ]) {
    return {
      for (final entry in getDerivatives(snapshot, context).values.entries)
        entry.key: entry.value.resolve(this, size, context),
    };
  }
}

/// Conditional configuration overlaid onto a Layout at its stable tree key.
class LayoutConfig {
  const LayoutConfig({
    this.visible,
    this.size,
    this.label,
    this.text,
    this.node,
    this.panel,
    this.background,
    this.state = const LayoutState(),
  });

  final bool? visible;
  final LayoutSize? size;
  final LabelConfig? label;
  final LayoutTextConfig? text;
  final NodeConfig? node;
  final PanelConfig? panel;
  final List<LayoutBackground>? background;
  final LayoutState<LayoutConfig> state;

  bool get hasVisibilityState =>
      visible != null ||
      state.values.values.any((value) => value.hasVisibilityState);

  Iterable<LayoutConfig> activeStateOverlays(LayoutContext context) sync* {
    for (final entry in state.values.entries) {
      if (!entry.key.isActive(context)) continue;
      yield entry.value;
      yield* entry.value.activeStateOverlays(context);
    }
  }
}

/// Stable interaction channels, independent of specific hardware models.
enum LayoutInputSource {
  cursor,
  touch,
  stylus,
  keyboard,
  terminal,
  streamDeck,
  gameController,
}

class LayoutDerivativeSnapshot {
  const LayoutDerivativeSnapshot({required this.values});

  final Map<String, LayoutDerivative> values;

  static const empty = LayoutDerivativeSnapshot(values: {});
}

class LayoutContext {
  const LayoutContext({
    this.inputSource,
    this.findOpened = false,
    this.selectedNodePath,
    this.selectedNodePaths = const [],
    this.highlightedNodePaths = const [],
    this.labelHighlighted = false,
    this.currentLabel,
    this.currentNodePath,
    this.currentNodeSlug,
    this.currentNodeLabels = const [],
    this.activeNodeSlugs = const [],
    this.activeNodePaths = const [],
    this.activeNodeLabels = const [],
    this.layoutPath = const [],
    this.rootFontSize = LayoutTextDefaults.rootFontSize,
  });

  static const empty = LayoutContext();

  /// Source of the interaction currently being evaluated, when applicable.
  final LayoutInputSource? inputSource;
  final bool findOpened;
  final String? selectedNodePath;
  final List<String> selectedNodePaths;
  final List<String> highlightedNodePaths;
  final bool labelHighlighted;
  final String? currentLabel;
  final String? currentNodePath;
  final String? currentNodeSlug;
  final List<String> currentNodeLabels;
  final List<String> activeNodeSlugs;
  final List<String> activeNodePaths;
  final List<String> activeNodeLabels;
  final List<String> layoutPath;
  final double rootFontSize;

  List<String> get resolvedActiveNodePaths {
    if (activeNodePaths.isNotEmpty) return activeNodePaths;
    final selected = selectedNodePath;
    return selected == null ? const [] : [selected];
  }

  LayoutContext withCurrentNodePath(String? path) {
    return LayoutContext(
      inputSource: inputSource,
      findOpened: findOpened,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      labelHighlighted: labelHighlighted,
      currentLabel: currentLabel,
      currentNodePath: path,
      currentNodeSlug: currentNodeSlug,
      currentNodeLabels: currentNodeLabels,
      activeNodeSlugs: activeNodeSlugs,
      activeNodePaths: activeNodePaths,
      activeNodeLabels: activeNodeLabels,
      layoutPath: layoutPath,
      rootFontSize: rootFontSize,
    );
  }

  LayoutContext withLabelHighlighted(bool value) {
    return LayoutContext(
      inputSource: inputSource,
      findOpened: findOpened,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      labelHighlighted: value,
      currentLabel: currentLabel,
      currentNodePath: currentNodePath,
      currentNodeSlug: currentNodeSlug,
      currentNodeLabels: currentNodeLabels,
      activeNodeSlugs: activeNodeSlugs,
      activeNodePaths: activeNodePaths,
      activeNodeLabels: activeNodeLabels,
      layoutPath: layoutPath,
      rootFontSize: rootFontSize,
    );
  }

  LayoutContext withCurrentLabel(String? label) {
    return LayoutContext(
      inputSource: inputSource,
      findOpened: findOpened,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      labelHighlighted: labelHighlighted,
      currentLabel: label,
      currentNodePath: currentNodePath,
      currentNodeSlug: currentNodeSlug,
      currentNodeLabels: currentNodeLabels,
      activeNodeSlugs: activeNodeSlugs,
      activeNodePaths: activeNodePaths,
      activeNodeLabels: activeNodeLabels,
      layoutPath: layoutPath,
      rootFontSize: rootFontSize,
    );
  }

  LayoutContext withCurrentNode({
    String? path,
    String? slug,
    List<String> labels = const [],
  }) {
    return LayoutContext(
      inputSource: inputSource,
      findOpened: findOpened,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: highlightedNodePaths,
      labelHighlighted: labelHighlighted,
      currentLabel: currentLabel,
      currentNodePath: path,
      currentNodeSlug: slug,
      currentNodeLabels: labels,
      activeNodeSlugs: activeNodeSlugs,
      activeNodePaths: activeNodePaths,
      activeNodeLabels: activeNodeLabels,
      layoutPath: layoutPath,
      rootFontSize: rootFontSize,
    );
  }

  LayoutContext withHighlightedNodePath(String path) {
    return LayoutContext(
      inputSource: inputSource,
      findOpened: findOpened,
      selectedNodePath: selectedNodePath,
      selectedNodePaths: selectedNodePaths,
      highlightedNodePaths: [...highlightedNodePaths, path],
      labelHighlighted: labelHighlighted,
      currentLabel: currentLabel,
      currentNodePath: currentNodePath,
      currentNodeSlug: currentNodeSlug,
      currentNodeLabels: currentNodeLabels,
      activeNodeSlugs: activeNodeSlugs,
      activeNodePaths: activeNodePaths,
      activeNodeLabels: activeNodeLabels,
      layoutPath: layoutPath,
      rootFontSize: rootFontSize,
    );
  }
}

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

class TextTransform {
  const TextTransform.none() : _kind = _TextTransformKind.none;

  const TextTransform.uppercase() : _kind = _TextTransformKind.uppercase;

  const TextTransform.lowercase() : _kind = _TextTransformKind.lowercase;

  /// Presents both uppercase and lowercase characters as small capitals,
  /// equivalent to CSS `font-variant-caps: all-small-caps`.
  const TextTransform.capitalCap() : _kind = _TextTransformKind.capitalCap;

  final _TextTransformKind _kind;

  String apply(String value) => switch (_kind) {
    _TextTransformKind.none || _TextTransformKind.capitalCap => value,
    _TextTransformKind.uppercase => value.toUpperCase(),
    _TextTransformKind.lowercase => value.toLowerCase(),
  };

  List<FontFeature>? get fontFeatures => switch (_kind) {
    _TextTransformKind.capitalCap => const [
      FontFeature.enable('smcp'),
      FontFeature.enable('c2sc'),
    ],
    _ => null,
  };
}

enum _TextTransformKind { none, uppercase, lowercase, capitalCap }

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

abstract final class LayoutHttpStatus {
  static const ok = 200;
  static const noContent = 204;
  static const notFound = 404;
}

class VaultNode {
  const VaultNode({
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

class ResolvedVaultNode extends VaultNode {
  const ResolvedVaultNode({
    required super.path,
    super.color,
    super.label,
    super.status,
    super.backgrounds,
    required this.node,
    required this.resolvedStatus,
    required this.origin,
    this.isVirtual = false,
  });

  final Node? node;
  final int resolvedStatus;
  final ResolvedNodeOrigin origin;

  /// True while this Node exists only in frontend state and has not been
  /// created in the canonical graph store.
  final bool isVirtual;

  bool get found => resolvedStatus == LayoutHttpStatus.ok;

  Color? get fillColor => switch (resolvedStatus) {
    LayoutHttpStatus.ok => color.resolve(),
    LayoutHttpStatus.noContent => color.resolve().withValues(alpha: 0.08),
    LayoutHttpStatus.notFound => null,
    _ => null,
  };
}

enum ResolvedNodeSource { server, layout }

/// Identifies where a resolved Node came from and which Layout requested it.
class ResolvedNodeOrigin {
  const ResolvedNodeOrigin.server({required this.layoutPath})
    : source = ResolvedNodeSource.server;

  const ResolvedNodeOrigin.layout({required this.layoutPath})
    : source = ResolvedNodeSource.layout;

  final ResolvedNodeSource source;
  final List<String> layoutPath;

  String get layoutAddress => layoutPath.join('/');
}

class ResolvedNodeTree {
  const ResolvedNodeTree({required this.tree, required this.origin});

  final NodeTree tree;
  final ResolvedNodeOrigin origin;
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
    super.slot,
    super.aliases,
    super.attributes,
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super();

  final GuideStyle style;
  final bool visible;
}

enum LayoutCircleBoundary { inner, outer }

class CirleLayout extends LayoutGuide {
  const CirleLayout({
    required this.boundary,
    required super.style,
    super.visible,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
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
    final derivatives = layout.getDerivatives(snapshot, context).values;
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
  final derivatives = layout.getDerivatives(snapshot, context).values;
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

class LayoutObservable {
  const LayoutObservable({required this.derivatives, this.epsilon = 0.001});

  final Set<String> derivatives;
  final double epsilon;
}

enum LayoutBackgroundFit { cover, contain, fill }

abstract class LayoutBackground {
  const LayoutBackground({this.orderPosition = 0, this.opacity = 1});

  const factory LayoutBackground.color(
    Color color, {
    int orderPosition,
    double opacity,
  }) = LayoutBackgroundColor;

  const factory LayoutBackground.image({
    required String assetPath,
    int orderPosition,
    double opacity,
    LayoutBackgroundFit fit,
    int repeat,
    Offset position,
    double rotationDegrees,
    double scale,
  }) = LayoutImageBackground;

  const factory LayoutBackground.svg({
    required String assetPath,
    int orderPosition,
    double opacity,
    LayoutBackgroundFit fit,
    int repeat,
    Offset position,
    double rotationDegrees,
    double scale,
  }) = LayoutSvgBackground;

  const factory LayoutBackground.guides({
    required List<LayoutBackgroundGuide> guides,
    int orderPosition,
    double opacity,
  }) = LayoutGuidingBackground;

  const factory LayoutBackground.random(
    List<LayoutBackground> backgrounds, {
    int orderPosition,
    double opacity,
  }) = RandomLayoutBackground;

  const factory LayoutBackground.conditional({
    required LayoutCondition activeCondition,
    required LayoutBackground background,
    int orderPosition,
    double opacity,
  }) = ConditionalLayoutBackground;

  final int orderPosition;
  final double opacity;
}

class RandomLayoutBackground extends LayoutBackground {
  const RandomLayoutBackground(
    this.backgrounds, {
    super.orderPosition,
    super.opacity,
  }) : assert(backgrounds.length > 0);

  final List<LayoutBackground> backgrounds;
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

class LayoutBackgroundColor extends LayoutBackground {
  const LayoutBackgroundColor(this.color, {super.orderPosition, super.opacity});

  final Color color;
}

class LayoutImageBackground extends LayoutBackground {
  const LayoutImageBackground({
    required this.assetPath,
    super.orderPosition,
    super.opacity,
    this.fit = LayoutBackgroundFit.cover,
    this.repeat = 1,
    this.position = const Offset(0.5, 0.5),
    this.rotationDegrees = 0,
    this.scale = 1,
  }) : assert(repeat > 0),
       assert(scale > 0);

  final String assetPath;
  final LayoutBackgroundFit fit;

  /// Number of equal horizontal tiles painted across the owning surface.
  final int repeat;

  /// Normalized image placement inside each repeated tile.
  final Offset position;

  /// Clockwise rotation around the center of each image tile.
  final double rotationDegrees;

  /// Uniform scale around the center of each image tile.
  final double scale;
}

/// SVG asset rasterized once for projection through the shared image mesh.
class LayoutSvgBackground extends LayoutImageBackground {
  const LayoutSvgBackground({
    required super.assetPath,
    super.orderPosition,
    super.opacity,
    super.fit,
    super.repeat,
    super.position,
    super.rotationDegrees,
    super.scale,
  });
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

enum LayoutSizeUnit { fraction, pixels, rootEms, calculatedFraction }

class LayoutSize {
  const LayoutSize.fr(double value)
    : _value = value,
      _unit = LayoutSizeUnit.fraction,
      _derivative = null,
      _primary = null,
      _secondary = null;

  const LayoutSize.px(double value)
    : _value = value,
      _unit = LayoutSizeUnit.pixels,
      _derivative = null,
      _primary = null,
      _secondary = null;

  const LayoutSize.pt(double value)
    : _value = value,
      _unit = LayoutSizeUnit.pixels,
      _derivative = null,
      _primary = null,
      _secondary = null;

  /// A fixed size relative to the root Layout's configured font size.
  const LayoutSize.rem(double value)
    : _value = value,
      _unit = LayoutSizeUnit.rootEms,
      _derivative = null,
      _primary = null,
      _secondary = null;

  const LayoutSize.calculatedFr(double value, {required String derivative})
    : _value = value,
      _unit = LayoutSizeUnit.calculatedFraction,
      // Keep the public parameter name free of private storage vocabulary.
      // ignore: prefer_initializing_formals
      _derivative = derivative,
      _primary = null,
      _secondary = null;

  /// A renderer-interpreted two-dimensional size.
  ///
  /// The owning renderer decides which physical or projected axes correspond
  /// to [primary] and [secondary]. Both dimensions must be scalar sizes.
  const LayoutSize.twoDimensional({
    required LayoutSize primary,
    required LayoutSize secondary,
  }) : _value = null,
       _unit = null,
       _derivative = null,
       // Keep the public dimension name independent of private storage.
       // ignore: prefer_initializing_formals
       _primary = primary,
       // Keep the public dimension name independent of private storage.
       // ignore: prefer_initializing_formals
       _secondary = secondary;

  final double? _value;
  final LayoutSizeUnit? _unit;
  final String? _derivative;
  final LayoutSize? _primary;
  final LayoutSize? _secondary;

  LayoutSize get primary => _primary?.primary ?? this;
  LayoutSize? get secondary => _secondary;
  bool get isTwoDimensional => secondary != null;
  double get value => _primary?.value ?? _value!;
  LayoutSizeUnit get unit => _primary?.unit ?? _unit!;
  String? get derivative => _primary?.derivative ?? _derivative;
}

/// Shared ordered track contract for layouts that present content as a table.
///
/// Concrete layouts keep their own content model: radial areas remain radial,
/// while node-property fields remain node-property fields.
mixin TableLayoutMixin on Layout {
  Map<String, LayoutSize> get tableRowsConfig;
  Map<String, LayoutSize> get tableColumnsConfig;
  GuideStyle? get tableGuideStyle;
}

abstract final class GridSpan {
  static const full = double.infinity;
}

enum GridSlotSpan { content, track }

class GridSlot {
  const GridSlot({
    required this.row,
    required this.column,
    this.aliases = const [],
    this.rowOffset = 0,
    this.columnOffset = 0,
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.initialSpan = GridSlotSpan.track,
    this.maxSpan = GridSlotSpan.track,
  });

  final String row;
  final String column;

  /// Alternative names that a child may use in [Layout.slot].
  final List<String> aliases;
  final double rowOffset;
  final double columnOffset;
  final double rowSpan;
  final double columnSpan;
  final GridSlotSpan initialSpan;
  final GridSlotSpan maxSpan;
}

/// CSS-like two-dimensional composition using named tracks and slots.
///
/// A child selects an entry in [slots] through [Layout.slot]. Its key in
/// [Layout.children] remains independent layout identity.
class GridLayout extends Layout {
  const GridLayout({
    required this.rowsConfig,
    required this.columnsConfig,
    this.slots = const {},
    this.guideStyle,
    super.children,
    super.size,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super();

  final Map<String, LayoutSize> rowsConfig;
  final Map<String, LayoutSize> columnsConfig;
  final Map<String, GridSlot> slots;
  final GuideStyle? guideStyle;
}

/// Vertical composition whose children retain their identity in [children].
class ColumnLayout extends Layout {
  const ColumnLayout({
    super.children,
    super.size,
    super.slot,
    super.aliases,
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super(attributes: const [LayoutAttribute.rectangular]);
}

/// Horizontal composition whose children retain their identity in [children].
class RowLayout extends Layout {
  const RowLayout({
    this.crossAxisAlignment,
    super.children,
    super.size,
    super.slot,
    super.aliases,
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super(attributes: const [LayoutAttribute.rectangular]);

  /// Places intrinsic-height children vertically within this row.
  ///
  /// Null preserves the original behavior where children stretch through the
  /// row's complete cross axis.
  final LayoutCrossAxisAlignment? crossAxisAlignment;
}

/// Direction-aware flex convenience that accepts position-identified items.
///
/// Each item's zero-based list index becomes its key in the canonical
/// [Layout.children] map. Use [RowLayout] when children need authored stable
/// identities that survive reordering.
class ListLayout extends RowLayout {
  ListLayout(
    List<Layout> layouts, {
    this.direction = ListLayoutDirection.horizontal,
    super.crossAxisAlignment,
    super.size,
    super.slot,
    super.aliases,
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super(children: _listLayoutChildren(layouts));

  final ListLayoutDirection direction;
}

Map<String, Layout> _listLayoutChildren(List<Layout> layouts) => {
  for (var index = 0; index < layouts.length; index += 1)
    index.toString(): layouts[index],
};

/// Main-axis direction for [ListLayout].
enum ListLayoutDirection {
  horizontal,
  vertical;

  static ListLayoutDirection parse(String value) {
    final direction = tryParse(value);
    if (direction != null) return direction;
    throw FormatException(
      'Unsupported ListLayoutDirection "$value". '
      'Expected one of: ${values.map((value) => value.name).join(', ')}.',
      value,
    );
  }

  static ListLayoutDirection? tryParse(String value) =>
      values.asNameMap()[value.trim().toLowerCase()];

  bool get isVertical => this == vertical;
}

/// Vertical placement of intrinsic-height children inside a [RowLayout].
class LayoutCrossAxisAlignment {
  const LayoutCrossAxisAlignment.stretch() : fraction = 0, stretches = true;
  const LayoutCrossAxisAlignment.top() : fraction = 0, stretches = false;
  const LayoutCrossAxisAlignment.center() : fraction = 0.5, stretches = false;
  const LayoutCrossAxisAlignment.bottom() : fraction = 1, stretches = false;

  final double fraction;
  final bool stretches;
}

abstract class LayoutTapAction {
  const LayoutTapAction._();

  const factory LayoutTapAction.findOpened() = FindOpenedLayoutTapAction;
}

class FindOpenedLayoutTapAction extends LayoutTapAction {
  const FindOpenedLayoutTapAction() : super._();
}

/// Paintable leaf used inside row/column composition.
class PanelLayout extends Layout {
  const PanelLayout({
    super.size,
    super.slot,
    this.borderStyle,
    this.onTap,
    super.aliases,
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super(attributes: const [LayoutAttribute.rectangular]);
  final GuideStyle? borderStyle;
  final LayoutTapAction? onTap;
}

class LayoutPath extends Layout {
  const LayoutPath({
    required this.points,
    this.style,
    this.ticks,
    this.curves = const [],
    this.padding = const LayoutPathPadding(),
    this.pointDerivatives = const {'A': 0, 'B': 1, 'C': 2, 'D': 3},
    super.children,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.inputSources,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
  }) : super();

  final List<LayoutDerivativeReference> points;
  final LayoutPathStyle? style;
  final LayoutPathTickStyle? ticks;
  final List<LayoutPathCurve> curves;
  final LayoutPathPadding padding;
  final Map<String, int> pointDerivatives;
}

/// A smooth replacement for one edge of a [LayoutPath].
///
/// [from] and [to] identify the structural edge, while [through] supplies a
/// shaping derivative that the rendered curve passes through.
class LayoutPathCurve {
  const LayoutPathCurve({
    required this.from,
    required this.through,
    required this.to,
  });

  final LayoutDerivativeReference from;
  final LayoutDerivativeReference through;
  final LayoutDerivativeReference to;
}

class FanLayout extends Layout with TableLayoutMixin {
  const FanLayout({
    this.rootNodeId,
    this.rootNodePointer,
    this.rootNodeFilter,
    this.traverseBy = GraphTraverseType.partOf,
    this.nodeFilter,
    this.minDepth = 1,
    this.maxDepth = 3,
    this.maxSectionCount = 6,
    this.sectionSizing = FanSectionSizing.equal,
    this.caption,
    this.position = LayoutRelativePosition.top,
    this.growthDirection,
    this.gridStyle,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : assert(
         (rootNodeId == null ? 0 : 1) +
                 (rootNodePointer == null ? 0 : 1) +
                 (rootNodeFilter == null ? 0 : 1) <=
             1,
       ),
       assert(minDepth > 0),
       assert(maxDepth > 0),
       assert(minDepth <= maxDepth),
       assert(maxSectionCount > 0),
       super();

  final String? caption;
  final String? rootNodeId;
  final LayoutNodePointer? rootNodePointer;
  final NodeSearchFilter? rootNodeFilter;
  final GraphTraverseType traverseBy;
  final NodeSearchFilter? nodeFilter;

  /// Minimum number of visible radial rows, including the root row.
  ///
  /// Rows beyond the returned graph depth remain empty but retain the fan's
  /// configured geometry.
  final int minDepth;
  final int maxDepth;
  final int maxSectionCount;
  final FanSectionSizing sectionSizing;
  final LayoutRelativePosition position;
  final LayoutDerivativeReference? growthDirection;
  final GuideStyle? gridStyle;

  String? resolveRootNodeId({required Node? selectedNode}) {
    final pointer = rootNodePointer;
    if (pointer != null) {
      return pointer.resolve(selectedNode: selectedNode);
    }
    return rootNodeId;
  }

  double get angleSpanDegrees {
    if (position.directionDegrees != null) return 90;
    final fraction = position.fraction;
    if (fraction == LayoutRelativePosition.top.fraction ||
        fraction == LayoutRelativePosition.right.fraction ||
        fraction == LayoutRelativePosition.bottom.fraction ||
        fraction == LayoutRelativePosition.left.fraction) {
      return 180;
    }
    return 360;
  }

  Map<String, LayoutSize> get rowsConfig => {
    for (var layer = 0; layer < maxDepth; layer += 1)
      layer == 0 ? 'root' : 'depth-$layer': const LayoutSize.fr(1),
  };

  Map<String, LayoutSize> get columnsConfig => {
    for (var section = 0; section < maxSectionCount; section += 1)
      'section-${section + 1}': const LayoutSize.fr(1),
  };

  @override
  Map<String, LayoutSize> get tableRowsConfig => rowsConfig;

  @override
  Map<String, LayoutSize> get tableColumnsConfig => columnsConfig;

  @override
  GuideStyle? get tableGuideStyle => gridStyle;
}

enum FanSectionSizing { equal, directPartsWeighted }

class GraphLayout extends Layout {
  const GraphLayout({
    required this.style,
    this.nodeExtentFactor = 0.5,
    this.emojiFontSizeFactor = 2,
    this.emojiSlugGapFactor = 0.5,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : assert(nodeExtentFactor > 0 && nodeExtentFactor <= 1),
       assert(emojiFontSizeFactor > 0),
       assert(emojiSlugGapFactor >= 0),
       super();

  /// Diameter of a rendered Node relative to its equal-sized pool cell.
  final double nodeExtentFactor;
  final double emojiFontSizeFactor;
  final double emojiSlugGapFactor;
  final GuideStyle style;
}

class NodeListLayout extends Layout {
  const NodeListLayout({
    required this.dataSource,
    required this.style,
    this.labelSize = 12,
    super.size,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super();

  final NodeListDataSource dataSource;
  final double labelSize;
  final GuideStyle style;
}

enum NodeListDataSource { virtualNodes, searchResults }

/// Single Node resolved from the first result of [filter].
class NodeLayout extends Layout {
  const NodeLayout({
    required this.filter,
    required this.fallbackNode,
    this.emojiFontSizeFactor = 2,
    this.emojiSlugGapFactor = 0.5,
    this.style = const GuideStyle(
      color: NodeDefaults.labelColor,
      strokeWidth: 1.5,
    ),
    super.size,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : assert(emojiFontSizeFactor > 0),
       assert(emojiSlugGapFactor >= 0),
       super();

  final NodeSearchFilter filter;

  /// Frontend fallback rendered and stored as Virtual after an empty lookup.
  final Node fallbackNode;
  final double emojiFontSizeFactor;
  final double emojiSlugGapFactor;
  final GuideStyle style;
}

abstract class LayoutNodePointer {
  const LayoutNodePointer._();

  const factory LayoutNodePointer.selectedNode() =
      _SelectedNodeLayoutNodePointer;

  String? resolve({required Node? selectedNode});
}

final class _SelectedNodeLayoutNodePointer extends LayoutNodePointer {
  const _SelectedNodeLayoutNodePointer() : super._();

  @override
  String? resolve({required Node? selectedNode}) {
    final id = selectedNode?.id.trim();
    return id == null || id.isEmpty ? null : id;
  }
}

class LayoutPathSlotReference {
  const LayoutPathSlotReference({
    this.layoutPath = const [],
    required this.path,
    required this.grid,
    required this.slot,
    this.position = LayoutRelativePosition.center,
  });

  final List<String> layoutPath;
  final String path;
  final String grid;
  final String slot;

  /// Position relative to the area resolved from the target slot.
  final LayoutRelativePosition position;
}

class LayoutSlotRayLayout extends LayoutGuide {
  const LayoutSlotRayLayout({
    required this.start,
    required this.towards,
    required super.style,
    this.showArrow = true,
    this.arrowSize = 10,
    super.visible,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  });

  final LayoutDerivativeReference start;
  final LayoutPathSlotReference towards;
  final bool showArrow;
  final double arrowSize;
}

class LayoutSlotToDerivativeRayLayout extends LayoutGuide {
  const LayoutSlotToDerivativeRayLayout({
    required this.start,
    required this.towards,
    required super.style,
    this.showArrow = true,
    this.arrowSize = 10,
    super.visible,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  });

  final LayoutPathSlotReference start;
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
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.linear],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  }) : super();

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
    this.vaultNode,
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
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.circular],
    super.background,
    super.children,
    super.derivatives,
    super.derivativeSnapshot,
    super.observables,
    super.inputSources,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
  }) : super();

  final VaultNode? vaultNode;
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
    super.slot,
    super.vaultNode,
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
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.shape,
    super.inputSources,
  });
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
    this.useLayoutStyle = false,
    super.visible,
    super.slot,
    super.aliases,
    super.attributes = const [LayoutAttribute.rectangular],
    super.background,
    super.layoutPadding,
    super.layoutGap,
    super.layoutBorderWidth,
    super.inactiveNodeBackgroundOpacity,
    super.activeNodeBackgroundOpacity,
    super.virtualNodeBackgroundOpacity,
    super.label,
    super.text,
    super.node,
    super.panel,
    super.state,
    super.inputSources,
  });

  final LayoutBorderShape shape;
  final LayoutBorderReference reference;
  final List<Point> anchors;
  final List<String> derivativeAnchors;
  final double anchorRadius;
  final double labelFontSize;
  final bool showAnchorDirections;
  final double anchorDirectionLength;
  final bool useLayoutStyle;
}
