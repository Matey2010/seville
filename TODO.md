# Seville TODO

1. Panoramic view
    1. Ribbon buttons all over the panoramic view.
1. Migrate Backend to fiber instead of using native go/http
2. Provide an ability to select source of data (local, johnny, throne)
3. Extend the basic virtual-Node Markdown input into a rich Node body editor.
    1. Render Markdown preview and link suggestions on the Layout-owned surface.
    2. Edit existing canonical Nodes as well as creation drafts.
    3. Persist canonical edits through `PATCH /api/v1/node/` and refresh graph connections from edited `[[slug]]` references.
    4. Preserve cursor, selection, focus, and hit geometry across flat and panoramic projection.
