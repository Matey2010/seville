import 'dart:math';

import 'package:flutter/material.dart';

import '../models/layout.dart';

void drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dashLength = 7,
  double gapLength = 5,
}) {
  final delta = end - start;
  final distance = delta.distance;
  if (distance == 0) return;

  final direction = delta / distance;
  var offset = 0.0;
  while (offset < distance) {
    final dashEnd = min(offset + dashLength, distance);
    canvas.drawLine(
      start + direction * offset,
      start + direction * dashEnd,
      paint,
    );
    offset += dashLength + gapLength;
  }
}

void drawGuideLine(Canvas canvas, Offset start, Offset end, GuideStyle style) {
  final paint = Paint()
    ..color = style.color
    ..strokeWidth = style.strokeWidth
    ..strokeCap = style.strokeCap
    ..style = PaintingStyle.stroke;
  switch (style.pattern) {
    case GuideLinePattern.solid:
      canvas.drawLine(start, end, paint);
    case GuideLinePattern.dashed:
      drawDashedLine(
        canvas,
        start,
        end,
        paint,
        dashLength: style.dashLength,
        gapLength: style.dashInterval,
      );
    case GuideLinePattern.dotted:
      _drawDottedLine(canvas, start, end, paint, style.dashInterval);
  }
}

void _drawDottedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint,
  double interval,
) {
  final delta = end - start;
  final distance = delta.distance;
  if (distance == 0) return;
  final direction = delta / distance;
  final step = interval <= 0 ? paint.strokeWidth * 2 : interval;
  for (var offset = 0.0; offset <= distance; offset += step) {
    canvas.drawCircle(
      start + direction * offset,
      paint.strokeWidth / 2,
      paint..style = PaintingStyle.fill,
    );
  }
}
