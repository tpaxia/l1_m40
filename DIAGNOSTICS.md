# L1 Diagnostics (DCOS 8.4) — disk set, boot flow & ROM handoff

Reverse-engineering notes on the Olivetti **L1 field-diagnostic disk set**, release
**DCOS 8.4** (8" DS/DD floppies). These boot on the M30/M40 via the resident ROM and
are the richest source of documented behaviour for the peripheral *governi* — each
disk exercises a subsystem register-by-register.

Confidence tags as in [`HARDWARE.md`](HARDWARE.md): **[ROM]** from the boot ROM,
**[DISK]** from the diagnostic images, **[MAN]** from a service manual, **[INF]**
inferred.

---

## 1. The disk set

Nine bootable 8" diskettes, one per subsystem. All are **DCOS 8.4.2** except `R`
(8.4.1). Every disk **self-boots the same Diagnostic Monitor**, then carries a
subsystem-specific test payload. **[DISK]**

| Disk | Subsystem | Notable tests |
|------|-----------|---------------|
| **A** | central unit / RAM | **BUS ARBITER TEST**, RESET TEST, S8000 TCM, BURST TRANSFER, MASTER/SLAVE (multiprocessor), ADAPTER, PIN-PAD |
| **B** | KDC (video/keyboard), MUX | keyboard (alpha/num/KANA/LED/buzzer), **VIDEO GRAPHICS COLOUR** |
| **C** | LINE | Z80-SIO / Z-SCC / DART, LION 9.6 + LCU V24, STARLAN, LCC loopback |
| **D** | **FDU / MFDU / STC / MTU** | CHECK COMMAND & STATUS PORT, R/W VECTOR INTERRUPTS, **R/W DATA IN MAIN MEMORY (DMA)**, **MEM-TO-MEM DMA CONTROLLER**, NMI-generation, tape |
| **E** | HDU 18/14 MB | GIPO routines (`GID_*`), floppy I/O (`mfior_*`), XU5006, ERMAP |
| **F** | HDU 60/120 MB (Fujitsu SMD) | controller/slot, **SEGM.ADDRESS 16/23 OF DMA RAM**, seek/error-rate |
| **G** | HDU WREN/Micropolis/ST506 | **PROGRAM 'NEC' & R/W FIFO** (µPD7261), **8253 TIMER & DMA TRANSFER LOGIC**, **DMA & RAM & ADDRESS COUNTER**, ECC |
| **H** | HDU 140 MB (ESDI) | subsystem/seek/format/verify |
| **R** | "Reduziert 3930" (8.4.1) | reduced A/B subset (bus arbiter, master/slave, keyboard) |

---

## 2. Boot mechanics

- **Format:** track 0 = **26 sectors × 128 bytes** (8" single density), sectors 1–26.
  This matches the ROM's format-B read template (`EOT=0x1a`, DMA count `0x0d00`). **[ROM]+[DISK]**
- **First-stage image:** the ROM reads that **one track (3328 bytes) into segment 60**,
  validates the magic **`"SYS0"`**, and jumps to the entry point in the block header.
  The header is identical on every disk:

  ```
  offset 0:  "SYS0"                      magic (0x53595330)
  offset 4:  <<25>>0x000c                entry point (segmented long)
  offset 8:  0x00000001                  flags/length
  offset C:  first-stage bootloader code
  ```

- **Two-stage boot:** the 3328-byte `SYS0` block is a **first-stage bootloader**; it
  then loads the rest of the disk (the Monitor + tests) itself. So the ROM IPL reads
  **exactly one track**; the bootloader does the bulk load. **[ROM]+[DISK]**

### 2.1 The three stages (traced)

The first-stage bootloader — the 512-byte code+tables prefix of the `SYS0` block —
has been fully disassembled (round-trippable to a byte-identical image) and is
**identical on all nine disks**. The flow:

```
Stage 1  ROM IPL          Read track 0 (26x128B) into the <<60>> DMA buffer, check
                          "SYS0", then alias MMU descriptor 25 onto that same buffer
                          and jp to the header entry <<25>>0x000c. The seg-1 config
                          table is handed off unchanged.

Stage 2  SYS0 bootloader  Runs at <<25>>; ~200 bytes of code + a few tables:
  0x0c  r2 = boot marker (<<1>>0x0308); rr2 = &descriptor (0x0114); call the loader
  0x22  loader: rl7 = config-table[bootslot].TYPE (<<1>>0x0230) — the ROM's own
        enumeration, no bus re-scan. Look TYPE up in the device-type table (0xdc),
        fetch a ROM (segment-0) read routine via the pointer table (0xe6), call it.
        The loop is retry-on-error, NOT a descriptor list: rr2 never advances, so
        exactly ONE load command is issued and retried (via ROM recovery routine
        0x0d10) until the FDC status word is clean.
  0xaa  LBA -> CHS (divide the start block by sectors/track, then heads).
  ->    jp <<25>>0x0234   (Monitor entry, which lies inside the loaded image)

Stage 3  Diagnostic Monitor   SYSTEM ENVIRONMENT screen, HIT ENTER, test menu
```

**The load command (exact second-stage size).** The 9-byte descriptor at
`<<25>>0x0114` is `99 00 02 00 | 0e 00 | 01 00 01`: destination **`<<25>>0x0200`**,
length **`0x0e00` (3584 bytes = 14 sectors × 256 B)**, start params `01 00 01`
(C/H/S, the first MFM data track). The ROM loader copies it to `<<1>>0x0366` and
reads the run. So the **entire second stage is a single 3584-byte load** to
`<<25>>0x0200`; the Monitor entry `<<25>>0x0234` sits inside it. That core is small
because the Monitor pulls each subsystem test in as an overlay afterwards. **[DISK]+[ROM]**

**The loader lives in the ROM.** The bootloader carries no disk driver; it reaches
one by a double indirection — `TYPE -> device-type table (0xdc) -> reversed index
-> pointer table (0xe6) -> a segment-0 offset -> ROM[offset] = routine entry`. (The
index is reversed because the `cpirb` search counter counts down.) In ROM 4.1 the
FDU/MFDU (`E0`/`E1`) routine is `<<0>>0x1642`, STC (`E6`/`E7`) is `0x1e2c`, MTU
(`62`) is `0x01c0`; the HDU types (`E4`/`66`/`60`/`61`/`65`) are unsupported by the
8 KB 4.1 and would resolve only in the 16 KB 6.0. So the bootloader boots the Monitor
off whatever device the ROM booted from, by **reusing that device's ROM read
routine**. **[DISK]+[ROM]**

---

## 3. The ROM → bootloader handoff (no bus rescan)

The bootloader **consumes the ROM's enumeration; it does not re-scan the bus.** Its
first action is to read the ROM's config table:

```
ldb rh4,<<1>>0x0302        ; the IPL slot the ROM booted from
srl/and -> slot*4          ; config-table index
ldb rl7,<<1>>0x0230(r4)    ; read config-table[slot] TYPE   <- the ROM's table
cpb rl7,#0x60/61/65/66 …   ; dispatch by device type -> device loader
```

Everything is passed through the **segment-1 system area** the ROM populated: **[ROM]+[DISK]**

| Address | Contents |
|---------|----------|
| `<<1>>0x0220`–`0x022a` | RAM start / end / size |
| `<<1>>0x0230` + slot*4 | **config table** — per-slot `type` + `diag-response` (16 slots; the "SYSTEM ENVIRONMENT" data) |
| `<<1>>0x0302` | IPL slot (device select) |
| `<<1>>0x0306/030c/030e` | IPL device parameters |
| `<<1>>0x0308` | boot-success marker (`0x5555`) |

Segment 1 stays mapped across the handoff (the ROM sets SP to `<<1>>0x01c0` and keeps
descriptor 1), so this area survives into the loaded software. The Monitor's full
16-slot SYSTEM ENVIRONMENT screen uses the same table format — almost certainly read
from `<<1>>0x0230` rather than re-enumerated. **[INF]**

---

## 4. Operating the diagnostics

Per the *Manuale dei Collaudi* (ch. 2): set the ISL/boot channel to FDU, boot the disk
→ `SELECTOR RUNNING` / `*** KEYBOARD ENABLE ***` → type `5 0` within 10 s → the resident
diagnostic loads → **SYSTEM ENVIRONMENT** screen → **`HIT "ENTER"` for the Diagnostic
Monitor** → the test menu (item 5 = new test list; 11–20 = stop-on-error / loop / trace
options; 14 = CRT controller select) → select the subsystem test. The Monitor is common
to all disks; the disk chosen must match the board under test. **[MAN]**

---

## 5. Value for the RE / MAME effort

These test programs drive the *governi* far more thoroughly than the ROM's minimal boot
driver, so they are the best reference for the register-level behaviour still open in
[`HARDWARE.md`](HARDWARE.md):

- **Disk D** — the FDU/MFDU governo tests (`COMMAND & STATUS PORT`, `MEM-TO-MEM DMA`,
  `R/W DATA IN MAIN MEMORY`) pin down the AM9517 + µPD765 protocol for **M2**.
- **Disk A** — the **BUS ARBITER TEST** documents the UC `0xFF80..0xFF8F`
  DMA/interrupt-arbitration logic.
- **Disk G** — the ST506 HDU governo (`PROGRAM 'NEC'`=µPD7261, `8253 TIMER & DMA`,
  `ADDRESS COUNTER`) for **M4**.

The images share the ROM's toolchain (segmented Z8001), so the same round-trip
disassembly pipeline applies; specific tests are disassembled on demand.
