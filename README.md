# Seville

This README is an index to the repository. Detailed documentation belongs in
[`docs/`](docs/) or in the README of the workspace it describes.

## Repository responsibilities

| Folder | Responsibility |
| --- | --- |
| [`seville/`](seville/) | The Seville product client, currently implemented with Flutter and Flame |
| [`backend/`](backend/) | Go source ingestion, Neo4j graph storage, reconciliation, and HTTP API |
| [`proto/`](proto/) | Canonical Protocol Buffer contracts and generated Go and Dart packages |
| [`scripts/`](scripts/) | macOS process control and focused source, graph, and migration utilities |
| [`docs/`](docs/) | Repository-wide architecture, design decisions, and project documentation |

Each functional workspace owns its implementation details, development
instructions, and workspace-specific documentation.

## Documentation

The `docs/` folder contains documentation that applies across workspace
boundaries:

- [`seville-architecture-plan.md`](docs/seville-architecture-plan.md) records
  the product goal, current architecture direction, accepted decisions, and
  open design questions.

## Architecture at a glance

Neo4j is Seville's canonical live graph. Git checkouts and Markdown folders are
input sources, Go owns parsing and application policy, and clients access data
through the authenticated Go API. SQLite is not part of the system.

The long-term direction is a persistent multiplayer knowledge world with
provenance, safe synchronization, verifiable history, and peer-assisted
recovery. See the [architecture document](docs/seville-architecture-plan.md)
for the current boundary and staged roadmap.

## Start locally on macOS

```sh
cp .env.example .env
./scripts/seville start
./scripts/seville status
```

Backend details and configuration live in [`backend/README.md`](backend/README.md).

To start the complete local dependency chain and macOS client:

```sh
./scripts/seville-interface
```

The short recovery runbook and graph-rule guide live in
[`docs/graph-recovery-sprint.md`](docs/graph-recovery-sprint.md).
