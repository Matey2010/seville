package main

import (
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/Matey2010/seville/backend/internal/config"
	"github.com/Matey2010/seville/backend/internal/server"
	"github.com/Matey2010/seville/backend/internal/store"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("configuration failed", "error", err)
		os.Exit(1)
	}
	database, err := store.Open(cfg.DBPath)
	if err != nil {
		slog.Error("database failed", "error", err)
		os.Exit(1)
	}
	defer database.Close()

	app := server.New(database, cfg.VaultPath, cfg.Token)
	if err := app.InitialScan(); err != nil {
		slog.Error("initial scan failed", "error", err)
		os.Exit(1)
	}

	httpServer := &http.Server{
		Addr:              cfg.Addr,
		Handler:           app.Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	slog.Info("seville backend listening", "addr", cfg.Addr, "vault", cfg.VaultPath)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}
