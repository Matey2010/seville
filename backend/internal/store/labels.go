package store

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

func validLabel(raw string) (string, error) {
	label := strings.TrimSpace(raw)
	if len(label) == 0 || len(label) > 80 || !neo4jNodeLabelPattern.MatchString(label) {
		return "", fmt.Errorf("%w: %q must match %s and be at most 80 characters", ErrInvalidLabel, raw, neo4jNodeLabelPattern)
	}
	if label == "Node" {
		return "", fmt.Errorf("%w: Node is reserved for canonical records", ErrInvalidLabel)
	}
	return label, nil
}

func normalizeLabels(raw []string) ([]string, error) {
	if len(raw) > 64 {
		return nil, fmt.Errorf("%w: at most 64 labels are allowed", ErrInvalidLabel)
	}
	seen := make(map[string]bool, len(raw))
	labels := make([]string, 0, len(raw))
	for _, value := range raw {
		label, err := validLabel(value)
		if err != nil {
			return nil, err
		}
		if !seen[label] {
			seen[label] = true
			labels = append(labels, label)
		}
	}
	sort.Strings(labels)
	return labels, nil
}

// Labels are Neo4j labels on canonical Nodes. There is no separate label entity.
func (s *Neo4jStore) SearchLabels(ctx context.Context, prefix string, limit uint32) (*nodesv1.LabelSearchResult, error) {
	if limit == 0 || limit > 200 {
		return nil, ErrInvalidLabel
	}
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
	result, err := session.Run(ctx, `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
UNWIND labels(node) AS label
WITH label, node WHERE label <> 'Node'
WITH label, count(*) AS node_count
WHERE toLower(label) STARTS WITH toLower($prefix)
RETURN label AS name, node_count
ORDER BY toLower(label), label
LIMIT $limit`, map[string]any{"prefix": strings.TrimSpace(prefix), "limit": int64(limit)})
	if err != nil {
		return nil, err
	}
	response := &nodesv1.LabelSearchResult{}
	for result.Next(ctx) {
		name, _ := recordString(result.Record(), "name")
		count, _ := recordInt64(result.Record(), "node_count")
		response.Labels = append(response.Labels, &nodesv1.LabelSummary{Name: name, NodeCount: uint64(count)})
	}
	if err := result.Err(); err != nil {
		return nil, err
	}
	_, err = result.Consume(ctx)
	return response, err
}

func (s *Neo4jStore) ReplaceNodeLabels(ctx context.Context, slug string, raw []string, expected uint64) (*nodev2.Node, error) {
	labels, err := normalizeLabels(raw)
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(slug) == "" || expected > 1<<63-2 {
		return nil, ErrInvalidLabel
	}
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `MATCH (node:Node {slug: $slug})
RETURN labels(node) AS labels, coalesce(toInteger(node.update_count), 0) AS update_count`, map[string]any{"slug": slug})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrNodeNotFound
		}
		old := make([]string, 0)
		for _, label := range recordStrings(result.Record(), "labels") {
			if label != "Node" {
				old = append(old, label)
			}
		}
		count, _ := recordInt64(result.Record(), "update_count")
		if result.Next(ctx) {
			return nil, ErrAmbiguousNodeSlug
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if count < 0 || uint64(count) != expected {
			return nil, ErrNodeConflict
		}
		wanted := make(map[string]bool, len(labels))
		for _, label := range labels {
			wanted[label] = true
		}
		present := make(map[string]bool, len(old))
		for _, label := range old {
			present[label] = true
		}
		query := `MATCH (node:Node {slug: $slug}) WHERE coalesce(toInteger(node.update_count), 0) = $expected`
		for _, label := range old {
			if !wanted[label] {
				query += "\nREMOVE node:`" + strings.ReplaceAll(label, "`", "``") + "`"
			}
		}
		for _, label := range labels {
			if !present[label] {
				query += "\nSET node:`" + label + "`"
			}
		}
		query += `
SET node.update_count = $expected + 1, node.modified_at = $modified_at
RETURN node.slug AS slug`
		result, err = tx.Run(ctx, query, map[string]any{"slug": slug, "expected": int64(expected), "modified_at": time.Now().UTC().UnixNano()})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrNodeConflict
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		return nodeBySlugInTransaction(ctx, tx, slug)
	})
	if err != nil {
		return nil, fmt.Errorf("replace Node labels: %w", err)
	}
	return value.(*nodev2.Node), nil
}

func (s *Neo4jStore) RenameLabel(ctx context.Context, oldRaw, newRaw string) (uint64, error) {
	old, err := validLabel(oldRaw)
	if err != nil {
		return 0, err
	}
	newLabel, err := validLabel(newRaw)
	if err != nil {
		return 0, err
	}
	if old == newLabel {
		return 0, ErrLabelConflict
	}
	return s.changeLabel(ctx, old, newLabel)
}

func (s *Neo4jStore) DeleteLabel(ctx context.Context, raw string) (uint64, error) {
	label, err := validLabel(raw)
	if err != nil {
		return 0, err
	}
	return s.changeLabel(ctx, label, "")
}

func (s *Neo4jStore) changeLabel(ctx context.Context, old, replacement string) (uint64, error) {
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		if replacement != "" {
			result, err := tx.Run(ctx, `MATCH (candidate:Node) WHERE candidate.slug IS NOT NULL
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
WHERE $label IN labels(node) RETURN count(node) AS count`, map[string]any{"label": replacement})
			if err != nil {
				return nil, err
			}
			if !result.Next(ctx) {
				return nil, result.Err()
			}
			count, _ := recordInt64(result.Record(), "count")
			if _, err := result.Consume(ctx); err != nil {
				return nil, err
			}
			if count > 0 {
				return nil, ErrLabelConflict
			}
		}
		query := `MATCH (candidate:Node) WHERE candidate.slug IS NOT NULL
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
WHERE $old IN labels(node)
REMOVE node:` + "`" + old + "`"
		if replacement != "" {
			query += "\nSET node:`" + replacement + "`"
		}
		query += `
SET node.update_count = coalesce(toInteger(node.update_count), 0) + 1,
    node.modified_at = $modified_at
RETURN count(node) AS count`
		result, err := tx.Run(ctx, query, map[string]any{"old": old, "modified_at": time.Now().UTC().UnixNano()})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			return nil, result.Err()
		}
		count, _ := recordInt64(result.Record(), "count")
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if count == 0 {
			return nil, ErrLabelNotFound
		}
		// Exact label color rules follow a rename and disappear with a deletion.
		if replacement != "" {
			result, err = tx.Run(ctx, `MATCH (settings:ObsivilianColorRuleSet {key: 'global'})-[:HAS_COLOR_RULE]->(rule:ObsivilianColorRule)
WHERE rule.field = 2 AND rule.operator = 1 AND toLower(rule.value) = toLower($old)
SET rule.value = $replacement, settings.revision = coalesce(settings.revision, 0) + 1
RETURN count(rule) AS count`, map[string]any{"old": old, "replacement": replacement})
		} else {
			result, err = tx.Run(ctx, `MATCH (settings:ObsivilianColorRuleSet {key: 'global'})-[:HAS_COLOR_RULE]->(rule:ObsivilianColorRule)
WHERE rule.field = 2 AND rule.operator = 1 AND toLower(rule.value) = toLower($old)
SET settings.revision = coalesce(settings.revision, 0) + 1
DETACH DELETE rule`, map[string]any{"old": old})
		}
		if err != nil {
			return nil, err
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		return uint64(count), nil
	})
	if err != nil {
		return 0, fmt.Errorf("change label: %w", err)
	}
	return value.(uint64), nil
}
