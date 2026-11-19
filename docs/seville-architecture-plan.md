# Seville architecture

## Product direction

Obsivilian's primary goal is a personal, extended digital atlas of reality
across space and time for research projects and self-development. It draws
inspiration from [Calculating Empires](https://calculatingempires.net/about),
Kate Crawford and Vladan Joler's layered, navigable research visualization.
Obsivilian uses its own orientation and Node data; the reference is a guide to
scale and legibility rather than content to import.

The native Flutter client explores connected Nodes, searches, creates Nodes,
and reads and edits Markdown bodies.
Game development is delegated outside this client. The former Flame renderer
and declarative Layout system have been removed from the active frontend.

## Boundary

```text
Markdown folder or Git checkout -- explicit import --> Go scanner
                                                      |
                                                      v
                                               Neo4j canonical graph
                                                      |
                                            existing protobuf HTTP API
                                                      |
                                                      v
                                              Riverpod request state
                                                      |
                                                      v
                                           native Flutter workspace
```

Flutter never connects to Neo4j. It uses the `QUERY` graph and search
endpoints, `POST` Node creation, and `PATCH` body update. No SQL store, game
server, simulation loop, WebSocket transport, or Tiled map participates in the
knowledge client.

## Graph and interface

`Node.slug` is the unique Node identity. The global `NodeGraph` response is
bounded to 200 Nodes in the client; its unfiltered overview samples dated
Nodes across the full calendar range and fills remaining slots with other
Nodes. Selecting a Node opens a floating details
window without changing graph positions. A submitted Find term narrows the
global graph. Only connections whose endpoints are returned are visible.
`has_more` indicates a truncated view. Floating controls sit over the full
window graph and can open Find and the Node list.
The top-left Home control clears the search and open overlays, then restores
the opening pan and zoom without changing canonical Node data.

The Flutter workspace uses ordinary panes and text fields. `InteractiveViewer`
applies one pan and zoom transform to the virtual graph world. Positioned Node widgets handle
tap, hover, focus, and semantics, while `CustomPaint` draws connections from
the same world positions. The graph uses Forge2D circular bodies for
collisions and gentle continuous drift. The physics world advances at a fixed
time step and is rebuilt when graph membership or viewport size changes.
Connections remain visual until their physics rules are defined.

One canonical Node is focused at a time in the details window. The reader shows its
Markdown source.
The body editor keeps local unsaved text, warns before discarding it, and sends
the last observed `update_count` with the save request. A conflict leaves the
draft open. The creation dialog likewise keeps its local draft open until the
API accepts it. The client does not retain a `NodeSnapshot` or a Layout tree.

## Connections and source policy

Imported and edited bodies use the backend's existing Markdown connection
parser. Resolved references become `LINKS_TO` relationships. Missing or
ambiguous references remain unresolved records. Creating a Node can resolve
older unambiguous `[[slug]]` references. The native client does not duplicate
connection parsing or alter this policy.

The manual Obsidian import remains conservative: it creates unseen slugs and
does not overwrite existing canonical Nodes. Source synchronization would need
provenance, checkpoints, and explicit conflict policy before it could update
canonical data.

## Time plane and future dimensions

The time plane stands to the left of the central graph. Native Neo4j `DATE`
spans place calendar Nodes on shared start-date rows. Today's local date is
the central reference, future dates go above it, and older dates go below.
Its columns run Year, Season, Month, Week, Day toward the graph;
Day is nearest. There is no visible Range column. The timeline compresses
distant history logarithmically and gives crowded dates taller rows. The
camera can pan and zoom across the resulting virtual world. Calendar links
are display-only, chosen by span overlap; weeks
that cross months are joined to the month with the most overlap. Forge2D
resolves nearby collisions and adds gentle motion around those slots.
Placement is separate from Node identity and from color rules so future
planes can contribute their own anchors. The layout exposes dated row
coordinates for future process Nodes to align beside the calendar without
becoming calendar Nodes. Recurring seasons and months without
a specific year remain in the central graph until given a dated span. Legacy
general range spans also remain in the central graph.

**TODO — bottom location plane:** add a location hierarchy and positioning
backed by native Neo4j spatial `POINT` values. It should share the virtual
world, camera, and plane contract with time while preserving the same slug
identity. Keep top and right available for other dimensions; decide their
semantics from research use before assigning them.

**TODO — full timeline navigation:** add date-range paging or viewport queries
so the time plane can load every matching Node on demand. The current
200-Node graph is a chronological overview and `has_more` signals omitted
Nodes. Add scale-aware guide density when browsing large spans.

## Next product work

0. Establish the [quality baseline](quality-baseline.md): inventory current
   behavior, log code-visible and owner-observed issues separately, and use the
   macOS read path as the first manual verification pass.
1. Audit and polish the existing read flow first: loading, empty, error, refresh,
   Node selection, body display, and connection navigation. Record reproducible
   issues and have the owner verify each corrected slice in the macOS app.
2. Audit the remaining existing flows: global and local graph exploration,
   search, Node creation, body editing, and keyboard behavior.
3. Add a **Latest** tab to the base interface showing the most recently changed
   Nodes. The canonical Node currently exposes `modified_at`, not `updated_at`;
   confirm that its update semantics match the intended recency. A correct
   database-wide list needs server-side ordering before pagination or limiting.
   A client sort of the bounded graph is insufficient. Design the smallest
   query/API extension when the owner reopens backend and protobuf work.
4. Process `.concepts` and `.concept` files exported from Concepts on iPadOS and
   Android. Inspect representative files and export variants first, establish
   what content and metadata can be extracted, then design an explicit,
   repeatable import into canonical Nodes. Preserve source files and define
   stable identity and duplicate handling before adding ingestion code. This
   requires backend/import work only after the owner reopens that boundary.
5. Consider paging or clustering for larger graphs, followed by Markdown
   preview, backlinks, unresolved target navigation, and richer Node editing
   after the read experience and the two near-term additions are stable.

The project owner runs and debugs the application. Codex uses formatting and
static analysis; this repository does not use automated application tests.
