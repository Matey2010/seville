import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart'
    hide NodeSearchFilter, NodeSearchParameter;

import '../data/seville_api.dart';
import '../models/graph_traverse_type.dart';
import '../models/layout.dart';
import '../models/node_search.dart';
import '../utils/vault_node_resolver.dart';

final sevilleApiProvider = Provider<SevilleApi>((ref) {
  final api = SevilleApi();
  ref.onDispose(api.close);
  return api;
});

final nodeSnapshotProvider = FutureProvider<NodeSnapshot>((ref) async {
  final api = ref.watch(sevilleApiProvider);
  return api.snapshot();
});

final vaultNodeResolverProvider = FutureProvider<VaultNodeResolver>((
  ref,
) async {
  final snapshot = await ref.watch(nodeSnapshotProvider.future);
  return VaultNodeResolver.fromNodes(snapshot.nodes);
});

final nodeEmojisProvider = Provider.family<AsyncValue<List<Emoji>>, String>((
  ref,
  nodeId,
) {
  return ref.watch(nodeSnapshotProvider).whenData((snapshot) {
    for (final node in snapshot.nodes) {
      if (node.id == nodeId) {
        return List<Emoji>.unmodifiable(node.emojis);
      }
    }
    return const <Emoji>[];
  });
});

final systemInfoProvider = FutureProvider<SystemInfo>((ref) async {
  final api = ref.watch(sevilleApiProvider);
  return api.systemInfo();
});

class NodeTreeRequest {
  NodeTreeRequest({
    required this.rootNodeId,
    required this.depth,
    required this.traverseBy,
    this.nodeFilter,
  });

  final String? rootNodeId;
  final int depth;
  final GraphTraverseType traverseBy;
  final NodeSearchFilter? nodeFilter;

  @override
  bool operator ==(Object other) =>
      other is NodeTreeRequest &&
      rootNodeId == other.rootNodeId &&
      depth == other.depth &&
      traverseBy == other.traverseBy &&
      nodeFilter == other.nodeFilter;

  @override
  int get hashCode => Object.hash(rootNodeId, depth, traverseBy, nodeFilter);
}

final nodeTreeProvider = FutureProvider.family<NodeTree, NodeTreeRequest>((
  ref,
  request,
) async {
  final api = ref.watch(sevilleApiProvider);
  return api.nodeTree(
    rootNodeId: request.rootNodeId,
    depth: request.depth,
    traverseBy: request.traverseBy,
    nodeFilter: request.nodeFilter,
  );
});

final highlightedNodesProvider =
    NotifierProvider<HighlightedNodesNotifier, List<ResolvedVaultNode>>(
      HighlightedNodesNotifier.new,
    );

class HighlightedNodesNotifier extends Notifier<List<ResolvedVaultNode>> {
  @override
  List<ResolvedVaultNode> build() => const [];

  void setNodes(Iterable<ResolvedVaultNode> nodes) {
    state = List.unmodifiable(nodes);
  }
}

final selectedNodesProvider =
    NotifierProvider<SelectedNodesNotifier, List<ResolvedVaultNode>>(
      SelectedNodesNotifier.new,
    );

class SelectedNodesNotifier extends Notifier<List<ResolvedVaultNode>> {
  @override
  List<ResolvedVaultNode> build() => const [];

  void toggle(ResolvedVaultNode node) {
    final remaining = [
      for (final candidate in state)
        if (!_representsSameNode(candidate, node)) candidate,
    ];
    if (remaining.length == state.length) {
      remaining.add(node);
    }
    state = List.unmodifiable(remaining);
  }

  void clear() {
    state = const [];
  }
}

bool _representsSameNode(ResolvedVaultNode left, ResolvedVaultNode right) {
  final leftId = left.node?.id.trim();
  final rightId = right.node?.id.trim();
  if (leftId != null &&
      leftId.isNotEmpty &&
      rightId != null &&
      rightId.isNotEmpty) {
    return leftId == rightId;
  }
  return left.path == right.path;
}
