# Seville project context

## Canonical vocabulary

- Read and follow [`docs/vocabulary.md`](docs/vocabulary.md) before naming a
  domain entity, API message, database label, or node-backed layout concept.
- `Node` is Seville's primary API and domain data unit across Go, protobuf, and
  Flutter. Neo4j labels are optional classification metadata: no identifying
  label is required, and label presence must not decide whether a graph entity
  is a Node. Do not introduce `Note`, `SevilleNote`, or a redundant `Knowledge`
  container as the core entity.

## Supported runtime

- Seville currently runs in production on macOS only.
- Treat web, Chrome, iOS, Android, Linux, and Windows as unimplemented unless
  the project owner explicitly says otherwise.
- When giving run or process-control instructions, use the macOS Make target:
  `make -C scripts interface`.
- Do not suggest other Flutter targets.

## HTTP methods

- Use `QUERY` for safe, idempotent API reads whose structured request is sent
  in the body, including Node search and graph traversal.
- Use `POST` to create a Node when the server owns its stable identity. There is
  no `CREATE` HTTP method.
- Use `PUT` only for a complete, idempotent replacement at a known Node resource
  URI, and `DELETE` to remove the identified resource.
- Use `PATCH` for partial Node mutations. Do not introduce or restore a custom
  `MUTATE` HTTP method; mutation remains domain vocabulary only.

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
- Layout composition uses `Map<String, Layout> children`: the key is identity
  and the value is another layout. Frames, content, guidelines, and guide grids
  share this tree; do not introduce separate root, node, or guide collections.
- The declarative Layout layer is one Dart library rooted at
  `lib/models/layout/layout.dart`. Layout variants and configuration
  dependencies live beside it as `part` files under `lib/models/layout/`.
  Application code imports only the library entry point; do not scatter Layout
  models back into `lib/models/` or restore cross-imports between its parts.
- Treat `aliases`, `label`, `text`, `node`, and `panel` as the standard global
  Layout configuration sequence. Presets place `label` and `text` between
  `aliases` and `node`.
- Conditional values use the reusable ordered `LayoutState<T>` container.
  Every `Layout` exposes `state: LayoutState<LayoutConfig>`; each matching
  `LayoutConfig` specializes common configuration at the same stable tree key,
  and later matching entries override only values they explicitly configure.
  Conditional visibility belongs exclusively to `LayoutConfig.visible`; do not
  restore `Layout.visibility`. If any state entry configures visibility, the
  Layout is hidden until a matching entry resolves `visible: true`, with later
  matching visibility values taking priority. Declare stable values such as
  size and text color once on the base Layout. Conditional text, Node, Label,
  and Panel configuration merges over that base; an explicit conditional
  background list replaces the base list. State must not replace the Layout's
  runtime type, children, or tree position. `LabelConfig` and `NodeConfig` use
  the same ordered merge semantics. Do not restore parallel raw condition maps
  or duplicate their traversal loops.
- Every `Layout` exposes `label: LabelConfig`. `LabelConfig.style` owns
  the classification-label `LabelStyle`, while its ordered
  `state: LayoutState<LabelConfig>` resolves and merges like
  `NodeConfig`. Label hover uses `LayoutCondition.labelHighlighted()` and a
  conditional border style. Semantic label colors use
  `LayoutCondition.equalsTo(...)` state entries; `LabelStyle.color` is only the
  fallback for unmatched labels. All Label defaults, including the beige
  `#F5EDD6` fill, live under the first `LayoutCondition.always()` state entry;
  do not place default presentation directly in `LabelConfig.style`. Do not add
  `fillColors`, hash labels into a
  palette, or restore separate classification-label palette, border, hole,
  text, or hover fields on individual layouts.
  `LabelConfig`, `LabelStyle`, and `LabelDefaults` live together in
  `lib/models/layout/label.dart`. LG Ergo declares its complete global label
  policy once on the root `LandscapeXlLayout`.
