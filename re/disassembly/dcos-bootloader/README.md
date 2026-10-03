# re/disassembly/dcos-bootloader/ — SYS0 first-stage bootloader (working notes, gitignored)

Round-trippable disassembly of the **first-stage bootloader** that the ROM IPL
loads from track 0 of an L1 DCOS 8.4 diagnostic disk. The 512-byte code+tables
prefix is byte-identical on all nine disks (A/B/C/D/E/F/G/H/R), so one artifact
covers them all. Public findings live in `doc/DIAGNOSTICS.md` §2.1.

## Files
- `boot.bin`  — the 512-byte bootloader (first 512 B of disk D track 0).
- `boot.s`    — annotated disassembly; reassembles byte-identical to `boot.bin`.
- `Makefile`  — `make verify` (rebuild + compare), `make regen` (mkasm + annotate).

## Reproduce
```
python3 ../../../tools/imd.py "<path>/D.IMD" extract /tmp/t0.bin 1   # track 0 (3328 B)
head -c 512 /tmp/t0.bin > boot.bin                              # bootloader prefix
make regen                                                      # disassemble+annotate
make verify                                                     # boot: IDENTICAL
```

## What the bootloader does (summary)
- Runs at `<<25>>` (ROM reads track 0 into the `<<60>>` buffer, then aliases MMU
  descriptor 25 onto it and jumps to the header entry `<<25>>0x000c`).
- Issues **one** load command — the 9-byte descriptor at `0x0114`
  (`99 00 02 00 | 0e 00 | 01 00 01`): read `0x0e00` bytes (14 × 256 B sectors) to
  `<<25>>0x0200`, retry-on-error, then `jp <<25>>0x0234` (Monitor entry).
- The actual sector read is delegated to a **ROM (segment-0) routine**, chosen by
  the booted device TYPE via `device-type table (0xdc) -> reversed index ->
  pointer table (0xe6) -> ROM vector`. FDU/MFDU (E0/E1) → ROM `<<0>>0x1642`.

## Tables in boot.s
- `0x00dc` device-type table: `E4 E0 66 E6 E7 E1 60 61 62 65`.
- `0x00e6` loader-pointer table (10 words, reversed index → segment-0 offsets).
- `0x0110` Monitor entry longword `<<25>>0x0234`.
- `0x0114` the 9-byte load descriptor (above); bytes past `0x011c` are a table
  used by the loaded Monitor, not by this first stage.
