import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';
import 'package:table_data/table_data.dart';

import '../models/landscape_xl_layout.dart';
import '../models/layout.dart';
import '../models/node_property_table.dart';
import '../utils/canvas_guides.dart';
import '../utils/layout_guidelines.dart';
import '../utils/vault_node_resolver.dart';

typedef LandscapeXlLayoutContentBuilder =
    Widget Function(BuildContext context, Layout layout);

typedef LandscapeXlLayoutTapCallback = void Function(LayoutTapTarget target);

class LayoutTapTarget {
  const LayoutTapTarget({
    required this.key,
    required this.layout,
    this.node,
    this.resolvedNode,
    this.label,
  });

  final String key;
  final Layout layout;
  final VaultNodeUiComponent? node;
  final ResolvedVaultNode? resolvedNode;
  final String? label;
}

class LandscapeXlLayoutView extends StatefulWidget {
  const LandscapeXlLayoutView({
    required this.layout,
    required this.contentBuilder,
    this.vaultNodeResolver,
    this.systemInfo,
    this.nodeTrees = const {},
    this.highlightedNodes = const [],
    this.selectedNodes = const [],
    this.onLayoutTap,
    super.key,
  });

  final LandscapeXlLayout layout;
  final LandscapeXlLayoutContentBuilder contentBuilder;
  final VaultNodeResolver? vaultNodeResolver;
  final SystemInfo? systemInfo;
  final Map<RadialTreeLayout, NodeTree> nodeTrees;
  final List<ResolvedVaultNode> highlightedNodes;
  final List<ResolvedVaultNode> selectedNodes;
  final LandscapeXlLayoutTapCallback? onLayoutTap;

  @override
  State<LandscapeXlLayoutView> createState() => _LandscapeXlLayoutViewState();
}

class _LandscapeXlLayoutViewState extends State<LandscapeXlLayoutView> {
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final selectedNode = widget.selectedNodes.lastOrNull;
    final layoutContext = _layoutContext(
      widget.highlightedNodes,
      widget.selectedNodes,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final view = Stack(
          fit: StackFit.expand,
          children: [
            _LandscapeXlLayoutNodeView(
              layout: widget.layout,
              selectedNode: selectedNode,
              contentBuilder: widget.contentBuilder,
              layoutContext: layoutContext,
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ReferenceLayoutPainter(
                  widget.layout,
                  safePadding,
                  widget.vaultNodeResolver,
                  widget.systemInfo,
                  widget.nodeTrees,
                  widget.highlightedNodes,
                  widget.selectedNodes,
                  _hoverPosition,
                ),
              ),
            ),
          ],
        );

        final hoverableView = MouseRegion(
          onHover: (event) => setState(() {
            _hoverPosition = event.localPosition;
          }),
          onExit: (_) => setState(() {
            _hoverPosition = null;
          }),
          child: view,
        );

        final tapHandler = widget.onLayoutTap;
        if (tapHandler == null) return hoverableView;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final target = _hitTestLayoutTapTarget(
              widget.layout,
              size,
              safePadding,
              details.localPosition,
              widget.vaultNodeResolver,
              widget.nodeTrees,
              widget.highlightedNodes,
              widget.selectedNodes,
            );
            if (target != null) tapHandler(target);
          },
          child: hoverableView,
        );
      },
    );
  }
}

class _LandscapeXlLayoutNodeView extends StatelessWidget {
  const _LandscapeXlLayoutNodeView({
    required this.layout,
    required this.selectedNode,
    required this.contentBuilder,
    required this.layoutContext,
  });

  final LandscapeXlLayout layout;
  final ResolvedVaultNode? selectedNode;
  final LandscapeXlLayoutContentBuilder contentBuilder;
  final LayoutContext layoutContext;

  @override
  Widget build(BuildContext context) {
    final backgrounds = [
      ...layout.backgrounds,
    ]..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
    Widget view = Stack(
      fit: StackFit.expand,
      children: [
        for (final background in backgrounds)
          _LayoutBackgroundView(
            background: background,
            layoutContext: layoutContext,
          ),
        IgnorePointer(
          child: CustomPaint(
            painter: _LayoutGuidePainter(layout, layoutContext),
          ),
        ),
        for (final child in layout.layouts.values)
          if (child.isVisible(layoutContext))
            if (child is LandscapeXlLayout)
              _LandscapeXlLayoutNodeView(
                layout: child,
                selectedNode: selectedNode,
                contentBuilder: contentBuilder,
                layoutContext: layoutContext,
              )
            else if (child is! LayoutGuide &&
                child is! LayoutPath &&
                child is! RadialTreeLayout &&
                child is! NodePropertyTable &&
                child is! StickmanLayout &&
                child is! PlaneLayout &&
                child is! GraphPreviewLayout)
              contentBuilder(context, child),
      ],
    );

    if (layout is SafeAreaLayout) {
      view = SafeArea(child: view);
    }
    return view;
  }
}

class _LayoutBackgroundView extends StatelessWidget {
  const _LayoutBackgroundView({
    required this.background,
    required this.layoutContext,
  });

  final LayoutBackground background;
  final LayoutContext layoutContext;

  @override
  Widget build(BuildContext context) {
    var resolvedBackground = background;
    if (resolvedBackground is ConditionalLayoutBackground) {
      if (!resolvedBackground.activeCondition.isActive(layoutContext)) {
        return const SizedBox.shrink();
      }
      resolvedBackground = resolvedBackground.background;
    }
    if (resolvedBackground is LayoutGuidingBackground) {
      return Positioned.fill(
        child: Opacity(
          opacity: resolvedBackground.opacity.clamp(0, 1),
          child: CustomPaint(
            painter: _LayoutGuidingBackgroundPainter(resolvedBackground),
          ),
        ),
      );
    }
    if (resolvedBackground is! LayoutImageBackground) {
      return const SizedBox.shrink();
    }
    final imageBackground = resolvedBackground;
    final image = Image.asset(
      imageBackground.assetPath,
      fit: switch (imageBackground.fit) {
        LayoutBackgroundFit.cover => BoxFit.cover,
        LayoutBackgroundFit.contain => BoxFit.contain,
        LayoutBackgroundFit.fill => BoxFit.fill,
      },
      alignment: Alignment(
        imageBackground.alignment.dx * 2 - 1,
        imageBackground.alignment.dy * 2 - 1,
      ),
      width: double.infinity,
      height: double.infinity,
    );
    return Positioned.fill(
      child: resolvedBackground.opacity == 1
          ? image
          : Opacity(
              opacity: resolvedBackground.opacity.clamp(0, 1),
              child: image,
            ),
    );
  }
}

class _LayoutGuidingBackgroundPainter extends CustomPainter {
  const _LayoutGuidingBackgroundPainter(this.background);

  final LayoutGuidingBackground background;

  @override
  void paint(Canvas canvas, Size size) {
    for (final guide in background.guides) {
      drawGuideLine(
        canvas,
        Offset(size.width * guide.start.dx, size.height * guide.start.dy),
        Offset(size.width * guide.end.dx, size.height * guide.end.dy),
        guide.style,
      );
    }
  }