- Every `Layout` exposes `text: LayoutTextConfig`. Its optional `value` is a
  typed `LayoutText`: use `none()` for inherited suppression, `lorem(length:)`
  for generated placeholder copy, `value(...)` for exact text,
  `format(..., parameters)` for `{parameter}` interpolation through the shared
  default representation, and `comment(...)` for exact text whose distinct
  presentation is reserved for later. General text color, dark/light contrast
  colors, font family and metrics, font features, and shadow effects remain in
  `LayoutTextConfig`. Panel text resolves from root through every ancestor to
  child; later non-null values override inherited values, so a child may
  replace an inherited `none()`.
  `PanelLayout` must not restore parallel `caption`, `labelColor`, or
  `labelSize` fields. Base `Layout.text` is empty; renderers seed
  `LayoutTextDefaults.config` once before merging the hierarchy so an
  unspecified child never resets its parent. When both contrast colors exist, renderers choose dark text
  for a light resolved background and light text for a dark background. Label
  captions use their resolved `LabelStyle.color` as that background and must
  not restore `LabelStyle.textColor` or painter-local contrast colors. The model
  and defaults live in `lib/models/layout/text.dart`. Tables, Node captions,
  and classification labels use `LayoutText.defaultRepresentation` rather than
  owning divergent object-to-text formatters.
- Every `Layout` exposes `node: NodeConfig`. `NodeConfig` directly owns Node
  presentation, including `slugPrefix`, `slugTransform`, and `slugSuffix`,
  while its ordered
  `state: LayoutState<NodeConfig>` recursively specializes the entire
  Node configuration. Resolve every matching condition in insertion order and
  merge later non-null values over earlier values. `NodeConfig` and
  `NodeDefaults` live together in
  `lib/models/layout/node_config.dart`, which remains part of the Layout model
  library until package extraction is justified. Keep base Node opacity,
  state-driven hover border, and slug defaults there. LG Ergo declares its
  shared highlighted-Node border directly at the top of `LandscapeXlLayout`.
  The older opacity fields remain temporarily active until Node renderers are
  migrated as one dedicated slice; do not create a second renderer path during
  this staging period.
  `NodeConfig.content` uses `NodeContent.slug()`, `.alias()`, `.emoji()`, or
  `.title()` to select one exact metadata source. Explicit content suppresses
  composite emoji-plus-slug rendering and paints nothing when that source is
  absent. It participates in normal `NodeConfig` state merging. LG Ergo's logo
  uses `NodeContent.emoji()` so highlight/selection styling never introduces
  its slug or title. Explicit Node content clamps its font size to the owning
  surface and must not be rejected by the composite Emoji-plus-slug size guard.
- Every `Layout` exposes `panel: PanelConfig`. Reusable panel vocabulary lives
  in `lib/models/layout/panel.dart`, not in a table-specific model. LG Ergo declares
  its shared folded panel size immediately after `node` on the root
  `LandscapeXlLayout`; table panels inherit that size through
  `TableConfig.panel` and may specialize it with their own `PanelConfig`.
- Every `Layout` owns a `LayoutSize size` directly. `ColumnLayout` and
  `RowLayout` resolve its primary dimension along their main axis using
  `LayoutSize.fr`, `px`/`pt`, `rem`, or `calculatedFr`; `rem` is a fixed extent
  multiplied by the root Layout's resolved text font size. Do not restore the redundant
  `GridAxisVariable` wrapper or introduce separate flex/extent properties.
  `RowLayout.crossAxisAlignment` optionally aligns intrinsic-height children
  through `LayoutCrossAxisAlignment.top()`, `.center()`, or `.bottom()`.
  Leaving it null preserves full-height stretching. An explicit
  `LayoutSize.secondary` controls a child's cross-axis extent; otherwise Flame
  derives it from the child's text, padding, and nested content. Flat paint,
  curved projection, backgrounds, and hit testing must share that geometry.
  `LayoutSize.twoDimensional(primary: ..., secondary: ...)` is the consolidated
  two-axis form. The owning renderer assigns geometric meaning to those axes;
  scalar consumers use `primary` and ignore an absent `secondary`.
  Shared panoramic chrome dimensions live in `LayoutDefaultSize`, a part of
  the Layout model library. Header, left-ribbon, their nested spacer tracks,
  footer height, and footer intersections reference its typed `LayoutSize`
  values instead of declaring preset-local constants.
- Use `Layout.aliases` for extra human/config vocabulary. The layout map key
  remains the stable address; aliases are alternative names, not identity.
