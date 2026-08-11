# SVG body rig compiler

Body-part SVGs are not font glyphs. Each source can keep its tightly cropped
Linearity artboard; `basic-human.body.json` owns the shared character canvas,
placement, mirroring, rotation, and layer order.

Build the default rig from the repository root:

```sh
make -C scripts buildBody
```

Validate the manifest and every SVG without changing generated output:

```sh
make -C scripts checkBody
```

To adjust anatomy, edit only
`frontend/seville7/assets/icons/vector/body-parts/basic-human.body.json`:

- `frame` positions and sizes a cropped source on the `1024×2048` rig canvas.
- `mirrorX` reuses a left-side prototype on the right side.
- `rotation` is clockwise in degrees around that part's frame center.
- `zIndex` controls overlap; larger values paint later and therefore on top.
- `source` selects another SVG variant, such as a different head.

Edit the original SVG in Linearity, export it over the same source file, then
run `buildBody`. The generated `basic-human.svg` is application output; do not
hand-edit it.
