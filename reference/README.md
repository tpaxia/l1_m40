# Reference material

Primary sources: ROM dumps, datasheets, manuals, disk images and photographs,
plus Markdown digests made from them. Only the ROMs, the NEC datasheet and
the digests are in git; the rest is kept locally (see `.gitignore`) and has
to be copied in from the original archives.

## In git

| Folder / file | Contents |
|---|---|
| `roms/m40rom-15-dec-81` | M40 system ROM dated 15 December 1981 |
| `roms/m40rom-4.1`, `roms/m40rom-6.0` | System ROMs REL 4.1 and REL 6.0; the sources in `re/disassembly/m40-rom/` rebuild them byte for byte |
| `roms/m40rom-6.0-hd65.bin` | REL 6.0 patched to boot from the GO363 hard disk; built by `tools/mkrom_hd65.py`, never a real ROM |
| `roms/9428ds-2067.bin` | The GO252 character generator, GI 9428DS-2067 (`re/evidence/go252-chargen-evidence.md`) |
| `roms/80491402.MCU` | The ANK keyboard's 8049 firmware (`keyboard/M40_8049_KEYBOARD.md`) |
| `roms/m40.zip`, `roms/m44.zip` | The MAME ROM sets for `m40` and `m44` |
| `roms/ROM L1 M40 BC` | A zip (no extension) holding the character generator and the two halves of ROM 6.0, the latter dumped with data bit 3 stuck at 1 |
| [datasheets/](datasheets/) | NEC uPD7261A/B hard-disk controller datasheet. The Zilog Z8000 CPU Technical Manual (January 1983) is kept here locally; at 20 MB it is not in git |
| [datasheet-digests/](datasheet-digests/README.md) | Markdown digests: Z8010 MMU, uPD765 floppy controller |
| [manual-digests/](manual-digests/) | Markdown extracts of the Olivetti manuals: BCOS II manual, ROM self-test notes, M34/M44 service manual chapter 1, MOS Programmer Guide chapter 8 |
| [images/](images/README.md) | Every floppy image of the two `Disk Images` folders as IMD, including the BCOS disks converted from flux; local only, the README is tracked |

## Local only

| Folder | Contents |
|---|---|
| `Disk Images/` | The Olivetti BCOS II 3.3 and 5.0 distribution set and DEE 2.1, as SCP flux captures and some IMDs |
| `Disk Images (Stefano Marinelli + others)/` | DCOS 8.4 diagnostics, ESE and MDOS, MOS (starter and DPC volumes), the OSLEM and data-set disks of the hard-disk restore procedure, the Gardini utility disk |
| `Manuals (Stefano Marinelli + Olivrea)/` | Scanned Olivetti manuals: BCOS II, DCOS, the floppy board, the M34/M44 service manual, the functional checks manual, and others |
| `Manuals/PARTE 1/` | Indexes of the schematic collections (M30BC; M34/M44/M60 video and keyboard boards; M34/M44 memories), the 15-inch video schematic, the GO252/GO151 spare-parts catalogue, ESE and DOS-environment documentation |
| `ArchiviOlivetti/` | Olivetti board descriptions for the M30/M40 hard-disk (HDC) and video/keyboard (KDC) boards |
| `Diablo/` | Diablo Model 44 disk drive maintenance manual |
| `Pictures (M40 + spares)/` | Photographs of an M40 and spare boards; `BOARD_INDEX.md` identifies the boards and chips in each |
| `zips/` | The original downloaded archives the material above was taken from |
