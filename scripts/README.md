# Scripts

This directory owns macOS project automation, graph inspection, and explicit
migration utilities.

Production parsing and reconciliation remain owned by the backend rather than
living only in scripts. Git and Markdown directories are source adapters;
Neo4j is the canonical database. There is no SQL persistence or planned
Neo4j-to-Markdown export path.

Stable local commands:

```sh
./scripts/seville start
./scripts/seville status
./scripts/seville stop
```

Legacy source migration tools live below `scripts/migrations/` so they cannot
be confused with normal process control. The documented Obsidian/Markdown
importer is in [`migrations/obsidian/`](migrations/obsidian/). It is manual and
is never invoked by Seville startup.

`./scripts/seville-interface` now verifies the complete dependency chain before
starting Flutter. For a localhost Neo4j URI it starts the bundled Neo4j
Community container, starts the Go API, waits for `/healthz`, and only then
hands control to Flutter. A remote `SEVILLE_NEO4J_URI` skips Docker.
