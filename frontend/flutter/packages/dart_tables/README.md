# dart_tables

`dart_tables` owns only renderer-independent table data and configuration:
values, rows, groups, ordering, and actions. It deliberately does not depend on
Flutter widgets, Flame, `dart:ui`, SVG, canvas painting, CSS, or Seville Node
types, and it does not resolve or render rows.

It occupies the same general space as `dart_tabulate`, while deliberately
keeping structure, ordering, sizes, formatting, and rendering extensible for
applications that need more than terminal-style table output. Consumers own
row resolution, geometry, hit testing, rendering, and action execution.

A consumer implements `TableDefinition<TSize>` and supplies `TableData`. The
consumer owns `TSize`, value formatting, geometry, painting, interaction, and
presentation. This keeps the configuration usable from Flame, native Flutter,
SVG, JavaScript, or another renderer.

`TableDefinition.tableConfig` exposes one `TableConfig<TSize>`. Its `groups`
and `rows` are maps whose keys own stable identity; `TableGroup` therefore has
no duplicate `id`, and `TableRow` has no duplicate `key`. Both values expose
an integer `orderPosition`. Rows first order groups by group position and rows
by row position, preserving map insertion order when positions tie. A group's
`TableRowOrdering` may deliberately replace the configured row order with
key- or value-alphabetical order.

`TableGroup.size` uses the consumer-owned `TSize`, just like `TableRow.size`.
`TableGroup.title` is optional renderer-independent metadata. `TableRow.groupId`
allows consumers to draw group boundaries and insert renderer-specific spacing
without putting canvas styles in this package. `TableGroup.foldable` and
`initiallyFolded` are renderer-independent interaction metadata; animation and
mutable expansion state remain the renderer's responsibility.
`TableRow.includeWhenEmpty` reserves an empty row only after another row
has made its owning group visible; it does not force an otherwise empty group
onto the screen.

`TableRow.actions` declares renderer-independent intent. Default actions include
`TableAction.copy()`, `TableAction.copyToClipboard()`, and
`TableAction.delete()`. Consumers decide their hit geometry and execute any
application side effects.
