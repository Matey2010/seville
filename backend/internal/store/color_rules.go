package store

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	presentationv1 "github.com/Matey2010/seville/proto/gen/go/seville/presentation/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

var colorHexPattern = regexp.MustCompile(`^#[0-9A-Fa-f]{6}$`)

const maxColorRules = 100

// NodeColorRules reads one shared presentation ruleset. These settings are
// separate from canonical Nodes and survive a full Neo4j database transfer.
func (s *Neo4jStore) NodeColorRules(ctx context.Context) (*presentationv1.NodeColorRuleSet, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)

	result, err := session.Run(ctx, `OPTIONAL MATCH (settings:ObsivilianColorRuleSet {key: 'global'})
OPTIONAL MATCH (settings)-[:HAS_COLOR_RULE]->(rule:ObsivilianColorRule)
RETURN coalesce(settings.revision, 0) AS revision,
       rule.name AS name, rule.enabled AS enabled, rule.weight AS weight,
       rule.field AS field, rule.operator AS operator, rule.value AS value,
       rule.frontmatter_key AS frontmatter_key, rule.color_hex AS color_hex
ORDER BY rule.position`, nil)
	if err != nil {
		return nil, fmt.Errorf("query Node color rules: %w", err)
	}
	rules := &presentationv1.NodeColorRuleSet{}
	for result.Next(ctx) {
		record := result.Record()
		revision, ok := recordInt64(record, "revision")
		if !ok || revision < 0 {
			return nil, fmt.Errorf("stored Node color rule revision is invalid")
		}
		rules.Revision = uint64(revision)
		if nameValue, _ := record.Get("name"); nameValue == nil {
			continue
		}
		name, _ := recordString(record, "name")
		weight, ok := recordInt64(record, "weight")
		if !ok {
			return nil, fmt.Errorf("stored Node color rule weight is invalid")
		}
		field, ok := recordInt64(record, "field")
		if !ok {
			return nil, fmt.Errorf("stored Node color rule field is invalid")
		}
		operator, ok := recordInt64(record, "operator")
		if !ok {
			return nil, fmt.Errorf("stored Node color rule operator is invalid")
		}
		enabled, ok := record.Get("enabled")
		if !ok {
			return nil, fmt.Errorf("stored Node color rule enabled state is missing")
		}
		enabledBool, ok := enabled.(bool)
		if !ok {
			return nil, fmt.Errorf("stored Node color rule enabled state is invalid")
		}
		value, _ := recordString(record, "value")
		frontmatterKey, _ := recordString(record, "frontmatter_key")
		colorHex, _ := recordString(record, "color_hex")
		rules.Rules = append(rules.Rules, &presentationv1.NodeColorRule{
			Name: name, Enabled: enabledBool, Weight: int32(weight),
			Field:    presentationv1.ColorRuleField(field),
			Operator: presentationv1.ColorRuleOperator(operator),
			Value:    value, FrontmatterKey: frontmatterKey, ColorHex: colorHex,
		})
	}
	if err := result.Err(); err != nil {
		return nil, fmt.Errorf("read Node color rules: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return nil, fmt.Errorf("consume Node color rules: %w", err)
	}
	return rules, nil
}

