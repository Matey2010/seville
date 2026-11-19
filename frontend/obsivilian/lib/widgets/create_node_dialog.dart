import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:seville_proto/seville_proto.dart';

/// One draft form for creating a Node or editing an existing Node.
class NodeEditorDialog extends StatefulWidget {
  const NodeEditorDialog({
    required this.saveNode,
    this.node,
    this.suggestedSlug = '',
    this.suggestedLabels = const [],
    this.lockSlug = false,
    super.key,
  });

  final Future<Node> Function(
    Node? existing,
    String slug,
    List<String> labels,
    String body,
  )
  saveNode;
  final Node? node;
  final String suggestedSlug;
  final List<String> suggestedLabels;
  final bool lockSlug;

  @override
  State<NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<NodeEditorDialog> {
  late final TextEditingController _slug = TextEditingController(
    text: widget.node?.slug ?? widget.suggestedSlug,
  );
  late final TextEditingController _labels = TextEditingController(
    text: (widget.node?.labels ?? widget.suggestedLabels).join(', '),
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.node?.body ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _slug.dispose();
    _labels.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final slug = _slug.text.trim();
    final labels = _labels.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    final validLabel = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    if (slug.isEmpty) {
      setState(() => _error = 'A slug is required.');
      return;
    }
    if (labels.length > 64 ||
        labels.any((label) => !validLabel.hasMatch(label))) {
      setState(
        () => _error = 'Use up to 64 labels with letters, digits, and _.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final node = await widget.saveNode(widget.node, slug, labels, _body.text);
      if (mounted) Navigator.of(context).pop(node);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.response?.statusCode == 409
            ? widget.node == null
                  ? 'A Node with this slug already exists.'
                  : 'This Node changed elsewhere. Reopen it before saving.'
            : 'The Node could not be saved. Check the connection and try again.';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'The Node could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.node == null ? 'Create Node' : 'Edit Node'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _slug,
              autofocus: widget.node == null,
              enabled: !_saving && widget.node == null && !widget.lockSlug,
              maxLength: 512,
              decoration: const InputDecoration(
                labelText: 'Slug',
                hintText: 'new-node',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labels,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Classification labels',
                hintText: 'Project, Science',
                helperText: 'Optional, separated by commas',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              enabled: !_saving,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Markdown body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.node == null ? 'Create' : 'Save'),
      ),
    ],
  );
}
