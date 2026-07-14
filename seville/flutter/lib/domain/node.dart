import 'package:seville_proto/seville_proto.dart';

extension NodeMetadata on Node {
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
