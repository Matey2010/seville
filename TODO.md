# Obsivilian TODO

1. Verify the native Flutter graph, search, creation, and body editor in the
   macOS application.
2. Add pagination or clustering for broad graph exploration beyond the current
   bounded global view.
3. Add visible graph filters and optional `PART_OF`/`FAMILY` relationship layers.
4. Render Markdown in the selected-Node reader while retaining source editing.
5. Add connection suggestions, backlinks, and navigation to unresolved targets.
6. Extend canonical Node editing beyond the body with the same conflict policy.
7. Introduce source checkpoints and provenance before synchronizing changes
   from Markdown or Git back into canonical Nodes.
8. Add the bottom location plane with a place hierarchy and native Neo4j
   spatial `POINT` properties. Reuse the virtual world and camera created for
   the time plane to the left of the graph; leave top and right for later dimensions.
9. Replace the bounded chronological sample with a viewport query carrying the
   visible temporal window and whether undated Nodes are requested. Debounce
   camera changes, page large results, and keep `modified_at` separate from
   semantic temporal placement.
