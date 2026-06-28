# Graph Recovery Sprint

## Outcome

Seville now has a complete read-only path from an Obsidian vault to a Flutter
graph:

```text
Markdown files -> Go scanner -> SQLite -> protobuf HTTP snapshot
               -> Flutter graph model -> deterministic layout -> Flame canvas
```

The backend recognizes `[[wikilinks]]`, `[[target|aliases]]`, heading
fragments, embeds, and local Markdown links. It resolves links by vault-relative
path, source-relative path, and unique filename. The Flutter client draws only
resolved links whose two notes pass the current tag filter.

## Fast path

1. Copy configuration and point it at the real vault:

   ```sh
   cp .env.example .env
   ```

   Set `SEVILLE_VAULT_PATH` in `.env`. Keep the default local URL and token for
   a local-only run.

2. Start and inspect the backend:

   ```sh
   ./scripts/seville start
   ./scripts/seville status
   ```

3. Start the macOS graph:

   ```sh
   ./scripts/seville-interface
   ```

4. After changing vault files, refresh the backend and click the refresh icon
   in the client:

   ```sh
   ./scripts/seville rescan
   ```

5. Stop the background service:

   ```sh
   ./scripts/seville stop
   ```

## The two-hour scope

The sprint deliberately favors one demonstrable vertical slice:

| Time box | Deliverable |
| --- | --- |
| 0–20 min | Confirm repository, scanner, API, and Flutter build health |
| 20–65 min | Convert protobuf notes and resolved links into a graph model |
| 65–95 min | Render weighted, colored nodes and typed edges with stable layout |
| 95–115 min | Add model tests and run Go/Flutter checks |
| 115–120 min | Record commands, rules, limits, and the next cut |

## Visual rules

Edit `interface/flutter/lib/graph/graph_rules.dart` and hot-reload Flutter.
`sevilleGraphRules` is the single policy object.

### Color

`tagColors` is ordered. The first tag in that map which exists on a note wins.
A note without a configured tag gets `fallbackColor`.

### Size

Each visible resolved edge adds its kind's `edgeWeights` value to both endpoint
notes. Radius is:

```text
baseNodeRadius + weightedDegree * radiusPerWeight
```

The result is capped at `maxNodeRadius`. The defaults count wiki links as
`1.0`, Markdown links as `0.75`, and embeds as `1.5`.

### Edges

`edgeColors` controls color by protobuf `LinkKind`. Thickness also increases
with the link weight. Unresolved links remain in the snapshot for diagnostics
but are intentionally absent from the graph.

### Position and labels

Positions are seeded from stable note IDs and refined with a deterministic
force simulation, so reloads do not randomly reshuffle the vault. The 24 notes
with the highest visible weighted degree receive labels. Above 250 visible
notes, the prototype skips the quadratic force simulation and uses stable
seeded positions to remain responsive.

Three Cortex timeline concepts are fixed as world anchors:
`cortex/time/concept/past` at bottom-left, `now` at bottom-center, and `future`
at bottom-right. They occupy a dedicated rail near the physical bottom of the
viewport. Other nodes are constrained above that rail, leaving the timeline
visually distinct while their links still connect into the graph.

## Code map

| File | Responsibility |
| --- | --- |
| `backend/internal/scanner/scanner.go` | Parse notes, tags, and links; resolve targets |
| `interface/flutter/lib/data/seville_api.dart` | Fetch and decode the snapshot |
| `interface/flutter/lib/graph/graph_rules.dart` | User-owned visual policy |
| `interface/flutter/lib/graph/graph_model.dart` | Snapshot-to-graph conversion |
| `interface/flutter/lib/graph/graph_layout.dart` | Stable force layout |
| `interface/flutter/lib/graph/graph_field.dart` | Flame canvas rendering |
| `interface/flutter/lib/main.dart` | Loading, filtering, status, and legend |

## Verification

Run all current automated checks:

```sh
go test ./backend/...
cd interface/flutter
flutter analyze
flutter test
```

The Flutter model tests cover visibility, unresolved-link exclusion, edge-kind
weighting, node sizing, and ordered tag-color rules.

## Known limits and next cut

This is the recovered prototype, not the final navigation experience.

- There is no node selection, pan/zoom, hover card, or note opening yet.
- The client reload is manual; it does not poll the snapshot ETag.
- Color rules are Dart constants rather than user-editable JSON/YAML.
- Ambiguous same-name wikilinks stay unresolved unless their path disambiguates
  them.
- Large-vault layout needs a spatial index or an offline/precomputed layout.

The highest-value next slice is pan/zoom plus tap-to-inspect, followed by a
small external rules file. Those additions can build on the current graph
model without changing the scanner or API contract.
