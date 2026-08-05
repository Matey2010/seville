part of 'layout.dart';

/// Canonical fallback values for classification-label presentation.
abstract final class LabelDefaults {
  static const config = LabelConfig(
    state: LayoutState({
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
    }),
  );
}

/// Extensible label configuration selected by Layout state.
class LabelConfig {
  const LabelConfig({
    this.style = const LabelStyle(),
    this.state = const LayoutState(),
  });

  final LabelStyle style;
  final LayoutState<LabelConfig> state;

  LabelConfig resolve(LayoutContext context) => state.resolve(
    context,
    base: LabelConfig(style: style),
    merge: (current, overlay) => current.merge(overlay),
    resolveValue: (value, stateContext) => value.resolve(stateContext),
  );

  LabelConfig resolveWithDefaults(LayoutContext context) =>
      LabelDefaults.config.resolve(context).merge(resolve(context));

  LabelConfig merge(LabelConfig overlay) => LabelConfig(
    style: style.merge(overlay.style),
    state: state.merge(overlay.state),
  );
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