- Do not add legacy axes, role tags, or frame metadata when the concrete layout
  type or guide geometry already expresses the behavior.
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
  `LayoutCondition.nodeHighlighted()`, `LayoutCondition.nodeSelected()`, and
  `LayoutCondition.not(LayoutCondition.hasActiveNodes())`. Concrete condition
  implementations remain private. Use `LayoutCondition.always()` for an
  ordered unconditional baseline, `LayoutCondition.equalsTo(...)` for one
  current contextual value, and `LayoutCondition.isIn(...)` for membership.
  Dart reserves `default` and `in`, so neither can be a named constructor.
- Use `Guideline.guidelineDerivatives` plus `GuidelineMarker` for labels or
  emoji pinned to points along a specific guide line. Use this for line-local
  points such as a diagonal guide's center; do not confuse those with the
  owning layout's center derivative.
- Use `LayoutSlotRayLayout` when a ray should target a named
  `GridSlot` position instead of a layout derivative; for example,
  target `position: LayoutRelativePosition.bottom` or
  `position: LayoutRelativePosition.d(90)` for the bottom of a grid slot's
  resolved area. `LayoutPathSlotReference.path`, `grid`, and `slot` address the
  owning path, its `GridLayout` child, and the named slot directly.
- Use `LayoutSlotToDerivativeRayLayout` for the reverse direction: starting at
  a named `GridSlot` anchor and pointing toward a layout derivative.
- Use `LayoutPath` for filled/vector-like planes and polygons. Its points
  should be `LayoutDerivativeReference` values, so SVG-like path structures stay
  configurable instead of becoming painter-only geometry.
- `LayoutPathCurve` replaces one structural edge through direct `from`,
  `through`, and `to` derivative references. Keep curve-only shaping
  derivatives out of `LayoutPath.points`; a quadrilateral remains four points
  for grids and other structural consumers. Curved `GridLayout`, `RowLayout`,
  and `ColumnLayout` descendants resolve on the same normalized surface, and
  paint and hit testing must use the same curved paths rather than clipping a
  flat composition. Curved `PanelLayout` captions project each glyph through
  the surface's local horizontal and vertical basis so text follows the same
  position, tangent, scale, and shear as its owning panel.
- Every `LayoutPath.padding` is a `LayoutPathPadding`. Configure its `left`,
  `top`, `right`, and `bottom` values independently, or use
  `LayoutPathPadding.all(...)` for a uniform inset.
- Use `FanLayout` for graph-like content that fans from a root point
  instead of a rectangular grid. It must be owned by a `LayoutPath`; its Flame
  component projects every fan row into that path's resolved polygon. Fan
  segments paint their resolved Node color and state overlay without owning an
  image background. LG Ergo configures the elder-brain artwork once on the
  `cortex-bush` Fan Layout surface; `time-fan` has no image background. By
  default it grows inward, opposite to its `position` in the owning plane; set
  `growthDirection: LayoutDerivativeReference(...)` only when a specific target
  derivative must override that natural direction. Its final row follows the
  owning polygon boundary; do not add a parallel radius/semicircle renderer.
  A two-point curved owning path uses the midpoint of those structural points
  as the Fan root and samples its configured curve as the outer boundary. The
  renderer closes that simple surface from both curve endpoints back to the
  root; do not require an opposite plane edge or add curve-only points to
  `LayoutPath.points`.
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
  occurrence prunes its traversal branch. Configure root discovery separately
  with `rootNodeFilter`; LG Ergo's top and bottom Fans and its logo
  `NodeLayout` share one exact Calendar-root filter for
  `cortex-timeline-calendar-2026-06-fr6h` instead of duplicating query values or
  using process environment configuration.
  Preserve every matching root as a depth-zero occurrence, capped by
  `maxSectionCount`. Divide the root band equally between matches before
  applying each root's normal child sizing policy; two roots occupy the two
  halves separated by the Fan's center ray.
  Keep internal bands on a shared regular radius so polygon perspective does
  not visually widen the edge sections; only the final row reaches the owning
  polygon boundary. Final-row endpoints project the sizing policy's cumulative
  fractions onto the visible polygon boundary by path length, so triangular and
  trapezoidal perspective does not add unintended edge width.
  Fan `rowsConfig` are radial bands from root outward and
  `columnsConfig` are angular segments across the tree fan.
  LG Ergo keeps its always-available shallow fan under `top-plane`.
