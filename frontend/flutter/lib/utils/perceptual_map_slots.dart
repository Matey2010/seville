import 'package:flutter/material.dart';

import '../models/layout.dart';
import '../models/perceptual_map_layout.dart';
import 'canvas_guides.dart';

void drawPerceptualMapSlots(
  Canvas canvas,
  Size size,
  PerceptualMapLayout layout,
) {
  if (size.isEmpty) return;

  final bottomConfig = layout.slotConfigs[PerceptualMapSlot.bottom];
  if (bottomConfig != null) {
    _drawBottomStack(canvas, size, bottomConfig);
  }

  final bottomLeftConfig = layout.slotConfigs[PerceptualMapSlot.bottomLeft];
  if (bottomLeftConfig != null &&
      bottomLeftConfig.shape == PerceptualMapSlotShape.stack) {
    _drawBottomSideStack(
      canvas,
      size,
      bottomLeftConfig,
      side: _HorizontalSide.left,
    );
  }

  final bottomRightConfig = layout.slotConfigs[PerceptualMapSlot.bottomRight];
  if (bottomRightConfig != null &&
      bottomRightConfig.shape == PerceptualMapSlotShape.stack) {
    _drawBottomSideStack(
      canvas,
      size,
      bottomRightConfig,
      side: _HorizontalSide.right,
    );
  }

  final bottomCenterConfig = layout.slotConfigs[PerceptualMapSlot.bottomCenter];
  if (bottomCenterConfig != null &&
      bottomCenterConfig.shape == PerceptualMapSlotShape.triangle) {
    _drawBottomCenterTriangle(canvas, size, bottomCenterConfig);
  }
}

enum _HorizontalSide { left, right }

void _drawBottomSideStack(
  Canvas canvas,
  Size size,
  PerceptualMapSlotConfig config, {
  required _HorizontalSide side,
}) {
  if (config.slots.isEmpty ||
      config.extentFractions <= 0 ||
      config.widthFractions <= 0) {
    return;
  }

  final normalizedExtent = (config.extent / config.extentFractions).clamp(
    0.0,
    1.0,
  );
  final center = Offset(size.width / 2, size.height / 2);
  final direction = side == _HorizontalSide.right ? 1.0 : -1.0;
  final outerHorizontal = Offset(
    center.dx + direction * size.width / 2 * normalizedExtent,
    center.dy,
  );
  final outerDiagonal =
      center +
      (Offset(side == _HorizontalSide.right ? size.width : 0, size.height) -
              center) *
          normalizedExtent;
  final apexSlot = config.apexSlot;
  final apexWeight = apexSlot == null ? 0.0 : _slotWeight(apexSlot);
  final slotsWeight = config.slots.fold<double>(
    0,
    (sum, slot) => sum + _slotWeight(slot),
  );
  final totalWeight = apexWeight + slotsWeight;
  if (normalizedExtent <= 0 || totalWeight <= 0) return;

  _drawSeparator(canvas, center, outerHorizontal, config.style);
  _drawSeparator(canvas, center, outerDiagonal, config.style);

  var consumedWeight = 0.0;
  if (apexSlot != null && apexWeight > 0) {
    consumedWeight = apexWeight;
    final apexFraction = consumedWeight / totalWeight;
    final apexOuterHorizontal = Offset.lerp(
      center,
      outerHorizontal,
      apexFraction,
    )!;
    final apexOuterDiagonal = Offset.lerp(center, outerDiagonal, apexFraction)!;
    _drawSeparator(
      canvas,
      apexOuterHorizontal,
      apexOuterDiagonal,
      config.style,
    );
    _drawCenteredLabel(
      canvas,
      apexSlot.label,
      Offset(
        (center.dx + apexOuterHorizontal.dx + apexOuterDiagonal.dx) / 3,
        (center.dy + apexOuterHorizontal.dy + apexOuterDiagonal.dy) / 3,
      ),
      (apexOuterDiagonal - apexOuterHorizontal).distance,
      config.style,
    );
  }

  for (final slot in config.slots) {
    final innerFraction = consumedWeight / totalWeight;
    consumedWeight += _slotWeight(slot);
    final outerFraction = consumedWeight / totalWeight;
    final innerHorizontal = Offset.lerp(
      center,
      outerHorizontal,
      innerFraction,
    )!;
    final innerDiagonal = Offset.lerp(center, outerDiagonal, innerFraction)!;
    final slotOuterHorizontal = Offset.lerp(
      center,
      outerHorizontal,
      outerFraction,
    )!;
    final slotOuterDiagonal = Offset.lerp(
      center,
      outerDiagonal,
      outerFraction,
    )!;

    _drawSeparator(
      canvas,
      slotOuterHorizontal,
      slotOuterDiagonal,
      config.style,
    );
    if (slot.label.isNotEmpty) {
      final labelCenter = innerFraction == 0
          ? Offset(
              (center.dx + slotOuterHorizontal.dx + slotOuterDiagonal.dx) / 3,
              (center.dy + slotOuterHorizontal.dy + slotOuterDiagonal.dy) / 3,
            )
          : Offset(
              (innerHorizontal.dx +
                      innerDiagonal.dx +
                      slotOuterHorizontal.dx +
                      slotOuterDiagonal.dx) /
                  4,
              (innerHorizontal.dy +
                      innerDiagonal.dy +
                      slotOuterHorizontal.dy +
                      slotOuterDiagonal.dy) /
                  4,
            );
      _drawCenteredLabel(
        canvas,
        slot.label,
        labelCenter,
        (slotOuterDiagonal - slotOuterHorizontal).distance,
        config.style,
      );
    }
  }
}

