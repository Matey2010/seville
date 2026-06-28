package config

import (
	"fmt"
	"os"
	"path/filepath"
)

type Config struct {
	Addr      string
	VaultPath string
	DBPath    string
	Token     string
}

func Load() (Config, error) {
	cfg := Config{
		Addr:      value("SEVILLE_ADDR", "127.0.0.1:8787"),
		VaultPath: os.Getenv("SEVILLE_VAULT_PATH"),
		DBPath:    value("SEVILLE_DB_PATH", ".local/seville.db"),
		Token:     value("SEVILLE_TOKEN", "local-seville-token"),
	}

	var err error
	cfg.VaultPath, err = filesystemPath(cfg.VaultPath)
	if err != nil {
		return Config{}, fmt.Errorf("SEVILLE_VAULT_PATH: %w", err)
	}
	cfg.DBPath, err = filepath.Abs(cfg.DBPath)
	if err != nil {
		return Config{}, fmt.Errorf("resolve database path: %w", err)
	}
	return cfg, nil
}

func value(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func filesystemPath(path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("is required; use an absolute path such as /Users/you/Vault or ~/Vault")
	}

	if path == "~" || len(path) > 2 && path[:2] == "~/" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("expand ~: %w", err)
		}
		path = filepath.Join(home, path[1:])
	}
	if !filepath.IsAbs(path) {
		return "", fmt.Errorf("must start with / or ~/; got %q", path)
	}
	return filepath.Clean(path), nil
}
