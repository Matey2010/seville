package store

import (
	"context"
	"fmt"
	"sort"
	"strings"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	nodesv1 "github.com/Matey2010/seville/proto/gen/go/seville/nodes/v1"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

// NodeGraph returns a bounded set of canonical Nodes and the connections whose
// endpoints are both in that set. An empty root requests a bounded global view.
func (s *Neo4jStore) NodeGraph(ctx context.Context, rootSlug, search string, depth, limit uint32) (*nodesv1.NodeGraph, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer closeSession(ctx, session)

	slugs := make([]string, 0, limit)
	hasMore := false
	seen := make(map[string]struct{}, limit)
	appendSlugs := func(result neo4j.Result) error {
		for result.Next(ctx) {
			slug, ok := recordString(result.Record(), "slug")
			if !ok || slug == "" {
				continue
			}
			if _, exists := seen[slug]; exists {
				continue
			}
			seen[slug] = struct{}{}
			slugs = append(slugs, slug)
		}
		if err := result.Err(); err != nil {
			return err
		}
		_, err := result.Consume(ctx)
		return err
	}

	if rootSlug == "" {
		// The global overview must include the time plane even when calendar
		// slugs sort after the first page of ordinary Nodes. Sample the full
		// dated range; the response remains bounded by the requested limit.
		if search == "" && limit > 1 {
			result, err := session.Run(ctx, `MATCH (node:Node)
WHERE node.slug IS NOT NULL AND node.temporal_start IS NOT NULL
  AND node.temporal_end_exclusive IS NOT NULL
  AND node.temporal_granularity IN ['year', 'season', 'month', 'week', 'day']
RETURN node.slug AS slug
ORDER BY node.temporal_start, node.slug`, nil)
			if err != nil {
				return nil, fmt.Errorf("query time plane overview: %w", err)
			}
			allDated := make([]string, 0)
			for result.Next(ctx) {
				if slug, ok := recordString(result.Record(), "slug"); ok && slug != "" {
					allDated = append(allDated, slug)
				}
			}
			if err := result.Err(); err != nil {
				return nil, fmt.Errorf("read time plane overview: %w", err)
			}
			if _, err := result.Consume(ctx); err != nil {
				return nil, fmt.Errorf("consume time plane overview: %w", err)
			}
			budget := int(limit) / 2
			if len(allDated) < budget {
				budget = len(allDated)
			}
			for index := 0; index < budget; index++ {
				// Include both chronological endpoints when sampling a long span.
				at := 0
				if budget > 1 {
					at = index * (len(allDated) - 1) / (budget - 1)
				}
				slug := allDated[at]
				if _, exists := seen[slug]; !exists {
					seen[slug] = struct{}{}
					slugs = append(slugs, slug)
				}
			}
			if len(allDated) > budget {
				hasMore = true
			}
		}
		result, err := session.Run(ctx, `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL AND trim(toString(candidate.slug)) <> ''
  AND NOT candidate.slug IN $selected
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
WHERE ($search = '' OR toLower(node.slug) CONTAINS $search
       OR toLower(coalesce(node.title, '')) CONTAINS $search
       OR toLower(coalesce(node.body, '')) CONTAINS $search
       OR any(label IN labels(node) WHERE label <> 'Node' AND toLower(label) CONTAINS $search))
RETURN node.slug AS slug
ORDER BY node.slug
LIMIT $limit`, map[string]any{
			"limit":    int64(limit) + 1,
			"search":   strings.ToLower(strings.TrimSpace(search)),
			"selected": slugs,
		})
		if err != nil {
			return nil, fmt.Errorf("query global Node graph: %w", err)
		}
		if err := appendSlugs(result); err != nil {
			return nil, fmt.Errorf("read global Node graph: %w", err)
		}
		if len(slugs) > int(limit) {
			hasMore = true
			slugs = slugs[:limit]
		}
	} else {
		result, err := session.Run(ctx, `MATCH (node:Node {slug: $slug})
RETURN count(node) AS matches`, map[string]any{"slug": rootSlug})
		if err != nil {
			return nil, fmt.Errorf("query graph root: %w", err)
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, fmt.Errorf("read graph root: %w", err)
			}
			return nil, ErrNodeNotFound
		}
		matches, ok := recordInt64(result.Record(), "matches")
		if _, err := result.Consume(ctx); err != nil {
			return nil, fmt.Errorf("read graph root: %w", err)
		}
		if !ok || matches == 0 {
			return nil, ErrNodeNotFound
		}
		if matches > 1 {
			return nil, ErrAmbiguousNodeSlug
		}
		slugs = append(slugs, rootSlug)
		seen[rootSlug] = struct{}{}
		frontier := []string{rootSlug}
		for level := uint32(0); level < depth && len(frontier) > 0 && len(slugs) < int(limit); level++ {
			result, err := session.Run(ctx, `MATCH (node:Node)-[:LINKS_TO]-(neighbor:Node)
WHERE node.slug IN $frontier AND NOT neighbor.slug IN $seen
  AND neighbor.slug IS NOT NULL
RETURN DISTINCT neighbor.slug AS slug
ORDER BY slug
LIMIT $remaining`, map[string]any{
				"frontier":  frontier,
				"seen":      slugs,
				"remaining": int64(limit) - int64(len(slugs)) + 1,
			})
			if err != nil {
				return nil, fmt.Errorf("query graph neighbors: %w", err)
			}
			start := len(slugs)
			if err := appendSlugs(result); err != nil {
				return nil, fmt.Errorf("read graph neighbors: %w", err)
			}
			if len(slugs) > int(limit) {
				hasMore = true
				slugs = slugs[:limit]
			}
			frontier = slugs[start:]
			if hasMore {
				break
			}
		}
	}

	graph := &nodesv1.NodeGraph{HasMore: hasMore}
	if len(slugs) == 0 {
		return graph, nil
	}
	sort.Strings(slugs)
	result, err := session.Run(ctx, `MATCH (candidate:Node)
WHERE candidate.slug IN $slugs
WITH candidate.slug AS slug, collect(candidate) AS matches
WHERE size(matches) = 1
WITH matches[0] AS node
OPTIONAL MATCH (node)-[:HAS_EMOJI]->(emoji)
WITH node, emoji
ORDER BY emoji.id
WITH node,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body, labels(node) AS labels,
       node.frontmatter_json AS frontmatter_json, node.modified_at AS modified_at,
       properties(node) AS properties, emojis
ORDER BY node.slug`, map[string]any{"slugs": slugs})
	if err != nil {
		return nil, fmt.Errorf("query graph Nodes: %w", err)
	}
	for result.Next(ctx) {
		graph.Nodes = append(graph.Nodes, nodeFromRecord(result.Record()))
	}
	if err := result.Err(); err != nil {
		return nil, fmt.Errorf("read graph Nodes: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return nil, fmt.Errorf("consume graph Nodes: %w", err)
	}
	slugs = slugs[:0]
	for _, node := range graph.Nodes {
		slugs = append(slugs, node.Slug)
	}
	result, err = session.Run(ctx, `MATCH (source:Node)-[connection:LINKS_TO]->(target:Node)
WHERE source.slug IN $slugs AND target.slug IN $slugs
RETURN source.slug AS source, target.slug AS target,
       connection.target_text AS target_text,
       connection.display_text AS display_text,
       connection.kind AS kind, connection.fragment AS fragment
ORDER BY source, target, elementId(connection)`, map[string]any{"slugs": slugs})
	if err != nil {
		return nil, fmt.Errorf("query graph connections: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		target, _ := recordString(record, "target")
		targetText, _ := recordString(record, "target_text")
		connection := &nodev2.NodeConnection{
			SourceNodeSlug: source, TargetNodeSlug: &target, TargetText: targetText,
		}
		if value, ok := recordString(record, "display_text"); ok {
			connection.DisplayText = &value
		}
		if value, ok := recordString(record, "fragment"); ok {
			connection.Fragment = &value
		}
		if value, ok := record.Get("kind"); ok {
			if kind, ok := value.(int64); ok {
				connection.Kind = nodev2.NodeConnectionKind(kind)
			}
		}
		graph.Connections = append(graph.Connections, connection)
	}
	if err := result.Err(); err != nil {
		return nil, fmt.Errorf("read graph connections: %w", err)
	}
	if _, err := result.Consume(ctx); err != nil {
		return nil, fmt.Errorf("consume graph connections: %w", err)
	}
	return graph, nil
}
