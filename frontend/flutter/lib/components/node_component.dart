import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../models/layout.dart';

/// Shared Flame renderer for Node paint state and hover decoration.
class NodeComponent extends PositionComponent {
  Path? _hoverPath;
  GuideStyle? _hoverStyle;

  void updateHoverTarget(Path? path, GuideStyle? style) {
    _hoverPath = path;
    _hoverStyle = style;
  }

  static Color backgroundColor(
    Color color,
    String nodeSlug,
    LayoutContext layoutContext,
    Layout layout, {
    bool isVirtual = false,
  }) {
    final normalizedNodeSlug = nodeSlug.trim();
    final active =
        normalizedNodeSlug.isNotEmpty &&
        layoutContext.activeNodeSlugs.contains(normalizedNodeSlug);
    final opacity = isVirtual
        ? layout.virtualNodeBackgroundOpacity
        : active
        ? layout.activeNodeBackgroundOpacity
        : layout.inactiveNodeBackgroundOpacity;
    return color.withValues(alpha: opacity);
  }

  static void renderBorder(
    Canvas canvas,
    Path path,
    GuideStyle style,
    double strokeWidth, {
    required bool isVirtual,
  }) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = strokeWidth
      ..strokeCap = style.strokeCap
      ..style = PaintingStyle.stroke;
    if (!isVirtual) {
      canvas.drawPath(path, paint);
      return;
    }

    final dashLength = style.dashLength <= 0 ? 7.0 : style.dashLength;
    final dashInterval = style.dashInterval <= 0 ? 5.0 : style.dashInterval;
    for (final metric in path.computeMetrics()) {
      var offset = 0.0;
      while (offset < metric.length) {
        final end = math.min(offset + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(offset, end), paint);
        offset = end + dashInterval;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final path = _hoverPath;
    final style = _hoverStyle;
    if (path == null || style == null) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = style.color.withValues(alpha: 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth + 5
        ..strokeCap = style.strokeCap
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    renderBorder(canvas, path, style, style.strokeWidth, isVirtual: false);
  }
}
