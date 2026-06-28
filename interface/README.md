# Seville Interface

This directory owns Seville's user-facing clients. The current client is the
Flutter and Flame application under [`flutter/`](flutter/). Other interfaces,
such as a CLI, can live beside it without becoming part of the Flutter project.

With the backend running, launch the client from the repository root:

```sh
./scripts/seville-interface
```

Pass a Flutter device name as the first argument, for example
`./scripts/seville-interface chrome`. The launcher reads `SEVILLE_BASE_URL` and
`SEVILLE_TOKEN` from `.env` and passes them to Flutter.

For direct development commands:

```sh
cd interface/flutter
flutter analyze
flutter test
```

The application fetches the generated protobuf `KnowledgeSnapshot`, turns
resolved Obsidian links into edges, and renders the result with Flame. Visual
rules are deliberately centralized in
[`flutter/lib/graph/graph_rules.dart`](flutter/lib/graph/graph_rules.dart):

- the first matching tag determines node color;
- weighted link degree determines node radius;
- wiki links, Markdown links, and embeds have independent weights and colors;
- unresolved links and links to filtered-out notes are not drawn.

Architecture and repository-wide decisions are documented in
[`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md).
