part of 'layout.dart';

abstract class LayoutCondition {
  const LayoutCondition._({this.exclude = const {}});

  factory LayoutCondition(
    bool Function(LayoutContext context) test, {
    Set<String> exclude = const {},
  }) {
    return _LayoutPredicateCondition(test, exclude: exclude);
  }

  static const never = _LayoutNeverCondition();

  const factory LayoutCondition.always() = _LayoutAlwaysCondition;

  const factory LayoutCondition.noSelectedNode() = _NoSelectedNodesCondition;

  const factory LayoutCondition.hasActiveNodes({Set<String> exclude}) =
      _HasActiveNodesCondition;

  const factory LayoutCondition.hasLabelsInActiveNodes(List<String> labels) =
      _HasLabelsInActiveNodesCondition;

  const factory LayoutCondition.hasLabelsInCurrentNode(List<String> labels) =
      _HasLabelsInCurrentNodeCondition;

  const factory LayoutCondition.not(LayoutCondition condition) =
      _LayoutNotCondition;

  const factory LayoutCondition.nodeHighlighted({String? nodePath}) =
      _LayoutNodeHighlightedCondition;

  const factory LayoutCondition.nodeSelected({String? nodePath}) =
      _LayoutNodeSelectedCondition;

  const factory LayoutCondition.labelHighlighted() =
      _LayoutLabelHighlightedCondition;

  const factory LayoutCondition.panelFocused() = _LayoutPanelFocusedCondition;

  const factory LayoutCondition.equalsTo(String value) =
      _LayoutEqualsToCondition;

  const factory LayoutCondition.isIn(List<String> values) =
      _LayoutIsInCondition;

  const factory LayoutCondition.inputSource(LayoutInputSource source) =
      _LayoutInputSourceCondition;

  const factory LayoutCondition.findOpened() = _LayoutFindOpenedCondition;

  final Set<String> exclude;

  Set<String> get normalizedExclude => {
    for (final path in exclude) _normalizeLayoutPath(path),
  };

  bool isActive(LayoutContext context);
}

class _LayoutPredicateCondition extends LayoutCondition {
  const _LayoutPredicateCondition(this.test, {super.exclude = const {}})
    : super._();

  final bool Function(LayoutContext context) test;

  @override
  bool isActive(LayoutContext context) => test(context);
}

class _LayoutNeverCondition extends LayoutCondition {
  const _LayoutNeverCondition() : super._();

  @override
  bool isActive(LayoutContext context) => false;
}

class _LayoutAlwaysCondition extends LayoutCondition {
  const _LayoutAlwaysCondition() : super._();

  @override
  bool isActive(LayoutContext context) => true;
}

class _LayoutNotCondition extends LayoutCondition {
  const _LayoutNotCondition(this.condition) : super._();

  final LayoutCondition condition;

  @override
  bool isActive(LayoutContext context) => !condition.isActive(context);
}

class _LayoutInputSourceCondition extends LayoutCondition {
  const _LayoutInputSourceCondition(this.source) : super._();

  final LayoutInputSource source;

  @override
  bool isActive(LayoutContext context) => context.inputSource == source;
}

class _LayoutFindOpenedCondition extends LayoutCondition {
  const _LayoutFindOpenedCondition() : super._();

  @override
  bool isActive(LayoutContext context) => context.findOpened;
}

class _LayoutNodeHighlightedCondition extends LayoutCondition {
  const _LayoutNodeHighlightedCondition({this.nodePath}) : super._();

  final String? nodePath;

  @override
  bool isActive(LayoutContext context) {
    final path = nodePath ?? context.currentNodePath;
    if (path == null) return false;
    final normalized = _normalizeLayoutPath(path);
    return context.highlightedNodePaths.any(
      (candidate) => _normalizeLayoutPath(candidate) == normalized,
    );
  }
}

class _LayoutNodeSelectedCondition extends LayoutCondition {
  const _LayoutNodeSelectedCondition({this.nodePath}) : super._();

