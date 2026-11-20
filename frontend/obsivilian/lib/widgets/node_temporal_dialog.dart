import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';

class NodeTemporalDialog extends ConsumerStatefulWidget {
  const NodeTemporalDialog({required this.node, super.key});

  final Node node;

  @override
  ConsumerState<NodeTemporalDialog> createState() => _NodeTemporalDialogState();
}

class _NodeTemporalDialogState extends ConsumerState<NodeTemporalDialog> {
  final TextEditingController _start = TextEditingController();
  final TextEditingController _end = TextEditingController();
  TemporalGranularity _granularity =
      TemporalGranularity.TEMPORAL_GRANULARITY_DAY;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final span = widget.node.hasTemporalSpan()
        ? widget.node.temporalSpan
        : _suggestFromSlug(widget.node);
    if (span != null) {
      _start.text = span.startDate;
      _end.text = span.endDateExclusive;
      _granularity =
          span.granularity == TemporalGranularity.TEMPORAL_GRANULARITY_RANGE
          ? TemporalGranularity.TEMPORAL_GRANULARITY_DAY
          : span.granularity;
    }
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save({bool clear = false}) async {
    if (_saving) return;
    final span = clear
        ? null
        : NodeTemporalSpan(
            startDate: _start.text.trim(),
            endDateExclusive: _end.text.trim(),
            granularity: _granularity,
          );
    if (!clear &&
        (!_isoDate.hasMatch(span!.startDate) ||
            !_isoDate.hasMatch(span.endDateExclusive))) {
      setState(
        () => _error = 'Use ISO dates such as 2026-08-07 or -0220-01-01.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final node = await ref
          .read(sevilleApiProvider)
          .replaceNodeTemporalSpan(
            slug: widget.node.slug,
            span: span,
            expectedUpdateCount: widget.node.updateCount.toInt(),
          );
      if (mounted) Navigator.of(context).pop(node);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.response?.statusCode) {
          400 => 'Check the interval and selected calendar scale.',
          409 => 'This Node changed elsewhere. Reopen it before saving.',
          _ => 'Could not save the temporal span.',
        };
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the temporal span.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Time placement'),
    content: SizedBox(
      width: 430,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Store an inclusive start and exclusive end as Neo4j dates.',
          ),
          if (widget.node.hasTemporalSpan() &&
              widget.node.temporalSpan.granularity ==
                  TemporalGranularity.TEMPORAL_GRANULARITY_RANGE) ...[
            const SizedBox(height: 12),
            const Text(
              'This legacy range has no dedicated HUD lane. Choose a calendar scale or clear it.',
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<TemporalGranularity>(
            initialValue: _granularity,
            decoration: const InputDecoration(labelText: 'Calendar scale'),
            items: [
              for (final (value, title) in _granularities)
                DropdownMenuItem(value: value, child: Text(title)),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) setState(() => _granularity = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _start,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Start date',
              hintText: '2026-08-07',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _end,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'End date (exclusive)',
              hintText: '2026-08-08',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      if (widget.node.hasTemporalSpan())
        TextButton(
          onPressed: _saving ? null : () => _save(clear: true),
          child: const Text('Clear time'),
        ),
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}

final _isoDate = RegExp(r'^-?\d{4,6}-\d{2}-\d{2}$');

const _granularities = <(TemporalGranularity, String)>[
  (TemporalGranularity.TEMPORAL_GRANULARITY_YEAR, 'Year'),
  (TemporalGranularity.TEMPORAL_GRANULARITY_SEASON, 'Season'),
  (TemporalGranularity.TEMPORAL_GRANULARITY_MONTH, 'Month'),
  (TemporalGranularity.TEMPORAL_GRANULARITY_WEEK, 'Week'),
  (TemporalGranularity.TEMPORAL_GRANULARITY_DAY, 'Day'),
];

NodeTemporalSpan? _suggestFromSlug(Node node) {
  final labels = node.labels.toSet();
  final slug = node.slug;
  if (labels.contains('Year')) {
    final match = RegExp(r'^(\d{4})$').firstMatch(slug);
    if (match != null) {
      final year = int.parse(match[1]!);
      if (year >= 1 && year < 9999) {
        return NodeTemporalSpan(
          startDate: '${year.toString().padLeft(4, '0')}-01-01',
          endDateExclusive: '${(year + 1).toString().padLeft(4, '0')}-01-01',
          granularity: TemporalGranularity.TEMPORAL_GRANULARITY_YEAR,
        );
      }
    }
  }
  if (labels.contains('Date')) {
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(slug);
    if (match != null) {
      final day = int.parse(match[1]!);
      final month = int.parse(match[2]!);
      final year = int.parse(match[3]!);
      final date = DateTime.utc(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return NodeTemporalSpan(
          startDate: _formatDate(date),
          endDateExclusive: _formatDate(date.add(const Duration(days: 1))),
          granularity: TemporalGranularity.TEMPORAL_GRANULARITY_DAY,
        );
      }
    }
  }
  return null;
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
