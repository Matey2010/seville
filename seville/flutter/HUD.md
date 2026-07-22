# Flutter HUD layers

Seville renders ordinary interface and graph content with Flame components.
Flutter widgets are reserved for the `GameWidget` host and deliberately named
HUD layers. The current HUDs are `SearchHud` and `HudToastLayer`.

## Toast flow

Toast state belongs to Riverpod:

1. An application action calls `hudToastProvider.notifier`.
2. The notifier appends a uniquely numbered `HudToastEvent`, carrying the
   shared protobuf `NotificationType`, to its Riverpod queue.
3. `HudToastLayer` owns one lifecycle listener with immediate replay and sends
   the current queue to `overlay_layers` after the Flutter frame is ready.
4. One native Flutter overlay renders the active event list at the safe
   top-right corner.
5. Every message is removed after three seconds; the overlay is removed when
   the list becomes empty or the owning screen is disposed.

Copying a selected Node slug uses `showCopiedText(slug)` only after the system
clipboard write succeeds. Repeating the same copy still creates a new event
because event identity is numeric rather than message-based. Copy notifications
use `NotificationType.success`. Pressing any selected-Node action button, or
Command-C, without a selected Node emits the error notification
`🔴 No Node Selected`; copy leaves the clipboard untouched.

The provider retains each event until dismissal. This prevents an action from
being lost when the HUD listener mounts again after a rebuild or hot reload.

## Search flow

`SearchHud` only captures query text. Its Search button and the keyboard Enter
action both call the same submission method, which stores the normalized value
in `hudStateProvider` and closes the HUD. `nodeSearchProvider` then issues
`QUERY /nodes/v1/search` and retains the asynchronous response in Riverpod.

Search results are not HUD widgets. The configured right-plane
`NodeListLayout` renders returned Nodes as Flame rows between the action buttons
and Gamepad content. Rows use slug-based active membership and the shared Node
opacity defaults. Tapping an inactive or active result toggles the same
`selectedNodesProvider` set consumed by Fan and Graph layouts.

## Notification widget

`NotificationType` is defined in
`proto/seville/notification/v1/notification.proto` with exactly four values.
The enum carries meaning only; it does not carry colors or Flutter concerns.

`HudNotification` is the Flutter widget inserted as each toast body. It accepts
an arbitrary child widget and currently owns these fixed defaults:

| Type | Background | Foreground |
| --- | --- | --- |
| `info` | blue `#1976D2` | white |
| `error` | red `#D32F2F` | white |
| `warning` | yellow `#F9A825` | dark |
| `success` | green `#388E3C` | white |

Content-driven or configurable styling can replace this switch later without
changing protobuf values or Riverpod event identity.

Riverpod notifiers and action handlers must not import `overlay_layers` or need
a `BuildContext`. `lib/widgets/hud_toast_layer.dart` is the only adapter allowed
to know the package API.

## overlay_layers dependency

Seville currently consumes the hosted package:

```yaml
dependencies:
  overlay_layers: ^3.0.0
```

Version 3.0.0 publicly exposes `OverlayManager`, `OverlayDataContext`, and
`OverlayType.toast`; a specialized public `ToastController` is not available
yet. The adapter therefore uses the generic manager with the toast overlay
type. No wrapper around `MaterialApp` is required.

When package development moves into this Flutter workspace, replace the hosted
dependency with the same package name and a path dependency:

```yaml
dependencies:
  overlay_layers:
    path: packages/overlay_layers
```

Keep the public imports stable as
`package:overlay_layers/overlay_layers.dart`. This lets Seville interface work
and package work alternate without changing Riverpod state or application
actions.
