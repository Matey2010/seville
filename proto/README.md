# Protocol Buffers

Canonical API contracts are grouped and independently versioned under
`seville/`. `seville/node/v2/node.proto` defines Nodes, assigned Emoji metadata,
snapshots, and connections;
`seville/system/v1/system.proto` defines database-wide system information,
including the backend-limited most frequently assigned Neo4j labels and the
running Go and Neo4j versions.
`seville/nodes/v1/tree.proto` defines occurrence-preserving Fan tree data,
structured Node filters, and the flat `NodeSearchQuery`/`NodeSearchResult`
contract used by `QUERY /api/v1/node/search`. It also owns the typed
`NodeCreateRequest` contract used by `POST /api/v1/node/` and the
`NodeMutationRequest`/`NodeMutationResult` contract used by
`PATCH /api/v1/node/`.
`seville/notification/v1/notification.proto` defines shared notification
severity vocabulary without prescribing a renderer or transport endpoint.
`Node` remains the primary data unit rather than an abstract knowledge
container. Its typed `update_count` records canonical backend mutations and is
never advanced by reads. Generated Go and Dart code is committed under `gen/`.

Contract vocabulary follows [`../docs/vocabulary.md`](../docs/vocabulary.md).
The v1 `knowledge.proto` contract was removed rather than retained as a second
source of terminology.

Regenerate all contracts from the repository root:

```sh
make -C scripts proto
```

The backend imports the generated module through the root `go.work` workspace.

## Notification v1

`NotificationType` has exactly four values: `info`, `error`, `warning`, and
`success`. `info` is protobuf value zero and therefore the default. Presentation
belongs to each consumer; the Flutter interface currently maps these values to
hardcoded blue, red, yellow, and green notification widgets respectively.
