# Seville architecture

## Product direction

Seville is a graph-centered knowledge base. Its native Flutter client explores
connected Nodes, searches, creates Nodes, and reads and edits Markdown bodies.
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

The Go API and Neo4j remain unchanged during the client simplification.
Flutter never connects to Neo4j. It uses the existing `QUERY` graph and search
endpoints, `POST` Node creation, and `PATCH` body update. No SQL store, game
server, simulation loop, WebSocket transport, or Tiled map participates in the
knowledge client.

## Graph and interface

`Node.id` is stable identity. The global `NodeGraph` response is bounded to 150
Nodes in the client; selecting a canonical Node opens a split modal with its
details on the left and its local `LINKS_TO` graph on the right. The back arrow
closes the modal and returns to the global graph. A submitted Find term
narrows the global graph. Only connections whose endpoints are returned are
visible. `has_more` tells the user to narrow a truncated view.
Graph-only mode hides the app bar, search, and Node list so the global graph
fills the window. Its overlay control or Command-backslash restores the
interface.

The Flutter workspace uses ordinary panes and text fields. `InteractiveViewer`
applies one pan and zoom transform to the graph. Positioned Node widgets handle
tap, hover, focus, and semantics, while `CustomPaint` draws connections from
the same normalized positions. Both graphs use Forge2D circular bodies for
collisions and gentle continuous drift. The physics world advances at a fixed
time step and is rebuilt when graph membership or viewport size changes.
Connections remain visual until their physics rules are defined.

One canonical Node is focused at a time in the modal. The reader shows its
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

The manual Obsidian import remains conservative: it creates unseen IDs and
does not overwrite existing canonical Nodes. Source synchronization would need
provenance, checkpoints, and explicit conflict policy before it could update
canonical data.

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
