#!/usr/bin/env python3
"""Create a sector-formatted (not BCOS-initialized) M40 8-inch blank.

Uses the track geometry and sector ordering of an existing IMD, but copies
none of its sector contents. Refuses unusual geometry and existing outputs.
"""
import argparse
from pathlib import Path

from imd import read_imd


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    tracks = read_imd(args.reference)
    expected = {(c, h) for c in range(77) for h in range(2)}
    if len(tracks) != 154 or {(t[1], t[2]) for t in tracks} != expected:
        raise ValueError("Expected exactly 77 cylinders, two heads")
    data = bytearray(b"IMD 1.18: M40 formatted blank; E5 sectors; no BCOS labels/files\r\n\x1a")
    for mode, cyl, head, count, size, sectors, _ in tracks:
        first = cyl == 0 and head == 0
        if (mode, count, size) != ((0, 26, 128) if first else (3, 26, 256)):
            raise ValueError(f"Unexpected geometry at {cyl}/{head}")
        if sorted(sectors) != list(range(1, 27)):
            raise ValueError(f"Unexpected sector IDs at {cyl}/{head}")
        data.extend((mode, cyl, head, count, 0 if first else 1))
        data.extend(sectors)
        data.extend(b"\x02\xe5" * count)  # Normal compressed sectors, E5 fill.
    with args.output.open("xb") as output:
        output.write(data)
    check = read_imd(args.output)
    assert [t[:6] for t in check] == [t[:6] for t in tracks]
    assert all(s == b"\xe5" * t[4] for t in check for s in t[6].values())
    print(f"Created {args.output}: {len(check)} tracks, 4004 sectors; no BCOS filesystem")


if __name__ == "__main__":
    main()
