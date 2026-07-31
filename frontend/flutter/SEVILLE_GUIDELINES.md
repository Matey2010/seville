# Seville Flutter Guidelines

See `CUSTOM_LAYOUTS.md` for the complete model → constants → component registry
workflow, including nesting, radial slots, perspective surfaces, responsive
scaling, and animation.

## Layout type taxonomy

- `LandscapeXlLayout` owns the full-screen landscape hierarchy. It extends
  `Layout` and nests every child under a stable key in `Layout.children`.
- `SafeAreaLayout`, `PlaneLayout`, `LayoutPath`, `GridLayout`, `ColumnLayout`,
  and `RowLayout` describe the active screen's structural composition.
- `GridLayout` combines ordered row and column tracks with named `GridSlot`
  placements. Slot keys address the same children in the ordinary
  `Layout.children` tree.
- `FanLayout` renders graph trees in radial bands, while `GraphLayout`
  renders the selected Node pool in equal centered cells.
- `TableLayout` and `SearchLayout` describe the active information and
  search surfaces.
- `Guideline`, `LayoutBorderGuide`, `CirleLayout`, and the ray layouts
  keep visual geometry in the same recursive layout tree as content.
- `Point` and `Coord` provide named, reusable geometry. `LayoutSize`
  provides scalar or two-dimensional sizing without legacy axis wrappers.

The retired open-box, perceptual-map, and calendar-timeline model families are
not part of the current layout protocol. Add new behavior by composing the
active layout tree and extending an existing model where its semantics fit.

## Curved composition surfaces

`LayoutPathCurve` identifies a structural edge with direct `from` and `to`
derivative references and a shaping derivative in `through`. Keep curve-only
derivatives out of `LayoutPath.points`; a four-corner path remains a
quadrilateral for structural consumers.

When a curved `LayoutPath` owns `GridLayout`, `RowLayout`, or `ColumnLayout`
content, Flame resolves descendants in normalized surface coordinates. Grid
rows and nested horizontal boundaries follow the path curves, while paint and
hit testing use the same sampled paths. Curving is inherited through nested
grid and flex layouts rather than approximated by clipping flat content.
Curved `PanelLayout` captions use the surface's local projected basis for each
glyph, so their position, tangent, scale, and shear remain aligned with the
same ancestor projection used by the panel fill and border.

## Layout parameters

Every `Layout` accepts `state: LayoutState<LayoutConfig>`. Conditional
visibility is a `LayoutConfig.visible` value under its owning condition:

```dart
state: LayoutState({
  LayoutCondition.hasActiveNodes(): LayoutConfig(visible: true),
}),
```

When any state entry configures visibility, the Layout is hidden until a
matching entry resolves `visible: true`; later matching entries have priority.
A Layout with no visibility state remains visible. Use `ConditionalDerivative`
when geometry must select between alternatives. Compose these condition-bearing
primitives directly; layouts do not introduce an intermediate mode or named
condition-group layer.
Layout configuration constructs conditions only through `LayoutCondition`
factories. Use `LayoutCondition.not(...)` to negate another condition instead
of addressing concrete condition implementation classes.


## Inner and outer circles

Every `Layout` may define an `innerCircle` and an `outerCircle`. Both use the
owning layout bounds as their coordinate space:

- `center` is a normalized `Offset`; `(0.5, 0.5)` is the layout center.
- `radiusFraction` is measured against the layout's shortest side; `0.5`
  touches its nearest edges.
- `Layout.center` resolves to the inner circle's center first, then the outer
  circle's center, and finally `(0.5, 0.5)`.

The circles are geometry references, not mandatory decoration. Add a
`CirleLayout` to `layout.children` when either boundary should be visible.
This keeps centering and radial calculations usable even when the circles are
hidden.

## Inner borders and anchors

Every visual layout may expose its meaningful content boundary under
`LayoutKey.innerBorder`. The value is a `LayoutBorderGuide`, so the border stays
inside the same recursive layout map as all other geometry. Borders should be
quiet alignment aids rather than containers: prefer a thin, partially
transparent dashed stroke.

