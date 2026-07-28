import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart'
    hide NodeSearchFilter, NodeSearchParameter;

import '../data/seville_api.dart';
import '../models/layout/layout.dart';
import '../utils/vault_node_resolver.dart';

final sevilleApiProvider = Provider<SevilleApi>((ref) {
  final api = SevilleApi();
  ref.onDispose(api.close);
  return api;
});

class VaultNodeLookupRequest {
  VaultNodeLookupRequest(Iterable<String> paths)
    : paths = List.unmodifiable({
        for (final path in paths)
          if (path.trim().isNotEmpty) path.trim(),
      });

  final List<String> paths;

  @override
  bool operator ==(Object other) =>
      other is VaultNodeLookupRequest && _sameStrings(paths, other.paths);

  @override
  int get hashCode => Object.hashAll(paths);
}

final vaultNodeResolverProvider =
    FutureProvider.family<VaultNodeResolver, VaultNodeLookupRequest>((
      ref,
      request,
    ) async {
      if (request.paths.isEmpty) return VaultNodeResolver.empty;
      final lookupParameters = <NodeSearchParameter>[];
      for (final path in request.paths) {
        final candidates = VaultNodeResolver.pathCandidates(path);
        lookupParameters.addAll(
          candidates
              .where((candidate) => candidate.isNotEmpty)
              .map(
                (candidate) => NodeSearchParameter(
                  parameter: NodeParameter.path,
                  value: candidate,
                ),
              ),
        );
        final normalizedPath = VaultNodeResolver.normalizePath(path);
        final leaf = normalizedPath.split('/').lastOrNull;
        if (leaf != null && leaf.isNotEmpty) {
          lookupParameters.add(
            NodeSearchParameter(parameter: NodeParameter.slug, value: leaf),
          );
        }
        if (VaultNodeResolver.isCortexRootPath(path)) {
          lookupParameters.add(
            const NodeSearchParameter(
              parameter: NodeParameter.slug,
              value: 'cortex',
              operator: NodeMatchOperator.contains,
            ),
          );
        }
      }
      final result = await ref
          .watch(sevilleApiProvider)
          .queryNodes(
            nodeFilter: NodeSearchFilter.anyOf(lookupParameters),
            limit: lookupParameters.length.clamp(1, 100),
          );
      return VaultNodeResolver.fromNodes(result.nodes);
    });

final nodeBySlugProvider = FutureProvider.family<Node?, String>((
  ref,
  slug,
) async {
  final normalizedSlug = slug.trim();
  if (normalizedSlug.isEmpty) return null;
  final result = await ref
      .watch(sevilleApiProvider)
      .queryNodes(
        nodeFilter: NodeSearchFilter.anyOf([
          NodeSearchParameter(
            parameter: NodeParameter.slug,
            value: normalizedSlug,
          ),
        ]),
        limit: 1,
      );
  for (final node in result.nodes) {
    if (node.slug.trim() == normalizedSlug) return node;
  }
  return null;
});

final systemInfoProvider = FutureProvider<SystemInfo>((ref) async {
  final api = ref.watch(sevilleApiProvider);
  return api.systemInfo();
});

final nodeSearchProvider = FutureProvider.family<NodeSearchResult, String>((
  ref,
  value,
) async {
  final normalizedValue = value.trim();
  if (normalizedValue.isEmpty) return NodeSearchResult();
  final api = ref.watch(sevilleApiProvider);
  return api.searchNodes(normalizedValue);
});

class NodeTreeRequest {
  NodeTreeRequest({
    required this.rootNodeId,
    required this.rootNodeFilter,
    required this.depth,
    required this.traverseBy,
    this.nodeFilter,
  });

  final String? rootNodeId;
  final NodeSearchFilter? rootNodeFilter;
  final int depth;
  final GraphTraverseType traverseBy;
  final NodeSearchFilter? nodeFilter;

  @override
  bool operator ==(Object other) =>
      other is NodeTreeRequest &&
      rootNodeId == other.rootNodeId &&
      rootNodeFilter == other.rootNodeFilter &&
      depth == other.depth &&
      traverseBy == other.traverseBy &&
      nodeFilter == other.nodeFilter;

  @override
  int get hashCode =>
      Object.hash(rootNodeId, rootNodeFilter, depth, traverseBy, nodeFilter);
}

final nodeTreeProvider = FutureProvider.family<NodeTree, NodeTreeRequest>((
  ref,
  request,
) async {
  final api = ref.watch(sevilleApiProvider);
  return api.nodeTree(
    rootNodeId: request.rootNodeId,
    rootNodeFilter: request.rootNodeFilter,
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
  var _nextVirtualNodeNumber = 1;

  @override
  List<ResolvedVaultNode> build() => const [];

  ResolvedVaultNode? get firstVirtualNode {
    for (final node in state) {
      if (node.isVirtual) return node;
    }
    return null;
  }

  String nextVirtualNodeSlugCandidate() {
    final usedSlugs = {
      for (final selectedNode in state)
        if (selectedNode.node?.slug.trim() case final slug?
            when slug.isNotEmpty)
          slug,
    };
    late String slug;
    do {
      final number = _nextVirtualNodeNumber++;
      slug = number == 1 ? 'new-node' : 'new-node-$number';
    } while (usedSlugs.contains(slug));
    return slug;
  }

  ResolvedVaultNode addVirtualNode({
    required String slug,
    Iterable<String> labels = const [],
  }) {
    final node = Node(
      slug: slug,
      path: slug,
      title: 'New Node',
      labels: labels,
    );
    final resolvedNode = ResolvedVaultNode(
      path: slug,
      node: node,
      resolvedStatus: LayoutHttpStatus.noContent,
      isVirtual: true,
    );
    state = List.unmodifiable([...state, resolvedNode]);
    return resolvedNode;
  }

  bool replaceVirtualNode(ResolvedVaultNode virtualNode, Node createdNode) {
    final virtualSlug = virtualNode.node?.slug.trim();
    if (virtualSlug == null || virtualSlug.isEmpty) return false;
    final index = state.indexWhere(
      (candidate) =>
          candidate.isVirtual && candidate.node?.slug.trim() == virtualSlug,
    );
    if (index < 0) return false;
    final createdSlug = createdNode.slug.trim();
    final createdPath = createdNode.path.trim();
    final resolvedNode = ResolvedVaultNode(
      path: createdPath.isEmpty ? createdSlug : createdPath,
      node: createdNode,
      resolvedStatus: LayoutHttpStatus.ok,
    );
    state = List.unmodifiable([
      ...state.take(index),
      resolvedNode,
      ...state.skip(index + 1),
    ]);
    return true;
  }

  void select(ResolvedVaultNode node) {
    final index = state.indexWhere(
      (candidate) => _representsSameNode(candidate, node),
    );
    if (index < 0) {
      state = List.unmodifiable([...state, node]);
      return;
    }
    state = List.unmodifiable([
      ...state.take(index),
      node,
      ...state.skip(index + 1),
    ]);
  }

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

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _representsSameNode(ResolvedVaultNode left, ResolvedVaultNode right) {
  final leftSlug = left.node?.slug.trim();
  final rightSlug = right.node?.slug.trim();
  return leftSlug != null &&
      leftSlug.isNotEmpty &&
      rightSlug != null &&
      rightSlug.isNotEmpty &&
      leftSlug == rightSlug;
}
