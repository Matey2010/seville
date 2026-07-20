class NodeSearchFilter {
  const NodeSearchFilter({
    this.includeNodesMatching = const [],
    this.excludeNodesMatching = const [],
  });

  final List<NodeSearchParameter> includeNodesMatching;
  final List<NodeSearchParameter> excludeNodesMatching;

  bool get isEmpty =>
      includeNodesMatching.isEmpty && excludeNodesMatching.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is NodeSearchFilter &&
      _sameParameters(includeNodesMatching, other.includeNodesMatching) &&
      _sameParameters(excludeNodesMatching, other.excludeNodesMatching);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(includeNodesMatching),
    Object.hashAll(excludeNodesMatching),
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

enum NodeParameter { name, id, path, title, tag, label }

enum NodeMatchOperator { exact, startsWith, endsWith, contains, regularExpression }

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
