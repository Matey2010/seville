# Make automation

This directory's Makefile owns macOS project automation, graph inspection, and
explicit migration utilities.

Production parsing and reconciliation remain owned by the backend rather than
living only in scripts. Git and Markdown directories are source adapters;
Neo4j is the canonical database. There is no SQL persistence or planned
Neo4j-to-Markdown export path.

Run `make -C scripts` from the repository root to see the available targets.
The stable local backend commands are:

```sh
make -C scripts start
make -C scripts status
make -C scripts stop
```

Legacy source migration tools live below `scripts/migrations/` so they cannot
be confused with normal process control. The documented Obsidian/Markdown
importer is described in [`migrations/obsidian/`](migrations/obsidian/) and runs
with `make -C scripts migrate-obsidian`. It is manual and is never invoked by
Seville startup.

`make -C scripts interface` verifies the complete dependency chain before
starting Flutter. For a localhost Neo4j URI it starts the bundled Neo4j
Community container, starts the Go API, waits for `/healthz`, and only then
hands control to the supported macOS client. A remote `SEVILLE_NEO4J_URI` skips
Docker.
