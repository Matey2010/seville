import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/interface_colors.dart';
import '../constants/layout_defaults.dart';
import '../models/knowledge_graph.dart';
import '../models/layout.dart';
import '../models/open_box_spatial_layout.dart';
import '../models/timeline_grid.dart';
import '../utils/canvas_guides.dart';
import '../utils/guide_grid_painter.dart';
import 'graph_layout.dart';

final _layout = defaultOpenBoxLayout;

typedef _ResolvedTimelineElement = ({LayoutElement element, LayoutArea area});

enum GuidelineAxis { horizontal, vertical }

class GuidelineComponent extends Component {
  GuidelineComponent({
    required this.axis,
    required this.viewportSize,
    required this.sceneCenter,
    this.color = guidelineRedColor,
  });

  final GuidelineAxis axis;
  final Vector2 Function() viewportSize;
  final Offset Function() sceneCenter;
  final Color color;

  @override
  void render(Canvas canvas) {
    final viewport = viewportSize();
    final center = sceneCenter();
    final (start, end) = switch (axis) {
      GuidelineAxis.horizontal => (
        Offset(0, center.dy),
        Offset(viewport.x, center.dy),
      ),
      GuidelineAxis.vertical => (
        Offset(center.dx, 0),
        Offset(center.dx, viewport.y),
      ),
    };
    drawDashedLine(
      canvas,
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      dashLength: 8,
      gapLength: 6,
    );
  }
}

class KnowledgeGraphGame extends FlameGame {
  late final _GraphField _field;
  KnowledgeGraph _graph = const KnowledgeGraph(nodes: [], edges: []);

  @override
  Color backgroundColor() => interfaceBackgroundColor;

  @override
  Future<void> onLoad() async {
    _field = _GraphField()..size = size;
    add(_field);
    _field.setGraph(_graph);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _field.size = size;
  }

  void setGraph(KnowledgeGraph graph) {
    _graph = graph;
    if (isLoaded) _field.setGraph(graph);
  }
}