A border may reference the layout bounds, inner circle, or outer circle. A
square referencing a circle is mathematically inscribed in it, so its four
corners touch the circle. Named `Point` values on the border are durable anchors
for later connections, labels, angles, and animation.

## Derivatives and observables

`Layout.derivatives` stores named `LayoutDerivativeSnapshot` values.
`derivativeSnapshot` selects the active snapshot, and `getDerivatives()` always
returns that snapshot unless a different name is requested explicitly. A
derivative is computed from current layout geometry rather than copied into the
preset as a fixed coordinate.

LG Ergo defines A, B, C, and D as `CircleRayIntersectionDerivative` values:
each point is the intersection of the outer circle with a diagonal ray.
`LayoutBorderGuide.derivativeAnchors` consumes those names, making the square a
result of the circle intersections. Resizing or moving the circle therefore
recomputes the square anchors automatically.

`Layout.observables` describes groups of derivative names and their comparison
tolerance. `LayoutDerivativeObserver` establishes a baseline on its first
`evaluate()` call, then notifies listeners with `LayoutDerivativeChange`
records whenever watched resolved points move beyond that tolerance. This is
the layout equivalent of Vue computed values plus watchers: presets remain
immutable, while runtime observers react to changed results.

## Layout attributes

Every `Layout` accepts a list of `LayoutAttribute` values using Flutter's
lower-camel enum convention: `screen`, `rectangular`, `circular`, `triangular`,
`linear`, and `safeArea`. Attributes classify behavior without string tags and
contribute standard derivatives:

- screen, rectangular, and SafeArea layouts provide center, named corners, and
  A–D corner aliases;
- circular layouts provide center and four cardinal circle points;
- triangular layouts provide center and three vertices;
- linear layouts provide start, midpoint, and end.

`getDerivatives()` merges these attribute derivatives first and then the active
explicit snapshot. Explicit derivatives therefore override defaults without
copying the entire characteristic set.

## Ordered layout backgrounds

Every `Layout` exposes an ordered `background` list. Concrete layout
constructors forward this base property so a background remains declarative and
owned by the layout whose geometry it fills. Each background declares its
`orderPosition` and opacity. Configuration constructs them through
`LayoutBackground.color`, `image`, `guides`, or `conditional`; these factories
retain typed concrete variants for renderer dispatch. Color backgrounds declare
a direct color, while image backgrounds additionally declare the asset, fit,
horizontal repeat count, normalized per-tile position, and clockwise
`rotationDegrees`. Rotation and uniform `scale` use the center of each tile;
values above `1` zoom in and values below `1` shrink. Repetition divides the
owning surface into equal horizontal tiles and applies fit independently;
every tile follows the same ancestor projection. Panel fills belong in this
shared list rather than a parallel `PanelLayout.fillColor` property.
Background resolution recursively follows Grid, Row, and Column children; a
Panel nested inside a flex composition therefore paints in its resolved curved
surface instead of silently losing its configured background.

An empty `background` list paints no background for that layout. There is no
ancestor fallback or separate background-default property.

`LayoutPath` paints color and image backgrounds behind its guides and content,
clips them to the resolved polygon, and projects quadrilateral images through
the same rectangle-to-quad transform used by `TableLayout`. This means
the image content itself obeys trapezoidal perspective instead of remaining a
screen-facing rectangle inside a trapezoidal clip. Conditional backgrounds use
the same `LayoutContext` as layout visibility.

LG Ergo places `assets/please-stand-by.png` at root background position `0`
with `cover` fitting, so it fills the physical screen while preserving its
aspect ratio. Its info panel owns a translucent, cover-fitted helmet image that
is clipped to the panel path. A backend may replace or periodically update
configuration, but visual stacking remains a frontend responsibility.

## Screen composition

`main.dart` owns only the application shell and selects
`LandscapeXlLayoutScreen`
as `MaterialApp.home`. The fresh starting hierarchy is declared entirely in
`constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`:

1. `lgErgoLayoutConfig` fills the physical screen.
2. Its `safe-area` child applies Flutter's runtime display insets.
3. The SafeArea layout owns the top and bottom planes so their future controls,
   radial branches, temporal bands, and overlays share one parent context.
