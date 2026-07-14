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

```
Stage 1  ROM IPL          read track 0 (26 sec) -> seg 60, check "SYS0",
                          jp <<25>>0x000c        (config table handed off in seg 1)

Stage 2  SYS0 bootloader  ~260 bytes of code+tables, runs at <<25>>:
  0x0c   read <<1>>0x0308 marker -> calr 0x22 (load Monitor) -> jp <<25>>0x0234
  0x22   ldb rh4,<<1>>0x0302        ; the boot slot (from the ROM)
         ldb rl7,<<1>>0x0230(slot)  ; read config-table TYPE  <- reuses ROM's scan
         dispatch: device-type table @0xdc -> loader-pointer table @0xe6
  0xaa   LBA -> CHS conversion (mul/div by 26 sec/track, 2 heads); read the
         Monitor as a run of logical sectors into <<25>>

Stage 3  Diagnostic Monitor   SYSTEM ENVIRONMENT screen, HIT ENTER, test menu
```

The bootloader's **device-type table** (`0xdc`, 10 entries) lets it load the Monitor
off whatever device the ROM booted from: `E4`(HDU) `E0`(MFDU) `66` `E6`(STC) `E7`
`E1`(FDU) `60`(HDU-14 adapter) `61`(HDU-SMD) `62`(MTU) `65`(ST506) — each with a
loader routine (`0xe6`). It reads sequential logical blocks, converting each **LBA to
cylinder/head/sector** for the FDC. So the second stage can be an arbitrary number of
sectors; the *first* stage (ROM) is always one track. **[ROM]+[DISK]**

*(Not yet unpacked: the exact Monitor load size — the load descriptor at bootloader
`0x114` is `<<25>>0x0200`, len `0x0e00`, … — only needed if we want the precise
second-stage sector count.)*

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
