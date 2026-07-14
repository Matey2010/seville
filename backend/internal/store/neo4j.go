package store

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
	"github.com/neo4j/neo4j-go-driver/v6/neo4j"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type Neo4jStore struct {
	driver   neo4j.Driver
	database string
}

func OpenNeo4j(ctx context.Context, uri, username, password, database string) (*Neo4jStore, error) {
	driver, err := neo4j.NewDriver(uri, neo4j.BasicAuth(username, password, ""))
	if err != nil {
		return nil, fmt.Errorf("create neo4j driver: %w", err)
	}
	if err := waitForConnectivity(ctx, driver, 30*time.Second); err != nil {
		driver.Close(ctx)
		return nil, fmt.Errorf("connect neo4j: %w", err)
	}
	store := &Neo4jStore{driver: driver, database: database}
	if err := store.migrate(ctx); err != nil {
		driver.Close(ctx)
		return nil, err
	}
	return store, nil
}

func waitForConnectivity(ctx context.Context, driver neo4j.Driver, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	var lastErr error
	for {
		if err := driver.VerifyConnectivity(ctx); err == nil {
			return nil
		} else {
			lastErr = err
		}
		if time.Now().After(deadline) {
			return lastErr
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(time.Second):
		}
	}
}

func (s *Neo4jStore) Close() error {
	return s.driver.Close(context.Background())
}

func (s *Neo4jStore) session(ctx context.Context, mode neo4j.AccessMode) neo4j.Session {
	return s.driver.NewSession(ctx, neo4j.SessionConfig{
		AccessMode:   mode,
		DatabaseName: s.database,
	})
}

func (s *Neo4jStore) migrate(ctx context.Context) error {
	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	statements := []string{
		`CREATE CONSTRAINT node_id IF NOT EXISTS FOR (node:Node) REQUIRE node.id IS UNIQUE`,
		`CREATE CONSTRAINT seville_tag_id IF NOT EXISTS FOR (tag:Tag) REQUIRE tag.id IS UNIQUE`,
	}
	for _, statement := range statements {
		result, err := session.Run(ctx, statement, nil)
		if err != nil {
			return fmt.Errorf("migrate neo4j: %w", err)
		}
		if _, err := result.Consume(ctx); err != nil {
			return fmt.Errorf("migrate neo4j: %w", err)
		}
	}
	return nil
}

func (s *Neo4jStore) ImportNew(ctx context.Context, snapshot *nodev2.NodeSnapshot) error {
	nodes := make([]map[string]any, 0, len(snapshot.Nodes))
	for _, node := range snapshot.Nodes {
		tags, _ := json.Marshal(node.Tags)
		frontmatter, _ := json.Marshal(node.Frontmatter)
		row := map[string]any{
			"id": node.Id, "path": node.Path, "title": node.Title,
			"body": node.Body, "tags": node.Tags, "tags_json": string(tags),
			"frontmatter_json": string(frontmatter),
			"modified_at":      node.ModifiedAt.AsTime().UnixNano(),
		}
		for key, value := range node.Frontmatter {
			if _, protected := row[key]; !protected {
				row[key] = value
			}
		}
		nodes = append(nodes, row)
	}
	warningsJSON, _ := json.Marshal(snapshot.Warnings)
	taggings := make([]map[string]any, 0)
	for _, node := range snapshot.Nodes {
		for _, tag := range node.Tags {
			taggings = append(taggings, map[string]any{
				"note_id": node.Id,
				"tag_id":  tag,
				"weight":  1.0,
			})
		}
	}
	resolvedConnections := make([]map[string]any, 0, len(snapshot.Connections))
	unresolvedConnections := make([]map[string]any, 0)
	for index, connection := range snapshot.Connections {
		row := map[string]any{
			"index": int64(index), "source": connection.SourceNodeId,
			"target_text": connection.TargetText, "display_text": stringValue(connection.DisplayText),
			"kind": int64(connection.Kind), "fragment": stringValue(connection.Fragment),
		}
		if connection.TargetNodeId == nil {
			unresolvedConnections = append(unresolvedConnections, row)
			continue
		}
		row["target"] = *connection.TargetNodeId
		resolvedConnections = append(resolvedConnections, row)
	}

	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	_, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		queries := []struct {
			cypher string
			params map[string]any
		}{
			{`UNWIND $nodes AS row
MERGE (node:Node {id: row.id})
ON CREATE SET node = row, node.import_revision = $revision`, map[string]any{"nodes": nodes, "revision": snapshot.Revision}},
			{`UNWIND $taggings AS row
MATCH (node:Node {id: row.note_id})
MERGE (tag:Tag {id: row.tag_id})
ON CREATE SET tag.name = row.tag_id
MERGE (node)-[tagging:TAGGED_WITH]->(tag)
ON CREATE SET tagging.weight = row.weight, tagging.source = 'markdown'`, map[string]any{"taggings": taggings}},
			{`UNWIND $connections AS row
MATCH (source:Node {id: row.source})
MATCH (target:Node {id: row.target})
WHERE source.import_revision = $revision
MERGE (source)-[connection:LINKS_TO {index: row.index}]->(target)
SET connection = row`, map[string]any{"connections": resolvedConnections, "revision": snapshot.Revision}},
			{`UNWIND $connections AS row
MATCH (source:Node {id: row.source})
WHERE source.import_revision = $revision
MERGE (connection:SevilleUnresolvedLink {source: row.source, index: row.index})
SET connection = row
MERGE (source)-[:HAS_UNRESOLVED_LINK]->(connection)`, map[string]any{"connections": unresolvedConnections, "revision": snapshot.Revision}},
			{`MERGE (state:SevilleScanState {singleton: true})
SET state.revision = $revision, state.generated_at = $generated_at,
    state.warnings_json = $warnings_json`, map[string]any{
				"revision":      snapshot.Revision,
				"generated_at":  snapshot.GeneratedAt.AsTime().UnixNano(),
				"warnings_json": string(warningsJSON),
			}},
		}
		for _, query := range queries {
			result, err := tx.Run(ctx, query.cypher, query.params)
			if err != nil {
				return nil, err
			}
			if _, err := result.Consume(ctx); err != nil {
				return nil, err
			}
		}
		return nil, nil
	})
	if err != nil {
		return fmt.Errorf("import vault into neo4j: %w", err)
	}
	return nil
}

