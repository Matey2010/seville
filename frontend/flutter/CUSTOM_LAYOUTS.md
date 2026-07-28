# Defining custom layouts

Seville separates layout data from Flame rendering:

1. A `Layout` subclass describes durable structure.
2. Constants create the default configuration.
3. A Flame `PositionComponent` renders that model.
4. `LayoutComponentRegistry` connects the model type to its component.
5. A parent layout places it under a stable key in `Layout.children`.

Do not start by inventing a new entity. First inspect the related layout,
guide, derivative, path, grid, plane, component, and rendering primitives
already in the codebase. If an existing concept can honestly represent the
behavior, extend or configure that concept. Add a new model or component only
when the project owner explicitly asks for a new thing or when reuse would make
dependencies unclear.
Geometry that depends on other geometry must be encoded as a dependency:
wrapping squares derive from the circles or planes they wrap, rings derive from
the plane radius they describe, and connector guides target the same anchors
that the visible shapes use.

## 1. Define the model

```dart
import 'layout.dart';

class OrbitLayout extends Layout {
  const OrbitLayout({
    required this.ringCount,
    super.children,
  });

  final int ringCount;
}
```

Keep the model immutable. Store configuration, topology, slot ownership, and
relationships here; do not store `BuildContext`, viewport pixels, animation
controllers, or mutable UI state.

## 2. Create constants

```dart
const defaultOrbitLayout = OrbitLayout(
  ringCount: 4,
  children: {
    'orbit-axis': Guideline(
      start: Offset(0.5, 0),
      end: Offset(0.5, 1),
      style: GuideStyle(
        color: Color(0xCCDC2626),
        pattern: GuideLinePattern.dashed,
        dashLength: 8,
        dashInterval: 6,
      ),
    ),
  },
),
```

Prefer normalized fractions for positions and sizes. They scale across users'
screens and remain independent from macOS window dimensions.

Guides are layouts. Put `Guideline`, `LayoutBorderGuide`, circle, and ray values
directly into `Layout.children`; their map keys are their identities.
`GuideStyle` supports solid, dashed, and dotted patterns. Omitting a guide
layout removes it.

A `Guideline` can also own line-local derivatives and markers. Use these when
the point belongs to the guide itself rather than to the whole screen or scene:

```dart
Guideline(
  start: Offset(0, 0),
  end: Offset(1, 1),
  style: diagonalStyle,
  guidelineDerivatives: {
    'center': GuidelineFractionDerivative(0.5),
  },
  markers: [
    GuidelineMarker(derivative: 'center', label: '🎯'),
  ],
)
```

The marker resolves from the guide's normalized start/end points at paint time,
so it remains aligned when the viewport changes.

## 3. Create the component

```dart
class OrbitComponent extends PositionComponent {
  OrbitComponent({required this.layout});

  final OrbitLayout layout;

  @override
  void render(Canvas canvas) {
    drawOrbit(canvas, Size(size.x, size.y), layout);
  }
}

PositionComponent buildOrbitLayout(
  Layout layout,
  LayoutComponentRegistry registry,
) {
  return OrbitComponent(layout: layout as OrbitLayout);
}
```

Renderable layout content is a Flame component. Flutter widgets are reserved
for application composition, the `GameWidget` host, and explicitly designed
`overlay_layers` popups/toasts. `LandscapeXlLayoutView` remains the direct
`Scaffold.body`; ordinary layout content must not be implemented as a widget or
parallel gesture layer.

## 4. Register it

```dart
final appLayoutComponentRegistry = const LayoutComponentRegistry().extended({
  OrbitLayout: buildOrbitLayout,
});

final orbitComponent = appLayoutComponentRegistry.build(defaultOrbitLayout);
```

Registry lookup uses the layout's exact runtime type. Every new concrete layout
type needs one registration. Registered layouts work as children of the active
layout hierarchy.

