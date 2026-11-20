package store

import (
	"context"
	"fmt"
	"path"
	"strings"
	"time"

	"github.com/Matey2010/seville/backend/internal/markdown"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
)

// UpdateNodeBody applies a Markdown edit and replaces its outgoing connections
// in one transaction. The open editor supplies the last observed update count.
func (s *Neo4jStore) UpdateNodeBody(ctx context.Context, slug, body string, expectedCount uint64) (*nodev2.Node, error) {
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	value, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		result, err := tx.Run(ctx, `MATCH (node:Node {slug: $slug})
RETURN node.path AS path, coalesce(toInteger(node.update_count), 0) AS update_count`, map[string]any{"slug": slug})
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
		if result.Next(ctx) {
			return nil, ErrAmbiguousNodeSlug
		}
		if _, err := result.Consume(ctx); err != nil {
			return nil, err
		}
		if currentCount < 0 || uint64(currentCount) != expectedCount {
			return nil, ErrNodeConflict
		}
		result, err = tx.Run(ctx, `MATCH (node:Node {slug: $slug})
WHERE coalesce(toInteger(node.update_count), 0) = $expected
SET node.body = $body, node.modified_at = $modified_at,
    node.update_count = $expected + 1
RETURN node.slug AS slug`, map[string]any{
			"slug": slug, "expected": int64(expectedCount),
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
		if err := replaceOutgoingConnections(ctx, tx, slug, sourcePath, body); err != nil {
			return nil, err
		}
		return nodeBySlugInTransaction(ctx, tx, slug)
	})
	if err != nil {
		return nil, fmt.Errorf("update Node body: %w", err)
	}
	return value.(*nodev2.Node), nil
}

// This is shared by Node creation and body editing. An unresolved or ambiguous
// target stays represented in Neo4j instead of becoming a misleading edge.
func replaceOutgoingConnections(ctx context.Context, tx neo4j.ManagedTransaction, slug, sourcePath, body string) error {
	connections := markdown.ExtractConnections(slug, body)
	for _, connection := range connections {
		targetText := strings.TrimSpace(strings.TrimSuffix(connection.TargetText, ".md"))
		relative := targetText
		if sourcePath != "" && !strings.HasPrefix(targetText, "/") {
			relative = path.Clean(path.Join(path.Dir(sourcePath), targetText))
		}
		result, err := tx.Run(ctx, `MATCH (target:Node)
WHERE target.slug IS NOT NULL
  AND (toLower(target.slug) = toLower($target)
       OR toLower(target.path) IN [toLower($target), toLower($target_md),
                                   toLower($relative), toLower($relative_md)])
RETURN target.slug AS slug
LIMIT 2`, map[string]any{
			"target": targetText, "target_md": targetText + ".md",
			"relative": relative, "relative_md": relative + ".md",
		})
		if err != nil {
			return err
		}
		var matches []string
		for result.Next(ctx) {
			if candidate, ok := recordString(result.Record(), "slug"); ok {
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
			connection.TargetNodeSlug = &matches[0]
		}
	}
	for _, cypher := range []string{
		`MATCH (source:Node {slug: $slug})-[connection:LINKS_TO]->() DELETE connection`,
		`MATCH (source:Node {slug: $slug})-[:HAS_UNRESOLVED_LINK]->(missing:SevilleUnresolvedLink) DETACH DELETE missing`,
	} {
		result, err := tx.Run(ctx, cypher, map[string]any{"slug": slug})
		if err != nil {
			return err
		}
		if _, err := result.Consume(ctx); err != nil {
			return err
		}
	}
	for index, connection := range connections {
		params := map[string]any{
			"source": slug, "index": index,
			"target_text":  connection.TargetText,
			"display_text": stringValue(connection.DisplayText),
			"fragment":     stringValue(connection.Fragment),
			"kind":         int64(connection.Kind),
		}
		cypher := `MATCH (source:Node {slug: $source})
CREATE (missing:SevilleUnresolvedLink {
  source: $source, index: $index, target_text: $target_text,
  display_text: $display_text, fragment: $fragment, kind: $kind
})
CREATE (source)-[:HAS_UNRESOLVED_LINK]->(missing)`
		if connection.TargetNodeSlug != nil {
			params["target"] = *connection.TargetNodeSlug
			cypher = `MATCH (source:Node {slug: $source}), (target:Node {slug: $target})
WITH source, collect(target) AS matches
WHERE size(matches) = 1
WITH source, matches[0] AS target
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
func resolveInboundUnresolvedForNode(ctx context.Context, tx neo4j.ManagedTransaction, slug string) error {
	result, err := tx.Run(ctx, `MATCH (candidate:Node)
WHERE candidate.slug IS NOT NULL
  AND (toLower(candidate.slug) = toLower($slug)
       OR toLower(candidate.path) IN [toLower($slug), toLower($slug_md)])
WITH count(candidate) AS matches
WHERE matches = 1
MATCH (source)-[:HAS_UNRESOLVED_LINK]->(missing:SevilleUnresolvedLink)
MATCH (target:Node {slug: $slug})
WHERE toLower(missing.target_text) = toLower($slug)
CREATE (source)-[:LINKS_TO {
  index: missing.index, target_text: missing.target_text,
  display_text: missing.display_text, fragment: missing.fragment,
  kind: missing.kind
}]->(target)
DETACH DELETE missing`, map[string]any{
		"slug": slug, "slug_md": slug + ".md",
	})
	if err != nil {
		return err
	}
	_, err = result.Consume(ctx)
	return err
}

func nodeBySlugInTransaction(ctx context.Context, tx neo4j.ManagedTransaction, slug string) (*nodev2.Node, error) {
	result, err := tx.Run(ctx, `MATCH (node:Node {slug: $slug})
WITH node
OPTIONAL MATCH (node)-[:HAS_EMOJI]->(emoji)
WITH node, emoji
ORDER BY emoji.id
WITH node,
     [emojiProperties IN collect(properties(emoji)) WHERE emojiProperties IS NOT NULL] AS emojis
RETURN node.slug AS slug, node.path AS path,
       node.title AS title, node.body AS body, labels(node) AS labels,
       node.frontmatter_json AS frontmatter_json,
       node.modified_at AS modified_at, properties(node) AS properties, emojis`, map[string]any{"slug": slug})
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
	if result.Next(ctx) {
		return nil, ErrAmbiguousNodeSlug
	}
	if _, err := result.Consume(ctx); err != nil {
		return nil, err
	}
	return node, nil
}
