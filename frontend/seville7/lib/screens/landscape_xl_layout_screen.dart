import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../components/layout_component_registry.dart';
import '../constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart';
import '../data/runtime_config.dart';
import '../models/layout/layout.dart';
import '../state/node_store.dart';
import '../state/overlay_store.dart';
import '../state/search_store.dart';
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
  bool _isResolvingPlayerNode = false;
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

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout ?? lgErgoLayoutConfig;
    final layoutSnapshot = ref.watch(layoutSnapshotProvider(layout));
    final highlightedNodes = ref.watch(highlightedNodesProvider);
    final selectedNodes = ref.watch(selectedNodesProvider);
    final searchValue = ref.watch(
      searchStateProvider.select((state) => state.value),
    );
    final findLayoutPath =
        layoutSnapshot.layoutsOfType<FindLayout>().firstOrNull?.path ??
        const <String>[];
    final searchRequest = NodeSearchRequest(
      value: searchValue,
      layoutPath: findLayoutPath,
    );
    final searchState = ref.watch(nodeSearchProvider(searchRequest));
    final vaultNodeLookup = VaultNodeLookupRequest(layoutSnapshot.vaultNodes);
    final resolverProvider = vaultNodeResolverProvider(vaultNodeLookup);
    final resolverState = ref.watch(resolverProvider);
    final systemInfoState = ref.watch(systemInfoProvider);
    ref.listen(resolverProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        CommonUtilities.log('[configured Node lookup] failed: $error');
      }
    });
    ref.listen(systemInfoProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        CommonUtilities.log('[system info] load failed: $error');
      }
    });
    ref.listen(nodeSearchProvider(searchRequest), (_, next) {
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
      AsyncData(:final value) => value,
      _ => const <ResolvedVaultNode>[],
    };
    final nodeTrees = <FanLayout, ResolvedNodeTree>{};
    final selectedNode = selectedNodes.lastOrNull?.node;
    for (final binding in layoutSnapshot.layoutsOfType<FanLayout>()) {
      final fan = binding.layout;
      final rootNodeId = fan.resolveRootNodeId(selectedNode: selectedNode);
      if (fan.rootNodePointer != null && rootNodeId == null) continue;
      final request = NodeTreeRequest(
        layoutPath: binding.path,
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
            '[node tree] load failed for ${fan.caption ?? fan.aliases.firstOrNull}: '
            '$error',
          );
        }
      });
      final treeState = ref.watch(treeProvider);
      if (treeState case AsyncData(:final value)) {
        nodeTrees[fan] = value;
      }
    }
    final nodeLayoutNodes = <NodeLayout, ResolvedVaultNode>{};
    for (final binding in layoutSnapshot.layoutsOfType<NodeLayout>()) {
      final nodeLayout = binding.layout;
      final provider = nodeLayoutProvider(
        NodeLayoutRequest(filter: nodeLayout.filter, layoutPath: binding.path),
      );
      ref.listen(provider, (_, next) {
        if (next case AsyncData(value: null)) {
          ref
              .read(selectedNodesProvider.notifier)
              .storeFallbackNode(
                nodeLayout.fallbackNode,
                layoutPath: binding.path,
              );
        } else if (next case AsyncError(:final error)) {
          CommonUtilities.log(
            '[NodeLayout] lookup failed for ${nodeLayout.aliases.firstOrNull}: $error',
          );
        }
      });
      final state = ref.watch(provider);
      if (state case AsyncData(:final value)) {
        if (value != null) {
          nodeLayoutNodes[nodeLayout] = value;
          continue;
        }
        final slug = nodeLayout.fallbackNode.slug.trim();
        final stored = selectedNodes.where(
          (candidate) => candidate.node?.slug.trim() == slug,
        );
        nodeLayoutNodes[nodeLayout] =
            stored.firstOrNull ??
            _resolvedFallbackNode(nodeLayout.fallbackNode, binding.path);
      }
    }
    return Scaffold(
      body: LandscapeXlLayoutView(
        layout: layout,
        componentRegistry: widget.componentRegistry,
        vaultNodeResolver: resolver,
        systemInfo: systemInfo,
        nodeTrees: nodeTrees,
        nodeLayoutNodes: nodeLayoutNodes,
        queryNodes: queryNodes,
        highlightedNodes: highlightedNodes,
        selectedNodes: selectedNodes,
        onLayoutTap: _handleLayoutTap,
        searchValue: searchValue,
        onSearchSubmitted: _submitSearch,
        onSearchNodeSelected: _selectSearchNode,
        onCreateVirtualNodeSubmitted: (slug, layoutKey) => unawaited(
          _createVirtualNode(_pathFromAddress(layoutKey), requestedSlug: slug),
        ),
        onCancel: _cancelInterface,
        onRefreshFanData: _refreshFanData,
        onCopySelectedNodeSlug: _copySelectedNodeSlug,
        onSubmit: () => unawaited(_submitVirtualNode()),
      ),
    );
  }

  ResolvedVaultNode _resolvedFallbackNode(
    Node fallbackNode,
    List<String> layoutPath,
  ) {
    final node = fallbackNode.deepCopy();
    final slug = node.slug.trim();
    if (!node.labels.contains('Virtual')) node.labels.add('Virtual');
    if (node.path.trim().isEmpty) node.path = slug;
    return ResolvedVaultNode(
      path: node.path,
      node: node,
      resolvedStatus: LayoutHttpStatus.noContent,
      origin: ResolvedNodeOrigin.layout(layoutPath: layoutPath),
      isVirtual: true,
    );
  }

  void _handleLayoutTap(LayoutTapTarget target) {
    if (target.tableAction?.copiesToClipboard ?? false) {
      _copyTextToClipboard(target.textValue ?? '');
      return;
    }
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
      unawaited(_createVirtualNode(_pathFromAddress(target.key)));
      return;
    }
    if (target.layout.aliases.contains('resolve-today-node')) {
      unawaited(_resolveTodayNode(_pathFromAddress(target.key)));
      return;
    }
    if (target.layout.aliases.contains('resolve-player-node')) {
      unawaited(_resolvePlayerNode(_pathFromAddress(target.key)));
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

    final resolvedNode =
        target.resolvedNode ??
        resolver.resolve(component, layoutPath: _pathFromAddress(target.key));
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
    ref.read(searchStateProvider.notifier).submit(value);
    CommonUtilities.log('[interface] submitted Find query');
  }

  void _selectSearchNode(ResolvedVaultNode node) {
    final slug = node.node?.slug.trim() ?? '';
    if (slug.isEmpty) return;
    ref.read(selectedNodesProvider.notifier).toggle(node);
    CommonUtilities.log('[search] selected Node: $slug');
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
    _copyTextToClipboard(slug);
  }

  void _copyTextToClipboard(String text) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      CommonUtilities.log('[interface] no text to copy');
      return;
    }
    unawaited(
      Clipboard.setData(ClipboardData(text: normalizedText)).then(
        (_) {
          CommonUtilities.log('[interface] copied text: $normalizedText');
          if (!mounted) return;
          ref.read(toastProvider.notifier).showCopiedText(normalizedText);
        },
        onError: (Object error, StackTrace stackTrace) {
          CommonUtilities.log('[interface] copy text failed: $error');
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

  Future<void> _createVirtualNode(
    List<String> layoutPath, {
    String? requestedSlug,
  }) async {
    if (_isAddingVirtualNode) return;
    _isAddingVirtualNode = true;
    try {
      final selectedNodes = ref.read(selectedNodesProvider.notifier);
      final explicitSlug = requestedSlug?.trim();
      var slug = explicitSlug == null || explicitSlug.isEmpty
          ? selectedNodes.nextVirtualNodeSlugCandidate()
          : explicitSlug;
      while (true) {
        final selectedDuplicate = ref
            .read(selectedNodesProvider)
            .any((node) => node.node?.slug.trim() == slug);
        final storedDuplicate = await ref.read(
          nodeBySlugProvider(
            NodeBySlugRequest(slug: slug, layoutPath: layoutPath),
          ).future,
        );
        if (!selectedDuplicate && storedDuplicate == null) break;
        if (explicitSlug != null && explicitSlug.isNotEmpty) {
          if (!mounted) return;
          ref
              .read(toastProvider.notifier)
              .show(
                'Node already exists: [[$slug]]',
                type: NotificationType.NOTIFICATION_TYPE_ERROR,
              );
          return;
        }
        slug = selectedNodes.nextVirtualNodeSlugCandidate();
      }
      if (!mounted) return;
      final node = selectedNodes.addVirtualNode(
        slug: slug,
        layoutPath: layoutPath,
      );
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
      ref.invalidate(nodeBySlugProvider);
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

  Future<void> _resolveTodayNode(List<String> layoutPath) async {
    if (_isResolvingTodayNode) return;
    _isResolvingTodayNode = true;
    final now = DateTime.now();
    final slug = [
      now.day.toString().padLeft(2, '0'),
      now.month.toString().padLeft(2, '0'),
      now.year.toString().padLeft(4, '0'),
    ].join('-');
    try {
      final request = NodeBySlugRequest(slug: slug, layoutPath: layoutPath);
      ref.invalidate(nodeBySlugProvider(request));
      final resolvedNode = await ref.read(nodeBySlugProvider(request).future);
      if (!mounted) return;
      final selectedNodes = ref.read(selectedNodesProvider.notifier);
      if (resolvedNode != null) {
        selectedNodes.select(resolvedNode);
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
          layoutPath: layoutPath,
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

  Future<void> _resolvePlayerNode(List<String> layoutPath) async {
    if (_isResolvingPlayerNode) return;
    final slug = sevillePlayerSlug().trim();
    if (slug.isEmpty) {
      CommonUtilities.log('[interface] SEVILLE_PLAYER_SLUG is not configured');
      ref
          .read(toastProvider.notifier)
          .show(
            'Player Node is not configured',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
      return;
    }

    _isResolvingPlayerNode = true;
    try {
      final request = NodeBySlugRequest(slug: slug, layoutPath: layoutPath);
      ref.invalidate(nodeBySlugProvider(request));
      final resolvedNode = await ref.read(nodeBySlugProvider(request).future);
      if (!mounted) return;
      if (resolvedNode == null) {
        CommonUtilities.log('[interface] player Node not found: $slug');
        ref
            .read(toastProvider.notifier)
            .show(
              'Player Node not found: [[$slug]]',
              type: NotificationType.NOTIFICATION_TYPE_WARNING,
            );
        return;
      }

      ref.read(selectedNodesProvider.notifier).select(resolvedNode);
      ref
          .read(toastProvider.notifier)
          .show(
            'Selected: [[$slug]]',
            type: NotificationType.NOTIFICATION_TYPE_INFO,
          );
      CommonUtilities.log('[interface] selected player Node: $slug');
    } catch (error) {
      CommonUtilities.log('[interface] player Node query failed: $error');
      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .show(
            'Player Node lookup failed',
            type: NotificationType.NOTIFICATION_TYPE_ERROR,
          );
    } finally {
      _isResolvingPlayerNode = false;
    }
  }

  void _cancelInterface() {
    ref.read(selectedNodesProvider.notifier).clear();
    ref.read(searchStateProvider.notifier).clear();
    ref.invalidate(nodeSearchProvider);
    CommonUtilities.log(
      '[interface] cancelled selection, virtual Nodes, and search results',
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

  VaultNodeResolver? _currentVaultNodeResolver() {
    final layout = widget.layout ?? lgErgoLayoutConfig;
    final snapshot = ref.read(layoutSnapshotProvider(layout));
    final request = VaultNodeLookupRequest(snapshot.vaultNodes);
    return switch (ref.read(vaultNodeResolverProvider(request))) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }
}

List<String> _pathFromAddress(String address) => [
  for (final segment in address.split('/'))
    if (segment.trim().isNotEmpty) segment.trim(),
];
