#!/usr/bin/env python3
"""Generate a diagnostic-test inventory from the DCOS 8.4 DML catalogs.

The monitor menu is reachable in MAME, and disk B has been verified reaching the
runtime MAP catalogue screen.  The generated MAP files remain catalogue-derived
so every disk gets a complete inventory even when we have not manually paged
through the monitor's on-screen MAP output.
"""
from __future__ import annotations

import json
import sys
from dataclasses import asdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import dml_catalog  # noqa: E402
import imd  # noqa: E402


DIAG_DIR = (
    ROOT
    / "reference"
    / "Disk Images (Stefano Marinelli + others)"
    / "diagnostici l1 dcos 8.4"
)
OUT_DIR = ROOT / "tools" / "diagnostic_tests"
RUNS_DIRS = (ROOT / "runs", ROOT / "runs-archive")
LETTERS = "ABCDEFGHR"

SUBSYSTEMS = {
    "A": "central unit / RAM / UC",
    "B": "KDC video-keyboard / MUX",
    "C": "line controllers",
    "D": "FDU / MFDU / STC / MTU",
    "E": "HDU 18/14 MB",
    "F": "HDU 60/120 MB Fujitsu SMD",
    "G": "HDU WREN/Micropolis/ST506",
    "H": "HDU 140 MB ESDI",
    "R": "reduced 3930 set",
}

KNOWN_NOTES = {
    "UCY805": "UCO.71 multiprocessor UC test; includes bus arbiter and master/slave coverage.",
    "KEYTE1": "Keyboard test; interrupt/vector, alpha/numeric/KANA/LED/buzzer paths.",
    "RAMVID": "Video RAM test for the GO252/KDC framebuffer.",
    "CRTAN5": "Alphanumeric CRT controller test.",
    "CRTGR2": "Black-and-white graphics CRT test.",
    "GRAPH3": "Video graphics colour / 7220-family graphics test.",
    "6030T6": "XU/XG6030 FDU running test; controller communication, timer, interrupt, DMA, format/read/write.",
    "FDUMA2": "FDU alignment/eccentricity test.",
    "7032E5": "FDU/MFDU error-rate test.",
    "4301T4": "MFDU running-test variant.",
    "4305T6": "MFDU running-test variant.",
    "HDC5": "GO363/HDC5 ST506 hard-disk controller diagnostic family.",
    "S24": "24-sector hard-disk media/seek/format/verify support test.",
    "ESDI": "ESDI hard-disk diagnostic family.",
}


def flat_image_from_imd(path: Path) -> bytes:
    buf = bytearray()
    for _mode, _cyl, _head, _nsec, _ssz, _smap, secs in imd.read_imd(str(path)):
        for sector in sorted(secs):
            buf += secs[sector]
    return bytes(buf)


def note_for(name: str) -> str:
    upper = name.upper()
    for prefix, note in KNOWN_NOTES.items():
        if upper.startswith(prefix):
            return note
    return ""


def display_name(name: str) -> str:
    return name[:6]


def release(name: str) -> str:
    return name[6:8] if len(name) >= 8 else ""


def date_code(name: str) -> str:
    return name[8:14] if len(name) >= 14 else ""


def latest_run(letter: str) -> Path | None:
    matches = sorted(m for d in RUNS_DIRS for m in d.glob(f"*-diag-tests-{letter}"))
    return matches[-1] if matches else None


def latest_menu_run(letter: str) -> Path | None:
    patterns = [
        f"*-enter-menu-{letter}",
        f"*-enter-code52-{letter}",
    ]
    matches: list[Path] = []
    for pattern in patterns:
        matches.extend(m for d in RUNS_DIRS for m in d.glob(pattern))
    return sorted(matches)[-1] if matches else None


def screen_excerpt(screen_path: Path) -> list[str]:
    if not screen_path.exists():
        return []
    lines = []
    for line in screen_path.read_text(errors="replace").splitlines():
        if line.strip() and not line.startswith(("source:", "vram_", "crtc_", "geometry:", "start:")):
            lines.append(line.rstrip())
    return lines