4. The SafeArea layout also owns the inner- and outer-circle geometry and their
   visible guide layouts.
5. Its `inner-border` is a square inscribed in the outer circle. A, B, C, and D
   run clockwise from the bottom-left corner, with outward directions derived
   automatically from the square's center.

The screen layout owns four configured dashed `Guideline` entries. Horizontal,
vertical, and both corner-to-corner diagonals span the full screen and intersect
at its center.

New top- and bottom-plane layers are added beneath their respective
`LayoutPath.children` maps inside `safe-area`, not beside `safe-area` at the
screen root. Existing graph, perceptual-map, and Compass models remain
available but inactive.

The top and bottom planes present occurrence-preserving `NodeTree` values
through `FanLayout`. The top `cortex-bush` uses direct-parts weighting and
excludes the shared space-time name match list. The bottom `time-fan` includes
that same list and retains equal sizing, making both policies visible at once.
Cardinal fan positions span 180 degrees, angular positions span 90 degrees, and
other positions span 360 degrees. Internal bands use a regular radius.
The two-point curved top plane resolves its structural midpoint as the Fan root
and its configured curve as the sampled outer boundary; it does not depend on
an opposing edge.
`sectionSizing` determines sibling spans: equal sizing assigns `1fr` to each
occurrence, while direct-parts weighting assigns
`1 + visibleDirectPartCount` fractions. Only the final band conforms to the
owning plane boundary, projecting the same cumulative fractions by boundary
path length so polygon perspective introduces no additional edge weighting.
Fan data matching belongs to the optional `FanLayout.nodeFilter`. Its
`includeNodesMatching` and `excludeNodesMatching` lists contain structured
`NodeSearchParameter` values. They are part of the Riverpod request identity
and are enforced by the tree API before Flame rendering. Include entries are
matched according to `includeMatchMode`: `any` retains OR behavior and `all`
requires every include. Any exclude match rejects, and a rejected occurrence
prunes that branch. `NodeSearchFilter.reverseOf(filter)` provides a const-safe
logical inverse and `filter.reversed()` provides the runtime equivalent. The
LG Ergo bottom Fan uses the reversed top filter from the same root, so the two
planes remain complementary without duplicating parameters. Painters and
components must not independently reimplement the filter.

Selected Nodes have an explicit center configuration at
`safe-area/panoramic-scene-plane/direction-pad/scene-graph`.
The panoramic plane's `GridLayout` places the `GraphLayout` across the complete
center 2fr column between 1fr side columns. Its three 1fr rows inherit the
owning curved `LayoutPath` projection. The
Graph renders the complete Riverpod-selected Node pool in equal centered cells, with
each circular Node occupying half of its cell by default. More selected Nodes
therefore produce smaller circles. Each logical circle is sampled through the
panoramic Grid's inherited curved projection, and its resulting path is shared
by paint and hit testing. Every circle shows its wrapped slug; an
assigned Emoji appears above it at twice the configured base Node font size,
with a half-font-size vertical gap. LG Ergo's Fan and Graph renderers share
the root `NodeConfig.text.fontSize` as that typography source; the renderers do
not own parallel `labelSize` fields or a font-size constant. It is visible only when
`LayoutCondition.hasActiveNodes()` is active and does not
request a `NodeTree`; connections and graph-distance placement remain future
extensions. `GraphLayoutComponent` is the single Flame owner of its geometry,
clipping, Node painting, labels, tap handling, and hover hit testing.
`LandscapeXlLayoutView` only supplies the resolved surface, current state, and
application callback boundary.


## Row and column composition

Use `ColumnLayout` and `RowLayout` when content has semantic interface order
that must remain independent from a `GridLayout`'s named axes. Their
children remain in `Map<String, Layout> children`, where each map key is the
child's stable identity.

`RowLayout.crossAxisAlignment` accepts `LayoutCrossAxisAlignment.top()`,
`.center()`, or `.bottom()`. When configured, each child uses its explicit
`LayoutSize.secondary` as height or derives an intrinsic height from its text,
padding, and nested content. The child is then placed along the row's vertical
cross axis. Omit the property to retain full-height stretching. The same
resolved frame drives flat and curved paint, backgrounds, and hit testing.

