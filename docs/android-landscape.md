# Android landscape client

Android phone landscape remains experimental. The native Flutter workspace
adapts its panes to available width: wide windows show Node list, graph, and
details; medium windows show graph and details; narrow windows stack graph and
details. Android portrait is disabled at startup and in the activity manifest.
The owner performs Pixel build and runtime verification.

## Connecting a physical Pixel

`127.0.0.1` on the phone refers to the phone. Set `SEVILLE_BASE_URL` to the
Mac's reachable LAN address, set `SEVILLE_ADDR` so the Go API listens on that
interface, and use the same `SEVILLE_TOKEN` on both sides. The phone and Mac
must be on the same network. Do not expose the local API to an untrusted
network. The Android debug manifest permits local HTTP for development;
production traffic should use HTTPS.

The orientation lock and app entry point live in
`frontend/seville7/lib/main.dart`; responsive composition lives in
`frontend/seville7/lib/screens/knowledge_workspace.dart`.
