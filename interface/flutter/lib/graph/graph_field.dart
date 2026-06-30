import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/interface_colors.dart';
import '../models/knowledge_graph.dart';
import '../models/layout.dart';
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
    final scene = _sceneRect();
    return Offset(
      scene.left + normalized.dx * scene.width,
      scene.top + normalized.dy * scene.height,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scene = _sceneRect();
    _renderBoxWalls(canvas);
    _renderGlobalLayoutDimensions(canvas);
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
      if (_renderBottomWallNodePlacement(canvas, node)) continue;

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
    return _sceneLayoutAreaRect(_layout.globalLayout.boxBottomArea);
  }

  void _renderGlobalLayoutDimensions(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final dimensions = _layout.globalLayout.dimensions;
    final paint = Paint()
      ..color = InterfaceColors.globalLayoutDimensions
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var column = 1; column < dimensions.horizontal; column += 1) {
      final x = size.x * dimensions.normalizedHorizontalPosition(column);
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }

    for (var row = 1; row < dimensions.vertical; row += 1) {
      final y = size.y * dimensions.normalizedVerticalPosition(row);
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _renderBoxWalls(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    for (final glue in _layout.globalLayout.wallGlues) {
      _drawWall(canvas, [
        _sceneLayoutPointFrom(glue.outerStart),
        _sceneLayoutPointFrom(glue.outerEnd),
        _sceneLayoutPointFrom(glue.innerEnd),
        _sceneLayoutPointFrom(glue.innerStart),
      ], _wallColor(glue.wall));
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
      ..color = _layout.desktop.guidelineColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _renderBottomWallDimensions(canvas, scene, perspectivePaint);
    _renderBottomWallTimeAxis(canvas, scene);
    for (final glue in _layout.globalLayout.wallGlues) {
      final outerStart = _sceneLayoutPointFrom(glue.outerStart);
      final outerEnd = _sceneLayoutPointFrom(glue.outerEnd);
      final innerStart = _sceneLayoutPointFrom(glue.innerStart);
      final innerEnd = _sceneLayoutPointFrom(glue.innerEnd);

      drawDashedLine(canvas, outerStart, innerStart, perspectivePaint);
      drawDashedLine(canvas, outerEnd, innerEnd, perspectivePaint);
      drawDashedLine(canvas, innerStart, innerEnd, perspectivePaint);
    }
    _renderWallRowGuides(canvas, perspectivePaint);
  }

  void _renderWallRowGuides(Canvas canvas, Paint paint) {
    for (final glue in _layout.globalLayout.wallGlues) {
      _drawWallRowGuides(
        canvas: canvas,
        outerStart: _sceneLayoutPointFrom(glue.outerStart),
        outerEnd: _sceneLayoutPointFrom(glue.outerEnd),
        innerStart: _sceneLayoutPointFrom(glue.innerStart),
        innerEnd: _sceneLayoutPointFrom(glue.innerEnd),
        rows: _wallRows(glue.wall),
        paint: paint,
      );
    }
  }

  void _renderBottomWallDimensions(Canvas canvas, Rect scene, Paint paint) {
    final dimensions = _layout.desktop.bottomWallDimensions;
    final outerLeft = Offset(0, size.y);
    final outerRight = Offset(size.x, size.y);

    for (var column = 1; column < dimensions.horizontal; column += 1) {
      final t = dimensions.normalizedHorizontalPosition(column);
      drawDashedLine(
        canvas,
        Offset.lerp(outerLeft, outerRight, t)!,
        Offset.lerp(scene.bottomLeft, scene.bottomRight, t)!,
        paint,
      );
    }

    for (var row = 1; row < dimensions.vertical; row += 1) {
      final t = dimensions.normalizedVerticalPosition(row);
      drawDashedLine(
        canvas,
        Offset.lerp(scene.bottomLeft, outerLeft, t)!,
        Offset.lerp(scene.bottomRight, outerRight, t)!,
        paint,
      );
    }
  }

  void _renderBottomWallTimeAxis(Canvas canvas, Rect scene) {
    final dimensions = _layout.desktop.bottomWallDimensions;
    final axisTrack =
        dimensions.vertical - _layout.desktop.bottomWallTimeAxisTrackInset;
    final axisY = dimensions.normalizedVerticalPosition(axisTrack);
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

    for (var hour = 0; hour <= dimensions.horizontal; hour += 1) {
      final x = dimensions.normalizedHorizontalPosition(hour);
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
      final x = dimensions.normalizedHorizontalPosition(entry.key);
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
    final dimensions = _layout.globalLayout.dimensions;
    return Offset(
      size.x * dimensions.normalizedHorizontalPosition(column),
      size.y * dimensions.normalizedVerticalPosition(row),
    );
  }

  Offset _sceneLayoutPointFrom(LayoutPoint point) {
    return _sceneLayoutPoint(point.column, point.row);
  }

  Offset? _bottomWallNodePosition(GraphNode node) {
    final placement = _bottomWallNodePlacement(node);
    if (placement == null) return null;

    final dimensions = _layout.desktop.bottomWallDimensions;
    final area = placement.area;
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

  bool _renderBottomWallNodePlacement(Canvas canvas, GraphNode node) {
    final placement = _bottomWallNodePlacement(node);
    if (placement == null || placement.shape != BottomWallNodeShape.cellSpan) {
      return false;
    }

    final path = _bottomWallLayoutAreaPath(_sceneRect(), placement.area);
    canvas.drawPath(path, Paint()..color = node.color.withValues(alpha: 0.78));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final center = _bottomWallLayoutAreaCenter(_sceneRect(), placement.area);
    final painter = TextPainter(
      text: TextSpan(
        text: node.title,
        style: const TextStyle(
          color: InterfaceColors.wallLabel,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
    return true;
  }

  Path _bottomWallLayoutAreaPath(Rect scene, LayoutArea area) {
    final dimensions = _layout.desktop.bottomWallDimensions;
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

    return Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(topLeft.dx, topLeft.dy)
      ..close();
  }

  Offset _bottomWallLayoutAreaCenter(Rect scene, LayoutArea area) {
    final dimensions = _layout.desktop.bottomWallDimensions;
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

  Color _wallColor(OpenBoxWall wall) {
    return switch (wall) {
      OpenBoxWall.top => _layout.desktop.topWallColor,
      OpenBoxWall.right => _layout.desktop.rightWallColor,
      OpenBoxWall.bottom => _layout.desktop.bottomWallColor,
      OpenBoxWall.left => _layout.desktop.leftWallColor,
    };
  }

  int _wallRows(OpenBoxWall wall) {
    return switch (wall) {
      OpenBoxWall.top => _layout.desktop.topWallRows,
      OpenBoxWall.right => _layout.desktop.rightWallRows,
      OpenBoxWall.bottom => _layout.desktop.bottomWallRows,
      OpenBoxWall.left => _layout.desktop.leftWallRows,
    };
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