Every `Layout` owns a `LayoutSize size` directly. A row resolves its primary
dimension along the horizontal main axis; a column resolves it along the
vertical main axis. Use the same track vocabulary used elsewhere:

- `LayoutSize.fr(value)` consumes a weighted share of remaining space;
- `LayoutSize.px(value)` (or `pt`) consumes a fixed visual extent;
- `LayoutSize.rem(value)` consumes the root Layout text size multiplied by
  `value`; and
- `LayoutSize.calculatedFr(...)` keeps computed fractional sizing available.

`LayoutSize` is the global sizing entity formerly wrapped by
`GridAxisVariable`. Do not restore that wrapper. A scalar size has one primary
axis. Use `LayoutSize.twoDimensional(primary: ..., secondary: ...)` when a
renderer needs a second configured dimension; the renderer decides how those
axes map to its projected geometry. Renderable components derive geometric
extent from their owning layout rather than carrying a parallel viewport-size
abstraction.

Do not add parallel `flex`, `extent`, width, or height fields to composition
layouts. For example, a browser-like action surface is expressed as a column
containing fixed-pixel navigation and action rows around a `1fr` content panel.
Nested row children use their own `size` values for button proportions.

## Conditional Node styles

Every `Layout` accepts `node: NodeConfig`. It directly owns immediate Node
presentation and typography; its `state` is an ordered
`Map<LayoutCondition, NodeConfig>` rather than renderer-specific branches.
`NodeConfig.content` optionally selects one exact rendered source through
`NodeContent.slug()`, `.alias()`, `.emoji()`, or `.title()`. An explicit source
does not fall back to another source when empty and replaces the normal
composite Node caption.
Resolution evaluates every condition against the current `LayoutContext`,
resolves matching configurations recursively, and merges them in insertion
order. Later non-null values specialize earlier broad rules.

Use `LayoutCondition.nodeSelected()` for presentation that belongs to the
currently rendered selected Node. It compares normalized Node paths and falls
back to slug identity for frontend-only virtual Nodes. The optional `nodePath:`
targets one explicit Node instead. Fan, Graph, and singular Node layouts resolve
the condition separately for each Node they paint.

The related model and canonical fallbacks live together in
`lib/models/layout/node_config.dart`: `NodeConfig` and `NodeDefaults`.
The file is part of the Layout library because conditional
resolution currently depends on `LayoutCondition`, `LayoutContext`,
`GuideStyle`, and `TextTransform`; it is not a separate package yet. Base Node
opacity, hover-border, and slug defaults must be changed there rather than
scattered through constructors.

Every Layout also exposes `panel: PanelConfig`, defined in
`lib/models/layout/panel.dart`. Root layouts may establish shared panel behavior and
sizes; concrete table panels specialize those defaults without restoring a
table-only panel model.

Global Layout configuration follows `aliases`, `label`, `text`, `node`, then
`panel`. `LabelConfig` and `LabelStyle` live in `lib/models/layout/label.dart` and own
classification-label fallback color, border, and hole color. Semantic
colors are conditional `LayoutCondition.equalsTo(...)` state entries; palette
and hash-based assignment are prohibited. Conditional
specializations use the same recursive state-map protocol as `NodeConfig`;
cursor highlighting resolves through `LayoutCondition.labelHighlighted()`.

Conditional configuration uses `LayoutState<T>`, an ordered map wrapper shared
by `Layout`, `LabelConfig`, and `NodeConfig`. A Layout declares
`LayoutState<LayoutConfig>` values under its `state` property. The base Layout
resolves first and every matching configuration overlays its explicitly
configured common properties at the same tree identity. Later matching values
have priority, but omitted size, text, Label, Node, Panel, background, and
visibility values continue to inherit. Layout state never replaces the concrete
Layout or its children. Label and Node state use the same traversal and merge
their specialized styles in insertion order.

