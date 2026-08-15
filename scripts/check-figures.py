#!/usr/bin/env python3
"""Compare two directories of screenshots by pixel, not by byte.

Byte comparison does not work here, and the reason is worth knowing: two runs
of shoot-ios.sh can produce PNGs with identical pixels, identical EXIF and
identical chunk structure, and still differ in their bytes, because the same
image does not always compress to the same IDAT stream. `git diff` on a PNG
therefore reports changes that do not exist.

Exit codes: 0 identical, 1 a figure changed, 2 something is missing.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops

# Figures that legitimately differ between runs, with the reason. Anything on
# this list is checked for existence only. Keep it short and keep the reasons
# honest - it is the list where excuses accumulate.
UNSTABLE = {
    "ios-add-deck": "text field caret blinks; the frame it is caught in varies",
}


def differing_region(a: Path, b: Path) -> tuple | None:
    first = Image.open(a).convert("RGB")
    second = Image.open(b).convert("RGB")
    if first.size != second.size:
        return (0, 0, *first.size)
    return ImageChops.difference(first, second).getbbox()


def main(committed: Path, fresh: Path) -> int:
    status = 0
    for expected in sorted(committed.glob("*.png")):
        actual = fresh / expected.name
        name = expected.stem
        if not actual.exists():
            print(f"MISSING  {name} — the script did not produce it")
            status = max(status, 2)
            continue
        if name in UNSTABLE:
            print(f"skipped  {name} — {UNSTABLE[name]}")
            continue
        region = differing_region(expected, actual)
        if region is None:
            print(f"ok       {name}")
        else:
            print(f"CHANGED  {name} — pixels differ in region {region}")
            status = max(status, 1)
    return status


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: check-figures.py <committed-dir> <fresh-dir>")
    raise SystemExit(main(Path(sys.argv[1]), Path(sys.argv[2])))
