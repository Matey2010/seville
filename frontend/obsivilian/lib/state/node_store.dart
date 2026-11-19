import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../data/seville_api.dart';

final sevilleApiProvider = Provider<SevilleApi>((ref) {
  final api = SevilleApi();
  ref.onDispose(api.close);
  return api;
});

/// A root slug selects a local neighborhood; an empty root selects the global
/// graph, optionally narrowed by the submitted search term.
typedef NodeGraphRequest = ({String? rootNodeSlug, String search});

final nodeGraphProvider = FutureProvider.family<NodeGraph, NodeGraphRequest>(
  (ref, request) => ref
      .watch(sevilleApiProvider)
      .nodeGraph(rootNodeSlug: request.rootNodeSlug, search: request.search),
);

final nodeSearchProvider = FutureProvider.family<NodeSearchResult, String>(
  (ref, search) => ref.watch(sevilleApiProvider).searchNodes(search),
);

final nodesByExactSlugsProvider =
    FutureProvider.family<Map<String, Node>, String>((ref, joinedSlugs) async {
      final slugs = joinedSlugs
          .split('\n')
          .where((slug) => slug.isNotEmpty)
          .toList(growable: false);
      final result = await ref
          .watch(sevilleApiProvider)
          .nodesByExactSlugs(slugs);
      return {for (final node in result.nodes) node.slug: node};
    });

final nodeColorRulesProvider = FutureProvider<NodeColorRuleSet>(
  (ref) => ref.watch(sevilleApiProvider).nodeColorRules(),
);
