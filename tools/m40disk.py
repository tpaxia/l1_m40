#!/usr/bin/env python3
"""Inspect and extract M30/M40 DCOS diagnostic and BCOS disks from IMD images.

This is intentionally scoped to the diagnostic DML catalog and the HDR1 extent
labels reverse engineered so far.  It is not a general M30/M40 filesystem tool.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


MODES = {
    0: "500k FM",
    1: "300k FM",
    2: "250k FM",
    3: "500k MFM",
    4: "300k MFM",
    5: "250k MFM",
}

SECTOR_TYPE_NAMES = {
    0: "unavailable",
    1: "normal",
    2: "compressed",
    3: "normal-deleted",
    4: "compressed-deleted",
    5: "normal-error",
    6: "compressed-error",
    7: "normal-deleted-error",
    8: "compressed-deleted-error",
}

DEFAULT_SECTORS_PER_TRACK = 26
DEFAULT_HEADS = 2
DEFAULT_SECTOR_SIZE = 256
TRACK0_128B_AS_256B = 13
VOL1_FLAT_OFFSET = 0x300


@dataclass(frozen=True)
class Sector:
    track_index: int
    mode: int
    cylinder: int
    head: int
    sector_id: int
    size: int
    imd_type: int
    data: bytes

    @property
    def type_name(self) -> str:
        return SECTOR_TYPE_NAMES.get(self.imd_type, f"type-{self.imd_type}")


@dataclass(frozen=True)
class Track:
    index: int
    mode: int
    cylinder: int
    head: int
    sector_size: int
    sector_ids: list[int]
    sectors: dict[int, Sector]

    @property
    def mode_name(self) -> str:
        return MODES.get(self.mode, f"mode-{self.mode}")


@dataclass(frozen=True)
class DmlEntry:
    ext: int
    loc: int
    length: int
    index: int
    name: str
    record_offset: int

    @property
    def logical_sector(self) -> int:
        return (
            self.ext * DEFAULT_SECTOR_SIZE
            + ((self.loc >> 8) * DEFAULT_SECTORS_PER_TRACK * DEFAULT_HEADS)
            + (self.loc & 0xff)
        )

    @property
    def flat_sector(self) -> int:
        return self.logical_sector - TRACK0_128B_AS_256B

    @property
    def flat_offset(self) -> int:
        return self.flat_sector * DEFAULT_SECTOR_SIZE

    @property
    def byte_length(self) -> int:
        return self.length * DEFAULT_SECTOR_SIZE


@dataclass(frozen=True)
class DmlCatalog:
    offset: int
    sectors: int
    special: str
    entries: list[DmlEntry]


@dataclass(frozen=True)
class BcosExtent:
    name: str
    record_size: int
    start_cylinder: int
    start_head: int
    start_sector: int
    end_cylinder: int
    end_head: int
    end_sector: int
    label_offset: int

    @property
    def start_text(self) -> str:
        return f"C{self.start_cylinder}/H{self.start_head}/S{self.start_sector}"

    @property
    def end_text(self) -> str:
        return f"C{self.end_cylinder}/H{self.end_head}/S{self.end_sector}"


class ImdFormatError(ValueError):
    pass


class DmlFormatError(ImdFormatError):
    pass


def decode_ascii(raw: bytes) -> str:
    return raw.rstrip(b" \x00").decode("ascii", "replace")


def printable(raw: bytes) -> str:
    return "".join(chr(b) if 32 <= b < 127 else "." for b in raw).rstrip()


def read_imd(path: Path) -> list[Track]:
    data = path.read_bytes()
    try:
        pos = data.index(0x1a) + 1
    except ValueError as exc:
        raise ImdFormatError("IMD header terminator 0x1a not found") from exc

    tracks: list[Track] = []
    while pos < len(data):
        if pos + 5 > len(data):
            raise ImdFormatError(f"truncated track header at 0x{pos:x}")

        mode, cylinder, head_flags, nsec, ssize_code = data[pos : pos + 5]
        pos += 5
        sector_size = 128 << ssize_code

        if pos + nsec > len(data):
            raise ImdFormatError(f"truncated sector map at track {len(tracks)}")
        sector_ids = list(data[pos : pos + nsec])
        pos += nsec

        cyl_map = None
        head_map = None
        if head_flags & 0x80:
            if pos + nsec > len(data):
                raise ImdFormatError(f"truncated cylinder map at track {len(tracks)}")
            cyl_map = list(data[pos : pos + nsec])
            pos += nsec
        if head_flags & 0x40:
            if pos + nsec > len(data):
                raise ImdFormatError(f"truncated head map at track {len(tracks)}")
            head_map = list(data[pos : pos + nsec])
            pos += nsec

        track_head = head_flags & 0x3f
        sectors: dict[int, Sector] = {}
        track_index = len(tracks)
        for entry_index, sector_id in enumerate(sector_ids):
            if pos >= len(data):
                raise ImdFormatError(f"truncated sector data at track {track_index}")
            imd_type = data[pos]
            pos += 1

            if imd_type == 0:
                sector_data = bytes(sector_size)
            elif imd_type in (1, 3, 5, 7):
                if pos + sector_size > len(data):
                    raise ImdFormatError(f"truncated sector payload at track {track_index}")
                sector_data = data[pos : pos + sector_size]
                pos += sector_size
            elif imd_type in (2, 4, 6, 8):
                if pos >= len(data):
                    raise ImdFormatError(f"truncated compressed sector at track {track_index}")
                sector_data = bytes([data[pos]]) * sector_size
                pos += 1
            else:
                raise ImdFormatError(f"bad IMD sector type {imd_type} at track {track_index}")

            cylinder_id = cyl_map[entry_index] if cyl_map else cylinder
            head_id = head_map[entry_index] if head_map else track_head
            sectors[sector_id] = Sector(
                track_index=track_index,
                mode=mode,
                cylinder=cylinder_id,
                head=head_id,
                sector_id=sector_id,
                size=sector_size,
                imd_type=imd_type,
                data=sector_data,
            )

        tracks.append(
            Track(
                index=track_index,
                mode=mode,
                cylinder=cylinder,
                head=track_head,
                sector_size=sector_size,
                sector_ids=sector_ids,
                sectors=sectors,
            )
        )

    return tracks


def iter_logical_sectors(tracks: Iterable[Track]) -> Iterable[Sector]:
    for track in tracks:
        for sector_id in sorted(track.sectors):
            yield track.sectors[sector_id]


def flat_image(tracks: list[Track]) -> bytes:
    return b"".join(sector.data for sector in iter_logical_sectors(tracks))


def sector_for_flat_offset(tracks: list[Track], offset: int) -> Sector | None:
    cursor = 0
    for sector in iter_logical_sectors(tracks):
        next_cursor = cursor + sector.size
        if cursor <= offset < next_cursor:
            return sector
        cursor = next_cursor
    return None


def parse_catalog(flat: bytes) -> DmlCatalog:
    vol1 = flat[VOL1_FLAT_OFFSET : VOL1_FLAT_OFFSET + 0x40]
    if len(vol1) < 0x40 or vol1[:4] != b"VOL1":
        raise DmlFormatError("VOL1 label not found at flat offset 0x300")
    if vol1[4:7] != b"DML":
        volume = decode_ascii(vol1[:16])
        raise DmlFormatError(f"not a diagnostic DML volume: {volume}")

    track = vol1[0x1c]
    sector = vol1[0x1d]
    count = vol1[0x1e]
    logical = track * DEFAULT_SECTORS_PER_TRACK * DEFAULT_HEADS + (sector - 1)
    flat_sector = logical - TRACK0_128B_AS_256B
    offset = flat_sector * DEFAULT_SECTOR_SIZE

    if offset < 0 or offset + count * DEFAULT_SECTOR_SIZE > len(flat):
        raise DmlFormatError(
            f"DML catalog extends beyond image: offset=0x{offset:x} sectors={count}"
        )

    special = decode_ascii(flat[offset + 2 : offset + 16])
    entries: list[DmlEntry] = []
    pos = offset + 16
    end = offset + count * DEFAULT_SECTOR_SIZE
    while pos + 20 <= end:
        record = flat[pos : pos + 20]
        index = record[5]
        if index == 0xff or record[6] == 0xff:
            break
        name = decode_ascii(record[6:20])
        if not name:
            break
        if not all(32 <= b < 127 for b in record[6 : 6 + len(name)]):
            break
        entries.append(
            DmlEntry(
                ext=record[0],
                loc=int.from_bytes(record[1:3], "little"),
                length=record[3],
                index=index,
                name=name,
                record_offset=pos,
            )
        )
        pos += 20

    return DmlCatalog(offset=offset, sectors=count, special=special, entries=entries)


def find_entry(catalog: DmlCatalog, selector: str) -> DmlEntry:
    selector = selector.strip().upper()
    if selector.isdigit():
        wanted = int(selector, 10)
        for entry in catalog.entries:
            if entry.index == wanted:
                return entry

    matches = [entry for entry in catalog.entries if entry.name.upper().startswith(selector)]
    if not matches:
        raise SystemExit(f"no DML catalog entry matching {selector!r}")
    if len(matches) > 1:
        choices = ", ".join(f"{entry.index:03d}:{entry.name}" for entry in matches[:20])
        raise SystemExit(f"ambiguous selector {selector!r}: {choices}")
    return matches[0]


def load_disk(path: Path) -> tuple[list[Track], bytes, DmlCatalog]:
    tracks = read_imd(path)
    flat = flat_image(tracks)
    catalog = parse_catalog(flat)
    return tracks, flat, catalog


def iter_labels(flat: bytes, limit: int = 0x2000) -> Iterable[tuple[int, bytes]]:
    pos = 0
    end = min(len(flat), limit)
    while pos + 0x40 <= end:
        chunk40 = flat[pos : pos + 0x40]
        prefix = chunk40[:4]
        if prefix in (b"SYS0", b"VOL1", b"ERMA", b"M   "):
            yield pos, chunk40
            pos += 0x40
            continue
        if prefix in (b"HDR1", b"DDR1") and pos + 0x80 <= end:
            yield pos, flat[pos : pos + 0x80]
            pos += 0x80
            continue
        pos += 0x40


def parse_decimal_chs(raw: bytes) -> tuple[int, int, int]:
    """Decode the five-character CCHSS address used in BCOS HDR1 labels."""
    try:
        text = raw.decode("ascii")
        if len(text) != 5 or not text.isdigit():
            raise ValueError
        return int(text[0:2]), int(text[2]), int(text[3:5])
    except (UnicodeDecodeError, ValueError) as exc:
        raise ImdFormatError(f"invalid HDR1 CHS address {raw!r}") from exc


def parse_bcos_extents(flat: bytes) -> list[BcosExtent]:
    extents: list[BcosExtent] = []
    seen: set[tuple[str, bytes, bytes]] = set()
    for offset, raw in iter_labels(flat):
        if raw[:4] != b"HDR1":
            continue
        name = decode_ascii(raw[5:22])
        record_raw = raw[22:27]
        start_raw = raw[28:33]
        end_raw = raw[34:39]
        if not name or not record_raw.isdigit():
            continue
        key = (name, start_raw, end_raw)
        if key in seen:
            continue
        seen.add(key)
        start_c, start_h, start_s = parse_decimal_chs(start_raw)
        end_c, end_h, end_s = parse_decimal_chs(end_raw)
        extents.append(
            BcosExtent(
                name=name,
                record_size=int(record_raw),
                start_cylinder=start_c,
                start_head=start_h,
                start_sector=start_s,
                end_cylinder=end_c,
                end_head=end_h,
                end_sector=end_s,
                label_offset=offset,
            )
        )
    return extents


def extract_bcos_extent(tracks: list[Track], extent: BcosExtent) -> bytes:
    sectors = {
        (sector.cylinder, sector.head, sector.sector_id): sector
        for sector in iter_logical_sectors(tracks)
    }
    start = (extent.start_cylinder, extent.start_head, extent.start_sector)
    end = (extent.end_cylinder, extent.end_head, extent.end_sector)
    output = bytearray()
    active = False
    for cylinder in range(100):
        for head in range(DEFAULT_HEADS):
            for sector_id in range(1, DEFAULT_SECTORS_PER_TRACK + 1):
                chs = (cylinder, head, sector_id)
                if chs == start:
                    active = True
                if active:
                    sector = sectors.get(chs)
                    if sector is None:
                        raise ImdFormatError(
                            f"missing sector C{cylinder}/H{head}/S{sector_id}"
                            f" while extracting {extent.name}"
                        )
                    output.extend(sector.data)
                if chs == end:
                    if not active:
                        raise ImdFormatError(
                            f"end precedes start for HDR1 extent {extent.name}"
                        )
                    return bytes(output)
    raise ImdFormatError(f"HDR1 extent {extent.name} ends outside the image")


def cmd_tracks(args: argparse.Namespace) -> None:
    tracks = read_imd(Path(args.image))
    print("trk  cyl head  sectors  bytes  mode      ids")
    for track in tracks:
        first = min(track.sector_ids) if track.sector_ids else 0
        last = max(track.sector_ids) if track.sector_ids else 0
        print(
            f"{track.index:3d}  {track.cylinder:3d}  {track.head:3d}"
            f"  {len(track.sector_ids):7d}  {track.sector_size:5d}"
            f"  {track.mode_name:<8}  {first}..{last}"
        )


def cmd_info(args: argparse.Namespace) -> None:
    image = Path(args.image)
    tracks = read_imd(image)
    flat = flat_image(tracks)
    sizes = sorted({track.sector_size for track in tracks})
    heads = sorted({track.head for track in tracks})
    cylinders = sorted({track.cylinder for track in tracks})
    vol1 = flat[VOL1_FLAT_OFFSET : VOL1_FLAT_OFFSET + 0x40]

    print(f"image: {image}")
    print(f"tracks: {len(tracks)}")
    print(f"cylinders: {min(cylinders)}..{max(cylinders)}")
    print(f"heads: {','.join(str(h) for h in heads)}")
    print(f"sector sizes: {','.join(str(s) for s in sizes)}")
    print(f"flat bytes: {len(flat)}")
    print(f"VOL1: {decode_ascii(vol1[:32])}")
    try:
        catalog = parse_catalog(flat)
    except DmlFormatError as exc:
        print(f"DML catalog: not available ({exc})")
        return

    cat_sector = sector_for_flat_offset(tracks, catalog.offset)
    print(f"catalog special: {catalog.special}")
    print(f"catalog offset: 0x{catalog.offset:05x}")
    print(f"catalog sectors: {catalog.sectors}")
    if cat_sector:
        print(f"catalog CHS: C{cat_sector.cylinder}/H{cat_sector.head}/S{cat_sector.sector_id}")
    print(f"catalog entries: {len(catalog.entries)}")


def cmd_labels(args: argparse.Namespace) -> None:
    tracks = read_imd(Path(args.image))
    flat = flat_image(tracks)
    print("offset  bytes  label")
    for offset, raw in iter_labels(flat):
        print(f"0x{offset:05x}  {len(raw):5d}  {printable(raw)}")


def cmd_bcos_list(args: argparse.Namespace) -> None:
    tracks = read_imd(Path(args.image))
    flat = flat_image(tracks)
    extents = parse_bcos_extents(flat)
    if not extents:
        raise SystemExit("no BCOS HDR1 extent labels found")
    print("name               record  start       end         sectors    bytes")
    for extent in extents:
        data = extract_bcos_extent(tracks, extent)
        print(
            f"{extent.name:<18} {extent.record_size:6d}  "
            f"{extent.start_text:<11} {extent.end_text:<11}"
            f" {len(data) // DEFAULT_SECTOR_SIZE:7d} {len(data):8d}"
        )


def cmd_bcos_extract(args: argparse.Namespace) -> None:
    tracks = read_imd(Path(args.image))
    flat = flat_image(tracks)
    selector = args.selector.strip().upper()
    matches = [e for e in parse_bcos_extents(flat) if e.name.upper().startswith(selector)]
    if not matches:
        raise SystemExit(f"no BCOS HDR1 extent matching {selector!r}")
    if len(matches) != 1:
        raise SystemExit(
            f"ambiguous selector {selector!r}: " + ", ".join(e.name for e in matches)
        )
    extent = matches[0]
    data = extract_bcos_extent(tracks, extent)
    output = Path(args.output)
    output.write_bytes(data)
    print(
        f"extracted {extent.name} {extent.start_text}..{extent.end_text}"
        f" bytes={len(data)} -> {output}"
    )


def cmd_list(args: argparse.Namespace) -> None:
    tracks, _flat, catalog = load_disk(Path(args.image))
    print(
        f"catalog offset=0x{catalog.offset:05x} sectors={catalog.sectors}"
        f" special={catalog.special}"
    )
    print("idx ext loc   len  log_sec flat_sec flat_off bytes  chs-start   name")
    for entry in catalog.entries:
        sector = sector_for_flat_offset(tracks, entry.flat_offset)
        chs = "-"
        if sector:
            chs = f"C{sector.cylinder}/H{sector.head}/S{sector.sector_id}"
        print(
            f"{entry.index:3d}  {entry.ext:02x}  {entry.loc:04x}"
            f"  {entry.length:02x}  {entry.logical_sector:7d}"
            f"  {entry.flat_sector:7d}  0x{entry.flat_offset:05x}"
            f"  {entry.byte_length:5d}  {chs:<10}  {entry.name}"
        )


def extract_entry(flat: bytes, entry: DmlEntry) -> bytes:
    end = entry.flat_offset + entry.byte_length
    if entry.flat_offset < 0 or end > len(flat):
        raise SystemExit(
            f"entry extends beyond image: {entry.name}"
            f" offset=0x{entry.flat_offset:x} bytes={entry.byte_length}"
        )
    return flat[entry.flat_offset:end]


def cmd_extract(args: argparse.Namespace) -> None:
    _tracks, flat, catalog = load_disk(Path(args.image))
    entry = find_entry(catalog, args.selector)
    data = extract_entry(flat, entry)
    output = Path(args.output)
    output.write_bytes(data)
    print(
        f"extracted {entry.index:03d}:{entry.name}"
        f" loc=0x{entry.loc:04x} offset=0x{entry.flat_offset:05x}"
        f" bytes={len(data)} -> {output}"
    )


def safe_name(entry: DmlEntry) -> str:
    allowed = []
    for ch in entry.name.strip():
        if ch.isalnum() or ch in "._-":
            allowed.append(ch)
        else:
            allowed.append("_")
    stem = "".join(allowed).strip("._")
    if not stem:
        stem = f"entry_{entry.index:03d}"
    return f"{entry.index:03d}_{stem}.bin"


def cmd_extract_all(args: argparse.Namespace) -> None:
    _tracks, flat, catalog = load_disk(Path(args.image))
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for entry in catalog.entries:
        data = extract_entry(flat, entry)
        out_path = out_dir / safe_name(entry)
        out_path.write_bytes(data)
        print(f"{entry.index:03d} {entry.name:<14} {len(data):5d} -> {out_path}")


def cmd_flatten(args: argparse.Namespace) -> None:
    tracks = read_imd(Path(args.image))
    data = flat_image(tracks)
    Path(args.output).write_bytes(data)
    print(f"wrote {args.output}: {len(data)} bytes")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspect/extract M30/M40 diagnostic DML and BCOS IMD images"
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_tracks = sub.add_parser("tracks", help="show IMD track/sector layout")
    p_tracks.add_argument("image")
    p_tracks.set_defaults(func=cmd_tracks)

    p_info = sub.add_parser("info", help="show DML volume/catalog summary")
    p_info.add_argument("image")
    p_info.set_defaults(func=cmd_info)

    p_labels = sub.add_parser("labels", help="show SYS0/VOL1/HDR1/DDR1-style labels")
    p_labels.add_argument("image")
    p_labels.set_defaults(func=cmd_labels)

    p_bcos_list = sub.add_parser("bcos-list", help="list BCOS HDR1 dataset extents")
    p_bcos_list.add_argument("image")
    p_bcos_list.set_defaults(func=cmd_bcos_list)

    p_bcos_extract = sub.add_parser("bcos-extract", help="extract one BCOS HDR1 extent")
    p_bcos_extract.add_argument("image")
    p_bcos_extract.add_argument("selector", help="unique dataset-name prefix")
    p_bcos_extract.add_argument("output")
    p_bcos_extract.set_defaults(func=cmd_bcos_extract)

    p_list = sub.add_parser("list", help="list DML catalog entries")
    p_list.add_argument("image")
    p_list.set_defaults(func=cmd_list)

    p_extract = sub.add_parser("extract", help="extract one DML catalog entry")
    p_extract.add_argument("image")
    p_extract.add_argument("selector", help="catalog index/code or unique name prefix")
    p_extract.add_argument("output")
    p_extract.set_defaults(func=cmd_extract)

    p_extract_all = sub.add_parser("extract-all", help="extract all DML catalog entries")
    p_extract_all.add_argument("image")
    p_extract_all.add_argument("output_dir")
    p_extract_all.set_defaults(func=cmd_extract_all)

    p_flatten = sub.add_parser("flatten", help="write concatenated logical-sector image")
    p_flatten.add_argument("image")
    p_flatten.add_argument("output")
    p_flatten.set_defaults(func=cmd_flatten)

    args = parser.parse_args()
    try:
        args.func(args)
    except ImdFormatError as exc:
        raise SystemExit(f"m40disk: {exc}") from exc


if __name__ == "__main__":
    main()
