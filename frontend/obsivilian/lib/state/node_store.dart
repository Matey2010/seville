import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../data/seville_api.dart';

final sevilleApiProvider = Provider<SevilleApi>((ref) {
  final api = SevilleApi();
  ref.onDispose(api.close);
  return api;
});

/// A root ID selects a local neighborhood; an empty root selects the global
/// graph, optionally narrowed by the submitted search term.
typedef NodeGraphRequest = ({String? rootNodeId, String search});

final nodeGraphProvider = FutureProvider.family<NodeGraph, NodeGraphRequest>(
  (ref, request) => ref
      .watch(sevilleApiProvider)
      .nodeGraph(rootNodeId: request.rootNodeId, search: request.search),
);

final nodeSearchProvider = FutureProvider.family<NodeSearchResult, String>(
  (ref, search) => ref.watch(sevilleApiProvider).searchNodes(search),
);

final nodeColorRulesProvider = FutureProvider<NodeColorRuleSet>(
  (ref) => ref.watch(sevilleApiProvider).nodeColorRules(),
);
