package config

import (
	"fmt"
	"os"
	"path/filepath"
)

type Config struct {
	Addr          string
	Source        string
	VaultPath     string
	GitRepoPath   string
	GitVaultPath  string
	Neo4jURI      string
	Neo4jUsername string
	Neo4jPassword string
	Neo4jDatabase string
	Token         string
	RootNodeID    string
}

func Load() (Config, error) {
	cfg := Config{
		Addr:          value("SEVILLE_ADDR", "127.0.0.1:8787"),
		Source:        value("SEVILLE_SOURCE", "vault"),
		VaultPath:     os.Getenv("SEVILLE_VAULT_PATH"),
		GitRepoPath:   os.Getenv("SEVILLE_GIT_REPOSITORY_PATH"),
		GitVaultPath:  value("SEVILLE_GIT_VAULT_SUBPATH", "."),
		Neo4jURI:      value("SEVILLE_NEO4J_URI", "bolt://127.0.0.1:7687"),
		Neo4jUsername: value("SEVILLE_NEO4J_USERNAME", "neo4j"),
		Neo4jPassword: value("SEVILLE_NEO4J_PASSWORD", "seville-local-password"),
		Neo4jDatabase: value("SEVILLE_NEO4J_DATABASE", "neo4j"),
		Token:         value("SEVILLE_TOKEN", "local-seville-token"),
		RootNodeID:    os.Getenv("SEVILLE_ROOT_NODE_ID"),
	}
	return cfg, nil
}

// LoadMigration validates and resolves the source-specific paths used only by
// explicit migration commands. The running backend must not require a source.
func LoadMigration() (Config, error) {
	cfg, err := Load()
	if err != nil {
		return Config{}, err
	}
	switch cfg.Source {
	case "vault":
		var err error
		cfg.VaultPath, err = filesystemPath(cfg.VaultPath)
		if err != nil {
			return Config{}, fmt.Errorf("SEVILLE_VAULT_PATH: %w", err)
		}
	case "git":
		var err error
		cfg.GitRepoPath, err = filesystemPath(cfg.GitRepoPath)
		if err != nil {
			return Config{}, fmt.Errorf("SEVILLE_GIT_REPOSITORY_PATH: %w", err)
		}
		cfg.VaultPath, err = gitVaultPath(cfg.GitRepoPath, cfg.GitVaultPath)
		if err != nil {
			return Config{}, err
		}
	default:
		return Config{}, fmt.Errorf("SEVILLE_SOURCE: must be vault or git; got %q", cfg.Source)
	}
	return cfg, nil
}

func gitVaultPath(repositoryPath, subpath string) (string, error) {
	info, err := os.Stat(repositoryPath)
	if err != nil {
		return "", fmt.Errorf("SEVILLE_GIT_REPOSITORY_PATH: cannot access %q: %w", repositoryPath, err)
	}
	if !info.IsDir() {
		return "", fmt.Errorf("SEVILLE_GIT_REPOSITORY_PATH: %q is not a directory", repositoryPath)
	}
	if _, err := os.Stat(filepath.Join(repositoryPath, ".git")); err != nil {
		return "", fmt.Errorf("SEVILLE_GIT_REPOSITORY_PATH: %q exists but has no .git metadata", repositoryPath)
	}
	if filepath.IsAbs(subpath) {
		return "", fmt.Errorf("SEVILLE_GIT_VAULT_SUBPATH: must be relative to the repository")
	}
	cleanSubpath := filepath.Clean(subpath)
	if cleanSubpath == ".." || len(cleanSubpath) > 3 && cleanSubpath[:3] == ".."+string(filepath.Separator) {
		return "", fmt.Errorf("SEVILLE_GIT_VAULT_SUBPATH: must stay inside the repository")
	}
	vaultPath := filepath.Join(repositoryPath, cleanSubpath)
	info, err = os.Stat(vaultPath)
	if err != nil {
		return "", fmt.Errorf("SEVILLE_GIT_VAULT_SUBPATH: %w", err)
	}
	if !info.IsDir() {
		return "", fmt.Errorf("SEVILLE_GIT_VAULT_SUBPATH: %q is not a directory", cleanSubpath)
	}
	return vaultPath, nil
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
