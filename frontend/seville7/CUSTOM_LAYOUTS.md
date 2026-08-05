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

Every Layout may conditionally specialize itself through the same ordered
state protocol used by Label and Node configuration:

```dart
PanelLayout(
  size: LayoutSize.fr(3),
  text: LayoutTextConfig(
    color: Color(0xFFFF614F),
    value: LayoutText.value('SELECT A NODE'),
  ),
  state: LayoutState({
    LayoutCondition.hasActiveNodes(): LayoutConfig(
      text: LayoutTextConfig(value: LayoutText.lorem(length: 1)),
    ),
  }),
)
```

Matching `LayoutConfig` values resolve recursively at the same child map key.
The base Layout resolves first, then matching entries overlay only explicitly
configured common properties in insertion order. In this example the size and
red text color remain defined once; the active state changes only the text
value. Conditional text, Label, Node, and Panel configuration merges, while an
explicit conditional background list replaces the current list. Layout state
does not replace the concrete Layout, its children, or its tree identity.

Visibility uses the same state rather than a parallel condition list:

```dart
state: LayoutState({
  LayoutCondition.hasActiveNodes(): LayoutConfig(visible: true),
}),
```

Once any state entry configures visibility, the Layout is hidden until a
matching configuration makes it visible. Later matching entries may override
that value. Layouts without a visibility state remain visible.

Neo4j `Node.labels` values in a `TableLayout` are rendered independently
through `ClassificationLabelComponent`. Each string becomes a colored
shopping tag instead of part of a comma-separated value. Configure that
presentation once through the root Layout's `label`:

