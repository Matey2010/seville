import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:seville_proto/seville_proto.dart';

import '../models/layout/layout.dart';
import 'layout_component_registry.dart';
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
    required this.nodeConfig,
    required this.imageFor,
    required this.surface,
    required this.isTapEnabled,
    required this.onNodeTap,
  });

  final String layoutKey;
  final GraphLayout layout;
  final bool Function() isLayoutVisible;
  final List<ResolvedVaultNode> Function() selectedNodes;
  final LayoutContext Function() layoutContext;
  final NodeConfig Function(ResolvedVaultNode node) nodeConfig;
  final ui.Image? Function(String assetPath) imageFor;
  final LayoutSurface? Function() surface;
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

    final context = layoutContext();
    canvas.save();
    canvas.clipPath(resolvedSurface.clipPath);
    for (final graphNode in nodes) {
      final config = nodeConfig(graphNode.resolvedNode);
      final borderStyle = config.borderStyle ?? layout.style;
      final borderWidth = layout.layoutBorderWidth ?? borderStyle.strokeWidth;
      canvas.drawPath(
        graphNode.path,
        Paint()
          ..color = NodeComponent.backgroundColor(
            NodeComponent.colorFor(graphNode.node).resolve(),
            graphNode.node.slug,
            context,
            layout,
            isVirtual: graphNode.resolvedNode.isVirtual,
            config: config,
          )
          ..style = PaintingStyle.fill,
      );
      NodeComponent.paintBackgrounds(
        canvas,
        graphNode.path,
        graphNode.circleBounds,
        config.background,
        context.withCurrentNode(
          path: graphNode.resolvedNode.path,
          slug: graphNode.node.slug,
          labels: graphNode.node.labels,
        ),
        nodeKey: graphNode.node.slug.trim().isNotEmpty
            ? graphNode.node.slug.trim()
            : graphNode.resolvedNode.path,
        imageFor: imageFor,
      );
      NodeComponent.renderBorder(
        canvas,
        graphNode.path,
        borderStyle,
        borderWidth,
        isVirtual: graphNode.resolvedNode.isVirtual,
      );
      NodeComponent.paintLabels(
        canvas,
        graphNode.node,
        graphNode.circleBounds,
        config: config,
        text: config.text,
        emojiFontSizeFactor: layout.emojiFontSizeFactor,
        emojiSlugGapFactor: layout.emojiSlugGapFactor,
      );
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
        label: nodeLabel(graphNode.resolvedNode, graphNode.node),
        circleBounds: graphNode.circleBounds,
        path: graphNode.path,
      );
    }
    return null;
  }

  String nodeLabel(ResolvedVaultNode resolvedNode, Node node) {
    return NodeComponent.presentationLabel(node, nodeConfig(resolvedNode));
  }

  List<_GraphNodeFrame> _nodesInFrame(
    List<ResolvedVaultNode> selected,
    LayoutSurface surface,
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
}

typedef _GraphNodeFrame = ({
  ResolvedVaultNode resolvedNode,
  Node node,
  Rect circleBounds,
  Path path,
});
