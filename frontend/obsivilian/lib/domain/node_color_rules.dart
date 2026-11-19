import 'package:seville_proto/seville_proto.dart';

/// Resolves presentation colors from canonical Node fields, without changing
/// the graph data or the physics simulation.
NodeColorRule? matchingNodeColorRule(Node node, List<NodeColorRule> rules) {
  NodeColorRule? winner;
  for (final rule in rules) {
    if (!rule.enabled || !_matches(node, rule)) continue;
    if (winner == null || rule.weight > winner.weight) winner = rule;
  }
  return winner;
}

NodeColorRule? matchingLabelColorRule(String label, List<NodeColorRule> rules) {
  NodeColorRule? winner;
  final candidate = label.trim().toLowerCase();
  for (final rule in rules) {
    if (!rule.enabled ||
        rule.field_4 != ColorRuleField.COLOR_RULE_FIELD_LABEL) {
      continue;
    }
    final query = rule.value.trim().toLowerCase();
    if (query.isEmpty) continue;
    final matches = switch (rule.operator) {
      ColorRuleOperator.COLOR_RULE_OPERATOR_EXACT => candidate == query,
      ColorRuleOperator.COLOR_RULE_OPERATOR_CONTAINS => candidate.contains(
        query,
      ),
      ColorRuleOperator.COLOR_RULE_OPERATOR_STARTS_WITH => candidate.startsWith(
        query,
      ),
      _ => false,
    };
    if (matches && (winner == null || rule.weight > winner.weight)) {
      winner = rule;
    }
  }
  return winner;
}

bool _matches(Node node, NodeColorRule rule) {
  final values = switch (rule.field_4) {
    ColorRuleField.COLOR_RULE_FIELD_LABEL => node.labels,
    ColorRuleField.COLOR_RULE_FIELD_SLUG => [node.slug],
    ColorRuleField.COLOR_RULE_FIELD_TITLE => [node.title],
    ColorRuleField.COLOR_RULE_FIELD_FRONTMATTER => [
      for (final entry in node.frontmatter.entries)
        if (entry.key.trim().toLowerCase() ==
            rule.frontmatterKey.trim().toLowerCase())
          entry.value,
    ],
    _ => <String>[],
  };
  final query = rule.value.trim().toLowerCase();
  if (query.isEmpty) return false;
  for (final value in values) {
    final candidate = value.trim().toLowerCase();
    final matches = switch (rule.operator) {
      ColorRuleOperator.COLOR_RULE_OPERATOR_EXACT => candidate == query,
      ColorRuleOperator.COLOR_RULE_OPERATOR_CONTAINS => candidate.contains(
        query,
      ),
      ColorRuleOperator.COLOR_RULE_OPERATOR_STARTS_WITH => candidate.startsWith(
        query,
      ),
      _ => false,
    };
    if (matches) return true;
  }
  return false;
}
