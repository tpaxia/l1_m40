# tools/

Command-line tools for the M40 reverse engineering: ROM disassembly, the
patched hard-disk boot ROM, floppy-image inspection, and the diagnostic-disk
harness. Run them from the project root.

Outside the project they need the patched z8k-coff binutils
(`~/Projects/binutils-2.46.0`) for the ROM builds, the
`~/Projects/M20/PCOS/z8kdis` library for `z8kdisrom`, and MAME for the harness.
The diagnostic and OS disk images under `reference/` are kept out of git.
The harness writes its run folders to `runs/` (git-ignored).

All were checked against the current tree on 2 October 2026: the ROM
pipelines rebuild byte-identical output, and the disk tools were run on the
real images.

## ROM disassembly

| Tool | Use |
|---|---|
| `mkasm.py ROM OUT.s` | Generate a round-trippable Z8001 disassembly of an M40 ROM. The `.s` reassembles (patched z8k-coff binutils, `~/Projects/binutils-2.46.0`) to the original bytes |
| `annotate_baa.py`, `annotate_tests.py`, `annotate_slotscan.py`, `annotate_ramsize.py`, `annotate_memtest.py`, `annotate_ipl.py`, `annotate_fdu.py` | Insert the comments for one region each of `re/disassembly/m40-rom/m40rom-4.1.s` (console/video, self-tests, slot scans, RAM sizing, memory test, IPL, floppy boot). Annotations live in these scripts, not in hand edits to the `.s` |
| `rebuild.sh` | Regenerate `re/disassembly/m40-rom/m40rom-4.1.s` and `re/disassembly/m40-rom/m40rom-6.0.s` from `reference/roms/`, apply every annotation pass, then `make verify` in `re/` (expects `IDENTICAL` for both) |
| `annotate_boot.py` | Annotate `re/disassembly/dcos-bootloader/boot.s`, the first-stage loader on the DCOS diagnostic disks; run by `make regen` in that folder |
| `z8kdisrom ROM [start] [end]` | Linear Z8001 disassembly of a ROM range, for quick looks. Build: `c++ -std=c++17 -O2 -I ~/Projects/M20/PCOS/z8kdis tools/z8kdisrom.cpp -L ~/Projects/M20/PCOS/z8kdis -lz8kdis -o tools/z8kdisrom` |

## Patched GO363 boot ROM

`mkrom_hd65.py` builds the experimental REL 6.0 ROM that can boot from the
GO363 hard disk (`reference/roms/m40rom-6.0-hd65.bin`; background in
`re/os/oslem/OSLEM_STATUS.md`, "Issue 2"). Build, from `re/`:

```sh
python3 ../tools/mkrom_hd65.py m40rom-6.0.s m40rom-6.0-hd65.s
z8k-coff-as -z8001 m40rom-6.0-hd65.s -o m40rom-6.0-hd65.o
z8k-coff-ld -mz8001 -Ttext 0 m40rom-6.0-hd65.o -o m40rom-6.0-hd65.coff
z8k-coff-objcopy -S -O binary m40rom-6.0-hd65.coff m40rom-6.0-hd65.bin
python3 ../tools/mkrom_hd65.py --checksum m40rom-6.0-hd65.bin
```

The last step recomputes the ROM checksum that the self-test checks.

## Floppy images

| Tool | Use |
|---|---|
| `l1lib.py` | Main tool for OSLEM and BCOS II floppies: `info`, `boot`, `labels`, `modules`, `dir`, `containers`, `config`, `extract`, `find`, `versions`. Read `L1_DISK_FORMATS.md` first |
| `L1_DISK_FORMATS.md` | The L1 floppy and hard-disk formats as far as they are known: labels, module headers, library directories, configuration records |
| `l1disk.py` | Library used by `l1lib.py` and the hard-disk build scripts: sector access by the L1 linear index |
| `imd.py IMG tracks` / `imd.py IMG extract OUT [ntracks]` | Minimal ImageDisk reader: list the track table, or write the sectors as a flat image |
| `m40disk.py` | DCOS diagnostic disks and BCOS datasets: `tracks`, `info`, `labels`, `list`, `extract`, `extract-all`, `flatten`, `bcos-list`, `bcos-extract` |
| `dml_catalog.py list FLAT` / `extract …` | The diagnostic disk's program catalogue, from a flat image made by `imd.py extract` (used by `collect_tests.py`) |
| `make_m40_blank_imd.py REFERENCE OUT` | A sector-formatted blank 8-inch disk with the geometry of `REFERENCE`, for BCOS system generation |
| `imd_trim_empty_tail.py SRC DST LIMIT` | Copy an IMD, dropping zero-filled cylinders at or beyond `LIMIT` (used for the MOS starter, whose image has an extra cylinder 77) |

## Diagnostic-disk harness

`m40_harness.py` runs the DCOS diagnostic disks in MAME and collects the
results. Subcommands: `run`, `run-test` (load a catalogued program and
optionally GO), `tests`, `disks`, `dump`, `parse`. Used by
`scripts/test-m40-uc.sh` and `scripts/test-m40-fdu.sh`; details in
`re/mame/MAME_diagnostic_trace_harness.md`.

The `--vram-trace` and `--fdu-trace` options and the `screen` and `fdu`
subcommands rely on trace output that the MAME driver no longer produces
(removed in the September instrumentation cleanup). Use screenshots instead.

`diagnostic_tests/collect_tests.py` regenerates the per-disk program
inventories in `diagnostic_tests/` (`catalogs.json`, `monitor_map_*.txt`,
`disk_*.md`). The `disk_*.md` pages embed screen captures from runs in
the run archive `runs-archive/` (July 2026); regenerating without them drops the
captures but keeps the catalogue data.