Neo4j `Node.labels` values in a `TableLayout` are rendered independently
through `ClassificationLabelComponent`. Each string becomes a colored
shopping tag instead of part of a comma-separated value. Configure that
presentation once through the root Layout's `label`:

```dart
label: const LabelConfig(
  state: {
    LayoutCondition.always(): LabelConfig(
      style: LabelStyle(
        color: Color(0xFFF5EDD6),
        borderStyle: GuideStyle(
          color: Color(0xFFE8D59F),
          strokeWidth: 1,
        ),
        holeColor: Color(0xFF27251F),
      ),
    ),
    LayoutCondition.equalsTo('Science'): LabelConfig(
      style: LabelStyle(color: Color(0xFF7B4FA3)),
    ),
    LayoutCondition.labelHighlighted(): LabelConfig(
      style: LabelStyle(
        borderStyle: GuideStyle(
          color: Color(0xFFFFD54F),
          strokeWidth: 2,
        ),
      ),
    ),
  },
);

text: const LayoutTextConfig(
  color: Color(0xFFFFF8E7),
  darkColor: Color(0xFF27251F),
  lightColor: Color(0xFFFFF8E7),
  fontFamily: SevilleTypography.fontFamily,
),
```

These colors are frontend layout policy. Assign semantic colors through
`LayoutCondition.equalsTo(...)`; use `LayoutCondition.isIn(...)` when several
labels share one specialization. Do not use a palette or derive paint from the
label string. Neo4j supplies classification strings, not tag paint. Fan, Graph,
and Node-list components keep their existing compact emoji/slug rendering and
do not use classification tags. When both contrast colors are present, label
text automatically uses `darkColor` on light fills and `lightColor` on dark
fills.

Raw Flame text does not inherit Flutter's `ThemeData`. Use
`SevilleTypography.fontFamily` in every component-owned `TextStyle`; the family
is bundled, registered, and preloaded before the game is constructed.

Use `Point` when placement requires named coordinate logic:

```dart
const pointA = Point(
  id: 'A',
  coordinates: {
    CoordAlias.horizontal: Coord.fraction(0),
    CoordAlias.vertical: Coord.fraction(1),
    CoordAlias.diagonal: Coord.scalar(0),
    CoordAlias.weight: Coord.scalar(1.5),
  },
);
```

The coordinate map accepts custom string aliases in addition to the built-in
aliases. `CoordRule.fromStart`, `fromCenter`, and `fromEnd` control the origin;
units include fraction, pixels, tracks, scalar metadata, degrees, and radians.
The same point can resolve against a small sublayout or the physical screen,
which keeps cross-depth connectors logically aligned.

## 5. Add hierarchy depth

The default hierarchy is:

```text
screen
└── safeArea
    ├── outer-circle
    ├── inner-circle
    ├── inner-border (inscribed square with A–D anchors)
    └── content added later...
```

Start from `lgErgoLayoutConfig` in
`constants/layout/presets/lg_ergo/lg_ergo_layout_config.dart`. Add subsections
directly to a parent layout's `children` map. Use `SafeAreaLayout` when a child
must respect macOS display insets; no role or frame metadata is required.

Every layout may also declare normalized `innerCircle` and `outerCircle`
geometry. Use `Layout.center` as the canonical center reference and add
`CirleLayout` values to `children` only when those boundaries should be painted.
Circle visibility and style are configured like any other guide; for example
the LG Ergo scene paints its inner circle with a purple dashed `GuideStyle`
declared in the preset constants.

Classify layouts with Flutter-style `LayoutAttribute` values such as
`screen`, `rectangular`, `circular`, `triangular`, `linear`, and `safeArea`.
Attributes contribute standard derivatives automatically; explicit derivative
snapshots override values with the same names.

Use `LayoutKey.innerBorder` for a layout's meaningful content boundary. Store a
`LayoutBorderGuide` there and provide named `Point` anchors when other layouts
will connect to its corners or edges. `showAnchorDirections` derives outward
directions from the border center without four manually configured vectors.

