import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

import 'data/seville_api.dart';
import 'graph/graph_field.dart';
import 'graph/graph_model.dart';

void main() {
  runApp(const SevilleApp());
}

class SevilleApp extends StatelessWidget {
  const SevilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seville',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const NodeFieldScreen(),
    );
  }
}

class NodeFieldScreen extends StatefulWidget {
  const NodeFieldScreen({super.key});

  @override
  State<NodeFieldScreen> createState() => _NodeFieldScreenState();
}

class _NodeFieldScreenState extends State<NodeFieldScreen> {
  late final KnowledgeGraphGame _game = KnowledgeGraphGame();
  late final SevilleApi _api = SevilleApi();

  KnowledgeSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  bool _matchAll = false;
  String _tagQuery = '';
  List<Note> _visibleNotes = const [];

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
        _visibleNotes = _filter(snapshot.notes);
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
      _visibleNotes = _filter(snapshot.notes);
    });
    _updateGraph();
  }

  void _updateGraph() {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    _game.setGraph(
      KnowledgeGraph.fromSnapshot(
        snapshot,
        visibleNoteIds: _visibleNotes.map((note) => note.id).toSet(),
      ),
    );
  }

  List<Note> _filter(List<Note> notes) {
    final wanted = _tagQuery
        .split(',')
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) return List.unmodifiable(notes);

    return List.unmodifiable(
      notes.where((note) {
        final tags = note.tags.map(_normalizeTag).toSet();
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
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilterPanel(
                loading: _loading,
                error: _error,
                totalCount: _snapshot?.notes.length ?? 0,
                visibleCount: _visibleNotes.length,
                linkCount:
                    _snapshot?.links
                        .where((link) => link.hasResolvedTargetId())
                        .length ??
                    0,
                matchAll: _matchAll,
                onQueryChanged: (query) => _updateFilter(query: query),
                onMatchAllChanged: (value) => _updateFilter(matchAll: value),
                onRetry: _loadSnapshot,
              ),
            ),
          ),
        ],
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
    required this.linkCount,
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
  final int linkCount;
  final bool matchAll;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onMatchAllChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: Card(
        color: const Color(0xE6171920),
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
                          ? 'Fetching knowledge snapshot…'
                          : error != null
                          ? 'Backend unavailable'
                          : '$visibleCount of $totalCount notes · $linkCount resolved links',
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
                  'Node size = weighted links · embeds count ${1.5}×',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ],
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
