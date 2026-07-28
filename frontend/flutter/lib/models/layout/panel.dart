part of 'layout.dart';

/// Reusable configuration for panel defaults and concrete panel instances.
class PanelConfig {
  const PanelConfig({
    this.foldedPanelSize,
    this.size,
    this.orderPosition,
    this.title,
    this.ordering,
    this.showEmpty,
    this.foldable,
    this.initiallyFolded,
  }) : assert(!(initiallyFolded ?? false) || (foldable ?? false));

  /// Shared folded size inherited by panels without an explicit [size].
  final LayoutSize? foldedPanelSize;

  /// Explicit size for a concrete panel.
  final LayoutSize? size;
  final int? orderPosition;
  final String? title;
  final TableRowOrdering? ordering;
  final bool? showEmpty;
  final bool? foldable;
  final bool? initiallyFolded;

  int get resolvedOrderPosition => orderPosition ?? 0;
  TableRowOrdering get rowOrdering => ordering ?? TableRowOrdering.asConfigured;
  bool get keepsEmpty => showEmpty ?? false;
  bool get isFoldable => foldable ?? false;
  bool get startsFolded => initiallyFolded ?? false;

  PanelConfig merge(PanelConfig overlay) => PanelConfig(
    foldedPanelSize: overlay.foldedPanelSize ?? foldedPanelSize,
    size: overlay.size ?? size,
    orderPosition: overlay.orderPosition ?? orderPosition,
    title: overlay.title ?? title,
    ordering: overlay.ordering ?? ordering,
    showEmpty: overlay.showEmpty ?? showEmpty,
    foldable: overlay.foldable ?? foldable,
    initiallyFolded: overlay.initiallyFolded ?? initiallyFolded,
  );
}