For calculated geometry, place named snapshots in `Layout.derivatives`, select
one with `derivativeSnapshot`, and consume its names through
`derivativeAnchors`. Register derivative groups in `Layout.observables` and use
`LayoutDerivativeObserver.addListener()` when runtime code must react to a
resolved point changing.

Use `RayLayout` when geometry starts at one derivative and points toward
another. `LayoutDerivativeReference.layoutPath` addresses nested layouts, so a
ray can connect scene geometry to screen geometry without copying either
coordinate.

Every concrete `Layout` constructor accepts the base `background` list. Lower
`orderPosition` values paint first; guides and content remain above the owning
layout's background elements. For example, a path can own an image without
adding a parallel renderer or child layout:

```dart
LayoutPath(
  background: const [
    LayoutImageBackground(
      assetPath: 'assets/wallpapers/helmet-background.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.34,
    ),
  ],
  points: panelPoints,
)
```

The renderer clips a `LayoutPath` image background to its resolved polygon. For
a quadrilateral it also uses the same projective transform as
`TableLayout`, so the image and table obey one perspective rather than
placing a screen-facing image behind distorted content.

An empty `background` list paints no background for that layout. Background
configuration is always owned directly by the layout whose geometry it fills.

## 6. Project a grid inside a path

Use `LayoutPath.grid` to divide a quadrilateral into ordinary rows and columns
while retaining the path's perspective:

```dart
LayoutPath(
  points: [screenA, sceneA, sceneD, screenD],
  style: planeStyle,
  grid: PerspectiveGridLayout(
    guideStyle: dashedGridStyle,
    rowsConfig: {
      'timeline': LayoutSize.pt(20),
      'hour': LayoutSize.fr(1),
      'day': LayoutSize.fr(1),
      'week': LayoutSize.fr(1),
    },
    columnsConfig: {
      'past-pointer': LayoutSize.pt(20),
      'previous': LayoutSize.fr(1),
      'current': LayoutSize.fr(1),
      'next': LayoutSize.fr(1),
      'future-pointer': LayoutSize.pt(20),
    },
    areas: {
      'current-day': PerspectiveGridArea(
        row: 'day',
        column: 'current',
        aliases: ['today'],
        label: 'today',
      ),
    },
  ),
)
```

`rowsConfig` and `columnsConfig` are ordered maps of `LayoutSize`. The map key
is the track identity, so identity and measurement cannot drift apart as they
could with parallel ID and fraction lists.
`LayoutSize.fr` divides remaining space, while `LayoutSize.px` preserves a
fixed logical-pixel width; `LayoutSize.pt` is its readable alias.
`LayoutSize.calculatedFr` is a Vue-like calculated track: it behaves like its
fallback fraction today, and its `derivative` names the future layout/context
value that should drive it.

### Conditional Node styles

Declare common Node configuration through the owning layout's `node` property:

```dart
LandscapeXlLayout(
  node: const NodeConfig(
    state: {
      LayoutCondition.nodeHighlighted(): NodeConfig(
        style: NodeStyle(
          borderStyle: GuideStyle(
            color: Color(0xFF2196F3),
            strokeWidth: 4,
          ),
        ),
      ),
    },
  ),
)
```

`NodeConfig.style` owns immediate presentation. Every matching condition points
to another `NodeConfig`, resolves recursively, and contributes in map insertion
order. Later declarations override only the non-null style values they provide.
The recursive shape leaves room for future Node behavior beside style without
flattening it into the renderer. Legacy Node paint fields remain active until
the planned renderer-wide migration.

`NodeConfig`, `NodeStyle`, and the canonical `NodeDefaults` are kept together
in `lib/models/layout/node_config.dart`. Update that file for global Node fallbacks;
use layout configuration for preset-specific conditional configuration.

