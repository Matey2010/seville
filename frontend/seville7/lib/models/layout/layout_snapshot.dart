part of 'layout.dart';

/// Immutable address index captured from one declarative Layout tree.
class LayoutSnapshot {
  LayoutSnapshot._(this.entries);

  factory LayoutSnapshot.capture(Layout root) {
    final entries = <LayoutSnapshotEntry<Layout>>[];

    void visit(Layout layout, List<String> path) {
      entries.add(
        LayoutSnapshotEntry(layout: layout, path: List.unmodifiable(path)),
      );
      for (final child in layout.children.entries) {
        visit(child.value, [...path, child.key]);
      }
    }

    visit(root, const []);
    return LayoutSnapshot._(List.unmodifiable(entries));
  }

  final List<LayoutSnapshotEntry<Layout>> entries;

  Iterable<LayoutSnapshotEntry<T>> layoutsOfType<T extends Layout>() sync* {
    for (final entry in entries) {
      final layout = entry.layout;
      if (layout is T) {
        yield LayoutSnapshotEntry<T>(layout: layout, path: entry.path);
      }
    }
  }

  Iterable<LayoutVaultNodeReference> get vaultNodes sync* {
    for (final entry in entries) {
      final layout = entry.layout;
      if (layout case PlaneLayout(:final vaultNode?)) {
        yield LayoutVaultNodeReference(
          layoutPath: entry.path,
          vaultNode: vaultNode,
        );
      }
    }
  }
}

class LayoutSnapshotEntry<T extends Layout> {
  const LayoutSnapshotEntry({required this.layout, required this.path});

  final T layout;
  final List<String> path;

  String get address => path.join('/');
}

class LayoutVaultNodeReference {
  const LayoutVaultNodeReference({
    required this.layoutPath,
    required this.vaultNode,
  });

  final List<String> layoutPath;
  final VaultNode vaultNode;
}
