#!/usr/bin/env python3
"""Build an aligned SVG character from independently cropped SVG body parts."""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


SVG_NAMESPACE = "http://www.w3.org/2000/svg"
XLINK_NAMESPACE = "http://www.w3.org/1999/xlink"
VECTORNATOR_NAMESPACE = "http://vectornator.io"

ET.register_namespace("", SVG_NAMESPACE)
ET.register_namespace("xlink", XLINK_NAMESPACE)
ET.register_namespace("vectornator", VECTORNATOR_NAMESPACE)


class BodyBuildError(Exception):
    pass


def _number(value: object, field: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise BodyBuildError(f"{field} must be a number.")
    return float(value)


def _positive(value: object, field: str) -> float:
    result = _number(value, field)
    if result <= 0:
        raise BodyBuildError(f"{field} must be greater than zero.")
    return result


def _identifier(value: object, field: str) -> str:
    result = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(value).strip()).strip("-")
    if not result:
        raise BodyBuildError(f"{field} must contain an SVG-safe name.")
    return result


def _view_box(root: ET.Element, source: Path) -> tuple[float, float, float, float]:
    raw = root.get("viewBox", "").replace(",", " ").split()
    if len(raw) != 4:
        raise BodyBuildError(f"SVG requires a four-number viewBox: {source}")
    try:
        x, y, width, height = (float(value) for value in raw)
    except ValueError as error:
        raise BodyBuildError(f"SVG has an invalid viewBox: {source}") from error
    if width <= 0 or height <= 0:
        raise BodyBuildError(f"SVG viewBox dimensions must be positive: {source}")
    return x, y, width, height


def _prefix_ids(elements: list[ET.Element], prefix: str) -> None:
    replacements: dict[str, str] = {}
    for element in elements:
        for descendant in element.iter():
            identifier = descendant.get("id")
            if identifier:
                replacement = f"{prefix}__{identifier}"
                replacements[identifier] = replacement
                descendant.set("id", replacement)

    if not replacements:
        return
    for element in elements:
        for descendant in element.iter():
            for key, value in list(descendant.attrib.items()):
                updated = value
                for original, replacement in replacements.items():
                    updated = updated.replace(f"url(#{original})", f"url(#{replacement})")
                    if updated == f"#{original}":
                        updated = f"#{replacement}"
                descendant.set(key, updated)


def _format_number(value: float) -> str:
    return f"{value:.4f}".rstrip("0").rstrip(".")


def _load_part(
    config: dict[str, object],
    source_directory: Path,
    canvas_width: float,
    canvas_height: float,
) -> tuple[int, ET.Element]:
    name = _identifier(config.get("name", ""), "part.name")
    source_value = str(config.get("source", "")).strip()
    if not source_value:
        raise BodyBuildError(f"part {name!r} requires source.")
    source = (source_directory / source_value).resolve()
    if not source.is_file():
        raise BodyBuildError(f"Body-part source does not exist: {source}")

    frame = config.get("frame")
    if not isinstance(frame, dict):
        raise BodyBuildError(f"part {name!r} requires a frame object.")
    x = _number(frame.get("x"), f"{name}.frame.x")
    y = _number(frame.get("y"), f"{name}.frame.y")
    width = _positive(frame.get("width"), f"{name}.frame.width")
    height = _positive(frame.get("height"), f"{name}.frame.height")
    if x < 0 or y < 0 or x + width > canvas_width or y + height > canvas_height:
        raise BodyBuildError(
            f"part {name!r} frame ({x}, {y}, {width}, {height}) escapes "
            f"the {canvas_width}x{canvas_height} rig canvas."
        )

    try:
        source_root = ET.parse(source).getroot()
    except ET.ParseError as error:
        raise BodyBuildError(f"Invalid SVG XML: {source}: {error}") from error
    source_view_box = _view_box(source_root, source)
    children = [copy.deepcopy(child) for child in list(source_root)]
    _prefix_ids(children, name)

    outer = ET.Element(f"{{{SVG_NAMESPACE}}}g", {"id": name})
    transforms = [f"translate({_format_number(x)} {_format_number(y)})"]
    rotation = _number(config.get("rotation", 0), f"{name}.rotation")
    if rotation:
        transforms.append(
            "rotate("
            f"{_format_number(rotation)} {_format_number(width / 2)} "
            f"{_format_number(height / 2)})"
        )
    if config.get("mirrorX", False):
        transforms.append(f"translate({_format_number(width)} 0) scale(-1 1)")
    outer.set("transform", " ".join(transforms))

    nested_attributes = {
        "width": _format_number(width),
        "height": _format_number(height),
        "viewBox": " ".join(_format_number(value) for value in source_view_box),
        "preserveAspectRatio": str(config.get("preserveAspectRatio", "xMidYMid meet")),
    }
    for attribute in ("style", "stroke-miterlimit"):
        value = source_root.get(attribute)
        if value:
            nested_attributes[attribute] = value
    nested = ET.SubElement(outer, f"{{{SVG_NAMESPACE}}}svg", nested_attributes)
    nested.extend(children)

    z_index_value = config.get("zIndex", 0)
    if isinstance(z_index_value, bool) or not isinstance(z_index_value, int):
        raise BodyBuildError(f"{name}.zIndex must be an integer.")
    return z_index_value, outer