The LG Ergo bottom plane no longer owns the earlier hour/day/week perspective
grid or `now` ray. It owns the `time-fan` graph presentation instead. The
surrounding screen and safe-area anchors stay unpadded; each plane owns its own
side-specific `LayoutPath.padding`, derived from `lgErgoLayoutDefaults.padding`
where needed.
The LG Ergo top and bottom planes themselves live in `safe-area.children`, and
future plane-specific content belongs in each plane's own `children` map.
`FanLayout` is the graph presentation used by both planes. Its cardinal
positions span 180 degrees, angular `LayoutRelativePosition.d(...)` positions
span 90 degrees, and non-directional positions span 360 degrees. Sections split
that span according to `sectionSizing`. `FanSectionSizing.equal` preserves equal
sibling widths. `FanSectionSizing.directPartsWeighted` assigns each occurrence
`1 + visibleDirectPartCount` fraction units after depth and `maxSectionCount`
limits. Internal bands keep a regular radius while the final band adapts the
same cumulative fractions to the owning `LayoutPath` boundary by path length,
preventing triangle or trapezoid perspective from adding unintended edge width.
Use `rootNodeId` for a fixed API root,
`rootNodeFilter` for data-driven root discovery, or
`rootNodePointer: LayoutNodePointer.selectedNode()` when the fan must follow
the current Riverpod-selected Node. These options are mutually exclusive. LG
Ergo uses an `all`-mode `rootNodeFilter` combining the `Calendar` label with an
exact cortex slug, so its Fans do not depend on a configured root ID. A
selected-Node pointer issues no tree request until the selected Node has a
stable ID.
Every root-filter match becomes a depth-zero occurrence up to
`maxSectionCount`. Root slices divide the root band equally; two matches form
two halves around the center ray. Descendants then apply `sectionSizing`
independently inside their owning root slice.
Use the optional `nodeFilter` for data-level fan matching. Its
`includeNodesMatching` and `excludeNodesMatching` lists accept structured
`NodeSearchParameter` values, currently supporting exact, starts-with,
ends-with, contains, and regular-expression matching over Node `name`, `id`,
`path`, `title`, `tag`, `slug`, and Neo4j `label`. A non-empty include list uses
`includeMatchMode`: `any` is the default, while `all` requires every include to
match. Any exclude match rejects the occurrence. Use
`NodeSearchFilter.reverseOf(filter)` in const layout configuration, or
`filter.reversed()` at runtime, to invert the complete predicate without
copying its parameters.
Matching is performed by the tree API
before occurrences reach the Flame component, and a rejected occurrence's
branch is pruned. The LG Ergo `cortex-bush` includes the `Section` label and
excludes the shared space-time slug matches. `time-fan` starts from the same
cortex root and reverses that complete child filter, keeping the two planes as
derived complementary partitions. The top uses direct-parts-weighted sizing;
the bottom uses equal sizing.
`GraphLayout` is the selected Node pool used by the center scene. It is owned by
a `LayoutPath`, reads the complete Riverpod-selected Node collection, and gives
every Node an equal centered cell. `nodeExtentFactor` controls the circular
Node diameter relative to that cell and defaults to `0.5`. The pool becomes
denser as selection grows; it does not fetch a `NodeTree` or infer graph
connections yet. Selection membership and active fill state use the Node's
unique slug. Fan and Graph compact labels render emoji first and wrap the slug
fallback with `LayoutDefaults.nodeSlugPrefix` and `nodeSlugSuffix`. LG Ergo's
Node defaults use `[[` and `]]`, producing `[[slug]]` without changing stored
Node identity. `GraphLayoutComponent` owns all GraphLayout drawing and hit
geometry; screen/layout hosts provide only plane resolution, state, and action
callbacks.
`NodeListLayout` renders a dynamic Node collection as equal rows inside a
row/column composition or a TableLayout value cell. The info table's
Updates/Added field owns the virtual source, which reads the
`isVirtual` subset of Riverpod-selected Nodes, retains dashed borders, uses
`LayoutDefaults.virtualNodeBackgroundOpacity` (50% by default), and keeps the
normal Node tap/toggle target.

