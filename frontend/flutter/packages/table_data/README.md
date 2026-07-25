# table_data

`table_data` owns renderer-independent table structure and logic: values,
fields, groups, ordering, and resolved rows. It deliberately does not depend on
Flutter widgets, `dart:ui`, SVG, canvas painting, CSS, or Seville Node types.

A consumer implements `TableDefinition<TSize>`, supplies `TableData`, and calls
`buildTableRows`. The consumer owns `TSize`, value formatting, geometry, field
painting, interaction, and presentation. This keeps the same table logic usable
from native Flutter, SVG, JavaScript, or another renderer.
