import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/compass_layout.dart';

class CompassFigureClipper extends CustomClipper<Path> {
  const CompassFigureClipper(this.figure);

  final CompassMainFigure figure;

  @override
  Path getClip(Size size) => _figurePath(Offset.zero & size, figure);

  @override
  bool shouldReclip(CompassFigureClipper oldClipper) {
    return oldClipper.figure != figure;
  }
}

void drawCompassMainFigure(
  Canvas canvas,
  Rect bounds,
  CompassMainSlot mainSlot,
) {
  final config = mainSlot.figureConfig;
  if (bounds.isEmpty ||
      config == null ||
      mainSlot.figure == CompassMainFigure.layout ||
      !config.paintSurface) {
    return;
  }

  final path = _figurePath(bounds, mainSlot.figure);
  canvas.drawPath(
    path,
    Paint()
      ..color = config.fillColor
      ..style = PaintingStyle.fill,
  );
  _drawParallelLines(canvas, bounds, path, config);
  canvas.drawPath(
    path,
    Paint()
      ..color = config.borderColor
      ..strokeWidth = config.borderWidth
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke,
  );
}

void drawCompassMainFigureBorder(
  Canvas canvas,
  Rect bounds,
  CompassMainSlot mainSlot,
) {
  final config = mainSlot.figureConfig;
  if (bounds.isEmpty ||
      config == null ||
      !config.paintBorder ||
      mainSlot.figure == CompassMainFigure.layout) {
    return;
  }
  canvas.drawPath(
    _figurePath(bounds, mainSlot.figure),
    Paint()
      ..color = config.borderColor
      ..strokeWidth = config.borderWidth
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke,
  );
}

Path _figurePath(Rect bounds, CompassMainFigure figure) {
  return switch (figure) {
    CompassMainFigure.circle =>
      Path()..addOval(
        Rect.fromCircle(
          center: bounds.center,
          radius: math.min(bounds.width, bounds.height) / 2,
        ),
      ),
    CompassMainFigure.triangle =>
      Path()
        ..moveTo(bounds.center.dx, bounds.top)
        ..lineTo(bounds.right, bounds.bottom)
        ..lineTo(bounds.left, bounds.bottom)
        ..close(),
    CompassMainFigure.square =>
      Path()..addRect(
        Rect.fromCenter(
          center: bounds.center,
          width: math.min(bounds.width, bounds.height),
          height: math.min(bounds.width, bounds.height),
        ),
      ),
    CompassMainFigure.star => _starPath(bounds),
    CompassMainFigure.layout => Path(),
  };
}

Path _starPath(Rect bounds) {
  final center = bounds.center;
  final outerRadius = math.min(bounds.width, bounds.height) / 2;
  final innerRadius = outerRadius * 0.45;
  final path = Path();
  for (var point = 0; point < 10; point += 1) {
    final radius = point.isEven ? outerRadius : innerRadius;
    final angle = -math.pi / 2 + point * math.pi / 5;
    final offset = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (point == 0) {
      path.moveTo(offset.dx, offset.dy);
    } else {
      path.lineTo(offset.dx, offset.dy);
    }
  }
  return path..close();
}

void _drawParallelLines(
  Canvas canvas,
  Rect bounds,
  Path clipPath,
  CompassFigureConfig config,
) {
  if (config.parallelLineCount <= 0 ||
      config.lineDirection == CompassFigureLineDirection.none) {
    return;
  }

  final paint = Paint()
    ..color = config.lineColor
    ..strokeWidth = config.lineWidth
    ..style = PaintingStyle.stroke;
  canvas
    ..save()
    ..clipPath(clipPath);
  for (var index = 1; index <= config.parallelLineCount; index += 1) {
    final fraction = index / (config.parallelLineCount + 1);
    if (config.lineDirection == CompassFigureLineDirection.vertical) {
      final x = bounds.left + bounds.width * fraction;
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), paint);
    } else {
      final y = bounds.top + bounds.height * fraction;
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
    }
  }
  canvas.restore();
}