- Use `GraphLayout` for the selected Node pool at
  `safe-area/panoramic-scene-plane/direction-pad/scene-graph`.
  The panoramic grid places it across all three 1fr rows of its center 2fr
  column between 1fr side columns; the Graph component must use that curved,
  resolved grid area rather than the complete owning path.
  It renders every Riverpod-selected Node through one Flame component. Arrange
  Nodes in equal centered cells, render each Node as a circle whose diameter is
  `nodeExtentFactor` of its cell, and shrink the cells as the selected set
  grows. Treat those as logical surface circles: sample each Node path through
  the complete inherited `LayoutPath`/Grid projection, and use that same warped
  path for clipping, paint, borders, taps, and hover. Scene Nodes always render
  their wrapped slug. When an Emoji exists,
  render it above the slug at `emojiFontSizeFactor` times the resolved
  `NodeConfig.text.fontSize`, separated by `emojiSlugGapFactor` times that same
  size; without an Emoji, center the slug. LG Ergo declares the shared 10px Fan
  and Graph typography once in the root `NodeConfig.text`, with a `2.0` Emoji
  factor and a `0.5` gap factor. Do not restore renderer-specific `labelSize`
  fields or a parallel font-size constant. Paint and hit-test from the same
  resolved projected geometry. `GraphLayoutComponent` owns Graph geometry,
  clipping, Node paint, labels, tap handling, and hover hit testing. The
  landscape game may resolve its owning `LayoutPath` and supply state/callbacks,
  but must not restore `_drawGraphLayout`, Graph geometry helpers, or Graph
  hit-testing inside `landscape_xl_layout_view.dart`. Graph
  connections, distance, labels between Nodes, and alternate interaction modes
  remain future extensions; do not request a `NodeTree` for this layout.
  A frontend-only draft is a normal selected `ResolvedVaultNode` with
  `isVirtual: true`; it is not yet canonical Neo4j data. Shared Node border
  rendering must use a dashed path and
  `LayoutDefaults.virtualNodeBackgroundOpacity` (0.5 by default) for virtual
  Nodes, while persisted Nodes retain the configured solid border and normal
  active/inactive opacity. The right-plane submit action creates the first
  virtual Node through `POST /api/v1/node/` with Neo4j labels `New` and
  `Virtual`, then atomically replaces that draft at the same selected-node
  index with the canonical Node returned by the backend.
  The right-plane top action row places the confirm action immediately beside
  the nuclear close action. Copy and Share remain in the second action row.
  Me is a visible, shared-width `PanelConfig` in the left info table. Keep the
  former right-plane `PanelLayout` commented beside that panel as the reference
  for its future global action; do not restore a live right-plane Me button.
  Direction controls belong to `panoramic-scene-plane/direction-pad`. Its
  three fractional scene rows and three fractional content columns represent
  top-left through bottom-right, including center; the center content column is
  wider than its side columns. A 4rem header and 2rem bottom ribbon are fixed
  rows around that core. A 4rem `left-ribbon` column precedes the content
  columns. The outer left-ribbon `GridLayout` spans every row, but reserves its
  first 4rem row so its nested `ColumnLayout` content starts beneath the header.
  The header is a direct `RowLayout` spanning the complete top row; do not wrap
  it in another Grid. A
  foreground `logo` slot owns their header/left-ribbon intersection and
  renders the aliased `brain-control` `NodeLayout`. It uses the exact shared
  top/bottom Fan root filter and renders its configured brain Emoji without a
  separate image background.
  Header panels remain direct children of
  that Row; do not restore a separate
  center-ribbon composition. The `footer` slot spans the complete 2rem bottom
  row, including its left-ribbon intersection. Its `RowLayout` contains a
  `LayoutDefaultSize.crossAxisRibbonWidth` start spacer, the flexible
  `bottom-ribbon` Panel, and a
  matching end spacer. `action-panel` spans only the three scene rows and must
  stop before this footer track. `info-grid` likewise spans from the first scene
  row after the header through the last scene row before the footer, including
  neither chrome row. Keep
  stable `direction-*` aliases in layout configuration;
  directional behavior remains a later interaction-policy concern.
