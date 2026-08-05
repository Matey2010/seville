import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:seville_proto/seville_proto.dart';

import '../constants/typography.dart';
import '../domain/node.dart';
import '../models/layout/layout.dart';

/// Shared Flame renderer for Node paint state and hover decoration.
class NodeComponent extends PositionComponent {
  static final math.Random _backgroundRandom = math.Random();
  static final Expando<Map<String, LayoutBackground>>
  _randomBackgroundSelections = Expando();

  Path? _hoverPath;
  GuideStyle? _hoverStyle;

  void updateHoverTarget(Path? path, GuideStyle? style) {
    _hoverPath = path;
    _hoverStyle = style;
  }

  static Color? parseColor(String? rawColor) {
    if (rawColor == null || rawColor.trim().isEmpty) return null;
    final normalized = rawColor
        .trim()
        .replaceFirst('#', '')
        .replaceFirst(RegExp('^0x', caseSensitive: false), '');
    final hex = switch (normalized.length) {
      6 => 'FF$normalized',
      8 => normalized,
      _ => null,
    };
    if (hex == null) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  static LayoutColor colorFor(Node node) {
    for (final key in const ['color', 'hex', 'background']) {
      final rawColor = node.frontmatter[key];
      if (parseColor(rawColor) != null) {
        return LayoutColor.fromHex(rawColor!);
      }
    }

    final normalizedSlug = node.slug.trim();
    final identity = normalizedSlug.isNotEmpty ? normalizedSlug : node.path;
    var seed = 0;
    for (final codeUnit in identity.codeUnits) {
      seed = (seed * 31 + codeUnit) & 0x7FFFFFFF;
    }
    final random = math.Random(seed);
    final red = 96 + random.nextInt(128);
    final green = 96 + random.nextInt(128);
    final blue = 96 + random.nextInt(128);
    final hex = [
      red,
      green,
      blue,
    ].map((channel) => channel.toRadixString(16).padLeft(2, '0')).join();
    return LayoutColor.fromHex(hex, opacity: 0.88);
  }

  static Color backgroundColor(
    Color color,
    String nodeSlug,
    LayoutContext layoutContext,
    Layout layout, {
    bool isVirtual = false,
    NodeConfig? config,
  }) {
    final normalizedNodeSlug = nodeSlug.trim();
    final active =
        normalizedNodeSlug.isNotEmpty &&
        layoutContext.activeNodeSlugs.contains(normalizedNodeSlug);
    final opacity =
        config?.backgroundOpacity ??
        (isVirtual
            ? layout.virtualNodeBackgroundOpacity
            : active
            ? layout.activeNodeBackgroundOpacity
            : layout.inactiveNodeBackgroundOpacity);
    return (config?.backgroundColor ?? color).withValues(alpha: opacity);
  }

  /// Paints Node-owned backgrounds after the Layout surface and Node fill.
  static void paintBackgrounds(
    Canvas canvas,
    Path path,
    Rect bounds,
    List<LayoutBackground>? configuredBackground,
    LayoutContext context, {
    required String nodeKey,
    required ui.Image? Function(String assetPath) imageFor,
  }) {
    if (configuredBackground == null || configuredBackground.isEmpty) return;
    final ordered = [
      ...configuredBackground,
    ]..sort((left, right) => left.orderPosition.compareTo(right.orderPosition));
    for (final background in ordered) {
      _paintBackground(
        canvas,
        path,
        bounds,
        background,
        context,
        nodeKey,
        imageFor,
      );
    }
  }

  static void _paintBackground(
    Canvas canvas,
    Path path,
    Rect bounds,
    LayoutBackground background,
    LayoutContext context,
    String nodeKey,
    ui.Image? Function(String assetPath) imageFor, {
    double inheritedOpacity = 1,
  }) {
    final opacity = (inheritedOpacity * background.opacity)
        .clamp(0, 1)
        .toDouble();
    if (opacity == 0) return;
    if (background is RandomLayoutBackground) {
      final selections = _randomBackgroundSelections[background] ??= {};
      final selected = selections.putIfAbsent(
        nodeKey,
        () =>
            background.backgrounds[_backgroundRandom.nextInt(
              background.backgrounds.length,
            )],
      );
      _paintBackground(
        canvas,
        path,
        bounds,
        selected,
        context,
        nodeKey,
        imageFor,
        inheritedOpacity: opacity,
      );
      return;
    }
    if (background is ConditionalLayoutBackground) {
      if (!background.activeCondition.isActive(context)) return;
      _paintBackground(
        canvas,
        path,
        bounds,
        background.background,
        context,
        nodeKey,
        imageFor,
        inheritedOpacity: opacity,
      );
      return;
    }
    if (background is LayoutBackgroundColor) {
      canvas.drawPath(
        path,
        Paint()
          ..color = background.color.withValues(
            alpha: background.color.a * opacity,
          )
          ..style = PaintingStyle.fill,
      );
      return;
    }
    if (background is LayoutImageBackground) {
      final image = imageFor(background.assetPath);
      if (image == null || bounds.isEmpty) return;
      canvas.save();
      canvas.clipPath(path);
      final tileWidth = bounds.width / background.repeat;
      for (var index = 0; index < background.repeat; index += 1) {
        final tile = Rect.fromLTWH(
          bounds.left + tileWidth * index,
          bounds.top,
          tileWidth,
          bounds.height,
        );
        canvas.save();
        final radians = background.rotationDegrees * math.pi / 180;
        if (radians != 0 || background.scale != 1) {
          canvas
            ..translate(tile.center.dx, tile.center.dy)
            ..rotate(radians)
            ..scale(background.scale)
            ..translate(-tile.center.dx, -tile.center.dy);
        }
        paintImage(
          canvas: canvas,
          rect: tile,
          image: image,
          fit: switch (background.fit) {
            LayoutBackgroundFit.cover => BoxFit.cover,
            LayoutBackgroundFit.contain => BoxFit.contain,
            LayoutBackgroundFit.fill => BoxFit.fill,
          },
          alignment: Alignment(
            background.position.dx * 2 - 1,
            background.position.dy * 2 - 1,
          ),
          opacity: opacity,
        );
        canvas.restore();
      }
      canvas.restore();
      return;
    }
    if (background is LayoutGuidingBackground) {
      canvas.save();
      canvas.clipPath(path);
      for (final guide in background.guides) {
        final guidePath = Path()
          ..moveTo(
            bounds.left + bounds.width * guide.start.dx,
            bounds.top + bounds.height * guide.start.dy,
          )
          ..lineTo(
            bounds.left + bounds.width * guide.end.dx,
            bounds.top + bounds.height * guide.end.dy,
          );
        renderGuide(canvas, guidePath, guide.style, opacity: opacity);
      }
      canvas.restore();
      return;
    }
    if (background is LayoutBorderBackground) {
      renderGuide(canvas, path, background.style, opacity: opacity);
    }
  }

  static void renderBorder(
    Canvas canvas,
    Path path,
    GuideStyle style,
    double strokeWidth, {
    required bool isVirtual,
  }) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = strokeWidth
      ..strokeCap = style.strokeCap
      ..style = PaintingStyle.stroke;
    if (!isVirtual) {
      canvas.drawPath(path, paint);
      return;
    }

    final dashLength = style.dashLength <= 0 ? 7.0 : style.dashLength;
    final dashInterval = style.dashInterval <= 0 ? 5.0 : style.dashInterval;
    for (final metric in path.computeMetrics()) {
      var offset = 0.0;
      while (offset < metric.length) {
        final end = math.min(offset + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(offset, end), paint);
        offset = end + dashInterval;
      }
    }
  }

