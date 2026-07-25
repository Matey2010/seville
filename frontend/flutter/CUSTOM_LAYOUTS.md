# Defining custom layouts

Seville separates layout data from Flame rendering:

1. A `Layout` subclass describes durable structure.
2. Constants create the default configuration.
3. A Flame `PositionComponent` renders that model.
4. `LayoutComponentRegistry` connects the model type to its component.
5. A parent layout places it under a stable key in `Layout.layouts`.

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
  const OrbitLayout.fromAxes({
    required super.axes,
    required this.ringCount,
    super.layouts,
    super.subLayouts,
    super.elements,
  }) : super.fromAxes();

  final int ringCount;
}
```

Keep the model immutable. Store configuration, topology, slot ownership, and
relationships here; do not store `BuildContext`, viewport pixels, animation
controllers, or mutable UI state.

## 2. Create constants

```dart
const defaultOrbitLayout = OrbitLayout.fromAxes(
  axes: [12, 12],
  ringCount: 4,
  layouts: {
    'orbit-grid': GuideGrid(
      renderMode: GuideGridRenderMode.intersections,
      intersectionSize: 2,
      style: GuideStyle(color: Color(0x334B5563)),
    ),
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
);
```

Prefer normalized fractions for positions and sizes. They scale across users'
screens and remain independent from macOS window dimensions.

Guides are layouts. Put `Guideline` and `GuideGrid` values directly into
`Layout.layouts`; their map keys are their identities. `GuideStyle` supports
solid, dashed, and dotted patterns. Omitting a guide layout removes it.

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

CompassView(
  layout: configuredCompassLayout,
  componentRegistry: appLayoutComponentRegistry,
);
```

Registry lookup uses the layout's exact runtime type. Every new concrete layout
type needs one registration. Registered layouts work both as hierarchy nodes
and as Compass main-slot sublayouts.

Neo4j `Node.labels` values in a `TableLayout` are rendered independently
through `ClassificationLabelComponent`. Each string becomes a colored
shopping tag instead of part of a comma-separated value. Configure that
presentation through the table's layout defaults:

```dart
const nodeDefaults = LayoutDefaults(
  classificationLabelColors: [Color(0xFF3F51B5), Color(0xFF2E7D32)],
  classificationLabelBorderColor: Color(0xFFE8D59F),
  classificationLabelHoleColor: Color(0xFF27251F),
  classificationLabelTextColor: Color(0xFFF5F7FF),
);
```

These colors are frontend layout policy. Neo4j supplies classification strings,
not tag paint. Fan, Graph, and Node-list components keep their existing compact
emoji/slug rendering and do not use classification tags.

Raw Flame text does not inherit Flutter's `ThemeData`. Use
`SevilleTypography.fontFamily` in every component-owned `TextStyle`; the family
is bundled, registered, and preloaded before the game is constructed.

## 5. Put it inside the Compass main slot

```dart
final orbitCompass = configuredCompassLayout.copyWith(
  mainSlot: configuredCompassLayout.mainSlot.copyWith(
    figure: CompassMainFigure.layout,
    subLayout: defaultOrbitLayout,
    positionFraction: const Offset(0.5, 0.5),
    anchorFraction: const Offset(0.5, 0.5),
    availableSizeFraction: const Size(0.35, 0.35),
  ),
);
```

- `positionFraction` places the anchor inside `CompassFrame`.
- `anchorFraction` chooses the point inside the sublayout attached there.
- `availableSizeFraction` sizes custom layout figures without fixed pixels.
- `translation` adds runtime logical-pixel movement for animation.

The main figure can instead be `circle`, `triangle`, `square`, or `star`.
`CompassFigureConfig` controls size, rotation, fill, border, and parallel
internal lines.

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

## 6. Define radial slots

```dart
const activitySlot = CompassSlot(
  slot: LayoutSlot(id: 'activity', label: 'Activity'),
  startDegrees: 215,
  spanDegrees: 60,
);
```

Compass degrees are clockwise and `0°` points upward. `startDegrees` fixes an
absolute start. `spanDegrees` fixes angular width. Slots without
`spanDegrees` split the remaining configured sweep according to
`LayoutSlot.fraction`; one unrestricted slot receives all `360°`.

A slot's optional `layout` field establishes ownership of a nested layout.
Rendering that nested layout into a curved wedge is intentionally separate
from ownership and can be implemented by its Flame component.

## 7. Add hierarchy depth

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
directly to a parent layout's `layouts` map. Use `SafeAreaLayout` when a child
must respect macOS display insets; no role or frame metadata is required.

Every layout may also declare normalized `innerCircle` and `outerCircle`
geometry. Use `Layout.center` as the canonical center reference and add
`CirleLayout` values to `layouts` only when those boundaries should be painted.
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

Every concrete `Layout` constructor accepts the base `backgrounds` list. Lower
`orderPosition` values paint first; guides and content remain above the owning
layout's backgrounds. For example, a path can own an image without adding a
parallel renderer or child layout:

```dart
LayoutPath(
  backgrounds: const [
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

Put a shared fallback in `LayoutDefaults.backgrounds`, beside padding, gap, and
border width. Layouts with an empty local list inherit the nearest non-empty
ancestor default; any explicit local background list replaces it.

## 8. Project a grid inside a path

Use `LayoutPath.grid` to divide a quadrilateral into ordinary rows and columns
while retaining the path's perspective:

```dart
LayoutPath(
  points: [screenA, sceneA, sceneD, screenD],
  style: planeStyle,
  grid: PerspectiveGridLayout(
    guideStyle: dashedGridStyle,
    rowsConfig: {
      'timeline': GridAxisVariable(size: LayoutSize.pt(20)),
      'hour': GridAxisVariable(size: LayoutSize.fr(1)),
      'day': GridAxisVariable(size: LayoutSize.fr(1)),
      'week': GridAxisVariable(size: LayoutSize.fr(1)),
    },
    columnsConfig: {
      'past-pointer': GridAxisVariable(size: LayoutSize.pt(20)),
      'previous': GridAxisVariable(size: LayoutSize.fr(1)),
      'current': GridAxisVariable(size: LayoutSize.fr(1)),
      'next': GridAxisVariable(size: LayoutSize.fr(1)),
      'future-pointer': GridAxisVariable(size: LayoutSize.pt(20)),
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

`rowsConfig` and `columnsConfig` are ordered maps of the same `GridAxisVariable`
type. The map key is the track identity, so identity and measurement cannot
drift apart as they could with parallel ID and fraction lists.
`LayoutSize.fr` divides remaining space, while `LayoutSize.px` preserves a
fixed logical-pixel width; `LayoutSize.pt` is its readable alias.
`LayoutSize.calculatedFr` is a Vue-like calculated track: it behaves like its
fallback fraction today, and its `derivative` names the future layout/context
value that should drive it.

The LG Ergo bottom plane no longer owns the earlier hour/day/week perspective
grid or `now` ray. It owns the `time-fan` graph presentation instead. The
surrounding screen and safe-area anchors stay unpadded; each plane owns its own
side-specific `LayoutPath.padding`, derived from `lgErgoLayoutDefaults.padding`
where needed.
The LG Ergo top and bottom planes themselves live in `safe-area.layouts`, and
future plane-specific content belongs in each plane's own `layouts` map.
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
Node identity.
`NodeListLayout` renders a dynamic Node collection as equal rows inside a
row/column composition or a TableLayout value cell. The LG Ergo right plane
configures one with `NodeListDataSource.searchResults` beneath its Node actions.
The info table's Updates/Added field owns the virtual source, which reads the
`isVirtual` subset of Riverpod-selected Nodes, retains dashed borders, uses
`LayoutDefaults.virtualNodeBackgroundOpacity` (50% by default), and keeps the
normal Node tap/toggle target.

`TableLayout.includeUnconfiguredFields` combines declarative ordering with
data-dependent rows. `unconfiguredFieldGroupId` places populated unconfigured
keys alphabetically inside their owning group. LG Ergo has one info-panel
table with four ordered groups: `last_selected_node`, `selected_nodes`,
`updates`, and `system`. The first keeps Slug and Labels before the remaining
complete Node value; the second lists selected slugs followed by deduplicated
labels; Updates owns Added, Updated, and Deleted rows; and the fourth contains
system data. Added renders virtual Nodes through a nested `NodeListLayout`.
Updated and Deleted remain empty placeholders whenever the Updates group is
visible. An optional `TableGroup.title` creates a header only for a populated
group.
`TableLayout.groupGap` separates visible groups, and `groupBorderStyle` wraps
each group independently. Empty groups produce no rows or decoration. A group
with `foldable: true` uses its title as a Flame hit target and animates its
content tracks open or closed over `TableLayout.groupFoldDuration`; the title
and its group border remain visible while folded.

The Flame Search HUD only submits text to Riverpod; it does not render those rows.
Riverpod performs `QUERY /api/v1/node/search`, and the Flame layout paints the
returned Nodes using the shared random/frontmatter color, selected-slug active
opacity, and layout tap path. Search rows always show the wrapped slug, even
when an Emoji exists, so each proposal exposes its Node identity. Tapping a row
therefore toggles the same
selected-node set used by Fan and Graph layouts.
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
consumes Enter to submit the query instead.

The right plane keeps Copy and Share in its second action row. Its bottom is a
three-by-three `direction-pad` whose equal cells represent top-left, top-center,
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

## 9. Add a human scale figure to a scene

`StickmanLayout` is a renderable layout entity for the center-scene human scale
reference. Put it in the owning scene/safe-area `layouts` map:

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

## 10. Animate without mutating constants

Keep defaults immutable and derive transient layouts in `AnimatedBuilder`:

```dart
AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    final t = Curves.easeInOut.transform(controller.value);
    final animatedMainSlot = configuredCompassLayout.mainSlot.copyWith(
      positionFraction: Offset.lerp(
        const Offset(0.5, 0.5),
        const Offset(0.65, 0.42),
        t,
      ),
      figureConfig:
          configuredCompassLayout.mainSlot.figureConfig?.copyWith(
            rotationDegrees: 90 + 90 * t,
          ),
    );
    return CompassView(
      layout: configuredCompassLayout.copyWith(mainSlot: animatedMainSlot),
      componentRegistry: appLayoutComponentRegistry,
    );
  },
);
```

Animate normalized position, fractions, degrees, and depth for device-independent
motion. Use logical-pixel `translation` only for short local effects. For many
simultaneously animated graph objects, keep the immutable layout as topology
and move per-frame transforms into the Flame component tree or a GPU shader.