- Use `NodeLayout` for one filter-backed Node. Its required
  `NodeSearchFilter filter` is the complete query identity and the provider
  always requests `limit: 1`; only the first returned Node renders. Its required
  `storedNode` is a frontend fallback, not a second query source. Activate that
  fallback only after a successful empty response, never while loading or after
  an error. Deep-copy it, ensure the `Virtual` Neo4j label and `isVirtual: true`,
  store it once in `selectedNodesProvider`, and render the same resolved value.
  A stored Node requires a non-empty slug and defaults its empty path to that
  slug. `NodeLayoutComponent` fills its complete dedicated projected surface;
  do not constrain it to GraphLayout's circular Node geometry or add a
  `nodeExtentFactor`. It owns paint, labels, tap, and hit geometry and delegates
  shared Node fill, dashed virtual border,
  emoji/slug presentation, and hover behavior to `NodeComponent`. It inherits
  the complete curved surface of its owning `LayoutPath` and uses the same
  projected path for paint and hit testing.
- Use `GridLayout` for named two-dimensional composition. It may be a
  `LayoutPath.children` entry and follows that path's straight, projective, or
  curved surface. `rowsConfig` and `columnsConfig` must be ordered maps of
  `LayoutSize`; the
  map key owns identity, preventing IDs and measurements from drifting apart.
  `GridLayout.slots` maps an area name to `GridSlot` geometry; each child
  requests an area through `Layout.slot`, while its `Layout.children` map key
  remains stable identity. A matching slot overrides the child's `size` for
  placement. `GridSlot.aliases` provides alternative area names; exact map-key
  matches take priority, then aliases resolve in slot map order. Slots reference
  named starting tracks and use `GridSpan.full` when they must
  continue through all remaining tracks, including tracks added later. Use
  `columnOffset`/`rowOffset` plus fractional spans when a slot must consume
  part of a track. Use `initialSpan: GridSlotSpan.content` with
  `maxSpan: GridSlotSpan.track` when a slot's initial vertical geometry should
  follow intrinsic content but remain capped by its named row; paint,
  backgrounds, and hit testing must share the area resolved from that slot. Do
  not restore `PerspectiveGridLayout`, `PerspectiveGridArea`, or
  `LayoutPath.grid`.
  Use `LayoutSize.fr` for flexible space, `LayoutSize.pt` (`px` alias)
  for fixed gaps, and `LayoutSize.calculatedFr` when a track is a computed
  fraction with a fallback value. Do not pad root screen or safe-area anchors
  in LG Ergo; each plane owns its own padding using `LayoutPath.padding` and
  `lgErgoLayoutDefaults.padding`, not fake grid tracks.
  The LG Ergo `top-plane` and `bottom-plane` are owned by
  `safe-area.children` and each owns a `FanLayout`. `cortex-bush` uses
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
  screen-left. Defer passed/left timeline-point adjustments to a later overlay
  layer.
- For node-backed grid content, place the node-backed layout under the matching
  `GridLayout.children` key. Every layout that is backed by knowledge-base data
  should own a `VaultNode`; runtime lookup belongs
  only to `VaultNodeResolver`, which returns `ResolvedVaultNode extends
  VaultNode`. Do not duplicate node path resolution in screens or painters.
  `ResolvedVaultNode.node` is the single source for tap/frontmatter behavior,
  and `ResolvedVaultNode.fillColor` is the single source for found/missing
  visuals. Node-backed layout visuals must not be optimistic: render a full
  background only when the configured node resolves through its focused Node
  query; render only a border when it does not. Keep `fillColor` for
  manual/background fills that are not graph-node assignments.