`LayoutTextConfig` lives in `lib/models/layout/text.dart` and owns an optional
typed `LayoutText` value, color, dark/light contrast colors, font family and
metrics, font features, and shadow effects. Use `LayoutText.none()` to suppress
inherited text, `LayoutText.lorem(length:)` for generated placeholder copy,
`LayoutText.value(...)` for a literal, `LayoutText.format(...)` for
`{parameter}` interpolation, and `LayoutText.comment(...)` for a literal whose
future comment presentation is intentionally not defined yet. An empty format
template renders its parameter map through the shared default representation.
Tables, Nodes, and classification labels use that same representation.

Panel text resolves in ancestor-to-child order; later non-null child values
override inherited values, including replacing an ancestor's
`LayoutText.none()`. `PanelLayout` does not carry parallel caption, label-color,
or label-size fields. Classification-label captions resolve text configuration
against their semantic fill:
light backgrounds select `darkColor`, while dark backgrounds select
`lightColor`.
The base `Layout.text` value is empty so an unspecified child cannot overwrite
its parent with defaults. Renderers seed `LayoutTextDefaults.config` once before
merging the root and descendants.

Use `LayoutCondition.always()` as the first state entry when baseline behavior
should participate in ordered condition resolution. Use
`LayoutCondition.isIn(...)` for membership. Dart reserves `default` and `in`,
so those words cannot be named constructors. Label defaults use this baseline
exclusively; the default fill is beige `#F5EDD6`, and the label painter contains
no independent fallback colors.

All declarative Layout models form one Dart library rooted at
`lib/models/layout/layout.dart`. Its supporting files are library parts in the
same directory, and interface code imports only that entry point. This is the
serialization boundary for a future protobuf, YAML, or combined representation;
renderers and runtime state remain outside it.

LG Ergo registers the common blue highlighted-Node border directly at the top
of `LandscapeXlLayout`. This first slice establishes configuration and
resolution only. Existing Node opacity and hover fields remain the active Flame
paint source until they can be removed in one coordinated renderer migration.
Do not partially duplicate Node paint behavior between both systems.

## Flutter code structure

The Flutter interface is built from explicit models, constants, utilities, and
rendering components. Do not spread design-system concepts across widgets and
components just because that is where they are first used.

Model files are ordered around their reason for existence. After imports, put
the primary public model first, followed by its conditions, context, and
immediately related definitions. Supporting typedefs, key constants, enums,
helper value objects, and concrete variants follow the headliner. File
organization should let a reader understand the stable public shape before
encountering its interchangeable implementation vocabulary.

- `lib/models/` contains durable interface and graph models: semantic data
  types, layout presets, dimension primitives, and other objects that describe
  the world.
- `lib/screens/` contains complete application surfaces. Screens consume layout
  models and rendering utilities but do not own reusable spatial rules.
- `lib/constants/` contains shared colors, tokens, and layout presets. The
  active hierarchy is configured in
  `lib/constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`.
- `lib/utils/` contains small reusable helpers: drawing helpers, formatting
  helpers, geometry helpers, and other stateless operations.
- `lib/components/` contains reusable Flame renderers such as Fan, Graph,
  classification-label, Node, and Search components.
- Flame components orchestrate and render interface content. Flutter widgets
  are limited to application composition, the `GameWidget` host, and transient
  `overlay_layers` popups/toasts. `LandscapeXlLayoutView` is the direct
  `Scaffold.body`; panels, controls, graphs, and layout content remain Flame
  components. Overlay widgets do not store
  global design rules, raw color systems, layout presets, or reusable helper
  algorithms.

If a concept can be named independently from the widget currently using it,
promote it into the appropriate folder before adding more behavior around it.
Before creating a new model, layout type, guide type, renderer concept, painter
helper, or configuration object, first inspect the nearby layout/model/utility
code and decide whether the existing entity should be reused or extended. New
entities are appropriate when the project owner explicitly asks for one or when
reuse would make the existing abstraction lie. Related geometry must stay
related in code: derive wrappers, rings, connectors, and anchors from the same
source shape instead of maintaining independent values that only visually align.

## Quality verification

