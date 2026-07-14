import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

import '../data/seville_api.dart';
import '../graph/graph_field.dart';
import '../models/node_graph.dart';

const _legendOverlay = 'legend';
const _legendToggleOverlay = 'legend-toggle';

class NodeFieldScreen extends StatefulWidget {
  const NodeFieldScreen({super.key});

  @override
  State<NodeFieldScreen> createState() => _NodeFieldScreenState();
}

class _NodeFieldScreenState extends State<NodeFieldScreen> {
  late final NodeGraphGame _game = NodeGraphGame();
  late final SevilleApi _api = SevilleApi();

  NodeSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  bool _matchAll = false;
  String _tagQuery = '';
  List<Node> _visibleNodes = const [];

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _api.snapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _visibleNodes = _filter(snapshot.nodes);
      });
      _updateGraph();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _updateFilter({String? query, bool? matchAll}) {
    if (query != null) _tagQuery = query;
    if (matchAll != null) _matchAll = matchAll;
    final snapshot = _snapshot;
    if (snapshot == null) return;
    setState(() {
      _visibleNodes = _filter(snapshot.nodes);
    });
    _updateGraph();
  }

  void _updateGraph() {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    _game.setGraph(
      NodeGraph.fromSnapshot(
        snapshot,
        visibleNodeIds: _visibleNodes.map((node) => node.id).toSet(),
      ),
    );
  }

  List<Node> _filter(List<Node> nodes) {
    final wanted = _tagQuery
        .split(',')
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) return List.unmodifiable(nodes);

    return List.unmodifiable(
      nodes.where((node) {
        final tags = node.tags.map(_normalizeTag).toSet();
        return _matchAll
            ? wanted.every(tags.contains)
            : wanted.any(tags.contains);
      }),
    );
  }

  String _normalizeTag(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('#') ? normalized.substring(1) : normalized;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<NodeGraphGame>(
        game: _game,
        initialActiveOverlays: const [_legendToggleOverlay],
        overlayBuilderMap: {
          _legendToggleOverlay: (context, game) {
            final isOpen = game.overlays.isActive(_legendOverlay);
            return SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Tooltip(
                    message: isOpen ? 'Close legend' : 'Open legend',
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.square(48),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 22),
                      ),
                      onPressed: () => game.overlays.toggle(_legendOverlay),
                      child: const Text('🧭'),
                    ),
                  ),
                ),
              ),
            );
          },
          _legendOverlay: (context, game) => SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 76, 16, 16),
                child: FilterPanel(
                  loading: _loading,
                  error: _error,
                  totalCount: _snapshot?.nodes.length ?? 0,
                  visibleCount: _visibleNodes.length,
                  connectionCount:
                      _snapshot?.connections
                          .where((connection) => connection.hasTargetNodeId())
                          .length ??
                      0,
                  matchAll: _matchAll,
                  onQueryChanged: (query) => _updateFilter(query: query),
                  onMatchAllChanged: (value) => _updateFilter(matchAll: value),
                  onRetry: _loadSnapshot,
                ),
              ),
            ),
          ),
        },
      ),
    );
  }
}

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    required this.loading,
    required this.error,
    required this.totalCount,
    required this.visibleCount,
    required this.connectionCount,
    required this.matchAll,
    required this.onQueryChanged,
    required this.onMatchAllChanged,
    required this.onRetry,
    super.key,
  });

  final bool loading;
  final Object? error;
  final int totalCount;
  final int visibleCount;
  final int connectionCount;
  final bool matchAll;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onMatchAllChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: const Color(0xF7FFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loading
                            ? 'Fetching node snapshot…'
                            : error != null
                            ? 'Backend unavailable'
                            : '$visibleCount of $totalCount nodes · $connectionCount resolved connections',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reload snapshot',
                      onPressed: loading ? null : onRetry,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !loading,
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Filter tags',
                      hintText: 'project, active',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Any tag')),
                      ButtonSegment(value: true, label: Text('All tags')),
                    ],
                    selected: {matchAll},
                    onSelectionChanged: (selection) {
                      onMatchAllChanged(selection.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _LegendDot(label: 'project', color: Color(0xFFFFB454)),
                      _LegendDot(label: 'active', color: Color(0xFF62D6A7)),
                      _LegendDot(label: 'idea', color: Color(0xFFB18CFE)),
                      _LegendDot(label: 'person', color: Color(0xFFFF7A90)),
                      _LegendDot(label: 'other', color: Color(0xFF76B7FF)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Node size = weighted connections · embeds count ${1.5}×',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
