# Obsivilian frontend

Obsivilian is the native Flutter knowledge client for macOS. It opens on a
bounded global Node graph. Selecting a Node opens a floating detail window
without moving the graph. Search, Node creation, body editing, and time
placement use the Go API and protobuf contracts.

Flutter widgets own the workspace, graph interaction, text, and accessibility.
Forge2D moves circular Nodes around stable anchors with gentle drift and
collisions. The left time plane uses intervals carried from native Neo4j
`DATE` values. Today is the central row, future dates go upward, and older
start dates go downward; columns run Year, Season,
Month, Week, Day from left to right, with Day nearest the graph. Older dates
are compressed logarithmically, while crowded date rows gain space. Legacy
general ranges are not shown in the plane. Calendar nesting links are derived from interval
overlap for display and are not stored relationships. The global API response
is a bounded overview, so omitted Nodes are not yet shown on the time plane.
Riverpod manages asynchronous API requests. The active client has no Flame
engine or declarative Layout layer. Search and Node lists open from floating
controls over the graph. The bottom location plane remains planned.
Home in the top-left clears search and open panels and resets the graph camera
to its opening view.

The project owner runs and verifies the macOS app with:

```sh
make -C scripts interface
```

Codex may use formatting and static analysis. Obsivilian does not use automated
application tests. See the repository
[architecture document](../docs/seville-architecture-plan.md) for the API and
data boundaries.
