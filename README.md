# Seville

This README is an index to the repository. Detailed documentation belongs in
[`docs/`](docs/) or in the README of the workspace it describes.

## Repository responsibilities

| Folder | Responsibility |
| --- | --- |
| [`interface/`](interface/) | Flutter and Flame application, including visualization and user interaction |
| [`backend/`](backend/) | Go ingestion service, Obsidian parsing, storage, and HTTP API |
| [`proto/`](proto/) | Canonical Protocol Buffer contracts and generated Go and Dart packages |
| [`scripts/`](scripts/) | Project automation and focused Obsidian import, export, inspection, and migration utilities |
| [`docs/`](docs/) | Repository-wide architecture, design decisions, and project documentation |

Each functional workspace owns its implementation details, development
instructions, and workspace-specific documentation.

## Documentation

The `docs/` folder contains documentation that applies across workspace
boundaries:

- [`seville-architecture-plan.md`](docs/seville-architecture-plan.md) records
  the product goal, current architecture direction, accepted decisions, and
  open design questions.
