package migration

import (
	"context"
	"log/slog"

	"github.com/Matey2010/seville/backend/internal/scanner"
	"github.com/Matey2010/seville/backend/internal/store"
	nodev2 "github.com/Matey2010/seville/proto/gen/go/seville/node/v2"
)

// ImportObsidianVault performs the legacy one-way Markdown-vault import.
// It is intentionally kept outside the running server so starting Seville can
// never ingest source data as a side effect.
func ImportObsidianVault(
	ctx context.Context,
	destination store.Importer,
	vaultPath string,
) (*nodev2.NodeSnapshot, error) {
	snapshot, err := scanner.Scan(vaultPath)
	if err != nil {
		return nil, err
	}
	for _, warning := range snapshot.Warnings {
		slog.Warn(
			"vault migration skipped file",
			"path", warning.Path,
			"reason", warning.Message,
		)
	}
	if err := destination.ImportNew(ctx, snapshot); err != nil {
		return nil, err
	}
	return snapshot, nil
}
