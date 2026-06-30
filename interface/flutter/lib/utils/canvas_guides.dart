import 'dart:math';

import 'package:flutter/material.dart';

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
