import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../components/layout_component_registry.dart';
import '../constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart';
import '../models/landscape_xl_layout.dart';
import '../models/layout.dart';
import '../state/node_store.dart';
import '../state/overlay_store.dart';
import '../utils/common_utilities.dart';
import '../utils/vault_node_resolver.dart';
import '../widgets/landscape_xl_layout_view.dart';
import '../widgets/toast_widget.dart';

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
  bool _isAddingVirtualNode = false;
  bool _isCreatingVirtualNode = false;
  bool _isResolvingTodayNode = false;
  final ToastOverlayPresenter _toastPresenter = ToastOverlayPresenter();
  late final ProviderSubscription<List<ToastEvent>> _toastSubscription;

  @override
  void initState() {
    super.initState();
    _toastSubscription = ref.listenManual(toastProvider, (_, next) {
      _toastPresenter.sync(
        context,
        next,
        dismiss: (id) {
          if (mounted) ref.read(toastProvider.notifier).dismiss(id);
        },
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _toastSubscription.close();
    _toastPresenter.dispose();
    super.dispose();
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
    final layout = widget.layout ?? lgErgoLayoutConfig;
    final highlightedNodes = ref.watch(highlightedNodesProvider);
    final selectedNodes = ref.watch(selectedNodesProvider);
    final searchValue = ref.watch(
      interfaceOverlayStateProvider.select((state) => state.searchValue),
    );
    final searchState = ref.watch(nodeSearchProvider(searchValue));
    final vaultNodeLookup = VaultNodeLookupRequest(
      _configuredVaultNodes(layout).map((node) => node.path),
    );
    final resolverProvider = vaultNodeResolverProvider(vaultNodeLookup);
    final resolverState = ref.watch(resolverProvider);
    final systemInfoState = ref.watch(systemInfoProvider);
    ref.listen(resolverProvider, (_, next) {
      switch (next) {
        case AsyncData(:final value):
          _highlightInitialNodeIfNeeded(value);
        case AsyncError(:final error):
          CommonUtilities.log('[configured Node lookup] failed: $error');
        case AsyncLoading():
          break;
      }
    });
    ref.listen(systemInfoProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        CommonUtilities.log('[system info] load failed: $error');
      }
    });
    ref.listen(nodeSearchProvider(searchValue), (_, next) {
      if (next case AsyncError(:final error)) {
        CommonUtilities.log('[node search] failed: $error');
        ref
            .read(toastProvider.notifier)
            .show(
              'Node search failed',
              type: NotificationType.NOTIFICATION_TYPE_ERROR,
            );
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
    final queryNodes = switch (searchState) {
      AsyncData(:final value) => [
        for (final node in value.nodes)
          ResolvedVaultNode(
            path: node.path.trim().isEmpty ? node.slug : node.path,
            node: node,
            resolvedStatus: LayoutHttpStatus.ok,
          ),
      ],
      _ => const <ResolvedVaultNode>[],
    };
    final nodeTrees = <FanLayout, NodeTree>{};
    final selectedNode = selectedNodes.lastOrNull?.node;
    for (final fan in _fanLayouts(layout)) {
      final rootNodeId = fan.resolveRootNodeId(selectedNode: selectedNode);
      if (fan.rootNodePointer != null && rootNodeId == null) continue;
      final request = NodeTreeRequest(
        rootNodeId: rootNodeId,
        rootNodeFilter: fan.rootNodeFilter,
        depth: fan.maxDepth - 1,
        traverseBy: fan.traverseBy,
        nodeFilter: fan.nodeFilter,
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
        queryNodes: queryNodes,
        highlightedNodes: highlightedNodes,
        selectedNodes: selectedNodes,
        onLayoutTap: _handleLayoutTap,
        searchValue: searchValue,
        onSearchSubmitted: _submitSearch,
        onCancel: _cancelInterface,
        onRefreshFanData: _refreshFanData,
        onCopySelectedNodeSlug: _copySelectedNodeSlug,
        onSubmit: () => unawaited(_submitVirtualNode()),
      ),
    );
  }

  Iterable<FanLayout> _fanLayouts(Layout layout) sync* {
    for (final child in layout.layouts.values) {
      if (child is FanLayout) yield child;
      yield* _fanLayouts(child);
    }
  }

  Iterable<VaultNodeUiComponent> _configuredVaultNodes(Layout layout) sync* {
    if (layout case LandscapeXlLayout(:final initialHighlightedNode?)) {
      yield initialHighlightedNode;
    }
    if (layout case PerspectiveGridArea(:final node?)) yield node;
    if (layout case PlaneLayout(:final node?)) yield node;
    for (final child in layout.layouts.values) {
      yield* _configuredVaultNodes(child);
    }
  }

  void _handleLayoutTap(LayoutTapTarget target) {
    if (target.layout.aliases.contains('selected-node-action') &&
        ref.read(selectedNodesProvider).isEmpty) {
      _showNoNodeSelected();
      return;
    }
    if (target.layout.aliases.contains('refresh-fan-data')) {
      _refreshFanData();
      return;
    }
    if (target.layout.aliases.contains('copy-selected-node-slug')) {
      _copySelectedNodeSlug();
      return;
    }
    if (target.layout.aliases.contains('create-virtual-node')) {
      unawaited(_createVirtualNode());
      return;
    }
    if (target.layout.aliases.contains('resolve-today-node')) {
      unawaited(_resolveTodayNode());
      return;
    }
    if (target.layout.aliases.contains('create-first-virtual-node')) {
      unawaited(_submitVirtualNode());
      return;
    }
    if (target.layout.aliases.contains('cancel-interface-action') ||
        target.layout.aliases.contains('clear-selection-action')) {
      _cancelInterface();
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

    final resolver = _currentVaultNodeResolver();
    if (resolver == null) {
      CommonUtilities.log(
        '[layout tap] ${target.key}: configured Node lookup is not loaded yet; cannot resolve "${component.path}"',
      );
      return;
    }

    final resolvedNode = target.resolvedNode ?? resolver.resolve(component);
    final resolvedGraphNode = resolvedNode.node;
    if (resolvedGraphNode == null) {
      if (resolver.isEmpty) {
        CommonUtilities.log(
          '[layout tap] ${target.key}: configured Node lookup is empty; cannot resolve "${component.path}"',
        );
        return;
      }
      CommonUtilities.log(
        '[layout tap] ${target.key}: node "${component.path}" was not resolved',
      );
      CommonUtilities.log(
        'candidate paths: ${VaultNodeResolver.pathCandidates(component.path)}',
      );
      CommonUtilities.log('resolved paths sample: ${resolver.pathSample()}');
      CommonUtilities.log('resolved titles sample: ${resolver.titleSample()}');
      return;
    }

    _logResolvedNodeTap(target, resolvedNode, resolvedGraphNode);
    ref.read(selectedNodesProvider.notifier).toggle(resolvedNode);
  }

  void _submitSearch(String value) {
    ref.read(interfaceOverlayStateProvider.notifier).submitSearch(value);
    CommonUtilities.log('[interface] submitted Search HUD query');
  }

  void _refreshFanData() {
    ref.invalidate(nodeTreeProvider);
    CommonUtilities.log('[interface] refreshed Fan data');
  }

  void _copySelectedNodeSlug() {
    final slug = ref.read(selectedNodesProvider).lastOrNull?.node?.slug.trim();
    if (slug == null || slug.isEmpty) {
      CommonUtilities.log('[interface] no selected Node slug to copy');
      _showNoNodeSelected();
      return;
    }
    unawaited(
      Clipboard.setData(ClipboardData(text: slug)).then(
        (_) {
          CommonUtilities.log('[interface] copied Node slug: $slug');
          if (!mounted) return;
          ref.read(toastProvider.notifier).showCopiedText(slug);
        },
        onError: (Object error, StackTrace stackTrace) {
          CommonUtilities.log('[interface] copy Node slug failed: $error');
        },
      ),
    );
  }

  void _showNoNodeSelected() {
    CommonUtilities.log('[interface] selected Node action has no selection');
    ref
        .read(toastProvider.notifier)
        .show(
          '🔴 No Node Selected',
          type: NotificationType.NOTIFICATION_TYPE_ERROR,
        );
  }

  Future<void> _createVirtualNode() async {
    if (_isAddingVirtualNode) return;
    _isAddingVirtualNode = true;
    try {
      final selectedNodes = ref.read(selectedNodesProvider.notifier);
      var slug = selectedNodes.nextVirtualNodeSlugCandidate();
      while (await ref.read(nodeBySlugProvider(slug).future) != null) {
        slug = selectedNodes.nextVirtualNodeSlugCandidate();
      }
      if (!mounted) return;
      final node = selectedNodes.addVirtualNode(slug: slug);
      CommonUtilities.log(
        '[interface] created virtual Node: ${node.node?.slug}',
      );
    } catch (error) {
      CommonUtilities.log('[interface] virtual Node lookup failed: $error');
      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .show(
            'Could not create virtual Node',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
    } finally {
      _isAddingVirtualNode = false;
    }
  }

  Future<void> _submitVirtualNode() async {
    if (_isCreatingVirtualNode) return;
    final selectedNodes = ref.read(selectedNodesProvider.notifier);
    final virtualNode = selectedNodes.firstVirtualNode;
    final slug = virtualNode?.node?.slug.trim();
    if (virtualNode == null || slug == null || slug.isEmpty) {
      CommonUtilities.log('[interface] no virtual Node to create');
      ref
          .read(toastProvider.notifier)
          .show(
            'No Virtual Node',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
      return;
    }

    _isCreatingVirtualNode = true;
    try {
      final createdNode = await ref
          .read(sevilleApiProvider)
          .createNode(slug: slug, labels: const ['New', 'Virtual']);
      if (!mounted) return;
      final replaced = ref
          .read(selectedNodesProvider.notifier)
          .replaceVirtualNode(virtualNode, createdNode);
      ref.invalidate(nodeBySlugProvider(slug));
      ref.invalidate(systemInfoProvider);
      ref.invalidate(nodeSearchProvider);
      if (!replaced) {
        CommonUtilities.log(
          '[interface] created Node $slug after its virtual selection was removed',
        );
        return;
      }
      CommonUtilities.log('[interface] created canonical Node: $slug');
      ref
          .read(toastProvider.notifier)
          .show(
            'Created: [[$slug]]',
            type: NotificationType.NOTIFICATION_TYPE_SUCCESS,
          );
    } catch (error) {
      CommonUtilities.log('[interface] create Node failed: $error');
      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .show(
            'Node creation failed',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
    } finally {
      _isCreatingVirtualNode = false;
    }
  }

  Future<void> _resolveTodayNode() async {
    if (_isResolvingTodayNode) return;
    _isResolvingTodayNode = true;
    final now = DateTime.now();
    final slug = [
      now.day.toString().padLeft(2, '0'),
      now.month.toString().padLeft(2, '0'),
      now.year.toString().padLeft(4, '0'),
    ].join('-');
    try {
      ref.invalidate(nodeBySlugProvider(slug));
      final node = await ref.read(nodeBySlugProvider(slug).future);
      if (!mounted) return;
      final selectedNodes = ref.read(selectedNodesProvider.notifier);
      if (node != null) {
        selectedNodes.select(
          ResolvedVaultNode(
            path: node.path.trim().isEmpty ? node.slug : node.path,
            node: node,
            resolvedStatus: LayoutHttpStatus.ok,
          ),
        );
        ref
            .read(toastProvider.notifier)
            .show(
              'Selected: [[$slug]]',
              type: NotificationType.NOTIFICATION_TYPE_INFO,
            );
        CommonUtilities.log('[interface] selected today Node: $slug');
        return;
      }
      final alreadySelected = ref
          .read(selectedNodesProvider)
          .any((node) => node.node?.slug.trim() == slug);
      if (!alreadySelected) {
        selectedNodes.addVirtualNode(
          slug: slug,
          labels: const ['Calendar', 'Date', 'Day'],
        );
      }
      ref
          .read(toastProvider.notifier)
          .show(
            'Virtual: [[$slug]]',
            type: NotificationType.NOTIFICATION_TYPE_WARNING,
          );
      CommonUtilities.log('[interface] created virtual today Node: $slug');
    } catch (error) {
      CommonUtilities.log('[interface] today Node query failed: $error');
      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .show(
            'Today Node lookup failed',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
    } finally {
      _isResolvingTodayNode = false;
    }
  }

  void _cancelInterface() {
    ref.read(selectedNodesProvider.notifier).clear();
    ref.read(interfaceOverlayStateProvider.notifier).cancel();
    ref.invalidate(nodeSearchProvider);
    CommonUtilities.log(
      '[interface] cancelled selection, virtual Nodes, search results, and overlays',
    );
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

  VaultNodeResolver? _currentVaultNodeResolver() {
    final layout = widget.layout ?? lgErgoLayoutConfig;
    final request = VaultNodeLookupRequest(
      _configuredVaultNodes(layout).map((node) => node.path),
    );
    return switch (ref.read(vaultNodeResolverProvider(request))) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }
}
