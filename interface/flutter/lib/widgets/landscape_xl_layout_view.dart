import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/landscape_xl_layout.dart';
import '../models/layout.dart';
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
  final VaultNode? node;
  final ResolvedVaultNode? resolvedNode;
  final String? label;
}

class LandscapeXlLayoutView extends StatefulWidget {
  const LandscapeXlLayoutView({
    required this.layout,
    required this.contentBuilder,
    this.vaultNodeResolver,
    this.selectedNode,
    this.onLayoutTap,
    super.key,
  });

  final LandscapeXlLayout layout;
  final LandscapeXlLayoutContentBuilder contentBuilder;
  final VaultNodeResolver? vaultNodeResolver;
  final ResolvedVaultNode? selectedNode;
  final LandscapeXlLayoutTapCallback? onLayoutTap;

  @override
  State<LandscapeXlLayoutView> createState() => _LandscapeXlLayoutViewState();
}

class _LandscapeXlLayoutViewState extends State<LandscapeXlLayoutView> {
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final view = Stack(
          fit: StackFit.expand,
          children: [
            _LandscapeXlLayoutNodeView(
              layout: widget.layout,
              contentBuilder: widget.contentBuilder,
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ReferenceLayoutPainter(
                  widget.layout,
                  safePadding,
                  widget.vaultNodeResolver,
                  widget.selectedNode,
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
    required this.contentBuilder,
  });

  final LandscapeXlLayout layout;
  final LandscapeXlLayoutContentBuilder contentBuilder;

  @override
  Widget build(BuildContext context) {
    final backgroundEntries =
        layout.layouts.entries
            .where((entry) => entry.value is LayoutBackgroundElement)
            .map(
              (entry) =>
                  MapEntry(entry.key, entry.value as LayoutBackgroundElement),
            )
            .toList()
          ..sort((left, right) {
            final order = left.value.orderPosition.compareTo(
              right.value.orderPosition,
            );
            return order != 0 ? order : left.key.compareTo(right.key);
          });
    Widget view = Stack(
      fit: StackFit.expand,
      children: [
        for (final entry in backgroundEntries)
          _LayoutBackgroundElementView(element: entry.value),
        IgnorePointer(child: CustomPaint(painter: _LayoutGuidePainter(layout))),
        for (final child in layout.layouts.values)
          if (child is LandscapeXlLayout)
            _LandscapeXlLayoutNodeView(
              layout: child,
              contentBuilder: contentBuilder,
            )
          else if (child is! LayoutGuide &&
              child is! LayoutBackgroundElement &&
              child is! LayoutPath &&
              child is! RadialTreeLayout &&
              child is! TableLayout &&
              child is! StickmanLayout &&
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

class _LayoutBackgroundElementView extends StatelessWidget {
  const _LayoutBackgroundElementView({required this.element});

  final LayoutBackgroundElement element;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      element.assetPath,
      fit: switch (element.fit) {
        LayoutBackgroundFit.cover => BoxFit.cover,
        LayoutBackgroundFit.contain => BoxFit.contain,
        LayoutBackgroundFit.fill => BoxFit.fill,
      },
      alignment: Alignment(
        element.alignment.dx * 2 - 1,
        element.alignment.dy * 2 - 1,
      ),
      width: double.infinity,
      height: double.infinity,
    );
    return Positioned.fill(
      child: element.opacity == 1
          ? image
          : Opacity(opacity: element.opacity.clamp(0, 1), child: image),
    );
  }
}

class _LayoutGuidePainter extends CustomPainter {
  const _LayoutGuidePainter(this.layout);

  final Layout layout;

  @override
  void paint(Canvas canvas, Size size) {
    drawLayoutGuidelines(canvas, size, layout);
  }

  @override
  bool shouldRepaint(_LayoutGuidePainter oldDelegate) {
    return oldDelegate.layout != layout;
  }
}

typedef _ResolvedLayout = ({Layout layout, Rect bounds});

class _ReferenceLayoutPainter extends CustomPainter {
  const _ReferenceLayoutPainter(
    this.layout,
    this.safePadding,
    this.vaultNodeResolver,
    this.selectedNode,
    this.hoverPosition,
  );

  final LandscapeXlLayout layout;
  final EdgeInsets safePadding;
  final VaultNodeResolver? vaultNodeResolver;
  final ResolvedVaultNode? selectedNode;
  final Offset? hoverPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final resolvedLayouts = _resolveLayouts(layout, size, safePadding);
    for (final resolved in resolvedLayouts.values) {
      for (final path
          in resolved.layout.layouts.values.whereType<LayoutPath>()) {
        _drawLayoutPath(
          canvas,
          size,
          path,
          resolvedLayouts,
          vaultNodeResolver,
          selectedNode,
          hoverPosition,
        );
      }
      for (final radialTree
          in resolved.layout.layouts.values.whereType<RadialTreeLayout>()) {
        _drawRadialTreeLayout(
          canvas,
          size,
          resolved.bounds,
          radialTree,
          vaultNodeResolver,
          resolvedLayouts,
        );
      }
      for (final ray in resolved.layout.layouts.values.whereType<RayLayout>()) {
        if (!ray.visible) continue;
        final start = _resolveReference(ray.start, resolvedLayouts);
        final target = _resolveReference(ray.towards, resolvedLayouts);
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawRayArrow(canvas, start, target, ray);
        }
      }
      for (final ray
          in resolved.layout.layouts.values.whereType<LayoutAreaRayLayout>()) {
        if (!ray.visible) continue;
        final start = _resolveReference(ray.start, resolvedLayouts);
        final target = _resolvePathAreaReference(ray.towards, resolvedLayouts);
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawAreaRayArrow(canvas, start, target, ray);
        }
      }
      for (final ray
          in resolved.layout.layouts.values
              .whereType<LayoutAreaToDerivativeRayLayout>()) {
        if (!ray.visible) continue;
        final start = _resolvePathAreaReference(ray.start, resolvedLayouts);
        final target = _resolveReference(ray.towards, resolvedLayouts);
        if (start == null || target == null) continue;
        drawGuideLine(canvas, start, target, ray.style);
        if (ray.showArrow) {
          _drawAreaToDerivativeRayArrow(canvas, start, target, ray);
        }
      }
      for (final stickman
          in resolved.layout.layouts.values.whereType<StickmanLayout>()) {
        _drawStickmanLayout(canvas, resolved.layout, resolved.bounds, stickman);
      }
      for (final graphPreview
          in resolved.layout.layouts.values.whereType<GraphPreviewLayout>()) {
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
        oldDelegate.selectedNode != selectedNode ||
        oldDelegate.hoverPosition != hoverPosition;
  }
}

void _drawLayoutPath(
  Canvas canvas,
  Size size,
  LayoutPath layoutPath,
  Map<String, _ResolvedLayout> layouts,
  VaultNodeResolver? vaultNodeResolver,
  ResolvedVaultNode? selectedNode,
  Offset? hoverPosition,
) {
  final points = [
    for (final reference in layoutPath.points)
      _resolveReference(reference, layouts),
  ];
  if (points.length < 2 || points.any((point) => point == null)) return;
  final resolvedPoints = _paddedPathPoints(
    points.cast<Offset>(),
    layoutPath.resolvedPadding,
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

  for (final radialTree
      in layoutPath.layouts.values.whereType<RadialTreeLayout>()) {
    _drawRadialTreeLayout(
      canvas,
      size,
      _boundsForPoints(resolvedPoints),
      radialTree,
      vaultNodeResolver,
      layouts,
    );
  }

  for (final table in layoutPath.layouts.values.whereType<TableLayout>()) {
    _drawTableLayout(
      canvas,
      resolvedPoints,
      table,
      selectedNode,
      hoverPosition,
    );
  }
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

void _drawRadialTreeLayout(
  Canvas canvas,
  Size size,
  Rect bounds,
  RadialTreeLayout radialTree,
  VaultNodeResolver? vaultNodeResolver,
  Map<String, _ResolvedLayout> layouts,
) {
  final radius = _resolveLayoutSize(
    radialTree.layoutSize,
    viewport: size,
    bounds: bounds,
    layouts: layouts,
  );
  if (radius <= 0) return;

  final center = radialTree.position.resolve(bounds);
  final target = radialTree.growthDirection == null
      ? bounds.center
      : _resolveReference(radialTree.growthDirection!, layouts);
  final growthVector = (target == null || (target - center).distance == 0)
      ? const Offset(0, 1)
      : target - center;
  final growthAngle = math.atan2(growthVector.dy, growthVector.dx);
  final resolvedRoot = _resolveVaultNode(radialTree.node, vaultNodeResolver);
  final rootColor = resolvedRoot.fillColor;
  final arcRect = Rect.fromCircle(center: Offset.zero, radius: radius);

  _drawRadialTreeGrid(
    canvas,
    radialTree,
    center,
    radius,
    growthAngle,
    vaultNodeResolver,
  );

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(growthAngle - math.pi / 2);

  if (rootColor != null) {
    final fillPath = Path()
      ..moveTo(-radius, 0)
      ..lineTo(radius, 0)
      ..arcTo(arcRect, 0, math.pi, false)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = rootColor
        ..style = PaintingStyle.fill,
    );
  }

  if (resolvedRoot.resolvedStatus == LayoutHttpStatus.notFound) {
    final strokePaint = Paint()
      ..color = radialTree.style.color
      ..strokeWidth = radialTree.style.strokeWidth
      ..strokeCap = radialTree.style.strokeCap
      ..style = PaintingStyle.stroke;
    canvas.drawArc(arcRect, 0, math.pi, false, strokePaint);
    canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), strokePaint);
  }
  canvas.restore();

  final label = radialTree.label;
  if (label == null || label.isEmpty) return;
  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: radialTree.labelColor,
        fontSize: radialTree.labelSize,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: radius * 2);
  final direction = growthVector / growthVector.distance;
  final labelCenter = center + direction * radius * 0.42;
  textPainter.paint(
    canvas,
    Offset(
      labelCenter.dx - textPainter.width / 2,
      labelCenter.dy - textPainter.height / 2,
    ),
  );
}

void _drawRadialTreeGrid(
  Canvas canvas,
  RadialTreeLayout radialTree,
  Offset center,
  double radius,
  double growthAngle,
  VaultNodeResolver? vaultNodeResolver,
) {
  if (radialTree.rowsConfig.isEmpty || radialTree.columnsConfig.isEmpty) {
    return;
  }

  final rowStops = _gridTrackStops([
    for (final row in radialTree.rowsConfig.values) row.size,
  ], radius);
  final columnStops = _gridTrackStops([
    for (final column in radialTree.columnsConfig.values) column.size,
  ], math.pi);
  if (rowStops.length < 2 || columnStops.length < 2) return;

  final rowKeys = radialTree.rowsConfig.keys.toList(growable: false);
  final columnKeys = radialTree.columnsConfig.keys.toList(growable: false);
  for (final area in radialTree.areas.values) {
    final rowStartIndex = rowKeys.indexOf(area.row);
    final columnStartIndex = columnKeys.indexOf(area.column);
    if (rowStartIndex < 0 || columnStartIndex < 0) continue;
    _drawRadialTreeArea(
      canvas,
      radialTree,
      center,
      growthAngle,
      rowStops,
      columnStops,
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

  final gridStyle = radialTree.gridStyle;
  if (gridStyle == null) return;

  for (final rowStop in rowStops.skip(1)) {
    _drawRadialTreeArc(
      canvas,
      center,
      growthAngle,
      rowStop,
      0,
      math.pi,
      gridStyle,
    );
  }
  for (final columnStop in columnStops) {
    final theta = -math.pi / 2 + columnStop;
    drawGuideLine(
      canvas,
      center,
      _radialTreePoint(center, growthAngle, radius, theta),
      gridStyle,
    );
  }
}

void _drawRadialTreeArea(
  Canvas canvas,
  RadialTreeLayout radialTree,
  Offset center,
  double growthAngle,
  List<double> rowStops,
  List<double> columnStops,
  double rowStartIndex,
  double rowEndIndex,
  double columnStartIndex,
  double columnEndIndex,
  RadialTreeArea area,
  VaultNodeResolver? vaultNodeResolver,
) {
  if (rowStartIndex < 0 ||
      rowEndIndex > radialTree.rowsConfig.length ||
      rowStartIndex >= rowEndIndex ||
      columnStartIndex < 0 ||
      columnEndIndex > radialTree.columnsConfig.length ||
      columnStartIndex >= columnEndIndex) {
    return;
  }

  final innerRadius = _gridStopAt(rowStops, rowStartIndex);
  final outerRadius = _gridStopAt(rowStops, rowEndIndex);
  final startTheta = -math.pi / 2 + _gridStopAt(columnStops, columnStartIndex);
  final endTheta = -math.pi / 2 + _gridStopAt(columnStops, columnEndIndex);
  final resolvedNode = area.node == null
      ? null
      : _resolveVaultNode(area.node!, vaultNodeResolver);
  final fillColor = resolvedNode?.fillColor ?? area.fillColor;
  final borderStyle = area.node == null
      ? area.borderStyle
      : resolvedNode?.resolvedStatus == LayoutHttpStatus.notFound
      ? area.borderStyle ?? radialTree.gridStyle
      : null;
  final label = area.label;
  if (fillColor == null &&
      borderStyle == null &&
      (label == null || label.isEmpty)) {
    return;
  }

  final path = _radialTreeAreaPath(
    center,
    growthAngle,
    innerRadius,
    outerRadius,
    startTheta,
    endTheta,
  );
  if (fillColor != null) {
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }
  if (borderStyle != null) {
    _drawRadialTreeArc(
      canvas,
      center,
      growthAngle,
      innerRadius,
      startTheta + math.pi / 2,
      endTheta + math.pi / 2,
      borderStyle,
    );
    _drawRadialTreeArc(
      canvas,
      center,
      growthAngle,
      outerRadius,
      startTheta + math.pi / 2,
      endTheta + math.pi / 2,
      borderStyle,
    );
    drawGuideLine(
      canvas,
      _radialTreePoint(center, growthAngle, innerRadius, startTheta),
      _radialTreePoint(center, growthAngle, outerRadius, startTheta),
      borderStyle,
    );
    drawGuideLine(
      canvas,
      _radialTreePoint(center, growthAngle, innerRadius, endTheta),
      _radialTreePoint(center, growthAngle, outerRadius, endTheta),
      borderStyle,
    );
  }

  if (label == null || label.isEmpty) return;
  final labelPoint = _radialTreePoint(
    center,
    growthAngle,
    (innerRadius + outerRadius) / 2,
    (startTheta + endTheta) / 2,
  );
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
    labelPoint - Offset(textPainter.width / 2, textPainter.height / 2),
  );
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
  path.close();
  return path;
}

void _drawRadialTreeArc(
  Canvas canvas,
  Offset center,
  double growthAngle,
  double radius,
  double startRadians,
  double endRadians,
  GuideStyle style,
) {
  var previous = _radialTreePoint(
    center,
    growthAngle,
    radius,
    -math.pi / 2 + startRadians,
  );
  const steps = 24;
  for (var index = 1; index <= steps; index += 1) {
    final theta =
        -math.pi / 2 +
        startRadians +
        (endRadians - startRadians) * index / steps;
    final next = _radialTreePoint(center, growthAngle, radius, theta);
    drawGuideLine(canvas, previous, next, style);
    previous = next;
  }
}

Offset _radialTreePoint(
  Offset center,
  double growthAngle,
  double radius,
  double theta,
) {
  final local = Offset(math.sin(theta) * radius, math.cos(theta) * radius);
  final rotation = growthAngle - math.pi / 2;
  final rotated = Offset(
    local.dx * math.cos(rotation) - local.dy * math.sin(rotation),
    local.dx * math.sin(rotation) + local.dy * math.cos(rotation),
  );
  return center + rotated;
}

LayoutTapTarget? _hitTestLayoutTapTarget(
  LandscapeXlLayout root,
  Size size,
  EdgeInsets safePadding,
  Offset position,
  VaultNodeResolver? vaultNodeResolver,
) {
  final resolvedLayouts = _resolveLayouts(root, size, safePadding);
  for (final resolved in resolvedLayouts.values.toList().reversed) {
    final children = resolved.layout.layouts.entries.toList().reversed;
    for (final entry in children) {
      final child = entry.value;
      if (child is RadialTreeLayout &&
          _hitTestRadialTreeRoot(
            child,
            resolved.bounds,
            size,
            resolvedLayouts,
            position,
          )) {
        return LayoutTapTarget(
          key: entry.key,
          layout: child,
          node: child.node,
          resolvedNode: vaultNodeResolver?.resolve(child.node),
          label: child.label,
        );
      }
    }
  }
  return null;
}

bool _hitTestRadialTreeRoot(
  RadialTreeLayout radialTree,
  Rect bounds,
  Size size,
  Map<String, _ResolvedLayout> layouts,
  Offset position,
) {
  final radius = _resolveLayoutSize(
    radialTree.layoutSize,
    viewport: size,
    bounds: bounds,
    layouts: layouts,
  );
  if (radius <= 0) return false;

  final center = radialTree.position.resolve(bounds);
  final target = radialTree.growthDirection == null
      ? bounds.center
      : _resolveReference(radialTree.growthDirection!, layouts);
  final growthVector = (target == null || (target - center).distance == 0)
      ? const Offset(0, 1)
      : target - center;
  final growthAngle = math.atan2(growthVector.dy, growthVector.dx);
  final rotation = growthAngle - math.pi / 2;
  final translated = position - center;
  final local = Offset(
    translated.dx * math.cos(-rotation) - translated.dy * math.sin(-rotation),
    translated.dx * math.sin(-rotation) + translated.dy * math.cos(-rotation),
  );

  return local.distance <= radius && local.dy >= 0;
}

ResolvedVaultNode _resolveVaultNode(
  VaultNode node,
  VaultNodeResolver? resolver,
) {
  return (resolver ?? VaultNodeResolver.empty).resolve(node);
}

double _resolveLayoutSize(
  LayoutSize layoutSize, {
  required Size viewport,
  required Rect bounds,
  required Map<String, _ResolvedLayout> layouts,
}) {
  if (layoutSize.unit != LayoutSizeUnit.derivativeDistance) {
    return layoutSize.resolve(viewport: viewport, bounds: bounds);
  }

  final from = layoutSize.from;
  final to = layoutSize.to;
  if (from == null || to == null) {
    return layoutSize.resolve(viewport: viewport, bounds: bounds);
  }

  final start = _resolveReference(from, layouts);
  final end = _resolveReference(to, layouts);
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
  TableLayout table,
  ResolvedVaultNode? selectedNode,
  Offset? hoverPosition,
) {
  if (selectedNode == null ||
      parentPoints.length < 4 ||
      table.rows.isEmpty ||
      table.columns.isEmpty) {
    return;
  }

  final rows = _tableLayoutRows(table, selectedNode);
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

  canvas.save();
  canvas.clipPath(panelPath);

  final tableLinePaint = Paint()
    ..color = table.guideStyle.color
    ..strokeWidth = table.guideStyle.strokeWidth
    ..style = PaintingStyle.stroke;
  final leftLength = (tablePoints[3] - tablePoints[0]).distance;
  final rightLength = (tablePoints[2] - tablePoints[1]).distance;
  final averageHeight = (leftLength + rightLength) / 2;
  final topWidth = (tablePoints[1] - tablePoints[0]).distance;
  final bottomWidth = (tablePoints[2] - tablePoints[3]).distance;
  final averageWidth = (topWidth + bottomWidth) / 2;
  final rowStops = _gridTrackStops([
    for (final row in table.rows) row.value.size,
  ], averageHeight);
  final columnStops = _gridTrackStops([
    for (final column in table.columns) column.value.size,
  ], averageWidth);

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
        canvas,
        tablePoints,
        rowStops[highlightedCell.row],
        rowStops[highlightedCell.row + 1],
        0,
        1,
        highlightPaint,
      );
    }
    if (highlight.columns) {
      _drawTableCellFill(
        canvas,
        tablePoints,
        0,
        1,
        columnStops[highlightedCell.column],
        columnStops[highlightedCell.column + 1],
        highlightPaint,
      );
    }
  }

