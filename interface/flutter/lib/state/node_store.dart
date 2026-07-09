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
  return VaultNodeResolver.fromNotes(snapshot.notes);
});

final selectedNodeProvider =
    NotifierProvider<SelectedNodeNotifier, ResolvedVaultNode?>(
      SelectedNodeNotifier.new,
    );

class SelectedNodeNotifier extends Notifier<ResolvedVaultNode?> {
  @override
  ResolvedVaultNode? build() => null;

  void select(ResolvedVaultNode? node) {
    state = node;
  }
}

final selectedNodeComponentProvider =
    NotifierProvider<SelectedNodeComponentNotifier, VaultNodeUiComponent?>(
      SelectedNodeComponentNotifier.new,
    );

class SelectedNodeComponentNotifier extends Notifier<VaultNodeUiComponent?> {
  @override
  VaultNodeUiComponent? build() => null;

  void select(VaultNodeUiComponent? component) {
    state = component;
  }
}