  final String? nodePath;

  @override
  bool isActive(LayoutContext context) {
    final path = nodePath ?? context.currentNodePath;
    if (path != null && path.trim().isNotEmpty) {
      final normalized = _normalizeLayoutPath(path);
      if (context.selectedNodePaths.any(
        (candidate) => _normalizeLayoutPath(candidate) == normalized,
      )) {
        return true;
      }
    }
    if (nodePath != null) return false;
    final slug = context.currentNodeSlug?.trim();
    if (slug == null || slug.isEmpty) return false;
    final normalizedSlug = _normalizeConditionValue(slug);
    return context.activeNodeSlugs.any(
      (candidate) => _normalizeConditionValue(candidate) == normalizedSlug,
    );
  }
}

class _LayoutLabelHighlightedCondition extends LayoutCondition {
  const _LayoutLabelHighlightedCondition() : super._();

  @override
  bool isActive(LayoutContext context) => context.labelHighlighted;
}

class _LayoutPanelFocusedCondition extends LayoutCondition {
  const _LayoutPanelFocusedCondition() : super._();

  @override
  bool isActive(LayoutContext context) => context.panelFocused;
}

class _LayoutEqualsToCondition extends LayoutCondition {
  const _LayoutEqualsToCondition(this.value) : super._();

  final String value;

  @override
  bool isActive(LayoutContext context) {
    final currentLabel = context.currentLabel;
    if (currentLabel == null) return false;
    return _normalizeConditionValue(currentLabel) ==
        _normalizeConditionValue(value);
  }
}

class _LayoutIsInCondition extends LayoutCondition {
  const _LayoutIsInCondition(this.values) : super._();

  final List<String> values;

  @override
  bool isActive(LayoutContext context) {
    final currentLabel = context.currentLabel;
    if (currentLabel == null) return false;
    final normalized = _normalizeConditionValue(currentLabel);
    return values.any(
      (candidate) => _normalizeConditionValue(candidate) == normalized,
    );
  }
}

class _HasActiveNodesCondition extends LayoutCondition {
  const _HasActiveNodesCondition({super.exclude = const {}}) : super._();

  @override
  bool isActive(LayoutContext context) {
    final excluded = normalizedExclude;
    return context.resolvedActiveNodePaths.any(
      (path) => !excluded.contains(_normalizeLayoutPath(path)),
    );
  }
}

class _HasLabelsInActiveNodesCondition extends LayoutCondition {
  const _HasLabelsInActiveNodesCondition(this.labels) : super._();

  final List<String> labels;

  @override
  bool isActive(LayoutContext context) {
    final normalizedLabels = {
      for (final label in labels) _normalizeConditionValue(label),
    };
    return context.activeNodeLabels.any(
      (label) => normalizedLabels.contains(_normalizeConditionValue(label)),
    );
  }
}

class _HasLabelsInCurrentNodeCondition extends LayoutCondition {
  const _HasLabelsInCurrentNodeCondition(this.labels) : super._();

  final List<String> labels;

  @override
  bool isActive(LayoutContext context) {
    final normalizedLabels = {
      for (final label in labels) _normalizeConditionValue(label),
    };
    return context.currentNodeLabels.any(
      (label) => normalizedLabels.contains(_normalizeConditionValue(label)),
    );
  }
}

class _NoSelectedNodesCondition extends LayoutCondition {
  const _NoSelectedNodesCondition() : super._();

  @override
  bool isActive(LayoutContext context) => context.selectedNodePaths.isEmpty;
}

String _normalizeConditionValue(String value) => value.trim().toLowerCase();

String _normalizeLayoutPath(String path) {
  return path
      .trim()
      .replaceAll(r'\', '/')
      .toLowerCase()
      .replaceAll(RegExp(r'/+'), '/')
      .replaceFirst(RegExp(r'\.md$'), '')
      .replaceFirst(RegExp(r'^/+'), '')
      .replaceFirst(RegExp(r'/+$'), '');
}
