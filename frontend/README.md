# Seville frontend

`seville7` is the native Flutter knowledge client for macOS. It opens on a
bounded global Node graph. Selecting a Node requests its local `LINKS_TO`
neighborhood and shows its Markdown body. Search, Node creation, and body
editing use the existing Go API and protobuf contracts.

Flutter widgets own the workspace, graph interaction, text, and accessibility.
Riverpod manages asynchronous API requests. The active client has no Flame
engine or declarative Layout layer. At larger widths it shows a Node list,
graph, and details; narrower widths use two or stacked panes. Android phone
landscape is experimental for owner verification.

The project owner runs and verifies the macOS app with:

```sh
make -C scripts interface
```

Codex may use formatting and static analysis. Seville does not use automated
application tests. See the repository
[architecture document](../docs/seville-architecture-plan.md) for the API and
data boundaries.
