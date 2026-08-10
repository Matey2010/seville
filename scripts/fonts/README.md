# SVG font compiler

Seville builds custom fonts locally with FontForge. Linearity Curve owns each
SVG prototype; the JSON manifest owns Unicode identity, font metrics, advance
geometry, outputs, and the optional migration base. No hosted font service
participates in the build.

Build the default Sevifont manifest from the repository root:

```sh
make -C scripts buildFont
```

Validate inputs and calculated glyph bounds without changing generated files:

```sh
make -C scripts checkFont
```

Use another manifest with either target:

```sh
make -C scripts buildFont manifest=path/to/font.json
```

FontForge is the only external compiler dependency:

```sh
brew install fontforge
```

## Coordinate contract

Every SVG uses a view box starting at `0 0` whose height equals the manifest's
`unitsPerEm`. With Sevifont's current metrics, the shared Linearity artboard is
`1024` units high and FontForge maps it as follows:

```text
SVG Y=0      → font Y=864   ascender
SVG Y=160    → font Y=704   cap height
SVG Y=352    → font Y=512   x-height
SVG Y=864    → font Y=0     baseline
SVG Y=1024   → font Y=-160  descender
```

The compiler rejects cropped SVG view boxes, live strokes, text, raster images,
and geometry that escapes the configured advance or vertical font bounds.
Export one monochrome filled silhouette from Linearity. Colors and borders are
runtime presentation rather than font data.

For a glyph designed on the shared `1024×1024` prototype, the manifest's
`sourceAdvanceLeft` selects the left edge of its visible advance box and
`advanceWidth` supplies the generated horizontal advance. The compiler moves
that source edge to font X=0. Optional `scale`, `xOffset`, and `yOffset` fields
provide explicit per-glyph adjustments when a deliberate exception is needed.

`expectedBounds` is optional. Any supplied `xMin`, `yMin`, `xMax`, or `yMax`
becomes a generation guard with the configured `tolerance`.

## Add or customize a glyph

Add an entry to the manifest's ordered `glyphs` list. The name is the font's
glyph name, `dartName` becomes the generated `Sevifont` constant, and
`codePoint` is the character that displays the artwork:

```json
{
  "name": "a",
  "dartName": "a",
  "codePoint": "U+0061",
  "source": "a.svg",
  "sourceAdvanceLeft": 320,
  "advanceWidth": 384,
  "xOffset": 0,
  "yOffset": 0,
  "scale": 1,
  "expectedBounds": {
    "yMin": 0,
    "yMax": 512,
    "tolerance": 1
  }
}
```

`source` is resolved from `sourceDirectory`. Change the advance box and
optional transforms in JSON, run `checkFont`, then run `buildFont`. Glyph names,
Unicode values, Dart identifiers, SVG structure, and resolved bounds are all
validated before any generated output is replaced.

## Migration away from IcoMoon

`baseFont` is optional. Sevifont temporarily points to the preserved IcoMoon
font so characters not yet represented in the SVG manifest remain available.
Every manifest glyph replaces the matching character from that base. Once the
SVG pool is complete, remove `baseFont`; the compiler will create the entire
font from manifest-owned sources only.

Generated TTF, OTF, and Dart files are outputs. Edit the SVG or manifest and
rebuild instead of editing generated artifacts by hand.
