#!/usr/bin/env python3
"""Build a deterministic OpenType font from manifest-owned SVG glyphs.

Run this script through FontForge's Python interpreter:

    fontforge -lang=py -script scripts/fonts/build_font.py MANIFEST.json

The SVG coordinate system is preserved. FontForge maps an SVG artboard whose
height equals unitsPerEm so that SVG Y=ascent becomes the font baseline. Each
glyph manifest then translates its configured source advance box to X=0.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import fontforge
import psMat


class FontBuildError(Exception):
    pass


def _required(mapping, key, context):
    if key not in mapping:
        raise FontBuildError(f'{context} is missing required field "{key}".')
    return mapping[key]


def _number(value, context):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise FontBuildError(f"{context} must be a number.")
    if not math.isfinite(float(value)):
        raise FontBuildError(f"{context} must be finite.")
    return float(value)


def _integer(value, context):
    number = _number(value, context)
    if not number.is_integer():
        raise FontBuildError(f"{context} must be an integer.")
    return int(number)


def _resolve(base, value):
    path = Path(value).expanduser()
    return path.resolve() if path.is_absolute() else (base / path).resolve()


def _code_point(value, context):
    if isinstance(value, int) and not isinstance(value, bool):
        code_point = value
    elif isinstance(value, str):
        source = value.strip()
        if len(source) == 1:
            code_point = ord(source)
        elif source.upper().startswith("U+"):
            code_point = int(source[2:], 16)
        elif source.lower().startswith("0x"):
            code_point = int(source[2:], 16)
        else:
            raise FontBuildError(
                f'{context} must be an integer, one character, "U+XXXX", or "0xXXXX".'
            )
    else:
        raise FontBuildError(
            f'{context} must be an integer, one character, "U+XXXX", or "0xXXXX".'
        )
    if not 0 <= code_point <= 0x10FFFF or 0xD800 <= code_point <= 0xDFFF:
        raise FontBuildError(f"{context} is not a valid Unicode scalar value.")
    return code_point


def _view_box(svg_path, units_per_em):
    try:
        root = ET.parse(svg_path).getroot()
    except (ET.ParseError, OSError) as error:
        raise FontBuildError(f"Cannot read SVG {svg_path}: {error}") from error

    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise FontBuildError(f"SVG source has no SVG root: {svg_path}")
    raw_view_box = root.attrib.get("viewBox")
    if raw_view_box is None:
        raise FontBuildError(f"SVG source has no viewBox: {svg_path}")
    try:
        values = [float(value) for value in re.split(r"[\s,]+", raw_view_box.strip())]
    except ValueError as error:
        raise FontBuildError(f"SVG source has an invalid viewBox: {svg_path}") from error
    if len(values) != 4 or not all(math.isfinite(value) for value in values):
        raise FontBuildError(f"SVG source has an invalid viewBox: {svg_path}")
    min_x, min_y, width, height = values
    if abs(min_x) > 0.001 or abs(min_y) > 0.001:
        raise FontBuildError(
            f"SVG viewBox must start at 0 0, got {raw_view_box!r}: {svg_path}"
        )
    if abs(height - units_per_em) > 0.001:
        raise FontBuildError(
            f"SVG viewBox height must equal unitsPerEm ({units_per_em}), "
            f"got {height:g}: {svg_path}"
        )
    if width <= 0:
        raise FontBuildError(f"SVG viewBox width must be positive: {svg_path}")

    for element in root.iter():
        tag = element.tag.rsplit("}", 1)[-1]
        if tag in {"text", "image", "use"}:
            raise FontBuildError(
                f"SVG source contains unsupported <{tag}> content: {svg_path}"
            )
        stroke = element.attrib.get("stroke", "").strip().lower()
        style = element.attrib.get("style", "").lower().replace(" ", "")
        if (stroke and stroke != "none") or (
            "stroke:" in style and "stroke:none" not in style
        ):
            raise FontBuildError(
                f"SVG source contains a live stroke; export one filled silhouette: {svg_path}"
            )
    return width


def _configure_font(font, config):
    units_per_em = _integer(
        _required(config, "unitsPerEm", "font"), "font.unitsPerEm"
    )
    ascent = _integer(_required(config, "ascent", "font"), "font.ascent")
    descent = _integer(_required(config, "descent", "font"), "font.descent")
    if units_per_em <= 0 or ascent <= 0 or descent < 0:
        raise FontBuildError("Font unitsPerEm/ascent must be positive; descent cannot be negative.")
    if ascent + descent != units_per_em:
        raise FontBuildError("font.ascent + font.descent must equal font.unitsPerEm.")

    family = str(_required(config, "family", "font")).strip()
    style = str(config.get("style", "Regular")).strip()
    if not family or not style:
        raise FontBuildError("font.family and font.style cannot be empty.")
    postscript_name = str(
        config.get(
            "postScriptName",
            re.sub(r"[^A-Za-z0-9-]", "", f"{family}-{style}"),
        )
    )
    if not postscript_name:
        raise FontBuildError("font.postScriptName cannot be empty.")

    font.em = units_per_em
    font.ascent = ascent
    font.descent = descent
    font.encoding = "UnicodeFull"
    font.familyname = family
    font.fullname = str(config.get("fullName", f"{family} {style}"))
    font.fontname = postscript_name
    font.weight = style
    font.version = str(config.get("version", "1.0"))
    font.copyright = str(config.get("copyright", ""))
    font.comment = str(
        config.get(
            "comment",
            "Generated from manifest-owned SVG sources by Seville's FontForge compiler.",
        )
    )

    font.os2_typoascent = ascent
    font.os2_typodescent = -descent
    font.os2_typolinegap = 0
    font.os2_winascent = ascent
    font.os2_windescent = descent
    font.os2_use_typo_metrics = True
    font.hhea_ascent = ascent
    font.hhea_descent = -descent
    font.hhea_linegap = 0
    font.os2_capheight = _integer(
        config.get("capHeight", ascent), "font.capHeight"
    )
    font.os2_xheight = _integer(config.get("xHeight", ascent), "font.xHeight")
    return units_per_em, ascent, descent, family


def _check_expected_bounds(name, actual, expected):
    if expected is None:
        return
    if not isinstance(expected, dict):
        raise FontBuildError(f"glyph {name}.expectedBounds must be an object.")
    tolerance = _number(expected.get("tolerance", 1), f"glyph {name} tolerance")
    keys = {"xMin": 0, "yMin": 1, "xMax": 2, "yMax": 3}
    for key, index in keys.items():
        if key not in expected:
            continue
        requested = _number(expected[key], f"glyph {name} expectedBounds.{key}")
        if abs(actual[index] - requested) > tolerance:
            raise FontBuildError(
                f"glyph {name} {key} is {actual[index]:.3f}; "
                f"expected {requested:g} ± {tolerance:g}."
            )


def _build_glyph(font, glyph_config, sources_dir, units_per_em, ascent, descent):
    name = str(_required(glyph_config, "name", "glyph")).strip()
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.-]*", name):
        raise FontBuildError(f"Invalid glyph name {name!r}.")
    code_point = _code_point(
        _required(glyph_config, "codePoint", f"glyph {name}"),
        f"glyph {name}.codePoint",
    )
    svg_path = _resolve(
        sources_dir,
        _required(glyph_config, "source", f"glyph {name}"),
    )
    if not svg_path.is_file():
        raise FontBuildError(f"Glyph SVG does not exist: {svg_path}")
    source_width = _view_box(svg_path, units_per_em)

    advance_width = _number(
        _required(glyph_config, "advanceWidth", f"glyph {name}"),
        f"glyph {name}.advanceWidth",
    )
    source_advance_left = _number(
        glyph_config.get("sourceAdvanceLeft", 0),
        f"glyph {name}.sourceAdvanceLeft",
    )
    scale = _number(glyph_config.get("scale", 1), f"glyph {name}.scale")
    x_offset = _number(glyph_config.get("xOffset", 0), f"glyph {name}.xOffset")
    y_offset = _number(glyph_config.get("yOffset", 0), f"glyph {name}.yOffset")
    if advance_width <= 0 or scale <= 0:
        raise FontBuildError(f"glyph {name} advanceWidth and scale must be positive.")
    source_advance_right = source_advance_left + advance_width / scale
    if source_advance_left < 0 or source_advance_right > source_width + 0.001:
        raise FontBuildError(
            f"glyph {name} advance box [{source_advance_left:g}, "
            f"{source_advance_right:g}] lies outside SVG width {source_width:g}."
        )

    glyph = font.createChar(code_point, name)
    glyph.clear()
    glyph.glyphname = name
    glyph.importOutlines(str(svg_path))
    if scale != 1:
        glyph.transform(psMat.scale(scale))
    glyph.transform(
        psMat.translate(-source_advance_left * scale + x_offset, y_offset)
    )
    glyph.correctDirection()
    glyph.width = round(advance_width)

    bounds = glyph.boundingBox()
    if bounds[0] < -0.001 or bounds[2] > advance_width + 0.001:
        raise FontBuildError(
            f"glyph {name} horizontal bounds [{bounds[0]:.3f}, {bounds[2]:.3f}] "
            f"escape advance width {advance_width:g}."
        )
    if bounds[1] < -descent - 0.001 or bounds[3] > ascent + 0.001:
        raise FontBuildError(
            f"glyph {name} vertical bounds [{bounds[1]:.3f}, {bounds[3]:.3f}] "
            f"escape font bounds [{-descent}, {ascent}]."
        )
    _check_expected_bounds(name, bounds, glyph_config.get("expectedBounds"))
    return {
        "name": name,
        "dartName": str(glyph_config.get("dartName", name)),
        "codePoint": code_point,
        "bounds": bounds,
        "advanceWidth": glyph.width,
        "source": svg_path,
    }


def _dart_identifier(value, context):
    pieces = re.findall(r"[A-Za-z0-9]+", value)
    if not pieces:
        raise FontBuildError(f"{context} does not contain a Dart identifier.")
    identifier = pieces[0][0].lower() + pieces[0][1:]
    identifier += "".join(piece[0].upper() + piece[1:] for piece in pieces[1:])
    if identifier[0].isdigit():
        identifier = f"glyph{identifier}"
    if identifier in {
        "abstract", "as", "assert", "async", "await", "break", "case",
        "catch", "class", "const", "continue", "covariant", "default",
        "deferred", "do", "dynamic", "else", "enum", "export", "extends",
        "extension", "external", "factory", "false", "final", "finally",
        "for", "function", "get", "hide", "if", "implements", "import",
        "in", "interface", "is", "late", "library", "mixin", "new", "null",
        "on", "operator", "part", "required", "rethrow", "return", "set",
        "show", "static", "super", "switch", "sync", "this", "throw", "true",
        "try", "typedef", "var", "void", "when", "while", "with", "yield",
    }:
        identifier = f"glyph{identifier[0].upper()}{identifier[1:]}"
    return identifier


def _dart_source(family, class_name, glyphs, manifest_path):
    identifiers = set()
    lines = [
        "// Generated file. Do not edit by hand.",
        f"// Source: {manifest_path.name}",
        "",
        "import 'package:flutter/widgets.dart';",
        "",
        f"abstract final class {class_name} {{",
        f"  static const fontFamily = {family!r};",
        "",
    ]
    for glyph in glyphs:
        identifier = _dart_identifier(glyph["dartName"], f"glyph {glyph['name']}")
        if identifier in identifiers:
            raise FontBuildError(f"Duplicate generated Dart identifier {identifier!r}.")
        identifiers.add(identifier)
        lines.append(
            f"  static const IconData {identifier} = "
            f"IconData(0x{glyph['codePoint']:x}, fontFamily: fontFamily);"
        )
    lines.extend(["}", ""])
    return "\n".join(lines)


def _atomic_generate(font, output_path):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output_path.stem}.", suffix=output_path.suffix, dir=output_path.parent
    )
    os.close(descriptor)
    temporary_path = Path(temporary_name)
    temporary_path.unlink()
    try:
        font.generate(str(temporary_path), flags=("opentype",))
        if not temporary_path.is_file() or temporary_path.stat().st_size == 0:
            raise FontBuildError(f"FontForge did not generate {output_path}.")
        os.replace(temporary_path, output_path)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def _atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.stem}.", suffix=path.suffix, dir=path.parent, text=True
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
        os.replace(temporary_name, path)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)


def build(manifest_path, check_only):
    manifest_path = manifest_path.resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise FontBuildError(f"Cannot read manifest {manifest_path}: {error}") from error
    if not isinstance(manifest, dict):
        raise FontBuildError("Font manifest root must be an object.")
    manifest_dir = manifest_path.parent
    font_config = _required(manifest, "font", "manifest")
    outputs = _required(manifest, "outputs", "manifest")
    glyph_configs = _required(manifest, "glyphs", "manifest")
    if not isinstance(font_config, dict) or not isinstance(outputs, dict):
        raise FontBuildError("manifest.font and manifest.outputs must be objects.")
    if not isinstance(glyph_configs, list) or not glyph_configs:
        raise FontBuildError("manifest.glyphs must be a non-empty list.")

    sources_dir = _resolve(manifest_dir, manifest.get("sourceDirectory", "."))
    base_value = manifest.get("baseFont")
    base_path = _resolve(manifest_dir, base_value) if base_value else None
    if base_path is not None and not base_path.is_file():
        raise FontBuildError(f"Base font does not exist: {base_path}")
    font = fontforge.open(str(base_path)) if base_path else fontforge.font()
    try:
        units_per_em, ascent, descent, family = _configure_font(font, font_config)
        glyphs = []
        code_points = set()
        names = set()
        for glyph_config in glyph_configs:
            if not isinstance(glyph_config, dict):
                raise FontBuildError("Every manifest glyph must be an object.")
            glyph = _build_glyph(
                font, glyph_config, sources_dir, units_per_em, ascent, descent
            )
            if glyph["codePoint"] in code_points:
                raise FontBuildError(
                    f"Duplicate code point U+{glyph['codePoint']:04X} in manifest."
                )
            if glyph["name"] in names:
                raise FontBuildError(f"Duplicate glyph name {glyph['name']!r} in manifest.")
            code_points.add(glyph["codePoint"])
            names.add(glyph["name"])
            glyphs.append(glyph)
            bounds = glyph["bounds"]
            print(
                f"{glyph['name']} U+{glyph['codePoint']:04X} "
                f"bbox=({bounds[0]:.3f}, {bounds[1]:.3f}, "
                f"{bounds[2]:.3f}, {bounds[3]:.3f}) "
                f"advance={glyph['advanceWidth']}"
            )

        if check_only:
            print(f"Validated {len(glyphs)} glyph(s); outputs were not changed.")
            return

        ttf_path = _resolve(manifest_dir, _required(outputs, "ttf", "outputs"))
        otf_path = _resolve(manifest_dir, _required(outputs, "otf", "outputs"))
        dart_path = _resolve(manifest_dir, _required(outputs, "dart", "outputs"))
        dart_class = str(outputs.get("dartClass", family.replace(" ", "")))
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", dart_class):
            raise FontBuildError(f"Invalid outputs.dartClass {dart_class!r}.")

        _atomic_generate(font, ttf_path)
        _atomic_generate(font, otf_path)
        _atomic_write(
            dart_path,
            _dart_source(family, dart_class, glyphs, manifest_path),
        )
        print(f"Generated {ttf_path}")
        print(f"Generated {otf_path}")
        print(f"Generated {dart_path}")
    finally:
        font.close()


def main():
    parser = argparse.ArgumentParser(
        description="Build TTF, OTF, and Dart glyph constants from SVG sources."
    )
    parser.add_argument("manifest", type=Path)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate SVGs and resolved glyph metrics without writing outputs.",
    )
    arguments = parser.parse_args()
    try:
        build(arguments.manifest, arguments.check)
    except FontBuildError as error:
        print(f"Font build failed: {error}", file=sys.stderr)
        raise SystemExit(65) from error


if __name__ == "__main__":
    main()
