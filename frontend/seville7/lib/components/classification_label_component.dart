import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../constants/typography.dart';
import '../models/layout/layout.dart';

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
    required LabelConfig config,
    required LayoutTextConfig textConfig,
    required LayoutContext context,
  }) {
    final values = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty || bounds.width <= 8 || bounds.height <= 8) {
      return const [];
    }

    final resolvedFontSize = textConfig.fontSize ?? fontSize;
    final tagHeight = math
        .min(math.max(resolvedFontSize * 1.8, 16), bounds.height - 4)
        .toDouble();
    if (tagHeight < 8) return const [];
    final pointWidth = tagHeight * 0.42;
    final horizontalPadding = math.max(resolvedFontSize * 0.55, 4);
    const gap = 5.0;
    var x = bounds.left + 6;
    var y = bounds.top + 4;
    final maxRight = bounds.right - 6;
    final maxBottom = bounds.bottom - 4;
    final frames = <ClassificationLabelFrame>[];

    for (final label in values) {
      final labelContext = context.withCurrentLabel(label);
      final style = config.resolve(labelContext).style;
      final availableTextWidth = math
          .max(
            bounds.width - 12 - pointWidth - horizontalPadding * 2,
            resolvedFontSize,
          )
          .toDouble();
      final textPainter = TextPainter(
        text: TextSpan(
          text: LayoutText.defaultRepresentation(label),
          style: TextStyle(
            fontFamily: textConfig.fontFamily ?? SevilleTypography.fontFamily,
            color: textConfig.resolveColor(style.color!),
            fontSize: resolvedFontSize,
            fontWeight: textConfig.fontWeight ?? FontWeight.w700,
            fontStyle: textConfig.fontStyle,
            letterSpacing: textConfig.letterSpacing,
            wordSpacing: textConfig.wordSpacing,
            height: textConfig.height,
            shadows: textConfig.effects,
            fontFeatures: textConfig.fontFeatures,
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
          hoverStyle: config
              .resolve(labelContext.withLabelHighlighted(true))
              .style
              .borderStyle,
          path: _paintTag(canvas, tagBounds, pointWidth, textPainter, style),
        ),
      );
      x += tagWidth + gap;
    }
    return frames;
  }

  Path _paintTag(
    Canvas canvas,
    Rect bounds,
    double pointWidth,
    TextPainter textPainter,
    LabelStyle style,
  ) {
    final path = Path()
      ..moveTo(bounds.left, bounds.center.dy)
      ..lineTo(bounds.left + pointWidth, bounds.top)
      ..lineTo(bounds.right, bounds.top)
      ..lineTo(bounds.right, bounds.bottom)
      ..lineTo(bounds.left + pointWidth, bounds.bottom)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = style.color!
        ..style = PaintingStyle.fill,
    );
    final borderStyle = style.borderStyle;
    if (borderStyle != null && borderStyle.strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderStyle.color
          ..strokeWidth = borderStyle.strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(
      Offset(bounds.left + pointWidth * 0.58, bounds.center.dy),
      math.max(bounds.height * 0.075, 1.2),
      Paint()
        ..color = style.holeColor!
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
  const ClassificationLabelFrame({
    required this.label,
    required this.path,
    this.hoverStyle,
  });

  final String label;
  final Path path;
  final GuideStyle? hoverStyle;
}