The Flutter interface does not contain or run automated tests. Do not add unit,
widget, integration, golden, snapshot, or system tests. Do not add test
dependencies, test directories, Xcode test targets, test runners, or pipeline
steps that execute tests. Test coverage is not accepted as evidence that a
layout or interaction still behaves correctly after a change.

Automated verification is limited to formatting and static analysis. The
project owner exclusively performs final visual, interaction, build, and
runtime verification in the real macOS application.

## Guidelines

A guideline is the interface equivalent of the Ukrainian term
_направляюча лінія_. It is a non-content alignment aid and must therefore be
visually distinct from graph edges and the box's perspective seams.

Structural perspective guides are red and dashed. Every alignment aid is a
`Guideline`, `LayoutBorderGuide`, circle, or ray layout inside
`Layout.children`. Shared `GuideStyle` supports solid, dashed, and dotted
patterns, configurable dash length and interval, stroke width, color, and cap.
Explicit guidelines use normalized endpoints, so later editing tools can add,
remove, or reposition them without changing graph rendering.

The Layout library lives at `lib/models/layout/layout.dart`, with its models in
sibling part files. The active hierarchy preset lives in
`lib/constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`. Explicit
guideline drawing lives in `lib/utils/layout_guidelines.dart`, and dashed guide
drawing lives in `lib/utils/canvas_guides.dart`. Recursive layout composition,
SafeArea geometry, and the `GameWidget` host live in
`lib/widgets/landscape_xl_layout_view.dart`;
the layout render tree inside that host is composed entirely of Flame
components. `SearchHudComponent` is a high-priority Flame component owned by the
game. It owns Search visibility, text input, and keyboard handling; its
submitted query is stored in `interfaceOverlayStateProvider`. The corresponding
action-plane button remains a Flame-rendered layout element.
Its frame and sizing come from LG Ergo's `safe-area/search-layout`
`SearchLayout`, which fills the resolved safe area and paints above ordinary
scene/action-panel content.

Toast producers write `ToastEvent` values to the durable queue in
`toastProvider`; they never call an overlay API. `ToastOverlayPresenter` adapts
that queue to `OverlayType.toast` without mounting an invisible widget layer in
the `Scaffold`. `ToastWidgets` stacks messages at the safe top-right and
dismisses each after three seconds. Every event carries the protobuf
`NotificationType`, while `ToastWidget` owns the fixed blue/info, red/error,
yellow/warning, and green/success backgrounds. Protobuf never owns UI colors.
See [`OVERLAYS.md`](OVERLAYS.md).

Application keyboard bindings live in `lib/constants/keymap.dart`. The keymap
maps macOS hardware key events to application actions without depending on
Riverpod. `SearchHudComponent` subscribes through Flame's keyboard-handler
system and invokes callbacks supplied by the screen. Command-F opens the Search
HUD, Command-R refreshes every currently watched Fan `NodeTree` provider,
Command-C copies the last selected Node slug, and Escape clears selected Nodes
and hides Search.

Search HUD submission is shared by its action-plane button and keyboard Enter.
The normalized value is stored in `interfaceOverlayStateProvider`, and
`nodeSearchProvider` performs `QUERY /api/v1/node/search`. Results are
Flame-native Node option components rendered directly beneath the HUD input.
Arrow keys move the highlighted option; Enter or a tap selects it through the
same slug-based selected-node state and selection-sound path. LG Ergo configures
`NodeConfig.slugPrefix` and
`slugSuffix` as `[[` and `]]`; Fan and Graph apply them only to their slug
fallback, while search rows always expose the wrapped slug.

The left info-table Updates/Added row owns a `NodeListLayout` sourced from
selected Nodes whose `ResolvedVaultNode.isVirtual` flag is true. These Nodes use
the shared paint and hit-test cycle, including 50% virtual background opacity,
dashed draft borders, slug-based selection toggling, and selection audio. The
opacity is owned by `LayoutDefaults.virtualNodeBackgroundOpacity`.

