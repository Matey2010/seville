# Seville

This directory owns Seville's user-facing clients. The current client is the
Flutter and Flame application under [`flutter/`](flutter/). Other interfaces,
such as a CLI, can live beside it without becoming part of the Flutter project.

With the backend running, launch the client from the repository root:

```sh
./scripts/seville-interface
```

The launcher targets the supported macOS application, reads `SEVILLE_BASE_URL`
and `SEVILLE_TOKEN` from `.env`, and passes them to Flutter. Other Flutter
targets are not currently implemented.

For direct development commands:

```sh
cd seville/flutter
flutter analyze
flutter build macos
```

Seville does not use unit tests as its client quality gate. Client
quality is verified through static analysis, real application builds, manual
visual review, and later integral/system testing around full user flows. Codex
handoffs should include directions for manual verification; the final
verification result belongs to the project owner.

The application fetches the generated protobuf `KnowledgeSnapshot`, turns
resolved graph links into edges, and renders the result with Flame. Visual
rules are deliberately centralized in
[`flutter/lib/graph/graph_rules.dart`](flutter/lib/graph/graph_rules.dart):

- the first matching tag determines node color;
- weighted link degree determines node radius;
- wiki links, Markdown links, and embeds have independent weights and colors;
- unresolved links and links to filtered-out notes are not drawn.

The Flutter composition follows the open-box spatial model documented in
[`flutter/SEVILLE_GUIDELINES.md`](flutter/SEVILLE_GUIDELINES.md).

Architecture and repository-wide decisions are documented in
[`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md).