  final tablePath = Path()..moveTo(tablePoints.first.dx, tablePoints.first.dy);
  for (final corner in tablePoints.skip(1)) {
    tablePath.lineTo(corner.dx, corner.dy);
  }
  tablePath.close();
  canvas.drawPath(tablePath, tableLinePaint);

  for (final stop in rowStops.skip(1).take(rowStops.length - 2)) {
    canvas.drawLine(
      _tableLayoutPoint(tablePoints, row: stop, column: 0),
      _tableLayoutPoint(tablePoints, row: stop, column: 1),
      tableLinePaint,
    );
  }
  for (final stop in columnStops.skip(1).take(columnStops.length - 2)) {
    canvas.drawLine(
      _tableLayoutPoint(tablePoints, row: 0, column: stop),
      _tableLayoutPoint(tablePoints, row: 1, column: stop),
      tableLinePaint,
    );
  }

  for (var index = 0; index < rows.length; index += 1) {
    final row = rows[index];
    final rowStart = rowStops[index];
    final rowEnd = rowStops[index + 1];
    for (
      var columnIndex = 0;
      columnIndex < table.columns.length;
      columnIndex += 1
    ) {
      final column = table.columns[columnIndex];
      final isKeyColumn = column.key == 'key';
      _paintTextInTableCell(
        canvas,
        tablePoints,
        rowStart: rowStart,
        rowEnd: rowEnd,
        columnStart: columnStops[columnIndex],
        columnEnd: columnStops[columnIndex + 1],
        text: isKeyColumn ? row.label : _formatBaseNodeInfoValue(row.value),
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

  canvas.restore();
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

List<({String label, Object? value})> _tableLayoutRows(
  TableLayout table,
  ResolvedVaultNode selectedNode,
) {
  final values = switch (table.dataSource) {
    TableLayoutDataSource.baseNodeInfo => _baseNodeInfoValues(selectedNode),
  };
  return [
    for (final row in table.rows) (label: row.key, value: values[row.key]),
  ];
}

Map<String, Object?> _baseNodeInfoValues(ResolvedVaultNode selectedNode) {
  final note = selectedNode.note;
  final frontmatter = note?.frontmatter ?? const <String, String>{};
  return {
    'id': note?.id ?? selectedNode.path,
    'version':
        frontmatter['version'] ??
        frontmatter['node_version'] ??
        frontmatter['schema_version'],
    'aliases':
        frontmatter['aliases'] ?? frontmatter['alias'] ?? selectedNode.label,
    'tags': note?.tags,
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
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: math.max(width - 12, 4));
  final textStart = left.dx <= right.dx ? left : right;
  final centerY = (left.dy + right.dy) / 2;
  textPainter.paint(
    canvas,
    Offset(textStart.dx + 6, centerY - textPainter.height / 2),
  );
}

String _formatBaseNodeInfoValue(Object? value) {
  if (value == null) return '—';
  if (value is VaultNode) {
    final label = value.label?.trim();
    return label == null || label.isEmpty
        ? value.path
        : '$label (${value.path})';
  }
  if (value is Iterable) {
    final formatted = value
        .map(_formatBaseNodeInfoValue)
        .where((item) => item != '—')
        .join(', ');
    return formatted.isEmpty ? '—' : formatted;
  }
  if (value is Map) {
    if (value.isEmpty) return '—';
    return value.entries
        .map(
          (entry) => '${entry.key}: ${_formatBaseNodeInfoValue(entry.value)}',
        )
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
  final circle = parent.outerCircle;
  if (circle == null) return parentBounds;

  final center = parentBounds.topLeft + circle.resolveCenter(parentBounds.size);
  final squareHalfSide = circle.resolveRadius(parentBounds.size) / math.sqrt(2);
  return Rect.fromCenter(
    center: center,
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

List<double> _gridTrackStops(
  List<GridTrackSize> tracks,
  double availablePixels,
) {
  final safePixels = math.max(availablePixels, 0);
  final fixedPixels = tracks
      .where((track) => track.unit == GridTrackUnit.pixels)
      .fold<double>(0, (sum, track) => sum + math.max(track.value, 0));
  final fractionTotal = tracks
      .where((track) => track.unit != GridTrackUnit.pixels)
      .fold<double>(
        0,
        (sum, track) => sum + math.max(_gridTrackFractionValue(track), 0),
      );
  final fractionPixels = math.max(safePixels - fixedPixels, 0);
  final rawSizes = [
    for (final track in tracks)
      track.unit == GridTrackUnit.pixels
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

double _gridTrackFractionValue(GridTrackSize track) {
  if (track.unit != GridTrackUnit.calculatedFraction) return track.value;

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
  EdgeInsets safePadding,
) {
  final resolved = <String, _ResolvedLayout>{
    '': (layout: root, bounds: Offset.zero & size),
  };

  void visit(
    LandscapeXlLayout parent,
    Rect parentBounds,
    List<String> parentPath,
    EdgeInsets remainingSafePadding,
  ) {
    for (final entry in parent.layouts.entries) {
      final child = entry.value;
      if (child is! LandscapeXlLayout) continue;
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
  Map<String, _ResolvedLayout> layouts,
) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final derivative = resolved.layout
      .getDerivatives(reference.snapshot)
      .values[reference.derivative];
  if (derivative == null) return null;
  return resolved.bounds.topLeft +
      derivative.resolve(resolved.layout, resolved.bounds.size);
}

Offset? _resolvePathAreaReference(
  LayoutPathAreaReference reference,
  Map<String, _ResolvedLayout> layouts,
) {
  final resolved = layouts[reference.layoutPath.join('/')];
  if (resolved == null) return null;
  final path = resolved.layout.layouts[reference.path];
  if (path is! LayoutPath) return null;
  final grid = path.grid;
  final area = grid?.areas[reference.area];
  if (grid == null || area == null) return null;

  final points = [
    for (final pointReference in path.points)
      _resolveReference(pointReference, layouts),
  ];
  if (points.length < 2 || points.any((point) => point == null)) return null;
  final corners = _resolvePerspectiveGridAreaCorners(
    _paddedPathPoints(points.cast<Offset>(), path.resolvedPadding),
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
