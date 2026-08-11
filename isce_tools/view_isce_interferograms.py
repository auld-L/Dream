#!/usr/bin/env python3
"""Batch-render ISCE interferograms into PNG quick-look images."""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def read_xml_value(xml_path: Path, name: str):
    root = ET.parse(xml_path).getroot()
    for element in root.iter():
        if element.tag.split("}")[-1] != "property":
            continue
        property_name = element.attrib.get("name", "")
        if not property_name:
            name_node = next((child for child in element if child.tag.split("}")[-1] == "name"), None)
            property_name = name_node.text if name_node is not None and name_node.text else ""
        if property_name.upper() != name.upper():
            continue
        value_node = next((child for child in element if child.tag.split("}")[-1] == "value"), None)
        if value_node is None or value_node.text is None:
            continue
        value = value_node.text.strip()
        try:
            return int(value)
        except ValueError:
            return value
    raise ValueError(f"{name} was not found in {xml_path}")


def image_shape(image_path: Path) -> tuple[int, int]:
    xml_path = image_path.with_name(image_path.name + ".xml")
    if not xml_path.exists():
        xml_path = image_path.with_suffix(image_path.suffix + ".xml")
    if not xml_path.exists():
        raise FileNotFoundError(f"Missing ISCE XML metadata: {xml_path}")
    return int(read_xml_value(xml_path, "LENGTH")), int(read_xml_value(xml_path, "WIDTH"))


def read_int(image_path: Path) -> tuple[np.ndarray, np.ndarray]:
    length, width = image_shape(image_path)
    values = np.fromfile(image_path, dtype=np.complex64)
    expected = length * width
    if values.size < expected:
        raise ValueError(f"{image_path} contains {values.size} complex pixels; expected {expected}")
    values = values[:expected].reshape(length, width)
    amplitude = np.abs(values)
    phase = np.angle(values)
    return amplitude, phase


def read_unw(image_path: Path) -> tuple[np.ndarray, np.ndarray]:
    length, width = image_shape(image_path)
    values = np.fromfile(image_path, dtype=np.float32)
    expected = 2 * length * width
    if values.size < expected:
        raise ValueError(f"{image_path} contains {values.size} float values; expected {expected}")
    values = values[:expected].reshape(length, 2, width)
    return values[:, 0, :], values[:, 1, :]


def percentile_limits(values: np.ndarray, low: float, high: float) -> tuple[float, float]:
    valid = values[np.isfinite(values)]
    if valid.size == 0:
        return 0.0, 1.0
    limits = np.percentile(valid, [low, high])
    if limits[0] == limits[1]:
        limits = np.array([limits[0] - 1.0, limits[1] + 1.0])
    return float(limits[0]), float(limits[1])


def render(image_path: Path, output_path: Path, kind: str, dpi: int, clip_low: float, clip_high: float) -> None:
    if kind == "int":
        amplitude, phase = read_int(image_path)
        phase_title = "Wrapped phase (rad)"
        phase_cmap = "twilight"
        phase_limits = (-np.pi, np.pi)
    else:
        amplitude, phase = read_unw(image_path)
        phase_title = "Unwrapped phase (rad)"
        phase_cmap = "turbo"
        phase_limits = percentile_limits(phase[amplitude > 0], clip_low, clip_high)

    amplitude_db = 20.0 * np.log10(np.maximum(amplitude, np.finfo(np.float32).tiny))
    amplitude_limits = percentile_limits(amplitude_db[amplitude > 0], clip_low, clip_high)
    invalid = ~np.isfinite(amplitude) | ~np.isfinite(phase) | (amplitude <= 0)
    masked_amplitude = np.ma.masked_where(invalid, amplitude_db)
    masked_phase = np.ma.masked_where(invalid, phase)

    figure, axes = plt.subplots(1, 2, figsize=(14, 6), constrained_layout=True)
    amplitude_image = axes[0].imshow(masked_amplitude, cmap="gray", vmin=amplitude_limits[0], vmax=amplitude_limits[1])
    phase_image = axes[1].imshow(masked_phase, cmap=phase_cmap, vmin=phase_limits[0], vmax=phase_limits[1])
    axes[0].set_title(f"{image_path.parent.name} amplitude (dB)")
    axes[1].set_title(f"{image_path.parent.name} {phase_title}")
    for axis in axes:
        axis.set_xlabel("Range pixel")
        axis.set_ylabel("Azimuth pixel")
    figure.colorbar(amplitude_image, ax=axes[0], fraction=0.046, pad=0.04)
    figure.colorbar(phase_image, ax=axes[1], fraction=0.046, pad=0.04)
    figure.savefig(output_path, dpi=dpi)
    plt.close(figure)


def pair_name(path: Path) -> str:
    match = re.search(r"(\d{8}_\d{8})", path.parent.name)
    return match.group(1) if match else path.parent.name


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_dir", type=Path, help="Directory containing date-pair subdirectories")
    parser.add_argument("output_dir", type=Path, help="Directory in which PNG files are written")
    parser.add_argument("--pattern", default="filt_fine.int", choices=["filt_fine.int", "fine.int", "filt_fine.unw", "fine.unw"], help="ISCE product to render")
    parser.add_argument("--dpi", type=int, default=180)
    parser.add_argument("--clip-low", type=float, default=2.0, help="Lower percentile for amplitude and unwrapped phase")
    parser.add_argument("--clip-high", type=float, default=98.0, help="Upper percentile for amplitude and unwrapped phase")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    kind = "unw" if args.pattern.endswith(".unw") else "int"
    paths = sorted(args.input_dir.glob(f"*/{args.pattern}"))
    if not paths:
        raise SystemExit(f"No files matched {args.input_dir}/*/{args.pattern}")
    failures = 0
    for path in paths:
        output_path = args.output_dir / f"{pair_name(path)}_{kind}.png"
        try:
            render(path, output_path, kind, args.dpi, args.clip_low, args.clip_high)
            print(f"written: {output_path}")
        except Exception as error:
            failures += 1
            print(f"skipped: {path}: {error}")
    if failures:
        print(f"Completed with {failures} skipped file(s).")


if __name__ == "__main__":
    main()
