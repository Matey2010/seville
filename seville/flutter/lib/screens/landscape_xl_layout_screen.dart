import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart';
import '../data/seville_api.dart';
import '../models/landscape_xl_layout.dart';
import '../models/layout.dart';
import '../state/node_store.dart';
import '../utils/common_utilities.dart';
import '../utils/vault_node_resolver.dart';
import '../widgets/landscape_xl_layout_view.dart';
import '../widgets/layout_renderer_registry.dart';

class LandscapeXlLayoutScreen extends ConsumerStatefulWidget {
  const LandscapeXlLayoutScreen({
    this.layout,
    this.rendererRegistry = const LayoutRendererRegistry(),
    super.key,
  });

  final LandscapeXlLayout? layout;
  final LayoutRendererRegistry rendererRegistry;

  @override
  ConsumerState<LandscapeXlLayoutScreen> createState() =>
      _LandscapeXlLayoutScreenState();
}

class _LandscapeXlLayoutScreenState
    extends ConsumerState<LandscapeXlLayoutScreen> {
  final SevilleApi _api = SevilleApi();
  VaultNodeResolver? _vaultNodeResolver;

  @override
  void initState() {
    super.initState();
    _loadNodePaths();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadNodePaths() async {
    try {
      final resolver = await _loadVaultNodeResolver();
      if (!mounted) return;
      setState(() {
        _vaultNodeResolver = resolver;
      });
      _highlightInitialNodeIfNeeded(resolver);
    } catch (error) {
      CommonUtilities.log('[snapshot] load failed: $error');
      // Keep status unresolved when the backend is unavailable. A failed
      // snapshot request must not visually turn every configured node into 404.
    }
  }

  Future<VaultNodeResolver> _loadVaultNodeResolver() async {
    final snapshot = await _api.snapshot();
    return VaultNodeResolver.fromNodes(snapshot.nodes);
  }

  ResolvedVaultNode? _resolveInitialHighlightedNode(
    VaultNodeResolver resolver,
  ) {
    final node = (widget.layout ?? lgErgoLayoutConfig).initialHighlightedNode;
    if (node == null) return null;
    final resolvedNode = resolver.resolve(node);
    return resolvedNode.found ? resolvedNode : null;
  }

  @override
  Widget build(BuildContext context) {
    final highlightedNodes = ref.watch(highlightedNodesProvider);
    final selectedNodes = ref.watch(selectedNodesProvider);
    return Scaffold(
      body: LandscapeXlLayoutView(
        layout: widget.layout ?? lgErgoLayoutConfig,
        vaultNodeResolver: _vaultNodeResolver,
        highlightedNodes: highlightedNodes,
        selectedNodes: selectedNodes,
        onLayoutTap: _handleLayoutTap,
        contentBuilder: widget.rendererRegistry.build,
      ),
    );
  }

  void _handleLayoutTap(LayoutTapTarget target) {
    if (target.layout is PanelLayout &&
        target.layout.aliases.contains('action-button')) {
      CommonUtilities.log(
        '[action panel] ${target.label ?? target.key} button pressed',
      );
      return;
    }

    final component = target.node;
    if (component == null) {
      CommonUtilities.log('[layout tap] ${target.key}: no node path');
      return;
    }

    final resolver = _vaultNodeResolver;
    if (resolver == null) {
      CommonUtilities.log(
        '[layout tap] ${target.key}: snapshot is not loaded yet; cannot resolve "${component.path}"',
      );
      return;
    }

    final resolvedNode = target.resolvedNode ?? resolver.resolve(component);
    final resolvedGraphNode = resolvedNode.node;
    if (resolvedGraphNode == null) {
      if (resolver.isEmpty) {
        CommonUtilities.log(
          '[layout tap] ${target.key}: snapshot is empty; cannot resolve "${component.path}"',
        );
        return;
      }
      CommonUtilities.log(
        '[layout tap] ${target.key}: node "${component.path}" was not resolved',
      );
      CommonUtilities.log(
        'candidate paths: ${VaultNodeResolver.pathCandidates(component.path)}',
      );
      CommonUtilities.log('snapshot paths sample: ${resolver.pathSample()}');
      CommonUtilities.log('snapshot titles sample: ${resolver.titleSample()}');
      return;
    }

    _logResolvedNodeTap(target, resolvedNode, resolvedGraphNode);
    ref.read(selectedNodesProvider.notifier).select(resolvedNode);
  }

  void _logResolvedNodeTap(
    LayoutTapTarget target,
    ResolvedVaultNode resolvedNode,
    Node node,
  ) {
    CommonUtilities.log('[layout tap] ${target.key}: ${node.title}');
    CommonUtilities.log('node: ${resolvedNode.path}');
    CommonUtilities.log('path: ${node.path}');

    if (node.frontmatter.isEmpty) {
      CommonUtilities.log('frontmatter: <empty>');
      return;
    }

    CommonUtilities.log('frontmatter:');
    for (final entry in node.frontmatter.entries) {
      CommonUtilities.log('- ${entry.key}: ${entry.value}');
    }
  }

  void _highlightInitialNodeIfNeeded(VaultNodeResolver resolver) {
    if (ref.read(highlightedNodesProvider).isNotEmpty) return;
    final resolvedNode = _resolveInitialHighlightedNode(resolver);
    if (resolvedNode == null) return;
    ref.read(highlightedNodesProvider.notifier).setNodes([resolvedNode]);
  }
}
