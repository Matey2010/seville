import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seville_proto/seville_proto.dart';

import '../state/node_store.dart';

const _fields = <(ColorRuleField, String)>[
  (ColorRuleField.COLOR_RULE_FIELD_ID, 'ID'),
  (ColorRuleField.COLOR_RULE_FIELD_LABEL, 'Label'),
  (ColorRuleField.COLOR_RULE_FIELD_TAG, 'Tag'),
  (ColorRuleField.COLOR_RULE_FIELD_SLUG, 'Slug'),
  (ColorRuleField.COLOR_RULE_FIELD_TITLE, 'Title'),
  (ColorRuleField.COLOR_RULE_FIELD_FRONTMATTER, 'Frontmatter'),
];
const _operators = <(ColorRuleOperator, String)>[
  (ColorRuleOperator.COLOR_RULE_OPERATOR_EXACT, 'Is exactly'),
  (ColorRuleOperator.COLOR_RULE_OPERATOR_CONTAINS, 'Contains'),
  (ColorRuleOperator.COLOR_RULE_OPERATOR_STARTS_WITH, 'Starts with'),
];
const _palette = <String>[
  '#E57373',
  '#FFB74D',
  '#FFF176',
  '#81C784',
  '#4DD0E1',
  '#64B5F6',
  '#BA68C8',
  '#F48FB1',
];

class ColorRulesDialog extends ConsumerStatefulWidget {
  const ColorRulesDialog({super.key});

  @override
  ConsumerState<ColorRulesDialog> createState() => _ColorRulesDialogState();
}

