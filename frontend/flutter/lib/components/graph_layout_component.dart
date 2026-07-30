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

typedef GraphLayoutSurface = ({
  Size logicalSize,
  Path clipPath,
  Offset Function(double u, double v) project,
});

/// Flame-owned renderer, geometry, and interaction cycle for [GraphLayout].
class GraphLayoutComponent extends PositionComponent with TapCallbacks {
  GraphLayoutComponent({
    required this.layoutKey,
    required this.layout,
    required this.isLayoutVisible,
    required this.selectedNodes,
    required this.layoutContext,
    required this.nodeStyle,
    required this.surface,
    required this.isTapEnabled,
    required this.onNodeTap,
  });

  final String layoutKey;
  final GraphLayout layout;
  final bool Function() isLayoutVisible;
  final List<ResolvedVaultNode> Function() selectedNodes;
  final LayoutContext Function() layoutContext;
  final NodeStyle Function() nodeStyle;
  final GraphLayoutSurface? Function() surface;
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
    final resolvedSurface = surface();
    if (resolvedSurface == null) return;
    final nodes = _nodesInFrame(selectedNodes(), resolvedSurface);
    if (nodes.isEmpty) return;

    final borderStyle = layout.style;
    final borderWidth = layout.layoutBorderWidth ?? borderStyle.strokeWidth;
    final context = layoutContext();
    canvas.save();
    canvas.clipPath(resolvedSurface.clipPath);
    for (final graphNode in nodes) {
      canvas.drawPath(
        graphNode.path,
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
        graphNode.path,
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
    final resolvedSurface = surface();
    if (resolvedSurface == null) return null;
    for (final graphNode in _nodesInFrame(
      selectedNodes(),
      resolvedSurface,
    ).reversed) {
      if (!graphNode.path.contains(position)) continue;
      return (
        key: '$layoutKey/${graphNode.node.slug}',
        resolvedNode: graphNode.resolvedNode,
        node: graphNode.node,
        label: nodeLabel(graphNode.node),
        circleBounds: graphNode.circleBounds,
        path: graphNode.path,
      );
    }
    return null;
  }

  String nodeLabel(Node node) {
    final slug = node.slug.trim();
    return slug.isNotEmpty ? nodeStyle().formatSlug(slug) : node.displayLabel;
  }

  List<_GraphNodeFrame> _nodesInFrame(
    List<ResolvedVaultNode> selected,
    GraphLayoutSurface surface,
  ) {
    final resolvedNodes = [
      for (final resolvedNode in selected)
        if (resolvedNode.node case final node?)
          (resolvedNode: resolvedNode, node: node),
    ];
    final logicalSize = surface.logicalSize;
    if (resolvedNodes.isEmpty || logicalSize.isEmpty) return const [];
    final aspectRatio = logicalSize.width / logicalSize.height;
    final columnCount = math.min(
      resolvedNodes.length,
      math.max(1, math.sqrt(resolvedNodes.length * aspectRatio).ceil()),
    );
    final rowCount = (resolvedNodes.length / columnCount).ceil();
    final cellWidth = logicalSize.width / columnCount;
    final cellHeight = logicalSize.height / rowCount;
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
          logicalSize,
          surface.project,
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
    Size logicalSize,
    Offset Function(double u, double v) project,
  ) {
    final row = index ~/ columnCount;
    final column = index % columnCount;
    final rowStart = row * columnCount;
    final rowNodeCount = math.min(columnCount, nodes.length - rowStart);
    final rowLeft = (logicalSize.width - rowNodeCount * cellWidth) / 2;
    final center = Offset(
      (rowLeft + (column + 0.5) * cellWidth) / logicalSize.width,
      ((row + 0.5) * cellHeight) / logicalSize.height,
    );
    final radiusU = diameter / (2 * logicalSize.width);
    final radiusV = diameter / (2 * logicalSize.height);
    const sampleCount = 40;
    final path = Path();
    for (var sample = 0; sample <= sampleCount; sample += 1) {
      final theta = math.pi * 2 * sample / sampleCount;
      final point = project(
        center.dx + math.cos(theta) * radiusU,
        center.dy + math.sin(theta) * radiusV,
      );
      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return (
      resolvedNode: nodes[index].resolvedNode,
      node: nodes[index].node,
      circleBounds: path.getBounds(),
      path: path,
    );
  }

  void _paintNodeLabels(Canvas canvas, Node node, Rect bounds) {
    final resolvedNodeStyle = nodeStyle();
    final maxWidth = bounds.width * 0.8;
    if (maxWidth < layout.labelSize * 2) return;
    final slugPainter = _textPainter(
      nodeLabel(node),
      isSlug: true,
      maxWidth: maxWidth,
      color: resolvedNodeStyle.slugColor ?? NodeDefaults.slugColor,
      fontSize: layout.labelSize,
      fontFeatures:
          (resolvedNodeStyle.slugTransform ?? NodeDefaults.slugTransform)
              .fontFeatures,
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
      color: resolvedNodeStyle.labelColor ?? NodeDefaults.labelColor,
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
  Path path,
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
    text: LayoutText.defaultRepresentation(text),
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
