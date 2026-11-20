package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	Addr          string
	Neo4jURI      string
	Neo4jUsername string
	Neo4jPassword string
	Neo4jDatabase string
	Neo4jQueryLog bool
	Token         string
}

func Load() (Config, error) {
	neo4jQueryLog, err := boolValue("SEVILLE_NEO4J_QUERY_LOG", false)
	if err != nil {
		return Config{}, err
	}
	cfg := Config{
		Addr:          value("SEVILLE_ADDR", "127.0.0.1:8787"),
		Neo4jURI:      value("SEVILLE_NEO4J_URI", "bolt://127.0.0.1:7687"),
		Neo4jUsername: value("SEVILLE_NEO4J_USERNAME", "neo4j"),
		Neo4jPassword: value("SEVILLE_NEO4J_PASSWORD", "seville-local-password"),
		Neo4jDatabase: value("SEVILLE_NEO4J_DATABASE", "neo4j"),
		Neo4jQueryLog: neo4jQueryLog,
		Token:         value("SEVILLE_TOKEN", "local-seville-token"),
	}
	return cfg, nil
}

func boolValue(name string, fallback bool) (bool, error) {
	value := os.Getenv(name)
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return false, fmt.Errorf("%s: must be true or false; got %q", name, value)
	}
	return parsed, nil
}

func value(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