- `TableLayout.includeUnconfiguredFields` includes every populated data value
  not already represented by its configured rows. Use
  `unconfiguredFieldPanelId` to insert those alphabetical rows into their
  owning configured panel, and `unconfiguredFieldSize` for their tracks.
  Table structure belongs only to `TableLayout.tableConfig: TableConfig`.
  `TableConfig` is native Layout configuration and composes four required
  contracts: shared `panel`, ordered `panels`, `rowConfig`, and `columnConfig`.
  Do not restore parallel `TableLayout.columns`, table groups, or direct row
  maps. Panels, rows, and columns own ordered identity maps; `PanelConfig`,
  `TableRow`, and `TableColumn` use `orderPosition` without
  duplicating map identity as `id` or `key`. Do not restore the ambiguous
  `TableFieldBuilder` name.
  The nearest Layout `panel: PanelConfig` supplies inherited defaults, while
  `TableConfig.panel` specializes them. `PanelConfig.foldedPanelSize` owns the
  shared `LayoutSize` dimensions; each panel's `PanelConfig.size` is an explicit
  local
  override. `TableRow.size` and `TableColumn.size` independently control their
  tracks. Flame packs consecutive
  fractional-width panels into horizontal bands. LG Ergo's root layout uses one
  two-dimensional `LayoutSize` with `0.33fr` primary and secondary panel rules
  and does not repeat sizes on its table panels. Folding currently animates content tracks only;
  future panel-width animation remains a Flame renderer concern and must not
  add mutable state to `TableConfig`.
  For a two-dimensional table panel, Flame interprets `LayoutSize.primary` as
  panel width and `LayoutSize.secondary` as band height. A scalar size keeps
  the existing content-derived band height.
  These contracts live in `lib/models/layout/table_config.dart` as part of the Layout
  model library and use `LayoutSize` directly; do not extract or restore a
  `dart_tables` or `table_data` package without a real external consumer.
  `TableLayout` inherits the same `node: NodeConfig` protocol as every Layout,
  so Node-backed table content resolves conditional Node configuration without
  a parallel table styling model. Flame owns row resolution, geometry, hit
  testing, rendering, and action execution.
  `TableAction.copyToClipboard()` copies the text value of a row's first
  non-key cell. Derive its hit path during the same Flame paint pass and route
  clipboard, toast, and listener side effects through the screen callback also
  used by Command-C.
  `PanelConfig.title` is optional; render its title only when non-empty and when
  the panel contains populated rows, unless `PanelConfig.showEmpty` explicitly
  retains it. A titled `showEmpty` panel with no configured rows resolves as a
  title-only panel. Flame wraps every visible panel with
  `TableLayout.panelBorderStyle` and separates adjacent visible panels using
  `TableLayout.panelGap`. `PanelConfig.foldable` makes its title the fold toggle;
  the Flame scene owns transient expansion state and animates content tracks
  with an `EffectController` using `TableLayout.panelFoldDuration`. Keep this
  presentation state out of Riverpod and layout configuration. LG Ergo's single
  info table orders `last_selected_node`, `updates`, `selected_nodes`, `me`,
  `settings`, then `system`. Me and Settings inherit the shared one-third panel
  width and use `showEmpty: true`, so they remain available before their future
  rows and
  global behavior exist. The first group owns complete last-selected Node
  properties, Updates owns Added/Updated/Deleted frontend mutation rows,
  Selected Nodes owns the selected slug list followed by the deduplicated
  alphabetical label set, and System owns system data. The Added row owns the
  virtual-Node
  `NodeListLayout` as a child layout so it retains shared Node paint, hit-testing,
  selection, and sound behavior. Updated and Deleted are reserved empty rows;
  the Updates group remains absent until any mutation row has content. Empty
  panels emit no title, border, gap, or rows unless `showEmpty` retains them.
  Do not restore parallel or
  visibility-switched table instances.
- For compact Node labels, render the first assigned non-empty
  `Emoji.character` before textual metadata. Fall back to `Node.slug`; legacy
  title and ID values are only last-resort compatibility labels. When a slug is
  rendered, wrap it with the owning `NodeConfig.slugPrefix` and
  `slugSuffix`; LG Ergo uses `[[` and `]]`. Search result
  rows deliberately render the wrapped slug even when the Node has an Emoji.
  Render slug references with their stored casing and bold weight; do not use
  the Alegreya Sans SC face for them because its small-cap glyphs visually
  uppercase lowercase syntax. Emoji and ordinary interface captions continue
  to use the shared interface font. Paint every slug with the owning
  resolved `NodeConfig.slugColor`; the default and LG Ergo value are readable
  gold `#FFD54F`. `NodeConfig.labelColor` and `valueColor` own the
  related Node text colors, and LG Ergo declares all three once on the root
  Layout. Ordinary layout text uses ivory `#FFF8E7`. This applies to
  Node components and plain
  `TableLayout` values whose field keys are `slug` or `selected_node_slugs`;
  wrap every item through the resolved `NodeConfig` exactly once.
  Keep this priority and formatting in the shared Node presentation helper
  rather than implementing different rules in individual Flame components.
  Riverpod-selected
  Node identity and active renderer state use the unique slug, never `Node.id`.
