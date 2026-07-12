import 'package:seville_proto/seville_proto.dart';

import '../domain/node.dart';
import '../models/layout.dart';

class VaultNodeResolver {
  const VaultNodeResolver._(this._notesByPath, this._notes);

  factory VaultNodeResolver.fromNotes(Iterable<Note> notes) {
    final noteList = List<Note>.unmodifiable(notes);
    return VaultNodeResolver._({
      for (final note in noteList) normalizePath(note.path): note,
    }, noteList);
  }

  static const empty = VaultNodeResolver._({}, []);

  final Map<String, Note> _notesByPath;
  final List<Note> _notes;

  bool get isEmpty => _notes.isEmpty;

  ResolvedVaultNode resolve(VaultNodeUiComponent component) {
    final configuredStatus = component.status;
    if (configuredStatus != null) {
      final note = configuredStatus == LayoutHttpStatus.ok
          ? _findNote(component.path)
          : null;
      return ResolvedVaultNode(
        path: component.path,
        color: component.color,
        label: component.label,
        status: component.status,
        node: note == null ? null : Node.fromNote(note),
        note: note,
        resolvedStatus: configuredStatus,
      );
    }

    final note = _findNote(component.path);
    return ResolvedVaultNode(
      path: component.path,
      color: component.color,
      label: component.label,
      status: component.status,
      node: note == null ? null : Node.fromNote(note),
      note: note,
      resolvedStatus: note == null
          ? LayoutHttpStatus.notFound
          : LayoutHttpStatus.ok,
    );
  }

  ResolvedVaultNode? findLinkedNode(String? value) {
    final components = linkedNodeComponents(value);
    return components.isEmpty ? null : resolve(components.first);
  }

  List<ResolvedVaultNode> findLinkedNodes(String? value) => [
    for (final component in linkedNodeComponents(value)) resolve(component),
  ];

  static List<VaultNodeUiComponent> linkedNodeComponents(String? value) {
    if (value == null || value.isEmpty) return const [];
    final links = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
    return [
      for (final match in links.allMatches(value))
        if ((match.group(1)?.trim() ?? '') case final path when path.isNotEmpty)
          VaultNodeUiComponent(
            path: path,
            label: switch (match.group(2)?.trim()) {
              final label? when label.isNotEmpty => label,
              _ => null,
            },
          ),
    ];
  }

  Iterable<String> pathSample({int count = 12}) =>
      _notes.map((note) => note.path).take(count);

  Iterable<String> titleSample({int count = 12}) =>
      _notes.map((note) => note.title).take(count);

  Note? _findNote(String path) {
    for (final candidate in pathCandidates(path)) {
      final note = _notesByPath[candidate];
      if (note != null) return note;
    }

    if (isCortexRootPath(path)) {
      for (final note in _notes) {
        if (_isCortexRootNote(note)) return note;
      }
    }

    return null;
  }

  static String normalizePath(String path) {
    return path
        .trim()
        .replaceAll(r'\', '/')
        .toLowerCase()
        .replaceAll(RegExp(r'/+'), '/')
        .replaceFirst(RegExp(r'\.md$'), '')
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'/+$'), '');
  }

  static Set<String> pathCandidates(String path) {
    final normalized = normalizePath(path);
    if (isCortexRootPath(path)) {
      return const {'', 'cortex', 'cortex/cortex'};
    }
    final segments = normalized.split('/');
    final leaf = segments.isEmpty ? normalized : segments.last;
    return {normalized, '$normalized/$leaf'};
  }

  static bool isCortexRootPath(String path) {
    final normalized = normalizePath(path);
    return normalized.isEmpty || normalized == 'cortex';
  }

  static bool _isCortexRootNote(Note note) {
    final path = normalizePath(note.path);
    final title = normalizePath(note.title);
    return path == 'cortex' ||
        path == 'cortex/cortex' ||
        title == 'cortex' ||
        path.endsWith('/cortex');
  }
}
