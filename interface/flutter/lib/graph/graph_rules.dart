import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

/// All visual decisions for the knowledge graph live here.
///
/// Change [sevilleGraphRules] to tune the graph without touching parsing,
/// filtering, layout, or rendering code.
class GraphRules {
  const GraphRules({
    required this.tagColors,
    required this.fallbackColor,
    required this.baseNodeRadius,
    required this.radiusPerWeight,
    required this.maxNodeRadius,
    required this.edgeWeights,
    required this.edgeColors,
  });

  final Map<String, Color> tagColors;
  final Color fallbackColor;
  final double baseNodeRadius;
  final double radiusPerWeight;
  final double maxNodeRadius;
  final Map<LinkKind, double> edgeWeights;
  final Map<LinkKind, Color> edgeColors;

  Color colorFor(Iterable<String> tags) {
    final normalized = tags.map((tag) => tag.toLowerCase()).toSet();
    for (final entry in tagColors.entries) {
      if (normalized.contains(entry.key.toLowerCase())) return entry.value;
    }
    return fallbackColor;
  }

  double weightFor(LinkKind kind) => edgeWeights[kind] ?? 1;

  Color edgeColorFor(LinkKind kind) =>
      edgeColors[kind] ?? const Color(0x557D8BA6);

  double radiusFor(double weightedDegree) {
    return (baseNodeRadius + weightedDegree * radiusPerWeight).clamp(
      baseNodeRadius,
      maxNodeRadius,
    );
  }
}

const sevilleGraphRules = GraphRules(
  // First matching tag wins: put the most meaningful categories first.
  tagColors: {
    'project': Color(0xFFFFB454),
    'active': Color(0xFF62D6A7),
    'idea': Color(0xFFB18CFE),
    'person': Color(0xFFFF7A90),
    'archive': Color(0xFF6D7890),
  },
  fallbackColor: Color(0xFF76B7FF),
  baseNodeRadius: 5,
  radiusPerWeight: 1.7,
  maxNodeRadius: 19,
  edgeWeights: {
    LinkKind.LINK_KIND_WIKI: 1,
    LinkKind.LINK_KIND_MARKDOWN: 0.75,
    LinkKind.LINK_KIND_EMBED: 1.5,
  },
  edgeColors: {
    LinkKind.LINK_KIND_WIKI: Color(0x6676B7FF),
    LinkKind.LINK_KIND_MARKDOWN: Color(0x447D8BA6),
    LinkKind.LINK_KIND_EMBED: Color(0x88B18CFE),
  },
);