void _drawBottomStack(
  Canvas canvas,
  Size size,
  PerceptualMapSlotConfig config,
) {
  if (config.slots.isEmpty ||
      config.extentFractions <= 0 ||
      config.widthFractions <= 0) {
    return;
  }

  final normalizedExtent = (config.extent / config.extentFractions).clamp(
    0.0,
    1.0,
  );
  final regionHeight = size.height / 2 * normalizedExtent;
  final regionTop = size.height - regionHeight;
  final totalWeight = config.slots.fold<double>(
    0,
    (sum, slot) => sum + _slotWeight(slot),
  );
  if (regionHeight <= 0 || totalWeight <= 0) return;

  var consumedWeight = 0.0;
  for (var index = 0; index < config.slots.length; index += 1) {
    final slot = config.slots[index];
    final top = regionTop + regionHeight * consumedWeight / totalWeight;
    consumedWeight += _slotWeight(slot);
    final bottom = regionTop + regionHeight * consumedWeight / totalWeight;
    final width = _slotWidth(size.width, slot, config.widthFractions);
    final left = (size.width - width) / 2;
    final right = left + width;
    _drawSeparator(canvas, Offset(left, top), Offset(right, top), config.style);
    _drawLabel(
      canvas,
      slot.label,
      Rect.fromLTRB(left, top, right, bottom),
      config.style,
    );
  }
}

void _drawBottomCenterTriangle(
  Canvas canvas,
  Size size,
  PerceptualMapSlotConfig config,
) {
  if (config.slots.isEmpty ||
      config.extentFractions <= 0 ||
      config.widthFractions <= 0) {
    return;
  }

  final normalizedExtent = (config.extent / config.extentFractions).clamp(
    0.0,
    1.0,
  );
  final triangleHeight = size.height / 2 * normalizedExtent;
  final apex = Offset(size.width / 2, size.height - triangleHeight);
  final bottomLeft = Offset(0, size.height);
  final bottomRight = Offset(size.width, size.height);
  final totalWeight = config.slots.fold<double>(
    0,
    (sum, slot) => sum + _slotWeight(slot),
  );
  if (triangleHeight <= 0 || totalWeight <= 0) return;

  _drawSeparator(canvas, apex, bottomLeft, config.style);
  _drawSeparator(canvas, apex, bottomRight, config.style);

  var consumedWeight = 0.0;
  for (final slot in config.slots) {
    final topFraction = consumedWeight / totalWeight;
    consumedWeight += _slotWeight(slot);
    final bottomFraction = consumedWeight / totalWeight;
    final widthScale =
        _slotWidth(size.width, slot, config.widthFractions) / size.width;
    final topHalfWidth = size.width / 2 * topFraction * widthScale;
    final bottomHalfWidth = size.width / 2 * bottomFraction * widthScale;
    final top = apex.dy + triangleHeight * topFraction;
    final bottom = apex.dy + triangleHeight * bottomFraction;
    final bottomStart = Offset(size.width / 2 - bottomHalfWidth, bottom);
    final bottomEnd = Offset(size.width / 2 + bottomHalfWidth, bottom);
    _drawSeparator(canvas, bottomStart, bottomEnd, config.style);
    _drawLabel(
      canvas,
      slot.label,
      Rect.fromLTRB(
        size.width / 2 - (topHalfWidth + bottomHalfWidth) / 2,
        top,
        size.width / 2 + (topHalfWidth + bottomHalfWidth) / 2,
        bottom,
      ),
      config.style,
    );
  }
}

double _slotWeight(LayoutSlot slot) {
  return (slot.fraction ?? 1).clamp(0, double.infinity).toDouble();
}

double _slotWidth(
  double availableWidth,
  LayoutSlot slot,
  double widthFractions,
) {
  final minimum = (slot.minWidth ?? 0).clamp(0, widthFractions).toDouble();
  final maximum = (slot.maxWidth ?? widthFractions)
      .clamp(minimum, widthFractions)
      .toDouble();
  final preferred = (slot.span ?? widthFractions)
      .clamp(minimum, maximum)
      .toDouble();
  return availableWidth * preferred / widthFractions;
}

void _drawSeparator(
  Canvas canvas,
  Offset start,
  Offset end,
  PerceptualMapSlotStyle style,
) {
  drawDashedLine(
    canvas,
    start,
    end,
    Paint()
      ..color = style.color
      ..strokeWidth = style.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
    dashLength: style.dashLength,
    gapLength: style.gapLength,
  );
}

void _drawLabel(
  Canvas canvas,
  String label,
  Rect bounds,
  PerceptualMapSlotStyle style,
) {
  _drawCenteredLabel(canvas, label, bounds.center, bounds.width, style);
}

void _drawCenteredLabel(
  Canvas canvas,
  String label,
  Offset center,
  double maxWidth,
  PerceptualMapSlotStyle style,
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
