import 'package:seville_proto/seville_proto.dart';

extension NodeMetadata on Node {
  String? get primaryEmojiCharacter {
    for (final emoji in emojis) {
      final character = emoji.character.trim();
      if (character.isNotEmpty) return character;
    }
    return null;
  }

  String get displayLabel {
    final emoji = primaryEmojiCharacter;
    if (emoji != null) return emoji;
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isNotEmpty) return normalizedSlug;
    final normalizedTitle = title.trim();
    return normalizedTitle.isNotEmpty ? normalizedTitle : id;
  }

  String? get version =>
      frontmatter['version'] ??
      frontmatter['node_version'] ??
      frontmatter['schema_version'];

  String? get aliases => frontmatter['aliases'] ?? frontmatter['alias'];

  String? get classification =>
      frontmatter['classification'] ??
      frontmatter['class'] ??
      frontmatter['type'] ??
      frontmatter['kind'];
}
