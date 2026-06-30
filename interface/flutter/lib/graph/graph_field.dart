import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/interface_colors.dart';
import '../models/knowledge_graph.dart';
import '../models/open_box_spatial_layout.dart';
import '../utils/canvas_guides.dart';
import 'graph_layout.dart';

const _layout = OpenBoxSpatialLayout.defaults;

enum GuidelineAxis { horizontal, vertical }

class GuidelineComponent extends Component {
  GuidelineComponent({
    required this.axis,
    required this.viewportSize,
    required this.sceneCenter,
    this.color = InterfaceColors.guidelineRed,
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
  Color backgroundColor() => InterfaceColors.background;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll([
      GuidelineComponent(
        axis: GuidelineAxis.horizontal,
        viewportSize: () => size,
        sceneCenter: () => _sceneRect().center,
        color: _layout.desktop.guidelineColor,
      ),
      GuidelineComponent(
        axis: GuidelineAxis.vertical,
        viewportSize: () => size,
        sceneCenter: () => _sceneRect().center,
        color: _layout.desktop.guidelineColor,
      ),
    ]);
  }

  void setGraph(KnowledgeGraph graph) {
    _graph = graph;
    _positions = layoutGraph(graph);
  }

  Offset _screenPosition(String id) {
    GraphNode? node;
    for (final candidate in _graph.nodes) {
      if (candidate.id == id) {
        node = candidate;
        break;
      }
    }
    final bottomWallPosition = node == null
        ? null
        : _bottomWallNodePosition(node);
    if (bottomWallPosition != null) return bottomWallPosition;

    final normalized = _positions[id] ?? const Offset(0.5, 0.5);
    return Offset(
      _layout.desktop.horizontalPadding +
          normalized.dx *
              max(0, size.x - _layout.desktop.horizontalPadding * 2),
      _layout.desktop.topPadding +
          normalized.dy *
              max(
                0,
                size.y -
                    _layout.desktop.topPadding -
                    _layout.desktop.bottomPadding,
              ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scene = _sceneRect();
    _renderBoxWalls(canvas, scene);
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

    final importantNodes = [..._graph.nodes]
      ..sort((a, b) => b.weightedDegree.compareTo(a.weightedDegree));
    final labeled = {
      ...importantNodes.take(24).map((node) => node.id),
      ..._graph.nodes.where(_hasBottomWallNodePlacement).map((node) => node.id),
    };

    for (final node in _graph.nodes) {
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
      if (labeled.contains(node.id)) {
        final isOnWall = _hasBottomWallNodePlacement(node);
        final painter = TextPainter(
          text: TextSpan(
            text: node.title,
            style: TextStyle(
              color: isOnWall
                  ? InterfaceColors.wallLabel
                  : InterfaceColors.graphLabel,
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
    return Rect.fromLTRB(
      _layout.desktop.horizontalPadding,
      _layout.desktop.topPadding,
      max(
        _layout.desktop.horizontalPadding,
        size.x - _layout.desktop.horizontalPadding,
      ),
      _normalizedY(_layout.desktop.sceneBottomRatio),
    );
  }

  void _renderBoxWalls(Canvas canvas, Rect scene) {
    if (size.x <= 0 || size.y <= 0) return;

    _drawWall(canvas, [
      Offset.zero,
      Offset(size.x, 0),
      scene.topRight,
      scene.topLeft,
    ], _layout.desktop.topWallColor);
    _drawWall(canvas, [
      Offset(size.x, 0),
      Offset(size.x, size.y),
      scene.bottomRight,
      scene.topRight,
    ], _layout.desktop.rightWallColor);
    _drawWall(canvas, [
      Offset(0, size.y),
      Offset(size.x, size.y),
      scene.bottomRight,
      scene.bottomLeft,
    ], _layout.desktop.bottomWallColor);
    _drawWall(canvas, [
      Offset.zero,
      scene.topLeft,
      scene.bottomLeft,
      Offset(0, size.y),
    ], _layout.desktop.leftWallColor);
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
      ..color = _layout.desktop.guidelineColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _renderBottomWallGrid(canvas, scene, perspectivePaint);
    _renderBottomWallTimeAxis(canvas, scene);
    drawDashedLine(canvas, Offset.zero, scene.topLeft, perspectivePaint);
    drawDashedLine(canvas, Offset(size.x, 0), scene.topRight, perspectivePaint);
    drawDashedLine(
      canvas,
      Offset(0, size.y),
      scene.bottomLeft,
      perspectivePaint,
    );
    drawDashedLine(
      canvas,
      Offset(size.x, size.y),
      scene.bottomRight,
      perspectivePaint,
    );
    drawDashedLine(canvas, scene.topLeft, scene.topRight, perspectivePaint);
    drawDashedLine(canvas, scene.topRight, scene.bottomRight, perspectivePaint);
    drawDashedLine(
      canvas,
      scene.bottomRight,
      scene.bottomLeft,
      perspectivePaint,
    );
    drawDashedLine(canvas, scene.bottomLeft, scene.topLeft, perspectivePaint);
    _renderWallRowGuides(canvas, scene, perspectivePaint);
  }

  void _renderWallRowGuides(Canvas canvas, Rect scene, Paint paint) {
    final topLeft = Offset.zero;
    final topRight = Offset(size.x, 0);
    final bottomRight = Offset(size.x, size.y);
    final bottomLeft = Offset(0, size.y);

    _drawWallRowGuides(
      canvas: canvas,
      outerStart: topLeft,
      outerEnd: topRight,
      innerStart: scene.topLeft,
      innerEnd: scene.topRight,
      rows: _layout.desktop.topWallRows,
      paint: paint,
    );
    _drawWallRowGuides(
      canvas: canvas,
      outerStart: topRight,
      outerEnd: bottomRight,
      innerStart: scene.topRight,
      innerEnd: scene.bottomRight,
      rows: _layout.desktop.rightWallRows,
      paint: paint,
    );
    _drawWallRowGuides(
      canvas: canvas,
      outerStart: bottomLeft,
      outerEnd: bottomRight,
      innerStart: scene.bottomLeft,
      innerEnd: scene.bottomRight,
      rows: _layout.desktop.bottomWallRows,
      paint: paint,
    );
    _drawWallRowGuides(
      canvas: canvas,
      outerStart: topLeft,
      outerEnd: bottomLeft,
      innerStart: scene.topLeft,
      innerEnd: scene.bottomLeft,
      rows: _layout.desktop.leftWallRows,
      paint: paint,
    );
  }

  void _renderBottomWallGrid(Canvas canvas, Rect scene, Paint paint) {
    final grid = _layout.desktop.bottomWallGrid;
    final outerLeft = Offset(0, size.y);
    final outerRight = Offset(size.x, size.y);

    for (var column = 1; column < grid.columns; column += 1) {
      final t = column / grid.columns;
      drawDashedLine(
        canvas,
        Offset.lerp(outerLeft, outerRight, t)!,
        Offset.lerp(scene.bottomLeft, scene.bottomRight, t)!,
        paint,
      );
    }

    for (var row = 1; row < grid.rows; row += 1) {
      final t = row / grid.rows;
      drawDashedLine(
        canvas,
        Offset.lerp(outerLeft, scene.bottomLeft, t)!,
        Offset.lerp(outerRight, scene.bottomRight, t)!,
        paint,
      );
    }
  }

  void _renderBottomWallTimeAxis(Canvas canvas, Rect scene) {
    final axisY = _layout.desktop.bottomWallTimeAxisY.clamp(0.0, 1.0);
    final grid = _layout.desktop.bottomWallGrid;
    final nowX = _bottomWallCurrentHourX(DateTime.now());
    final axisPaint = Paint()
      ..color = InterfaceColors.bottomWallTimeAxis
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nowPaint = Paint()
      ..color = InterfaceColors.bottomWallNowPointer
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      _bottomWallPoint(scene, 0, axisY),
      _bottomWallPoint(scene, 1, axisY),
      axisPaint,
    );
    drawDashedLine(
      canvas,
      _bottomWallPoint(scene, nowX, 0),
      _bottomWallPoint(scene, nowX, 1),
      nowPaint,
      dashLength: 10,
      gapLength: 5,
    );

    for (var hour = 0; hour <= grid.columns; hour += 1) {
      final x = hour / grid.columns;
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
      final x = entry.key / grid.columns;
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
    return ((6 + hourOfToday) / 36).clamp(0.0, 1.0);
  }

  Offset _bottomWallPoint(Rect scene, double x, double y) {
    final left = Offset.lerp(Offset(0, size.y), scene.bottomLeft, y)!;
    final right = Offset.lerp(Offset(size.x, size.y), scene.bottomRight, y)!;
    return Offset.lerp(left, right, x)!;
  }

  Offset? _bottomWallNodePosition(GraphNode node) {
    final placement = _bottomWallNodePlacement(node);
    if (placement == null) return null;

    final grid = _layout.desktop.bottomWallGrid;
    final area = placement.area;
    final centerX = (area.column + area.columnSpan / 2) / grid.columns;
    final centerY = (area.row + area.rowSpan / 2) / grid.rows;
    return _bottomWallPoint(
      _sceneRect(),
      centerX.clamp(0.0, 1.0),
      centerY.clamp(0.0, 1.0),
    );
  }

  BottomWallNodePlacement? _bottomWallNodePlacement(GraphNode node) {
    final path = _normalizedVaultPath(node.path);
    for (final placement in _layout.desktop.bottomWallNodePlacements) {
      if (_endsWithVaultPath(path, placement.vaultPath)) return placement;
    }
    return null;
  }

  bool _hasBottomWallNodePlacement(GraphNode node) =>
      _bottomWallNodePlacement(node) != null;

  void _paintBottomWallTimeLabel(Canvas canvas, String label, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: InterfaceColors.graphLabel,
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

  void _drawWallRowGuides({
    required Canvas canvas,
    required Offset outerStart,
    required Offset outerEnd,
    required Offset innerStart,
    required Offset innerEnd,
    required int rows,
    required Paint paint,
  }) {
    for (var divider = 1; divider < rows; divider += 1) {
      final t = divider / rows;
      drawDashedLine(
        canvas,
        Offset.lerp(outerStart, innerStart, t)!,
        Offset.lerp(outerEnd, innerEnd, t)!,
        paint,
      );
    }
  }

  double _normalizedY(double value) {
    return _layout.desktop.topPadding +
        value *
            max(
              0,
              size.y -
                  _layout.desktop.topPadding -
                  _layout.desktop.bottomPadding,
            );
  }
}

bool _isFutureAnchor(GraphNode node) {
  final path = _normalizedVaultPath(node.path);
  return path == 'time/concept/future' || path.endsWith('/time/concept/future');
}

String _normalizedVaultPath(String path) {
  return path
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceFirst(RegExp(r'\.md$'), '');
}

bool _endsWithVaultPath(String path, String suffix) =>
    path == suffix || path.endsWith('/$suffix');
