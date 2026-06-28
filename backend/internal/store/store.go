package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	knowledgev1 "github.com/Matey2010/seville/proto/gen/go/seville/knowledge/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
	_ "modernc.org/sqlite"
)

type Store struct {
	db *sql.DB
}

func Open(path string) (*Store, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, fmt.Errorf("create database directory: %w", err)
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("open sqlite: %w", err)
	}
	store := &Store{db: db}
	if err := store.migrate(context.Background()); err != nil {
		db.Close()
		return nil, err
	}
	return store, nil
}

func (s *Store) Close() error {
	return s.db.Close()
}

func (s *Store) migrate(ctx context.Context) error {
	const schema = `
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  tags_json TEXT NOT NULL,
  frontmatter_json TEXT NOT NULL,
  modified_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_note_id TEXT NOT NULL,
  target_text TEXT NOT NULL,
  resolved_target_id TEXT,
  display_text TEXT,
  kind INTEGER NOT NULL,
  fragment TEXT
);
CREATE TABLE IF NOT EXISTS scan_state (
  singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
  revision TEXT NOT NULL,
  generated_at TEXT NOT NULL,
  warnings_json TEXT NOT NULL
);`
	if _, err := s.db.ExecContext(ctx, schema); err != nil {
		return fmt.Errorf("migrate sqlite: %w", err)
	}
	return nil
}

func (s *Store) Replace(ctx context.Context, snapshot *knowledgev1.KnowledgeSnapshot) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin scan transaction: %w", err)
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx, "DELETE FROM links; DELETE FROM notes;"); err != nil {
		return fmt.Errorf("clear old snapshot: %w", err)
	}
	for _, note := range snapshot.Notes {
		tags, _ := json.Marshal(note.Tags)
		frontmatter, _ := json.Marshal(note.Frontmatter)
		if _, err := tx.ExecContext(ctx, `
INSERT INTO notes (id, path, title, body, tags_json, frontmatter_json, modified_at)
VALUES (?, ?, ?, ?, ?, ?, ?)`,
			note.Id, note.Path, note.Title, note.Body, string(tags), string(frontmatter), note.ModifiedAt.AsTime().Format(time.RFC3339Nano)); err != nil {
			return fmt.Errorf("insert note %q: %w", note.Path, err)
		}
	}
	for _, link := range snapshot.Links {
		if _, err := tx.ExecContext(ctx, `
INSERT INTO links (source_note_id, target_text, resolved_target_id, display_text, kind, fragment)
VALUES (?, ?, ?, ?, ?, ?)`,
			link.SourceNoteId, link.TargetText, nullable(link.ResolvedTargetId), nullable(link.DisplayText), link.Kind, nullable(link.Fragment)); err != nil {
			return fmt.Errorf("insert link: %w", err)
		}
	}
	warnings, _ := json.Marshal(snapshot.Warnings)
	if _, err := tx.ExecContext(ctx, `
INSERT INTO scan_state (singleton, revision, generated_at, warnings_json)
VALUES (1, ?, ?, ?)
ON CONFLICT(singleton) DO UPDATE SET
  revision = excluded.revision,
  generated_at = excluded.generated_at,
  warnings_json = excluded.warnings_json`,
		snapshot.Revision, snapshot.GeneratedAt.AsTime().Format(time.RFC3339Nano), string(warnings)); err != nil {
		return fmt.Errorf("update scan state: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit scan transaction: %w", err)
	}
	return nil
}

func (s *Store) Snapshot(ctx context.Context) (*knowledgev1.KnowledgeSnapshot, error) {
	snapshot := &knowledgev1.KnowledgeSnapshot{}
	var generatedAt, warningsJSON string
	err := s.db.QueryRowContext(ctx, "SELECT revision, generated_at, warnings_json FROM scan_state WHERE singleton = 1").
		Scan(&snapshot.Revision, &generatedAt, &warningsJSON)
	if err != nil {
		return nil, err
	}
	generated, err := time.Parse(time.RFC3339Nano, generatedAt)
	if err != nil {
		return nil, fmt.Errorf("parse scan time: %w", err)
	}
	snapshot.GeneratedAt = timestamppb.New(generated)
	if err := json.Unmarshal([]byte(warningsJSON), &snapshot.Warnings); err != nil {
		return nil, fmt.Errorf("decode warnings: %w", err)
	}

	rows, err := s.db.QueryContext(ctx, "SELECT id, path, title, body, tags_json, frontmatter_json, modified_at FROM notes ORDER BY path")
	if err != nil {
		return nil, fmt.Errorf("query notes: %w", err)
	}
	for rows.Next() {
		note := &knowledgev1.Note{}
		var tagsJSON, frontmatterJSON, modifiedAt string
		if err := rows.Scan(&note.Id, &note.Path, &note.Title, &note.Body, &tagsJSON, &frontmatterJSON, &modifiedAt); err != nil {
			rows.Close()
			return nil, err
		}
		_ = json.Unmarshal([]byte(tagsJSON), &note.Tags)
		_ = json.Unmarshal([]byte(frontmatterJSON), &note.Frontmatter)
		modified, _ := time.Parse(time.RFC3339Nano, modifiedAt)
		note.ModifiedAt = timestamppb.New(modified)
		snapshot.Notes = append(snapshot.Notes, note)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}

	linkRows, err := s.db.QueryContext(ctx, "SELECT source_note_id, target_text, resolved_target_id, display_text, kind, fragment FROM links ORDER BY id")
	if err != nil {
		return nil, fmt.Errorf("query links: %w", err)
	}
	defer linkRows.Close()
	for linkRows.Next() {
		link := &knowledgev1.Link{}
		var resolved, display, fragment sql.NullString
		if err := linkRows.Scan(&link.SourceNoteId, &link.TargetText, &resolved, &display, &link.Kind, &fragment); err != nil {
			return nil, err
		}
		link.ResolvedTargetId = pointer(resolved)
		link.DisplayText = pointer(display)
		link.Fragment = pointer(fragment)
		snapshot.Links = append(snapshot.Links, link)
	}
	return snapshot, linkRows.Err()
}

func nullable(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}

func pointer(value sql.NullString) *string {
	if !value.Valid {
		return nil
	}
	return &value.String
}
