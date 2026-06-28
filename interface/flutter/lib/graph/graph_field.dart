import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'graph_layout.dart';
import 'graph_model.dart';

class KnowledgeGraphGame extends FlameGame {
  late final _GraphField _field;
  KnowledgeGraph _graph = const KnowledgeGraph(nodes: [], edges: []);

  @override
  Color backgroundColor() => Colors.deepPurpleAccent;

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

  void setGraph(KnowledgeGraph graph) {
    _graph = graph;
    _positions = layoutGraph(graph);
  }

  Offset _screenPosition(String id) {
    const horizontalMargin = 24.0;
    const topMargin = 24.0;
    const bottomMargin = 20.0;
    final normalized = _positions[id] ?? const Offset(0.5, 0.5);
    return Offset(
      horizontalMargin + normalized.dx * max(0, size.x - horizontalMargin * 2),
      topMargin + normalized.dy * max(0, size.y - topMargin - bottomMargin),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderTimelineRail(canvas);

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
      ..._graph.nodes.where(_isTimelineAnchor).map((node) => node.id),
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
        final painter = TextPainter(
          text: TextSpan(
            text: node.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
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

  void _renderTimelineRail(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final railTop = _normalizedY(0.86);
    final railCenter = _normalizedY(0.975);
    canvas.drawRect(
      Rect.fromLTRB(0, railTop, size.x, size.y),
      Paint()..color = const Color(0xB3090B12),
    );
    canvas.drawLine(
      Offset(24, railTop),
      Offset(size.x - 24, railTop),
      Paint()
        ..color = const Color(0x445D4A88)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(24, railCenter),
      Offset(size.x - 24, railCenter),
      Paint()
        ..color = const Color(0x665D4A88)
        ..strokeWidth = 1.2,
    );
  }

  double _normalizedY(double value) {
    const topMargin = 24.0;
    const bottomMargin = 20.0;
    return topMargin + value * max(0, size.y - topMargin - bottomMargin);
  }
}

bool _isTimelineAnchor(GraphNode node) {
  final path = node.path
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceFirst(RegExp(r'\.md$'), '');
  return path.endsWith('/time/concept/past') ||
      path.endsWith('/time/concept/now') ||
      path.endsWith('/time/concept/future') ||
      path == 'time/concept/past' ||
      path == 'time/concept/now' ||
      path == 'time/concept/future';
}

bool _isFutureAnchor(GraphNode node) {
  final path = node.path
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceFirst(RegExp(r'\.md$'), '');
  return path == 'time/concept/future' || path.endsWith('/time/concept/future');
}