`TableLayout.includeUnconfiguredFields` combines declarative ordering with
data-dependent rows. `unconfiguredFieldPanelId` places populated unconfigured
keys alphabetically inside their owning panel. LG Ergo has one info-panel
table with six ordered panels: `last_selected_node`, `updates`,
`selected_nodes`, `me`, `settings`, and `system`. The first keeps Slug and
Labels before the remaining complete Node value; Updates owns Added, Updated,
and Deleted rows; Selected Nodes lists selected slugs followed by deduplicated
labels; Me and Settings are visible empty placeholders; and System contains
system data. Added renders virtual Nodes through a nested `NodeListLayout`.
Updated and Deleted remain empty placeholders whenever the Updates group is
visible. Configure this structure through `TableLayout.tableConfig`, which
combines shared `panel`, ordered `panels`, `rowConfig`, and `columnConfig`.
Panels, rows, and columns live in identity-keyed maps. Each `PanelConfig`,
`TableRow`, and `TableColumn` supplies
`orderPosition` instead of repeating an ID or key inside the value. Columns do
not live separately on `TableLayout`. An optional `PanelConfig.title` creates a
header only for a populated panel.
Set `PanelConfig.showEmpty` when a titled panel must remain visible without a
populated or configured row. LG Ergo uses it for Me and Settings, which inherit
the shared one-third panel width directly before System. The former right-plane
Me `PanelLayout` remains commented beside the table panel as a reference for
its future global action.
The root Layout's `panel: PanelConfig` supplies shared panel dimensions, and
`TableConfig.panel` may specialize them. A panel may provide `PanelConfig.size` as
an exception, but LG Ergo's info table uses one two-dimensional `0.33fr` by
`0.33fr` rule and has no per-panel size values. Flame packs consecutive
fractional panels into horizontal bands.
`TableRow.size` remains separate because it controls vertical row tracks.
Current folding animates those content tracks while panel width remains stable;
a later width transition belongs to the Flame renderer, not `TableConfig`.
Use `LayoutSize.twoDimensional(primary: ..., secondary: ...)` when a panel also
needs a configured band height. Table packing treats primary as width and
secondary as height; a scalar panel keeps content-derived height. If peers in
one band request different secondary dimensions, the renderer uses the largest
normalized height for their shared band.

```dart
panel: PanelConfig(
  foldedPanelSize: LayoutSize.twoDimensional(
    primary: LayoutSize.fr(0.33),
    secondary: LayoutSize.fr(0.33),
  ),
),
```

Omit the secondary dimension when visible row tracks should derive band height.
These configuration contracts live in Seville's native
`lib/models/layout/table_config.dart` Layout library and use `LayoutSize` directly.
`TableLayout` also inherits `node: NodeConfig`, so Node content inside a table
uses the common conditional Node protocol. Flame owns row resolution, geometry,
hit testing, rendering, and action execution.
`TableLayout.panelGap` separates visible panels, and `panelBorderStyle` wraps
each panel independently. Empty panels produce no rows or decoration. A panel
with `foldable: true` uses its title as a Flame hit target and animates its
content tracks open or closed over `TableLayout.panelFoldDuration`; the title
and its group border remain visible while folded.

