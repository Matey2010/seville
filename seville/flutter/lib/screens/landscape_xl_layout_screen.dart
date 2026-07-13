import 'dart:async';

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

  Future<VaultNodeResolver> _loadVaultNodeResolver({
    bool rescan = false,
  }) async {
    if (rescan) {
      await _api.rescan();
    }
    final snapshot = await _api.snapshot();
    return VaultNodeResolver.fromNotes(snapshot.notes);
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
    final node = target.node;
    if (node == null) {
      CommonUtilities.log('[layout tap] ${target.key}: no node path');
      return;
    }

    final resolver = _vaultNodeResolver;
    if (resolver == null) {
      CommonUtilities.log(
        '[layout tap] ${target.key}: snapshot is not loaded yet; cannot resolve "${node.path}"',
      );
      return;
    }

    final resolvedNode = target.resolvedNode ?? resolver.resolve(node);
    final note = resolvedNode.note;
    if (note == null) {
      if (resolver.isEmpty) {
        CommonUtilities.log(
          '[layout tap] ${target.key}: snapshot is empty; cannot resolve "${node.path}"',
        );
        return;
      }
      CommonUtilities.log(
        '[layout tap] ${target.key}: node "${node.path}" was not resolved',
      );
      CommonUtilities.log(
        'candidate paths: ${VaultNodeResolver.pathCandidates(node.path)}',
      );
      CommonUtilities.log('snapshot paths sample: ${resolver.pathSample()}');
      CommonUtilities.log('snapshot titles sample: ${resolver.titleSample()}');
      CommonUtilities.log('[layout tap] ${target.key}: refetching snapshot…');
      unawaited(_refetchAndRetryNodeTap(target, node));
      return;
    }

    _logResolvedNodeTap(target, resolvedNode, note);
    ref.read(selectedNodesProvider.notifier).select(resolvedNode);
  }

  Future<void> _refetchAndRetryNodeTap(
    LayoutTapTarget target,
    VaultNodeUiComponent node,
  ) async {
    try {
      final resolver = await _loadVaultNodeResolver(rescan: true);
      if (!mounted) return;
      setState(() {
        _vaultNodeResolver = resolver;
      });
      _highlightInitialNodeIfNeeded(resolver);

      final resolvedNode = resolver.resolve(node);
      final note = resolvedNode.note;
      if (note == null) {
        CommonUtilities.log(
          '[layout tap] ${target.key}: still unresolved after rescan: "${node.path}"',
        );
        CommonUtilities.log(
          'candidate paths: ${VaultNodeResolver.pathCandidates(node.path)}',
        );
        CommonUtilities.log('snapshot paths sample: ${resolver.pathSample()}');
        CommonUtilities.log(
          'snapshot titles sample: ${resolver.titleSample()}',
        );
        return;
      }

      CommonUtilities.log('[layout tap] ${target.key}: resolved after rescan');
      _logResolvedNodeTap(target, resolvedNode, note);
      ref.read(selectedNodesProvider.notifier).select(resolvedNode);
    } catch (error) {
      CommonUtilities.log(
        '[layout tap] ${target.key}: rescan/refetch failed: $error',
      );
    }
  }

  void _logResolvedNodeTap(
    LayoutTapTarget target,
    ResolvedVaultNode resolvedNode,
    Note note,
  ) {
    CommonUtilities.log('[layout tap] ${target.key}: ${note.title}');
    CommonUtilities.log('node: ${resolvedNode.path}');
    CommonUtilities.log('path: ${note.path}');

    if (note.frontmatter.isEmpty) {
      CommonUtilities.log('frontmatter: <empty>');
      return;
    }

    CommonUtilities.log('frontmatter:');
    for (final entry in note.frontmatter.entries) {
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
