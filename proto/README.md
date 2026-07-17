# Protocol Buffers

Canonical API contracts are grouped and independently versioned under
`seville/`. `seville/node/v2/node.proto` defines Node snapshots and connections;
`seville/system/v1/system.proto` defines database-wide system information.
`seville/nodes/v1/tree.proto` defines occurrence-preserving radial tree data.
`Node` remains the primary data unit rather than an abstract knowledge
container. Generated Go and Dart code is committed under `gen/`.

Contract vocabulary follows [`../docs/vocabulary.md`](../docs/vocabulary.md).
The v1 `knowledge.proto` contract was removed rather than retained as a second
source of terminology.

Regenerate all contracts from the repository root:

```sh
./scripts/generate-proto
```

The backend imports the generated module through the root `go.work` workspace.