The Flame Search HUD submits text to Riverpod, which performs
`QUERY /api/v1/node/search`, then renders the returned Nodes as Flame-native
option components immediately beneath the input. Search options always show
the wrapped slug, even when an Emoji exists, so each proposal exposes its Node
identity. Arrow keys move the highlighted option; Enter or tapping an option
toggles the same selected-node set used by Fan and Graph layouts.
LG Ergo configures the HUD through `safe-area/search-layout`. `SearchLayout`
fills that resolved safe-area frame and owns padding, input/result dimensions,
maximum width, and the visible option limit; its high-priority Flame renderer
stacks above normal scene and action-panel content.
The LG Ergo right-plane green Add action appends a uniquely slugged virtual
Node (`new-node`, `new-node-2`, and so on) to `selectedNodesProvider`. Virtual
status is carried by `ResolvedVaultNode.isVirtual`; it is not written into the
Node protobuf. Graph uses the shared Node border path to render that draft with
a dashed border while retaining normal active fill and tap behavior.
The top-row ✅ action beside the nuclear close action submits the first virtual
Node with `New` and `Virtual` labels through `POST /api/v1/node/`. On success,
`SelectedNodesNotifier.replaceVirtualNode` preserves the selected-list position
but swaps in the canonical response, making the shared border solid. Plain
Enter invokes this action outside the Search HUD; while the HUD is visible it
consumes Enter to submit the query or select the highlighted Node instead.

The right plane keeps Copy and Share in its second action row. Me has moved to
the left info table as a visible group; its previous exact-slug player action
is intentionally not connected until the group receives global functionality.
The right plane's bottom is a three-by-three
`direction-pad` whose equal cells represent top-left, top-center,
top-right, center-left, center, center-right, bottom-left, bottom-center, and
bottom-right. These controls expose stable `direction-*` aliases but remain
declarative interaction placeholders for now.

The top-row Today action formats the local calendar date as `DD-MM-YYYY` and
performs an exact-slug `QUERY /api/v1/node/search`. A returned canonical Node is
selected through the shared Riverpod set. A successful empty result creates a
dashed virtual Node with `Calendar`, `Date`, and `Day` labels. Query failures do
not manufacture a potentially duplicate draft.

The right-plane cross and Escape both dispatch the same nuclear cancel action.
It clears canonical and virtual selection, empties the submitted search value
and visible results, closes the Search HUD, invalidates cached Node searches, and
therefore closes the selected-node scene. The left plane is not involved.
The `left-plane`
provides the 12-segment x/space plane between scene-left and screen-left; its
grid contains only the real space rows, not fake padding tracks. The scene inner
circle uses the owning layout's `padding + borderWidth` as an inset, while the
outer circle remains the scene boundary for anchors and shape framing.

`areas` owns content and paint independently from track geometry. An area
references its starting row and column by their stable map keys, then spans
tracks with `rowSpan` and `columnSpan`. `GridSpan.full` means from the starting
track through every remaining track, including rows added later.
`rowOffset` and `columnOffset` allow fractional placement inside the starting
track, so an area can span, for example, one full column plus half of the next.

Fills are painted before the dashed grid, keeping structural lines visible.
`PerspectiveGridArea.borderStyle` can draw dashed border-only areas, useful for
wrapping an outer padded rim and an inner content rim inside the same
perspective grid.
`topStartIndex`, `topEndIndex`, `bottomStartIndex`, and
`bottomEndIndex` select the four path points used for projection.

## 7. Add a human scale figure to a scene

`StickmanLayout` is a renderable layout entity for the center-scene human scale
reference. Put it in the owning scene/safe-area `children` map:

```dart
'scene-stickman': StickmanLayout(
  aliases: ['stickman', 'person', 'human-scale'],
  heightCm: 200,
  rangeStart: -0.1,
  rangeEnd: 1.1,
  style: stickmanStyle,
),
```

The body itself is drawn in logical vertical `0..1`, where `1.0` equals
`heightCm`. The render frame can extend outside that body range; `-0.1..1.1`
means 20cm of conceptual space around a 200cm figure. When the parent layout has
an `outerCircle`, the figure is fitted into the inscribed scene square of that
circle.

## 8. Animate without mutating constants

Keep immutable Layout configuration as topology. Animate normalized position,
fractions, degrees, and depth inside the owning Flame component for
device-independent motion. Use logical-pixel translation only for short local
effects. For many simultaneously animated graph objects, keep per-frame
transforms in the Flame component tree or a GPU shader.
