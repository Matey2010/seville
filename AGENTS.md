# Seville project context

## Canonical vocabulary

- Read and follow [`docs/vocabulary.md`](docs/vocabulary.md) before naming a
  domain entity, API message, database label, or node-backed layout concept.
- `Node` is Seville's primary data unit across Neo4j, Go, protobuf, and Flutter.
  Do not introduce `Note`, `SevilleNote`, or a redundant `Knowledge` container
  as the core entity.

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

## Automated testing policy

- Seville applications and services do not use automated tests. Do not add or
  retain unit, widget, integration, snapshot, or system tests.
- Do not add test dependencies, test targets, test runners, or CI/pipeline
  steps that execute tests.
- Use non-mutating static analysis and formatting checks where appropriate.
  The project owner verifies final behavior in the real application.

## Dart configuration style

- Model files put their primary public model immediately after imports. Follow
  it with that model's conditions, context, and directly associated definitions;
  supporting typedefs, keys, enums, helpers, and concrete specializations come
  afterward. Do not make readers cross a soup of implementation vocabulary to
  find the model that gives the file its name and reason to exist.
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
- Every `Layout` owns a `GridAxisVariable size`. `ColumnLayout` and `RowLayout`
  resolve child sizes along their main axis using `LayoutSize.fr`, `px`/`pt`,
  or `calculatedFr`; do not introduce separate flex or extent properties.
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
- Layout configuration creates conditions only through the `LayoutCondition`
  protocol factories, such as `LayoutCondition.hasActiveNodes()`,
  `LayoutCondition.nodeHighlighted()`, and
  `LayoutCondition.not(LayoutCondition.hasActiveNodes())`. Concrete condition
  implementations remain private.
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
- Every `LayoutPath.padding` is a `LayoutPathPadding`. Configure its `left`,
  `top`, `right`, and `bottom` values independently, or use
  `LayoutPathPadding.all(...)` for a uniform inset.
- Use `FanLayout` for graph-like content that fans from a root point
  instead of a rectangular grid. It must be owned by a `LayoutPath`; its Flame
  component projects every fan row into that path's resolved polygon. By
  default it grows inward, opposite to its `position` in the owning plane; set
  `growthDirection: LayoutDerivativeReference(...)` only when a specific target
  derivative must override that natural direction. Its final row follows the
  owning polygon boundary; do not add a parallel radius/semicircle renderer.
  Cardinal positions (`top`, `right`, `bottom`, and `left`) own a 180-degree
  fan, `LayoutRelativePosition.d(...)` owns a 90-degree fan, and other
  positions own a 360-degree fan. `FanSectionSizing.equal` divides sibling
  spans equally. `FanSectionSizing.directPartsWeighted` gives each occurrence
  `1 + visibleDirectPartCount` fraction units after `maxSectionCount` and depth
  limits are applied. Use the same calculated stops for paths, guides, labels,
  and hit testing.
  Configure data-level matching through the optional `nodeFilter`, whose
  `includeNodesMatching` and `excludeNodesMatching` lists contain structured
  `NodeSearchParameter` values. These filters belong to the tree API request
  and Riverpod provider identity, not to the painter. Include entries are
  OR-matched when present, exclude entries are always OR-matched, and a rejected
  occurrence prunes its traversal branch.
  Keep internal bands on a shared regular radius so polygon perspective does
  not visually widen the edge sections; only the final row reaches the owning
  polygon boundary. Final-row endpoints project the sizing policy's cumulative
  fractions onto the visible polygon boundary by path length, so triangular and
  trapezoidal perspective does not add unintended edge width.
  Fan `rowsConfig` are radial bands from root outward and
  `columnsConfig` are angular segments across the tree fan.
  LG Ergo keeps its always-available shallow fan under `top-plane`.
- Use `GraphLayout` for the selected Node pool at
  `safe-area/inner-circle-plane/wrapped-scene-square/scene-graph-plane/scene-graph`.
  It renders every Riverpod-selected Node through one Flame component. Arrange
  Nodes in equal centered cells, render each Node as a circle whose diameter is
  `nodeExtentFactor` of its cell, and shrink the cells as the selected set
  grows. Paint and hit-test from the same resolved circle geometry. Graph
  connections, distance, labels between Nodes, and alternate interaction modes
  remain future extensions; do not request a `NodeTree` for this layout.
