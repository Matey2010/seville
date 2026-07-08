import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/compass_layout.dart';
import '../models/layout.dart';
import 'canvas_guides.dart';

typedef _ResolvedTimeCompassSlot = ({
  TimeCompassSlot placement,
  double columnStart,
  double columnEnd,
  double rowStart,
  double rowEnd,
});

void drawTimeCompass(Canvas canvas, Size size, TimeCompassLayout layout) {
  final radialGrid = layout.guideGrid(GuideGridGeometry.radial);
  if (size.isEmpty ||
      radialGrid == null ||
      !radialGrid.visible ||
      layout.layers.isEmpty ||
      layout.angularFractionCount <= 0) {
    return;
  }

  final geometry = layout.geometry;
  final frame = layout.frame.resolve(size);
  final center = Offset(
    frame.left + frame.width * geometry.centerXFraction,
    frame.top + frame.height * geometry.centerYFraction,
  );
  final availableRadius = math.min(
    center.dx - frame.left,
    frame.right - center.dx,
  );
  final outerRadius =
      availableRadius * geometry.outerRadiusFraction.clamp(0.0, 1.0).toDouble();
  final innerRadius =
      outerRadius * geometry.innerRadiusFraction.clamp(0.0, 1.0).toDouble();
  if (outerRadius <= innerRadius) return;

  final startAngle = geometry.startAngleRadians + geometry.rotationRadians;
  final sweepAngle = geometry.sweepAngleRadians;
  final resolvedSlots = _resolveSlots(layout);
  final angularFractionCount = layout.angularFractionCount.isFinite
      ? layout.angularFractionCount
      : resolvedSlots.fold<double>(
          0,
          (maximum, slot) => math.max(maximum, slot.columnEnd),
        );
  if (angularFractionCount <= 0) return;
  if (radialGrid.drawRows) {
    _drawLayerBoundaries(
      canvas,
      center,
      innerRadius,
      outerRadius,
      startAngle,
      sweepAngle,
      layout,
      resolvedSlots,
      angularFractionCount,
      radialGrid.style,
    );
  }
  if (radialGrid.drawColumns) {
    _drawVirtualColumns(
      canvas,
      center,
      _rowRadius(
        innerRadius,
        outerRadius,
        layout.layers,
        layout.virtualColumnStartRow,
      ),
      outerRadius,
      startAngle,
      sweepAngle,
      layout,
      angularFractionCount,
    );
    _drawSlots(
      canvas,
      center,
      innerRadius,
      outerRadius,
      startAngle,
      sweepAngle,
      layout,
      resolvedSlots,
      angularFractionCount,
    );
  }
  _drawCenterSlot(canvas, frame, center, layout);
}

void _drawCenterSlot(
  Canvas canvas,
  Rect frame,
  Offset center,
  TimeCompassLayout layout,
) {
  final centerSlot = layout.centerSlot;
  if (centerSlot == null) return;

  final meepleConfig = layout.meepleLayout.config;
  final availableHeight =
      frame.height * layout.mainSlot.availableSizeFraction.height;
  final radius =
      meepleConfig.meepleWidthFor(availableHeight) / 2 +
      meepleConfig.padding.top;
  if (!radius.isFinite || radius <= 0) return;

  final bounds = Rect.fromCircle(center: center, radius: radius);
  final stage = Path()
    ..moveTo(center.dx - radius, center.dy)
    ..arcTo(bounds, math.pi, -math.pi, false)
    ..close();
  canvas.drawPath(
    stage,
    Paint()
      ..color = centerSlot.backgroundColor
      ..style = PaintingStyle.fill,
  );
  final radialGrid = layout.guideGrid(GuideGridGeometry.radial);
  if (radialGrid != null && radialGrid.visible) {
    _drawArc(canvas, center, radius, math.pi, -math.pi, radialGrid.style);
  }
  _paintSlotLabel(
    canvas,
    centerSlot.slot.label,
    center + Offset(0, radius / 2),
    radius * 1.7,
    layout.slotStyle,
  );
}

