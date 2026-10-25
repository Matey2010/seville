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
func (s *Neo4jStore) NodeGraph(ctx context.Context, rootID, search string, depth, limit uint32) (*nodesv1.NodeGraph, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)

	ids := make([]string, 0, limit)
	hasMore := false
	seen := make(map[string]struct{}, limit)
	appendIDs := func(result neo4j.Result) error {
		for result.Next(ctx) {
			id, ok := recordString(result.Record(), "id")
			if !ok || id == "" {
				continue
			}
			if _, exists := seen[id]; exists {
				continue
			}
			seen[id] = struct{}{}
			ids = append(ids, id)
		}
		if err := result.Err(); err != nil {
			return err
		}
		_, err := result.Consume(ctx)
		return err
	}

	if rootID == "" {
		result, err := session.Run(ctx, `MATCH (node)
WHERE node.id IS NOT NULL AND node.slug IS NOT NULL
  AND NOT node:Tag AND NOT node:Emoji
  AND ($search = '' OR toLower(node.slug) CONTAINS $search
       OR toLower(coalesce(node.title, '')) CONTAINS $search
       OR toLower(coalesce(node.body, '')) CONTAINS $search
       OR any(label IN labels(node) WHERE toLower(label) CONTAINS $search)
       OR any(tag IN coalesce(node.tags, []) WHERE toLower(tag) CONTAINS $search)
       OR EXISTS { MATCH (node)-[:TAGGED_WITH]->(tag:Tag)
                   WHERE toLower(tag.id) CONTAINS $search })
RETURN node.id AS id
ORDER BY node.slug, node.id
LIMIT $limit`, map[string]any{
			"limit":  int64(limit) + 1,
			"search": strings.ToLower(strings.TrimSpace(search)),
		})
		if err != nil {
			return nil, fmt.Errorf("query global Node graph: %w", err)
		}
		if err := appendIDs(result); err != nil {
			return nil, fmt.Errorf("read global Node graph: %w", err)
		}
		if len(ids) > int(limit) {
			hasMore = true
			ids = ids[:limit]
		}
	} else {
		result, err := session.Run(ctx, `MATCH (node {id: $id})
WHERE node.slug IS NOT NULL AND NOT node:Tag AND NOT node:Emoji
RETURN node.id AS id LIMIT 1`, map[string]any{"id": rootID})
		if err != nil {
			return nil, fmt.Errorf("query graph root: %w", err)
		}
		if err := appendIDs(result); err != nil {
			return nil, fmt.Errorf("read graph root: %w", err)
		}
		if len(ids) == 0 {
			return nil, ErrNodeNotFound
		}
		frontier := []string{rootID}
		for level := uint32(0); level < depth && len(frontier) > 0 && len(ids) < int(limit); level++ {
			result, err := session.Run(ctx, `MATCH (node)-[:LINKS_TO]-(neighbor)
WHERE node.id IN $frontier AND NOT neighbor.id IN $seen
  AND neighbor.id IS NOT NULL
  AND neighbor.slug IS NOT NULL AND NOT neighbor:Tag AND NOT neighbor:Emoji
RETURN DISTINCT neighbor.id AS id
ORDER BY id
LIMIT $remaining`, map[string]any{
				"frontier":  frontier,
				"seen":      ids,
				"remaining": int64(limit) - int64(len(ids)) + 1,
			})
			if err != nil {
				return nil, fmt.Errorf("query graph neighbors: %w", err)
			}
			start := len(ids)
			if err := appendIDs(result); err != nil {
				return nil, fmt.Errorf("read graph neighbors: %w", err)
			}
			if len(ids) > int(limit) {
				hasMore = true
				ids = ids[:limit]
			}
			frontier = ids[start:]
			if hasMore {
				break
			}
		}
	}

	graph := &nodesv1.NodeGraph{HasMore: hasMore}
	if len(ids) == 0 {
		return graph, nil
	}
	sort.Strings(ids)
	result, err := session.Run(ctx, `MATCH (node)
WHERE node.id IN $ids
OPTIONAL MATCH (node)-[:TAGGED_WITH]->(tag:Tag)
WITH node, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
OPTIONAL MATCH (node)-[:HAS_EMOJI]->(emoji)
WITH node, graphTags, emoji
ORDER BY emoji.id
WITH node, graphTags,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN node.id AS id, node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body, labels(node) AS labels,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE node.tags END AS tags,
       node.frontmatter_json AS frontmatter_json, node.modified_at AS modified_at,
       properties(node) AS properties, emojis
ORDER BY node.slug, node.id`, map[string]any{"ids": ids})
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
	result, err = session.Run(ctx, `MATCH (source)-[connection:LINKS_TO]->(target)
WHERE source.id IN $ids AND target.id IN $ids
RETURN source.id AS source, target.id AS target,
       connection.target_text AS target_text,
       connection.display_text AS display_text,
       connection.kind AS kind, connection.fragment AS fragment
ORDER BY source, target, elementId(connection)`, map[string]any{"ids": ids})
	if err != nil {
		return nil, fmt.Errorf("query graph connections: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		target, _ := recordString(record, "target")
		targetText, _ := recordString(record, "target_text")
		connection := &nodev2.NodeConnection{
			SourceNodeId: source, TargetNodeId: &target, TargetText: targetText,
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
