# Seville Vocabulary

This document defines the shared language used across Seville. Code, database
labels, API contracts, layouts, documentation, and conversation should use the
same terms.

## Node

`Node` is Seville's primary data unit and the center of the system.

A node has a stable Seville `id` plus data such as title, body, tags,
frontmatter, provenance, and timestamps. The stable `id` is application
identity; Neo4j `elementId()` is an internal database locator and must not cross
the API boundary.

Seville:

1. imports or creates nodes;
2. stores and connects nodes in Neo4j;
3. passes nodes through the Go API using `seville.node.v2` protobuf contracts;
4. resolves nodes into configurable Flutter layouts; and
5. paints and interacts with those layouts through Flutter and Flame.

Do not call the primary entity `Note` or `SevilleNote`. Markdown notes are one
possible source representation of nodes, not the domain model.

## Node connection

`NodeConnection` is a directed relationship from one node to another or to an
unresolved target reference. Its `kind` describes imported link syntax today;
Neo4j relationship types express richer domain meaning such as `PART_OF`.

Use `connection` for API/domain vocabulary. Use `relationship` when discussing
Neo4j specifically. Avoid generic `link` when the object is a durable graph
connection.

## Node snapshot

`NodeSnapshot` is the current bulk API representation of nodes, their
connections, import warnings, and source revision. It is transport, not the
canonical database. Neo4j remains the canonical live graph.

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

## Renderer

The renderer turns resolved layouts into visible, interactive geometry. Flutter
owns application composition and widgets; Flame supports game-like graph
visualization and interaction. Rendering must use the same resolved geometry
for paint and hit testing.

Seville aims to become a strongly customizable data visualization,
import/export, and interaction tool with broad platform portability. The
current supported production runtime remains macOS until other targets are
implemented deliberately.

## Reserved distinctions

- `Node.id`: stable Seville identity.
- `elementId(node)`: private Neo4j storage identity.
- `Node`: primary data unit.
- `Tag`: a graph classification connected to nodes.
- `Layout`: configurable presentation and interaction structure.
- `Panel`: a visible layout role, not a data entity.
- `NodeConnection`: API/domain edge.
- Neo4j relationship: stored graph edge.
- Protobuf: typed transport contract.
- Cypher: Go-to-Neo4j query language.
