import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seville/graph/graph_model.dart';
import 'package:seville/graph/graph_rules.dart';
import 'package:seville_proto/seville_proto.dart';

void main() {
  group('KnowledgeGraph', () {
    test('creates edges only for resolved visible notes', () {
      final snapshot = KnowledgeSnapshot(
        notes: [
          Note(id: 'a', title: 'A', path: 'A.md', tags: ['project']),
          Note(id: 'b', title: 'B', path: 'B.md'),
          Note(id: 'c', title: 'C', path: 'C.md'),
        ],
        links: [
          Link(
            sourceNoteId: 'a',
            targetText: 'B',
            resolvedTargetId: 'b',
            kind: LinkKind.LINK_KIND_WIKI,
          ),
          Link(
            sourceNoteId: 'a',
            targetText: 'Missing',
            kind: LinkKind.LINK_KIND_WIKI,
          ),
          Link(
            sourceNoteId: 'b',
            targetText: 'C',
            resolvedTargetId: 'c',
            kind: LinkKind.LINK_KIND_WIKI,
          ),
        ],
      );

      final graph = KnowledgeGraph.fromSnapshot(
        snapshot,
        visibleNoteIds: {'a', 'b'},
      );

      expect(graph.nodes.map((node) => node.id), unorderedEquals(['a', 'b']));
      expect(graph.edges, hasLength(1));
      expect(graph.edges.single.sourceId, 'a');
      expect(graph.edges.single.targetId, 'b');
    });

    test(
      'weights degree by link kind and applies first matching tag color',
      () {
        const rules = GraphRules(
          tagColors: {
            'important': Color(0xFFFF0000),
            'later': Color(0xFF00FF00),
          },
          fallbackColor: Color(0xFF0000FF),
          baseNodeRadius: 4,
          radiusPerWeight: 2,
          maxNodeRadius: 20,
          edgeWeights: {
            LinkKind.LINK_KIND_WIKI: 1,
            LinkKind.LINK_KIND_EMBED: 2,
          },
          edgeColors: {},
        );
        final snapshot = KnowledgeSnapshot(
          notes: [
            Note(
              id: 'a',
              title: 'A',
              path: 'A.md',
              tags: ['later', 'important'],
            ),
            Note(id: 'b', title: 'B', path: 'B.md'),
          ],
          links: [
            Link(
              sourceNoteId: 'a',
              targetText: 'B',
              resolvedTargetId: 'b',
              kind: LinkKind.LINK_KIND_EMBED,
            ),
          ],
        );

        final graph = KnowledgeGraph.fromSnapshot(snapshot, rules: rules);
        final a = graph.nodes.singleWhere((node) => node.id == 'a');

        expect(a.weightedDegree, 2);
        expect(a.radius, 8);
        expect(a.color, const Color(0xFFFF0000));
      },
    );
  });
}