def load_catalog(letter: str) -> dict[str, object]:
    disk = DIAG_DIR / f"{letter}.IMD"
    image = flat_image_from_imd(disk)
    offset, count, special, entries = dml_catalog.read_catalog(image)
    serialized = []
    for entry in entries:
        row = asdict(entry)
        row["logical_sector"] = entry.logical_sector
        row["flat_sector"] = entry.flat_sector
        row["flat_offset"] = entry.flat_offset
        row["byte_length"] = entry.byte_length
        row["note"] = note_for(entry.name)
        serialized.append(row)
    return {
        "letter": letter,
        "disk": str(disk.relative_to(ROOT)),
        "subsystem": SUBSYSTEMS[letter],
        "catalog_offset": offset,
        "catalog_sectors": count,
        "special": special,
        "entries": serialized,
    }


def write_disk_markdown(data: dict[str, object]) -> None:
    letter = str(data["letter"])
    run = latest_run(letter)
    menu_run = latest_menu_run(letter)
    screen = screen_excerpt(run / "screen.txt") if run else []
    menu_screen = screen_excerpt(menu_run / "screen.txt") if menu_run else []
    if menu_run and menu_screen:
        menu_path = OUT_DIR / f"monitor_menu_{letter}.txt"
        menu_path.write_text(
            "\n".join(
                [
                    f"disk: {letter}",
                    f"run: {menu_run.relative_to(ROOT)}",
                    "",
                    *menu_screen,
                    "",
                ]
            )
        )
    path = OUT_DIR / f"disk_{letter}.md"

    lines = [
        f"# Diagnostic Disk {letter}",
        "",
        f"- Subsystem: {data['subsystem']}",
        f"- Image: `{data['disk']}`",
        f"- DML special/catalog loader: `{data['special']}`",
        f"- Catalog: offset `0x{data['catalog_offset']:05x}`, sectors `{data['catalog_sectors']}`",
    ]
    if run:
        lines.append(f"- MAME boot run: `{run.relative_to(ROOT)}`")
    else:
        lines.append("- MAME boot run: not found")
    if menu_run:
        lines.append(f"- Post-Enter monitor run: `{menu_run.relative_to(ROOT)}`")
        lines.append(f"- Post-Enter screen dump: [monitor_menu_{letter}.txt](monitor_menu_{letter}.txt)")
    else:
        lines.append("- Post-Enter monitor run: not found")
    lines.append(f"- Generated MAP inventory: [monitor_map_{letter}.txt](monitor_map_{letter}.txt)")
    lines += [
        "",
        "## Captured Boot Screen",
        "",
    ]
    if screen:
        lines += ["```text", *screen, "```"]
    else:
        lines.append("_No screen capture found._")

    lines += [
        "",
        "## Captured Monitor Menu",
        "",
    ]
    if menu_screen:
        lines += ["```text", *menu_screen, "```"]
    else:
        lines.append("_No post-Enter monitor capture found._")

    lines += [
        "",
        "## Generated MAP Inventory",
        "",
        f"See [monitor_map_{letter}.txt](monitor_map_{letter}.txt). This is generated",
        "from the DML catalog records, not from manually paging the monitor UI.",
        "The runtime MAP screen shows TR/ST and its own LENGHT unit; the generated",
        "file records DML loc and sector/byte length instead.",
        "",
        "",
        "## Available Catalog Entries",
        "",
        "These are the DML catalog payloads present on the disk. The emulator can",
        "inject Enter, select monitor options, and disk B has been verified reaching",
        "the runtime MAP catalogue screen. The table is the machine-derived full",
        "inventory of available tests/support overlays.",
        "",
        "| Idx | Name | Ext | Loc | Len sectors | Flat offset | Bytes | Notes |",
        "|---:|---|---:|---:|---:|---:|---:|---|",
    ]
    for entry in data["entries"]:
        lines.append(
            "| {index} | `{name}` | `{ext:02x}` | `0x{loc:04x}` | {length} | "
            "`0x{flat_offset:05x}` | {byte_length} | {note} |".format(**entry)
        )
    lines.append("")
    path.write_text("\n".join(lines))