List<_ResolvedTimeCompassSlot> _resolveSlots(TimeCompassLayout layout) {
  final resolved = <_ResolvedTimeCompassSlot>[];
  final rowCursors = List<double>.filled(layout.layers.length, 0);
  final configuredLimit = layout.angularFractionCount.isFinite
      ? layout.angularFractionCount
      : double.maxFinite;

  for (var index = 0; index < layout.slots.length; index += 1) {
    final placement = layout.slots[index];
    final area = placement.area;
    final rowStart = area.row
        .toDouble()
        .clamp(0, layout.layers.length)
        .toDouble();
    final rowEnd = (area.row + area.rowSpan)
        .toDouble()
        .clamp(rowStart, layout.layers.length)
        .toDouble();
    final firstRow = rowStart.floor();
    final lastRow = (placement.reserveSpannedRows ? rowEnd : rowStart + 1)
        .ceil()
        .clamp(0, layout.layers.length);
    var autoColumn = 0.0;
    for (var row = firstRow; row < lastRow; row += 1) {
      autoColumn = math.max(autoColumn, rowCursors[row]);
    }
    final columnStart =
        (area.hasExplicitColumn ? area.column.toDouble() : autoColumn)
            .clamp(0, configuredLimit)
            .toDouble();
    final columnEnd = _resolvedColumnEnd(
      layout,
      index,
      columnStart,
      rowStart,
      rowEnd,
      configuredLimit,
    );
    resolved.add((
      placement: placement,
      columnStart: columnStart,
      columnEnd: columnEnd,
      rowStart: rowStart,
      rowEnd: rowEnd,
    ));
    for (var row = firstRow; row < lastRow; row += 1) {
      rowCursors[row] = math.max(rowCursors[row], columnEnd);
    }
  }
  return resolved;
}

void _drawSlots(
  Canvas canvas,
  Offset center,
  double innerRadius,
  double outerRadius,
  double startAngle,
  double sweepAngle,
  TimeCompassLayout layout,
  List<_ResolvedTimeCompassSlot> resolvedSlots,
  double angularFractionCount,
) {
  for (final resolved in resolvedSlots) {
    final placement = resolved.placement;
    final columnStart = resolved.columnStart;
    final columnEnd = resolved.columnEnd;
    final rowStart = resolved.rowStart;
    final rowEnd = resolved.rowEnd;
    if (columnEnd <= columnStart || rowEnd <= rowStart) continue;

    final slotInnerRadius = _rowRadius(
      innerRadius,
      outerRadius,
      layout.layers,
      rowStart,
    );
    final slotOuterRadius = _rowRadius(
      innerRadius,
      outerRadius,
      layout.layers,
      rowEnd,
    );
    final slotStartAngle =
        startAngle + sweepAngle * columnStart / angularFractionCount;
    final slotSweep =
        sweepAngle * (columnEnd - columnStart) / angularFractionCount;

    _drawRadialBoundary(
      canvas,
      center,
      slotInnerRadius,
      slotOuterRadius,
      slotStartAngle,
      layout.guideGrid(GuideGridGeometry.radial)!.style,
    );
    _drawRadialBoundary(
      canvas,
      center,
      slotInnerRadius,
      slotOuterRadius,
      slotStartAngle + slotSweep,
      layout.guideGrid(GuideGridGeometry.radial)!.style,
    );

    final lineView = placement.lineView;
    if (lineView != null) {
      _drawLineView(
        canvas,
        center,
        slotInnerRadius,
        slotOuterRadius,
        slotStartAngle,
        slotSweep,
        lineView,
        layout,
      );
      continue;
    }

    final labelInnerRadius =
        placement.labelRadialAlignment ==
            TimeCompassSlotLabelRadialAlignment.outermostRow
        ? _rowRadius(
            innerRadius,
            outerRadius,
            layout.layers,
            math.max(rowStart, rowEnd - 1),
          )
        : slotInnerRadius;
    final labelRadius = (labelInnerRadius + slotOuterRadius) / 2;
    final labelAngle = slotStartAngle + slotSweep / 2;
    final labelCenter =
        center +
        Offset(math.cos(labelAngle), math.sin(labelAngle)) * labelRadius;
    final maxWidth = 2 * labelRadius * math.sin(slotSweep.abs() / 2) * 0.85;
    _paintSlotLabel(
      canvas,
      placement.slot.label,
      labelCenter,
      maxWidth,
      layout.slotStyle,
    );
  }
}

