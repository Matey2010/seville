# table_data

`table_data` owns renderer-independent table structure and logic: values,
fields, groups, ordering, and resolved rows. It deliberately does not depend on
Flutter widgets, `dart:ui`, SVG, canvas painting, CSS, or Seville Node types.

A consumer implements `TableDefinition<TSize>`, supplies `TableData`, and calls
`buildTableRows`. The consumer owns `TSize`, value formatting, geometry, field
painting, interaction, and presentation. This keeps the same table logic usable
from native Flutter, SVG, JavaScript, or another renderer.

`TableGroup.title` is optional renderer-independent metadata. Resolved
`TableRow` values retain `groupId`, allowing consumers to draw group boundaries
and insert renderer-specific spacing without putting canvas styles in this
package. Consumers can pass `includeValue` to omit empty fields; a group with no
included fields emits neither title nor rows. `TableGroup.foldable` and
`initiallyFolded` are renderer-independent interaction metadata; animation and
mutable expansion state remain the renderer's responsibility.
`TableField.includeWhenEmpty` reserves an empty row only after another field
has made its owning group visible; it does not force an otherwise empty group
onto the screen.