class _GraphField extends PositionComponent {
  KnowledgeGraph _graph = const KnowledgeGraph(nodes: [], edges: []);
  Map<String, Offset> _positions = const {};
  Map<String, GraphNode> _nodesById = const {};
  Map<String, List<_ResolvedTimelineElement>> _timelineElementsByNodeId =
      const {};
  Map<LayoutElement, GraphNode> _timelineNodesByElement = const {};
  Set<String> _labeledNodeIds = const {};
  final Map<String, Offset> _screenPositions = {};
  late final List<_ResolvedTimelineElement> _timelineElements =
      _resolvedTimelineElements().toList(growable: false);
  ui.Picture? _timelinePicture;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll([
      GuidelineComponent(
        axis: GuidelineAxis.horizontal,
        viewportSize: () => size,
        sceneCenter: () => _sceneRect().center,
        color: guidelineRedColor,
      ),
      GuidelineComponent(
        axis: GuidelineAxis.vertical,
        viewportSize: () => size,
        sceneCenter: () => _sceneRect().center,
        color: guidelineRedColor,
      ),
    ]);
  }

  void setGraph(KnowledgeGraph graph) {
    _graph = graph;
    _positions = layoutGraph(graph);
    _nodesById = {for (final node in graph.nodes) node.id: node};
    _bindTimelineElements();
    final importantNodes = [...graph.nodes]
      ..sort((a, b) => b.weightedDegree.compareTo(a.weightedDegree));
    _labeledNodeIds = {
      ...importantNodes.take(24).map((node) => node.id),
      ..._timelineElementsByNodeId.keys,
    };
    _screenPositions.clear();
    _invalidateTimelinePicture();
  }

  void _bindTimelineElements() {
    final byNodeId = <String, List<_ResolvedTimelineElement>>{};
    final nodesByElement = <LayoutElement, GraphNode>{};
    for (final node in _graph.nodes) {
      final path = _normalizedVaultPath(node.path);
      for (final resolved in _timelineElements) {
        final defaultPath = resolved.element.defaultPath;
        if (defaultPath == null ||
            !_endsWithVaultPath(path, _normalizedVaultPath(defaultPath))) {
          continue;
        }
        (byNodeId[node.id] ??= []).add(resolved);
        nodesByElement[resolved.element] = node;
      }
    }
    _timelineElementsByNodeId = byNodeId;
    _timelineNodesByElement = nodesByElement;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _screenPositions.clear();
    _invalidateTimelinePicture();
  }

  @override
  void onRemove() {
    _invalidateTimelinePicture();
    super.onRemove();
  }

  void _invalidateTimelinePicture() {
    _timelinePicture?.dispose();
    _timelinePicture = null;
  }

  Offset _screenPosition(String id) {
    return _screenPositions.putIfAbsent(id, () {
      final node = _nodesById[id];
      final bottomWallPosition = node == null
          ? null
          : _bottomWallNodePosition(node);
      if (bottomWallPosition != null) return bottomWallPosition;

      final normalized = _positions[id] ?? const Offset(0.5, 0.5);
      final scene = _sceneRect();
      return Offset(
        scene.left + normalized.dx * scene.width,
        scene.top + normalized.dy * scene.height,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scene = _sceneRect();
    _renderBoxWalls(canvas);
    _renderLayoutGrids(canvas);
    _renderPerspectiveGuides(canvas, scene);

    final edgePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final edge in _graph.edges) {
      edgePaint
        ..color = edge.color
        ..strokeWidth = 0.7 + edge.weight * 0.65;
      canvas.drawLine(
        _screenPosition(edge.sourceId),
        _screenPosition(edge.targetId),
        edgePaint,
      );
    }

    _renderCachedBottomWallElements(canvas);

    for (final node in _graph.nodes) {
      if (_hasBottomWallNodeElement(node)) continue;

      final center = _screenPosition(node.id);
      canvas.drawCircle(
        center,
        node.radius + 5,
        Paint()..color = node.color.withValues(alpha: 0.12),
      );
      canvas.drawCircle(center, node.radius, Paint()..color = node.color);
      canvas.drawCircle(
        center,
        node.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      if (_labeledNodeIds.contains(node.id)) {
        final isOnWall = _hasBottomWallNodeElement(node);
        final painter = TextPainter(
          text: TextSpan(
            text: node.title,
            style: TextStyle(
              color: isOnWall ? wallLabelColor : graphLabelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: isOnWall ? Colors.black54 : Colors.white,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 140);
        final labelOffset = _isFutureAnchor(node)
            ? Offset(-node.radius - 5 - painter.width, -painter.height / 2)
            : Offset(node.radius + 5, -painter.height / 2);
        painter.paint(canvas, center + labelOffset);
      }
    }
  }

  Rect _sceneRect() {
    return _sceneLayoutAreaRect(_layout.boxBottomArea);
  }

  void _renderLayoutGrids(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    drawGuideGrids(
      canvas,
      _layout,
      GuideGridProjection(
        topLeft: Offset.zero,
        topRight: Offset(size.x, 0),
        bottomLeft: Offset(0, size.y),
        bottomRight: Offset(size.x, size.y),
      ),
      drawSubLayouts: false,
    );

    for (final wall in OpenBoxWall.values) {
      final coordinates = _layout.wallCoordinates(wall);
      final outerStart = _sceneLayoutPointFrom(coordinates.outerStart);
      final outerEnd = _sceneLayoutPointFrom(coordinates.outerEnd);
      final innerStart = _sceneLayoutPointFrom(coordinates.innerStart);
      final innerEnd = _sceneLayoutPointFrom(coordinates.innerEnd);
      final startsAtInnerEdge = wall == OpenBoxWall.bottom;
      drawGuideGrids(
        canvas,
        _layout.wallLayout(wall),
        GuideGridProjection(
          topLeft: startsAtInnerEdge ? innerStart : outerStart,
          topRight: startsAtInnerEdge ? innerEnd : outerEnd,
          bottomLeft: startsAtInnerEdge ? outerStart : innerStart,
          bottomRight: startsAtInnerEdge ? outerEnd : innerEnd,
        ),
      );
    }
  }

  void _renderBoxWalls(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    for (final wall in OpenBoxWall.values) {
      final coordinates = _layout.wallCoordinates(wall);
      _drawWall(canvas, [
        _sceneLayoutPointFrom(coordinates.outerStart),
        _sceneLayoutPointFrom(coordinates.outerEnd),
        _sceneLayoutPointFrom(coordinates.innerEnd),
        _sceneLayoutPointFrom(coordinates.innerStart),
      ], _wallColor(wall));
    }
  }

  void _drawWall(Canvas canvas, List<Offset> corners, Color color) {
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _renderPerspectiveGuides(Canvas canvas, Rect scene) {
    if (size.x <= 0 || size.y <= 0) return;

    final perspectivePaint = Paint()
      ..color = guidelineRedColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _renderBottomWallTimeAxis(canvas, scene);
    for (final wall in OpenBoxWall.values) {
      final coordinates = _layout.wallCoordinates(wall);
      final outerStart = _sceneLayoutPointFrom(coordinates.outerStart);
      final outerEnd = _sceneLayoutPointFrom(coordinates.outerEnd);
      final innerStart = _sceneLayoutPointFrom(coordinates.innerStart);
      final innerEnd = _sceneLayoutPointFrom(coordinates.innerEnd);

      drawDashedLine(canvas, outerStart, innerStart, perspectivePaint);
      drawDashedLine(canvas, outerEnd, innerEnd, perspectivePaint);
      drawDashedLine(canvas, innerStart, innerEnd, perspectivePaint);
    }
  }

  void _renderBottomWallTimeAxis(Canvas canvas, Rect scene) {
    final timeline = _layout.bottomWallTimelineLayout;
    final timeAxis = timeline.element(TimelineGrid.timeAxis).area;
    final nowPointer = timeline.element(TimelineGrid.nowPointer).area;
    final axisY = _bottomWallTimelineY(timeAxis.row);
    final nowX = _bottomWallCurrentHourX(DateTime.now());
    final axisPaint = Paint()
      ..color = bottomWallTimeAxisColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nowPaint = Paint()
      ..color = bottomWallNowPointerColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      _bottomWallPoint(scene, _bottomWallTimelineX(timeAxis, 0), axisY),
      _bottomWallPoint(
        scene,
        _bottomWallTimelineX(timeAxis, timeline.dimensions.horizontal),
        axisY,
      ),
      axisPaint,
    );
    drawDashedLine(
      canvas,
      _bottomWallPoint(scene, nowX, _bottomWallTimelineY(nowPointer.row)),
      _bottomWallPoint(
        scene,
        nowX,
        _bottomWallTimelineY(nowPointer.row + nowPointer.rowSpan),
      ),
      nowPaint,
      dashLength: 10,
      gapLength: 5,
    );

    for (var hour = 0; hour <= timeline.dimensions.horizontal; hour += 1) {
      final x = _bottomWallTimelineX(timeAxis, hour);
      final isMajorTick = hour % 6 == 0;
      canvas.drawLine(
        _bottomWallPoint(scene, x, axisY),
        _bottomWallPoint(scene, x, max(axisY - (isMajorTick ? 0.08 : 0.04), 0)),
        axisPaint,
      );
    }

    const labels = {
      0: 'Y 18',
      6: '00',
      12: '06',
      18: '12',
      24: '18',
      30: '24',
      36: 'T 06',
    };
    for (final entry in labels.entries) {
      final x = _bottomWallTimelineX(timeAxis, entry.key);
      final labelPoint = _bottomWallPoint(scene, x, max(axisY - 0.08, 0));
      _paintBottomWallTimeLabel(
        canvas,
        entry.value,
        labelPoint + const Offset(0, 3),
      );
    }
  }

  double _bottomWallCurrentHourX(DateTime now) {
    final hourOfToday =
        now.hour +
        now.minute / 60 +
        now.second / 3600 +
        now.millisecond / 3600000;
    return _bottomWallTimelineX(
      _layout.bottomWallTimelineLayout.element(TimelineGrid.nowPointer).area,
      6 + hourOfToday,
    );
  }

  double _bottomWallTimelineX(LayoutArea element, num track) {
    final timeline = _layout.bottomWallTimelineLayout;
    final placement = _layout.bottomWallTimelineArea;
    final trackPosition = timeline.dimensions.normalizedHorizontalPosition(
      track,
    );
    final timelineColumn = element.column + element.columnSpan * trackPosition;
    final timelinePosition = timeline.dimensions.normalizedHorizontalPosition(
      timelineColumn,
    );
    final column = placement.column + placement.columnSpan * timelinePosition;
    return _layout.bottomWallDimensions.normalizedHorizontalPosition(column);
  }

  double _bottomWallTimelineY(num row) {
    final timeline = _layout.bottomWallTimelineLayout;
    final placement = _layout.bottomWallTimelineArea;
    final timelinePosition = timeline.dimensions.normalizedVerticalPosition(
      row,
    );
    final bottomWallRow = placement.row + placement.rowSpan * timelinePosition;
    return _layout.bottomWallDimensions.normalizedVerticalPosition(
      bottomWallRow,
    );
  }

  Offset _bottomWallPoint(Rect scene, double x, double y) {
    final left = Offset.lerp(scene.bottomLeft, Offset(0, size.y), y)!;
    final right = Offset.lerp(scene.bottomRight, Offset(size.x, size.y), y)!;
    return Offset.lerp(left, right, x)!;
  }

  Rect _sceneLayoutAreaRect(LayoutArea area) {
    final topLeft = _sceneLayoutPoint(area.column, area.row);
    final bottomRight = _sceneLayoutPoint(
      area.column + area.columnSpan,
      area.row + area.rowSpan,
    );
    return Rect.fromLTRB(
      min(topLeft.dx, bottomRight.dx),
      min(topLeft.dy, bottomRight.dy),
      max(topLeft.dx, bottomRight.dx),
      max(topLeft.dy, bottomRight.dy),
    );
  }

  Offset _sceneLayoutPoint(num column, num row) {
    final dimensions = _layout.dimensions;
    return Offset(
      size.x * dimensions.normalizedHorizontalPosition(column),
      size.y * dimensions.normalizedVerticalPosition(row),
    );
  }

  Offset _sceneLayoutPointFrom(LayoutPoint point) {
    return _sceneLayoutPoint(point.column, point.row);
  }

  Offset? _bottomWallNodePosition(GraphNode node) {
    final element = _bottomWallNodeElement(node);
    if (element == null) return null;

    final dimensions = _layout.bottomWallDimensions;
    final area = _bottomWallTimelineElementArea(element.area);
    final centerX = dimensions.normalizedHorizontalPosition(
      area.column + area.columnSpan / 2,
    );
    final centerY = dimensions.normalizedVerticalPosition(
      area.row + area.rowSpan / 2,
    );
    return _bottomWallPoint(
      _sceneRect(),
      centerX.clamp(0.0, 1.0),
      centerY.clamp(0.0, 1.0),
    );
  }

  void _renderBottomWallElements(Canvas canvas) {
    for (final resolved in _timelineElements) {
      if (resolved.element.defaultPath == null) continue;
      final node = _graphNodeForTimelineElement(resolved.element);
      final emptySlotStyle = node == null ? resolved.element.slotStyle : null;
      final area = _bottomWallTimelineElementArea(resolved.area);
      final path = _bottomWallLayoutAreaPath(
        _sceneRect(),
        area,
        borderRadius: resolved.element.borderRadius,
      );
      if (emptySlotStyle == null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = (node?.color ?? bottomWallTimeAxisColor).withValues(
              alpha: 0.78,
            ),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else {
        _drawDashedPolygon(
          canvas,
          _bottomWallLayoutAreaCorners(_sceneRect(), area),
          emptySlotStyle,
        );
      }

      final center = _bottomWallLayoutAreaCenter(_sceneRect(), area);
      final painter = TextPainter(
        text: TextSpan(
          text:
              node?.title ??
              resolved.element.defaultLabel ??
              _timelineLabelFromPath(resolved.element.defaultPath!),
          style: TextStyle(
            color: emptySlotStyle?.borderColor ?? wallLabelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: emptySlotStyle == null
                ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                : const [],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 120);
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _renderCachedBottomWallElements(Canvas canvas) {
    final picture = _timelinePicture ??= _recordBottomWallElements();
    canvas.drawPicture(picture);
  }

  ui.Picture _recordBottomWallElements() {
    final recorder = ui.PictureRecorder();
    _renderBottomWallElements(Canvas(recorder));
    return recorder.endRecording();
  }

  Path _bottomWallLayoutAreaPath(
    Rect scene,
    LayoutArea area, {
    double borderRadius = 0,
  }) {
    return _roundedPolygonPath(
      _bottomWallLayoutAreaCorners(scene, area),
      borderRadius,
    );
  }

  List<Offset> _bottomWallLayoutAreaCorners(Rect scene, LayoutArea area) {
    final dimensions = _layout.bottomWallDimensions;
    final left = dimensions.normalizedHorizontalPosition(area.column);
    final right = dimensions.normalizedHorizontalPosition(
      area.column + area.columnSpan,
    );
    final bottom = dimensions.normalizedVerticalPosition(area.row);
    final top = dimensions.normalizedVerticalPosition(area.row + area.rowSpan);
    final bottomLeft = _bottomWallPoint(scene, left, bottom);
    final bottomRight = _bottomWallPoint(scene, right, bottom);
    final topRight = _bottomWallPoint(scene, right, top);
    final topLeft = _bottomWallPoint(scene, left, top);

    return [bottomLeft, bottomRight, topRight, topLeft];
  }

  void _drawDashedPolygon(
    Canvas canvas,
    List<Offset> corners,
    LayoutSlotStyle style,
  ) {
    final paint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < corners.length; index += 1) {
      drawDashedLine(
        canvas,
        corners[index],
        corners[(index + 1) % corners.length],
        paint,
        dashLength: style.dashLength,
        gapLength: style.gapLength,
      );
    }
  }

  Offset _bottomWallLayoutAreaCenter(Rect scene, LayoutArea area) {
    final dimensions = _layout.bottomWallDimensions;
    final centerX = dimensions.normalizedHorizontalPosition(
      area.column + area.columnSpan / 2,
    );
    final centerY = dimensions.normalizedVerticalPosition(
      area.row + area.rowSpan / 2,
    );
    return _bottomWallPoint(
      scene,
      centerX.clamp(0.0, 1.0),
      centerY.clamp(0.0, 1.0),
    );
  }

  ({LayoutElement element, LayoutArea area})? _bottomWallNodeElement(
    GraphNode node,
  ) {
    final elements = _timelineElementsByNodeId[node.id];
    return elements == null || elements.isEmpty ? null : elements.first;
  }

  bool _hasBottomWallNodeElement(GraphNode node) =>
      _timelineElementsByNodeId.containsKey(node.id);

  GraphNode? _graphNodeForTimelineElement(LayoutElement element) =>
      _timelineNodesByElement[element];

  Iterable<_ResolvedTimelineElement> _resolvedTimelineElements() sync* {
    final timeline = _layout.bottomWallTimelineLayout;
    for (final element in timeline.elements.values) {
      yield (element: element, area: element.area);
    }
    for (final subLayout in timeline.subLayouts.values) {
      yield* _resolvedLayoutElements(subLayout.layout, subLayout.area);
    }
  }

  Iterable<_ResolvedTimelineElement> _resolvedLayoutElements(
    Layout layout,
    LayoutArea placement,
  ) sync* {
    for (final element in layout.elements.values) {
      yield (
        element: element,
        area: _placeLayoutArea(element.area, layout, placement),
      );
    }
    for (final subLayout in layout.subLayouts.values) {
      final nestedPlacement = _placeLayoutArea(
        subLayout.area,
        layout,
        placement,
      );
      yield* _resolvedLayoutElements(subLayout.layout, nestedPlacement);
    }
  }

  LayoutArea _placeLayoutArea(
    LayoutArea area,
    Layout layout,
    LayoutArea placement,
  ) {
    final dimensions = layout.dimensions;
    final left = dimensions.normalizedHorizontalPosition(area.column);
    final right = dimensions.normalizedHorizontalPosition(
      area.column + area.columnSpan,
    );
    final top = dimensions.dimensionCount > 1
        ? dimensions.normalizedVerticalPosition(area.row)
        : 0.0;
    final bottom = dimensions.dimensionCount > 1
        ? dimensions.normalizedVerticalPosition(area.row + area.rowSpan)
        : 1.0;

    return LayoutArea(
      column: placement.column + placement.columnSpan * left,
      row: placement.row + placement.rowSpan * top,
      columnSpan: placement.columnSpan * (right - left),
      rowSpan: placement.rowSpan * (bottom - top),
    );
  }

  LayoutArea _bottomWallTimelineElementArea(LayoutArea elementArea) {
    final timeline = _layout.bottomWallTimelineLayout;
    final placement = _layout.bottomWallTimelineArea;
    final dimensions = timeline.dimensions;
    final left = dimensions.normalizedHorizontalPosition(elementArea.column);
    final right = dimensions.normalizedHorizontalPosition(
      elementArea.column + elementArea.columnSpan,
    );
    final top = dimensions.normalizedVerticalPosition(elementArea.row);
    final bottom = dimensions.normalizedVerticalPosition(
      elementArea.row + elementArea.rowSpan,
    );
    final column = placement.column + placement.columnSpan * left;
    final row = placement.row + placement.rowSpan * top;

    return LayoutArea(
      column: column,
      row: row,
      columnSpan: placement.columnSpan * (right - left),
      rowSpan: placement.rowSpan * (bottom - top),
    );
  }

  Path _roundedPolygonPath(List<Offset> points, double radius) {
    if (points.length < 3 || radius <= 0) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path..close();
    }

    final path = Path();
    for (var index = 0; index < points.length; index += 1) {
      final previous = points[(index - 1) % points.length];
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final previousDistance = (previous - current).distance;
      final nextDistance = (next - current).distance;
      final cornerRadius = min(
        radius,
        min(previousDistance / 2, nextDistance / 2),
      );
      final entry =
          current + (previous - current) * (cornerRadius / previousDistance);
      final exit = current + (next - current) * (cornerRadius / nextDistance);

      if (index == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, exit.dx, exit.dy);
    }
    return path..close();
  }

  void _paintBottomWallTimeLabel(Canvas canvas, String label, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: graphLabelColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.white, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 32);
    painter.paint(canvas, offset - Offset(painter.width / 2, 0));
  }

  Color _wallColor(OpenBoxWall wall) {
    return switch (wall) {
      OpenBoxWall.top => topWallColor,
      OpenBoxWall.right => rightWallColor,
      OpenBoxWall.bottom => bottomWallColor,
      OpenBoxWall.left => leftWallColor,
    };
  }
}

bool _isFutureAnchor(GraphNode node) {
  final path = _normalizedVaultPath(node.path);
  return path == 'time/concept/future' || path.endsWith('/time/concept/future');
}

String _timelineLabelFromPath(String path) {
  final name = _normalizedVaultPath(path).split('/').last;
  return name
      .split('-')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _normalizedVaultPath(String path) {
  return path
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceFirst(RegExp(r'\.md$'), '');
}

bool _endsWithVaultPath(String path, String suffix) =>
    path == suffix || path.endsWith('/$suffix');
