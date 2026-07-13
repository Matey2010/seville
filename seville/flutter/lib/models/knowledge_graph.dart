import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

import '../graph/graph_rules.dart';

class KnowledgeGraph {
  const KnowledgeGraph({required this.nodes, required this.edges});

  factory KnowledgeGraph.fromSnapshot(
    KnowledgeSnapshot snapshot, {
    Set<String>? visibleNoteIds,
    GraphRules rules = sevilleGraphRules,
  }) {
    final visible =
        visibleNoteIds ?? snapshot.notes.map((note) => note.id).toSet();
    final notes = {
      for (final note in snapshot.notes)
        if (visible.contains(note.id)) note.id: note,
    };
    final degree = {for (final id in notes.keys) id: 0.0};
    final edges = <GraphEdge>[];

    for (final link in snapshot.links) {
      if (!link.hasResolvedTargetId() ||
          !notes.containsKey(link.sourceNoteId) ||
          !notes.containsKey(link.resolvedTargetId)) {
        continue;
      }
      final weight = rules.weightFor(link.kind);
      degree[link.sourceNoteId] = degree[link.sourceNoteId]! + weight;
      degree[link.resolvedTargetId] = degree[link.resolvedTargetId]! + weight;
      edges.add(
        GraphEdge(
          sourceId: link.sourceNoteId,
          targetId: link.resolvedTargetId,
          kind: link.kind,
          weight: weight,
          color: rules.edgeColorFor(link.kind),
        ),
      );
    }

    return KnowledgeGraph(
      nodes: [
        for (final note in notes.values)
          GraphNode(
            id: note.id,
            title: note.title,
            path: note.path,
            tags: List.unmodifiable(note.tags),
            weightedDegree: degree[note.id]!,
            radius: rules.radiusFor(degree[note.id]!),
            color: rules.colorFor(note.tags),
          ),
      ],
      edges: List.unmodifiable(edges),
    );
  }

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
}

class GraphNode {
  const GraphNode({
    required this.id,
    required this.title,
    required this.path,
    required this.tags,
    required this.weightedDegree,
    required this.radius,
    required this.color,
  });

  final String id;
  final String title;
  final String path;
  final List<String> tags;
  final double weightedDegree;
  final double radius;
  final Color color;
}

class GraphEdge {
  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.kind,
    required this.weight,
    required this.color,
  });

  final String sourceId;
  final String targetId;
  final LinkKind kind;
  final double weight;
  final Color color;
}
