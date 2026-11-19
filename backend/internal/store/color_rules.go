package store

import (
	"context"
	"fmt"
	"math"
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
       rule.frontmatter_key AS frontmatter_key, rule.color_hex AS color_hex,
       rule.gravity_scale AS gravity_scale, rule.size_scale AS size_scale
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
		gravity := 1.0
		if stored, _ := record.Get("gravity_scale"); stored != nil {
			value, ok := stored.(float64)
			if !ok {
				return nil, fmt.Errorf("stored rule gravity scale is invalid")
			}
			gravity = value
		}
		size := 1.0
		if stored, _ := record.Get("size_scale"); stored != nil {
			value, ok := stored.(float64)
			if !ok {
				return nil, fmt.Errorf("stored rule size scale is invalid")
			}
			size = value
		}
		rules.Rules = append(rules.Rules, &presentationv1.NodeColorRule{
			Name: name, Enabled: enabledBool, Weight: int32(weight),
			Field:    presentationv1.ColorRuleField(field),
			Operator: presentationv1.ColorRuleOperator(operator),
			Value:    value, FrontmatterKey: frontmatterKey, ColorHex: colorHex,
			GravityScale: &gravity, SizeScale: &size,
		})
	}
	if err := result.Err(); err != nil {
		return nil, fmt.Errorf("read Node color rules: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return nil, fmt.Errorf("consume Node color rules: %w", err)
	}
	// A legacy exact ID rule can be represented by the same Node's slug.
	// Other ID match operators cannot be translated without changing meaning.
	converted := make([]*presentationv1.NodeColorRule, 0, len(rules.Rules))
	for _, rule := range rules.Rules {
		if rule.Field != presentationv1.ColorRuleField(1) {
			converted = append(converted, rule)
			continue
		}
		if rule.Operator != presentationv1.ColorRuleOperator_COLOR_RULE_OPERATOR_EXACT {
			continue
		}
		match, err := session.Run(ctx, `MATCH (node:Node {id: $legacy_id})
WHERE node.slug IS NOT NULL AND trim(toString(node.slug)) <> ''
RETURN node.slug AS slug LIMIT 2`, map[string]any{"legacy_id": rule.Value})
		if err != nil {
			return nil, fmt.Errorf("resolve legacy ID color rule: %w", err)
		}
		var slug string
		matches := 0
		for match.Next(ctx) {
			slug, _ = recordString(match.Record(), "slug")
			matches++
		}
		if err := match.Err(); err != nil {
			return nil, fmt.Errorf("read legacy ID color rule: %w", err)
		}
		if _, err := match.Consume(ctx); err != nil {
			return nil, fmt.Errorf("consume legacy ID color rule: %w", err)
		}
		if matches != 1 || slug == "" {
			continue
		}
		unique, err := session.Run(ctx, `MATCH (node:Node {slug: $slug}) RETURN count(node) AS copies`, map[string]any{"slug": slug})
		if err != nil {
			return nil, fmt.Errorf("check legacy rule slug: %w", err)
		}
		if !unique.Next(ctx) {
			return nil, fmt.Errorf("check legacy rule slug: no result")
		}
		copies, _ := recordInt64(unique.Record(), "copies")
		if _, err := unique.Consume(ctx); err != nil {
			return nil, fmt.Errorf("consume legacy rule slug: %w", err)
		}
		if copies == 1 {
			rule.Field = presentationv1.ColorRuleField_COLOR_RULE_FIELD_SLUG
			rule.Value = slug
			converted = append(converted, rule)
		}
	}
	rules.Rules = converted
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
			"gravity_scale": rule.GetGravityScale(), "size_scale": rule.GetSizeScale(),
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
  color_hex: row.color_hex, gravity_scale: row.gravity_scale,
  size_scale: row.size_scale
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
		gravity := 1.0
		if rule.GravityScale != nil {
			gravity = rule.GetGravityScale()
		}
		size := 1.0
		if rule.SizeScale != nil {
			size = rule.GetSizeScale()
		}
		if name == "" || len(name) > 80 || value == "" || len(value) > 256 ||
			rule.GetWeight() < -10000 || rule.GetWeight() > 10000 || !colorHexPattern.MatchString(color) ||
			math.IsNaN(gravity) || math.IsInf(gravity, 0) || gravity < 0 || gravity > 3 ||
			math.IsNaN(size) || math.IsInf(size, 0) || size < 0.5 || size > 2 {
			return nil, fmt.Errorf("%w: rule %d has an invalid name, value, weight, color, gravity, or size", ErrInvalidColorRules, index+1)
		}
		switch rule.GetField() {
		case presentationv1.ColorRuleField_COLOR_RULE_FIELD_LABEL,
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
			GravityScale: &gravity, SizeScale: &size,
		})
	}
	return normalized, nil
}