class _ColorRulesDialogState extends ConsumerState<ColorRulesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rules = <NodeColorRule>[];
  int _revision = 0;
  bool _loaded = false;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  void _load(NodeColorRuleSet set) {
    _rules
      ..clear()
      ..addAll(set.rules.map((rule) => rule.deepCopy()));
    _revision = set.revision.toInt();
    _loaded = true;
    _dirty = false;
    _error = null;
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard color rule changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !_loaded || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(sevilleApiProvider)
          .replaceNodeColorRules(
            NodeColorRuleSet(revision: Int64(_revision), rules: _rules),
          );
      if (!mounted) return;
      ref.invalidate(nodeColorRulesProvider);
      Navigator.pop(context);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.response?.statusCode == 409
            ? 'Rules changed on another device. Your draft is still here. Close and reopen to load the latest version.'
            : 'Could not save color rules. Your draft is still here.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not save color rules. Your draft is still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addRule() {
    if (_rules.length >= 100) return;
    setState(() {
      _rules.add(
        NodeColorRule(
          name: 'New rule',
          enabled: true,
          weight: 0,
          field_4: ColorRuleField.COLOR_RULE_FIELD_LABEL,
          operator: ColorRuleOperator.COLOR_RULE_OPERATOR_EXACT,
          colorHex: _palette[_rules.length % _palette.length],
        ),
      );
      _dirty = true;
    });
  }

  void _move(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _rules.length) return;
    setState(() {
      final rule = _rules.removeAt(index);
      _rules.insert(target, rule);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeColorRulesProvider);
    if (!_loaded && state is AsyncData<NodeColorRuleSet>) {
      _load(state.value);
    }
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_close());
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: math.min(size.width - 40, 820),
          height: math.min(size.height - 40, 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close color rules',
                      onPressed: _saving ? null : () => unawaited(_close()),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Node color rules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (_loaded) Text('Revision $_revision'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: !_loaded
                    ? Center(
                        child: switch (state) {
                          AsyncError() => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load color rules.'),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(nodeColorRulesProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                          _ => const CircularProgressIndicator(),
                        },
                      )
                    : AbsorbPointer(
                        absorbing: _saving,
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const Text(
                                'Higher weight wins when several enabled rules match. '
                                'Rules with equal weight use the first rule in this list. '
                                'Matching ignores letter case.',
                              ),
                              const SizedBox(height: 12),
                              if (_rules.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text('No color rules yet.'),
                                  ),
                                ),
                              for (
                                var index = 0;
                                index < _rules.length;
                                index++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RuleEditor(
                                    key: ObjectKey(_rules[index]),
                                    rule: _rules[index],
                                    index: index,
                                    count: _rules.length,
                                    onChanged: _changed,
                                    onMove: _move,
                                    onDelete: () => setState(() {
                                      _rules.removeAt(index);
                                      _dirty = true;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: !_loaded || _saving || _rules.length >= 100
                          ? null
                          : _addRule,
                      icon: const Icon(Icons.add),
                      label: const Text('Add rule'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : () => unawaited(_close()),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: !_loaded || !_dirty || _saving
                          ? null
                          : () => unawaited(_save()),
                      child: Text(_saving ? 'Saving…' : 'Save rules'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleEditor extends StatefulWidget {
  const _RuleEditor({
    required this.rule,
    required this.index,
    required this.count,
    required this.onChanged,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  final NodeColorRule rule;
  final int index;
  final int count;
  final VoidCallback onChanged;
  final void Function(int, int) onMove;
  final VoidCallback onDelete;

  @override
  State<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<_RuleEditor> {
  late final TextEditingController _color;

  @override
  void initState() {
    super.initState();
    _color = TextEditingController(text: widget.rule.colorHex);
  }

  @override
  void dispose() {
    _color.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final colorValid = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(_color.text);
    final preview = colorValid
        ? Color(0xFF000000 | int.parse(_color.text.substring(1), radix: 16))
        : Colors.transparent;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: rule.enabled,
                  onChanged: (value) {
                    setState(() => rule.enabled = value);
                    widget.onChanged();
                  },
                ),
                Text('Rule ${widget.index + 1}'),
                const Spacer(),
                IconButton(
                  tooltip: 'Move rule up',
                  onPressed: widget.index == 0
                      ? null
                      : () => widget.onMove(widget.index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move rule down',
                  onPressed: widget.index == widget.count - 1
                      ? null
                      : () => widget.onMove(widget.index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Delete rule',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    initialValue: rule.name,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter a name' : null,
                    onChanged: (value) {
                      rule.name = value;
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: rule.weight.toString(),
                    decoration: const InputDecoration(labelText: 'Weight'),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    validator: (value) {
                      final weight = int.tryParse((value ?? '').trim());
                      return weight == null || weight < -10000 || weight > 10000
                          ? '−10000 to 10000'
                          : null;
                    },
                    onChanged: (value) {
                      final weight = int.tryParse(value.trim());
                      if (weight != null) rule.weight = weight;
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<ColorRuleField>(
                    initialValue: rule.field_4,
                    decoration: const InputDecoration(labelText: 'Node field'),
                    items: [
                      for (final (field, label) in _fields)
                        DropdownMenuItem(value: field, child: Text(label)),
                    ],
                    onChanged: (field) {
                      if (field == null) return;
                      setState(() => rule.field_4 = field);
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<ColorRuleOperator>(
                    initialValue: rule.operator,
                    decoration: const InputDecoration(labelText: 'Match'),
                    items: [
                      for (final (operator, label) in _operators)
                        DropdownMenuItem(value: operator, child: Text(label)),
                    ],
                    onChanged: (operator) {
                      if (operator == null) return;
                      rule.operator = operator;
                      widget.onChanged();
                    },
                  ),
                ),
                if (rule.field_4 == ColorRuleField.COLOR_RULE_FIELD_FRONTMATTER)
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      initialValue: rule.frontmatterKey,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Frontmatter key',
                      ),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Enter a key' : null,
                      onChanged: (value) {
                        rule.frontmatterKey = value;
                        widget.onChanged();
                      },
                    ),
                  ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    initialValue: rule.value,
                    maxLength: 256,
                    decoration: const InputDecoration(
                      labelText: 'Value to match',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter a value' : null,
                    onChanged: (value) {
                      rule.value = value;
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _color,
                    decoration: InputDecoration(
                      labelText: 'Color #RRGGBB',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircleAvatar(
                          backgroundColor: preview,
                          radius: 10,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        RegExp(
                          r'^#[0-9A-Fa-f]{6}$',
                        ).hasMatch((value ?? '').trim())
                        ? null
                        : 'Use #RRGGBB',
                    onChanged: (value) {
                      setState(() => rule.colorHex = value);
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              children: [
                for (final hex in _palette)
                  Tooltip(
                    message: hex,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        _color.text = hex;
                        setState(() => rule.colorHex = hex);
                        widget.onChanged();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(
                            0xFF000000 | int.parse(hex.substring(1), radix: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