```dart
label: const LabelConfig(
  state: LayoutState({
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
  }),
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

Every concrete `Layout` constructor accepts the base `background` list. Lower
`orderPosition` values paint first; guides and content remain above the owning
layout's background elements. Use the `LayoutBackground.color`, `image`, `svg`,
`guides`, and `conditional` factories so configuration has one discoverable
entry point while retaining typed concrete background variants. For example, a
path can own a color and image without adding a parallel renderer or child
layout:

```dart
LayoutPath(
  background: const [
    LayoutBackground.color(Color(0xCC283252)),
    LayoutBackground.image(
      assetPath: 'assets/wallpapers/helmet-background.jpg',
      fit: LayoutBackgroundFit.cover,
      opacity: 0.34,
      repeat: 3,
      position: Offset(0.5, 1),
      rotationDegrees: 180,
      scale: 1.25,
    ),
  ],
  points: panelPoints,
)
```

The renderer clips color and image backgrounds to the owning resolved polygon.
For a quadrilateral it also uses the same projective transform as
`TableLayout`, so the image and table obey one perspective rather than
placing a screen-facing image behind distorted content.
`repeat` divides the owning surface into that many equal horizontal tiles and
applies `fit` independently inside each tile. `position` is normalized image
placement within every tile: `(0, 0)` is top-left, `(0.5, 0.5)` is centered,
and `(0.5, 1)` is bottom-centered. Repeated tiles use the same curved projection
as a single background. `rotationDegrees` rotates each fitted tile clockwise
around its center. `scale` uniformly scales around that same center: values
above `1` zoom in and values between `0` and `1` shrink. Both transforms are
preserved through flat, projective, curved, and Fan surfaces.

An empty `background` list paints no background for that layout. Background
configuration is always owned directly by the layout whose geometry it fills.

## 6. Compose named grid slots

Use `GridLayout` for CSS-like two-dimensional composition. Rows and columns are
ordered track maps, `slots` maps area names to track geometry, and each layout
in `children` requests its area through `Layout.slot`:

```dart
LayoutPath(
  points: [a, b, c, d],
  style: planeStyle,
  children: {
    'controls': GridLayout(
      rowsConfig: {
        'top': LayoutSize.fr(1),
        'center': LayoutSize.fr(1),
        'bottom': LayoutSize.fr(1),
        'ribbon': LayoutSize.rem(2),
      },
      columnsConfig: {
        'left': LayoutSize.fr(1),
        'center': LayoutSize.fr(2),
        'right': LayoutSize.fr(1),
      },
      slots: {
        'top-left': GridSlot(row: 'top', column: 'left'),
        'center': GridSlot(row: 'center', column: 'center'),
        'footer': GridSlot(
          row: 'ribbon',
          column: 'left',
          aliases: ['status-bar'],
          columnSpan: GridSpan.full,
        ),
      },
      children: {
        'back-button': PanelLayout(
          slot: 'top-left',
          text: LayoutTextConfig(value: LayoutText.value('↖')),
        ),
        'focus-indicator': PanelLayout(
          slot: 'center',
          text: LayoutTextConfig(value: LayoutText.value('•')),
        ),
        'status-controls': RowLayout(slot: 'footer', children: {...}),
      },
    ),
  },
)
```

`rowsConfig` and `columnsConfig` are ordered maps of `LayoutSize`. The map key
is the track identity, so identity and measurement cannot drift apart as they
could with parallel ID and fraction lists.

Text content is typed independently from typography:

```dart
text: LayoutTextConfig(value: LayoutText.lorem(length: 1))
text: LayoutTextConfig(value: LayoutText.value('Exact caption'))
text: LayoutTextConfig(value: LayoutText.none())
text: LayoutTextConfig(
  value: LayoutText.format('{place}: {year}', {
    'place': 'BCN',
    'year': 2026,
  }),
)
text: LayoutTextConfig(
  flow: LayoutTextFlow.vertical(
    verticalDirection: LayoutTextVerticalDirection.topToBottom,
    glyphOrientation: LayoutTextGlyphOrientation.rotated,
  ),
)
```

`none()` suppresses inherited text until a descendant supplies another typed
value. `comment(...)` currently paints exactly like `value(...)`, leaving its
future visual treatment open. Format parameters use the same default textual
representation as tables, Nodes, and classification labels.
`LayoutTextFlow.vertical()` rotates the shaped caption clockwise and reads from
top to bottom by default. Select `bottomToTop` for the opposite progression or
`upright` to stack grapheme clusters without rotating them. The enum
`parse`/`tryParse` methods accept normalized serialized values such as
`top-to-bottom`, `bottom_to_top`, and `upright`.
`LayoutSize.fr` divides remaining space, while `LayoutSize.px` preserves a
fixed logical-pixel width; `LayoutSize.pt` is its readable alias.
`LayoutSize.rem` is also fixed, but multiplies its value by the root Layout's
resolved text font size, making typography-relative tracks configurable without
coupling them to nested font overrides.
`LayoutSize.calculatedFr` is a Vue-like calculated track: it behaves like its
fallback fraction today, and its `derivative` names the future layout/context
value that should drive it.

`RowLayout.crossAxisAlignment` accepts `LayoutCrossAxisAlignment.top()`,
`.center()`, or `.bottom()`. With alignment enabled, an explicit
`LayoutSize.secondary` controls the child's height; otherwise Flame derives an
intrinsic height from resolved text, padding, and nested content. Omit the
property to preserve full-height stretching. Flat paint, curved projection,
backgrounds, and hit testing consume the same aligned child frame.

On a curved owning `LayoutPath`, `PanelLayout` captions resolve through the
same projected surface as the panel fill and border. Glyph position, tangent,
scale, and shear therefore follow the ancestor projection instead of remaining
screen-aligned.
Panel content is `LayoutTextConfig.value`; `PanelLayout` has no parallel
`caption`, `labelColor`, or `labelSize` fields. Text configuration resolves from
root to owning path to nested composition to child, with each child overriding
only its non-null values.

A slot's key is an area name independent of child identity. `GridSlot.aliases`
adds alternative names for that same area. Exact map-key matches take priority;
when aliases overlap, the first declared slot wins. Every `Layout` accepts an
optional `slot`; when its parent is a `GridLayout` containing that name or
alias, the layout fills the resolved area and its own `size` is ignored. A child
without a matching declared slot does not participate in that grid. `row` and
`column` select named starting tracks; `rowSpan`, `columnSpan`, `rowOffset`, and
`columnOffset` extend or fractionally adjust that placement. `GridSpan.full`
continues through all remaining tracks. Slots may contain `PanelLayout`,
`NodeListLayout`, `TableLayout`, `RowLayout`, `ColumnLayout`, or another
`GridLayout`.
`initialSpan: GridSlotSpan.content` starts a slot's resolved area at its
resolved text/content height. `maxSpan: GridSlotSpan.track` caps that frame at
the complete named row, preserving room for future expansion without adding a
second track or overlay. Backgrounds, projected content, and hit testing all
consume the same intrinsic frame.
`TableLayout` painting and interaction geometry both consume the area resolved
from its named slot, so folding, Node hits, labels, and actions remain aligned
after nesting.

### Curved paths

`LayoutPathCurve` replaces a structural path edge without adding shaping
points to `LayoutPath.points`:

```dart
LayoutPath(
  points: [a, b, c, d],
  curves: [
    LayoutPathCurve(
      from: b,
      through: LayoutDerivativeReference(
        layoutPath: ['safe-area'],
        derivative: 'innerSquare.BC-center',
      ),
      to: c,
    ),
  ],
  children: {'content': GridLayout(/* ... */)},
)
```

`from` and `to` must resolve to structural path corners. The curve passes
through the resolved `through` derivative. A `GridLayout`, `RowLayout`, or
`ColumnLayout` beneath a curved path is resolved in normalized surface
coordinates: horizontal boundaries follow the curve, nested layouts inherit
the same projection, and hit testing uses the rendered curved paths. The
content is not rendered as a flat quadrilateral and clipped afterward.

### Conditional Node styles

Declare common Node configuration through the owning layout's `node` property:

```dart
LandscapeXlLayout(
  node: const NodeConfig(
    state: LayoutState({
      LayoutCondition.nodeHighlighted(): NodeConfig(
        borderStyle: GuideStyle(
          color: Color(0xFF2196F3),
          strokeWidth: 4,
        ),
      ),
      LayoutCondition.nodeSelected(): NodeConfig(
        backgroundOpacity: 1,
        borderStyle: GuideStyle(
          color: Color(0xFFFFD54F),
          strokeWidth: 3,
        ),
      ),
      LayoutCondition.hasLabelsInCurrentNode(['Science']): NodeConfig(
        background: [
          LayoutBackground.svg(
            assetPath: 'assets/icons/vector/proto-icon.svg',
            fit: LayoutBackgroundFit.contain,
          ),
        ],
      ),
    }),
  ),
)
```

`NodeConfig` directly owns Node presentation and typography. Every matching
condition points to another `NodeConfig`, resolves recursively, and contributes
in map insertion order. Later declarations override only the non-null values
they provide.
Its optional ordered `background` list is Node-local artwork. It paints over
the Layout background and Node fill, then the Node border and caption paint over
it. A non-null list replaces the inherited Node artwork list, while `[]`
explicitly clears it. `LayoutCondition.hasLabelsInCurrentNode(...)` matches any
of the supplied labels against the Node currently being painted.
Set `NodeConfig.content` when a Node must render one exact metadata source:
`NodeContent.slug()`, `NodeContent.alias()`, `NodeContent.emoji()`, or
`NodeContent.title()`. Explicit content suppresses the normal composite
emoji-plus-slug presentation. If the selected source is absent, the Node paints
no content rather than silently switching to another source. Because `content`
merges with the rest of `NodeConfig`, conditional states may override it.
`LayoutCondition.nodeSelected()` evaluates the Node currently being painted,
matching its normalized path first and its slug as the virtual-Node fallback.
Pass `nodePath:` only when a condition intentionally targets one fixed Node.
`FanLayout`, `GraphLayout`, and `NodeLayout` resolve this state independently
for every rendered Node rather than once for their complete surface.
`NodeConfig.text` owns inherited Node typography. Fan and Graph labels resolve
their font size and other text metrics from it rather than declaring local
`labelSize` properties.
The recursive shape leaves room for future Node behavior without splitting
configuration into renderer-specific wrappers.

`NodeConfig` and the canonical `NodeDefaults` are kept together in
`lib/models/layout/node_config.dart`. Update that file for global Node fallbacks;
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
Fan segments paint their resolved Node color and state overlay without owning
an image background. LG Ergo configures the elder-brain artwork once on the
`cortex-bush` Fan Layout surface, so it does not repeat per Node. `time-fan`
has no image background.
For a two-point curved Fan plane, Flame uses the midpoint of the structural
edge as the root and samples the configured curve as the outer boundary. Both
curve endpoints close directly back to that root, so no opposing plane edge or
extra curve points are required.
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
`GraphLayout` is the selected Node pool used by the center scene. It is nested
at `panoramic-scene-plane/direction-pad/scene-graph`; its named slot spans the
curved grid's complete center column and resolves the projected Graph area. It
reads the complete Riverpod-selected Node
collection and gives every Node an equal centered cell. `nodeExtentFactor` controls the circular
Node diameter relative to that cell and defaults to `0.5`. The pool becomes
denser as selection grows. Logical Node circles are sampled through the full
inherited curved surface, so paint and hit testing use the same projected path.
It does not fetch a `NodeTree` or infer graph
connections yet. Selection membership and active fill state use the Node's
unique slug. Fan and Graph compact labels render emoji first and wrap the slug
fallback with `NodeConfig.slugPrefix` and `slugSuffix`. LG Ergo's
Node defaults use `[[` and `]]`, producing `[[slug]]` without changing stored
Node identity. `GraphLayoutComponent` owns all GraphLayout drawing and hit
geometry; screen/layout hosts provide only the resolved projected surface,
state, image cache, and action callbacks. Every random background configured on
the Graph, including one nested beneath conditional backgrounds, resolves to a
stable independent choice for each Node slug. The chosen color, image, guide,
or border is clipped to that Node's projected path beneath its border and
labels.
`NodeListLayout` renders a dynamic Node collection as equal rows inside a
row/column composition or a TableLayout value cell. The info table's
Updates/Added field owns the virtual source, which reads the
`isVirtual` subset of Riverpod-selected Nodes, retains dashed borders, uses
`LayoutDefaults.virtualNodeBackgroundOpacity` (50% by default), and keeps the
normal Node tap/toggle target.

Use `NodeLayout` when a layout intentionally owns one filtered Node:

```dart
NodeLayout(
  filter: NodeSearchFilter.allOf([
    NodeSearchParameter(
      parameter: NodeParameter.slug,
      value: 'cortex',
    ),
  ]),
  fallbackNode: Node(slug: 'cortex', title: 'Cortex'),
)
```

The query always requests one result and only its first Node renders. After a
successful empty response, `fallbackNode` is deep-copied, marked with the
`Virtual` label and virtual renderer status, inserted once into the selected
Node store, and rendered instead. Loading and error states do not create the
fallback. `NodeLayoutComponent` uses `NodeComponent` for shared fill, border,
emoji, slug, hover, and tap behavior, including inherited curved projection.
The Node fills the complete slot assigned to `NodeLayout`; it does not use
GraphLayout's circular `nodeExtentFactor` geometry.

`TableLayout.includeUnconfiguredFields` combines declarative ordering with
data-dependent rows. `unconfiguredFieldPanelId` places populated unconfigured
keys alphabetically inside their owning panel. LG Ergo has one `info-grid`
table in the panoramic grid's projected left column, with six ordered panels:
`last_selected_node`, `updates`,
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

`FindLayout` submits text to Riverpod, which performs
`QUERY /api/v1/node/search`, then renders the returned Nodes as Flame-native
option components immediately beneath the input. Search options always show
the wrapped slug, even when an Emoji exists, so each proposal exposes its Node
identity. Arrow keys move the highlighted option; Enter or tapping an option
toggles the same selected-node set used by Fan and Graph layouts.
LG Ergo configures it through `safe-area/find-layout`. `FindLayout` fills that
resolved safe-area frame and owns padding, input/result dimensions, maximum
width, hint, input fill, and border presentation. The editable Flutter control
uses the same projected input corners resolved by Flame, while result Nodes
remain native Flame layout children above normal scene and action-panel content.
The LG Ergo right-plane green Add action appends a uniquely slugged virtual
Node (`new-node`, `new-node-2`, and so on) to `selectedNodesProvider`. Virtual
status is carried by `ResolvedVaultNode.isVirtual`; it is not written into the
Node protobuf. Graph uses the shared Node border path to render that draft with
a dashed border while retaining normal active fill and tap behavior.
The top-row ✅ action beside the nuclear close action submits the first virtual
Node with `New` and `Virtual` labels through `POST /api/v1/node/`. On success,
`SelectedNodesNotifier.replaceVirtualNode` preserves the selected-list position
but swaps in the canonical response, making the shared border solid. Plain
Enter invokes this action outside Find; while Find is visible it
consumes Enter to submit the query or select the highlighted Node instead.

The right plane keeps Copy and Share in its second action row. Me has moved to
the left info table as a visible group; its previous exact-slug player action
is intentionally not connected until the group receives global functionality.
The panoramic scene contains a three-by-three directional core whose slots
represent top-left, top-center,
top-right, center-left, center, center-right, bottom-left, bottom-center, and
bottom-right. A fixed 4rem header and 2rem bottom ribbon surround those rows,
while a fixed 4rem left-ribbon slot spans the complete column. Its nested
content skips the first 4rem header row. The header is a direct `RowLayout`
spanning all four columns. A
foreground logo slot owns their first-cell intersection and uses `NodeLayout`
to load the same exact Calendar root as the top and bottom Fans, while
preserving its `brain-control` aliases and brain Emoji. The elder-brain image
is configured once on `cortex-bush`, not on the logo. The center
content column is wider than its side columns. Header panels are direct children of its
single RowLayout. These controls
expose stable `direction-*` aliases but remain
declarative interaction placeholders for now.
The full-width bottom track is owned by `footer: RowLayout`. It crosses the
left-ribbon column explicitly and orders a fixed ribbon-width start spacer, the
flexible teletext `bottom-ribbon` panel, and a matching end spacer.

The top-row Today action formats the local calendar date as `DD-MM-YYYY` and
performs an exact-slug `QUERY /api/v1/node/search`. A returned canonical Node is
selected through the shared Riverpod set. A successful empty result creates a
dashed virtual Node with `Calendar`, `Date`, and `Day` labels. Query failures do
not manufacture a potentially duplicate draft.

The right-plane cross and Escape both dispatch the same nuclear cancel action.
It clears canonical and virtual selection, empties the submitted search value
and visible results, closes Find, invalidates cached Node searches, and
therefore closes the selected-node scene. The left plane is not involved.
The `left-plane`
provides the 12-segment x/space plane between scene-left and screen-left; its
grid contains only the real space rows, not fake padding tracks. The scene inner
circle uses the owning layout's `padding + borderWidth` as an inset, while the
outer circle remains the scene boundary for anchors and shape framing.

The `direction-pad` is the panoramic reference grid: three fractional scene
rows plus fixed header and bottom-ribbon rows, and three fractional content
columns preceded by the fixed 4rem `left-ribbon`. `info-grid` spans its
projected left content column across the three scene rows between header and
footer, `scene-graph` spans
its projected center column, and `action-panel` directly owns the projected
right column as a `ColumnLayout` across the three scene rows, stopping before
the footer. The left-ribbon content is also a
`ColumnLayout`, nested in a full-height Grid slot whose first row is reserved
for the logo. The header is a direct full-width Row. `logo` separately owns the
header/left-ribbon intersection. Its shared-root `NodeLayout` and brain Emoji
paint above both outer ribbon surfaces without a separate image background.
The directional
slots remain reserved for controls. Its center track is
wider than its side tracks, demonstrating that grid tracks remain independent
from child `Layout.size` values.

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