void _drawLineView(
  Canvas canvas,
  Offset center,
  double innerRadius,
  double outerRadius,
  double startAngle,
  double sweepAngle,
  LineView lineView,
  TimeCompassLayout layout,
) {
  final totalWeight = _totalWeight(lineView.segments);
  if (totalWeight <= 0) return;

  var consumedWeight = 0.0;
  for (var index = 0; index < lineView.segments.length; index += 1) {
    final segment = lineView.segments[index];
    final segmentStart = startAngle + sweepAngle * consumedWeight / totalWeight;
    if (index > 0) {
      _drawRadialBoundary(
        canvas,
        center,
        innerRadius,
        outerRadius,
        segmentStart,
        layout.guideGrid(GuideGridGeometry.radial)!.style,
      );
    }

    final segmentWeight = _weight(segment);
    final segmentSweep = sweepAngle * segmentWeight / totalWeight;
    final labelRadius = (innerRadius + outerRadius) / 2;
    final labelAngle = segmentStart + segmentSweep / 2;
    final labelCenter =
        center +
        Offset(math.cos(labelAngle), math.sin(labelAngle)) * labelRadius;
    final maxWidth = 2 * labelRadius * math.sin(segmentSweep.abs() / 2) * 0.85;
    _paintSlotLabel(
      canvas,
      segment.label,
      labelCenter,
      maxWidth,
      layout.slotStyle,
    );
    consumedWeight += segmentWeight;
  }
}

double _resolvedColumnEnd(
  TimeCompassLayout layout,
  int placementIndex,
  double columnStart,
  double rowStart,
  double rowEnd,
  double configuredLimit,
) {
  final placement = layout.slots[placementIndex];
  final area = placement.area;
  if (area.columnSpan != LayoutFraction.fullSpan) {
    return (columnStart + area.columnSpan)
        .toDouble()
        .clamp(columnStart, configuredLimit)
        .toDouble();
  }

  var columnEnd = configuredLimit;
  for (
    var candidateIndex = placementIndex + 1;
    candidateIndex < layout.slots.length;
    candidateIndex += 1
  ) {
    final candidate = layout.slots[candidateIndex];
    final candidateArea = candidate.area;
    if (!candidateArea.hasExplicitColumn) continue;
    final candidateRowStart = candidateArea.row.toDouble();
    final candidateRowEnd = (candidateArea.row + candidateArea.rowSpan)
        .toDouble();
    final rowsOverlap =
        candidateRowStart < rowEnd && candidateRowEnd > rowStart;
    final candidateColumn = candidateArea.column.toDouble();
    if (rowsOverlap &&
        candidateColumn > columnStart &&
        candidateColumn < columnEnd) {
      columnEnd = candidateColumn;
    }
  }
  return columnEnd == double.maxFinite ? columnStart + 1 : columnEnd;
}

void _drawVirtualColumns(
  Canvas canvas,
  Offset center,
  double innerRadius,
  double outerRadius,
  double startAngle,
  double sweepAngle,
  TimeCompassLayout layout,
  double angularFractionCount,
) {
  final grid = layout.guideGrid(GuideGridGeometry.radialVirtual);
  if (grid == null || !grid.visible || outerRadius <= innerRadius) return;

  for (final fraction in layout.virtualColumnFractions) {
    final normalizedFraction = fraction.clamp(0, angularFractionCount);
    final angle =
        startAngle + sweepAngle * normalizedFraction / angularFractionCount;
    _drawRadialBoundary(
      canvas,
      center,
      innerRadius,
      outerRadius,
      angle,
      grid.style,
    );
  }
}

void _drawLayerBoundaries(
  Canvas canvas,
  Offset center,
  double innerRadius,
  double outerRadius,
  double startAngle,
  double sweepAngle,
  TimeCompassLayout layout,
  List<_ResolvedTimeCompassSlot> resolvedSlots,
  double angularFractionCount,
  GuideStyle style,
) {
  final totalWeight = _totalWeight(layout.layers);
  if (totalWeight <= 0) return;

  _drawLayerBoundaryArc(
    canvas,
    center,
    innerRadius,
    startAngle,
    sweepAngle,
    layout,
    resolvedSlots,
    angularFractionCount,
    0,
    style,
  );
  var consumedWeight = 0.0;
  for (var index = 0; index < layout.layers.length; index += 1) {
    final layer = layout.layers[index];
    consumedWeight += _weight(layer);
    final radius =
        innerRadius +
        (outerRadius - innerRadius) * consumedWeight / totalWeight;
    _drawLayerBoundaryArc(
      canvas,
      center,
      radius,
      startAngle,
      sweepAngle,
      layout,
      resolvedSlots,
      angularFractionCount,
      index + 1,
      style,
    );
  }
}

