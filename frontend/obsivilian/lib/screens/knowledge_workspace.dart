import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';
import '../widgets/create_node_dialog.dart';
import '../widgets/color_rules_dialog.dart';
import '../widgets/node_graph_view.dart';

/// The macOS knowledge workspace, composed entirely from Flutter widgets.
class KnowledgeWorkspace extends ConsumerStatefulWidget {
  const KnowledgeWorkspace({super.key});

  @override
  ConsumerState<KnowledgeWorkspace> createState() => _KnowledgeWorkspaceState();
}

class _KnowledgeWorkspaceState extends ConsumerState<KnowledgeWorkspace> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _globalGraphKey = GlobalKey(debugLabel: 'globalNodeGraph');
  String _submittedSearch = '';
  bool _graphOnly = false;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _openLocalGraph(Node node) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LocalGraphDialog(initialNode: node),
    );
  }

  Future<void> _openColorRules() async {
    ref.invalidate(nodeColorRulesProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ColorRulesDialog(),
    );
  }

  Future<void> _submitSearch(String value) async {
    final search = value.trim();
    _search.text = search;
    _search.selection = TextSelection.collapsed(offset: search.length);
    setState(() => _submittedSearch = search);
    _searchFocus.unfocus();
  }

  void _showAll() {
    _search.clear();
    setState(() => _submittedSearch = '');
  }

  void _toggleInterface() {
    setState(() => _graphOnly = !_graphOnly);
    if (_graphOnly) _searchFocus.unfocus();
  }

  void _focusSearch() {
    if (_graphOnly) setState(() => _graphOnly = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _handleEscape() {
    if (_graphOnly) {
      _toggleInterface();
    } else {
      _showAll();
    }
  }

  Future<void> _openCreate({String suggestedSlug = ''}) async {
    final api = ref.read(sevilleApiProvider);
    final created = await showDialog<Node>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateNodeDialog(
        suggestedSlug: suggestedSlug,
        createNode: (slug, labels, body) =>
            api.createNode(slug: slug, labels: labels, body: body),
      ),
    );
    if (created == null || !mounted) return;
    ref.invalidate(nodeGraphProvider);
    ref.invalidate(nodeSearchProvider);
    _search.clear();
    setState(() => _submittedSearch = '');
    _message('Node created');
    await _openLocalGraph(created);
  }

  void _refresh() {
    ref.invalidate(nodeGraphProvider);
    ref.invalidate(nodeColorRulesProvider);
    if (_submittedSearch.isNotEmpty) ref.invalidate(nodeSearchProvider);
  }

  void _message(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final request = (rootNodeId: null, search: _submittedSearch);
    final graphState = ref.watch(nodeGraphProvider(request));
    final searchState = _submittedSearch.isEmpty
        ? null
        : ref.watch(nodeSearchProvider(_submittedSearch));
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _refresh,
        const SingleActivator(LogicalKeyboardKey.backslash, meta: true):
            _toggleInterface,
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'color-rules',
            tooltip: 'Node color rules',
            onPressed: () => unawaited(_openColorRules()),
            child: const Icon(Icons.palette_outlined),
          ),
          appBar: _graphOnly
              ? null
              : AppBar(
                  title: const Text('Obsivilian'),
                  actions: [
                    IconButton(
                      tooltip: 'Show all Nodes',
                      onPressed: _showAll,
                      icon: const Icon(Icons.hub_outlined),
                    ),
                    IconButton(
                      tooltip: 'Refresh graph',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: 'Create Node',
                      onPressed: () => unawaited(_openCreate()),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Show graph only',
                      onPressed: _toggleInterface,
                      icon: const Icon(Icons.fullscreen),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
          body: _graphOnly
              ? _expandedGraph(graphState)
              : SafeArea(
                  child: Column(
                    children: [
                      _searchBar(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            if (width < 620) {
                              return _graphPane(graphState);
                            }
                            return Row(
                              children: [
                                SizedBox(
                                  width: width >= 1160 ? 260 : 220,
                                  child: _nodeList(graphState, searchState),
                                ),
                                Expanded(child: _graphPane(graphState)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _expandedGraph(AsyncValue<NodeGraph> graphState) => Stack(
    children: [
      Positioned.fill(
        child: _GraphContent(
          graphState: graphState,
          graphKey: _globalGraphKey,
          selectedNodeId: null,
          onNodeSelected: (node) => unawaited(_openLocalGraph(node)),
          onRetry: _refresh,
          moreMessage: 'More Nodes exist. Use Find to narrow the graph.',
          overlayMoreMessage: true,
        ),
      ),
      Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 12,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          elevation: 4,
          child: IconButton(
            tooltip: 'Show interface',
            onPressed: _toggleInterface,
            icon: const Icon(Icons.fullscreen_exit),
          ),
        ),
      ),
    ],
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            maxLength: 256,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => unawaited(_submitSearch(value)),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Find Nodes by slug, title, label, or tag',
              border: const OutlineInputBorder(),
              isDense: true,
              counterText: '',
              suffixIcon: _submittedSearch.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _showAll,
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => unawaited(_submitSearch(_search.text)),
          child: const Text('Find'),
        ),
      ],
    ),
  );

  Widget _graphPane(AsyncValue<NodeGraph> graphState) => Card(
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.hardEdge,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(
                'Global graph',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (graphState case AsyncData(:final value))
                Text('${value.nodes.length} Nodes'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _GraphContent(
            graphState: graphState,
            graphKey: _globalGraphKey,
            selectedNodeId: null,
            onNodeSelected: (node) => unawaited(_openLocalGraph(node)),
            onRetry: _refresh,
            moreMessage: 'More Nodes exist. Use Find to narrow the graph.',
          ),
        ),
      ],
    ),
  );

  Widget _nodeList(
    AsyncValue<NodeGraph> graphState,
    AsyncValue<NodeSearchResult>? searchState,
  ) {
    final graphNodes = switch (graphState) {
      AsyncData(:final value) => value.nodes,
      _ => <Node>[],
    };
    final nodes = switch (searchState) {
      AsyncData(:final value) when value.nodes.isNotEmpty => value.nodes,
      _ => graphNodes,
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _submittedSearch.isEmpty ? 'Nodes' : 'Search results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: nodes.isEmpty
                ? Center(
                    child: switch (searchState) {
                      AsyncLoading() => const CircularProgressIndicator(),
                      AsyncError() => const Text('Search failed.'),
                      _ when _submittedSearch.isNotEmpty => TextButton(
                        onPressed: () => unawaited(
                          _openCreate(suggestedSlug: _submittedSearch),
                        ),
                        child: Text('Create [[$_submittedSearch]]'),
                      ),
                      _ => const Text('No Nodes yet.'),
                    },
                  )
                : ListView.builder(
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return ListTile(
                        dense: true,
                        title: Text('[[${node.slug}]]', maxLines: 1),
                        subtitle: node.title.trim().isEmpty
                            ? null
                            : Text(node.title, maxLines: 1),
                        onTap: () => unawaited(_openLocalGraph(node)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocalGraphDialog extends ConsumerStatefulWidget {
  const _LocalGraphDialog({required this.initialNode});

  final Node initialNode;

  @override
  ConsumerState<_LocalGraphDialog> createState() => _LocalGraphDialogState();
}

class _LocalGraphDialogState extends ConsumerState<_LocalGraphDialog> {
  final TextEditingController _body = TextEditingController();
  late Node _root;
  late String _bodyBaseline;
  bool _editing = false;
  bool _saving = false;
  String? _feedback;
  bool _feedbackIsError = false;

  bool get _hasUnsavedBody => _editing && _body.text != _bodyBaseline;

  @override
  void initState() {
    super.initState();
    _root = widget.initialNode;
    _bodyBaseline = _root.body;
    _body.text = _root.body;
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<bool> _mayLeaveDraft() async {
    if (_saving) return false;
    if (!_hasUnsavedBody) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard body changes?'),
            content: const Text(
              'The current Markdown edit has not been saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _selectNode(Node node) async {
    if (node.id == _root.id) return;
    if (!await _mayLeaveDraft() || !mounted) return;
    setState(() {
      _root = node;
      _bodyBaseline = node.body;
      _body.text = node.body;
      _editing = false;
      _feedback = null;
    });
  }

  Future<void> _close() async {
    if (!await _mayLeaveDraft() || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _cancelEdit() async {
    if (!await _mayLeaveDraft() || !mounted) return;
    setState(() {
      _body.text = _bodyBaseline;
      _editing = false;
      _feedback = null;
    });
  }

  Future<void> _saveBody() async {
    if (_saving) return;
    if (!_hasUnsavedBody) {
      setState(() => _editing = false);
      return;
    }
    setState(() {
      _saving = true;
      _feedback = null;
    });
    try {
      final updated = await ref
          .read(sevilleApiProvider)
          .updateNodeBody(
            id: _root.id,
            body: _body.text,
            expectedUpdateCount: _root.updateCount.toInt(),
          );
      if (!mounted) return;
      ref.invalidate(nodeGraphProvider);
      ref.invalidate(nodeSearchProvider);
      setState(() {
        _root = updated;
        _bodyBaseline = updated.body;
        _body.text = updated.body;
        _editing = false;
        _feedback = 'Node body saved';
        _feedbackIsError = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _feedback = error.response?.statusCode == 409
            ? 'Node changed elsewhere. Your edit remains open.'
            : 'Could not save Node body.';
        _feedbackIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedback = 'Could not save Node body.';
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copySlug() async {
    final slug = _root.slug;
    if (slug.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: slug));
    if (mounted) {
      setState(() {
        _feedback = 'Copied [[$slug]]';
        _feedbackIsError = false;
      });
    }
  }

  Widget _localGraphPane(
    AsyncValue<NodeGraph> graphState,
    NodeGraphRequest request,
  ) => Card(
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.hardEdge,
    child: _GraphContent(
      graphState: graphState,
      selectedNodeId: _root.id,
      onNodeSelected: (node) => unawaited(_selectNode(node)),
      onRetry: () => ref.invalidate(nodeGraphProvider(request)),
      moreMessage:
          'More nearby Nodes exist. Select a neighbor to explore further.',
    ),
  );

  Widget _detailsPane(Node node) => Card(
    margin: const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.title.trim().isEmpty ? node.slug : node.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Copy slug',
                onPressed: () => unawaited(_copySlug()),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          Text(
            '[[${node.slug}]]',
            style: const TextStyle(color: Color(0xFFFFD54F)),
          ),
          if (node.labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 56),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final label in node.labels) Chip(label: Text(label)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          Row(
            children: [
              Text('Body', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (!_editing)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _root = node;
                      _bodyBaseline = node.body;
                      _body.text = node.body;
                      _editing = true;
                      _feedback = null;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _body,
                    enabled: !_saving,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Markdown body',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  )
                : SelectionArea(
                    child: SingleChildScrollView(
                      child: Text(
                        node.body.isEmpty
                            ? 'This Node has no body.'
                            : node.body,
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ),
          ),
          if (_feedback case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: _feedbackIsError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (_editing) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => unawaited(_cancelEdit()),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : () => unawaited(_saveBody()),
                  child: _saving ? const Text('Saving…') : const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final request = (rootNodeId: _root.id, search: '');
    final graphState = ref.watch(nodeGraphProvider(request));
    final node = switch (graphState) {
      AsyncData(:final value) =>
        value.nodes.where((node) => node.id == _root.id).firstOrNull ?? _root,
      _ => _root,
    };
    final size = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            unawaited(_saveBody()),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            unawaited(_editing ? _cancelEdit() : _close()),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_close());
          },
          child: Dialog(
            insetPadding: const EdgeInsets.all(12),
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: math.min(size.width - 24, 1100),
              height: math.min(size.height - 24, 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to global graph',
                          onPressed: _saving ? null : () => unawaited(_close()),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Local graph · [[${_root.slug}]]',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (graphState case AsyncData(:final value))
                          Text('${value.nodes.length} Nodes'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final details = _detailsPane(node);
                        final graph = _localGraphPane(graphState, request);
                        return Row(
                          children: [
                            SizedBox(
                              width: math.min(constraints.maxWidth * 0.42, 440),
                              child: details,
                            ),
                            Expanded(child: graph),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphContent extends ConsumerWidget {
  const _GraphContent({
    required this.graphState,
    required this.selectedNodeId,
    required this.onNodeSelected,
    required this.onRetry,
    required this.moreMessage,
    this.graphKey,
    this.overlayMoreMessage = false,
  });

  final AsyncValue<NodeGraph> graphState;
  final String? selectedNodeId;
  final ValueChanged<Node> onNodeSelected;
  final VoidCallback onRetry;
  final String moreMessage;
  final Key? graphKey;
  final bool overlayMoreMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesState = ref.watch(nodeColorRulesProvider);
    final colorRules = switch (rulesState) {
      AsyncData(:final value) => value.rules,
      _ => <NodeColorRule>[],
    };
    final graph = switch (graphState) {
      AsyncData(:final value) => NodeGraphView(
        key: graphKey,
        graph: value,
        colorRules: colorRules,
        selectedNodeId: selectedNodeId,
        onNodeSelected: onNodeSelected,
      ),
      AsyncError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load the Node graph.'),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
    final hasMore = switch (graphState) {
      AsyncData(value: final value) => value.hasMore,
      _ => false,
    };
    if (overlayMoreMessage) {
      return Stack(
        children: [
          Positioned.fill(child: graph),
          if (hasMore)
            Positioned(
              left: 12,
              bottom: 12,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(moreMessage),
                ),
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: graph),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text(moreMessage),
          ),
      ],
    );
  }
}
