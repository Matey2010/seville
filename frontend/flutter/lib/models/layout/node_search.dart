part of 'layout.dart';

class NodeSearchFilter {
  /// Accepts a Node when any matching parameter succeeds and no exclusion does.
  const NodeSearchFilter.anyOf(
    List<NodeSearchParameter> matching, {
    List<NodeSearchParameter> excluding = const [],
  }) : _includeNodesMatching = matching,
       _excludeNodesMatching = excluding,
       _includeMatchMode = NodeSearchMatchMode.any,
       _negated = false,
       _source = null;

  /// Accepts a Node when every matching parameter succeeds and no exclusion does.
  const NodeSearchFilter.allOf(
    List<NodeSearchParameter> matching, {
    List<NodeSearchParameter> excluding = const [],
  }) : _includeNodesMatching = matching,
       _excludeNodesMatching = excluding,
       _includeMatchMode = NodeSearchMatchMode.all,
       _negated = false,
       _source = null;

  /// Const-safe logical complement of [source].
  const NodeSearchFilter.reverseOf(NodeSearchFilter source)
    : _includeNodesMatching = const [],
      _excludeNodesMatching = const [],
      _includeMatchMode = NodeSearchMatchMode.any,
      _negated = false,
      _source = source;

  const NodeSearchFilter._(
    this._includeNodesMatching,
    this._excludeNodesMatching,
    this._includeMatchMode,
    this._negated,
  ) : _source = null;

  final List<NodeSearchParameter> _includeNodesMatching;
  final List<NodeSearchParameter> _excludeNodesMatching;
  final NodeSearchMatchMode _includeMatchMode;
  final bool _negated;
  final NodeSearchFilter? _source;

  List<NodeSearchParameter> get includeNodesMatching =>
      _source?.includeNodesMatching ?? _includeNodesMatching;

  List<NodeSearchParameter> get excludeNodesMatching =>
      _source?.excludeNodesMatching ?? _excludeNodesMatching;

  NodeSearchMatchMode get includeMatchMode =>
      _source?.includeMatchMode ?? _includeMatchMode;

  bool get isNegated => _source == null ? _negated : !_source.isNegated;

  bool get isEmpty =>
      !isNegated &&
      includeNodesMatching.isEmpty &&
      excludeNodesMatching.isEmpty;

  /// Returns the logical complement of this filter for runtime composition.
  NodeSearchFilter reversed() => NodeSearchFilter._(
    includeNodesMatching,
    excludeNodesMatching,
    includeMatchMode,
    !isNegated,
  );

  @override
  bool operator ==(Object other) =>
      other is NodeSearchFilter &&
      _sameParameters(includeNodesMatching, other.includeNodesMatching) &&
      _sameParameters(excludeNodesMatching, other.excludeNodesMatching) &&
      includeMatchMode == other.includeMatchMode &&
      isNegated == other.isNegated;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(includeNodesMatching),
    Object.hashAll(excludeNodesMatching),
    includeMatchMode,
    isNegated,
  );
}

class NodeSearchParameter {
  const NodeSearchParameter({
    required this.parameter,
    required this.value,
    this.operator = NodeMatchOperator.exact,
  });

  final NodeParameter parameter;
  final String value;
  final NodeMatchOperator operator;

  @override
  bool operator ==(Object other) =>
      other is NodeSearchParameter &&
      parameter == other.parameter &&
      value == other.value &&
      operator == other.operator;

  @override
  int get hashCode => Object.hash(parameter, value, operator);
}

enum NodeParameter { name, id, path, title, tag, label, slug }

enum NodeMatchOperator {
  exact,
  startsWith,
  endsWith,
  contains,
  regularExpression,
}

enum NodeSearchMatchMode { any, all }

bool _sameParameters(
  List<NodeSearchParameter> left,
  List<NodeSearchParameter> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
