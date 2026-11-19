import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';
import '../domain/node_color_rules.dart';
import '../widgets/create_node_dialog.dart';
import '../widgets/color_rules_dialog.dart';
import '../widgets/labels_dialog.dart';
import '../widgets/node_graph_view.dart';
import '../widgets/node_temporal_dialog.dart';

enum _SidebarView { hidden, nodes }

/// The macOS knowledge workspace, composed entirely from Flutter widgets.
class KnowledgeWorkspace extends ConsumerStatefulWidget {
  const KnowledgeWorkspace({super.key});

  @override
  ConsumerState<KnowledgeWorkspace> createState() => _KnowledgeWorkspaceState();
}

class _KnowledgeWorkspaceState extends ConsumerState<KnowledgeWorkspace> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _workspaceFocus = FocusNode(debugLabel: 'workspace');
  final GlobalKey _canvasKey = GlobalKey(debugLabel: 'graphCanvas');
  final GlobalKey<_NodeDetailsPopupState> _detailsKey = GlobalKey();
  String _submittedSearch = '';
  int _graphViewEpoch = 0;
  bool _findOpen = false;
  _SidebarView _sidebarView = _SidebarView.hidden;
  Node? _focusedNode;
  Offset? _popupAnchor;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _workspaceFocus.dispose();
    super.dispose();
  }

  Future<bool> _focusNode(
    Node node, {
    bool checkDraft = true,
    Offset? globalAnchor,
  }) async {
    if (checkDraft && _focusedNode != null) {
      final details = _detailsKey.currentState;
      if (details != null && !await details.selectNode(node)) return false;
    }
    if (!mounted) return false;
    final canvas = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    setState(() {
      _focusedNode = node;
      _popupAnchor = globalAnchor == null
          ? null
          : canvas?.globalToLocal(globalAnchor);
      _sidebarView = _SidebarView.hidden;
    });
    return true;
  }

  Future<void> _closePopup() async {
    if (_focusedNode != null &&
        !await (_detailsKey.currentState?.mayLeaveDraft() ??
            Future.value(true))) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _focusedNode = null;
      _popupAnchor = null;
    });
  }

  void _closeSidebar() => setState(() => _sidebarView = _SidebarView.hidden);

  void _toggleSidebar() => unawaited(_toggleSidebarAsync());

  Future<void> _toggleSidebarAsync() async {
    if (_sidebarView == _SidebarView.nodes) {
      _closeSidebar();
      return;
    }
    if (_focusedNode != null &&
        !await (_detailsKey.currentState?.mayLeaveDraft() ??
            Future.value(true))) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _focusedNode = null;
      _popupAnchor = null;
      _sidebarView = _SidebarView.nodes;
    });
  }

  Future<void> _openColorRules() async {
    ref.invalidate(nodeColorRulesProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ColorRulesDialog(),
    );
  }

  Future<void> _openLabels() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          LabelsManagerDialog(openColorRules: _openColorRules),
    );
  }

  Future<void> _submitSearch(String value) async {
    final search = value.trim();
    _search.text = search;
    _search.selection = TextSelection.collapsed(offset: search.length);
    setState(() => _submittedSearch = search);
  }

  void _showAll() => unawaited(_showAllAsync());

  Future<void> _showAllAsync() async {
    if (_focusedNode != null &&
        !await (_detailsKey.currentState?.mayLeaveDraft() ??
            Future.value(true))) {
      return;
    }
    if (!mounted) return;
    _search.clear();
    setState(() {
      _submittedSearch = '';
      _focusedNode = null;
      _popupAnchor = null;
    });
  }

  void _goHome() => unawaited(_goHomeAsync());

  Future<void> _goHomeAsync() async {
    if (_focusedNode != null &&
        !await (_detailsKey.currentState?.mayLeaveDraft() ??
            Future.value(true))) {
      return;
    }
    if (!mounted) return;
    _search.clear();
    _searchFocus.unfocus();
    setState(() {
      _submittedSearch = '';
      _findOpen = false;
      _sidebarView = _SidebarView.hidden;
      _focusedNode = null;
      _popupAnchor = null;
      _graphViewEpoch++;
    });
    _restoreWorkspaceFocus();
  }

  void _focusSearch() {
    if (_findOpen) {
      _searchFocus.requestFocus();
      return;
    }
    setState(() => _findOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeFind() {
    _searchFocus.unfocus();
    setState(() => _findOpen = false);
    _restoreWorkspaceFocus();
  }

  void _restoreWorkspaceFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _workspaceFocus.requestFocus();
    });
  }

  void _handleEscape() {
    if (_findOpen) {
      _closeFind();
    } else if (_focusedNode != null &&
        _detailsKey.currentState?._editing == true) {
      unawaited(_detailsKey.currentState!._cancelEdit());
    } else if (_focusedNode != null) {
      unawaited(_closePopup());
    } else if (_sidebarView != _SidebarView.hidden) {
      _closeSidebar();
    } else {
      _goHome();
    }
  }

  Future<void> _openCreate({
    String suggestedSlug = '',
    List<String> suggestedLabels = const [],
    DateTime? calendarDate,
    Node? node,
  }) async {
    if (_focusedNode != null &&
        !await (_detailsKey.currentState?.mayLeaveDraft() ??
            Future.value(true))) {
      return;
    }
    if (!mounted) return;
    final created = await showDialog<Node>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NodeEditorDialog(
        node: node,
        suggestedSlug: suggestedSlug,
        suggestedLabels: suggestedLabels,
        lockSlug: calendarDate != null,
        saveNode: (existing, slug, labels, body) => _saveNodeDraft(
          existing: existing,
          slug: slug,
          labels: labels,
          body: body,
          calendarDate: calendarDate,
        ),
      ),
    );
    if (created == null || !mounted) return;
    ref.invalidate(nodeGraphProvider);
    ref.invalidate(nodeSearchProvider);
    ref.invalidate(nodesByExactSlugsProvider);
    _search.clear();
    setState(() {
      _submittedSearch = '';
      _findOpen = false;
    });
    _restoreWorkspaceFocus();
    _message(node == null ? 'Node created' : 'Node saved');
    if (calendarDate == null) {
      await _focusNode(created, checkDraft: false);
    }
  }

  Future<Node> _saveNodeDraft({
    required Node? existing,
    required String slug,
    required List<String> labels,
    required String body,
    required DateTime? calendarDate,
  }) async {
    final api = ref.read(sevilleApiProvider);
    final normalizedLabels = labels.toSet();
    if (calendarDate != null) normalizedLabels.add('Date');
    var saved = existing;
    if (saved == null) {
      saved = await api.createNode(
        slug: slug,
        labels: normalizedLabels,
        body: body,
      );
    } else {
      if (saved.body != body) {
        saved = await api.updateNodeBody(
          slug: saved.slug,
          body: body,
          expectedUpdateCount: saved.updateCount.toInt(),
        );
      }
      if (!setEquals(saved.labels.toSet(), normalizedLabels)) {
        saved = await api.replaceNodeLabels(
          slug: saved.slug,
          labels: normalizedLabels,
          expectedUpdateCount: saved.updateCount.toInt(),
        );
      }
    }
    if (calendarDate != null) {
      final start = DateTime.utc(
        calendarDate.year,
        calendarDate.month,
        calendarDate.day,
      );
      final startText = _isoDay(start);
      final endText = _isoDay(start.add(const Duration(days: 1)));
      if (!saved.hasTemporalSpan() ||
          saved.temporalSpan.startDate != startText ||
          saved.temporalSpan.endDateExclusive != endText ||
          saved.temporalSpan.granularity !=
              TemporalGranularity.TEMPORAL_GRANULARITY_DAY) {
        saved = await api.replaceNodeTemporalSpan(
          slug: saved.slug,
          span: NodeTemporalSpan(
            startDate: startText,
            endDateExclusive: endText,
            granularity: TemporalGranularity.TEMPORAL_GRANULARITY_DAY,
          ),
          expectedUpdateCount: saved.updateCount.toInt(),
        );
      }
    }
    return saved;
  }

  Future<void> _openCalendarDate(DateTime date) async {
    final slug = _dateSlug(date);
    NodeSearchResult result;
    try {
      result = await ref.read(sevilleApiProvider).nodesByExactSlugs([slug]);
    } catch (_) {
      if (mounted) _message('Could not check the Date Node.');
      return;
    }
    Node? existing;
    for (final node in result.nodes) {
      if (node.slug == slug) {
        existing = node;
        break;
      }
    }
    if (!mounted) return;
    await _openCreate(
      suggestedSlug: slug,
      suggestedLabels: const ['Date'],
      calendarDate: date,
      node: existing,
    );
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
    final request = (rootNodeSlug: null, search: _submittedSearch);
    final graphState = ref.watch(nodeGraphProvider(request));
    final listGraphState = _sidebarView == _SidebarView.nodes
        ? ref.watch(nodeGraphProvider((rootNodeSlug: null, search: '')))
        : graphState;
    final viewport = MediaQuery.sizeOf(context);
    final sidebarWidth = math.min(300.0, math.max(0.0, viewport.width - 24));
    final popupSize = Size(
      math.min(440.0, math.max(0.0, viewport.width - 24)),
      math.min(560.0, math.max(0.0, viewport.height - 24)),
    );
    final popupPosition = _popupPosition(viewport, popupSize);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _refresh,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          final details = _detailsKey.currentState;
          if (details?._editing == true) unawaited(details!._saveBody());
        },
        const SingleActivator(LogicalKeyboardKey.backslash, meta: true):
            _toggleSidebar,
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      child: Focus(
        focusNode: _workspaceFocus,
        autofocus: true,
        child: Scaffold(
          floatingActionButton: _floatingActions(),
          body: Stack(
            key: _canvasKey,
            children: [
              Positioned.fill(child: _visibleGraph(graphState)),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                top: MediaQuery.paddingOf(context).top + 72,
                bottom: MediaQuery.paddingOf(context).bottom + 120,
                left: _sidebarView == _SidebarView.hidden
                    ? -sidebarWidth - 16
                    : 12,
                width: sidebarWidth,
                child: _nodeSidebar(listGraphState),
              ),
              Positioned(
                left: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                child: _leftFloatingActions(),
              ),
              Positioned(
                left: 16,
                top: MediaQuery.paddingOf(context).top + 16,
                child: _floatingAction(
                  tag: 'home',
                  tooltip: 'Home · reset graph view',
                  icon: Icons.home_outlined,
                  onPressed: _goHome,
                ),
              ),
              if (_submittedSearch.isNotEmpty && !_findOpen)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: _sidebarView == _SidebarView.nodes
                      ? sidebarWidth + 24
                      : 72,
                  child: InputChip(
                    label: Text('Filtered: $_submittedSearch'),
                    tooltip: 'Clear graph search filter',
                    onPressed: _focusSearch,
                    onDeleted: _showAll,
                  ),
                ),
              if (_focusedNode != null)
                Positioned(
                  left: popupPosition.dx,
                  top: popupPosition.dy,
                  width: popupSize.width,
                  height: popupSize.height,
                  child: _NodeDetailsPopup(
                    key: _detailsKey,
                    initialNode: _focusedNode!,
                    onClose: () => unawaited(_closePopup()),
                  ),
                ),
              if (_findOpen)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 12,
                  right: 12,
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Focus(
                        onKeyEvent: (_, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            _closeFind();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          child: _searchBar(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _popupPosition(Size viewport, Size popup) {
    final anchor = _popupAnchor;
    if (anchor == null) {
      return Offset(
        (viewport.width - popup.width) / 2,
        (viewport.height - popup.height) / 2,
      );
    }
    final preferredX = anchor.dx + popup.width + 14 <= viewport.width - 12
        ? anchor.dx + 14
        : anchor.dx - popup.width - 14;
    final preferredY = anchor.dy + popup.height + 14 <= viewport.height - 12
        ? anchor.dy + 14
        : anchor.dy - popup.height - 14;
    return Offset(
      preferredX.clamp(12.0, math.max(12.0, viewport.width - popup.width - 12)),
      preferredY.clamp(
        12.0,
        math.max(12.0, viewport.height - popup.height - 12),
      ),
    );
  }

  Widget _leftFloatingActions() => _floatingAction(
    tag: 'node-sidebar',
    tooltip: _sidebarView == _SidebarView.nodes
        ? 'Hide Node list'
        : 'Show Node list',
    icon: _sidebarView == _SidebarView.nodes
        ? Icons.menu_open
        : Icons.view_sidebar_outlined,
    onPressed: _toggleSidebar,
  );

  Widget _floatingActions() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _floatingAction(
        tag: 'find-nodes',
        tooltip: 'Find Nodes',
        icon: Icons.search,
        onPressed: _focusSearch,
      ),
      const SizedBox(height: 8),
      _floatingAction(
        tag: 'create-node',
        tooltip: 'Create Node',
        icon: Icons.add_circle_outline,
        onPressed: () => unawaited(_openCreate()),
      ),
      const SizedBox(height: 8),
      _floatingAction(
        tag: 'refresh-graph',
        tooltip: 'Refresh graph',
        icon: Icons.refresh,
        onPressed: _refresh,
      ),
      const SizedBox(height: 8),
      _floatingAction(
        tag: 'manage-labels',
        tooltip: 'Manage Neo4j labels',
        icon: Icons.label_outline,
        onPressed: () => unawaited(_openLabels()),
      ),
      const SizedBox(height: 8),
      _floatingAction(
        tag: 'color-rules',
        tooltip: 'Node appearance rules',
        icon: Icons.palette_outlined,
        onPressed: () => unawaited(_openColorRules()),
      ),
    ],
  );

  Widget _floatingAction({
    required String tag,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => FloatingActionButton.small(
    heroTag: tag,
    tooltip: tooltip,
    onPressed: onPressed,
    child: Icon(icon),
  );

  Widget _visibleGraph(AsyncValue<NodeGraph> graphState) => _GraphContent(
    graphState: graphState,
    graphKey: ValueKey<int>(_graphViewEpoch),
    selectedNodeSlug: _focusedNode?.slug,
    onNodeSelected: (node, anchor) =>
        unawaited(_focusNode(node, globalAnchor: anchor)),
    onCalendarDateSelected: (date) => unawaited(_openCalendarDate(date)),
    onRetry: _refresh,
    moreMessage: '',
    overlayMoreMessage: true,
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
                  hintText: 'Find Nodes by slug, title, or label',
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
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Close Find',
              onPressed: _closeFind,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (_submittedSearch.isNotEmpty) _searchResults(),
      ],
    ),
  );

  Widget _searchResults() {
    final result = ref.watch(nodeSearchProvider(_submittedSearch));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: switch (result) {
        AsyncLoading() => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton(
            onPressed: () =>
                ref.invalidate(nodeSearchProvider(_submittedSearch)),
            child: const Text('Search failed. Retry'),
          ),
        ),
        AsyncData(:final value) when value.nodes.isEmpty => Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton(
            onPressed: () =>
                unawaited(_openCreate(suggestedSlug: _submittedSearch)),
            child: Text('No matches. Create [[$_submittedSearch]]'),
          ),
        ),
        AsyncData(:final value) => ListView.builder(
          shrinkWrap: true,
          itemCount: value.nodes.length,
          itemBuilder: (context, index) {
            final node = value.nodes[index];
            return ListTile(
              dense: true,
              title: Text('[[${node.slug}]]'),
              subtitle: node.title.trim().isEmpty ? null : Text(node.title),
              onTap: () => unawaited(_selectSearchResult(node)),
            );
          },
        ),
      },
    );
  }

  Future<void> _selectSearchResult(Node node) async {
    if (await _focusNode(node) && mounted) _closeFind();
  }

  Widget _nodeSidebar(AsyncValue<NodeGraph> graphState) {
    final graph = switch (graphState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final nodes = graph?.nodes ?? <Node>[];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nodes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        graph == null
                            ? 'Loading count…'
                            : '${nodes.length} shown${graph.hasMore ? ' · more available' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close Node list',
                  onPressed: _toggleSidebar,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (graphState) {
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncError() => Center(
                child: TextButton(
                  onPressed: _refresh,
                  child: const Text('Retry loading Nodes'),
                ),
              ),
              _ when nodes.isEmpty => const Center(
                child: Text('No Nodes yet.'),
              ),
              _ => ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  return ListTile(
                    dense: true,
                    title: Text('[[${node.slug}]]', maxLines: 1),
                    subtitle: node.title.trim().isEmpty
                        ? null
                        : Text(node.title, maxLines: 1),
                    onTap: () => unawaited(_focusNode(node)),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}

String _dateSlug(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.year.toString().padLeft(4, '0')}';

String _isoDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _NodeDetailsPopup extends ConsumerStatefulWidget {
  const _NodeDetailsPopup({
    super.key,
    required this.initialNode,
    required this.onClose,
  });

  final Node initialNode;
  final VoidCallback onClose;

  @override
  ConsumerState<_NodeDetailsPopup> createState() => _NodeDetailsPopupState();
}

class _NodeDetailsPopupState extends ConsumerState<_NodeDetailsPopup> {
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

  Future<bool> mayLeaveDraft() async {
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

  Future<bool> selectNode(Node node) async {
    if (node.slug == _root.slug) return true;
    if (!await mayLeaveDraft() || !mounted) return false;
    setState(() {
      _root = node;
      _bodyBaseline = node.body;
      _body.text = node.body;
      _editing = false;
      _feedback = null;
    });
    return true;
  }

  Future<void> _cancelEdit() async {
    if (!await mayLeaveDraft() || !mounted) return;
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
            slug: _root.slug,
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

  Future<void> _editLabels() async {
    if (_saving || _editing) return;
    final updated = await showDialog<Node>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NodeLabelsDialog(node: _root),
    );
    if (updated == null || !mounted) return;
    ref.invalidate(nodeGraphProvider);
    ref.invalidate(nodeSearchProvider);
    setState(() {
      _root = updated;
      _bodyBaseline = updated.body;
      _body.text = updated.body;
      _feedback = 'Node labels saved';
      _feedbackIsError = false;
    });
  }

  Future<void> _editTemporal() async {
    if (_saving || _editing) return;
    final updated = await showDialog<Node>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NodeTemporalDialog(node: _root),
    );
    if (updated == null || !mounted) return;
    ref.invalidate(nodeGraphProvider);
    ref.invalidate(nodeSearchProvider);
    setState(() {
      _root = updated;
      _bodyBaseline = updated.body;
      _body.text = updated.body;
      _feedback = 'Time placement saved';
      _feedbackIsError = false;
    });
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
          Row(
            children: [
              Text('Labels', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _saving || _editing
                    ? null
                    : () => unawaited(_editLabels()),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
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
                    for (final label in node.labels) _labelChip(label),
                  ],
                ),
              ),
            ),
          ],
          if (node.labels.isEmpty) const Text('No labels'),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            children: [
              Text('Time', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _saving || _editing
                    ? null
                    : () => unawaited(_editTemporal()),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
          ),
          Text(
            node.hasTemporalSpan()
                ? '${node.temporalSpan.startDate} → ${node.temporalSpan.endDateExclusive} (end excluded)'
                : 'No time placement',
          ),
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

  Widget _labelChip(String label) {
    final rules = switch (ref.watch(nodeColorRulesProvider)) {
      AsyncData(:final value) => value.rules,
      _ => <NodeColorRule>[],
    };
    final rule = matchingLabelColorRule(label, rules);
    final hex = rule?.colorHex ?? '';
    final color = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)
        ? Color(0xFF000000 | int.parse(hex.substring(1), radix: 16))
        : null;
    return Chip(
      label: Text(
        label,
        style: color == null
            ? null
            : TextStyle(
                color:
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
      ),
      backgroundColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close Node details',
                  onPressed: _saving ? null : widget.onClose,
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Node · [[${_root.slug}]]',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _detailsPane(_root)),
        ],
      ),
    );
  }
}

class _GraphContent extends ConsumerWidget {
  const _GraphContent({
    required this.graphState,
    required this.selectedNodeSlug,
    required this.onNodeSelected,
    required this.onCalendarDateSelected,
    required this.onRetry,
    required this.moreMessage,
    this.graphKey,
    this.overlayMoreMessage = false,
  });

  final AsyncValue<NodeGraph> graphState;
  final String? selectedNodeSlug;
  final void Function(Node node, Offset globalAnchor) onNodeSelected;
  final ValueChanged<DateTime> onCalendarDateSelected;
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
        selectedNodeSlug: selectedNodeSlug,
        onNodeSelected: onNodeSelected,
        onCalendarDateSelected: onCalendarDateSelected,
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
          if (hasMore && moreMessage.isNotEmpty)
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
