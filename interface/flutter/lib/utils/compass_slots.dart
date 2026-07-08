import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/compass_layout.dart';
import 'canvas_guides.dart';

typedef _ResolvedCompassSlot = ({
  CompassSlot slot,
  double startDegrees,
  double spanDegrees,
});

void drawCompassSlots(
  Canvas canvas,
  Size size,
  CompassLayout layout, {
  required Rect mainBounds,
}) {
  if (size.isEmpty || mainBounds.isEmpty || layout.compassSlots.isEmpty) {
    return;
  }

  final resolvedSlots = _resolveCompassSlots(layout);
  if (resolvedSlots.isEmpty) return;

  final center = mainBounds.center;
  final viewport = layout.frame.resolve(size);
  final boundaries = <double>{};
  for (final resolved in resolvedSlots) {
    if (resolved.spanDegrees <= 0) continue;
    boundaries
      ..add(_normalizedDegrees(resolved.startDegrees))
      ..add(_normalizedDegrees(resolved.startDegrees + resolved.spanDegrees));
    _drawSlotLabel(
      canvas,
      viewport,
      mainBounds,
      center,
      resolved,
      layout.compassSlotStyle,
    );
  }

  if (boundaries.length == 1 && _coversFullCircle(resolvedSlots)) return;
  for (final degrees in boundaries) {
    final direction = _directionForDegrees(degrees);
    final start = _rayRectIntersection(center, direction, mainBounds);
    final end = _rayRectIntersection(center, direction, viewport);
    _drawBoundary(canvas, start, end, layout.compassSlotStyle);
  }
}

List<_ResolvedCompassSlot> _resolveCompassSlots(CompassLayout layout) {
  final sweep = layout.compassGeometry.sweepDegrees.clamp(0, 360).toDouble();
  if (sweep <= 0) return const [];

  var fixedDegrees = 0.0;
  var flexWeight = 0.0;
  for (final slot in layout.compassSlots) {
    final span = slot.spanDegrees;
    if (span == null) {
      flexWeight += _slotWeight(slot);
    } else {
      fixedDegrees += span.clamp(0, sweep);
    }
  }
  final availableFlexDegrees = math.max(0.0, sweep - fixedDegrees);
  var cursor = layout.compassGeometry.startDegrees;
  final resolvedSlots = <_ResolvedCompassSlot>[];
  for (final slot in layout.compassSlots) {
    final startDegrees = slot.startDegrees ?? cursor;
    final spanDegrees = _resolvedSpan(
      slot,
      sweep,
      availableFlexDegrees,
      flexWeight,
    );
    resolvedSlots.add((
      slot: slot,
      startDegrees: startDegrees,
      spanDegrees: spanDegrees,
    ));
    cursor = startDegrees + spanDegrees;
  }
  return resolvedSlots;
}

double _resolvedSpan(
  CompassSlot slot,
  double sweep,
  double availableFlexDegrees,
  double flexWeight,
) {
  final fixedSpan = slot.spanDegrees;
  if (fixedSpan != null) return fixedSpan.clamp(0, sweep).toDouble();
  if (flexWeight <= 0) return 0;
  return availableFlexDegrees * _slotWeight(slot) / flexWeight;
}

double _slotWeight(CompassSlot slot) {
  return (slot.slot.fraction ?? 1).clamp(0, double.infinity).toDouble();
}

void _drawSlotLabel(
  Canvas canvas,
  Rect viewport,
  Rect mainBounds,
  Offset center,
  _ResolvedCompassSlot resolved,
  CompassSlotStyle style,
) {
  final label = resolved.slot.slot.label;
  if (label.isEmpty) return;

  final middleDegrees = resolved.startDegrees + resolved.spanDegrees / 2;
  final direction = _directionForDegrees(middleDegrees);
  final inner = _rayRectIntersection(center, direction, mainBounds);
  final outer = _rayRectIntersection(center, direction, viewport);
  final labelCenter = Offset.lerp(inner, outer, 0.35)!;
  final availableWidth = math.max(0.0, (outer - inner).distance * 0.6);
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: style.guideStyle.color,
        fontSize: style.fontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: availableWidth);
  painter.paint(
    canvas,
    labelCenter - Offset(painter.width / 2, painter.height / 2),
  );
}

Offset _directionForDegrees(double degrees) {
  final radians = (degrees - 90) * math.pi / 180;
  return Offset(math.cos(radians), math.sin(radians));
}

Offset _rayRectIntersection(Offset origin, Offset direction, Rect bounds) {
  final horizontalDistance = direction.dx == 0
      ? double.infinity
      : (direction.dx > 0
                ? bounds.right - origin.dx
                : origin.dx - bounds.left) /
            direction.dx.abs();
  final verticalDistance = direction.dy == 0
      ? double.infinity
      : (direction.dy > 0
                ? bounds.bottom - origin.dy
                : origin.dy - bounds.top) /
            direction.dy.abs();
  final distance = math.min(horizontalDistance, verticalDistance);
  return origin + direction * math.max(0, distance);
}

void _drawBoundary(
  Canvas canvas,
  Offset start,
  Offset end,
  CompassSlotStyle style,
) {
  drawGuideLine(canvas, start, end, style.guideStyle);
}

double _normalizedDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

bool _coversFullCircle(List<_ResolvedCompassSlot> slots) {
  return slots.length == 1 && slots.single.spanDegrees >= 360;
}
