part of 'layout.dart';

/// Canonical fallback values for classification-label presentation.
abstract final class LabelDefaults {
  static const config = LabelConfig(
    state: {
      LayoutCondition.always(): LabelConfig(
        style: LabelStyle(
          color: Color(0xFFF5EDD6),
          borderStyle: GuideStyle(color: Color(0xFFE8D59F), strokeWidth: 1),
          holeColor: Color(0xFF27251F),
        ),
      ),
      LayoutCondition.labelHighlighted(): LabelConfig(
        style: LabelStyle(
          borderStyle: GuideStyle(color: Color(0xFFFFD54F), strokeWidth: 4),
        ),
      ),
    },
  );
}

/// Extensible label configuration selected by Layout state.
class LabelConfig {
  const LabelConfig({this.style = const LabelStyle(), this.state = const {}});

  final LabelStyle style;
  final Map<LayoutCondition, LabelConfig> state;

  LabelConfig resolve(LayoutContext context) {
    var resolved = LabelConfig(style: style);
    for (final entry in state.entries) {
      if (entry.key.isActive(context)) {
        resolved = resolved.merge(entry.value.resolve(context));
      }
    }
    return resolved;
  }

  LabelConfig resolveWithDefaults(LayoutContext context) =>
      LabelDefaults.config.resolve(context).merge(resolve(context));

  LabelConfig merge(LabelConfig overlay) =>
      LabelConfig(style: style.merge(overlay.style));
}

/// Renderer-independent visual values owned by [LabelConfig].
class LabelStyle {
  const LabelStyle({this.color, this.borderStyle, this.holeColor});

  final Color? color;
  final GuideStyle? borderStyle;
  final Color? holeColor;

  LabelStyle merge(LabelStyle overlay) => LabelStyle(
    color: overlay.color ?? color,
    borderStyle: overlay.borderStyle ?? borderStyle,
    holeColor: overlay.holeColor ?? holeColor,
  );
}