- `Node.labels` are Neo4j classification metadata, not Nodes and not compact
  Node captions. `TableLayout` renders `labels` and `neo4j_labels` values
  through `ClassificationLabelComponent` as separate shopping-tag shapes
  instead of comma-separated text. Their semantic fill color, border, hole,
  and text colors belong to the root `LabelConfig`; Neo4j supplies only label
  strings. Label colors are decorative frontend knowledge-folder semantics,
  selected explicitly with `LayoutCondition.equalsTo(...)`, never inferred from
  a hash palette. Keep them on the table canvas so they obey its perspective.
  The component also owns the additional cursor-hover border resolved through
  `LayoutCondition.labelHighlighted()`; LG Ergo uses yellow.
- Every `Layout` exposes its own ordered `background` list. Concrete layout
  constructors must forward that base property. `orderPosition` is frontend
  stacking metadata: lower values paint first, while guides and content stay
  above background elements. Configuration uses the `LayoutBackground.color`,
  `image`, `guides`, and `conditional` factories, which retain typed concrete
  variants for renderer dispatch. Use the color factory for solid or
  translucent layout fills instead of concrete-layout `fillColor` properties.
  `LayoutPath` color and image backgrounds are clipped to the path's resolved
  polygon; quadrilateral image backgrounds use the same
  projective transform as `TableLayout`, so both image and content follow one
  perspective without separate renderer coordinates. `LayoutBackground.image`
  uses `repeat` as a positive horizontal tile count and normalized `position`
  inside each tile. Its `rotationDegrees` rotates clockwise around each tile's
  center, while positive `scale` uniformly scales around that same center;
  fit, transforms, and ancestor projection apply independently per tile.
  Background traversal must recurse through nested `GridLayout`, `RowLayout`,
  and `ColumnLayout` compositions so a leaf Panel paints in the exact projected
  frame used by its content.
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
  the `GameWidget` host and transient overlays. `LandscapeXlLayoutView` is the
  direct `Scaffold.body`; do not wrap it in a parallel HUD `Stack`. Do not build
  Flutter widget renderers, interaction layers, or hit boxes for layout content.
- Short repeated interface sounds use `flame_audio` `AudioPool` instances owned
  and disposed by `LandscapeXlLayoutGame`; do not put audio players in Riverpod
  notifiers or Node data. Node activation plays
  `assets/audio/technology-select.wav` only when the tapped Node changes from
  inactive to selected, not when it is deselected. Cursor entry into a rendered
  Node plays pooled `assets/audio/stone-scrap.wav`; deduplicate by rendered Node
  hit identity so pointer movement within the same geometry remains silent.
  The same exact hit geometry feeds `NodeComponent`, which owns ordinary Node
  background/border paint and the additional hover border configured by
  the target hierarchy's `NodeConfig.state` entry for
  `LayoutCondition.nodeHighlighted()`. Do not restore a parallel
  `nodeHoverBorderStyle` Layout parameter. Keep hover paint in the Node Flame
  component above ordinary layout content and below explicit HUDs; the game
  host may route pointer identity for sound but must not implement the visual.
- The macOS game cursor hides the native pointer through Flame's
  `Game.mouseCursor` hook and paints `_GameCursorComponent` at the Flame pointer
  position. Keep its position, animation, and lifecycle inside the game; do not
  add a cursor plugin or cursor-following Flutter overlay.
- Alegreya Sans SC is the shared interface font. Keep its OFL-licensed files in
  `frontend/flutter/assets/fonts/alegreya_sans_sc/`, register weights in
  `pubspec.yaml`, and preload them through `SevilleTypography.ensureLoaded()`
  before `runApp`. Material widgets inherit the family from the application
  theme; every raw Flame/canvas `TextStyle` must set
  `SevilleTypography.fontFamily` explicitly because `TextPainter` does not
  inherit the widget theme. Do not fetch fonts at runtime.