void _drawLayerBoundaryArc(
  Canvas canvas,
  Offset center,
  double radius,
  double startAngle,
  double sweepAngle,
  TimeCompassLayout layout,
  List<_ResolvedTimeCompassSlot> resolvedSlots,
  double angularFractionCount,
  int rowBoundary,
  GuideStyle style,
) {
  final blockedRanges = <({double start, double end})>[];
  if (rowBoundary > 0 && rowBoundary < layout.layers.length) {
    for (final resolved in resolvedSlots) {
      final rowStart = resolved.rowStart;
      final rowEnd = resolved.rowEnd;
      if (rowStart >= rowBoundary || rowEnd <= rowBoundary) continue;

      final columnStart = resolved.columnStart;
      final columnEnd = resolved.columnEnd;
      if (columnEnd > columnStart) {
        blockedRanges.add((start: columnStart, end: columnEnd));
      }
    }
  }
  blockedRanges.sort((left, right) => left.start.compareTo(right.start));

  var cursor = 0.0;
  for (final blocked in blockedRanges) {
    if (blocked.start > cursor) {
      _drawArc(
        canvas,
        center,
        radius,
        startAngle + sweepAngle * cursor / angularFractionCount,
        sweepAngle * (blocked.start - cursor) / angularFractionCount,
        style,
      );
    }
    if (blocked.end > cursor) cursor = blocked.end;
  }
  if (cursor < angularFractionCount) {
    _drawArc(
      canvas,
      center,
      radius,
      startAngle + sweepAngle * cursor / angularFractionCount,
      sweepAngle * (angularFractionCount - cursor) / angularFractionCount,
      style,
    );
  }
}

double _rowRadius(
  double innerRadius,
  double outerRadius,
  List<LayoutSlot> layers,
  double row,
) {
  final totalWeight = _totalWeight(layers);
  if (totalWeight <= 0) return innerRadius;

  final clampedRow = row.clamp(0, layers.length);
  final wholeRows = clampedRow.floor();
  final partialRow = clampedRow - wholeRows;
  var consumedWeight = 0.0;
  for (var index = 0; index < wholeRows; index += 1) {
    consumedWeight += _weight(layers[index]);
  }
  if (wholeRows < layers.length && partialRow > 0) {
    consumedWeight += _weight(layers[wholeRows]) * partialRow;
  }
  return innerRadius +
      (outerRadius - innerRadius) * consumedWeight / totalWeight;
}

void _drawRadialBoundary(
  Canvas canvas,
  Offset center,
  double innerRadius,
  double outerRadius,
  double angle,
  GuideStyle style,
) {
  final direction = Offset(math.cos(angle), math.sin(angle));
  final start = center + direction * innerRadius;
  final end = center + direction * outerRadius;
  drawGuideLine(canvas, start, end, style);
}

void _drawArc(
  Canvas canvas,
  Offset center,
  double radius,
  double startAngle,
  double sweepAngle,
  GuideStyle style,
) {
  final bounds = Rect.fromCircle(center: center, radius: radius);
  final paint = _paint(style);
  if (style.pattern == GuideLinePattern.solid) {
    canvas.drawArc(bounds, startAngle, sweepAngle, false, paint);
    return;
  }

  final path = Path()..addArc(bounds, startAngle, sweepAngle);
  for (final metric in path.computeMetrics()) {
    if (style.pattern == GuideLinePattern.dotted) {
      final interval = style.dashInterval <= 0
          ? style.strokeWidth * 2
          : style.dashInterval;
      for (
        var distance = 0.0;
        distance <= metric.length;
        distance += interval
      ) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            style.strokeWidth / 2,
            Paint()
              ..color = style.color
              ..style = PaintingStyle.fill,
          );
        }
      }
      continue;
    }
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + style.dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance = end + style.dashInterval;
    }
  }
}

Paint _paint(GuideStyle style) {
  return Paint()
    ..color = style.color
    ..strokeWidth = style.strokeWidth
    ..strokeCap = style.strokeCap
    ..style = PaintingStyle.stroke;
}

void _paintSlotLabel(
  Canvas canvas,
  String label,
  Offset center,
  double maxWidth,
  TimeCompassSlotStyle style,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: style.color,
        fontSize: style.fontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

double _totalWeight(List<LayoutSlot> slots) {
  return slots.fold<double>(0, (sum, slot) => sum + _weight(slot));
}

double _weight(LayoutSlot slot) {
  return (slot.fraction ?? 1).clamp(0, double.infinity).toDouble();
}
