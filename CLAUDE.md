# Seville

Seville (app: **Obsivilian**) is the owner's personal operating system: a tool
for one person to plan, track, and reach real-world goals. Its foundation is a
graph atlas of Nodes in Neo4j, placed on a time plane and, soon, a location
plane. Claude is the project's main AI.

Next work: **Objectives** (goals inspired by RPG quest systems but named for
professional use), then the bottom **location plane**. Priorities and the
Objective design are in [docs/roadmap.md](docs/roadmap.md).

## Rules

- **Never launch, build-run, or runtime-debug the app**, and don't offer to.
  The owner runs it with `make -C scripts interface`.
- **No automated tests**: no test files, test dependencies, runners, or CI test
  steps. Formatting, dependency resolution, and static analysis are allowed,
  but they are not runtime verification; say so when reporting.
- **Read [docs/vocabulary.md](docs/vocabulary.md) before naming** an entity or
  API contract, and add new terms there first. Never use "Quest" in code, API,
  or UI; the term is **Objective**.
- **The backend and protobuf are closed by default.** Change Go, Neo4j, or
  `.proto` contracts only when the owner reopens them for the task.
- macOS is the only supported platform. Never commit `.env`, dumps, or
  credentials.
- Keep docs short and non-duplicated: each fact lives in one file. Planned work
  goes in `docs/roadmap.md`, not in other docs.

Area rules load automatically from `.claude/rules/`: the domain model always;
backend and client rules when working in those folders.

## Checks

Run from the repository root before reporting a change as done:

```sh
(cd backend && go build ./... && go vet ./... && golangci-lint run ./...)
gofmt -l backend
(cd frontend/obsivilian && flutter analyze && dart format --output=none --set-exit-if-changed lib)
make -C scripts proto    # only after editing .proto files
```

Baseline as of 2026-11-20: 0 `golangci-lint` issues and 7 `flutter analyze`
infos (deprecated `package:flutter/material.dart`). New work must not add any.

## Map

| Path | Contents |
| --- | --- |
| `frontend/obsivilian/` | Flutter client (Riverpod, Dio, Forge2D 0.15.1) |
| `backend/` | Go API, Neo4j store |
| `proto/` | Contracts; generated `gen/` is committed |
| `docs/` | roadmap, architecture, vocabulary, HTTP API, data runbook |
