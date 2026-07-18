# Seville HTTP API conventions

This document defines how Seville names, versions, and transports HTTP API
data. New endpoints should follow these rules unless an endpoint documents a
specific compatibility exception.

## Route structure

Application routes use this structure:

```text
/{group}/v{major}/{resource}
```

- `group` is a stable product area such as `system` or `nodes`.
- The major version belongs to that group. A breaking system API change moves
  `/system/v1/...` to `/system/v2/...` without forcing unrelated APIs to move.
- Route segments use lowercase kebab-case when more than one word is needed.
- Resource names are nouns. HTTP methods express the operation.
- Health checks that carry no application data may remain unversioned, such as
  `GET /healthz`.

## Field names and generated names

Protocol Buffer definitions are the canonical wire contracts. Their fields use
`snake_case`:

```proto
uint64 node_count = 1;
uint64 node_property_count = 2;
```

Generated language bindings follow their language conventions without manual
renaming:

| Context | Example |
| --- | --- |
| Protobuf source | `node_property_count` |
| Dart | `nodePropertyCount` |
| Go | `NodePropertyCount` |
| Protobuf JSON, if explicitly offered later | `nodePropertyCount` |

Do not use `nodes_amount`, `node_amount`, or hand-written casing aliases.
Countable entities use the `_count` suffix. Database-wide counters use
`uint64`; an implementation must reject an invalid negative database result
before converting it to the unsigned wire type.

Successful typed responses use `Content-Type: application/x-protobuf` and the
message defined by the endpoint's protobuf package. JSON is not an implicit
second contract. If JSON is added later, use standard protobuf JSON mapping
rather than separately named fields.

Authenticated application routes require the existing bearer token. Errors use
the existing typed API error response until a shared error package replaces it.

## System v1

The first system endpoint is:

```text
GET /system/v1/info
```

It returns a `seville.system.v1.SystemInfo` message:

```proto
message SystemInfo {
  uint64 node_count = 1;
  uint64 node_property_count = 2;
}
```

`node_count` is the number of Neo4j nodes labeled `Node` that have a non-empty
stable Seville `id`. It does not count `Tag` nodes, alias records, unresolved
connection records, or relationships.

`node_property_count` is the total number of stored Neo4j property assignments
across those same stable Nodes. If one stable Node has `id`, `title`, and
`body`, it contributes three. The metric counts assignments, not distinct
property keys. Relationship properties and properties attached to other labels
are excluded.

The storage query should compute both values from one graph view so they
describe the same instant:

```cypher
MATCH (node:Node)
WHERE node.id IS NOT NULL AND trim(toString(node.id)) <> ''
RETURN count(node) AS node_count,
       sum(size(keys(node))) AS node_property_count
```

A distinct count of property names would be a different future metric named
`node_property_key_count`; it must not change the meaning of
`node_property_count`.

## Nodes v1

`GET /nodes/v1/tree` returns a `seville.nodes.v1.NodeTree`. The optional
`root_node_id` query field overrides `SEVILLE_ROOT_NODE_ID`; one of them must
provide the stable root Node ID. The optional unsigned `depth` defaults to `3`,
with the root at depth zero.

The endpoint follows incoming `PART_OF` relationships, stored as
`(child)-[:PART_OF]->(parent)`. Each traversal path produces its own
`NodeTreeOccurrence`, identified independently from its Node. Repeated Nodes
and cycles are therefore preserved until the requested depth instead of being
deduplicated.

## Implementation boundary

Contracts live under the corresponding versioned package in `proto/seville/`.
The backend queries Neo4j through the store and exposes authenticated read-only
handlers. Flutter consumes generated protobuf types rather than decoding
untyped maps.

Every returned `seville.node.v2.Node` includes its typed `emojis` collection,
hydrated from outgoing `HAS_EMOJI` relationships. This applies consistently to
both snapshot Nodes and Nodes embedded in tree occurrences.

This endpoint reports current canonical database state. It must not scan a
vault, run migration logic, mutate graph data, or derive its values from the
legacy import snapshot.
