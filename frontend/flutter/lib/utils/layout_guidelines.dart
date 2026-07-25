import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/layout.dart';
import 'canvas_guides.dart';

void drawLayoutGuidelines(
  Canvas canvas,
  Size size,
  Layout layout, [
  LayoutContext context = LayoutContext.empty,
]) {
  if (size.isEmpty) return;

  for (final guide in layout.layouts.values.whereType<LayoutGuide>()) {
    if (!guide.visible || !guide.isVisible(context)) continue;
    if (guide is CirleLayout) {
      _drawCircleGuide(canvas, size, layout, guide);
    } else if (guide is LayoutBorderGuide) {
      _drawBorderGuide(canvas, size, layout, guide, context);
    }
  }
}

void _drawBorderGuide(
  Canvas canvas,
  Size size,
  Layout layout,
  LayoutBorderGuide guide,
  LayoutContext context,
) {
  final bounds = _resolveBorderBounds(size, layout, guide);
  final derivatives = layout.resolveDerivatives(size, null, context);
  final anchors = <({String id, Offset position})>[
    for (final id in guide.derivativeAnchors)
      if (derivatives[id] case final position?) (id: id, position: position),
    for (final anchor in guide.anchors)
      (id: anchor.id, position: anchor.resolve(bounds)),
  ];
  final corners = anchors.isEmpty
      ? [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft]
      : [for (final anchor in anchors) anchor.position];

  if (guide.shape == LayoutBorderShape.circle) {
    Offset? center;
    Offset? radiusPoint;
    for (final anchor in anchors) {
      if (anchor.id.toLowerCase().contains('center')) {
        center ??= anchor.position;
      } else {
        radiusPoint ??= anchor.position;
      }
    }
    if (center != null && radiusPoint != null) {
      _drawCircleByCenterRadius(
        canvas,
        center,
        (radiusPoint - center).distance,
        guide.style,
      );
    } else {
      _drawCircleByCenterRadius(
        canvas,
        bounds.center,
        bounds.shortestSide / 2,
        guide.style,
      );
    }
    for (final anchor in anchors) {
      _drawAnchorLabel(
        canvas,
        bounds.center,
        anchor.position,
        anchor.id,
        guide,
      );
    }
    return;
  }

  for (var index = 0; index < corners.length; index += 1) {
    drawGuideLine(
      canvas,
      corners[index],
      corners[(index + 1) % corners.length],
      guide.style,
    );
  }

  final anchorPaint = Paint()
    ..color = guide.style.color
    ..style = PaintingStyle.fill;
  for (final anchor in anchors) {
    final position = anchor.position;
    canvas.drawCircle(position, guide.anchorRadius, anchorPaint);
    if (guide.showAnchorDirections) {
      final delta = position - bounds.center;
      final distance = delta.distance;
      if (distance > 0) {
        drawGuideLine(
          canvas,
          position,
          position + delta / distance * guide.anchorDirectionLength,
          guide.style,
        );
      }
    }
    _drawAnchorLabel(canvas, bounds.center, position, anchor.id, guide);
  }
}

Rect _resolveBorderBounds(Size size, Layout layout, LayoutBorderGuide guide) {
  final fullBounds = Offset.zero & size;
  if (guide.reference == LayoutBorderReference.bounds) return fullBounds;
  final boundary = guide.reference == LayoutBorderReference.innerCircle
      ? LayoutCircleBoundary.inner
      : LayoutCircleBoundary.outer;
  final center = layout.resolveCircleCenter(
    size,
    boundary,
    useLayoutDefaults: guide.useLayoutDefaults,
  );
  final radius = layout.resolveCircleRadius(
    size,
    boundary,
    useLayoutDefaults: guide.useLayoutDefaults,
  );
  final halfExtent = guide.shape == LayoutBorderShape.square
      ? radius / math.sqrt2
      : radius;
  return Rect.fromCenter(
    center: center,
    width: halfExtent * 2,
    height: halfExtent * 2,
  );
}

void _drawAnchorLabel(
  Canvas canvas,
  Offset center,
  Offset anchor,
  String label,
  LayoutBorderGuide guide,
) {
  final direction = anchor - center;
  final distance = direction.distance;
  final outward = distance == 0 ? Offset.zero : direction / distance * 10;
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: guide.style.color,
        fontSize: guide.labelFontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    anchor + outward - Offset(painter.width / 2, painter.height / 2),
  );
}

void _drawCircleGuide(
  Canvas canvas,
  Size size,
  Layout layout,
  CirleLayout guide,
) {
  final center = layout.resolveCircleCenter(size, guide.boundary);
  final radius = layout.resolveCircleRadius(size, guide.boundary);
  if (radius <= 0) return;

  _drawCircleByCenterRadius(canvas, center, radius, guide.style);
}

void _drawCircleByCenterRadius(
  Canvas canvas,
  Offset center,
  double radius,
  GuideStyle style,
) {
  if (radius <= 0) return;
  final paint = Paint()
    ..color = style.color
    ..strokeWidth = style.strokeWidth
    ..strokeCap = style.strokeCap
    ..style = PaintingStyle.stroke;
  if (style.pattern == GuideLinePattern.solid) {
    canvas.drawCircle(center, radius, paint);
    return;
  }

  final circumference = 2 * math.pi * radius;
  final step = style.pattern == GuideLinePattern.dotted
      ? math.max(style.dashInterval, style.strokeWidth * 2)
      : style.dashLength + style.dashInterval;
  for (var distance = 0.0; distance < circumference; distance += step) {
    final angle = distance / radius;
    if (style.pattern == GuideLinePattern.dotted) {
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        style.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      continue;
    }
    final sweep = math.min(style.dashLength, circumference - distance) / radius;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle,
      sweep,
      false,
      paint,
    );
  }
}
