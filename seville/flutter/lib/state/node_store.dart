import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seville_api.dart';
import '../models/layout.dart';
import '../utils/vault_node_resolver.dart';

final sevilleApiProvider = Provider<SevilleApi>((ref) {
  final api = SevilleApi();
  ref.onDispose(api.close);
  return api;
});

final vaultNodeResolverProvider = FutureProvider<VaultNodeResolver>((
  ref,
) async {
  final api = ref.watch(sevilleApiProvider);
  final snapshot = await api.snapshot();
  return VaultNodeResolver.fromNodes(snapshot.nodes);
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