// ReplaceNodeColorRules atomically replaces the shared ruleset if its revision
// still matches the version that the editor opened.
func (s *Neo4jStore) ReplaceNodeColorRules(ctx context.Context, request *presentationv1.NodeColorRuleSet) (*presentationv1.NodeColorRuleSet, error) {
	normalized, err := normalizeColorRules(request)
	if err != nil {
		return nil, err
	}
	if request.GetRevision() > 1<<63-2 {
		return nil, fmt.Errorf("%w: revision is out of range", ErrInvalidColorRules)
	}
	rows := make([]map[string]any, 0, len(normalized))
	for position, rule := range normalized {
		rows = append(rows, map[string]any{
			"position": position, "name": rule.Name, "enabled": rule.Enabled,
			"weight": int64(rule.Weight), "field": int64(rule.Field),
			"operator": int64(rule.Operator), "value": rule.Value,
			"frontmatter_key": rule.FrontmatterKey, "color_hex": rule.ColorHex,
		})
	}

	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `MERGE (settings:ObsivilianColorRuleSet {key: 'global'})
ON CREATE SET settings.revision = 0
SET settings.revision = settings.revision + 1
WITH settings WHERE settings.revision = $next_revision
RETURN settings.revision AS revision`, map[string]any{
			"next_revision": int64(request.GetRevision() + 1),
		})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrColorRulesConflict
		}
		revision, ok := recordInt64(result.Record(), "revision")
		if !ok {
			return nil, fmt.Errorf("updated Node color rule revision is invalid")
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}

		result, err = tx.Run(ctx, `MATCH (:ObsivilianColorRuleSet {key: 'global'})-[:HAS_COLOR_RULE]->(rule:ObsivilianColorRule)
DETACH DELETE rule`, nil)
		if err != nil {
			return nil, err
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		result, err = tx.Run(ctx, `MATCH (settings:ObsivilianColorRuleSet {key: 'global'})
UNWIND $rules AS row
CREATE (rule:ObsivilianColorRule {
  position: row.position, name: row.name, enabled: row.enabled,
  weight: row.weight, field: row.field, operator: row.operator,
  value: row.value, frontmatter_key: row.frontmatter_key,
  color_hex: row.color_hex
})
CREATE (settings)-[:HAS_COLOR_RULE]->(rule)`, map[string]any{"rules": rows})
		if err != nil {
			return nil, err
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		return revision, nil
	})
	if err != nil {
		return nil, fmt.Errorf("replace Node color rules: %w", err)
	}
	return &presentationv1.NodeColorRuleSet{Revision: uint64(value.(int64)), Rules: normalized}, nil
}

func normalizeColorRules(request *presentationv1.NodeColorRuleSet) ([]*presentationv1.NodeColorRule, error) {
	if request == nil || len(request.Rules) > maxColorRules {
		return nil, fmt.Errorf("%w: at most %d rules are allowed", ErrInvalidColorRules, maxColorRules)
	}
	normalized := make([]*presentationv1.NodeColorRule, 0, len(request.Rules))
	for index, rule := range request.Rules {
		if rule == nil {
			return nil, fmt.Errorf("%w: rule %d is missing", ErrInvalidColorRules, index+1)
		}
		name := strings.TrimSpace(rule.GetName())
		value := strings.TrimSpace(rule.GetValue())
		key := strings.TrimSpace(rule.GetFrontmatterKey())
		color := strings.ToUpper(strings.TrimSpace(rule.GetColorHex()))
		if name == "" || len(name) > 80 || value == "" || len(value) > 256 ||
			rule.GetWeight() < -10000 || rule.GetWeight() > 10000 || !colorHexPattern.MatchString(color) {
			return nil, fmt.Errorf("%w: rule %d has an invalid name, value, weight, or color", ErrInvalidColorRules, index+1)
		}
		switch rule.GetField() {
		case presentationv1.ColorRuleField_COLOR_RULE_FIELD_ID,
			presentationv1.ColorRuleField_COLOR_RULE_FIELD_LABEL,
			presentationv1.ColorRuleField_COLOR_RULE_FIELD_TAG,
			presentationv1.ColorRuleField_COLOR_RULE_FIELD_SLUG,
			presentationv1.ColorRuleField_COLOR_RULE_FIELD_TITLE:
			key = ""
		case presentationv1.ColorRuleField_COLOR_RULE_FIELD_FRONTMATTER:
			if key == "" || len(key) > 80 {
				return nil, fmt.Errorf("%w: rule %d requires a frontmatter key", ErrInvalidColorRules, index+1)
			}
		default:
			return nil, fmt.Errorf("%w: rule %d has an unsupported field", ErrInvalidColorRules, index+1)
		}
		switch rule.GetOperator() {
		case presentationv1.ColorRuleOperator_COLOR_RULE_OPERATOR_EXACT,
			presentationv1.ColorRuleOperator_COLOR_RULE_OPERATOR_CONTAINS,
			presentationv1.ColorRuleOperator_COLOR_RULE_OPERATOR_STARTS_WITH:
		default:
			return nil, fmt.Errorf("%w: rule %d has an unsupported operator", ErrInvalidColorRules, index+1)
		}
		normalized = append(normalized, &presentationv1.NodeColorRule{
			Name: name, Enabled: rule.GetEnabled(), Weight: rule.GetWeight(),
			Field: rule.GetField(), Operator: rule.GetOperator(), Value: value,
			FrontmatterKey: key, ColorHex: color,
		})
	}
	return normalized, nil
}
