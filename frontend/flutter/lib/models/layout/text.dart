part of 'layout.dart';

abstract final class LayoutTextDefaults {
  static const config = LayoutTextConfig(
    color: Color(0xFFFFF8E7),
    darkColor: Color(0xFF27251F),
    lightColor: Color(0xFFFFF8E7),
  );
}

/// Renderer-independent typography and contrast policy for a [Layout].
class LayoutTextConfig {
  const LayoutTextConfig({
    this.color,
    this.darkColor,
    this.lightColor,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.effects,
    this.fontFeatures,
  });

  final Color? color;
  final Color? darkColor;
  final Color? lightColor;
  final String? fontFamily;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final List<Shadow>? effects;
  final List<FontFeature>? fontFeatures;

  Color resolveColor(Color backgroundColor) {
    final dark = darkColor;
    final light = lightColor;
    if (dark != null && light != null) {
      return backgroundColor.computeLuminance() > 0.5 ? dark : light;
    }
    return color ?? dark ?? light ?? LayoutTextDefaults.config.color!;
  }

  LayoutTextConfig merge(LayoutTextConfig overlay) => LayoutTextConfig(
    color: overlay.color ?? color,
    darkColor: overlay.darkColor ?? darkColor,
    lightColor: overlay.lightColor ?? lightColor,
    fontFamily: overlay.fontFamily ?? fontFamily,
    fontSize: overlay.fontSize ?? fontSize,
    fontWeight: overlay.fontWeight ?? fontWeight,
    fontStyle: overlay.fontStyle ?? fontStyle,
    letterSpacing: overlay.letterSpacing ?? letterSpacing,
    wordSpacing: overlay.wordSpacing ?? wordSpacing,
    height: overlay.height ?? height,
    effects: overlay.effects ?? effects,
    fontFeatures: overlay.fontFeatures ?? fontFeatures,
  );
}
