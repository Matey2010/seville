# Flutter overlays

`LandscapeXlLayoutView` is the direct body of its `Scaffold`. Ordinary
interface and graph content remains Flame-rendered, while transient Flutter
presentation uses the native overlay system through `overlay_layers`. Seville
does not maintain a parallel HUD `Stack` around the game.

Search is not a Flutter overlay. `SearchHudComponent` is rendered and controlled
inside the Flame game, so it cannot mount a transparent Flutter backdrop over
layout interaction. `overlay_layers` is currently used only for toast widgets.

## Toast widgets

Toast producers append `ToastEvent` values through `toastProvider`; they do not
import `overlay_layers` or require a `BuildContext`. The screen forwards the
durable queue to `ToastOverlayPresenter`, which calls the public generic
`OverlayManager` with `OverlayType.toast`. No invisible toast-layer widget is
mounted in the `Scaffold`.

The overlay body is `ToastWidgets`, a safe top-right collection of
`ToastWidget` values. Each event remains visible for three seconds and carries
the protobuf `NotificationType`. `ToastWidget` currently owns these Flutter
colors:

| Type | Background | Foreground |
| --- | --- | --- |
| `info` | blue `#1976D2` | white |
| `error` | red `#D32F2F` | white |
| `warning` | yellow `#F9A825` | dark |
| `success` | green `#388E3C` | white |

The protobuf enum owns semantic severity only, never presentation.

## overlay_layers dependency

Seville currently consumes the hosted package:

```yaml
dependencies:
  overlay_layers: ^3.0.0
```

Version 3.0.0 exposes `PopupController` and the generic `OverlayManager`, but
not a specialized public toast controller. Search therefore uses the popup
controller directly, while toast presentation uses the manager's
`OverlayType.toast` path. No application wrapper is required.

When package development moves into this workspace, replace the hosted
dependency without changing imports:

```yaml
dependencies:
  overlay_layers:
    path: packages/overlay_layers
```

All package use stays behind the screen/presenter boundary so Riverpod actions
and Flame components remain independent from overlay implementation details.
