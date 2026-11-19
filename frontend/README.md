# Obsivilian frontend

Obsivilian is the native Flutter knowledge client for macOS. It opens on a
bounded global Node graph. Selecting a Node opens a floating detail window
without moving the graph. Search, Node creation, body editing, and time
placement use the Go API and protobuf contracts.

Flutter widgets own the workspace, graph interaction, text, and accessibility.
Forge2D moves circular Nodes around stable anchors with gentle drift and
collisions. Temporal graph Nodes use intervals carried from native Neo4j
`DATE` values. The current moment is centered, future dates go upward, and
older dates go downward. There are no separate calendar columns. Calendar
nesting links are derived from interval overlap for display and are not stored
relationships. The global API response is a bounded overview.
The calendar is a HUD under the graph. Home shows about twelve hours above and
below now; zooming out reveals progressively larger spans and displays the
current approximate span at the top. A red dashed NOW line, translucent dotted
hour lines, day boundaries, and valid date labels exist without corresponding
Nodes. Stored Neo4j `DATE` values remain day-granular.
Vertical dragging changes the HUD's actual calendar window. The top bubble
shows a NOW-relative span while NOW is visible and a compact chronological
bottom-to-top range after NOW leaves the screen.

The HUD checks visible date slugs in one API request. Existing dates use a
filled edit label; missing dates use an outlined add label. Date Nodes are not
Forge2D bodies. Both labels open the shared Node editor, and missing dates
receive their slug, `Date` label, and one-day span automatically.
Date controls are vertical and centered within their complete calendar day,
keeping the HUD rail narrow.
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
