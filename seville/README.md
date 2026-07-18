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

All current interface rendering and interaction belongs to Flame components.
Flutter widgets are limited to application composition and the `GameWidget`
host. An explicit HUD may use widgets in the future, but no HUD exists today;
ordinary panels, controls, layouts, graphs, and overlays must not be implemented
as Flutter widgets.

Component-independent table structure and row-building logic lives in
[`flutter/packages/table_data`](flutter/packages/table_data). Seville keeps
layout sizing, Node/system adapters, canvas geometry, and component rendering
in the application layer.

For direct development commands:

```sh
cd seville/flutter
flutter analyze
flutter build macos
```

Seville clients do not contain or run automated tests. Do not add test suites,
test dependencies, test targets, or test runners. Automated feedback is limited
to formatting and static analysis. The project owner verifies final behavior
in the real application.

The application fetches the generated protobuf `NodeSnapshot`, turns
resolved graph links into edges, and renders the result with Flame. Visual
rules are deliberately centralized in
[`flutter/lib/graph/graph_rules.dart`](flutter/lib/graph/graph_rules.dart):

- the first matching tag determines node color;
- weighted link degree determines node radius;
- wiki links, Markdown links, and embeds have independent weights and colors;
- unresolved connections and connections to filtered-out nodes are not drawn.

The Flutter composition follows the open-box spatial model documented in
[`flutter/SEVILLE_GUIDELINES.md`](flutter/SEVILLE_GUIDELINES.md).

Architecture and repository-wide decisions are documented in
[`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md).
