---
paths:
  - "frontend/**"
---

# Flutter client

- Widgets own layout, input, gestures, and accessibility. Riverpod owns API
  request state. Dio plus generated protobuf types are the only path to the API.
- Graph: `InteractiveViewer` pan/zoom, positioned Node widgets, `CustomPaint`
  connections. Forge2D (pinned at 0.15.1; check compatibility before
  upgrading) adds circular collisions and gentle drift around semantic
  anchors.
  - Advance physics on a fixed time step, never on pointer events.
  - Rebuild bodies when graph membership or viewport size changes.
  - Connections are visual only.
- Selecting a Node opens a floating details window and never moves the graph.
  Home (top left) clears search and overlays and resets the camera.
- Drafts (create and edit) stay open until the API accepts them. Saves send the
  last observed `update_count`.
- One shared appearance ruleset: highest weight wins, list order breaks ties.

## Planes

- **Time** is a full-canvas HUD and the camera's scale basis: NOW centered,
  future up, past down. Home shows about ±12 hours, and zooming out widens the
  span.
  - Hour and date guides are generated from the calendar whether or not Nodes
    exist, and they follow pan and zoom.
  - The top bubble shows the distance around NOW while NOW is visible, and the
    bottom-to-top interval otherwise.
- **Date Nodes** are HUD date labels, never Forge2D bodies. Filled means the
  Node exists, outlined means create. Both open the shared editor, which fills
  in the slug, `Date` label, and one-day span.
- **Location** gets the bottom dimension (planned). Top and right stay
  unassigned.
- Viewport loading must query by canonical placement or its explicit absence.
