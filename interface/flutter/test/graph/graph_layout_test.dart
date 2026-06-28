import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seville/graph/graph_layout.dart';
import 'package:seville/graph/graph_model.dart';

void main() {
  test('pins Cortex timeline concepts along the bottom of the world', () {
    const graph = KnowledgeGraph(
      nodes: [
        GraphNode(
          id: 'past',
          title: 'Past',
          path: 'science/physics/time/concept/past.md',
          tags: [],
          weightedDegree: 0,
          radius: 5,
          color: Colors.white,
        ),
        GraphNode(
          id: 'now',
          title: 'Now',
          path: r'cortex\time\concept\now.md',
          tags: [],
          weightedDegree: 0,
          radius: 5,
          color: Colors.white,
        ),
        GraphNode(
          id: 'future',
          title: 'Future',
          path: 'cortex/time/concept/future',
          tags: [],
          weightedDegree: 0,
          radius: 5,
          color: Colors.white,
        ),
      ],
      edges: [],
    );

    final positions = layoutGraph(graph);

    expect(positions['past'], const Offset(0.02, 0.975));
    expect(positions['now'], const Offset(0.50, 0.975));
    expect(positions['future'], const Offset(0.98, 0.975));
  });
}
