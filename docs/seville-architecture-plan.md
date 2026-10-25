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
Nodes in the client; selecting a canonical Node requests its local `LINKS_TO`
neighborhood. A submitted Find term narrows the global graph. Only connections
whose endpoints are returned are visible. `has_more` tells the user to narrow
a truncated view.

The Flutter workspace uses ordinary panes and text fields. `InteractiveViewer`
applies one pan and zoom transform to the graph. Positioned Node widgets handle
tap, hover, focus, and semantics, while `CustomPaint` draws connections from
the same cached normalized positions. Force positions settle when graph data
changes; there is no frame update loop.

One canonical Node is focused at a time. The reader shows its Markdown source.
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

1. Owner verification of graph, search, creation, body editing, and keyboard
   behavior in the macOS app; Pixel landscape remains experimental.
2. Better global graph exploration through paging or clustering while keeping
   backend limits explicit.
3. Markdown preview, backlinks, unresolved target navigation, and richer Node
   editing once the native workspace is stable.

The project owner runs and debugs the application. Codex uses formatting and
static analysis; this repository does not use automated application tests.
