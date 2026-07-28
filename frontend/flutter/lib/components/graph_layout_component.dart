import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:seville_proto/seville_proto.dart';

import '../constants/typography.dart';
import '../domain/node.dart';
import '../models/layout/layout.dart';
import 'node_component.dart';

typedef GraphLayoutNodeHit = ({
  String key,
  ResolvedVaultNode resolvedNode,
  Node node,
  String label,
  Rect circleBounds,
  Path path,
});

/// Flame-owned renderer, geometry, and interaction cycle for [GraphLayout].
class GraphLayoutComponent extends PositionComponent with TapCallbacks {
  GraphLayoutComponent({
    required this.layoutKey,
    required this.layout,
    required this.isLayoutVisible,
    required this.selectedNodes,
    required this.layoutContext,
    required this.planePoints,
    required this.isTapEnabled,
    required this.onNodeTap,
  });

  final String layoutKey;
  final GraphLayout layout;
  final bool Function() isLayoutVisible;
  final List<ResolvedVaultNode> Function() selectedNodes;
  final LayoutContext Function() layoutContext;
  final List<Offset>? Function() planePoints;
  final bool Function() isTapEnabled;
  final void Function(GraphLayoutNodeHit hit) onNodeTap;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    if (!isLayoutVisible()) return;
    final points = planePoints();
    if (points == null) return;
    final nodes = _nodesInFrame(selectedNodes(), points);
    if (nodes.isEmpty) return;

