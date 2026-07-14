package store

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
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
		`MATCH (node:SevilleNote) SET node:Node REMOVE node:SevilleNote`,
		`DROP CONSTRAINT seville_note_id IF EXISTS`,
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

func (s *Neo4jStore) ImportNew(ctx context.Context, snapshot *knowledgev1.KnowledgeSnapshot) error {
	notes := make([]map[string]any, 0, len(snapshot.Notes))
	for _, note := range snapshot.Notes {
		tags, _ := json.Marshal(note.Tags)
		frontmatter, _ := json.Marshal(note.Frontmatter)
		row := map[string]any{
			"id": note.Id, "path": note.Path, "title": note.Title,
			"body": note.Body, "tags": note.Tags, "tags_json": string(tags),
			"frontmatter_json": string(frontmatter),
			"modified_at":      note.ModifiedAt.AsTime().UnixNano(),
		}
		for key, value := range note.Frontmatter {
			if _, protected := row[key]; !protected {
				row[key] = value
			}
		}
		notes = append(notes, row)
	}
	warningsJSON, _ := json.Marshal(snapshot.Warnings)
	taggings := make([]map[string]any, 0)
	for _, note := range snapshot.Notes {
		for _, tag := range note.Tags {
			taggings = append(taggings, map[string]any{
				"note_id": note.Id,
				"tag_id":  tag,
				"weight":  1.0,
			})
		}
	}
	resolvedLinks := make([]map[string]any, 0, len(snapshot.Links))
	unresolvedLinks := make([]map[string]any, 0)
	for index, link := range snapshot.Links {
		row := map[string]any{
			"index": int64(index), "source": link.SourceNoteId,
			"target_text": link.TargetText, "display_text": stringValue(link.DisplayText),
			"kind": int64(link.Kind), "fragment": stringValue(link.Fragment),
		}
		if link.ResolvedTargetId == nil {
			unresolvedLinks = append(unresolvedLinks, row)
			continue
		}
		row["target"] = *link.ResolvedTargetId
		resolvedLinks = append(resolvedLinks, row)
	}

	session := s.session(ctx, neo4j.AccessModeWrite)
	defer session.Close(ctx)
	_, err := session.ExecuteWrite(ctx, func(tx neo4j.ManagedTransaction) (any, error) {
		queries := []struct {
			cypher string
			params map[string]any
		}{
			{`UNWIND $notes AS row
MERGE (note:Node {id: row.id})
ON CREATE SET note = row, note.import_revision = $revision`, map[string]any{"notes": notes, "revision": snapshot.Revision}},
			{`UNWIND $taggings AS row
MATCH (note:Node {id: row.note_id})
MERGE (tag:Tag {id: row.tag_id})
ON CREATE SET tag.name = row.tag_id
MERGE (note)-[tagging:TAGGED_WITH]->(tag)
ON CREATE SET tagging.weight = row.weight, tagging.source = 'markdown'`, map[string]any{"taggings": taggings}},
			{`UNWIND $links AS row
MATCH (source:Node {id: row.source})
MATCH (target:Node {id: row.target})
WHERE source.import_revision = $revision
MERGE (source)-[link:LINKS_TO {index: row.index}]->(target)
SET link = row`, map[string]any{"links": resolvedLinks, "revision": snapshot.Revision}},
			{`UNWIND $links AS row
MATCH (source:Node {id: row.source})
WHERE source.import_revision = $revision
MERGE (link:SevilleUnresolvedLink {source: row.source, index: row.index})
SET link = row
MERGE (source)-[:HAS_UNRESOLVED_LINK]->(link)`, map[string]any{"links": unresolvedLinks, "revision": snapshot.Revision}},
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

func (s *Neo4jStore) Snapshot(ctx context.Context) (*knowledgev1.KnowledgeSnapshot, error) {
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
	snapshot := &knowledgev1.KnowledgeSnapshot{Revision: revision.(string)}
	if nanos, ok := generatedAt.(int64); ok {
		snapshot.GeneratedAt = timestamppb.New(time.Unix(0, nanos).UTC())
	}
	if raw, ok := warningsJSON.(string); ok {
		_ = json.Unmarshal([]byte(raw), &snapshot.Warnings)
	}
	if err := s.readNotes(ctx, session, snapshot); err != nil {
		return nil, err
	}
	if err := s.readLinks(ctx, session, snapshot); err != nil {
		return nil, err
	}
	return snapshot, nil
}

func (s *Neo4jStore) readNotes(ctx context.Context, session neo4j.Session, snapshot *knowledgev1.KnowledgeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (note:Node)
OPTIONAL MATCH (note)-[:TAGGED_WITH]->(tag:Tag)
WITH note, [tagId IN collect(tag.id) WHERE tagId IS NOT NULL] AS graphTags
RETURN note.id AS id, note.path AS path, note.title AS title, note.body AS body,
       CASE WHEN size(graphTags) > 0 THEN graphTags ELSE note.tags END AS tags,
       note.frontmatter_json AS frontmatter_json,
       note.modified_at AS modified_at, properties(note) AS properties
ORDER BY note.path`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j notes: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		note := &knowledgev1.Note{}
		note.Id, _ = recordString(record, "id")
		note.Path, _ = recordString(record, "path")
		note.Title, _ = recordString(record, "title")
		note.Body, _ = recordString(record, "body")
		if values, ok := record.Get("tags"); ok {
			if items, ok := values.([]any); ok {
				for _, item := range items {
					if value, ok := item.(string); ok {
						note.Tags = append(note.Tags, value)
					}
				}
			}
		}
		if raw, ok := recordString(record, "frontmatter_json"); ok {
			_ = json.Unmarshal([]byte(raw), &note.Frontmatter)
		}
		if properties, ok := record.Get("properties"); ok {
			if values, ok := properties.(map[string]any); ok {
				for key, value := range values {
					if isStoredNoteField(key) {
						continue
					}
					if text, ok := value.(string); ok {
						note.Frontmatter[key] = text
					}
				}
			}
		}
		if value, ok := record.Get("modified_at"); ok {
			if nanos, ok := value.(int64); ok {
				note.ModifiedAt = timestamppb.New(time.Unix(0, nanos).UTC())
			}
		}
		snapshot.Notes = append(snapshot.Notes, note)
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j notes: %w", err)
	}
	return nil
}

func isStoredNoteField(key string) bool {
	switch key {
	case "id", "path", "title", "body", "tags", "tags_json", "frontmatter_json", "modified_at", "import_revision":
		return true
	default:
		return false
	}
}

func (s *Neo4jStore) readLinks(ctx context.Context, session neo4j.Session, snapshot *knowledgev1.KnowledgeSnapshot) error {
	result, err := session.Run(ctx, `MATCH (source:Node)-[link:LINKS_TO]->(target:Node)
RETURN source.id AS source, target.id AS target, link.target_text AS target_text,
       link.display_text AS display_text, link.kind AS kind, link.fragment AS fragment, link.index AS index
UNION ALL
MATCH (source:Node)-[:HAS_UNRESOLVED_LINK]->(link:SevilleUnresolvedLink)
RETURN source.id AS source, null AS target, link.target_text AS target_text,
       link.display_text AS display_text, link.kind AS kind, link.fragment AS fragment, link.index AS index
ORDER BY source, index`, nil)
	if err != nil {
		return fmt.Errorf("query neo4j links: %w", err)
	}
	for result.Next(ctx) {
		record := result.Record()
		source, _ := recordString(record, "source")
		targetText, _ := recordString(record, "target_text")
		link := &knowledgev1.Link{SourceNoteId: source, TargetText: targetText}
		if value, ok := record.Get("target"); ok {
			if target, ok := value.(string); ok {
				link.ResolvedTargetId = &target
			}
		}
		if value, ok := record.Get("display_text"); ok {
			if text, ok := value.(string); ok {
				link.DisplayText = &text
			}
		}
		if value, ok := record.Get("fragment"); ok {
			if text, ok := value.(string); ok {
				link.Fragment = &text
			}
		}
		if value, ok := record.Get("kind"); ok {
			if kind, ok := value.(int64); ok {
				link.Kind = knowledgev1.LinkKind(kind)
			}
		}
		snapshot.Links = append(snapshot.Links, link)
	}
	if err := result.Err(); err != nil {
		return fmt.Errorf("read neo4j links: %w", err)
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
