import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';
import '../widgets/create_node_dialog.dart';
import '../widgets/node_graph_view.dart';

/// The macOS knowledge workspace, composed entirely from Flutter widgets.
class KnowledgeWorkspace extends ConsumerStatefulWidget {
  const KnowledgeWorkspace({super.key});

  @override
  ConsumerState<KnowledgeWorkspace> createState() => _KnowledgeWorkspaceState();
}

class _KnowledgeWorkspaceState extends ConsumerState<KnowledgeWorkspace> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _submittedSearch = '';
  String _bodyBaseline = '';
  Node? _focusedNode;
  bool _editing = false;
  bool _saving = false;

  bool get _hasUnsavedBody => _editing && _body.text != _bodyBaseline;

  @override
  void dispose() {
    _search.dispose();
    _body.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<bool> _mayLeaveDraft() async {
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

  Future<void> _focusNode(Node node) async {
    if (_focusedNode?.id == node.id) return;
    if (!await _mayLeaveDraft() || !mounted) return;
    setState(() {
      _focusedNode = node;
      _bodyBaseline = node.body;
      _body.text = node.body;
      _editing = false;
    });
  }

  Future<void> _submitSearch(String value) async {
    if (!await _mayLeaveDraft() || !mounted) return;
    final search = value.trim();
    _search.text = search;
    _search.selection = TextSelection.collapsed(offset: search.length);
    setState(() {
      _submittedSearch = search;
      _focusedNode = null;
      _editing = false;
    });
    _searchFocus.unfocus();
  }

  Future<void> _showAll() async {
    if (!await _mayLeaveDraft() || !mounted) return;
    _search.clear();
    _body.clear();
    setState(() {
      _submittedSearch = '';
      _focusedNode = null;
      _editing = false;
    });
  }

  Future<void> _cancelEditOrSelection() async {
    if (_editing) {
      if (!await _mayLeaveDraft() || !mounted) return;
      setState(() {
        _body.text = _bodyBaseline;
        _editing = false;
      });
      return;
    }
    await _showAll();
  }

  Future<void> _openCreate({String suggestedSlug = ''}) async {
    if (!await _mayLeaveDraft() || !mounted) return;
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
    setState(() {
      _submittedSearch = '';
      _focusedNode = created;
      _bodyBaseline = created.body;
      _body.text = created.body;
      _editing = false;
    });
    _message('Node created');
  }

  Future<void> _saveBody() async {
    final node = _focusedNode;
    if (node == null || _saving) return;
    if (!_hasUnsavedBody) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(sevilleApiProvider)
          .updateNodeBody(
            id: node.id,
            body: _body.text,
            expectedUpdateCount: node.updateCount.toInt(),
          );
      if (!mounted) return;
      ref.invalidate(nodeGraphProvider);
      ref.invalidate(nodeSearchProvider);
      setState(() {
        _focusedNode = updated;
        _bodyBaseline = updated.body;
        _body.text = updated.body;
        _editing = false;
      });
      _message('Node body saved');
    } on DioException catch (error) {
      if (!mounted) return;
      _message(
        error.response?.statusCode == 409
            ? 'Node changed elsewhere. Your edit remains open.'
            : 'Could not save Node body.',
      );
    } catch (_) {
      if (mounted) _message('Could not save Node body.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _refresh() {
    ref.invalidate(nodeGraphProvider);
    if (_submittedSearch.isNotEmpty) ref.invalidate(nodeSearchProvider);
  }

  Future<void> _copySlug() async {
    final slug = _focusedNode?.slug;
    if (slug == null || slug.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: slug));
    if (mounted) _message('Copied [[$slug]]');
  }

  void _message(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final request = (
      rootNodeId: _focusedNode?.id,
      search: _focusedNode == null ? _submittedSearch : '',
    );
    final graphState = ref.watch(nodeGraphProvider(request));
    final searchState = _submittedSearch.isEmpty
        ? null
        : ref.watch(nodeSearchProvider(_submittedSearch));
    final graph = switch (graphState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final focused =
        graph?.nodes.where((node) => node.id == _focusedNode?.id).firstOrNull ??
        _focusedNode;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _refresh,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            unawaited(_saveBody()),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            unawaited(_cancelEditOrSelection()),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Seville'),
            actions: [
              IconButton(
                tooltip: 'Show all Nodes',
                onPressed: () => unawaited(_showAll()),
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
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _searchBar(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      if (width < 760) {
                        return Column(
                          children: [
                            Expanded(flex: 3, child: _graphPane(graphState)),
                            SizedBox(
                              height: constraints.maxHeight * 0.42,
                              child: _detailsPane(focused),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          if (width >= 1160)
                            SizedBox(
                              width: 260,
                              child: _nodeList(graphState, searchState),
                            ),
                          Expanded(child: _graphPane(graphState)),
                          SizedBox(
                            width: width >= 1160 ? 360 : 320,
                            child: _detailsPane(focused),
                          ),
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
                      onPressed: () => unawaited(_showAll()),
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
                _focusedNode == null ? 'Global graph' : 'Local graph',
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
          child: switch (graphState) {
            AsyncData(:final value) => NodeGraphView(
              graph: value,
              selectedNodeId: _focusedNode?.id,
              onNodeSelected: (node) => unawaited(_focusNode(node)),
            ),
            AsyncError() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load the Node graph.'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
        if (graphState case AsyncData(value: final graph) when graph.hasMore)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text(
              _focusedNode == null
                  ? 'More Nodes exist. Use Find to narrow the graph.'
                  : 'More nearby Nodes exist. Select a neighbor to explore further.',
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
                        selected: node.id == _focusedNode?.id,
                        title: Text('[[${node.slug}]]', maxLines: 1),
                        subtitle: node.title.trim().isEmpty
                            ? null
                            : Text(node.title, maxLines: 1),
                        onTap: () => unawaited(_focusNode(node)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailsPane(Node? node) => Card(
    margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
    child: node == null
        ? const Center(child: Text('Select a Node to read its body.'))
        : Padding(
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
                    constraints: const BoxConstraints(maxHeight: 110),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final label in node.labels)
                            Chip(label: Text(label)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  children: [
                    Text(
                      'Body',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (!_editing)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _focusedNode = node;
                            _bodyBaseline = node.body;
                            _body.text = node.body;
                            _editing = true;
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
                if (_editing) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => unawaited(_cancelEditOrSelection()),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving
                            ? null
                            : () => unawaited(_saveBody()),
                        child: _saving
                            ? const Text('Saving…')
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
  );
}
