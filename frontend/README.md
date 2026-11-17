# Obsivilian frontend

Obsivilian is the native Flutter knowledge client for macOS. It opens on a
bounded global Node graph. Selecting a Node opens a split modal with its
details and Markdown body on the left and its local `LINKS_TO` graph on the
right. Search, Node creation, and body editing use the existing Go API and
protobuf contracts.

Flutter widgets own the workspace, graph interaction, text, and accessibility.
Forge2D moves circular Nodes with gentle drift and collisions in both graph
views. Connections remain visual until their physics rules are defined.
Riverpod manages asynchronous API requests. The active client has no Flame
engine or declarative Layout layer. The global workspace shows a Node list
beside the graph.
The full-window graph mode hides the app bar, search, and Node list; use its
overlay button or Command-backslash to restore the interface.

The project owner runs and verifies the macOS app with:

```sh
make -C scripts interface
```

Codex may use formatting and static analysis. Obsivilian does not use automated
application tests. See the repository
[architecture document](../docs/seville-architecture-plan.md) for the API and
data boundaries.