`NodeLayout` intentionally renders exactly one Node through the shared Flame
Node presentation cycle. Configure its complete lookup with `filter`; the
Riverpod request always uses a limit of one and renders only the first result.
Configure `storedNode` as its frontend fallback. A successful empty lookup
deep-copies that Node, ensures its `Virtual` label and `isVirtual` status, stores
it once in `selectedNodesProvider`, and renders it. Loading and failed requests
must not create virtual Nodes. Its Flame component uses the owning
`LayoutPath` projection and fills the complete dedicated slot with the same
paint, hover, and tap geometry. Circular pool geometry remains specific to
`GraphLayout`.

The left info panel contains one `TableLayout`, never separate Node and System
tables. Its `TableConfig` composes shared `panel`, ordered `panels`, `rowConfig`,
and `columnConfig`. Identity-keyed panels, rows, and columns use each value's
`orderPosition` for rendering order. It orders six panels:
Last Selected Node, Updates, Selected Nodes, Me, Settings, and System. The first
contains the complete latest Node value, Updates contains Added, Updated, and
Deleted mutation rows, and Selected Nodes lists every selected slug above the
deduplicated alphabetical label set. Me and Settings inherit the table's shared
one-third panel width and use `showEmpty: true`, so their titles remain visible
before their rows are introduced. System retains system information. Added
renders current virtual Nodes; Updated and Deleted
are reserved for later state. Each retained panel has its own optional title,
border, and spacing from its neighbor. Empty panels normally have no title,
geometry, or gap; Me and Settings are the explicit `showEmpty` exceptions, so
an empty selection still retains both placeholders before System. Foldable
panels toggle through their title rows. The Flame scene keeps their transient fold state and drives
row-track expansion with `EffectController`; presentation-only folding does not
enter Riverpod.

LG Ergo declares one root `panel: PanelConfig` whose `foldedPanelSize` is a
two-dimensional `LayoutSize` with `0.33fr` primary and secondary dimensions.
Every table panel inherits those dimensions; the preset does not repeat panel
sizes. Row and column sizes remain independent track configuration. A
panel-level size is reserved
for a deliberate exception to the shared table rule. Folding currently
animates row content only; eventual panel-size animation stays presentation
state inside Flame.

Table rendering interprets a two-dimensional panel size with `primary` as the
panel width and `secondary` as its band height. When `secondary` is absent, the
band height continues to derive from visible row tracks. This keeps both
options declarative while leaving projection and packing math in Flame. When
panels sharing a horizontal band provide different secondary sizes, Flame uses
the largest normalized height for that band.

The table contracts live natively in `lib/models/layout/table_config.dart` as part of
the Layout model library and use `LayoutSize` directly. `TableLayout` inherits
the standard `node: NodeConfig`, so table-owned Node content uses the same
conditional state and style protocol as Fan, Graph, and Node-list layouts.
Flame retains geometry, row resolution, presentation, hit testing, and action
execution. Do not restore the former `dart_tables` or `table_data` package
boundary without a real external consumer.

The `TableLayout` renders `Node.labels`, the selected-Node label set, and system
`neo4j_labels` through `ClassificationLabelComponent`. Every classification
string is a separate shopping-tag shape rather than comma-separated text. The
root `LabelConfig` owns explicit semantic colors, the unmatched-label fallback,
border, hole, and text colors; Neo4j does not own paint.
`ClassificationLabelComponent` resolves both label identity and hover through
LabelConfig state. Fan, Graph, and Node-list Node captions remain their existing
emoji/slug text.

## Typography

Alegreya Sans SC is bundled as Seville's interface font in Regular, Medium,
Bold, and Black weights under the SIL Open Font License 1.1. The Material theme
sets the family for widgets. `SevilleTypography.ensureLoaded()` completes before
`runApp`, and Flame `TextPainter` styles specify
`SevilleTypography.fontFamily` directly so first-frame canvas text never falls
back to the macOS system font. Font files are local assets; the interface makes
no runtime font request. Node slug references are the deliberate exception:
they preserve their stored case in a bold normal-case face because Alegreya
Sans SC would visually convert lowercase wikilink-like syntax into small caps.
The same rule applies to the left info table's `slug` and
`selected_node_slugs` fields, including configured slug wrappers. Every slug
uses the resolved `NodeConfig.slugColor`; the default LG Ergo syntax color is
gold `#FFD54F`. `NodeConfig.labelColor` and `valueColor` provide the
corresponding Node label and value colors. LG Ergo declares all three once on
the root Layout's `NodeConfig`, and descendants inherit them. Ordinary layout
text uses ivory `#FFF8E7` instead of hard white, keeping wrapped Node references
visually distinct.

