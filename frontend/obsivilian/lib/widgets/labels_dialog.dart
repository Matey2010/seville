import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';

final _labelPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

class NodeLabelsDialog extends ConsumerStatefulWidget {
  const NodeLabelsDialog({super.key, required this.node});

  final Node node;

  @override
  ConsumerState<NodeLabelsDialog> createState() => _NodeLabelsDialogState();
}

class _NodeLabelsDialogState extends ConsumerState<NodeLabelsDialog> {
  final _input = TextEditingController();
  late final List<String> _labels = [...widget.node.labels];
  List<LabelSummary> _suggestions = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final result = await ref.read(sevilleApiProvider).searchLabels();
      if (mounted) setState(() => _suggestions = result.labels);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load existing labels.');
    }
  }

  void _add(String value) {
    final label = value.trim();
    if (!_labelPattern.hasMatch(label) || label.length > 80) {
      setState(
        () => _error =
            'Use letters, numbers, and underscores; start with a letter or underscore.',
      );
      return;
    }
    if (_labels.length >= 64 && !_labels.contains(label)) {
      setState(() => _error = 'A Node can have at most 64 labels.');
      return;
    }
    setState(() {
      if (!_labels.contains(label)) _labels.add(label);
      _input.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final node = await ref
          .read(sevilleApiProvider)
          .replaceNodeLabels(
            slug: widget.node.slug,
            labels: _labels,
            expectedUpdateCount: widget.node.updateCount.toInt(),
          );
      if (mounted) Navigator.of(context).pop(node);
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.response?.statusCode == 409
              ? 'This Node changed elsewhere. Reopen it before saving labels.'
              : 'Could not save labels.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save labels.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Labels · ${widget.node.slug}'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neo4j labels classify this Node.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final label in _labels)
                InputChip(
                  label: Text(label),
                  onDeleted: _saving
                      ? null
                      : () => setState(() => _labels.remove(label)),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Add label'),
                  onSubmitted: _add,
                ),
              ),
              IconButton(
                tooltip: 'Add label',
                onPressed: _saving ? null : () => _add(_input.text),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Existing labels',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            SizedBox(
              height: 130,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final item in _suggestions)
                      if (!_labels.contains(item.name))
                        ActionChip(
                          label: Text(item.name),
                          onPressed: _saving ? null : () => _add(item.name),
                        ),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Save labels'),
      ),
    ],
  );
}

class LabelsManagerDialog extends ConsumerStatefulWidget {
  const LabelsManagerDialog({super.key, required this.openColorRules});

  final Future<void> Function() openColorRules;

  @override
  ConsumerState<LabelsManagerDialog> createState() =>
      _LabelsManagerDialogState();
}

class _LabelsManagerDialogState extends ConsumerState<LabelsManagerDialog> {
  final _filter = TextEditingController();
  List<LabelSummary>? _labels;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final result = await ref
          .read(sevilleApiProvider)
          .searchLabels(prefix: _filter.text);
      if (mounted) {
        setState(() {
          _labels = result.labels;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load labels.');
    }
  }

  Future<void> _rename(LabelSummary item) async {
    final controller = TextEditingController(text: item.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename ${item.name} on ${item.nodeCount} Nodes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New label name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next == item.name || !mounted) return;
    if (!_labelPattern.hasMatch(next) || next.length > 80) {
      setState(
        () => _error =
            'Invalid label name. Use letters, numbers, and underscores.',
      );
      return;
    }
    await _mutate(
      () => ref.read(sevilleApiProvider).renameLabel(item.name, next),
    );
  }

  Future<void> _delete(LabelSummary item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: Text('Remove this label from all ${item.nodeCount} Nodes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete label'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutate(() => ref.read(sevilleApiProvider).deleteLabel(item.name));
  }

  Future<void> _mutate(Future<LabelMutationResult> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(nodeGraphProvider);
      ref.invalidate(nodeColorRulesProvider);
      await _reload();
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.response?.statusCode == 409
              ? 'That label name is already in use.'
              : 'Could not change label.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not change label.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Neo4j labels'),
    content: SizedBox(
      width: 470,
      height: 420,
      child: Column(
        children: [
          Text(
            'Create a label by adding it to a Node. Rename or delete here affects every Node using it.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextField(
            controller: _filter,
            decoration: InputDecoration(
              labelText: 'Find label by prefix',
              suffixIcon: IconButton(
                tooltip: 'Search labels',
                onPressed: _reload,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _reload(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _labels == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      for (final item in _labels!)
                        ListTile(
                          title: Text(item.name),
                          subtitle: Text('${item.nodeCount} Nodes'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename ${item.name}',
                                onPressed: _busy ? null : () => _rename(item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete ${item.name}',
                                onPressed: _busy ? null : () => _delete(item),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: _busy
            ? null
            : () async {
                Navigator.of(context).pop();
                await widget.openColorRules();
              },
        icon: const Icon(Icons.palette_outlined),
        label: const Text('Appearance rules'),
      ),
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}
