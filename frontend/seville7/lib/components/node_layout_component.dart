import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:seville_proto/seville_proto.dart';

import '../models/layout/layout.dart';
import 'layout_component_registry.dart';
import 'node_component.dart';

typedef NodeLayoutHit = ({
  String key,
  ResolvedVaultNode resolvedNode,
  Node node,
  String label,
  Path path,
});

/// Flame-owned single-Node renderer for [NodeLayout].
class NodeLayoutComponent extends PositionComponent with TapCallbacks {
  NodeLayoutComponent({
    required this.layoutKey,
    required this.layout,
    required this.isLayoutVisible,
    required this.resolvedNode,
    required this.layoutContext,
    required this.nodeConfig,
    required this.imageFor,
    required this.surface,
    required this.isTapEnabled,
    required this.onNodeTap,
  });

  final String layoutKey;
  final NodeLayout layout;
  final bool Function() isLayoutVisible;
  final ResolvedVaultNode? Function() resolvedNode;
  final LayoutContext Function() layoutContext;
  final NodeConfig Function(ResolvedVaultNode node) nodeConfig;
  final ui.Image? Function(String assetPath) imageFor;
  final LayoutSurface? Function() surface;
  final bool Function() isTapEnabled;
  final void Function(NodeLayoutHit hit) onNodeTap;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    final frame = _frame();
    if (frame == null) return;
    final config = nodeConfig(frame.resolvedNode);
    final borderStyle = config.borderStyle ?? layout.style;
    final borderWidth = layout.layoutBorderWidth ?? borderStyle.strokeWidth;
    canvas.save();
    canvas.clipPath(frame.surface.clipPath);
    canvas.drawPath(
      frame.path,
      Paint()
        ..color = NodeComponent.backgroundColor(
          NodeComponent.colorFor(frame.node).resolve(),
          frame.node.slug,
          layoutContext(),
          layout,
          isVirtual: frame.resolvedNode.isVirtual,
          config: config,
        )
        ..style = PaintingStyle.fill,
    );
    NodeComponent.paintBackgrounds(
      canvas,
      frame.path,
      frame.path.getBounds(),
      config.background,
      layoutContext().withCurrentNode(
        path: frame.resolvedNode.path,
        slug: frame.node.slug,
        labels: frame.node.labels,
      ),
      nodeKey: frame.node.slug.trim().isNotEmpty
          ? frame.node.slug.trim()
          : frame.resolvedNode.path,
      imageFor: imageFor,
    );
    NodeComponent.renderBorder(
      canvas,
      frame.path,
      borderStyle,
      borderWidth,
      isVirtual: frame.resolvedNode.isVirtual,
    );
    NodeComponent.paintLabels(
      canvas,
      frame.node,
      frame.path.getBounds(),
      config: config,
      text: config.text,
      emojiFontSizeFactor: layout.emojiFontSizeFactor,
      emojiSlugGapFactor: layout.emojiSlugGapFactor,
    );
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

  NodeLayoutHit? hitTest(Offset position) {
    final frame = _frame();
    if (frame == null || !frame.path.contains(position)) return null;
    return (
      key: '$layoutKey/${frame.node.slug}',
      resolvedNode: frame.resolvedNode,
      node: frame.node,
      label: NodeComponent.presentationLabel(
        frame.node,
        nodeConfig(frame.resolvedNode),
      ),
      path: frame.path,
    );
  }

  _NodeLayoutFrame? _frame() {
    if (!isLayoutVisible()) return null;
    final resolved = resolvedNode();
    final node = resolved?.node;
    final resolvedSurface = surface();
    if (resolved == null || node == null || resolvedSurface == null) {
      return null;
    }
    final logicalSize = resolvedSurface.logicalSize;
    if (logicalSize.isEmpty) return null;
    return (
      resolvedNode: resolved,
      node: node,
      surface: resolvedSurface,
      path: resolvedSurface.clipPath,
    );
  }
}

typedef _NodeLayoutFrame = ({
  ResolvedVaultNode resolvedNode,
  Node node,
  LayoutSurface surface,
  Path path,
});