- `SearchHudComponent` is a Flame HUD owned by `LandscapeXlLayoutGame`. It owns
  its visible state, text draft, drawing, Flame keyboard subscription, and
  Flame-native Node option components. The action-plane Search button and
  Command-F open it. Enter submits a draft without hiding the HUD; after results
  arrive, arrows move through options and Enter or a tap selects a Node and
  closes the HUD. Escape hides it before dispatching the global cancel callback.
  Search must not use a Flutter popup, `OverlayScaffold`, or focus-based text
  field.
- `SearchLayout` is the Search HUD's layout configuration and Flame render
  frame. LG Ergo owns it at `safe-area/search-layout`, where it resolves to the
  complete safe-area bounds and stacks above ordinary scene/action-panel
  content. Its configuration owns Search padding, input and option dimensions,
  maximum width, visible option count, and input-to-options gap. Do not restore
  screen-coordinate or MediaQuery padding calculations inside
  `SearchHudComponent`.
- Search submission from the Flame HUD writes one normalized value to
  `interfaceOverlayStateProvider`. `nodeSearchProvider` sends that value
  through `QUERY /api/v1/node/search`. Results are Node-backed Flame option
  components rendered directly beneath the Search input. They use the shared
  selected-node slug set and toggle `selectedNodesProvider` through a callback
  supplied by the screen, including the normal Node-selection sound.
  The info-table Updates/Added field uses
  `NodeListDataSource.virtualNodes` and reads the `isVirtual` subset of selected
  Nodes; keep its dashed border and tap behavior on the same shared Node cycle.
- Toast producers append `ToastEvent` values only through `toastProvider`. Its
  Riverpod state is a durable queue until dismissal; `ToastOverlayPresenter`
  calls the public `overlay_layers` API without mounting an invisible layer in
  the `Scaffold`. It owns the top-right `ToastWidgets`, three-second dismissal,
  and overlay cleanup. Keep this boundary compatible with replacing
  the hosted dependency by `packages/overlay_layers`; do not import
  `overlay_layers` into actions, Flame components, or Riverpod notifiers.
  Every event carries the protobuf `NotificationType`. `ToastWidget` is the
  Flutter widget body and currently owns the fixed mappings: info blue
  `#1976D2`, error red `#D32F2F`, warning yellow `#F9A825`, and success green
  `#388E3C`. Do not move colors into protobuf.
- Keyboard bindings resolve centrally in `lib/constants/keymap.dart` from
  Flutter hardware key events to application actions. `SearchHudComponent` is
  the game's keyboard-handler component and translates actions into callbacks;
  the screen supplies Riverpod-backed callback implementations. Do not import
  providers into the keymap or Flame component. Command-R refreshes
  every currently watched Fan `NodeTree` provider through the screen action.
  Command-C copies the last Riverpod-selected Node slug through the same screen
  action used by the Flame-rendered copy button.
  Plain Enter dispatches the right-plane submit action unless the Search HUD is
  visible. While visible, the component consumes Enter to submit its local
  draft or select its highlighted Node option.
  `SevilleKeymapAction.cancel` is the global nuclear cancel action. Both Escape
  and the right-plane cross dispatch it through the screen; it clears selected
  and virtual Nodes, clears cached/search-visible results, closes the Search HUD,
  and closes the selected-node scene. Keep these effects on one action path.
- Classify layouts with `List<LayoutAttribute>` using lower-camel enum values.
  Put reusable computed geometry in attribute-provided derivatives and let
  explicit snapshots override only the values they specialize.

## Vault paths

- Backend graph paths are relative to the configured knowledge root:
  `SEVILLE_VAULT_PATH`, or `SEVILLE_GIT_REPOSITORY_PATH` plus
  `SEVILLE_GIT_VAULT_SUBPATH` when the Git source adapter is active.
- The current vault root directory is already `cortex`; never prefix configured
  default paths with `cortex/`.
- For example, use `time/century/ce/xxi-century`, not
  `cortex/time/century/ce/xxi-century`.
