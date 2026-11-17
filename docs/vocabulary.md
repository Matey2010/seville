# Seville vocabulary

## Node

`Node` is Seville's primary data unit across Neo4j, Go, protobuf, and Flutter.
Its stable `id` is application identity. Its `slug` is a human-readable
reference, commonly displayed as `[[slug]]`. Title, Markdown body, tags,
frontmatter, Emoji, timestamps, and Neo4j labels are Node data or metadata.
Neo4j labels classify a Node; no particular label is required to make an
entity a Node. Neo4j `elementId()` remains internal to storage.

Do not call the core entity Note or SevilleNote. Markdown files are an optional
import representation, not the canonical live database.

## NodeConnection

`NodeConnection` is a directed API connection from one Node toward a resolved
Node or an unresolved target reference. Its kind records Markdown connection
syntax. Neo4j relationships store resolved connections; `LINKS_TO` is the
relationship shown in the current graph view. Other relationship types, such
as `PART_OF` and `FAMILY`, remain separate.

## NodeGraph and search

`NodeGraph` is a bounded API response containing canonical Nodes and
connections between them. An empty root requests a global view; a selected
Node's stable ID requests a local neighborhood. A submitted search term can
narrow the global view. Search results are complete Nodes, not graph layout
objects. `NodeSnapshot` remains a bulk transport representation and is not
retained as client state.

## Draft

A creation draft is local Flutter form state until `POST /api/v1/node/` returns
a canonical Node. It is not a Neo4j Node yet and does not need a synthetic
Layout or renderer identity. The focused canonical Node is identified by its
stable `id`; body edits use its `update_count` to detect stale writes.

## Source adapter

A source adapter reads a Git checkout or Markdown folder for explicit import.
Sources do not silently overwrite canonical Neo4j content.

## Client presentation

Flutter widgets own screens, text, controls, interaction, and accessibility.
The graph uses Flutter's `InteractiveViewer` for pan and zoom, positioned Node
widgets for interaction, and `CustomPaint` for connections. Forge2D supplies
circular Node collisions and gentle drift in both graph views; connections do
not constrain the physics yet. Riverpod holds asynchronous API request state.
The former declarative Layout and Flame layers are retired from the active
client.
