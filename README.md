# Seville

This README is an index to the repository. Detailed documentation belongs in
[`docs/`](docs/) or in the README of the workspace it describes.

## Repository responsibilities

| Folder | Responsibility |
| --- | --- |
| [`frontend/`](frontend/) | User-facing clients, currently implemented with Flutter and Flame |
| [`backend/`](backend/) | Go source ingestion, Neo4j graph storage, reconciliation, and HTTP API |
| [`proto/`](proto/) | Canonical Protocol Buffer contracts and generated Go and Dart packages |
| [`scripts/`](scripts/) | macOS process control and focused source, graph, and migration utilities |
| [`docs/`](docs/) | Repository-wide architecture, design decisions, and project documentation |

Each functional workspace owns its implementation details, development
instructions, and workspace-specific documentation.

## Client rendering policy

Seville interface content is rendered and interacted with through Flame
components. Flutter widgets host the `GameWidget` and Riverpod-driven toast
widgets through `overlay_layers`; Search is a Flame HUD component.
Do not add Flutter widget renderers, gesture layers, or hit boxes for layout or
graph content.

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
  by Neo4j, Go, protobuf, Flutter layouts, and renderers.
- [`http-api-conventions.md`](docs/http-api-conventions.md) defines route
  versioning, field naming, transport, and the planned system information API.
- [`seville-architecture-plan.md`](docs/seville-architecture-plan.md) records
  the product goal, current architecture direction, accepted decisions, and
  open design questions.
- [`TODO.md`](TODO.md) records the repository-wide near-term product goals.

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
