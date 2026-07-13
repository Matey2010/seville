import 'package:seville_proto/seville_proto.dart';

class Node {
  const Node({
    required this.id,
    required this.path,
    required this.title,
    required this.body,
    required this.tags,
    required this.frontmatter,
    required this.note,
  });

  factory Node.fromNote(Note note) {
    return Node(
      id: note.id,
      path: note.path,
      title: note.title,
      body: note.body,
      tags: List.unmodifiable(note.tags),
      frontmatter: Map.unmodifiable(note.frontmatter),
      note: note,
    );
  }

  final String id;
  final String path;
  final String title;
  final String body;
  final List<String> tags;
  final Map<String, String> frontmatter;
  final Note note;

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