  static void renderGuide(
    Canvas canvas,
    Path path,
    GuideStyle style, {
    double opacity = 1,
  }) {
    final paint = Paint()
      ..color = style.color.withValues(alpha: style.color.a * opacity)
      ..strokeWidth = style.strokeWidth
      ..strokeCap = style.strokeCap
      ..style = PaintingStyle.stroke;
    if (style.pattern == GuideLinePattern.solid) {
      canvas.drawPath(path, paint);
      return;
    }
    final dashLength = style.pattern == GuideLinePattern.dotted
        ? math.max(style.strokeWidth, 1)
        : style.dashLength;
    for (final metric in path.computeMetrics()) {
      var offset = 0.0;
      while (offset < metric.length) {
        final end = math.min(offset + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(offset, end), paint);
        offset = end + style.dashInterval;
      }
    }
  }

  static String presentationLabel(Node node, NodeConfig config) {
    final content = config.content;
    if (content != null) return content.resolve(node, config);
    final slug = node.slug.trim();
    return slug.isNotEmpty ? config.formatSlug(slug) : node.displayLabel;
  }

  static void paintLabels(
    Canvas canvas,
    Node node,
    Rect bounds, {
    required NodeConfig config,
    required LayoutTextConfig text,
    required double emojiFontSizeFactor,
    required double emojiSlugGapFactor,
  }) {
    final labelSize = text.fontSize ?? LayoutTextDefaults.rootFontSize;
    final maxWidth = bounds.width * 0.8;
    final content = config.content;
    if (content != null) {
      final value = content.resolve(node, config);
      if (value.isEmpty) return;
      final requestedFontSize = content.isEmoji
          ? labelSize * emojiFontSizeFactor
          : labelSize;
      final availableFontSize = math.min(maxWidth, bounds.height * 0.8);
      if (availableFontSize <= 0) return;
      final painter = _nodeTextPainter(
        value,
        isSlug: content.isSlug,
        maxWidth: maxWidth,
        color: content.isSlug
            ? config.slugColor ?? NodeDefaults.slugColor
            : config.labelColor ?? NodeDefaults.labelColor,
        fontSize: math.min(requestedFontSize, availableFontSize),
        textConfig: text,
        fontFeatures: content.isSlug
            ? (config.slugTransform ?? NodeDefaults.slugTransform).fontFeatures
            : null,
      );
      painter.paint(
        canvas,
        bounds.center - Offset(painter.width / 2, painter.height / 2),
      );
      return;
    }
    if (maxWidth < labelSize * 2) return;
    final slugPainter = _nodeTextPainter(
      presentationLabel(node, config),
      isSlug: true,
      maxWidth: maxWidth,
      color: config.slugColor ?? NodeDefaults.slugColor,
      fontSize: labelSize,
      textConfig: text,
      fontFeatures:
          (config.slugTransform ?? NodeDefaults.slugTransform).fontFeatures,
    );
    final emoji = node.primaryEmojiCharacter;
    if (emoji == null) {
      slugPainter.paint(
        canvas,
        bounds.center - Offset(slugPainter.width / 2, slugPainter.height / 2),
      );
      return;
    }
    final emojiPainter = _nodeTextPainter(
      emoji,
      isSlug: false,
      maxWidth: maxWidth,
      color: config.labelColor ?? NodeDefaults.labelColor,
      fontSize: labelSize * emojiFontSizeFactor,
      textConfig: text,
    );
    final gap = labelSize * emojiSlugGapFactor;
    final contentHeight = emojiPainter.height + gap + slugPainter.height;
    final top = bounds.center.dy - contentHeight / 2;
    emojiPainter.paint(
      canvas,
      Offset(bounds.center.dx - emojiPainter.width / 2, top),
    );
    slugPainter.paint(
      canvas,
      Offset(
        bounds.center.dx - slugPainter.width / 2,
        top + emojiPainter.height + gap,
      ),
    );
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
    renderBorder(canvas, path, style, style.strokeWidth, isVirtual: false);
  }
}

TextPainter _nodeTextPainter(
  String text, {
  required bool isSlug,
  required double maxWidth,
  required Color color,
  required double fontSize,
  required LayoutTextConfig textConfig,
  List<FontFeature>? fontFeatures,
}) => TextPainter(
  text: TextSpan(
    text: LayoutText.defaultRepresentation(text),
    style: TextStyle(
      fontFamily: isSlug
          ? null
          : textConfig.fontFamily ?? SevilleTypography.fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: isSlug
          ? FontWeight.w700
          : textConfig.fontWeight ?? FontWeight.w600,
      fontStyle: textConfig.fontStyle,
      letterSpacing: textConfig.letterSpacing,
      wordSpacing: textConfig.wordSpacing,
      height: textConfig.height,
      shadows: textConfig.effects,
      fontFeatures: fontFeatures,
    ),
  ),
  maxLines: 1,
  ellipsis: '…',
  textDirection: TextDirection.ltr,
  textAlign: TextAlign.center,
)..layout(maxWidth: maxWidth);