def write_map_inventory(data: dict[str, object]) -> None:
    letter = str(data["letter"])
    path = OUT_DIR / f"monitor_map_{letter}.txt"
    special = str(data["special"])
    lines = [
        f"disk: {letter}",
        "source: generated from DML catalog records",
        "note: runtime MAP uses TR/ST and its own LENGHT unit; this file uses DML LOC and sector/byte length",
        "",
        "DCOS *L1* LIBRARY",
        "CODE  FILENAME  REL  LOC     LEN(SECT)  BYTES  DATE    NOTES",
        "001   {name:<8} {rel:<4} {loc:<7} {length:>9}  {bytes:>5}  {date:<6}  special/catalog loader".format(
            name=display_name(special),
            rel=release(special),
            loc="-",
            length="-",
            bytes="-",
            date=date_code(special),
        ),
    ]
    for entry in data["entries"]:
        name = str(entry["name"])
        lines.append(
            "{index:03d}   {display:<8} {rel:<4} 0x{loc:04x}  {length:>9}  "
            "{byte_length:>5}  {date:<6}  {note}".format(
                index=entry["index"],
                display=display_name(name),
                rel=release(name),
                loc=entry["loc"],
                length=entry["length"],
                byte_length=entry["byte_length"],
                date=date_code(name),
                note=entry["note"],
            ).rstrip()
        )
    lines += [
        "",
        "Monitor workflow from the collaudi manual and live menu:",
        "  1 + ENTER: LOAD, then type the MAP code as three digits and ENTER.",
        "  2 + ENTER: MAP, displays the monitor's runtime catalogue screen.",
        "  4 + ENTER: GO, runs the loaded program.",
        "  SKIP: documented back-page/back-to-menu key; the MAME key binding still needs confirmation.",
        "",
    ]
    path.write_text("\n".join(lines))


def write_readme(catalogs: list[dict[str, object]]) -> None:
    lines = [
        "# M40 Diagnostic Test Inventory",
        "",
        "Generated from the DCOS 8.4 diagnostic disk DML catalogs, with one",
        "MAME boot-screen capture per disk. The emulator reaches the common",
        "`SYSTEM ENVIRONMENT` / `HIT \"ENTER\" FOR DIAGNOSTIC MONITOR` screen on all",
        "nine disks, and the GO252/KDC keyboard path can now inject Enter to reach",
        "the Diagnostic Monitor menu.",
        "",
        "## Disks",
        "",
        "| Disk | Subsystem | Catalog special | Entries | Inventory | Monitor menu | MAP inventory |",
        "|---|---|---|---:|---|---|---|",
    ]
    for data in catalogs:
        letter = data["letter"]
        lines.append(
            f"| {letter} | {data['subsystem']} | `{data['special']}` | "
            f"{len(data['entries'])} | [disk_{letter}.md](disk_{letter}.md) | "
            f"[monitor_menu_{letter}.txt](monitor_menu_{letter}.txt) | "
            f"[monitor_map_{letter}.txt](monitor_map_{letter}.txt) |"
        )
    lines += [
        "",
        "## Collection Status",
        "",
        "- MAME was run for disks A, B, C, D, E, F, G, H, and R with `--vram-trace`.",
        "- Each run reached console sequence `01 02 44 55 21 FF` and displayed the common prompt.",
        "- Enter is delivered as KDC byte `0x52`, which the monitor accepts as the prompt key.",
        "- Verified post-Enter monitor-menu dumps are present as `monitor_menu_A.txt` through `monitor_menu_H.txt`, plus `monitor_menu_R.txt`.",
        "- Disk B option `2` reaches the runtime `DCOS *L1* LIBRARY` MAP page; the first page confirms the DML-derived program codes/names/releases/dates through entries 001-021.",
        "- The monitor/help/manual path is: `1` = LOAD by MAP code, `2` = MAP, `4` = GO; SKIP is the documented back-page/back-to-menu key.",
        "- Generated `monitor_map_*.txt` files enumerate every known program code from the DML catalog, including entries beyond the first visible MAP page; their LOC/LEN fields are DML fields, not a byte-for-byte runtime MAP transcript.",
        "",
    ]
    (OUT_DIR / "README.md").write_text("\n".join(lines))


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    catalogs = [load_catalog(letter) for letter in LETTERS]
    for data in catalogs:
        write_map_inventory(data)
        write_disk_markdown(data)
    write_readme(catalogs)
    (OUT_DIR / "catalogs.json").write_text(json.dumps(catalogs, indent=2, sort_keys=True) + "\n")
    print(f"wrote {OUT_DIR.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
