#!/usr/bin/env python3
"""List/extract the L1 diagnostic DML catalogue from an extracted flat image.

Input is the flat image produced by:
  tools/imd.py <A.IMD> extract /tmp/diskA.bin
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path


SECTORS_PER_CYL = 52
TRACK0_128B_AS_256B = 13
SECTOR_SIZE = 256


@dataclass
class Entry:
    ext: int
    loc: int
    length: int
    index: int
    name: str
    record_offset: int

    @property
    def logical_sector(self) -> int:
        return (
            (self.ext * SECTOR_SIZE)
            + ((self.loc >> 8) * SECTORS_PER_CYL)
            + (self.loc & 0xFF)
        )

    @property
    def flat_sector(self) -> int:
        return self.logical_sector - TRACK0_128B_AS_256B

    @property
    def flat_offset(self) -> int:
        return self.flat_sector * SECTOR_SIZE

    @property
    def byte_length(self) -> int:
        return self.length * SECTOR_SIZE


def decode_ascii(raw: bytes) -> str:
    return raw.rstrip(b" \x00").decode("ascii", "replace")


def catalog_offset(vol1: bytes) -> tuple[int, int]:
    if vol1[:4] != b"VOL1":
        raise ValueError("VOL1 label not found at flat offset 0x300")

    track = vol1[0x1C]
    sector = vol1[0x1D]
    count = vol1[0x1E]
    logical = track * SECTORS_PER_CYL + (sector - 1)
    flat_sector = logical - TRACK0_128B_AS_256B
    return flat_sector * SECTOR_SIZE, count


def read_catalog(image: bytes) -> tuple[int, int, str, list[Entry]]:
    offset, count = catalog_offset(image[0x300:0x340])
    special = decode_ascii(image[offset + 2 : offset + 16])

    entries: list[Entry] = []
    pos = offset + 16
    end = offset + count * SECTOR_SIZE
    while pos + 20 <= end:
        rec = image[pos : pos + 20]
        index = rec[5]
        if index == 0xFF or rec[6] == 0xFF:
            break
        name = decode_ascii(rec[6:20])
        if not name or not all(32 <= b < 127 for b in rec[6 : 6 + len(name)]):
            break
        entries.append(
            Entry(
                ext=rec[0],
                loc=int.from_bytes(rec[1:3], "little"),
                length=rec[3],
                index=index,
                name=name,
                record_offset=pos,
            )
        )
        pos += 20
    return offset, count, special, entries


def cmd_list(args: argparse.Namespace) -> None:
    image = Path(args.image).read_bytes()
    offset, count, special, entries = read_catalog(image)
    print(f"catalog offset=0x{offset:05x} sectors={count} special={special}")
    print("idx ext loc   len  flat_sec  flat_off  bytes  name")
    for e in entries:
        print(
            f"{e.index:3d}  {e.ext:02x}   {e.loc:04x}  {e.length:02x}"
            f"   {e.flat_sector:7d}  0x{e.flat_offset:05x}"
            f"  {e.byte_length:5d}  {e.name}"
        )


def find_entry(entries: list[Entry], name: str) -> Entry:
    needle = name.upper()
    matches = [e for e in entries if e.name.upper().startswith(needle)]
    if not matches:
        raise SystemExit(f"no catalogue entry matching {name!r}")
    if len(matches) > 1:
        choices = ", ".join(e.name for e in matches)
        raise SystemExit(f"ambiguous name {name!r}: {choices}")
    return matches[0]


def cmd_extract(args: argparse.Namespace) -> None:
    image = Path(args.image).read_bytes()
    _, _, _, entries = read_catalog(image)
    entry = find_entry(entries, args.name)
    data = image[entry.flat_offset : entry.flat_offset + entry.byte_length]
    if len(data) != entry.byte_length:
        raise SystemExit(f"entry extends beyond end of image: {entry.name}")
    Path(args.output).write_bytes(data)
    print(
        f"extracted {entry.name}: loc=0x{entry.loc:04x}"
        f" offset=0x{entry.flat_offset:05x} bytes={entry.byte_length}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("list", help="list DML catalogue entries")
    p_list.add_argument("image", help="flat image from tools/imd.py extract")
    p_list.set_defaults(func=cmd_list)

    p_extract = sub.add_parser("extract", help="extract a catalogue entry")
    p_extract.add_argument("image", help="flat image from tools/imd.py extract")
    p_extract.add_argument("name", help="catalogue name or unique prefix")
    p_extract.add_argument("output", help="output file")
    p_extract.set_defaults(func=cmd_extract)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
