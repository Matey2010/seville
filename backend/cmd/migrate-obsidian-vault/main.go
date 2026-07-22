package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/Matey2010/seville/backend/internal/config"
	"github.com/Matey2010/seville/backend/internal/migration"
	"github.com/Matey2010/seville/backend/internal/store"
)

func main() {
	ctx := context.Background()
	cfg, err := config.LoadMigration()
	if err != nil {
		slog.Error("migration configuration failed", "error", err)
		os.Exit(1)
	}
	database, err := store.OpenNeo4j(
		ctx,
		cfg.Neo4jURI,
		cfg.Neo4jUsername,
		cfg.Neo4jPassword,
		cfg.Neo4jDatabase,
		cfg.Neo4jQueryLog,
	)
	if err != nil {
		slog.Error("migration database failed", "error", err)
		os.Exit(1)
	}
	defer database.Close()

	snapshot, err := migration.ImportObsidianVault(ctx, database, cfg.VaultPath)
	if err != nil {
		slog.Error("Obsidian vault migration failed", "error", err)
		os.Exit(1)
	}
	slog.Info(
		"Obsidian vault migration complete",
		"nodes", len(snapshot.Nodes),
		"connections", len(snapshot.Connections),
		"warnings", len(snapshot.Warnings),
		"revision", snapshot.Revision,
	)
}
