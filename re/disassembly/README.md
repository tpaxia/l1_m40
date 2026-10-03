# Disassembly

| Folder | Contents | Rebuild |
|---|---|---|
| [m40-rom/](m40-rom/README.md) | Z8001 sources of the ROMs REL 4.1 and REL 6.0, and of the patched REL 6.0 that boots from the GO363 (`m40rom-6.0-hd65.s`). Each `.s` reassembles to the original bytes; `.asm` are plain listings, `.reset` the reset-path extracts | `tools/rebuild.sh`, then `make verify` here |
| [dcos-bootloader/](dcos-bootloader/README.md) | The 512-byte first-stage loader on track 0 of every DCOS 8.4 diagnostic disk | `make regen` |
| `diagnostics/` | Listings of diagnostic programs, cut from the flat disk images at the catalogue offsets in the file names (`disk<letter>_<program>_<start>_<end>.dis`) | none: read-only listings |

`diagnostics/` holds:

- `go252/`: disk B video and keyboard tests (CRTAN5, KEYTE1, RAMVID, …);
  analysed in [`../hardware/go252/`](../hardware/go252/).
- `go363/`: disk G hard-disk tests (HDC505, HDC5F5, HDC5X3, the Standard 24
  programs, …); analysed in [`../hardware/go363/`](../hardware/go363/).
- `diskD_*.dis`: disk D floppy tests (6030T6, FDUMA2, 4305T6); analysed in
  [`../hardware/go280/`](../hardware/go280/).
- `line/`: the line-controller programs 002–006, extracted for the MDOS
  line-driver work ([`../os/mdos/`](../os/mdos/MDOS30_E0xx_line_driver.md)).
- `runtime/`: code dumped from memory after the DCOS monitor loaded it
  (`seg<NN>_…`: the segment it ran in), for programs whose on-disk form is
  overlaid or relocated.

The annotations of the ROM sources live in `tools/annotate_*.py`, not in
hand edits to the `.s` files, so a rebuild keeps them.
