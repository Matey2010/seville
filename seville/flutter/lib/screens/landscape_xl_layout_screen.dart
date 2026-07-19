import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../components/layout_component_registry.dart';
import '../constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart';
import '../models/landscape_xl_layout.dart';
import '../models/layout.dart';
import '../state/node_store.dart';
import '../utils/common_utilities.dart';
import '../utils/vault_node_resolver.dart';
import '../widgets/landscape_xl_layout_view.dart';

class LandscapeXlLayoutScreen extends ConsumerStatefulWidget {
  const LandscapeXlLayoutScreen({
    this.layout,
    this.componentRegistry = const LayoutComponentRegistry(),
    super.key,
  });

  final LandscapeXlLayout? layout;
  final LayoutComponentRegistry componentRegistry;

  @override
  ConsumerState<LandscapeXlLayoutScreen> createState() =>
      _LandscapeXlLayoutScreenState();
}

class _LandscapeXlLayoutScreenState
    extends ConsumerState<LandscapeXlLayoutScreen> {
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
    final layout = widget.layout ?? lgErgoLayoutConfig;
    final highlightedNodes = ref.watch(highlightedNodesProvider);
    final selectedNodes = ref.watch(selectedNodesProvider);
    final resolverState = ref.watch(vaultNodeResolverProvider);
    final systemInfoState = ref.watch(systemInfoProvider);
    ref.listen(vaultNodeResolverProvider, (_, next) {
      switch (next) {
        case AsyncData(:final value):
          _highlightInitialNodeIfNeeded(value);
        case AsyncError(:final error):
          CommonUtilities.log('[snapshot] load failed: $error');
        case AsyncLoading():
          break;
      }
    });
    ref.listen(systemInfoProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        CommonUtilities.log('[system info] load failed: $error');
      }
    });
    final resolver = switch (resolverState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final systemInfo = switch (systemInfoState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final nodeTrees = <FanLayout, NodeTree>{};
    final selectedNode = selectedNodes.lastOrNull?.node;
    for (final fan in _fanLayouts(layout)) {
      final rootNodeId = fan.resolveRootNodeId(selectedNode: selectedNode);
      if (fan.rootNodePointer != null && rootNodeId == null) continue;
      final request = (
        rootNodeId: rootNodeId,
        depth: fan.maxDepth - 1,
        traverseBy: fan.traverseBy,
      );
      final treeProvider = nodeTreeProvider(request);
      ref.listen(treeProvider, (_, next) {
        if (next case AsyncError(:final error)) {
          CommonUtilities.log(
            '[node tree] load failed for ${fan.label ?? fan.aliases.firstOrNull}: '
            '$error',
          );
        }
      });
      final treeState = ref.watch(treeProvider);
      if (treeState case AsyncData(:final value)) {
        nodeTrees[fan] = value;
      }
    }
    return Scaffold(
      body: LandscapeXlLayoutView(
        layout: layout,
        componentRegistry: widget.componentRegistry,
        vaultNodeResolver: resolver,
        systemInfo: systemInfo,
        nodeTrees: nodeTrees,
        highlightedNodes: highlightedNodes,
        selectedNodes: selectedNodes,
        onLayoutTap: _handleLayoutTap,
      ),
    );
  }

  Iterable<FanLayout> _fanLayouts(Layout layout) sync* {
    for (final child in layout.layouts.values) {
      if (child is FanLayout) yield child;
      yield* _fanLayouts(child);
    }
  }

  void _handleLayoutTap(LayoutTapTarget target) {
    if (target.layout.aliases.contains('clear-selection-action')) {
      ref.read(selectedNodesProvider.notifier).clear();
      CommonUtilities.log('[action panel] cleared selected nodes');
      return;
    }
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

    final treeNode = target.resolvedNode;
    final resolvedTreeNode = treeNode?.node;
    if (treeNode != null && resolvedTreeNode != null) {
      _logResolvedNodeTap(target, treeNode, resolvedTreeNode);
      ref.read(selectedNodesProvider.notifier).toggle(treeNode);
      return;
    }

    final resolverState = ref.read(vaultNodeResolverProvider);
    final resolver = switch (resolverState) {
      AsyncData(:final value) => value,
      _ => null,
    };
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
    ref.read(selectedNodesProvider.notifier).toggle(resolvedNode);
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
