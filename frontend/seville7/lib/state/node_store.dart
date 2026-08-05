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

final layoutSnapshotProvider = Provider.family<LayoutSnapshot, Layout>(
  (ref, layout) => LayoutSnapshot.capture(layout),
);

class VaultNodeLookupRequest {
  VaultNodeLookupRequest(Iterable<LayoutVaultNodeReference> references)
    : references = List.unmodifiable(references);

  final List<LayoutVaultNodeReference> references;

  Iterable<String> get paths => {
    for (final reference in references)
      if (reference.vaultNode.path.trim().isNotEmpty)
        reference.vaultNode.path.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is VaultNodeLookupRequest &&
      _sameVaultNodeReferences(references, other.references);

  @override
  int get hashCode => Object.hashAll([
    for (final reference in references)
      Object.hash(
        Object.hashAll(reference.layoutPath),
        reference.vaultNode.path,
      ),
  ]);
}

final vaultNodeResolverProvider =
    FutureProvider.family<VaultNodeResolver, VaultNodeLookupRequest>((
      ref,
      request,
    ) async {
      final paths = request.paths.toList(growable: false);
      if (paths.isEmpty) return VaultNodeResolver.empty;
      final lookupParameters = <NodeSearchParameter>[];
      for (final path in paths) {
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

class NodeBySlugRequest {
  const NodeBySlugRequest({required this.slug, required this.layoutPath});

  final String slug;
  final List<String> layoutPath;

  @override
  bool operator ==(Object other) =>
      other is NodeBySlugRequest &&
      slug == other.slug &&
      _sameStrings(layoutPath, other.layoutPath);

  @override
  int get hashCode => Object.hash(slug, Object.hashAll(layoutPath));
}

final nodeBySlugProvider =
    FutureProvider.family<ResolvedVaultNode?, NodeBySlugRequest>((
      ref,
      request,
    ) async {
      final normalizedSlug = request.slug.trim();
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
        if (node.slug.trim() != normalizedSlug) continue;
        return ResolvedVaultNode(
          path: node.path.trim().isEmpty ? node.slug : node.path,
          node: node,
          resolvedStatus: LayoutHttpStatus.ok,
          origin: ResolvedNodeOrigin.server(layoutPath: request.layoutPath),
        );
      }
      return null;
    });

class NodeLayoutRequest {
  const NodeLayoutRequest({required this.filter, required this.layoutPath});

  final NodeSearchFilter filter;
  final List<String> layoutPath;

  @override
  bool operator ==(Object other) =>
      other is NodeLayoutRequest &&
      filter == other.filter &&
      _sameStrings(layoutPath, other.layoutPath);

  @override
  int get hashCode => Object.hash(filter, Object.hashAll(layoutPath));
}

final nodeLayoutProvider =
    FutureProvider.family<ResolvedVaultNode?, NodeLayoutRequest>((
      ref,
      request,
    ) async {
      final result = await ref
          .watch(sevilleApiProvider)
          .queryNodes(nodeFilter: request.filter, limit: 1);
      final node = result.nodes.firstOrNull;
      if (node == null) return null;
      return ResolvedVaultNode(
        path: node.path.trim().isEmpty ? node.slug : node.path,
        node: node,
        resolvedStatus: LayoutHttpStatus.ok,
        origin: ResolvedNodeOrigin.server(layoutPath: request.layoutPath),
      );
    });

final systemInfoProvider = FutureProvider<SystemInfo>((ref) async {
  final api = ref.watch(sevilleApiProvider);
  return api.systemInfo();
});

class NodeSearchRequest {
  const NodeSearchRequest({required this.value, required this.layoutPath});

  final String value;
  final List<String> layoutPath;

  @override
  bool operator ==(Object other) =>
      other is NodeSearchRequest &&
      value == other.value &&
      _sameStrings(layoutPath, other.layoutPath);

  @override
  int get hashCode => Object.hash(value, Object.hashAll(layoutPath));
}

final nodeSearchProvider =
    FutureProvider.family<List<ResolvedVaultNode>, NodeSearchRequest>((
      ref,
      request,
    ) async {
      final normalizedValue = request.value.trim();
      if (normalizedValue.isEmpty) return const [];
      final api = ref.watch(sevilleApiProvider);
      final result = await api.searchNodes(normalizedValue);
      return [
        for (final node in result.nodes)
          ResolvedVaultNode(
            path: node.path.trim().isEmpty ? node.slug : node.path,
            node: node,
            resolvedStatus: LayoutHttpStatus.ok,
            origin: ResolvedNodeOrigin.server(layoutPath: request.layoutPath),
          ),
      ];
    });

class NodeTreeRequest {
  NodeTreeRequest({
    required this.layoutPath,
    required this.rootNodeId,
    required this.rootNodeFilter,
    required this.depth,
    required this.traverseBy,
    this.nodeFilter,
  });

  final List<String> layoutPath;
  final String? rootNodeId;
  final NodeSearchFilter? rootNodeFilter;
  final int depth;
  final GraphTraverseType traverseBy;
  final NodeSearchFilter? nodeFilter;

  @override
  bool operator ==(Object other) =>
      other is NodeTreeRequest &&
      _sameStrings(layoutPath, other.layoutPath) &&
      rootNodeId == other.rootNodeId &&
      rootNodeFilter == other.rootNodeFilter &&
      depth == other.depth &&
      traverseBy == other.traverseBy &&
      nodeFilter == other.nodeFilter;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(layoutPath),
    rootNodeId,
    rootNodeFilter,
    depth,
    traverseBy,
    nodeFilter,
  );
}

final nodeTreeProvider =
    FutureProvider.family<ResolvedNodeTree, NodeTreeRequest>((
      ref,
      request,
    ) async {
      final api = ref.watch(sevilleApiProvider);
      return ResolvedNodeTree(
        tree: await api.nodeTree(
          rootNodeId: request.rootNodeId,
          rootNodeFilter: request.rootNodeFilter,
          depth: request.depth,
          traverseBy: request.traverseBy,
          nodeFilter: request.nodeFilter,
        ),
        origin: ResolvedNodeOrigin.server(layoutPath: request.layoutPath),
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
    required List<String> layoutPath,
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
      origin: ResolvedNodeOrigin.layout(layoutPath: layoutPath),
      isVirtual: true,
    );
    state = List.unmodifiable([...state, resolvedNode]);
    return resolvedNode;
  }

  ResolvedVaultNode storeFallbackNode(
    Node fallbackNode, {
    required List<String> layoutPath,
  }) {
    final node = fallbackNode.deepCopy();
    final slug = node.slug.trim();
    if (slug.isEmpty) {
      throw ArgumentError.value(
        fallbackNode,
        'fallbackNode',
        'slug is required',
      );
    }
    final existing = state
        .where((candidate) => candidate.node?.slug.trim() == slug)
        .firstOrNull;
    if (existing != null) return existing;
    if (!node.labels.contains('Virtual')) node.labels.add('Virtual');
    if (node.path.trim().isEmpty) node.path = slug;
    final resolvedNode = ResolvedVaultNode(
      path: node.path,
      node: node,
      resolvedStatus: LayoutHttpStatus.noContent,
      origin: ResolvedNodeOrigin.layout(layoutPath: layoutPath),
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
      origin: ResolvedNodeOrigin.server(
        layoutPath: virtualNode.origin.layoutPath,
      ),
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

bool _sameVaultNodeReferences(
  List<LayoutVaultNodeReference> left,
  List<LayoutVaultNodeReference> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (!_sameStrings(left[index].layoutPath, right[index].layoutPath) ||
        left[index].vaultNode.path != right[index].vaultNode.path) {
      return false;
    }
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