def build(manifest_path: Path, check_only: bool) -> None:
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise BodyBuildError(f"Cannot read body manifest {manifest_path}: {error}") from error
    if not isinstance(manifest, dict):
        raise BodyBuildError("Body manifest root must be an object.")

    canvas = manifest.get("canvas")
    if not isinstance(canvas, dict):
        raise BodyBuildError("manifest.canvas must be an object.")
    canvas_width = _positive(canvas.get("width"), "canvas.width")
    canvas_height = _positive(canvas.get("height"), "canvas.height")

    source_directory_value = str(manifest.get("sourceDirectory", ".")).strip()
    output_value = str(manifest.get("output", "")).strip()
    if not output_value:
        raise BodyBuildError("manifest.output cannot be empty.")
    source_directory = (manifest_path.parent / source_directory_value).resolve()
    output = (manifest_path.parent / output_value).resolve()

    parts = manifest.get("parts")
    if not isinstance(parts, list) or not parts:
        raise BodyBuildError("manifest.parts must be a non-empty list.")
    rendered_parts = []
    names: set[str] = set()
    for order, raw_part in enumerate(parts):
        if not isinstance(raw_part, dict):
            raise BodyBuildError(f"parts[{order}] must be an object.")
        name = _identifier(raw_part.get("name", ""), f"parts[{order}].name")
        if name in names:
            raise BodyBuildError(f"Duplicate body-part name: {name}")
        names.add(name)
        z_index, element = _load_part(
            raw_part, source_directory, canvas_width, canvas_height
        )
        rendered_parts.append((z_index, order, element))

    root = ET.Element(
        f"{{{SVG_NAMESPACE}}}svg",
        {
            "viewBox": f"0 0 {_format_number(canvas_width)} {_format_number(canvas_height)}",
            "width": "100%",
            "height": "100%",
            "style": "fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;",
            "version": "1.1",
        },
    )
    root.extend(element for _, _, element in sorted(rendered_parts))
    ET.indent(root, space="  ")

    if check_only:
        print(
            f"Body rig valid: {len(rendered_parts)} layers on "
            f"{_format_number(canvas_width)}x{_format_number(canvas_height)} canvas."
        )
        return

    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(f"{output.suffix}.tmp")
    ET.ElementTree(root).write(temporary, encoding="utf-8", xml_declaration=True)
    temporary.replace(output)
    print(f"Built body rig: {output}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    try:
        build(arguments.manifest.resolve(), arguments.check)
    except BodyBuildError as error:
        print(f"Body build failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
