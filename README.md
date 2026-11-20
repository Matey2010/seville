# Seville

Seville (app: **Obsivilian**) is a personal operating system: one person's tool
for planning, tracking, and reaching real-world goals. It is built on a graph
atlas of Nodes placed in time and, soon, space.

| Folder | Contents |
| --- | --- |
| [`frontend/`](frontend/) | Flutter macOS client |
| [`backend/`](backend/) | Go API over Neo4j |
| [`proto/`](proto/) | Protobuf contracts and generated code |
| [`scripts/`](scripts/) | Makefile: process control, codegen, migrations |
| [`docs/`](docs/) | [Roadmap](docs/roadmap.md), [architecture](docs/architecture.md), [vocabulary](docs/vocabulary.md), [HTTP API](docs/http-api-conventions.md), [data runbook](docs/data-runbook.md) |

Run on macOS:

```sh
cp .env.example .env    # set real credentials
make -C scripts interface
```

There are no automated tests. The owner verifies behavior in the app. AI
assistant context lives in [`CLAUDE.md`](CLAUDE.md).
