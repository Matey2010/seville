# Frontend

`obsivilian/` is the native Flutter macOS client. Architecture:
[../docs/architecture.md](../docs/architecture.md). Behavior rules:
[../.claude/rules/client.md](../.claude/rules/client.md).

The owner runs it with `make -C scripts interface`, which starts Neo4j and the
Go API first. Automated checks are limited to `flutter analyze` and
`dart format`. There are no automated tests.

| Path | Role |
| --- | --- |
| `lib/screens/knowledge_workspace.dart` | Main window, panels, floating controls |
| `lib/widgets/node_graph_view.dart` | Graph canvas and time HUD |
| `lib/widgets/node_graph_physics.dart` | Forge2D world |
| `lib/widgets/graph_world_layout.dart` | Semantic anchors (time-to-Y mapping) |
| `lib/state/node_store.dart` | Riverpod providers |
| `lib/data/seville_api.dart` | Dio + protobuf API client |
