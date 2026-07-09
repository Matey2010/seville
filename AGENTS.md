# Seville project context

## Supported runtime

- Seville currently runs in production on macOS only.
- Treat web, Chrome, iOS, Android, Linux, and Windows as unimplemented unless
  the project owner explicitly says otherwise.
- When giving run or process-control instructions, use the macOS launcher:
  `./scripts/seville-interface`.
- Do not suggest `./scripts/seville-interface chrome` or other Flutter targets.

## Development ownership

- The project owner exclusively runs and debugs the final application.
- Codex implements requested changes and may run non-interactive static checks,
  such as formatting and analysis.
- Codex must not launch, build-run, or runtime-debug Seville, and must not
  request permission to do so.

## Dart configuration style

- Layout preset files expose their primary public configuration constant
  immediately after imports.
- Do not introduce a new model, layout type, guide type, renderer concept,
  painter helper, or configuration entity until the related existing codebase
  elements have been inspected and reuse or extension has been ruled out.
  If the project owner explicitly asks for a new entity, implement it; otherwise
  prefer connecting, deriving from, or extending the nearest existing concept.
- When two visual or layout elements are conceptually related, encode that
  dependency in configuration or derivatives instead of making them independent
  values that merely happen to align. A wrapped square should derive from the
  circle it wraps; connector lines should target the same geometry used by the
  painted shape.
- Keep the visible hierarchy ordered from the shallowest screen layer to the
  deepest nested layer. Supporting styles, frames, and other primitives belong
  below the primary configuration.
- Layout composition uses `Map<String, Layout> layouts`: the key is identity
  and the value is another layout. Frames, content, guidelines, and guide grids
  share this tree; do not introduce separate root, node, or guide collections.
- Use `Layout.aliases` for extra human/config vocabulary. The layout map key
  remains the stable address; aliases are alternative names, not identity.
- Generic layouts have default axes `[0, 0]`. Do not add axes, role tags, or
  frame metadata when the concrete layout type or guide geometry already
  expresses the behavior.
- Use `LayoutKey.innerBorder` with a subtle `LayoutBorderGuide` for meaningful
  visual boundaries. Prefer named `Point` anchors over anonymous coordinates
  when later layouts may connect to that border.
- Prefer automatically derived anchor directions from the owning border center
  unless a layout explicitly requires custom directional geometry.
- Store calculated geometry in named `LayoutDerivativeSnapshot` values instead
  of duplicating resolved coordinates. Runtime reactions belong to
  `LayoutObservable` descriptors and `LayoutDerivativeObserver`.
- Use `Guideline.guidelineDerivatives` plus `GuidelineMarker` for labels or
  emoji pinned to points along a specific guide line. Use this for line-local
  points such as a diagonal guide's center; do not confuse those with the
  owning layout's center derivative.
- Use `RayLayout` for geometry with a fixed origin and direction toward another
  derivative. Use layout paths for cross-layout references rather than copying
  resolved screen coordinates.
- Use `LayoutAreaRayLayout` when a ray should target a named
  `PerspectiveGridArea` position instead of a layout derivative; for example,
  target `position: LayoutRelativePosition.bottom` or
  `position: LayoutRelativePosition.d(90)` for the bottom of a grid area.
- Use `LayoutAreaToDerivativeRayLayout` for the reverse direction: starting at
  a named `PerspectiveGridArea` anchor and pointing toward a layout derivative.
- Use `LayoutPath` for filled/vector-like planes and polygons. Its points
  should be `LayoutDerivativeReference` values, so SVG-like path structures stay
  configurable instead of becoming painter-only geometry.
- Use `LayoutPath.pathPadding` with `LayoutPathPadding` when a plane needs
  side-specific visual insets. Keep legacy `LayoutPath.padding` only for
  uniform insets.
- Use `RadialTreeLayout` for graph-like content that grows from a root point
  instead of a grid. Its `root` is a vault path resolved by the same node
  folder/file conventions as `PerspectiveGridArea.node`. By default it grows
  inward, opposite to its `position` in the owning layout bounds; set
  `growthDirection: LayoutDerivativeReference(...)` only when a specific target
  derivative must override that natural direction. Use
  `layoutSize: LayoutSize.px/%/vw/vh/vmin/vmax(...)` to size its root without
  baking screen math into the painter. Use
  `LayoutSize.derivativeDistance(from: ..., to: ...)` when the tree size must
  follow actual geometry between two layout derivatives. Radial tree
  `rowsConfig` are radial bands from root outward, `columnsConfig` are angular
  segments across the tree fan, and `areas` are `RadialTreeArea` cells that can
  span both axes. Keep optional `RadialTreeArea.segments` for deeper local
  splits inside a branch area.
