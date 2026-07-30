part of 'layout.dart';

/// Canonical fallback values for Node presentation across Layouts.
abstract final class NodeDefaults {
  static const config = NodeConfig(
    slugColor: slugColor,
    labelColor: labelColor,
    valueColor: valueColor,
    slugPrefix: slugPrefix,
    slugTransform: slugTransform,
    slugSuffix: slugSuffix,
    state: LayoutState({
      LayoutCondition.nodeHighlighted(): NodeConfig(
        borderStyle: GuideStyle(color: Color(0xFF2196F3), strokeWidth: 4),
      ),
    }),
  );
  static const inactiveBackgroundOpacity = 0.1;
  static const activeBackgroundOpacity = 1.0;
  static const virtualBackgroundOpacity = 0.5;
  static const slugPrefix = '';
  static const slugTransform = TextTransform.none();
  static const slugSuffix = '';
  static const slugColor = Color(0xFFFFD54F);
  static const labelColor = Color(0xFFFFF8E7);
  static const valueColor = Color(0xFFFFF8E7);
}

/// Extensible Node configuration selected by Layout state.
class NodeConfig {
  const NodeConfig({
    this.content,
    this.backgroundColor,
    this.backgroundOpacity,
    this.borderStyle,
    this.slugColor,
    this.slugPrefix,
    this.slugTransform,
    this.slugSuffix,
    this.labelColor,
    this.valueColor,
    this.text = const LayoutTextConfig(),
    this.state = const LayoutState(),
  }) : assert(
         backgroundOpacity == null ||
             (backgroundOpacity >= 0 && backgroundOpacity <= 1),
       );

  final NodeContent? content;
  final Color? backgroundColor;
  final double? backgroundOpacity;
  final GuideStyle? borderStyle;
  final Color? slugColor;
  final String? slugPrefix;
  final TextTransform? slugTransform;
  final String? slugSuffix;
  final Color? labelColor;
  final Color? valueColor;
  final LayoutTextConfig text;

  /// Ordered conditional specializations of this configuration.
  ///
  /// Matching child configurations resolve recursively and merge in insertion
  /// order. This permits nested state without coupling future Node behavior to
  /// the renderer or splitting presentation into parallel wrappers.
  final LayoutState<NodeConfig> state;

  NodeConfig resolve(LayoutContext context) => state.resolve(
    context,
    base: NodeConfig(
      content: content,
      backgroundColor: backgroundColor,
      backgroundOpacity: backgroundOpacity,
      borderStyle: borderStyle,
      slugColor: slugColor,
      slugPrefix: slugPrefix,
      slugTransform: slugTransform,
      slugSuffix: slugSuffix,
      labelColor: labelColor,
      valueColor: valueColor,
      text: text,
    ),
    merge: (current, overlay) => current.merge(overlay),
    resolveValue: (value, stateContext) => value.resolve(stateContext),
  );

  NodeConfig merge(NodeConfig overlay) => NodeConfig(
    content: overlay.content ?? content,
    backgroundColor: overlay.backgroundColor ?? backgroundColor,
    backgroundOpacity: overlay.backgroundOpacity ?? backgroundOpacity,
    borderStyle: overlay.borderStyle ?? borderStyle,
    slugColor: overlay.slugColor ?? slugColor,
    slugPrefix: overlay.slugPrefix ?? slugPrefix,
    slugTransform: overlay.slugTransform ?? slugTransform,
    slugSuffix: overlay.slugSuffix ?? slugSuffix,
    labelColor: overlay.labelColor ?? labelColor,
    valueColor: overlay.valueColor ?? valueColor,
    text: text.merge(overlay.text),
  );

  String formatSlug(String slug) {
    final prefix = slugPrefix ?? NodeDefaults.slugPrefix;
    final transform = slugTransform ?? NodeDefaults.slugTransform;
    final suffix = slugSuffix ?? NodeDefaults.slugSuffix;
    return '$prefix${transform.apply(slug)}$suffix';
  }
}

/// Selects one exact piece of Node data for compact Node content.
class NodeContent {
  const NodeContent.slug() : _type = _NodeContentType.slug;
  const NodeContent.alias() : _type = _NodeContentType.alias;
  const NodeContent.emoji() : _type = _NodeContentType.emoji;
  const NodeContent.title() : _type = _NodeContentType.title;

  final _NodeContentType _type;

  bool get isSlug => _type == _NodeContentType.slug;
  bool get isEmoji => _type == _NodeContentType.emoji;

  String resolve(Node node, NodeConfig config) => switch (_type) {
    _NodeContentType.slug => config.formatSlug(node.slug.trim()),
    _NodeContentType.alias =>
      (node.frontmatter['aliases'] ?? node.frontmatter['alias'] ?? '').trim(),
    _NodeContentType.emoji => _firstNodeEmoji(node),
    _NodeContentType.title => node.title.trim(),
  };
}

enum _NodeContentType { slug, alias, emoji, title }

String _firstNodeEmoji(Node node) {
  for (final emoji in node.emojis) {
    final character = emoji.character.trim();
    if (character.isNotEmpty) return character;
  }
  return '';
}
