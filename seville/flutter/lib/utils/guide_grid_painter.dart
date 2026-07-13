import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/layout.dart';
import 'canvas_guides.dart';

class GuideGridProjection {
  const GuideGridProjection({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  Offset point(double x, double y) {
    final left = Offset.lerp(topLeft, bottomLeft, y)!;
    final right = Offset.lerp(topRight, bottomRight, y)!;
    return Offset.lerp(left, right, x)!;
  }

  GuideGridProjection area(LayoutDimensions dimensions, LayoutArea area) {
    final left = dimensions.normalizedHorizontalPosition(area.column);
    final right = dimensions.normalizedHorizontalPosition(
      area.column + area.columnSpan,
    );
    final top = dimensions.normalizedVerticalPosition(area.row);
    final bottom = dimensions.normalizedVerticalPosition(
      area.row + area.rowSpan,
    );
    return GuideGridProjection(
      topLeft: point(left, top),
      topRight: point(right, top),
      bottomLeft: point(left, bottom),
      bottomRight: point(right, bottom),
    );
  }
}

void drawGuideGrids(
  Canvas canvas,
  Layout layout,
  GuideGridProjection projection, {
  bool drawSubLayouts = true,
}) {
  final dimensions = layout.dimensions;
  if (dimensions.dimensionCount >= 2) {
    for (final guide in layout.layouts.values.whereType<LayoutGuide>()) {
      if (guide is! GuideGrid ||
          !guide.visible ||
          guide.geometry != GuideGridGeometry.cartesian) {
        continue;
      }
      if (guide.renderMode == GuideGridRenderMode.intersections) {
        _drawGridIntersections(canvas, projection, dimensions, guide);
      } else {
        _drawGridLines(canvas, projection, dimensions, guide);
      }
    }
  }

  if (!drawSubLayouts || dimensions.dimensionCount < 2) return;
  for (final subLayout in layout.subLayouts.values) {
    if (subLayout.layout.dimensionCount < 2) continue;
    drawGuideGrids(
      canvas,
      subLayout.layout,
      projection.area(dimensions, subLayout.area),
    );
  }
}

void _drawGridLines(
  Canvas canvas,
  GuideGridProjection projection,
  LayoutDimensions dimensions,
  GuideGrid grid,
) {
  final style = grid.style;

  if (grid.drawColumns) {
    for (var column = 1; column < dimensions.horizontal; column += 1) {
      final position = dimensions.normalizedHorizontalPosition(column);
      drawGuideLine(
        canvas,
        projection.point(position, 0),
        projection.point(position, 1),
        style,
      );
    }
  }

  if (grid.drawRows) {
    for (var row = 1; row < dimensions.vertical; row += 1) {
      final position = dimensions.normalizedVerticalPosition(row);
      drawGuideLine(
        canvas,
        projection.point(0, position),
        projection.point(1, position),
        style,
      );
    }
  }
}

void _drawGridIntersections(
  Canvas canvas,
  GuideGridProjection projection,
  LayoutDimensions dimensions,
  GuideGrid grid,
) {
  if (!grid.drawColumns ||
      !grid.drawRows ||
      grid.intersectionSize <= 0 ||
      dimensions.horizontal <= 1 ||
      dimensions.vertical <= 1) {
    return;
  }

  final points = Float32List(
    (dimensions.horizontal - 1) * (dimensions.vertical - 1) * 2,
  );
  var offset = 0;
  for (var row = 1; row < dimensions.vertical; row += 1) {
    final y = dimensions.normalizedVerticalPosition(row);
    for (var column = 1; column < dimensions.horizontal; column += 1) {
      final x = dimensions.normalizedHorizontalPosition(column);
      final point = projection.point(x, y);
      points[offset] = point.dx;
      points[offset + 1] = point.dy;
      offset += 2;
    }
  }
  canvas.drawRawPoints(
    ui.PointMode.points,
    points,
    Paint()
      ..color = grid.style.color
      ..strokeWidth = grid.intersectionSize
      ..strokeCap = grid.style.strokeCap,
  );
}
