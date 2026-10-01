# Android landscape layout

Seville has an experimental compact landscape preset for Android phones. It
uses the existing Layout tree, Riverpod state, Flame renderer, Node search,
creation flow, and gameplay kernel; LG Ergo remains the macOS preset. Android
screens with a landscape logical height of at most 600 pixels select the compact
preset. Larger Android screens retain LG Ergo until they have a dedicated
layout. Android portrait is disabled at startup and in the activity manifest.

The compact preset has a four-action touch menu (Continue, New Node, Find
Nodes, Today), the existing label-driven Node creation flow, a full-content
Find surface, and a closer character scene with a separate selected-Node area.
The bottom action returns from gameplay to the menu without discarding selected
Nodes. Android Back first closes an open input, then leaves gameplay or clears
an active creation draft; Back from the plain menu leaves the application.

## Connecting a physical Pixel

`127.0.0.1` on the phone is the phone, not the development Mac. Supply
`SEVILLE_BASE_URL` as the Mac's reachable LAN address and set `SEVILLE_ADDR`
so the Go API listens on that interface. The phone and Mac must be on the same
network, and `SEVILLE_TOKEN` must match on both sides. Do not expose the local
API to an untrusted network. The Android debug manifest permits local HTTP for
development; production traffic should use HTTPS. The application still needs
the project owner's on-device visual and interaction check.

The preset lives at
`frontend/seville7/lib/presets/compact_landscape/compact_landscape_layout_config.dart`.
Device selection and the orientation lock live in `frontend/seville7/lib/main.dart`.