- Use `PerspectiveGridLayout` in `LayoutPath.grid` when a path needs normal
  rows and columns projected inside its quadrilateral. `rowsConfig` and
  `columnsConfig` must be ordered maps of the same `GridAxisVariable` type; the
  map key owns identity, preventing IDs and measurements from drifting apart.
  Use `LayoutSize.fr` for flexible space, `LayoutSize.pt` (`px` alias)
  for fixed gaps, and `LayoutSize.calculatedFr` when a track is a computed
  fraction with a fallback value. Do not pad root screen or safe-area anchors
  in LG Ergo; each plane owns its own padding using `LayoutPath.padding` and
  `lgErgoLayoutDefaults.padding`, not fake grid tracks.
  The LG Ergo `top-plane` and `bottom-plane` are owned by
  `safe-area.layouts` and each owns a `FanLayout`. `cortex-bush` uses
  direct-parts-weighted sizing and excludes the shared space-time name matches;
  `time-fan` includes those matches and uses equal sizing. Keep the shared match
  list as the configuration dependency between their complementary filters.
  Future controls, radial branches, temporal bands, and overlays for those
  planes belong beneath those plane nodes rather than at the screen root.
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
  `ResolvedVaultNode.node` is the single source for tap/frontmatter behavior,
  and `ResolvedVaultNode.fillColor` is the single source for found/missing
  visuals. Node-backed layout visuals must not be optimistic: render a full
  background only when the configured node resolves against the snapshot; render
  only a border when it does not. Keep `fillColor` for manual/background fills
  that are not graph-node assignments.
- For compact Node labels, render the first assigned non-empty
  `Emoji.character` before textual metadata. Fall back to `Node.title`, then
  `Node.id`. Keep this priority in the shared Node presentation helper rather
  than implementing different selection rules in individual Flame components.
- Store `LayoutBackgroundElement` values in the parent `Layout.layouts` map.
  `orderPosition` is frontend stacking metadata: lower values paint first,
  while guides and content stay above background children.
- Use `StickmanLayout` for the simple center-scene human scale reference. Its
  logical body lives in vertical `0..1`, where `1.0` equals `heightCm`
  (currently 200cm), and its visible frame can extend beyond that, e.g.
  `-0.1..1.1`, for breathing room around the figure.
- Every renderable layout entity, including background elements and guides,
  must extend the base `Layout`. Keep geometry, dimensions, snapshots, and
  configuration records as non-renderable value objects.
- Renderable layouts are Flame components. Route taps through
  `LandscapeXlLayoutView.onLayoutTap` and return a `LayoutTapTarget` from the
  same geometry rendered by the component. Flutter widgets are reserved for
  the `GameWidget` host and explicitly introduced HUDs. `SearchHud` is the only
  HUD implementation today, so do not classify ordinary interface content as
  HUD to justify a widget. Do not build Flutter widget renderers, interaction
  layers, or hit boxes for layout content.
- `SearchHud` is the first explicit Flutter HUD exception. Its visibility and
  submitted value belong to `hudStateProvider`; its action-plane trigger
  remains a Flame-rendered `PanelLayout`. Additional ordinary layout content
  must not be reclassified as HUD merely because this overlay exists.
- Keyboard bindings resolve centrally in `lib/constants/keymap.dart` from
  Flutter hardware key events to application actions. The screen owns the one
  lifecycle keyboard handler and translates those actions into Riverpod
  notifier calls. Do not import providers into the keymap or duplicate key
  interpretation inside Flame components and HUD widgets.
- Classify layouts with `List<LayoutAttribute>` using lower-camel enum values.
  Put reusable computed geometry in attribute-provided derivatives and let
  explicit snapshots override only the values they specialize.

## Vault paths

- Backend graph paths are relative to the configured knowledge root:
  `SEVILLE_VAULT_PATH`, or `SEVILLE_GIT_REPOSITORY_PATH` plus
  `SEVILLE_GIT_VAULT_SUBPATH` when the Git source adapter is active.
- Shared vault path constants live in `seville/flutter/lib/constants/paths/`.
  Timeline paths belong to `DefaultTimelineVaultPaths` there; broader vault
  roots or concepts belong to sibling static classes such as `DefaultVaultPaths`.
- The current vault root directory is already `cortex`; never prefix configured
  default paths with `cortex/`.
- Use `DefaultVaultPaths.cortex` for the explicit cortex Node path. It should
  resolve to a real clickable graph node, not an empty vault-root sentinel.
  The renderer still treats empty root as a forgiving alias for older config,
  but new interactive node config should point at a concrete path.
- For example, use `time/century/ce/xxi-century`, not
  `cortex/time/century/ce/xxi-century`.