func (s *Neo4jStore) Snapshot(ctx context.Context) (*nodev2.NodeSnapshot, error) {
	session := s.session(ctx, neo4j.AccessModeRead)
	defer session.Close(ctx)
	result, err := session.Run(ctx, `MATCH (state:SevilleScanState {singleton: true})
RETURN state.revision AS revision, state.generated_at AS generated_at,
       state.warnings_json AS warnings_json`, nil)
	if err != nil {
		return nil, fmt.Errorf("query neo4j snapshot: %w", err)
	}
	if !result.Next(ctx) {
		if err := result.Err(); err != nil {
			return nil, fmt.Errorf("read neo4j snapshot: %w", err)
		}
		return nil, ErrSnapshotUnavailable
	}
	record := result.Record()
	revision, _ := record.Get("revision")
	generatedAt, _ := record.Get("generated_at")
	warningsJSON, _ := record.Get("warnings_json")
	snapshot := &nodev2.NodeSnapshot{Revision: revision.(string)}
	if nanos, ok := generatedAt.(int64); ok {
		snapshot.GeneratedAt = timestamppb.New(time.Unix(0, nanos).UTC())
	}
	if raw, ok := warningsJSON.(string); ok {
		_ = json.Unmarshal([]byte(raw), &snapshot.Warnings)
	}
	if err := s.readNodes(ctx, session, snapshot); err != nil {
		return nil, err
	}
	if err := s.readLinks(ctx, session, snapshot); err != nil {
		return nil, err
	}
	return snapshot, nil
}

func (s *Neo4jStore) readNodes(ctx context.Context, session neo4j.Session, snapshot *nodev2.NodeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (node:Node)
OPTIONAL MATCH (node)-[:TAGGED_WITH]->(tag:Tag)
WITH node, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
RETURN node.id AS id, node.path AS path, node.title AS title, node.body AS body,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE node.tags END AS tags,
       node.frontmatter_json AS frontmatter_json,
       node.modified_at AS modified_at, properties(node) AS properties
ORDER BY node.path`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j nodes: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		node := &nodev2.Node{}
		node.Id, _ = recordString(record, "id")
		node.Path, _ = recordString(record, "path")
		node.Title, _ = recordString(record, "title")
		node.Body, _ = recordString(record, "body")
		if values, ok := record.Get("tags"); ok {
			if items, ok := values.([]any); ok {
				for _, item := range items {
					if value, ok := item.(string); ok {
						node.Tags = append(node.Tags, value)
					}
				}
			}
		}
		if raw, ok := recordString(record, "frontmatter_json"); ok {
			_ = json.Unmarshal([]byte(raw), &node.Frontmatter)
		}
		if properties, ok := record.Get("properties"); ok {
			if values, ok := properties.(map[string]any); ok {
				for key, value := range values {
					if isStoredNodeField(key) {
						continue
					}
					if text, ok := value.(string); ok {
						node.Frontmatter[key] = text
					}
				}
			}
		}
		if value, ok := record.Get("modified_at"); ok {
			if nanos, ok := value.(int64); ok {
				node.ModifiedAt = timestamppb.New(time.Unix(0, nanos).UTC())
			}
		}
		snapshot.Nodes = append(snapshot.Nodes, node)
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j nodes: %w", err)
	}
	return nil
}

func isStoredNodeField(key string) bool {
	switch key {
	case "id", "path", "title", "body", "tags", "tags_json", "frontmatter_json", "modified_at", "import_revision":
		return true
	default:
		return false
	}
}

func (s *Neo4jStore) readLinks(ctx context.Context, session neo4j.Session, snapshot *nodev2.NodeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (source:Node)-[connection:LINKS_TO]->(target:Node)
RETURN source.id AS source, target.id AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
UNION ALL
MATCH (source:Node)-[:HAS_UNRESOLVED_LINK]->(connection:SevilleUnresolvedLink)
RETURN source.id AS source, null AS target, connection.target_text AS target_text,
       connection.display_text AS display_text, connection.kind AS kind, connection.fragment AS fragment, connection.index AS index
ORDER BY source, index`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j connections: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		targetText, _ := recordString(record, "target_text")
		connection := &nodev2.NodeConnection{SourceNodeId: source, TargetText: targetText}
		if value, ok := record.Get("target"); ok {
			if target, ok := value.(string); ok {
				connection.TargetNodeId = &target
			}
		}
		if value, ok := record.Get("display_text"); ok {
			if text, ok := value.(string); ok {
				connection.DisplayText = &text
			}
		}
		if value, ok := record.Get("fragment"); ok {
			if text, ok := value.(string); ok {
				connection.Fragment = &text
			}
		}
		if value, ok := record.Get("kind"); ok {
			if kind, ok := value.(int64); ok {
				connection.Kind = nodev2.NodeConnectionKind(kind)
			}
		}
		snapshot.Connections = append(snapshot.Connections, connection)
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j connections: %w", err)
	}
	return nil
}

func recordString(record *neo4j.Record, key string) (string, bool) {
	value, ok := record.Get(key)
	if !ok {
		return "", false
	}
	text, ok := value.(string)
	return text, ok
}

func stringValue(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}