- Use `PerspectiveGridLayout` in `LayoutPath.grid` when a path needs normal
  rows and columns projected inside its quadrilateral. `rowsConfig` and
  `columnsConfig` must be ordered maps of the same `GridAxisVariable` type; the
  map key owns identity, preventing IDs and measurements from drifting apart.
  Use `GridTrackSize.fr` for flexible space, `GridTrackSize.pt` (`px` alias)
  for fixed gaps, and `GridTrackSize.calculatedFr` when a track is a computed
  fraction with a fallback value. The current LG Ergo bottom time grid is
  intentionally simple: rows `hour`, `day`, and `week` use shared `previous`,
  `current`, and `next` columns. `now` itself is not a grid column in this
  preset; render it as a red overlay `RayLayout`. Do not pad root screen or
  safe-area anchors in LG Ergo; each plane owns its own padding using
  `LayoutPath.padding` and `lgErgoLayoutDefaults.padding`, not fake grid tracks.
  The scene inner circle resolves through the
  owning layout's `padding + borderWidth`, while the outer circle remains the
  scene boundary for anchors and shape framing.
  Use `LayoutBorderGuide(useLayoutDefaults: true)` without derivative anchors
  when drawing the padded scene square between raw ABCD and the inner circle;
  derivative anchors intentionally snap back to raw ABCD.
  `left-plane` is the 12-segment x/space plane between scene-left and
  screen-left; its perspective grid contains only the real 12 space rows.
  Defer passed/left timeline-point adjustments to a later overlay
  layer. Keep content and paint in named `PerspectiveGridArea` values; areas
  reference track map keys and use `GridSpan.full` when they must continue
  through all remaining tracks, including tracks added later. Use
  `columnOffset`/`rowOffset` plus fractional spans when an area must consume
  part of a track. Use `PerspectiveGridArea.borderStyle` for dashed rim
  wrappers, such as left-plane outer-with-padding and inner-without-padding
  borders.
- For node-backed grid content, prefer `PerspectiveGridArea(node: path,
  VaultNode(path: ..., color: LayoutColor.fromHex(...)))`. Every layout that is
  backed by knowledge-base data should own a `VaultNode`; runtime lookup belongs
  only to `VaultNodeResolver`, which returns `ResolvedVaultNode extends
  VaultNode`. Do not duplicate node path resolution in screens or painters.
  `ResolvedVaultNode.note` is the single source for tap/frontmatter behavior,
  and `ResolvedVaultNode.fillColor` is the single source for found/missing
  visuals. Node-backed layout visuals must not be optimistic: render a full
  background only when the configured node resolves against the snapshot; render
  only a border when it does not. Keep `fillColor` for manual/background fills
  that are not graph-node assignments.
- Store `LayoutBackgroundElement` values in the parent `Layout.layouts` map.
  `orderPosition` is frontend stacking metadata: lower values paint first,
  while guides and content stay above background children.
- Use `StickmanLayout` for the simple center-scene human scale reference. Its
  logical body lives in vertical `0..1`, where `1.0` equals `heightCm`
  (currently 200cm), and its visible frame can extend beyond that, e.g.
  `-0.1..1.1`, for breathing room around the figure.
- Use `GraphPreviewLayout` for temporary graph-node placeholders inside the
  scene. Keep it config-only: normalized `GraphPreviewNode.position` values
  sketch where future database-backed nodes will live.
- Every renderable layout entity, including background elements and guides,
  must extend the base `Layout`. Keep geometry, dimensions, snapshots, and
  configuration records as non-renderable value objects.
- Painted layouts can still be interactive. Route taps through
  `LandscapeXlLayoutView.onLayoutTap` and return a `LayoutTapTarget` from the
  same geometry used by the painter, instead of layering invisible widgets with
  divergent hit boxes.
- Classify layouts with `List<LayoutAttribute>` using lower-camel enum values.
  Put reusable computed geometry in attribute-provided derivatives and let
  explicit snapshots override only the values they specialize.

## Vault paths

- Backend graph paths are relative to `SEVILLE_VAULT_PATH`.
- Shared vault path constants live in `interface/flutter/lib/constants/paths/`.
  Timeline paths belong to `DefaultTimelineVaultPaths` there; broader vault
  roots or concepts belong to sibling static classes such as `DefaultVaultPaths`.
- The current vault root directory is already `cortex`; never prefix configured
  default paths with `cortex/`.
- Use `DefaultVaultPaths.cortex` for the explicit cortex note path. It should
  resolve to a real clickable graph node, not an empty vault-root sentinel.
  The renderer still treats empty root as a forgiving alias for older config,
  but new interactive node config should point at a concrete path.
- For example, use `time/century/ce/xxi-century`, not
  `cortex/time/century/ce/xxi-century`.