  @override
  bool shouldRepaint(_LayoutGuidingBackgroundPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

void _drawPlaneLayout(
  Canvas canvas,
  Layout parent,
  Rect parentBounds,
  PlaneLayout plane,
  ResolvedVaultNode? selectedNode,
) {
  final geometry = _resolvePlaneGeometry(parent, parentBounds, plane);
  if (geometry == null) return;

  final node = selectedNode?.node;
  final borderColor = node == null
      ? plane.borderColor
      : _subjectNodeColor(node.frontmatter['color']) ??
            plane.resolvedBorderColor;
  _drawFilledPlaneShape(
    canvas,
    geometry.shapeFrame,
    plane.shape,
    plane.backgroundColor,
    borderColor,
    plane.borderWidth,
  );
  final planeStyle = plane.style;
  if (plane.showGeometryGuides && planeStyle != null) {
    _drawPlaneBlueprint(
      canvas,
      geometry.shapeFrame,
      geometry.center,
      plane.shape,
      planeStyle,
    );
  } else if (plane.showGeometryGuides) {
    _drawPlaneConnectors(
      canvas,
      geometry.parentFrame,
      geometry.shapeFrame,
      plane.geometryGuideStyle,
    );
    for (var index = 0; index < plane.ringGuides.length; index += 1) {
      _drawPlaneRing(
        canvas,
        geometry.center,
        geometry.ringRadii[index],
        plane.ringGuides[index].style,
      );
    }
    _drawPlaneShape(
      canvas,
      geometry.shapeFrame,
      plane.shape,
      plane.geometryGuideStyle,
    );
  }
}

void _drawPlaneBlueprint(
  Canvas canvas,
  Rect frame,
  Offset center,
  LayoutShape shape,
  PlaneLayoutStyle style,
) {
  _drawPlaneShape(canvas, frame, shape, style.borderStyle);
  switch (shape) {
    case LayoutShape.square || LayoutShape.rectangle:
      final diagonalStyle = style.diagonalStyle ?? style.borderStyle;
      drawGuideLine(canvas, frame.topLeft, frame.bottomRight, diagonalStyle);
      drawGuideLine(canvas, frame.bottomLeft, frame.topRight, diagonalStyle);

      final centerLineStyle = style.centerLineStyle ?? style.borderStyle;
      drawGuideLine(
        canvas,
        Offset(center.dx, frame.top),
        Offset(center.dx, frame.bottom),
        centerLineStyle,
      );
      drawGuideLine(
        canvas,
        Offset(frame.left, center.dy),
        Offset(frame.right, center.dy),
        centerLineStyle,
      );
    case LayoutShape.circle:
      final radiusStyle = style.radiusStyle ?? style.borderStyle;
      drawGuideLine(canvas, center, Offset(center.dx, frame.top), radiusStyle);
      _drawPlaneCenterPoint(canvas, center, style);
  }
}

void _drawPlaneCenterPoint(
  Canvas canvas,
  Offset center,
  PlaneLayoutStyle style,
) {
  final color = style.centerPointColor;
  if (color == null || style.centerPointRadius <= 0) return;
  canvas.drawCircle(
    center,
    style.centerPointRadius,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
}

void _drawFilledPlaneShape(
  Canvas canvas,
  Rect frame,
  LayoutShape shape,
  Color fillColor,
  Color borderColor,
  double borderWidth,
) {
  final fillPaint = Paint()
    ..color = fillColor
    ..style = PaintingStyle.fill;
  final strokePaint = Paint()
    ..color = borderColor
    ..strokeWidth = borderWidth
    ..style = PaintingStyle.stroke;
  switch (shape) {
    case LayoutShape.circle:
      canvas.drawOval(frame, fillPaint);
      if (borderWidth > 0) canvas.drawOval(frame, strokePaint);
    case LayoutShape.square || LayoutShape.rectangle:
      canvas.drawRect(frame, fillPaint);
      if (borderWidth > 0) canvas.drawRect(frame, strokePaint);
  }
}

void _drawPlaneShape(
  Canvas canvas,
  Rect frame,
  LayoutShape shape,
  GuideStyle style,
) {
  switch (shape) {
    case LayoutShape.circle:
      _drawGuideOval(canvas, frame, style);
    case LayoutShape.square || LayoutShape.rectangle:
      _drawGuideRect(canvas, frame, style);
  }
}

void _drawGuideRect(Canvas canvas, Rect frame, GuideStyle style) {
  drawGuideLine(canvas, frame.topLeft, frame.topRight, style);
  drawGuideLine(canvas, frame.topRight, frame.bottomRight, style);
  drawGuideLine(canvas, frame.bottomRight, frame.bottomLeft, style);
  drawGuideLine(canvas, frame.bottomLeft, frame.topLeft, style);
}

void _drawGuideOval(Canvas canvas, Rect frame, GuideStyle style) {
  const segments = 96;
  Offset pointAt(int index) {
    final theta = math.pi * 2 * index / segments;
    return Offset(
      frame.center.dx + math.cos(theta) * frame.width / 2,
      frame.center.dy + math.sin(theta) * frame.height / 2,
    );
  }

  for (var index = 0; index < segments; index += 1) {
    drawGuideLine(canvas, pointAt(index), pointAt(index + 1), style);
  }
}

typedef _ParentShapeFrame = ({Rect frame, LayoutShape shape});

_ParentShapeFrame _parentShapeFrame(Layout parent, Rect parentBounds) {
  if (parent is PlaneLayout) {
    return (frame: parentBounds, shape: parent.shape);
  }

  final innerCircle = _layoutCircleFrame(
    parent,
    parentBounds,
    LayoutCircleBoundary.inner,
  );
  return (frame: innerCircle, shape: LayoutShape.circle);
}

typedef _PlaneGeometry = ({
  Rect parentFrame,
  Rect shapeFrame,
  Offset center,
  List<double> ringRadii,
});

_PlaneGeometry? _resolvePlaneGeometry(
  Layout parent,
  Rect parentBounds,
  PlaneLayout plane,
) {
  final parentShape = _parentShapeFrame(parent, parentBounds);
  final availableFrame = parentShape.frame.deflate(
    math.max(plane.padding + plane.wrapPadding, 0),
  );
  if (availableFrame.isEmpty) return null;

  final center = Offset(
    availableFrame.left + availableFrame.width * plane.position.dx,
    availableFrame.top + availableFrame.height * plane.position.dy,
  );
  final inscribedFrame = _inscribedShapeFrame(
    plane.shape,
    availableFrame,
    parentShape.shape,
  );
  final scale = (plane.radiusFraction / 0.5).clamp(0.0, 1.0).toDouble();
  final shapeFrame = Rect.fromCenter(
    center: center,
    width: inscribedFrame.width * scale,
    height: inscribedFrame.height * scale,
  );
  if (shapeFrame.isEmpty) return null;

  final baseRadius = shapeFrame.shortestSide / 2;
  final availableRadius = availableFrame.shortestSide / 2;
  final ringRadii = [
    for (final ring in plane.ringGuides)
      baseRadius +
          (availableRadius - baseRadius) * ring.fraction.clamp(0, 1).toDouble(),
  ];
  return (
    parentFrame: parentShape.frame,
    shapeFrame: shapeFrame,
    center: center,
    ringRadii: ringRadii,
  );
}

Rect _inscribedShapeFrame(
  LayoutShape childShape,
  Rect parentFrame,
  LayoutShape parentShape,
) {
  return switch (childShape) {
    LayoutShape.rectangle => parentFrame,
    LayoutShape.square =>
      parentShape == LayoutShape.circle
          ? _layoutSquareFrameForCircle(parentFrame, fallback: parentFrame)
          : _centeredSquareFrame(parentFrame),
    LayoutShape.circle =>
      parentShape == LayoutShape.rectangle
          ? _centeredSquareFrame(parentFrame)
          : parentFrame,
  };
}

Rect _centeredSquareFrame(Rect frame) {
  final side = frame.shortestSide;
  return Rect.fromCenter(center: frame.center, width: side, height: side);
}

void _drawPlaneConnectors(
  Canvas canvas,
  Rect frame,
  Rect wrapFrame,
  GuideStyle style,
) {
  drawGuideLine(
    canvas,
    Offset(frame.center.dx, frame.top),
    Offset(wrapFrame.center.dx, wrapFrame.top),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.right, frame.center.dy),
    Offset(wrapFrame.right, wrapFrame.center.dy),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.center.dx, frame.bottom),
    Offset(wrapFrame.center.dx, wrapFrame.bottom),
    style,
  );
  drawGuideLine(
    canvas,
    Offset(frame.left, frame.center.dy),
    Offset(wrapFrame.left, wrapFrame.center.dy),
    style,
  );
}

void _drawPlaneRing(
  Canvas canvas,
  Offset center,
  double radius,
  GuideStyle style,
) {
  if (radius <= 0) return;
  const steps = 96;
  var previous = center + Offset(radius, 0);
  for (var index = 1; index <= steps; index += 1) {
    final radians = math.pi * 2 * index / steps;
    final next = center + Offset(math.cos(radians), math.sin(radians)) * radius;
    drawGuideLine(canvas, previous, next, style);
    previous = next;
  }
}

Color? _subjectNodeColor(String? rawColor) {
  if (rawColor == null || rawColor.trim().isEmpty) return null;
  final normalized = rawColor
      .trim()
      .replaceFirst('#', '')
      .replaceFirst(RegExp('^0x', caseSensitive: false), '');
  final hex = switch (normalized.length) {
    6 => 'FF$normalized',
    8 => normalized,
    _ => null,
  };
  if (hex == null) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

LayoutColor _radialTreeNodeColor(Node node) {
  for (final key in const ['color', 'hex', 'background']) {
    final rawColor = node.frontmatter[key];
    if (_subjectNodeColor(rawColor) != null) {
      return LayoutColor.fromHex(rawColor!);
    }
  }

  final identity = node.id.isNotEmpty ? node.id : node.path;
  var seed = 0;
  for (final codeUnit in identity.codeUnits) {
    seed = (seed * 31 + codeUnit) & 0x7FFFFFFF;
  }
  final random = math.Random(seed);
  final red = 96 + random.nextInt(128);
  final green = 96 + random.nextInt(128);
  final blue = 96 + random.nextInt(128);
  final hex = [
    red,
    green,
    blue,
  ].map((channel) => channel.toRadixString(16).padLeft(2, '0')).join();
  return LayoutColor.fromHex(hex, opacity: 0.88);
}

class _LayoutGuidePainter extends CustomPainter {
  const _LayoutGuidePainter(this.layout, this.layoutContext);

  final Layout layout;
  final LayoutContext layoutContext;

  @override
  void paint(Canvas canvas, Size size) {
    drawLayoutGuidelines(canvas, size, layout, layoutContext);
  }

  @override
  bool shouldRepaint(_LayoutGuidePainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.layoutContext != layoutContext;
  }
}

typedef _ResolvedLayout = ({Layout layout, Rect bounds});

class _ReferenceLayoutPainter extends CustomPainter {
  const _ReferenceLayoutPainter(
    this.layout,
    this.safePadding,
    this.vaultNodeResolver,
    this.systemInfo,
    this.nodeTrees,
    this.highlightedNodes,
    this.selectedNodes,
    this.hoverPosition,
  );

  final LandscapeXlLayout layout;
  final EdgeInsets safePadding;
  final VaultNodeResolver? vaultNodeResolver;
  final SystemInfo? systemInfo;
  final Map<RadialTreeLayout, NodeTree> nodeTrees;
  final List<ResolvedVaultNode> highlightedNodes;
  final List<ResolvedVaultNode> selectedNodes;
  final Offset? hoverPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final selectedNode = selectedNodes.lastOrNull;
    final layoutContext = _layoutContext(highlightedNodes, selectedNodes);
    final resolvedLayouts = _resolveLayouts(
      layout,
      size,
      safePadding,
      layoutContext,
    );
    for (final resolved in resolvedLayouts.values) {
      for (final path
          in resolved.layout.layouts.values.whereType<LayoutPath>()) {
        if (!path.isVisible(layoutContext)) continue;
        _drawLayoutPath(
          canvas,
          size,
          path,
          resolvedLayouts,
          vaultNodeResolver,
          systemInfo,
          nodeTrees,
          selectedNode,
          hoverPosition,
          layoutContext,
        );
      }
      for (final radialTree
          in resolved.layout.layouts.values.whereType<RadialTreeLayout>()) {
        if (!radialTree.isVisible(layoutContext)) continue;
        _drawRadialTreeLayout(
          canvas,
          size,
          resolved.bounds,
          radialTree,
          nodeTrees[radialTree],
          resolvedLayouts,
          layoutContext,
        );
      }
      for (final ray in resolved.layout.layouts.values.whereType<RayLayout>()) {
        if (!ray.visible || !ray.isVisible(layoutContext)) continue;
        final start = _resolveReference(
          ray.start,
          resolvedLayouts,
          layoutContext,
        );
        final target = _resolveReference(
          ray.towards,
          resolvedLayouts,
          layoutContext,
        );
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawRayArrow(canvas, start, target, ray);
        }
      }
      for (final ray
          in resolved.layout.layouts.values.whereType<LayoutAreaRayLayout>()) {
        if (!ray.visible || !ray.isVisible(layoutContext)) continue;
        final start = _resolveReference(
          ray.start,
          resolvedLayouts,
          layoutContext,
        );
        final target = _resolvePathAreaReference(
          ray.towards,
          resolvedLayouts,
          layoutContext,
        );
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawAreaRayArrow(canvas, start, target, ray);
        }
      }
      for (final ray
          in resolved.layout.layouts.values
              .whereType<LayoutAreaToDerivativeRayLayout>()) {
        if (!ray.visible || !ray.isVisible(layoutContext)) continue;
        final start = _resolvePathAreaReference(
          ray.start,
          resolvedLayouts,
          layoutContext,
        );
        final target = _resolveReference(
          ray.towards,
          resolvedLayouts,
          layoutContext,
        );
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawAreaToDerivativeRayArrow(canvas, start, target, ray);
        }
      }
      for (final stickman
          in resolved.layout.layouts.values.whereType<StickmanLayout>()) {
        if (!stickman.isVisible(layoutContext)) continue;
        _drawStickmanLayout(canvas, resolved.layout, resolved.bounds, stickman);
      }
      for (final plane
          in resolved.layout.layouts.values.whereType<PlaneLayout>()) {
        if (!plane.isVisible(layoutContext)) continue;
        _drawPlaneLayout(
          canvas,
          resolved.layout,
          resolved.bounds,
          plane,
          selectedNode,
        );
      }
      for (final graphPreview
          in resolved.layout.layouts.values.whereType<GraphPreviewLayout>()) {
        if (!graphPreview.isVisible(layoutContext)) continue;
        _drawGraphPreviewLayout(
          canvas,
          resolved.layout,
          resolved.bounds,
          graphPreview,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ReferenceLayoutPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.safePadding != safePadding ||
        oldDelegate.vaultNodeResolver != vaultNodeResolver ||
        oldDelegate.systemInfo != systemInfo ||
        oldDelegate.nodeTrees != nodeTrees ||
        oldDelegate.highlightedNodes != highlightedNodes ||
        oldDelegate.selectedNodes != selectedNodes ||
        oldDelegate.hoverPosition != hoverPosition;
  }
}

LayoutContext _layoutContext(
  List<ResolvedVaultNode> highlightedNodes,
  List<ResolvedVaultNode> selectedNodes,
) {
  final selectedPath = selectedNodes.lastOrNull?.path;
  final selectedPaths = [for (final node in selectedNodes) node.path];
  final nodeContext = LayoutContext(
    selectedNodePath: selectedPath,
    selectedNodePaths: selectedPaths,
    highlightedNodePaths: [for (final node in highlightedNodes) node.path],
    activeNodePaths: selectedPaths,
  );
  return nodeContext;
}

void _drawLayoutPath(
  Canvas canvas,
  Size size,
  LayoutPath layoutPath,
  Map<String, _ResolvedLayout> layouts,
  VaultNodeResolver? vaultNodeResolver,
  SystemInfo? systemInfo,
  Map<RadialTreeLayout, NodeTree> nodeTrees,
  ResolvedVaultNode? selectedNode,
  Offset? hoverPosition,
  LayoutContext layoutContext,
) {
  final points = [
    for (final reference in layoutPath.points)
      _resolveReference(reference, layouts, layoutContext),
  ];
  if (points.length < 2 || points.any((point) => point == null)) return;
  final resolvedPoints = _paddedPathPoints(
    points.cast<Offset>(),
    layoutPath.padding,
  );
  final path = Path()..moveTo(resolvedPoints.first.dx, resolvedPoints.first.dy);
  for (final point in resolvedPoints.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  final style = layoutPath.style;
  if (style?.close ?? true) {
    path.close();
  }

  if (style != null) {
    final fillPaint = Paint()
      ..color = style.fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  final strokeStyle = style?.strokeStyle;
  if (strokeStyle != null) {
    for (var index = 0; index < resolvedPoints.length - 1; index += 1) {
      drawGuideLine(
        canvas,
        resolvedPoints[index],
        resolvedPoints[index + 1],
        strokeStyle,
      );
    }
    if ((style?.close ?? true) && resolvedPoints.length > 2) {
      drawGuideLine(
        canvas,
        resolvedPoints.last,
        resolvedPoints.first,
        strokeStyle,
      );
    }
  }

  final ticks = layoutPath.ticks;
  if (ticks != null) {
    _drawPathTicks(canvas, size, resolvedPoints, ticks);
  }

  final grid = layoutPath.grid;
  if (grid != null) {
    _drawPerspectiveGrid(canvas, resolvedPoints, grid, vaultNodeResolver);
  }

  canvas.save();
  canvas.clipPath(path);
  for (final composition
      in layoutPath.layouts.values.whereType<ColumnLayout>()) {
    if (!composition.isVisible(layoutContext)) continue;
    _drawFlexComposition(
      canvas,
      _screenOrderedQuadrilateral(resolvedPoints),
      composition,
      layoutContext,
    );
  }
  for (final composition in layoutPath.layouts.values.whereType<RowLayout>()) {
    if (!composition.isVisible(layoutContext)) continue;
    _drawFlexComposition(
      canvas,
      _screenOrderedQuadrilateral(resolvedPoints),
      composition,
      layoutContext,
    );
  }
  for (final radialTree
      in layoutPath.layouts.values.whereType<RadialTreeLayout>()) {
    if (!radialTree.isVisible(layoutContext)) continue;
    _drawRadialTreeLayout(
      canvas,
      size,
      _boundsForPoints(resolvedPoints),
      radialTree,
      nodeTrees[radialTree],
      layouts,
      layoutContext,
    );
  }

  for (final table
      in layoutPath.layouts.values.whereType<NodePropertyTable>()) {
    if (!table.isVisible(layoutContext)) continue;
    _drawTableLayout(
      canvas,
      resolvedPoints,
      table,
      _tableData(table, selectedNode, systemInfo),
      hoverPosition,
    );
  }
  canvas.restore();
}

TableData _tableData(
  NodePropertyTable table,
  ResolvedVaultNode? selectedNode,
  SystemInfo? systemInfo,
) {
  return switch (table.dataSource) {
    NodePropertyTableDataSource.nodeInfo => TableData(
      selectedNode == null ? const {} : _nodeInfoValues(selectedNode),
    ),
    NodePropertyTableDataSource.systemInfo => TableData({
      'node_count': systemInfo?.nodeCount,
      'node_property_count': systemInfo?.nodePropertyCount,
    }),
  };
}

void _drawPathTicks(
  Canvas canvas,
  Size size,
  List<Offset> points,
  LayoutPathTickStyle ticks,
) {
  if (ticks.count <= 0 ||
      ticks.edgeStartIndex < 0 ||
      ticks.edgeEndIndex < 0 ||
      ticks.edgeStartIndex >= points.length ||
      ticks.edgeEndIndex >= points.length) {
    return;
  }
  final start = points[ticks.edgeStartIndex];
  final end = points[ticks.edgeEndIndex];
  final edge = end - start;
  final edgeLength = edge.distance;
  if (edgeLength == 0) return;

  final direction = edge / edgeLength;
  final normal = Offset(-direction.dy, direction.dx);
  final centroid =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  final midpoint = Offset.lerp(start, end, 0.5)!;
  final centroidDelta = centroid - midpoint;
  final dot = centroidDelta.dx * normal.dx + centroidDelta.dy * normal.dy;
  final inward = dot >= 0 ? normal : -normal;
  final tickLength = size.shortestSide * ticks.lengthFraction;
  final inset = ticks.insetFraction.clamp(0.0, 0.45);
  final usableStart = inset;
  final usableEnd = 1 - inset;
  final divisor = math.max(ticks.count - 1, 1);

  for (var index = 0; index < ticks.count; index += 1) {
    final t = ticks.count == 1
        ? 0.5
        : usableStart + (usableEnd - usableStart) * index / divisor;
    final origin = Offset.lerp(start, end, t)!;
    drawGuideLine(canvas, origin, origin + inward * tickLength, ticks.style);
  }
}

List<Offset> _paddedPathPoints(List<Offset> points, LayoutPathPadding padding) {
  if (padding.isEmpty || points.length < 3) return points;

  final centroid =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  return [
    for (final point in points)
      point +
          Offset(
            point.dx < centroid.dx ? padding.left : -padding.right,
            point.dy < centroid.dy ? padding.top : -padding.bottom,
          ),
  ];
}

void _drawPerspectiveGrid(
  Canvas canvas,
  List<Offset> points,
  PerspectiveGridLayout grid,
  VaultNodeResolver? vaultNodeResolver,
) {
  if (grid.rowsConfig.isEmpty ||
      grid.columnsConfig.isEmpty ||
      !_hasPoint(points, grid.topStartIndex) ||
      !_hasPoint(points, grid.topEndIndex) ||
      !_hasPoint(points, grid.bottomStartIndex) ||
      !_hasPoint(points, grid.bottomEndIndex)) {
    return;
  }

  final leftLength =
      (points[grid.bottomStartIndex] - points[grid.topStartIndex]).distance;
  final rightLength =
      (points[grid.bottomEndIndex] - points[grid.topEndIndex]).distance;
  final rowStops = _gridTrackStops([
    for (final row in grid.rowsConfig.values) row.size,
  ], (leftLength + rightLength) / 2);
  if (rowStops.length < 2) return;

  final rowKeys = grid.rowsConfig.keys.toList(growable: false);
  final columnKeys = grid.columnsConfig.keys.toList(growable: false);
  for (final area in grid.areas.values) {
    final rowStartIndex = rowKeys.indexOf(area.row);
    final columnStartIndex = columnKeys.indexOf(area.column);
    if (rowStartIndex < 0 || columnStartIndex < 0) continue;
    _drawPerspectiveGridArea(
      canvas,
      points,
      grid,
      rowStops,
      rowStartIndex + area.rowOffset,
      _gridAreaEnd(
        rowStartIndex + area.rowOffset,
        area.rowSpan,
        rowKeys.length,
      ),
      columnStartIndex + area.columnOffset,
      _gridAreaEnd(
        columnStartIndex + area.columnOffset,
        area.columnSpan,
        columnKeys.length,
      ),
      area,
      vaultNodeResolver,
    );
  }

  for (final stop in rowStops.skip(1).take(rowStops.length - 2)) {
    drawGuideLine(
      canvas,
      _perspectiveGridPoint(points, grid, stop, 0),
      _perspectiveGridPoint(points, grid, stop, 1),
      grid.guideStyle,
    );
  }

  final topStops = _perspectiveColumnStops(points, grid, 0);
  final bottomStops = _perspectiveColumnStops(points, grid, 1);
  for (
    var columnIndex = 1;
    columnIndex < grid.columnsConfig.length;
    columnIndex += 1
  ) {
    drawGuideLine(
      canvas,
      _perspectiveGridPoint(points, grid, 0, topStops[columnIndex]),
      _perspectiveGridPoint(points, grid, 1, bottomStops[columnIndex]),
      grid.guideStyle,
    );
  }
}

typedef _RadialTreeSegment = ({
  NodeTreeOccurrence occurrence,
  Path path,
  Offset labelPoint,
  double labelWidth,
});

typedef _RadialTreeFrame = ({
  Offset center,
  double growthAngle,
  double radius,
  List<double> rowStops,
  List<double> columnStops,
});

void _drawRadialTreeLayout(
  Canvas canvas,
  Size size,
  Rect bounds,
  RadialTreeLayout radialTree,
  NodeTree? tree,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext,
) {
  if (tree == null || tree.occurrences.isEmpty) return;
  final frame = _resolveRadialTreeFrame(
    radialTree,
    tree,
    size,
    bounds,
    layouts,
    layoutContext,
  );
  if (frame == null) return;
  final segments = _radialTreeSegmentsInFrame(radialTree, tree, frame);
  final borderStyle = radialTree.style;
  final borderWidth =
      radialTree.layoutDefaults?.borderWidth ?? borderStyle.strokeWidth;
  for (final segment in segments) {
    final fillColor = _radialTreeNodeColor(segment.occurrence.node).resolve();
    canvas.drawPath(
      segment.path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }
  _drawRadialTreeGrid(canvas, radialTree, frame);
  for (final segment in segments) {
    canvas.drawPath(
      segment.path,
      Paint()
        ..color = borderStyle.color
        ..strokeWidth = borderWidth
        ..strokeCap = borderStyle.strokeCap
        ..style = PaintingStyle.stroke,
    );
  }
  for (final segment in segments) {
    final node = segment.occurrence.node;
    final label = node.title.isNotEmpty ? node.title : node.id;
    if (label.isEmpty || segment.labelWidth < radialTree.labelSize * 2) {
      continue;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: radialTree.labelColor,
          fontSize: radialTree.labelSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: segment.labelWidth);
    textPainter.paint(
      canvas,
      segment.labelPoint -
          Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}

List<_RadialTreeSegment> _radialTreeSegments(
  RadialTreeLayout radialTree,
  NodeTree tree,
  Size size,
  Rect bounds,
  Map<String, _ResolvedLayout> layouts, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final frame = _resolveRadialTreeFrame(
    radialTree,
    tree,
    size,
    bounds,
    layouts,
    layoutContext,
  );
  return frame == null
      ? const []
      : _radialTreeSegmentsInFrame(radialTree, tree, frame);
}

_RadialTreeFrame? _resolveRadialTreeFrame(
  RadialTreeLayout radialTree,
  NodeTree tree,
  Size size,
  Rect bounds,
  Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext,
) {
  final radius = _resolveLayoutExtent(
    radialTree.layoutSize,
    viewport: size,
    bounds: bounds,
    layouts: layouts,
    layoutContext: layoutContext,
  );
  if (radius <= 0) return null;

  final center = radialTree.position.resolve(bounds);
  final target = radialTree.growthDirection == null
      ? bounds.center
      : _resolveReference(radialTree.growthDirection!, layouts, layoutContext);
  final growthVector = (target == null || (target - center).distance == 0)
      ? const Offset(0, 1)
      : target - center;
  final growthAngle = math.atan2(growthVector.dy, growthVector.dx);
  final visibleOccurrences = tree.occurrences
      .where((occurrence) => occurrence.depth < radialTree.maxDepth)
      .toList(growable: false);
  final root = visibleOccurrences
      .where((occurrence) => occurrence.depth == 0)
      .firstOrNull;
  if (root == null) return null;
  final deepestDepth = visibleOccurrences.fold<int>(
    0,
    (deepest, occurrence) => math.max(deepest, occurrence.depth.toInt()),
  );
  final rowCount = math.min(radialTree.maxDepth, deepestDepth + 1);
  final rootSectionCount = visibleOccurrences
      .where(
        (occurrence) =>
            occurrence.hasParentOccurrenceId() &&
            occurrence.parentOccurrenceId == root.occurrenceId,
      )
      .length;
  final columnCount = math.min(
    radialTree.maxSectionCount,
    math.max(rootSectionCount, 1),
  );
  final rowStops = _gridTrackStops([
    for (final row in radialTree.rowsConfig.values.take(rowCount)) row.size,
  ], radius).map((stop) => stop * radius).toList(growable: false);
  final columnStops = _gridTrackStops(
    [
      for (final column in radialTree.columnsConfig.values.take(columnCount))
        column.size,
    ],
    math.pi,
  ).map((stop) => -math.pi / 2 + stop * math.pi).toList(growable: false);
  return (
    center: center,
    growthAngle: growthAngle,
    radius: radius,
    rowStops: rowStops,
    columnStops: columnStops,
  );
}

List<_RadialTreeSegment> _radialTreeSegmentsInFrame(
  RadialTreeLayout radialTree,
  NodeTree tree,
  _RadialTreeFrame frame,
) {
  final childrenByParent = <String, List<NodeTreeOccurrence>>{};
  NodeTreeOccurrence? root;
  for (final occurrence in tree.occurrences) {
    if (occurrence.depth == 0 && root == null) root = occurrence;
    if (occurrence.hasParentOccurrenceId()) {
      childrenByParent
          .putIfAbsent(occurrence.parentOccurrenceId, () => [])
          .add(occurrence);
    }
  }
  if (root == null) return const [];

  final segments = <_RadialTreeSegment>[];
  late void Function(NodeTreeOccurrence, double, double) addOccurrence;
  addOccurrence = (occurrence, startTheta, endTheta) {
    final occurrenceDepth = occurrence.depth.toInt();
    if (occurrenceDepth + 1 >= frame.rowStops.length) return;
    final innerRadius = frame.rowStops[occurrenceDepth];
    final outerRadius = frame.rowStops[occurrenceDepth + 1];
    segments.add((
      occurrence: occurrence,
      path: _radialTreeAreaPath(
        frame.center,
        frame.growthAngle,
        innerRadius,
        outerRadius,
        startTheta,
        endTheta,
      ),
      labelPoint: _radialTreePoint(
        frame.center,
        frame.growthAngle,
        (innerRadius + outerRadius) / 2,
        (startTheta + endTheta) / 2,
      ),
      labelWidth: math.max(
        (endTheta - startTheta) * (innerRadius + outerRadius) / 2 - 4,
        0,
      ),
    ));

    final children = (childrenByParent[occurrence.occurrenceId] ?? const [])
        .take(radialTree.maxSectionCount)
        .toList(growable: false);
    if (children.isEmpty) return;
    final childSpan = (endTheta - startTheta) / children.length;
    var childStart = startTheta;
    for (final child in children) {
      final childEnd = childStart + childSpan;
      addOccurrence(child, childStart, childEnd);
      childStart = childEnd;
    }
  };
  addOccurrence(root, -math.pi / 2, math.pi / 2);
  return segments;
}

void _drawRadialTreeGrid(
  Canvas canvas,
  RadialTreeLayout radialTree,
  _RadialTreeFrame frame,
) {
  final style = radialTree.gridStyle;
  if (style == null || frame.rowStops.length < 2) return;

  for (final radius in frame.rowStops.skip(1)) {
    _drawRadialTreeArc(canvas, frame.center, frame.growthAngle, radius, style);
  }
  final rootRadius = frame.rowStops[1];
  for (final theta in frame.columnStops) {
    drawGuideLine(
      canvas,
      _radialTreePoint(frame.center, frame.growthAngle, rootRadius, theta),
      _radialTreePoint(frame.center, frame.growthAngle, frame.radius, theta),
      style,
    );
  }
}

void _drawRadialTreeArc(
  Canvas canvas,
  Offset center,
  double growthAngle,
  double radius,
  GuideStyle style,
) {
  const steps = 48;
  var previous = _radialTreePoint(center, growthAngle, radius, -math.pi / 2);
  for (var index = 1; index <= steps; index += 1) {
    final theta = -math.pi / 2 + math.pi * index / steps;
    final next = _radialTreePoint(center, growthAngle, radius, theta);
    drawGuideLine(canvas, previous, next, style);
    previous = next;
  }
}

Path _radialTreeAreaPath(
  Offset center,
  double growthAngle,
  double innerRadius,
  double outerRadius,
  double startTheta,
  double endTheta,
) {
  const steps = 18;
  final path = Path();
  for (var index = 0; index <= steps; index += 1) {
    final theta = startTheta + (endTheta - startTheta) * index / steps;
    final point = _radialTreePoint(center, growthAngle, outerRadius, theta);
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  for (var index = steps; index >= 0; index -= 1) {
    final theta = startTheta + (endTheta - startTheta) * index / steps;
    final point = _radialTreePoint(center, growthAngle, innerRadius, theta);
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

Offset _radialTreePoint(
  Offset center,
  double growthAngle,
  double radius,
  double theta,
) {
  final angle = growthAngle + theta;
  return center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
}

LayoutTapTarget? _hitTestLayoutTapTarget(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding,
  Offset position,
  VaultNodeResolver? vaultNodeResolver,
  Map<RadialTreeLayout, NodeTree> nodeTrees,
  List<ResolvedVaultNode> highlightedNodes,
  List<ResolvedVaultNode> selectedNodes,
) {
  final layoutContext = _layoutContext(highlightedNodes, selectedNodes);
  final resolvedLayouts = _resolveLayouts(
    root,
    size,
    safePadding,
    layoutContext,
  );
  for (final resolved in resolvedLayouts.values.toList().reversed) {
    final children = resolved.layout.layouts.entries.toList().reversed;
    for (final entry in children) {
      final child = entry.value;
      if (child is LayoutPath && child.layouts.isNotEmpty) {
        final points = [
          for (final reference in child.points)
            _resolveReference(reference, resolvedLayouts, layoutContext),
        ];
        if (points.length == 4 && points.every((point) => point != null)) {
          final paddedPoints = _paddedPathPoints(
            points.cast<Offset>(),
            child.padding,
          );
          final compositionPoints = _screenOrderedQuadrilateral(paddedPoints);
          for (final compositionEntry
              in child.layouts.entries.toList().reversed) {
            final composition = compositionEntry.value;
            if (composition is! ColumnLayout && composition is! RowLayout) {
              continue;
            }
            final target = _hitTestFlexComposition(
              composition,
              compositionPoints,
              position,
              '${entry.key}/${compositionEntry.key}',
              layoutContext,
            );
            if (target != null) return target;
          }
          for (final treeEntry in child.layouts.entries.toList().reversed) {
            final radialTree = treeEntry.value;
            if (radialTree is! RadialTreeLayout ||
                !radialTree.isVisible(layoutContext)) {
              continue;
            }
            final tree = nodeTrees[radialTree];
            if (tree == null) continue;
            final occurrence = _hitTestRadialTree(
              radialTree,
              tree,
              _boundsForPoints(paddedPoints),
              size,
              resolvedLayouts,
              position,
              layoutContext,
            );
            if (occurrence == null) continue;
            final resolvedNode = _resolvedRadialTreeNode(occurrence);
            return LayoutTapTarget(
              key: '${entry.key}/${treeEntry.key}/${occurrence.occurrenceId}',
              layout: radialTree,
              node: resolvedNode,
              resolvedNode: resolvedNode,
              label: occurrence.node.title,
            );
          }
        }
      }
      if (child is RadialTreeLayout && child.isVisible(layoutContext)) {
        final tree = nodeTrees[child];
        if (tree == null) continue;
        final occurrence = _hitTestRadialTree(
          child,
          tree,
          resolved.bounds,
          size,
          resolvedLayouts,
          position,
          layoutContext,
        );
        if (occurrence == null) continue;
        final resolvedNode = _resolvedRadialTreeNode(occurrence);
        return LayoutTapTarget(
          key: '${entry.key}/${occurrence.occurrenceId}',
          layout: child,
          node: resolvedNode,
          resolvedNode: resolvedNode,
          label: occurrence.node.title,
        );
      }
    }
  }
  return null;
}

bool _polygonContains(List<Offset> points, Offset position) {
  if (points.length < 3) return false;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path.contains(position);
}

void _drawFlexComposition(
  Canvas canvas,
  List<Offset> points,
  Layout composition,
  LayoutContext layoutContext,
) {
  if (points.length != 4) return;

  final leftHeight = (points[3] - points[0]).distance;
  final rightHeight = (points[2] - points[1]).distance;
  final topWidth = (points[1] - points[0]).distance;
  final bottomWidth = (points[2] - points[3]).distance;
  final flatWidth = (topWidth + bottomWidth) / 2;
  final flatHeight = (leftHeight + rightHeight) / 2;
  if (flatWidth <= 0 || flatHeight <= 0) return;

  final flatPoints = [
    Offset.zero,
    Offset(flatWidth, 0),
    Offset(flatWidth, flatHeight),
    Offset(0, flatHeight),
  ];
  final recorder = ui.PictureRecorder();
  final flatCanvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, flatWidth, flatHeight),
  )..clipRect(Rect.fromLTWH(0, 0, flatWidth, flatHeight));
  _drawFlatFlexComposition(flatCanvas, flatPoints, composition, layoutContext);

  final picture = recorder.endRecording();
  final clipPath = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    clipPath.lineTo(point.dx, point.dy);
  }
  clipPath.close();
  canvas.save();
  canvas.clipPath(clipPath);
  canvas.transform(_rectToQuadTransform(flatWidth, flatHeight, points));
  canvas.drawPicture(picture);
  canvas.restore();
  picture.dispose();
}

void _drawFlatFlexComposition(
  Canvas canvas,
  List<Offset> points,
  Layout composition,
  LayoutContext layoutContext,
) {
  for (final child in _resolveFlexChildren(
    composition,
    points,
    layoutContext,
  )) {
    final layout = child.layout;
    if (layout is PanelLayout) {
      _drawPanelLayout(canvas, child.points, layout);
    } else if (layout is ColumnLayout || layout is RowLayout) {
      _drawFlatFlexComposition(canvas, child.points, layout, layoutContext);
    }
  }
}

LayoutTapTarget? _hitTestFlexComposition(
  Layout composition,
  List<Offset> points,
  Offset position,
  String path,
  LayoutContext layoutContext,
) {
  final children = _resolveFlexChildren(
    composition,
    points,
    layoutContext,
  ).toList().reversed;
  for (final child in children) {
    final childPath = '$path/${child.key}';
    final layout = child.layout;
    if (layout is ColumnLayout || layout is RowLayout) {
      final nested = _hitTestFlexComposition(
        layout,
        child.points,
        position,
        childPath,
        layoutContext,
      );
      if (nested != null) return nested;
    }
    if (layout is PanelLayout &&
        layout.aliases.contains('action-button') &&
        _polygonContains(child.points, position)) {
      return LayoutTapTarget(
        key: childPath,
        layout: layout,
        label: layout.label,
      );
    }
  }
  return null;
}

Iterable<({String key, Layout layout, List<Offset> points})>
_resolveFlexChildren(
  Layout composition,
  List<Offset> points,
  LayoutContext layoutContext,
) sync* {
  final vertical = composition is ColumnLayout;
  if (!vertical && composition is! RowLayout) return;
  final children = composition.layouts.entries
      .where((entry) => entry.value.isVisible(layoutContext))
      .toList(growable: false);
  if (children.isEmpty) return;

  final mainPixels = vertical
      ? ((points[3] - points[0]).distance + (points[2] - points[1]).distance) /
            2
      : ((points[1] - points[0]).distance + (points[2] - points[3]).distance) /
            2;
  if (mainPixels <= 0) return;

  final stops = _gridTrackStops([
    for (final child in children) child.value.size.size,
  ], mainPixels);
  for (var index = 0; index < children.length; index += 1) {
    final entry = children[index];
    final start = stops[index];
    final end = stops[index + 1];
    yield (
      key: entry.key,
      layout: entry.value,
      points: vertical
          ? _quadrilateralSlice(points, top: start, bottom: end)
          : _quadrilateralSlice(points, left: start, right: end),
    );
  }
}

List<Offset> _quadrilateralSlice(
  List<Offset> points, {
  double left = 0,
  double right = 1,
  double top = 0,
  double bottom = 1,
}) {
  return [
    _projectiveQuadrilateralPoint(points, left, top),
    _projectiveQuadrilateralPoint(points, right, top),
    _projectiveQuadrilateralPoint(points, right, bottom),
    _projectiveQuadrilateralPoint(points, left, bottom),
  ];
}

Offset _projectiveQuadrilateralPoint(List<Offset> points, double x, double y) {
  final transform = _rectToQuadTransform(1, 1, points);
  final transformedX = transform[0] * x + transform[4] * y + transform[12];
  final transformedY = transform[1] * x + transform[5] * y + transform[13];
  final transformedW = transform[3] * x + transform[7] * y + transform[15];
  if (transformedW.abs() <= 0.000001) {
    return Offset(transformedX, transformedY);
  }
  return Offset(transformedX / transformedW, transformedY / transformedW);
}

List<Offset> _screenOrderedQuadrilateral(List<Offset> points) {
  if (points.length != 4) return points;
  final byVertical = [...points]
    ..sort((left, right) => left.dy.compareTo(right.dy));
  final top = byVertical.take(2).toList()
    ..sort((left, right) => left.dx.compareTo(right.dx));
  final bottom = byVertical.skip(2).toList()
    ..sort((left, right) => left.dx.compareTo(right.dx));
  return [top[0], top[1], bottom[1], bottom[0]];
}

void _drawPanelLayout(Canvas canvas, List<Offset> points, PanelLayout panel) {
  if (points.length != 4) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  if (panel.fillColor case final fillColor?) {
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }
  if (panel.borderStyle case final borderStyle?) {
    for (var index = 0; index < points.length; index += 1) {
      drawGuideLine(
        canvas,
        points[index],
        points[(index + 1) % points.length],
        borderStyle,
      );
    }
  }
  final label = panel.label;
  if (label == null || label.isEmpty) return;
  final center =
      points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: panel.labelColor,
        fontSize: panel.labelSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  textPainter.paint(
    canvas,
    center - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}

NodeTreeOccurrence? _hitTestRadialTree(
  RadialTreeLayout radialTree,
  NodeTree tree,
  Rect bounds,
  Size size,
  Map<String, _ResolvedLayout> layouts,
  Offset position,
  LayoutContext layoutContext,
) {
  final segments = _radialTreeSegments(
    radialTree,
    tree,
    size,
    bounds,
    layouts,
    layoutContext,
  );
  for (final segment in segments.reversed) {
    if (segment.path.contains(position)) return segment.occurrence;
  }
  return null;
}

ResolvedVaultNode _resolvedRadialTreeNode(NodeTreeOccurrence occurrence) {
  final node = occurrence.node;
  return ResolvedVaultNode(
    path: node.path,
    color: _radialTreeNodeColor(node),
    label: node.title,
    node: node,
    resolvedStatus: LayoutHttpStatus.ok,
  );
}

ResolvedVaultNode _resolveVaultNode(
  VaultNodeUiComponent node,
  VaultNodeResolver? resolver,
) {
  return (resolver ?? VaultNodeResolver.empty).resolve(node);
}

double _resolveLayoutExtent(
  LayoutExtent layoutSize, {
  required Size viewport,
  required Rect bounds,
  required Map<String, _ResolvedLayout> layouts,
  LayoutContext layoutContext = LayoutContext.empty,
}) {
  if (layoutSize.unit != LayoutExtentUnit.derivativeDistance) {
    return layoutSize.resolve(viewport: viewport, bounds: bounds);
  }

  final from = layoutSize.from;
  final to = layoutSize.to;
  if (from == null || to == null) {
    return layoutSize.resolve(viewport: viewport, bounds: bounds);
  }

  final start = _resolveReference(from, layouts, layoutContext);
  final end = _resolveReference(to, layouts, layoutContext);
  if (start == null || end == null) {
    return layoutSize.resolve(viewport: viewport, bounds: bounds);
  }

  return math.max((end - start).distance * layoutSize.amount, 0);
}

Rect _boundsForPoints(List<Offset> points) {
  return Rect.fromLTRB(
    points.map((point) => point.dx).reduce(math.min),
    points.map((point) => point.dy).reduce(math.min),
    points.map((point) => point.dx).reduce(math.max),
    points.map((point) => point.dy).reduce(math.max),
  );
}

void _drawPerspectiveGridArea(
  Canvas canvas,
  List<Offset> points,
  PerspectiveGridLayout grid,
  List<double> rowStops,
  double rowStartIndex,
  double rowEndIndex,
  double columnStartIndex,
  double columnEndIndex,
  PerspectiveGridArea area,
  VaultNodeResolver? vaultNodeResolver,
) {
  final resolvedNode = area.node == null
      ? null
      : _resolveVaultNode(area.node!, vaultNodeResolver);
  final fillColor = resolvedNode?.fillColor ?? area.fillColor;
  final borderStyle = area.node == null
      ? area.borderStyle
      : resolvedNode?.resolvedStatus == LayoutHttpStatus.notFound
      ? area.borderStyle ?? grid.guideStyle
      : null;
  final label = area.label;
  if (fillColor == null &&
      borderStyle == null &&
      (label == null || label.isEmpty)) {
    return;
  }
  if (rowStartIndex < 0 ||
      rowEndIndex > grid.rowsConfig.length ||
      rowStartIndex >= rowEndIndex ||
      columnStartIndex < 0 ||
      columnEndIndex > grid.columnsConfig.length ||
      columnStartIndex >= columnEndIndex) {
    return;
  }

  final rowStart = _gridStopAt(rowStops, rowStartIndex);
  final rowEnd = _gridStopAt(rowStops, rowEndIndex);
  final startStops = _perspectiveColumnStops(points, grid, rowStart);
  final endStops = _perspectiveColumnStops(points, grid, rowEnd);
  final corners = [
    _perspectiveGridPoint(
      points,
      grid,
      rowStart,
      _gridStopAt(startStops, columnStartIndex),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowStart,
      _gridStopAt(startStops, columnEndIndex),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowEnd,
      _gridStopAt(endStops, columnEndIndex),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowEnd,
      _gridStopAt(endStops, columnStartIndex),
    ),
  ];
  if (fillColor != null) {
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }
  if (borderStyle != null) {
    for (var index = 0; index < corners.length; index += 1) {
      drawGuideLine(
        canvas,
        corners[index],
        corners[(index + 1) % corners.length],
        borderStyle,
      );
    }
  }

  if (label == null || label.isEmpty) return;
  final center =
      corners.fold<Offset>(Offset.zero, (sum, corner) => sum + corner) /
      corners.length.toDouble();
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: area.labelColor,
        fontSize: area.labelSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  textPainter.paint(
    canvas,
    center - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}

void _drawTableLayout(
  Canvas canvas,
  List<Offset> parentPoints,
  NodePropertyTable table,
  TableData data,
  Offset? hoverPosition,
) {
  if (parentPoints.length < 4 ||
      table.fieldBuilder == null ||
      table.fieldBuilder!.fields.isEmpty ||
      table.columns.isEmpty) {
    return;
  }

  final rows = buildTableRows(
    table,
    data,
    sectionSize: _tableSeparatorSize,
    formatValue: _formatTableValue,
  );
  if (rows.isEmpty) return;

  final panelPath = Path()
    ..moveTo(parentPoints.first.dx, parentPoints.first.dy);
  for (final corner in parentPoints.skip(1)) {
    panelPath.lineTo(corner.dx, corner.dy);
  }
  panelPath.close();

  final tablePoints = _paddedPathPoints(
    parentPoints,
    LayoutPathPadding.all(table.padding),
  );
  final panelBounds = _boundsForPoints(tablePoints);
  if (panelBounds.width <= 48 || panelBounds.height <= 48) return;

  final leftLength = (tablePoints[3] - tablePoints[0]).distance;
  final rightLength = (tablePoints[2] - tablePoints[1]).distance;
  final averageHeight = (leftLength + rightLength) / 2;
  final topWidth = (tablePoints[1] - tablePoints[0]).distance;
  final bottomWidth = (tablePoints[2] - tablePoints[3]).distance;
  final averageWidth = (topWidth + bottomWidth) / 2;
  final rowStops = _gridTrackStops([
    for (final row in rows) row.size.size,
  ], averageHeight);
  final columnStops = _gridTrackStops([
    for (final column in table.tableColumnsConfig.values) column.size,
  ], averageWidth);
  final tableTransformPoints = [
    _tableLayoutPoint(tablePoints, row: 0, column: 0),
    _tableLayoutPoint(tablePoints, row: 0, column: 1),
    _tableLayoutPoint(tablePoints, row: 1, column: 1),
    _tableLayoutPoint(tablePoints, row: 1, column: 0),
  ];
  final flatTablePoints = [
    Offset.zero,
    Offset(averageWidth, 0),
    Offset(averageWidth, averageHeight),
    Offset(0, averageHeight),
  ];
  final recorder = ui.PictureRecorder();
  final tableCanvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, averageWidth, averageHeight),
  )..clipRect(Rect.fromLTWH(0, 0, averageWidth, averageHeight));

  final tableLinePaint = Paint()
    ..color = table.guideStyle.color
    ..strokeWidth = table.guideStyle.strokeWidth
    ..style = PaintingStyle.stroke;

  final highlightedCell = _tableHighlightedCell(
    tablePoints,
    rowStops,
    columnStops,
    hoverPosition,
  );
  final highlight = table.cellHighlight;
  if (highlight != null && highlightedCell != null) {
    final highlightPaint = Paint()
      ..color = highlight.color
      ..style = PaintingStyle.fill;
    if (highlight.rows) {
      _drawTableCellFill(
        tableCanvas,
        flatTablePoints,
        rowStops[highlightedCell.row],
        rowStops[highlightedCell.row + 1],
        0,
        1,
        highlightPaint,
      );
    }
    if (highlight.columns) {
      _drawTableCellFill(
        tableCanvas,
        flatTablePoints,
        0,
        1,
        columnStops[highlightedCell.column],
        columnStops[highlightedCell.column + 1],
        highlightPaint,
      );
    }
  }

  final tablePath = Path()
    ..moveTo(flatTablePoints.first.dx, flatTablePoints.first.dy);
  for (final corner in flatTablePoints.skip(1)) {
    tablePath.lineTo(corner.dx, corner.dy);
  }
  tablePath.close();
  tableCanvas.drawPath(tablePath, tableLinePaint);

  for (final stop in rowStops.skip(1).take(rowStops.length - 2)) {
    tableCanvas.drawLine(
      _tableLayoutPoint(flatTablePoints, row: stop, column: 0),
      _tableLayoutPoint(flatTablePoints, row: stop, column: 1),
      tableLinePaint,
    );
  }
  for (final columnStop in columnStops.skip(1).take(columnStops.length - 2)) {
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
      if (rows[rowIndex].section) continue;
      tableCanvas.drawLine(
        _tableLayoutPoint(
          flatTablePoints,
          row: rowStops[rowIndex],
          column: columnStop,
        ),
        _tableLayoutPoint(
          flatTablePoints,
          row: rowStops[rowIndex + 1],
          column: columnStop,
        ),
        tableLinePaint,
      );
    }
  }

  for (var index = 0; index < rows.length; index += 1) {
    final row = rows[index];
    final rowStart = rowStops[index];
    final rowEnd = rowStops[index + 1];
    if (row.section) {
      _drawTableCellFill(
        tableCanvas,
        flatTablePoints,
        rowStart,
        rowEnd,
        0,
        1,
        Paint()
          ..color = table.guideStyle.color.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );
      if (row.label.isNotEmpty) {
        _paintTextInTableCell(
          tableCanvas,
          flatTablePoints,
          rowStart: rowStart,
          rowEnd: rowEnd,
          columnStart: 0,
          columnEnd: 1,
          text: row.label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: table.labelColor,
            fontSize: table.labelSize,
            fontWeight: FontWeight.w900,
          ),
        );
      }
      continue;
    }
    for (
      var columnIndex = 0;
      columnIndex < table.tableColumnsConfig.length;
      columnIndex += 1
    ) {
      final column = table.tableColumnsConfig.entries.elementAt(columnIndex);
      final isKeyColumn = column.key == 'key';
      _paintTextInTableCell(
        tableCanvas,
        flatTablePoints,
        rowStart: rowStart,
        rowEnd: rowEnd,
        columnStart: columnStops[columnIndex],
        columnEnd: columnStops[columnIndex + 1],
        text: isKeyColumn ? row.label : _formatTableValue(row.value),
        maxLines: isKeyColumn ? 2 : 3,
        style: TextStyle(
          color: isKeyColumn ? table.labelColor : table.valueColor,
          fontSize: isKeyColumn ? table.labelSize : table.valueSize,
          fontWeight: isKeyColumn ? FontWeight.w800 : FontWeight.w600,
          height: isKeyColumn ? null : 1.25,
        ),
      );
    }
  }

  final tablePicture = recorder.endRecording();
  canvas.save();
  canvas.clipPath(panelPath);
  canvas.transform(
    _rectToQuadTransform(averageWidth, averageHeight, tableTransformPoints),
  );
  canvas.drawPicture(tablePicture);
  canvas.restore();
  tablePicture.dispose();
}

Offset _tableLayoutPoint(
  List<Offset> points, {
  required double row,
  required double column,
}) {
  final firstSide = Offset.lerp(points[0], points[3], row)!;
  final secondSide = Offset.lerp(points[1], points[2], row)!;
  final visualLeft = firstSide.dx <= secondSide.dx ? firstSide : secondSide;
  final visualRight = firstSide.dx <= secondSide.dx ? secondSide : firstSide;
  return Offset.lerp(visualLeft, visualRight, column)!;
}

({int row, int column})? _tableHighlightedCell(
  List<Offset> points,
  List<double> rowStops,
  List<double> columnStops,
  Offset? hoverPosition,
) {
  if (hoverPosition == null) return null;

  for (var row = 0; row < rowStops.length - 1; row += 1) {
    for (var column = 0; column < columnStops.length - 1; column += 1) {
      final path = _tableCellPath(
        points,
        rowStops[row],
        rowStops[row + 1],
        columnStops[column],
        columnStops[column + 1],
      );
      if (path.contains(hoverPosition)) {
        return (row: row, column: column);
      }
    }
  }
  return null;
}

void _drawTableCellFill(
  Canvas canvas,
  List<Offset> points,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
  Paint paint,
) {
  canvas.drawPath(
    _tableCellPath(points, rowStart, rowEnd, columnStart, columnEnd),
    paint,
  );
}

Float64List _rectToQuadTransform(
  double width,
  double height,
  List<Offset> quad,
) {
  final x0 = quad[0].dx;
  final y0 = quad[0].dy;
  final x1 = quad[1].dx;
  final y1 = quad[1].dy;
  final x2 = quad[2].dx;
  final y2 = quad[2].dy;
  final x3 = quad[3].dx;
  final y3 = quad[3].dy;

  final dx1 = x1 - x2;
  final dy1 = y1 - y2;
  final dx2 = x3 - x2;
  final dy2 = y3 - y2;
  final dx3 = x0 - x1 + x2 - x3;
  final dy3 = y0 - y1 + y2 - y3;
  final denominator = dx1 * dy2 - dx2 * dy1;

  var g = 0.0;
  var h = 0.0;
  if (denominator.abs() > 0.000001) {
    g = (dx3 * dy2 - dx2 * dy3) / denominator;
    h = (dx1 * dy3 - dx3 * dy1) / denominator;
  }

  final a = x1 - x0 + g * x1;
  final b = x3 - x0 + h * x3;
  final c = x0;
  final d = y1 - y0 + g * y1;
  final e = y3 - y0 + h * y3;
  final f = y0;
  final safeWidth = math.max(width, 0.000001);
  final safeHeight = math.max(height, 0.000001);

  return Float64List.fromList([
    a / safeWidth,
    d / safeWidth,
    0,
    g / safeWidth,
    b / safeHeight,
    e / safeHeight,
    0,
    h / safeHeight,
    0,
    0,
    1,
    0,
    c,
    f,
    0,
    1,
  ]);
}

Path _tableCellPath(
  List<Offset> points,
  double rowStart,
  double rowEnd,
  double columnStart,
  double columnEnd,
) {
  return Path()
    ..moveTo(
      _tableLayoutPoint(points, row: rowStart, column: columnStart).dx,
      _tableLayoutPoint(points, row: rowStart, column: columnStart).dy,
    )
    ..lineTo(
      _tableLayoutPoint(points, row: rowStart, column: columnEnd).dx,
      _tableLayoutPoint(points, row: rowStart, column: columnEnd).dy,
    )
    ..lineTo(
      _tableLayoutPoint(points, row: rowEnd, column: columnEnd).dx,
      _tableLayoutPoint(points, row: rowEnd, column: columnEnd).dy,
    )
    ..lineTo(
      _tableLayoutPoint(points, row: rowEnd, column: columnStart).dx,
      _tableLayoutPoint(points, row: rowEnd, column: columnStart).dy,
    )
    ..close();
}

GridAxisVariable _tableSeparatorSize(GridAxisVariable fieldSize) {
  const separatorScale = 0.5;
  final size = fieldSize.size;
  return GridAxisVariable(
    size: switch (size.unit) {
      LayoutSizeUnit.fraction => LayoutSize.fr(size.value * separatorScale),
      LayoutSizeUnit.pixels => LayoutSize.px(size.value * separatorScale),
      LayoutSizeUnit.calculatedFraction => LayoutSize.calculatedFr(
        size.value * separatorScale,
        derivative: size.derivative ?? '',
      ),
    },
  );
}

Map<String, Object?> _nodeInfoValues(ResolvedVaultNode selectedNode) {
  final node = selectedNode.node;
  final frontmatter = node?.frontmatter ?? const <String, String>{};
  return {
    'id': node?.id ?? selectedNode.path,
    'version':
        frontmatter['version'] ??
        frontmatter['node_version'] ??
        frontmatter['schema_version'],
    'aliases':
        frontmatter['aliases'] ?? frontmatter['alias'] ?? selectedNode.label,
    'tags': node?.tags,
    'classification':
        frontmatter['classification'] ??
        frontmatter['class'] ??
        frontmatter['type'] ??
        frontmatter['kind'],
  };
}

void _paintTextInTableCell(
  Canvas canvas,
  List<Offset> points, {
  required double rowStart,
  required double rowEnd,
  required double columnStart,
  required double columnEnd,
  required String text,
  required TextStyle style,
  int maxLines = 2,
  TextAlign textAlign = TextAlign.left,
}) {
  final rowCenter = (rowStart + rowEnd) / 2;
  final left = _tableLayoutPoint(points, row: rowCenter, column: columnStart);
  final right = _tableLayoutPoint(points, row: rowCenter, column: columnEnd);
  final width = (right - left).distance;
  final height =
      ((_tableLayoutPoint(points, row: rowEnd, column: columnStart) -
                  _tableLayoutPoint(points, row: rowStart, column: columnStart))
              .distance +
          (_tableLayoutPoint(points, row: rowEnd, column: columnEnd) -
                  _tableLayoutPoint(points, row: rowStart, column: columnEnd))
              .distance) /
      2;
  if (width <= 8 || height <= 8) return;

  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: math.max(width - 12, 4));
  final textStart = left.dx <= right.dx ? left : right;
  final centerY = (left.dy + right.dy) / 2;
  final x = switch (textAlign) {
    TextAlign.center => textStart.dx + (width - textPainter.width) / 2,
    TextAlign.right ||
    TextAlign.end => textStart.dx + width - textPainter.width - 6,
    TextAlign.left || TextAlign.start || TextAlign.justify => textStart.dx + 6,
  };
  textPainter.paint(canvas, Offset(x, centerY - textPainter.height / 2));
}

String _formatTableValue(Object? value) {
  if (value == null) return '—';
  if (value is VaultNodeUiComponent) {
    final label = value.label?.trim();
    return label == null || label.isEmpty
        ? value.path
        : '$label (${value.path})';
  }
  if (value is Iterable) {
    final formatted = value
        .map(_formatTableValue)
        .where((item) => item != '—')
        .join(', ');
    return formatted.isEmpty ? '—' : formatted;
  }
  if (value is Map) {
    if (value.isEmpty) return '—';
    return value.entries
        .map((entry) => '${entry.key}: ${_formatTableValue(entry.value)}')
        .join(', ');
  }

  final string = value.toString().trim();
  return string.isEmpty ? '—' : string;
}

void _drawStickmanLayout(
  Canvas canvas,
  Layout parent,
  Rect parentBounds,
  StickmanLayout stickman,
) {
  final frame = _stickmanFrame(parent, parentBounds);
  final range = stickman.rangeEnd - stickman.rangeStart;
  if (frame.isEmpty || range <= 0) return;

  final unitPx = frame.height / range;
  final centerX = frame.left + frame.width * stickman.centerX;
  Offset point(double x, double y) {
    return Offset(
      centerX + x * unitPx,
      frame.top + (y - stickman.rangeStart) * unitPx,
    );
  }

  final paint = Paint()
    ..color = stickman.style.color
    ..strokeWidth = stickman.style.strokeWidth
    ..strokeCap = stickman.style.strokeCap
    ..style = PaintingStyle.stroke;

  final headCenter = point(0, stickman.headRadius);
  canvas.drawCircle(headCenter, stickman.headRadius * unitPx, paint);

  final neck = point(0, stickman.headRadius * 2);
  final hip = point(0, stickman.hipY);
  final leftShoulder = point(-stickman.shoulderHalfWidth, stickman.shoulderY);
  final rightShoulder = point(stickman.shoulderHalfWidth, stickman.shoulderY);
  final leftHand = point(-stickman.handHalfWidth, stickman.handY);
  final rightHand = point(stickman.handHalfWidth, stickman.handY);
  final leftFoot = point(-stickman.footHalfWidth, stickman.footY);
  final rightFoot = point(stickman.footHalfWidth, stickman.footY);

  canvas.drawLine(neck, hip, paint);
  canvas.drawLine(leftShoulder, rightShoulder, paint);
  canvas.drawLine(leftShoulder, leftHand, paint);
  canvas.drawLine(rightShoulder, rightHand, paint);
  canvas.drawLine(hip, leftFoot, paint);
  canvas.drawLine(hip, rightFoot, paint);
}

void _drawGraphPreviewLayout(
  Canvas canvas,
  Layout parent,
  Rect parentBounds,
  GraphPreviewLayout graphPreview,
) {
  final frame = _stickmanFrame(parent, parentBounds);
  if (frame.isEmpty || graphPreview.nodes.isEmpty) return;

  Offset pointFor(GraphPreviewNode node) => Offset(
    frame.left + frame.width * node.position.dx,
    frame.top + frame.height * node.position.dy,
  );

  final nodeById = {for (final node in graphPreview.nodes) node.id: node};
  final edgeStyle = graphPreview.edgeStyle;
  if (edgeStyle != null) {
    for (final edge in graphPreview.edges) {
      final from = nodeById[edge.from];
      final to = nodeById[edge.to];
      if (from == null || to == null) continue;
      drawGuideLine(canvas, pointFor(from), pointFor(to), edgeStyle);
    }
  }

  final fillPaint = Paint()
    ..color = graphPreview.fillColor
    ..style = PaintingStyle.fill;
  final strokePaint = Paint()
    ..color = graphPreview.nodeStyle.color
    ..strokeWidth = graphPreview.nodeStyle.strokeWidth
    ..strokeCap = graphPreview.nodeStyle.strokeCap
    ..style = PaintingStyle.stroke;

  for (final node in graphPreview.nodes) {
    final center = pointFor(node);
    canvas.drawCircle(center, node.radius, fillPaint);
    canvas.drawCircle(center, node.radius, strokePaint);

    final label = node.label;
    if (label == null || label.isEmpty) continue;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: graphPreview.labelColor,
          fontSize: graphPreview.labelSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}

Rect _stickmanFrame(Layout parent, Rect parentBounds) {
  return _layoutInnerSquareFrame(parent, parentBounds);
}

Rect _layoutInnerSquareFrame(Layout parent, Rect parentBounds) {
  return _layoutSquareFrameForCircle(
    _layoutCircleFrame(parent, parentBounds, LayoutCircleBoundary.outer),
    fallback: parentBounds,
  );
}

Rect _layoutCircleFrame(
  Layout parent,
  Rect parentBounds,
  LayoutCircleBoundary boundary,
) {
  return parent
      .resolveCircleBounds(parentBounds.size, boundary)
      .shift(parentBounds.topLeft);
}

Rect _layoutSquareFrameForCircle(Rect circleFrame, {required Rect fallback}) {
  final squareHalfSide = circleFrame.shortestSide / 2 / math.sqrt(2);
  return Rect.fromCenter(
    center: circleFrame.center,
    width: squareHalfSide * 2,
    height: squareHalfSide * 2,
  );
}

double _gridAreaEnd(double start, double span, int trackCount) {
  if (span == GridSpan.full) return trackCount.toDouble();
  return (start + math.max(span, 0.0001)).clamp(0, trackCount).toDouble();
}

double _gridStopAt(List<double> stops, double track) {
  if (stops.isEmpty) return 0;
  final clampedTrack = track.clamp(0, stops.length - 1).toDouble();
  final index = clampedTrack.floor();
  if (index >= stops.length - 1) return stops.last;

  final fraction = clampedTrack - index;
  return stops[index] + (stops[index + 1] - stops[index]) * fraction;
}

List<double> _perspectiveColumnStops(
  List<Offset> points,
  PerspectiveGridLayout grid,
  double row,
) {
  final left = _perspectiveGridPoint(points, grid, row, 0);
  final right = _perspectiveGridPoint(points, grid, row, 1);
  return _gridTrackStops([
    for (final column in grid.columnsConfig.values) column.size,
  ], (right - left).distance);
}

bool _hasPoint(List<Offset> points, int index) {
  return index >= 0 && index < points.length;
}

List<double> _gridTrackStops(List<LayoutSize> tracks, double availablePixels) {
  final safePixels = math.max(availablePixels, 0);
  final fixedPixels = tracks
      .where((track) => track.unit == LayoutSizeUnit.pixels)
      .fold<double>(0, (sum, track) => sum + math.max(track.value, 0));
  final fractionTotal = tracks
      .where((track) => track.unit != LayoutSizeUnit.pixels)
      .fold<double>(
        0,
        (sum, track) => sum + math.max(_gridTrackFractionValue(track), 0),
      );
  final fractionPixels = math.max(safePixels - fixedPixels, 0);
  final rawSizes = [
    for (final track in tracks)
      track.unit == LayoutSizeUnit.pixels
          ? math.max(track.value, 0)
          : fractionTotal == 0
          ? 0
          : fractionPixels *
                math.max(_gridTrackFractionValue(track), 0) /
                fractionTotal,
  ];
  final total = rawSizes.fold<double>(0, (sum, size) => sum + size);
  if (total <= 0) return const [0, 1];
  final stops = <double>[0];
  var cursor = 0.0;
  for (final size in rawSizes) {
    cursor += size / total;
    stops.add(cursor.clamp(0, 1));
  }
  stops[stops.length - 1] = 1;
  return stops;
}

double _gridTrackFractionValue(LayoutSize track) {
  if (track.unit != LayoutSizeUnit.calculatedFraction) return track.value;

  final now = DateTime.now();
  final hourPassed =
      (now.minute * 60 + now.second + now.millisecond / 1000) / 3600;
  final hourPassedFraction = hourPassed.clamp(0.0, 1.0);
  final hourLeftFraction = 1 - hourPassedFraction;
  final dayPassed =
      (now.hour * 3600 +
          now.minute * 60 +
          now.second +
          now.millisecond / 1000) /
      86400;
  final dayPassedFraction = dayPassed.clamp(0.0, 1.0);
  final dayLeftFraction = 1 - dayPassedFraction;

  return switch (track.derivative) {
    'now-in-current-hour.passed' => hourPassedFraction,
    'now-in-current-hour.left' => hourLeftFraction,
    'now-in-current-day.passed' => dayPassedFraction,
    'now-in-current-day.left' => dayLeftFraction,
    'now-in-time-grid.balance-before-now' =>
      track.value + hourLeftFraction - 0.5 + dayLeftFraction - 0.5,
    'now-in-time-grid.balance-after-now' =>
      track.value + hourPassedFraction - 0.5 + dayPassedFraction - 0.5,
    _ => track.value,
  };
}

Offset _perspectiveGridPoint(
  List<Offset> points,
  PerspectiveGridLayout layout,
  double row,
  double column,
) {
  final topStart = points[layout.topStartIndex];
  final topEnd = points[layout.topEndIndex];
  final bottomStart = points[layout.bottomStartIndex];
  final bottomEnd = points[layout.bottomEndIndex];
  final left = Offset.lerp(topStart, bottomStart, row)!;
  final right = Offset.lerp(topEnd, bottomEnd, row)!;
  return Offset.lerp(left, right, column)!;
}

Map<String, _ResolvedLayout> _resolveLayouts(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolved = <String, _ResolvedLayout>{
    '': (layout: root, bounds: Offset.zero & size),
  };

  void visit(
    Layout parent,
    Rect parentBounds,
    List<String> parentPath,
    EdgeInsets remainingSafePadding,
  ) {
    for (final entry in parent.layouts.entries) {
      final child = entry.value;
      if (!child.isVisible(layoutContext)) continue;
      var bounds = parentBounds;
      var childSafePadding = remainingSafePadding;
      if (child is SafeAreaLayout) {
        bounds = Rect.fromLTRB(
          bounds.left + remainingSafePadding.left,
          bounds.top + remainingSafePadding.top,
          bounds.right - remainingSafePadding.right,
          bounds.bottom - remainingSafePadding.bottom,
        );
        childSafePadding = EdgeInsets.zero;
      } else if (child is PlaneLayout) {
        final geometry = _resolvePlaneGeometry(parent, bounds, child);
        if (geometry != null) {
          bounds = geometry.shapeFrame;
        }
      }
      final path = [...parentPath, entry.key];
      resolved[path.join('/')] = (layout: child, bounds: bounds);
      visit(child, bounds, path, childSafePadding);
    }
  }

  visit(root, Offset.zero & size, const [], safePadding);
  return resolved;
}

Offset? _resolveReference(
  LayoutDerivativeReference reference,
  Map<String, _ResolvedLayout> layouts, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final derivative = resolved.layout
      .getDerivatives(reference.snapshot, layoutContext)
      .values[reference.derivative];
  if (derivative == null) return null;
  return resolved.bounds.topLeft +
      derivative.resolve(resolved.layout, resolved.bounds.size, layoutContext);
}

Offset? _resolvePathAreaReference(
  LayoutPathAreaReference reference,
  Map<String, _ResolvedLayout> layouts, [
  LayoutContext layoutContext = LayoutContext.empty,
]) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final path = resolved.layout.layouts[reference.path];
  if (path is! LayoutPath) return null;
  final grid = path.grid;
  final area = grid?.areas[reference.area];
  if (grid == null || area == null) return null;

  final points = [
    for (final pointReference in path.points)
      _resolveReference(pointReference, layouts, layoutContext),
  ];
  if (points.length < 2 || points.any((point) => point == null)) return null;
  final corners = _resolvePerspectiveGridAreaCorners(
    _paddedPathPoints(points.cast<Offset>(), path.padding),
    grid,
    area,
  );
  if (corners == null) return null;

  final bounds = _boundsForPoints(corners);
  return reference.position.resolve(bounds);
}

List<Offset>? _resolvePerspectiveGridAreaCorners(
  List<Offset> points,
  PerspectiveGridLayout grid,
  PerspectiveGridArea area,
) {
  if (grid.rowsConfig.isEmpty ||
      grid.columnsConfig.isEmpty ||
      !_hasPoint(points, grid.topStartIndex) ||
      !_hasPoint(points, grid.topEndIndex) ||
      !_hasPoint(points, grid.bottomStartIndex) ||
      !_hasPoint(points, grid.bottomEndIndex)) {
    return null;
  }

  final rowKeys = grid.rowsConfig.keys.toList(growable: false);
  final columnKeys = grid.columnsConfig.keys.toList(growable: false);
  final rowStartIndex = rowKeys.indexOf(area.row);
  final columnStartIndex = columnKeys.indexOf(area.column);
  if (rowStartIndex < 0 || columnStartIndex < 0) return null;

  final leftLength =
      (points[grid.bottomStartIndex] - points[grid.topStartIndex]).distance;
  final rightLength =
      (points[grid.bottomEndIndex] - points[grid.topEndIndex]).distance;
  final rowStops = _gridTrackStops([
    for (final row in grid.rowsConfig.values) row.size,
  ], (leftLength + rightLength) / 2);
  if (rowStops.length < 2) return null;

  final rowStartIndexWithOffset = rowStartIndex + area.rowOffset;
  final rowEndIndex = _gridAreaEnd(
    rowStartIndexWithOffset,
    area.rowSpan,
    rowKeys.length,
  );
  final columnStartIndexWithOffset = columnStartIndex + area.columnOffset;
  final columnEndIndex = _gridAreaEnd(
    columnStartIndexWithOffset,
    area.columnSpan,
    columnKeys.length,
  );

  if (rowStartIndexWithOffset < 0 ||
      rowEndIndex > grid.rowsConfig.length ||
      rowStartIndexWithOffset >= rowEndIndex ||
      columnStartIndexWithOffset < 0 ||
      columnEndIndex > grid.columnsConfig.length ||
      columnStartIndexWithOffset >= columnEndIndex) {
    return null;
  }

  final rowStart = _gridStopAt(rowStops, rowStartIndexWithOffset);
  final rowEnd = _gridStopAt(rowStops, rowEndIndex);
  final startStops = _perspectiveColumnStops(points, grid, rowStart);
  final endStops = _perspectiveColumnStops(points, grid, rowEnd);
  return [
    _perspectiveGridPoint(
      points,
      grid,
      rowStart,
      _gridStopAt(startStops, columnStartIndexWithOffset),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowStart,
      _gridStopAt(startStops, columnEndIndex),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowEnd,
      _gridStopAt(endStops, columnEndIndex),
    ),
    _perspectiveGridPoint(
      points,
      grid,
      rowEnd,
      _gridStopAt(endStops, columnStartIndexWithOffset),
    ),
  ];
}

void _drawRayArrow(Canvas canvas, Offset start, Offset target, RayLayout ray) {
  final delta = target - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final base = target - direction * ray.arrowSize;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final paint = Paint()
    ..color = ray.style.color
    ..strokeWidth = ray.style.strokeWidth
    ..strokeCap = ray.style.strokeCap
    ..style = PaintingStyle.stroke;
  canvas.drawLine(target, base + perpendicular * ray.arrowSize * 0.5, paint);
  canvas.drawLine(target, base - perpendicular * ray.arrowSize * 0.5, paint);
}

void _drawAreaRayArrow(
  Canvas canvas,
  Offset start,
  Offset target,
  LayoutAreaRayLayout ray,
) {
  final delta = target - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final base = target - direction * ray.arrowSize;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final paint = Paint()
    ..color = ray.style.color
    ..strokeWidth = ray.style.strokeWidth
    ..strokeCap = ray.style.strokeCap
    ..style = PaintingStyle.stroke;
  canvas.drawLine(target, base + perpendicular * ray.arrowSize * 0.5, paint);
  canvas.drawLine(target, base - perpendicular * ray.arrowSize * 0.5, paint);
}

void _drawAreaToDerivativeRayArrow(
  Canvas canvas,
  Offset start,
  Offset target,
  LayoutAreaToDerivativeRayLayout ray,
) {
  final delta = target - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final base = target - direction * ray.arrowSize;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final paint = Paint()
    ..color = ray.style.color
    ..strokeWidth = ray.style.strokeWidth
    ..strokeCap = ray.style.strokeCap
    ..style = PaintingStyle.stroke;
  canvas.drawLine(target, base + perpendicular * ray.arrowSize * 0.5, paint);
  canvas.drawLine(target, base - perpendicular * ray.arrowSize * 0.5, paint);
}
