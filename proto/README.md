# Protocol Buffers

The canonical API contract is `seville/node/v2/node.proto`. `Node` is the root
data unit; snapshots and connections are defined around nodes rather than an
abstract knowledge container. Generated Go and Dart code is committed under
`gen/`.

Contract vocabulary follows [`../docs/vocabulary.md`](../docs/vocabulary.md).
The v1 `knowledge.proto` contract was removed rather than retained as a second
source of terminology.

Regenerate it from the repository root:

```sh
./scripts/generate-proto
```

The backend imports the generated module through the root `go.work` workspace.
