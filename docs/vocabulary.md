# Obsivilian vocabulary

## Node

`Node` is Obsivilian's primary data unit across Neo4j, Go, protobuf, and Flutter.
Its unique, human-readable `slug` is application identity, commonly displayed
as `[[slug]]`. Do not add a separate Node `id` or UUID property. Title, Markdown body,
frontmatter, Emoji, timestamps, and Neo4j labels are Node data or metadata.
The reserved Neo4j `:Node` label marks every canonical Node and lets the
database enforce unique slugs. It is hidden from user-facing label editing,
search, and display. Other Neo4j labels classify Nodes. Neo4j `elementId()`
remains internal to storage.
Startup rejects duplicate slugged records before applying `:Node`; normal
Node operations address only `:Node` records by slug.

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
Node's slug requests a local neighborhood. A submitted search term can
narrow the global view. Search results are complete Nodes, not graph layout
objects. `NodeSnapshot` remains a bulk transport representation and is not
retained as client state.

## Time and location planes

An optional temporal span on a Node is canonical Neo4j data: an inclusive
`DATE` start and exclusive `DATE` end. It determines placement in the time
plane left of the graph and does not change the Node's slug or create another
entity. Today's local date is the central row, future dates extend upward,
and older dates extend downward. Nodes starting on the same date share a
horizontal row.
Columns run Year, Season, Month, Week, Day from left to right, so Day is nearest
the graph. Legacy general ranges remain in Node data but have no timeline
column. A week may overlap two months, so visual grouping does not imply a
strict `PART_OF` relationship.

The bottom location plane is planned. It will use native Neo4j spatial `POINT`
values and location hierarchy data; no location coordinates are inferred from
Node labels or slugs. The plane system leaves top and right unassigned.

## Draft

A creation draft is local Flutter form state until `POST /api/v1/node/` returns
a canonical Node. It is not a Neo4j Node yet and does not need a synthetic
Layout or renderer identity. The focused canonical Node is identified by its
slug; body edits use its `update_count` to detect stale writes.

## Source adapter

A source adapter reads a Git checkout or Markdown folder for explicit import.
Sources do not silently overwrite canonical Neo4j content.

## Client presentation

Flutter widgets own screens, text, controls, interaction, and accessibility.
The graph uses Flutter's `InteractiveViewer` for pan and zoom, positioned Node
widgets for interaction, and `CustomPaint` for connections. Forge2D supplies
circular Node collisions and gentle drift in the visible graph; connections do
not constrain the physics yet. Selecting a Node leaves graph positions intact
and opens a floating detail window. Riverpod holds asynchronous API request state.
The former declarative Layout and Flame layers are retired from the active
client.

## Node appearance rule

A Node appearance rule is shared presentation configuration, not a canonical Node.
It matches one Node field (label, slug, title, or a named frontmatter
value) using case-insensitive exact, contains, or starts-with matching. Among
enabled matching rules, the highest integer weight wins; list order breaks
ties. A rule supplies a `#RRGGBB` fill color, a multiplier for the pull toward
its resting position, and a multiplier for its visible and colliding size.
Existing rules use 1× for both multipliers. The ordered ruleset has a revision
to prevent stale edits from replacing changes made on another device.
Label rules color Nodes and their label chips; Neo4j labels are the only
user-facing classification. Adding or removing labels edits one Node. Renaming
or deleting a label changes every canonical Node that carries it.
