import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../constants/typography.dart';
import '../models/layout.dart';

/// Flame renderer for Neo4j classification labels in table value cells.
///
/// Labels are Node classification metadata, not Nodes. This component only
/// owns their shopping-tag presentation; colors remain layout configuration.
class ClassificationLabelComponent extends PositionComponent {
  ClassificationLabelComponent();

  Path? _hoverPath;
  GuideStyle? _hoverStyle;

  void updateHoverTarget(Path? path, GuideStyle? style) {
    _hoverPath = path;
    _hoverStyle = style;
  }

  List<ClassificationLabelFrame> renderLabels(
    Canvas canvas, {
    required Iterable<String> labels,
    required Rect bounds,
    required double fontSize,
    LayoutDefaults? layoutDefaults,
  }) {
    final values = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty || bounds.width <= 8 || bounds.height <= 8) {
      return const [];
    }

    final defaults = layoutDefaults ?? const LayoutDefaults();
    final tagHeight = math
        .min(math.max(fontSize * 1.8, 16), bounds.height - 4)
        .toDouble();
    if (tagHeight < 8) return const [];
    final pointWidth = tagHeight * 0.42;
    final horizontalPadding = math.max(fontSize * 0.55, 4);
    const gap = 5.0;
    var x = bounds.left + 6;
    var y = bounds.top + 4;
    final maxRight = bounds.right - 6;
    final maxBottom = bounds.bottom - 4;
    final frames = <ClassificationLabelFrame>[];

    for (final label in values) {
      final availableTextWidth = math
          .max(bounds.width - 12 - pointWidth - horizontalPadding * 2, fontSize)
          .toDouble();
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: SevilleTypography.fontFamily,
            color: defaults.classificationLabelTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: availableTextWidth);
      final tagWidth = math.min(
        pointWidth + horizontalPadding * 2 + textPainter.width,
        bounds.width - 12,
      );
      if (x + tagWidth > maxRight && x > bounds.left + 6) {
        x = bounds.left + 6;
        y += tagHeight + gap;
      }
      if (y + tagHeight > maxBottom) return frames;

      final tagBounds = Rect.fromLTWH(x, y, tagWidth, tagHeight);
      frames.add(
        ClassificationLabelFrame(
          label: label,
          path: _paintTag(
            canvas,
            label,
            tagBounds,
            pointWidth,
            textPainter,
            defaults,
          ),
        ),
      );
      x += tagWidth + gap;
    }
    return frames;
  }

  Path _paintTag(
    Canvas canvas,
    String label,
    Rect bounds,
    double pointWidth,
    TextPainter textPainter,
    LayoutDefaults defaults,
  ) {
    final path = Path()
      ..moveTo(bounds.left, bounds.center.dy)
      ..lineTo(bounds.left + pointWidth, bounds.top)
      ..lineTo(bounds.right, bounds.top)
      ..lineTo(bounds.right, bounds.bottom)
      ..lineTo(bounds.left + pointWidth, bounds.bottom)
      ..close();
    final palette = defaults.classificationLabelColors.isEmpty
        ? const [Color(0xFF4E79A7)]
        : defaults.classificationLabelColors;
    final color = palette[_stableColorIndex(label, palette.length)];
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (defaults.classificationLabelBorderWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = defaults.classificationLabelBorderColor
          ..strokeWidth = defaults.classificationLabelBorderWidth
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(
      Offset(bounds.left + pointWidth * 0.58, bounds.center.dy),
      math.max(bounds.height * 0.075, 1.2),
      Paint()
        ..color = defaults.classificationLabelHoleColor
        ..style = PaintingStyle.fill,
    );
    final textCenter = Offset(
      bounds.left + pointWidth + (bounds.width - pointWidth) / 2,
      bounds.center.dy,
    );
    textPainter.paint(
      canvas,
      textCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );
    return path;
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
    canvas.drawPath(
      path,
      Paint()
        ..color = style.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..strokeCap = style.strokeCap,
    );
  }
}

class ClassificationLabelFrame {
  const ClassificationLabelFrame({required this.label, required this.path});

  final String label;
  final Path path;
}

int _stableColorIndex(String value, int colorCount) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
  }
  return hash % colorCount;
}
