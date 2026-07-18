import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../data/seville_api.dart';
import '../models/layout.dart';
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

typedef NodeTreeRequest = ({String? rootNodeId, int depth});

final nodeTreeProvider = FutureProvider.family<NodeTree, NodeTreeRequest>((
  ref,
  request,
) async {
  final api = ref.watch(sevilleApiProvider);
  return api.nodeTree(rootNodeId: request.rootNodeId, depth: request.depth);
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

  void select(ResolvedVaultNode node) {
    if (state.any((candidate) => candidate.path == node.path)) return;
    state = List.unmodifiable([...state, node]);
  }

  void clear() {
    state = const [];
  }
}
