# Protocol Buffers

Canonical wire contracts. Names follow [../docs/vocabulary.md](../docs/vocabulary.md).
Generated Go and Dart code lives in `gen/` and is committed.

| Package | Contents |
| --- | --- |
| `seville/node/v2` | `Node` (with labels, Emoji, temporal span), connections, `ApiError` |
| `seville/nodes/v1` | Graph, search, filter, create, body, label, and temporal requests |
| `seville/presentation/v1` | Node appearance ruleset |

Regenerate after editing any `.proto` file:

```sh
make -C scripts proto
```
