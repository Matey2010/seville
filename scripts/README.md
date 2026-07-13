# Scripts

This directory owns macOS project automation and focused source ingestion,
graph inspection, and migration utilities.

Production parsing and reconciliation remain owned by the backend rather than
living only in scripts. Git and Markdown directories are source adapters;
Neo4j is the canonical database. There is no SQL persistence or planned
Neo4j-to-Markdown export path.

Stable local commands:

```sh
./scripts/seville start
./scripts/seville status
./scripts/seville rescan
./scripts/seville stop
```

`./scripts/seville-interface` now verifies the complete dependency chain before
starting Flutter. For a localhost Neo4j URI it starts the bundled Neo4j
Community container, starts the Go API, waits for `/healthz`, and only then
hands control to Flutter. A remote `SEVILLE_NEO4J_URI` skips Docker.
