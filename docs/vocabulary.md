# Seville Vocabulary

This document defines the shared language used across Seville. Code, database
labels, API contracts, layouts, documentation, and conversation should use the
same terms.

## Node

`Node` is Seville's primary data unit and the center of the system.

A node has a stable Seville `id` plus data such as title, body, tags,
frontmatter, Neo4j labels, emoji assignments, provenance, and timestamps. The
stable `id` is application identity; Neo4j labels are transported classification
metadata rather than Node identity. Neo4j `elementId()` is an internal database
locator and must not cross the API boundary.

Seville:

1. imports or creates nodes;
2. stores and connects nodes in Neo4j;
3. passes nodes through the Go API using `seville.node.v2` protobuf contracts;
4. resolves nodes into configurable Flutter layouts; and
5. renders and interacts with those layouts through Flame components hosted by
   Flutter.

Do not call the primary entity `Note` or `SevilleNote`. Markdown notes are one
possible source representation of nodes, not the domain model.

## Node connection

`NodeConnection` is a directed relationship from one node to another or to an
unresolved target reference. Its `kind` describes imported link syntax today;
Neo4j relationship types express richer domain meaning such as `PART_OF`.

Use `connection` for API/domain vocabulary. Use `relationship` when discussing
Neo4j specifically. Avoid generic `link` when the object is a durable graph
connection.

## Emoji

`Emoji` is typed presentation metadata assigned to a Node through a Neo4j
`HAS_EMOJI` relationship. Emoji identity and metadata remain distinct from the
Node while the API embeds assigned Emoji values in its Node representation for
convenient rendering and Riverpod consumption.

Node renderers use the first assigned non-empty `Emoji.character` as the
primary compact display label. They fall back to the Node slug when no
displayable emoji is assigned. Legacy title and ID values remain last-resort
compatibility labels only. Rendered slugs remain visibly identifiable as Node
references by using the owning layout defaults' prefix and suffix; LG Ergo uses
the familiar `[[slug]]` form. Search results intentionally show this wrapped
slug even when an Emoji is assigned because identity is the proposal's purpose.

`Node.labels` are classification strings, not Nodes and not compact Node
captions. The frontend presents them in property tables through the Flame
`ClassificationLabelComponent`. Each string receives its own shopping-tag
shape and a deterministic color from the owning `LayoutDefaults`; Neo4j does
not store frontend paint.

## Node snapshot

`NodeSnapshot` is the current bulk API representation of nodes, their
connections, import warnings, and source revision. It is transport, not the
canonical database. Neo4j remains the canonical live graph.

Flutter does not retain a `NodeSnapshot` in Riverpod state. Fans fetch their
own depth-limited trees, search fetches its own query results, and configured
Node references use focused lookup requests.

## Virtual Node

A virtual Node is a frontend draft represented by `ResolvedVaultNode` with
`isVirtual: true`. It participates in the same slug-identified selected-node
state and Graph layout as canonical Nodes, but it has not been created in
Neo4j. Flame renderers distinguish that status with a dashed Node border.
Submitting creates the first virtual Node as canonical `:New:Virtual` data and
replaces the draft in place with the backend response. Cancelling the interface
discards virtual Nodes with the rest of selection.

## Source adapter

A source adapter reads an external representation such as a local Git checkout
or Markdown folder and proposes nodes and connections to the ingestion layer.
Source formats do not define Seville's domain vocabulary and do not silently
overwrite newer canonical graph state.

## Layout

`Layout` is the configurable UI structure that decides where and how nodes are
presented. Layouts do not redefine node identity. They reference, resolve,
arrange, style, and expose interaction for nodes.

The layout map key is stable layout identity. `Layout.aliases` adds vocabulary
without replacing that identity. `Layout.size` uses `GridAxisVariable` and
`LayoutSize` for composition.

## Notification

`NotificationType` is shared protobuf vocabulary describing semantic severity:
`info`, `error`, `warning`, or `success`. It does not define color, duration,
placement, or widget structure. Flutter owns the current `ToastWidget`
presentation and Riverpod owns the active notification queue.

## Node search

Node search is a flat, structured query returning complete Nodes rather than a
relationship traversal. `SearchHudComponent` captures and submits the query,
Riverpod owns its asynchronous state, and `NodeListLayout` renders the result
inside the configured Flame layout tree. Selecting a search result changes the
same slug-identified active Node set used by Fan and Graph layouts.

## HTTP graph operations

`QUERY` is Seville's canonical HTTP method for safe, idempotent graph reads
with structured request bodies, including Node search and tree traversal.
`POST` creates a Node whose stable identity is assigned by the backend. `PUT`
means complete, idempotent replacement of a known Node resource, `PATCH` means
a partial Node mutation, and `DELETE` removes a known resource. The mutation
domain may use names such as `NodeMutationRequest`, but neither `CREATE` nor
`MUTATE` is a Seville HTTP method.

## Renderer

The renderer turns resolved layouts into visible, interactive geometry. All
current renderers are Flame components. Flutter owns application composition,
the `GameWidget` host, and transient `overlay_layers` popups/toasts; no HUD
exists today. Rendering and interaction must use the same component-owned
resolved geometry. A Flutter widget renderer or parallel widget hit box is not
a renderer in Seville's architecture.

Seville aims to become a strongly customizable data visualization,
import/export, and interaction tool with broad platform portability. The
current supported production runtime remains macOS until other targets are
implemented deliberately.

## Reserved distinctions

- `Node.id`: stable Seville identity.
- `Node.slug`: unique human-facing identity used by Flutter Riverpod selection,
  active renderer state, and compact Node labels.
- `Node.labels`: sorted or unsorted Neo4j classification metadata; no label is
  required to establish Node identity.
- `Node.update_count`: number of canonical backend mutation requests applied to
  the Node; reads and source imports do not increment it.
- `elementId(node)`: private Neo4j storage identity.
- `Node`: primary data unit.
- `Emoji`: typed metadata assigned through `HAS_EMOJI`.
- `Tag`: a graph classification connected to nodes.
- `Layout`: configurable presentation and interaction structure.
- `NotificationType`: shared notification severity, not presentation styling.
- `Panel`: a visible layout role, not a data entity.
- `NodeConnection`: API/domain edge.
- Neo4j relationship: stored graph edge.
- Protobuf: typed transport contract.
- Cypher: Go-to-Neo4j query language.
