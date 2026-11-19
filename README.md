# Obsivilian

This README is an index to the repository. Detailed documentation belongs in
[`docs/`](docs/) or in the README of the workspace it describes.

Obsivilian's primary goal is a personal, extended digital atlas of reality
across space and time for research projects and self-development. The
[Calculating Empires](https://calculatingempires.net/about) project inspires
its layered, zoomable reading of history; Obsivilian uses the owner's own
Neo4j graph and layout.

## Repository responsibilities

| Folder | Responsibility |
| --- | --- |
| [`frontend/`](frontend/) | Native Flutter knowledge graph client |
| [`backend/`](backend/) | Go source ingestion, Neo4j graph storage, reconciliation, and HTTP API |
| [`proto/`](proto/) | Canonical Protocol Buffer contracts and generated Go and Dart packages |
| [`scripts/`](scripts/) | macOS process control and focused source, graph, and migration utilities |
| [`docs/`](docs/) | Repository-wide architecture, design decisions, and project documentation |

Each functional workspace owns its implementation details, development
instructions, and workspace-specific documentation.

## Client rendering policy

Flutter widgets own the workspace and graph interaction. The graph uses
`InteractiveViewer`, positioned Node widgets, and a `CustomPaint` connection
layer. Riverpod manages asynchronous API request state. The former Flame and
declarative Layout layers are retired from the active client.

## Verification policy

Seville applications and services do not contain or run automated tests. Do
not add test suites, test dependencies, test runners, test targets, or pipeline
steps that execute tests. Automated tests are not treated as evidence that
product behavior remains correct after a change. Use static analysis and
formatting checks for automated feedback; the project owner verifies behavior
in the real application.

## Documentation

The `docs/` folder contains documentation that applies across workspace
boundaries:

- [`vocabulary.md`](docs/vocabulary.md) defines the canonical language shared
  by Neo4j, Go, protobuf, and Flutter.
- [`http-api-conventions.md`](docs/http-api-conventions.md) defines route
  versioning, field naming, transport, and the planned system information API.
- [`seville-architecture-plan.md`](docs/seville-architecture-plan.md) defines
  the graph-centered knowledge client and its Go/Neo4j boundary.
- [`TODO.md`](TODO.md) records the repository-wide near-term product goals.

## Architecture at a glance

Neo4j is Seville's canonical live graph. Git checkouts and Markdown folders are
input sources, Go owns parsing and application policy, and clients access data
through the authenticated Go API. SQLite is not part of the system.

The current product is a graph-centered knowledge client. Native Flutter displays
and handles the graph; gameplay development is delegated outside this client. See
the [architecture document](docs/seville-architecture-plan.md) for the current
boundary and delivery priorities.

## Start locally on macOS

```sh
cp .env.example .env
make -C scripts interface
```

Backend details and configuration live in [`backend/README.md`](backend/README.md).

The short recovery runbook and graph-rule guide live in
[`docs/graph-recovery-sprint.md`](docs/graph-recovery-sprint.md).
