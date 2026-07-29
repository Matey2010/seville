part of 'layout.dart';

/// Canonical fallback values for Node presentation across Layouts.
abstract final class NodeDefaults {
  static const config = NodeConfig(
    style: NodeStyle(
      slugColor: slugColor,
      labelColor: labelColor,
      valueColor: valueColor,
      slugPrefix: slugPrefix,
      slugTransform: slugTransform,
      slugSuffix: slugSuffix,
    ),
  );
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
  static const labelColor = Color(0xFFFFF8E7);
  static const valueColor = Color(0xFFFFF8E7);
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
    this.slugPrefix,
    this.slugTransform,
    this.slugSuffix,
    this.labelColor,
    this.valueColor,
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
  final String? slugPrefix;
  final TextTransform? slugTransform;
  final String? slugSuffix;
  final Color? labelColor;
  final Color? valueColor;
  final double? labelSize;

  String formatSlug(String slug) {
    final prefix = slugPrefix ?? NodeDefaults.slugPrefix;
    final transform = slugTransform ?? NodeDefaults.slugTransform;
    final suffix = slugSuffix ?? NodeDefaults.slugSuffix;
    return '$prefix${transform.apply(slug)}$suffix';
  }

  NodeStyle merge(NodeStyle overlay) => NodeStyle(
    backgroundColor: overlay.backgroundColor ?? backgroundColor,
    backgroundOpacity: overlay.backgroundOpacity ?? backgroundOpacity,
    borderStyle: overlay.borderStyle ?? borderStyle,
    slugColor: overlay.slugColor ?? slugColor,
    slugPrefix: overlay.slugPrefix ?? slugPrefix,
    slugTransform: overlay.slugTransform ?? slugTransform,
    slugSuffix: overlay.slugSuffix ?? slugSuffix,
    labelColor: overlay.labelColor ?? labelColor,
    valueColor: overlay.valueColor ?? valueColor,
    labelSize: overlay.labelSize ?? labelSize,
  );
}
