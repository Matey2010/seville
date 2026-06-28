# Protocol Buffers

The canonical API contract is
`seville/knowledge/v1/knowledge.proto`. Generated Go code is committed under
`gen/go`.

Regenerate it from the repository root:

```sh
./scripts/generate-proto
```

The backend imports the generated module through the root `go.work` workspace.
