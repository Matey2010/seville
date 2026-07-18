import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';
import '../graph/graph_rules.dart';

class NodeGraph {
  const NodeGraph({required this.nodes, required this.edges});

  factory NodeGraph.fromSnapshot(
    NodeSnapshot snapshot, {
    Set<String>? visibleNodeIds,
    GraphRules rules = sevilleGraphRules,
  }) {
    final visible =
        visibleNodeIds ?? snapshot.nodes.map((node) => node.id).toSet();
    final visibleNodes = {
      for (final node in snapshot.nodes)
        if (visible.contains(node.id)) node.id: node,
    };
    final degree = {for (final id in visibleNodes.keys) id: 0.0};
    final edges = <GraphEdge>[];

    for (final connection in snapshot.connections) {
      if (!connection.hasTargetNodeId() ||
          !visibleNodes.containsKey(connection.sourceNodeId) ||
          !visibleNodes.containsKey(connection.targetNodeId)) {
        continue;
      }
      final weight = rules.weightFor(connection.kind);
      degree[connection.sourceNodeId] =
          degree[connection.sourceNodeId]! + weight;
      degree[connection.targetNodeId] =
          degree[connection.targetNodeId]! + weight;
      edges.add(
        GraphEdge(
          sourceId: connection.sourceNodeId,
          targetId: connection.targetNodeId,
          kind: connection.kind,
          weight: weight,
          color: rules.edgeColorFor(connection.kind),
        ),
      );
    }

    return NodeGraph(
      nodes: [
        for (final node in visibleNodes.values)
          GraphNode(
            id: node.id,
            title: node.title,
            displayLabel: node.displayLabel,
            path: node.path,
            tags: List.unmodifiable(node.tags),
            weightedDegree: degree[node.id]!,
            radius: rules.radiusFor(degree[node.id]!),
            color: rules.colorFor(node.tags),
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
    required this.displayLabel,
    required this.path,
    required this.tags,
    required this.weightedDegree,
    required this.radius,
    required this.color,
  });

  final String id;
  final String title;
  final String displayLabel;
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
  final NodeConnectionKind kind;
  final double weight;
  final Color color;
}
