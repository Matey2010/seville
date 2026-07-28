import 'package:seville_proto/seville_proto.dart';

import '../models/layout/layout.dart';

class VaultNodeResolver {
  const VaultNodeResolver._(this._nodesByPath, this._nodes);

  factory VaultNodeResolver.fromNodes(Iterable<Node> nodes) {
    final nodeList = List<Node>.unmodifiable(nodes);
    return VaultNodeResolver._({
      for (final node in nodeList) normalizePath(node.path): node,
    }, nodeList);
  }

  static const empty = VaultNodeResolver._({}, []);

  final Map<String, Node> _nodesByPath;
  final List<Node> _nodes;

  bool get isEmpty => _nodes.isEmpty;

  ResolvedVaultNode resolve(VaultNode vaultNode) {
    final configuredStatus = vaultNode.status;
    if (configuredStatus != null) {
      final node = configuredStatus == LayoutHttpStatus.ok
          ? _findNode(vaultNode.path)
          : null;
      return ResolvedVaultNode(
        path: vaultNode.path,
        color: vaultNode.color,
        label: vaultNode.label,
        status: vaultNode.status,
        backgrounds: vaultNode.backgrounds,
        node: node,
        resolvedStatus: configuredStatus,
      );
    }

    final node = _findNode(vaultNode.path);
    return ResolvedVaultNode(
      path: vaultNode.path,
      color: vaultNode.color,
      label: vaultNode.label,
      status: vaultNode.status,
      backgrounds: vaultNode.backgrounds,
      node: node,
      resolvedStatus: node == null
          ? LayoutHttpStatus.notFound
          : LayoutHttpStatus.ok,
    );
  }

  ResolvedVaultNode? findLinkedNode(String? value) {
    final nodes = linkedNodes(value);
    return nodes.isEmpty ? null : resolve(nodes.first);
  }

  List<ResolvedVaultNode> findLinkedNodes(String? value) => [
    for (final node in linkedNodes(value)) resolve(node),
  ];

  static List<VaultNode> linkedNodes(String? value) {
    if (value == null || value.isEmpty) return const [];
    final links = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
    return [
      for (final match in links.allMatches(value))
        if ((match.group(1)?.trim() ?? '') case final path when path.isNotEmpty)
          VaultNode(
            path: path,
            label: switch (match.group(2)?.trim()) {
              final label? when label.isNotEmpty => label,
              _ => null,
            },
          ),
    ];
  }

  Iterable<String> pathSample({int count = 12}) =>
      _nodes.map((node) => node.path).take(count);

  Iterable<String> titleSample({int count = 12}) =>
      _nodes.map((node) => node.title).take(count);

  Node? _findNode(String path) {
    for (final candidate in pathCandidates(path)) {
      final node = _nodesByPath[candidate];
      if (node != null) return node;
    }

    if (isCortexRootPath(path)) {
      for (final node in _nodes) {
        if (_isCortexRootNode(node)) return node;
      }
    }

    return null;
  }

  static String normalizePath(String path) {
    return path
        .trim()
        .replaceAll(r'\', '/')
        .toLowerCase()
        .replaceAll(RegExp(r'/+'), '/')
        .replaceFirst(RegExp(r'\.md$'), '')
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'/+$'), '');
  }

  static Set<String> pathCandidates(String path) {
    final normalized = normalizePath(path);
    if (isCortexRootPath(path)) {
      return const {'', 'cortex', 'cortex/cortex'};
    }
    final segments = normalized.split('/');
    final leaf = segments.isEmpty ? normalized : segments.last;
    return {normalized, '$normalized/$leaf'};
  }

  static bool isCortexRootPath(String path) {
    final normalized = normalizePath(path);
    return normalized.isEmpty || normalized == 'cortex';
  }

  static bool _isCortexRootNode(Node node) {
    final path = normalizePath(node.path);
    final slug = normalizePath(node.slug);
    final title = normalizePath(node.title);
    return path == 'cortex' ||
        path == 'cortex/cortex' ||
        slug == 'cortex' ||
        slug.contains('cortex') ||
        title == 'cortex' ||
        path.endsWith('/cortex');
  }
}
