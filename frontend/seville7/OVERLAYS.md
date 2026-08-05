# Flutter overlays

`LandscapeXlLayoutView` is the direct body of its `Scaffold`. Ordinary
interface and graph content remains Flame-rendered, while transient Flutter
presentation uses the native overlay system through `overlay_layers`.

`FindLayoutComponent` owns Find state and geometry inside the Flame game.
`FindInputOverlay` contributes only the native editable Flutter control in the
view's `Stack`; it uses the projected corners resolved by Flame and has no
full-screen hit backdrop. Find result Nodes and the surrounding layout remain
Flame-rendered. `overlay_layers` is currently used only for toast widgets.

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
not a specialized public toast controller. Toast presentation uses the
manager's `OverlayType.toast` path. Find does not use `overlay_layers`.

When package development moves into this workspace, replace the hosted
dependency without changing imports:

```yaml
dependencies:
  overlay_layers:
    path: packages/overlay_layers
```

All package use stays behind the screen/presenter boundary so Riverpod actions
and Flame components remain independent from overlay implementation details.