## Interface audio

Short interaction sounds belong to the Flame game lifecycle. Seville loads
`technology-select.wav` from `assets/audio/` into a `flame_audio` `AudioPool`,
plays it when a Node becomes selected, and disposes the pool with the game.
The separate pooled `stone-scrap.wav` plays when the cursor enters a different
rendered Node, not on every pointer-move frame. Riverpod continues to own
selection data but does not own audio playback.

The cursor-hovered Node receives a second border from `NodeComponent`. It
reuses the renderer's exact Fan segment, Graph circle, or Node-list polygon and
resolves its style from the target hierarchy's `NodeConfig.state` entry for
`LayoutCondition.nodeHighlighted()`. Node background, solid/dashed border, and
hover paint therefore remain owned by the Node Flame component; the game host
only routes the hovered identity to pooled audio.

## Game cursor

The GameWidget region hides the native pointer through Flame's
`Game.mouseCursor` hook and renders a centered gold targeting reticle with cyan
glow through `_GameCursorComponent`. Position and animation remain inside the
Flame game. No platform cursor plugin or Flutter overlay follows the pointer.

The green right-plane Add button creates a frontend-only selected Node through
`SelectedNodesNotifier.addVirtualNode()`. `ResolvedVaultNode.isVirtual` is the
explicit not-yet-persisted flag, and the shared Flame Node border renderer
paints virtual geometry dashed. The right-plane cross and Escape use the same
`SevilleKeymapAction.cancel` path, which clears selection and drafts, resets and
hides search, invalidates Node-search results, and closes the Graph scene.
The top-row ✅ action beside the nuclear close action and plain Enter create the
first virtual Node through the backend with Neo4j labels `New` and `Virtual`,
then replace that exact Riverpod entry with the canonical response. If the
Search HUD is visible, its Flame keyboard handler consumes Enter to submit
Search or select the highlighted result instead of creating a Node.

Copy and Share occupy the second right-plane action row. Me is now a visible
shared-width group in the left info table. Its former right-plane implementation
is retained as a comment beside the new group, ready for a later global action
contract; the current group does not dispatch the player query yet.
Direction controls use a three-by-three fractional core, ordered from top-left
through bottom-right with center included. Fixed header and bottom-ribbon rows
surround it. A fixed 4rem left-ribbon track precedes the content columns and its
outer Grid slot spans every row; its nested `ColumnLayout` skips the first 4rem
header row. The header itself is a direct `RowLayout` spanning every column in
the complete top row. A foreground `logo` slot owns their intersection and
renders the 🧠 `brain-control` `NodeLayout`. Its filter is the same exact
Calendar-root filter used by both Fans, while the elder-brain image is
configured once on `cortex-bush`. The center content column remains wider than
the side columns. Their `direction-*` aliases are configuration-level
interaction vocabulary; concrete movement behavior is not implied by their
rendering.
The `footer` Grid slot spans the entire fixed bottom row, including the
left-ribbon intersection. Its Row content is a fixed ribbon-width start spacer,
the flexible teletext `bottom-ribbon` Panel, and a matching end spacer.
The spanning header is one flat `RowLayout` whose panels are direct children.
There is no nested header or center-ribbon Grid slot.

The right-plane Today action performs an exact-slug Node query for the local
`DD-MM-YYYY` value. A returned canonical Node is slug-upserted into
`selectedNodesProvider`. Only a successful empty result creates a dashed
virtual Node with `Calendar`, `Date`, and `Day` labels; a failed query must not
create a draft that could duplicate unavailable canonical data.

`SEVILLE_PLAYER_SLUG` is the local player Node identity used before
authentication provides one. Configure it in the ignored `.env`; the macOS
`scripts/seville-interface` launcher exports it and supplies the corresponding
Dart define to Flutter. It is identity configuration, not an API secret.
