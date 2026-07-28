part of 'layout.dart';

/// Canonical fallback values for Node presentation across Layouts.
abstract final class NodeDefaults {
  static const config = NodeConfig();
  static const inactiveBackgroundOpacity = 0.1;
  static const activeBackgroundOpacity = 1.0;
  static const virtualBackgroundOpacity = 0.5;
  static const hoverBorderStyle = GuideStyle(
    color: Color(0xFF2196F3),
    strokeWidth: 4,
  );
  static const slugPrefix = '';
  static const slugTransform = TextTransform.none();
  static const slugSuffix = '';
  static const slugColor = Color(0xFFFFD54F);
}

/// Extensible Node configuration selected by Layout state.
class NodeConfig {
  const NodeConfig({this.style = const NodeStyle(), this.state = const {}});

  final NodeStyle style;

  /// Ordered conditional specializations of this configuration.
  ///
  /// Matching child configurations resolve recursively and merge in insertion
  /// order. This permits nested state without coupling future Node behavior to
  /// the renderer or flattening every concern into [NodeStyle].
  final Map<LayoutCondition, NodeConfig> state;

  NodeConfig resolve(LayoutContext context) {
    var resolved = NodeConfig(style: style);
    for (final entry in state.entries) {
      if (entry.key.isActive(context)) {
        resolved = resolved.merge(entry.value.resolve(context));
      }
    }
    return resolved;
  }

  NodeConfig merge(NodeConfig overlay) =>
      NodeConfig(style: style.merge(overlay.style));
}

/// Renderer-independent Node presentation values owned by [NodeConfig].
class NodeStyle {
  const NodeStyle({
    this.backgroundColor,
    this.backgroundOpacity,
    this.borderStyle,
    this.slugColor,
    this.labelColor,
    this.labelSize,
  }) : assert(
         backgroundOpacity == null ||
             (backgroundOpacity >= 0 && backgroundOpacity <= 1),
       ),
       assert(labelSize == null || labelSize >= 0);

  final Color? backgroundColor;
  final double? backgroundOpacity;
  final GuideStyle? borderStyle;
  final Color? slugColor;
  final Color? labelColor;
  final double? labelSize;

  NodeStyle merge(NodeStyle overlay) => NodeStyle(
    backgroundColor: overlay.backgroundColor ?? backgroundColor,
    backgroundOpacity: overlay.backgroundOpacity ?? backgroundOpacity,
    borderStyle: overlay.borderStyle ?? borderStyle,
    slugColor: overlay.slugColor ?? slugColor,
    labelColor: overlay.labelColor ?? labelColor,
    labelSize: overlay.labelSize ?? labelSize,
  );
}