    final clipPath = _polygonPath(points);
    final borderStyle = layout.style;
    final borderWidth = layout.layoutBorderWidth ?? borderStyle.strokeWidth;
    final context = layoutContext();
    canvas.save();
    canvas.clipPath(clipPath);
    for (final graphNode in nodes) {
      final nodePath = Path()..addOval(graphNode.circleBounds);
      canvas.drawPath(
        nodePath,
        Paint()
          ..color = NodeComponent.backgroundColor(
            NodeComponent.colorFor(graphNode.node).resolve(),
            graphNode.node.slug,
            context,
            layout,
            isVirtual: graphNode.resolvedNode.isVirtual,
          )
          ..style = PaintingStyle.fill,
      );
      NodeComponent.renderBorder(
        canvas,
        nodePath,
        borderStyle,
        borderWidth,
        isVirtual: graphNode.resolvedNode.isVirtual,
      );
      _paintNodeLabels(canvas, graphNode.node, graphNode.circleBounds);
    }
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.continuePropagation = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    event.continuePropagation = true;
    if (!isTapEnabled()) return;
    final hit = hitTest(Offset(event.localPosition.x, event.localPosition.y));
    if (hit == null) return;
    onNodeTap(hit);
    event.continuePropagation = false;
  }

  GraphLayoutNodeHit? hitTest(Offset position) {
    if (!isLayoutVisible()) return null;
    final points = planePoints();
    if (points == null) return null;
    for (final graphNode in _nodesInFrame(selectedNodes(), points).reversed) {
      final path = Path()..addOval(graphNode.circleBounds);
      if (!path.contains(position)) continue;
      return (
        key: '$layoutKey/${graphNode.node.slug}',
        resolvedNode: graphNode.resolvedNode,
        node: graphNode.node,
        label: nodeLabel(graphNode.node),
        circleBounds: graphNode.circleBounds,
        path: path,
      );
    }
    return null;
  }

  String nodeLabel(Node node) {
    final slug = node.slug.trim();
    return slug.isNotEmpty ? layout.formatNodeSlug(slug) : node.displayLabel;
  }

  List<_GraphNodeFrame> _nodesInFrame(
    List<ResolvedVaultNode> selected,
    List<Offset> points,
  ) {
    final resolvedNodes = [
      for (final resolvedNode in selected)
        if (resolvedNode.node case final node?)
          (resolvedNode: resolvedNode, node: node),
    ];
    if (resolvedNodes.isEmpty || points.length < 3) return const [];

    final bounds = _boundsForPoints(points);
    if (bounds.isEmpty) return const [];
    final aspectRatio = bounds.width / bounds.height;
    final columnCount = math.min(
      resolvedNodes.length,
      math.max(1, math.sqrt(resolvedNodes.length * aspectRatio).ceil()),
    );
    final rowCount = (resolvedNodes.length / columnCount).ceil();
    final cellWidth = bounds.width / columnCount;
    final cellHeight = bounds.height / rowCount;
    final diameter = math.min(cellWidth, cellHeight) * layout.nodeExtentFactor;
    return [
      for (var index = 0; index < resolvedNodes.length; index += 1)
        _frameFor(
          resolvedNodes,
          index,
          columnCount,
          cellWidth,
          cellHeight,
          diameter,
          bounds,
        ),
    ];
  }

  _GraphNodeFrame _frameFor(
    List<({ResolvedVaultNode resolvedNode, Node node})> nodes,
    int index,
    int columnCount,
    double cellWidth,
    double cellHeight,
    double diameter,
    Rect bounds,
  ) {
    final row = index ~/ columnCount;
    final column = index % columnCount;
    final rowStart = row * columnCount;
    final rowNodeCount = math.min(columnCount, nodes.length - rowStart);
    final rowLeft = bounds.center.dx - rowNodeCount * cellWidth / 2;
    final center = Offset(
      rowLeft + (column + 0.5) * cellWidth,
      bounds.top + (row + 0.5) * cellHeight,
    );
    return (
      resolvedNode: nodes[index].resolvedNode,
      node: nodes[index].node,
      circleBounds: Rect.fromCircle(center: center, radius: diameter / 2),
    );
  }

  void _paintNodeLabels(Canvas canvas, Node node, Rect bounds) {
    final maxWidth = bounds.width * 0.8;
    if (maxWidth < layout.labelSize * 2) return;
    final slugPainter = _textPainter(
      nodeLabel(node),
      isSlug: true,
      maxWidth: maxWidth,
      color: layout.slugColor,
      fontSize: layout.labelSize,
      fontFeatures: layout.nodeSlugTransform.fontFeatures,
    );
    final emoji = node.primaryEmojiCharacter;
    if (emoji == null) {
      slugPainter.paint(
        canvas,
        bounds.center - Offset(slugPainter.width / 2, slugPainter.height / 2),
      );
      return;
    }

    final emojiPainter = _textPainter(
      emoji,
      isSlug: false,
      maxWidth: maxWidth,
      color: layout.labelColor,
      fontSize: layout.labelSize * layout.emojiFontSizeFactor,
    );
    final gap = layout.labelSize * layout.emojiSlugGapFactor;
    final contentHeight = emojiPainter.height + gap + slugPainter.height;
    final top = bounds.center.dy - contentHeight / 2;
    emojiPainter.paint(
      canvas,
      Offset(bounds.center.dx - emojiPainter.width / 2, top),
    );
    slugPainter.paint(
      canvas,
      Offset(
        bounds.center.dx - slugPainter.width / 2,
        top + emojiPainter.height + gap,
      ),
    );
  }
}

typedef _GraphNodeFrame = ({
  ResolvedVaultNode resolvedNode,
  Node node,
  Rect circleBounds,
});

TextPainter _textPainter(
  String text, {
  required bool isSlug,
  required double maxWidth,
  required Color color,
  required double fontSize,
  List<FontFeature>? fontFeatures,
}) => TextPainter(
  text: TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: isSlug ? null : SevilleTypography.fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: isSlug ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: fontFeatures,
    ),
  ),
  maxLines: 1,
  ellipsis: '…',
  textDirection: TextDirection.ltr,
  textAlign: TextAlign.center,
)..layout(maxWidth: maxWidth);

Path _polygonPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

Rect _boundsForPoints(List<Offset> points) {
  final xs = points.map((point) => point.dx);
  final ys = points.map((point) => point.dy);
  return Rect.fromLTRB(
    xs.reduce(math.min),
    ys.reduce(math.min),
    xs.reduce(math.max),
    ys.reduce(math.max),
  );
}
