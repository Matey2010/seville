package store

import (
	"context"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/Matey2010/seville/backend/internal/scanner"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

// UpdateNodeBody applies a Markdown edit and replaces its outgoing connections
// in one transaction. The open editor supplies the last observed update count.
func (s *Neo4jStore) UpdateNodeBody(ctx context.Context, id, body string, expectedCount uint64) (*nodev2.Node, error) {
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `MATCH (node {id: $id})
WHERE node.slug IS NOT NULL AND NOT node:Tag AND NOT node:Emoji
RETURN node.path AS path, coalesce(toInteger(node.update_count), 0) AS update_count`, map[string]any{"id": id})
		if err != nil {
			return nil, err
		}
		if !result.Next(ctx) {
			if err := result.Err(); err != nil {
				return nil, err
			}
			return nil, ErrNodeNotFound
		}
		sourcePath, _ := recordString(result.Record(), "path")
		currentCount, _ := recordInt64(result.Record(), "update_count")
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if currentCount < 0 || uint64(currentCount) != expectedCount {
			return nil, ErrNodeConflict
		}
		result, err = tx.Run(ctx, `MATCH (node {id: $id})
WHERE coalesce(toInteger(node.update_count), 0) = $expected
SET node.body = $body, node.modified_at = $modified_at,
    node.update_count = $expected + 1
RETURN node.id AS id`, map[string]any{
			"id": id, "expected": int64(expectedCount),
			"body": body, "modified_at": time.Now().UTC().UnixNano(),
		})
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
		if err := replaceOutgoingConnections(ctx, tx, id, sourcePath, body); err != nil {
			return nil, err
		}
		return nodeByIDInTransaction(ctx, tx, id)
	})
	if err != nil {
		return nil, fmt.Errorf("update Node body: %w", err)
	}
	return value.(*nodev2.Node), nil
}

// This is shared by Node creation and body editing. An unresolved or ambiguous
// target stays represented in Neo4j instead of becoming a misleading edge.
func replaceOutgoingConnections(ctx context.Context, tx neo4j.ManagedTransaction, id, sourcePath, body string) error {
	connections := scanner.ExtractConnections(id, body)
	for _, connection := range connections {
		targetText := strings.TrimSpace(strings.TrimSuffix(connection.TargetText, ".md"))
		relative := targetText
		if sourcePath != "" && !strings.HasPrefix(targetText, "/") {
			relative = path.Clean(path.Join(path.Dir(sourcePath), targetText))
		}
		result, err := tx.Run(ctx, `MATCH (target)
WHERE target.id IS NOT NULL AND target.slug IS NOT NULL
  AND NOT target:Tag AND NOT target:Emoji
  AND (toLower(target.slug) = toLower($target)
       OR toLower(target.path) IN [toLower($target), toLower($target_md),
                                   toLower($relative), toLower($relative_md)])
RETURN DISTINCT target.id AS id
LIMIT 2`, map[string]any{
			"target": targetText, "target_md": targetText + ".md",
			"relative": relative, "relative_md": relative + ".md",
		})
		if err != nil {
			return err
		}
		var matches []string
		for result.Next(ctx) {
			if candidate, ok := recordString(result.Record(), "id"); ok {
				matches = append(matches, candidate)
			}
		}
		if err := result.Err(); err != nil {
			return err
		}
		if _, err := result.Consume(ctx); err != nil {
			return err
		}
		if len(matches) == 1 {
			connection.TargetNodeId = &matches[0]
		}
	}
	for _, cypher := range []string{
		`MATCH (source {id: $id})-[connection:LINKS_TO]->() DELETE connection`,
		`MATCH (source {id: $id})-[:HAS_UNRESOLVED_LINK]->(missing:SevilleUnresolvedLink) DETACH DELETE missing`,
	} {
		result, err := tx.Run(ctx, cypher, map[string]any{"id": id})
		if err != nil {
			return err
		}
		if _, err := result.Consume(ctx); err != nil {
			return err
		}
	}
	for index, connection := range connections {
		params := map[string]any{
			"source": id, "index": index,
			"target_text":  connection.TargetText,
			"display_text": stringValue(connection.DisplayText),
			"fragment":     stringValue(connection.Fragment),
			"kind":         int64(connection.Kind),
		}
		cypher := `MATCH (source {id: $source})
CREATE (missing:SevilleUnresolvedLink {
  source: $source, index: $index, target_text: $target_text,
  display_text: $display_text, fragment: $fragment, kind: $kind
})
CREATE (source)-[:HAS_UNRESOLVED_LINK]->(missing)`
		if connection.TargetNodeId != nil {
			params["target"] = *connection.TargetNodeId
			cypher = `MATCH (source {id: $source}), (target {id: $target})
CREATE (source)-[:LINKS_TO {
  index: $index, target_text: $target_text,
  display_text: $display_text, fragment: $fragment, kind: $kind
}]->(target)`
		}
		result, err := tx.Run(ctx, cypher, params)
		if err != nil {
			return err
		}
		if _, err := result.Consume(ctx); err != nil {
			return err
		}
	}
	return nil
}

// A newly created Node can resolve older [[slug]] references without another
// source import. Ambiguous slugs or paths remain unresolved for manual review.
func resolveInboundUnresolvedForNode(ctx context.Context, tx neo4j.ManagedTransaction, id, slug string) error {
	result, err := tx.Run(ctx, `MATCH (candidate)
WHERE candidate.id IS NOT NULL AND candidate.slug IS NOT NULL
  AND NOT candidate:Tag AND NOT candidate:Emoji
  AND (toLower(candidate.slug) = toLower($slug)
       OR toLower(candidate.path) IN [toLower($slug), toLower($slug_md)])
WITH count(candidate) AS matches
WHERE matches = 1
MATCH (source)-[:HAS_UNRESOLVED_LINK]->(missing:SevilleUnresolvedLink)
MATCH (target {id: $id})
WHERE toLower(missing.target_text) = toLower($slug)
CREATE (source)-[:LINKS_TO {
  index: missing.index, target_text: missing.target_text,
  display_text: missing.display_text, fragment: missing.fragment,
  kind: missing.kind
}]->(target)
DETACH DELETE missing`, map[string]any{
		"id": id, "slug": slug, "slug_md": slug + ".md",
	})
	if err != nil {
		return err
	}
	_, err = result.Consume(ctx)
	return err
}

func nodeByIDInTransaction(ctx context.Context, tx neo4j.ManagedTransaction, id string) (*nodev2.Node, error) {
	result, err := tx.Run(ctx, `MATCH (node {id: $id})
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
       node.frontmatter_json AS frontmatter_json,
       node.modified_at AS modified_at, properties(node) AS properties, emojis`, map[string]any{"id": id})
	if err != nil {
		return nil, err
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			return nil, err
		}
		return nil, ErrNodeNotFound
	}
	node := nodeFromRecord(result.Record())
	if _, err := result.Consume(ctx); err != nil {
		return nil, err
	}
	return node, nil
}
