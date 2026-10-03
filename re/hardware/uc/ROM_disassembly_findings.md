# M30/M40 ROM — Disassembly Findings (pass 1)

Disassembled with a local driver over the MAME-based Z8000 library at
`~/Projects/M20/PCOS/z8kdis` (generic Z8000, **Z8001 segmented mode** — not
PCOS-specific). Driver: `tools/z8kdisrom.cpp`. Listings: `re/disassembly/m40-rom/m40rom-4.1.asm`,
`re/disassembly/m40-rom/m40rom-6.0.asm`. ROMs are `REL 4.1` (8 KB) and `REL 6.0` (16 KB), both
banner-dated *17 DEC 82*. (The manual's "ROM 151/152" is a board-generation label
by UC production date, not tied to the REL number — "152" for these is inferred
from the date, not confirmed.)

Rebuild / regenerate:
```sh
c++ -std=c++17 -O2 -I ~/Projects/M20/PCOS/z8kdis tools/z8kdisrom.cpp \
    -L ~/Projects/M20/PCOS/z8kdis -lz8kdis -o tools/z8kdisrom
./tools/z8kdisrom reference/roms/m40rom-4.1 0x106 0x1fac > re/disassembly/m40-rom/m40rom-4.1.asm
```

---

## 1. Reset & Program Status Area (segment 0)

The Z8001 reset reads a segmented vector from the first 8 bytes of segment 0:

| Offset | Word | Meaning |
|---|---|---|
| `0x0000` | `dfbb` | reserved (reset entry's unused word) |
| `0x0002` | `c000` | **FCW** = segmented + system mode (SEG=1, S/N=1) |
| `0x0004` | `8000` | PC **segment** = 0 |
| `0x0006` | `0106` | PC **offset** → **reset entry = `<<0>>0x0106`** |

`PSAP` is set (at `0x012c`) to **`<<0>>0x0000`**, so the ROM's first bytes are the
**Program Status Area** (segmented layout = 8 bytes/entry: `rsvd, FCW, PCseg, PCoff`):

| PSA offset | Vector | Target | Note |
|---|---|---|---|
| `0x00` | (reset) | `<<0>>0x0106` | |
| `0x08`–`0x27` | EPA / Priv / SysCall / Segment traps | — | **reused to hold the ASCII banner** `" 17 DEC. 82  REL 4.1 "` (these traps are never taken) |
| `0x28` | **NMI** | `<<0>>0x00ce` | RAM-sizing fault catcher (see §4) |
| `0x30` | **NVI** | `<<0>>0x00f2` | |
| `0x38` | **VI** base | `<<0>>0x0000` | (unused) |

Stuffing the version string into the unused trap-vector slots is a nice confirmation
of the PSA layout — and it's why `REL 4.1`/`REL 6.0` sit at ROM offset `0x12`.

### Reset entry (`0x0106`)
```
0106: ldb  rl0,#0x80
0108: soutb #0x0000,rl0     ; MMU mode reg = 0x80 (MSEN=1, TRNS=0 → transparent)
010c: sub  r0,r0
010e: out  #0xf0e0,r0       ; clear F0 system-control latch (TBD)
0112: out  #0xf0e2,r0
0116: ldar rr10,0x0122      ; manual return address
011c: jp   <<0>>0x0baa      ; console/video bring-up (phase code rl7=1)
0122: ld   r0,#0x9200
0126: ldctl refresh,r0      ; Z8001 DRAM refresh control = 0x9200
0128: lda  rr14,<<0>>0x00fe ; stack pointer (rr14 = SP)
012c: ldar rr2,0x0000
0130: ldctl psapseg,r2      ; PSAP = <<0>>0x0000  (PSA is at ROM start)
0132: ldctl psap,r3
0134: ldb  rl0,#0x34
0136: outb #0xffc7,rl0      ; 8253 control: counter0, mode2
013a: ldb  rl0,#0x70
013c: outb #0xffc7,rl0      ; 8253 control: counter1, mode0
```

---

## 2. I/O map — confirms the "FF = CPU-board chips" model  ⭐

Across **both** ROMs the *only* normal-I/O device selects used are **`0xFF__`**
(94 accesses) and **`0xF0__`** (4 accesses). Everything else — video, floppy, HDU
governi — is reached through **memory** windows programmed into the MMU, not via
I/O ports.

So your model is right, with one refinement: the CPU board (UC, *nome logico* **`FF`**)
answers at I/O high-byte **`0xFF`** for all its on-board chips. That is a
**device-type select, not a slot number** — the UC is always `FF` regardless of
whether it sits in slot 1 (M40) or slot 2 (M30). The *slot* position instead
determines the priority daisy-chain and the **MMU memory window** each governo gets
(video base = segment 61; see §3).

### UC on-board chips (I/O high-byte `0xFF`)

| Port(s) | Chip / function | Evidence |
|---|---|---|
| `0xFFC1 / C3 / C5 / C7` | **8253 PIT** (counter 0/1/2 + control) | control words `0x34`,`0x70`; counter load/read pairs |
| `0xFF80`–`0xFF8F` | **MB15652 bus/DMA arbiter** | full-block NVI-paced init sweep at `0x2aa`–`0x32e`; disk-A BUS ARBITER test decodes grant/ack behavior |
| `0xFF64`–`0xFF67` | **diagnostic-console** device (char output) | routine `0x0baa` writes chars here |
| `0xFFE0` | **diagnostic-console step/error-code latch** | `outb #0xffe0,rl7` — writes the phase code (the "codice su console" 1–5) |
| `0xFF41` | **NMI / READY control & status** | read+cleared in NMI handler; bit 6 tested |
| `0xFFA0` | status/jumper read | `inb rl0,#0xffa0` early in reset |
| `0xFF20` | control latch | `outb #0xff20` |
| `0xFF01` | control latch | `outb #0xff01` |
| `0xF0E0 / F0E2` | system-control latch, cleared at reset (**TBD** — only non-FF port) | first thing after MMU enable |

### MMU (Z8010) — via **Special-I/O** (`sinb`/`soutb`/`sotirb`)

Single MMU (low byte of the port is always `00`). Opcodes seen (high byte =
command, per the Z8010 reference §8):

| Special-I/O port | Z8010 command |
|---|---|
| `0x0000` | mode register (`0x80` written = enable) |
| `0x0100` | SAR (segment address register) |
| `0x2000` | DSC (descriptor selection counter) |
| `0x0F00` | R/W descriptor + increment SAR → **block-load via `sotirb`** |

Block-load of all descriptors matches the datasheet's `SOTIRB @R1,@RR4,R0` idiom.
A single Z8010 covers segments 0–63, consistent with the manual's *segment 0 = ROM,
segment 61 = video RAM*.

---

## 3. Video is memory-mapped at **segment 61**

Confirmed in code at `0x0bfe`:
```
0bfe: lda rr2,<<61>>0x0000  ; base of video RAM (segment 61 decimal)
0c04: ld  r5,#0x0800        ; test 2 KB
0c0c: ld  @rr2,r0 / cp r0,@rr2 ; write-readback video-RAM logic test
```
This is the manual's "video-control-logic test" whose result becomes the `%0000`
(ok) / `%FFFF` (fail) response word in the config table. Video output for
diagnostic messages therefore goes through the MMU-mapped window, not I/O.

---

## 4. NMI handler = RAM-sizing fault catcher (`0x00ce`)

```
00ce: inc  r15,#8           ; discard the 8-byte NMI frame (SP += 8) → resume, not iret
00d0: cp   r13,#0x0aa8      ; r13 = expected checkpoint PC (phase guard)
00d4: jr   z,0x00dc
00d6: cp   r13,#0x0aea
00da: jr   nz,0x00ec
00dc: inb  rl6,#0xff41      ; read UC NMI/READY status
00e0: out  #0xff41,r0       ; clear it
00e4: bitb rl6,#6           ; test bit 6
00e6: jp   nz,<<0>>0x0ada
00ec: out  #0xff41,r0       ; clear
00f0: jp   @rr12            ; return via rr12 (not iret)
```
Matches the manual: **RAM presence/extent is probed by watching `READY`; a missing
`READY` raises an NMI.** The handler pops the frame (`inc r15,#8`), checks a
checkpoint PC in `r13`, reads/clears the NMI source at **`0xFF41`**, and resumes.
`rr12`/`r13` are the probe's working "return PC" pair.

---

## 4b. Backplane slot scan (`0x150`, `0x27c`)

Both scans share one idiom: step the **device-select high byte** over all 16
slots (`rh1` = `0x00,0x10,…,0xF0`), form the port `(slot<<8)|0x0FFF`, and read the
board's **ID byte** (its *nome logico*). An **empty slot has no `READY`**, so the
`inb` faults → NMI → the NMI handler (`0x00ce`) does `jp @rr12`, and `rr12` was
pre-loaded with the **next-slot address** — so absent boards are skipped for free.

- **Preliminary scan `0x150`–`0x1b6`**: dispatches on ID — `0xF0` (write `0x07`
  to reg `0x81`), `0xFE` video (inline CRTC blank: R6=R1=0), `0xD?` line family
  (write `0x01` to reg `0xB1`, set `rh7=0xFF`). That `rh7` flag later gates the ROM
  checksum (`0x1ba`: line board present ⇒ skip checksum).
- **Video scan `0x27c`–`0x2a4`**: for every `0xFE` board call the video
  detect/init/test (`0x0bc6`) and hand it the next `+0x2000` framebuffer window.
- The post-scan block `0x2a6`–`0x321` drives the **MB15652 `0xFF80..0xFF8F`
  bus/DMA arbiter** through an **NVI-paced** sequence (arm → `ei nvi` → spin
  `jr self` until NVI resumes at the next `rr12`). Disk-A UCO.71 test 13 gives the
  per-channel grant/ack behavior.

## 4c. RAM allocation, BBU warm-start & memory test (`0x0b0e`, `0x35c`, `0x3ba`)

After RAM sizing (§4b) succeeds, stage ② runs:

- **`0x0b0e` — map RAM into segments.** Programs MMU descriptors from #2 upward to
  cover the contiguous physical RAM in **64 KB chunks** (base, limit `0xFF`, attr 0),
  the last sized to the remainder; then sets **descriptor 1** = a small (~1 KB)
  system/stack segment near the RAM top and moves the stack to `<<1>>0x01c0`. So the
  live MMU map becomes: seg 0 = ROM, **seg 1 = stack/system**, **seg 2..N = bulk RAM**,
  seg 60 = probe scratch, seg 61/62 = video.
- **`0x35c` — BBU (Battery Backup Unit) warm-start check.** If `ff41` bit 0 says the
  BBU kept RAM alive and the marker **`"$BBU ON "`** (8 bytes, ROM `0x39c`) is present
  at `<<1>>0x03f8`, it restores a saved MMU descriptor from `<<1>>0x0210` and `jp @rr2`
  to a saved entry — a **warm boot / resume**. Otherwise cold start.
- **`0x3a4` — cold start**: zero low RAM; if a line board was found (NSP flag from the
  scan) branch to `0x4ca`, else run the memory test.
- **`0x3ba` — memory pattern test** ("test piastra di memoria"): a marching test over
  all mapped RAM writing **`0x5555` / `0x3131` / `0xFFFF`** (+ complements), verifying
  each pass; a miscompare jumps to the fault handler `0x0430` (which computes the
  faulting address). Note: `0x0b0e` (map) is *not* itself a test — earlier guess corrected.

## 4d. Config table & IPL device search (`0x0590`, `0x065c`)

- **`0x0590`** — build the **config table** ("SYSTEM ENVIRONMENT"): full 16-slot
  scan storing each slot's `type (XX)` at `<<1>>0x0230+slot*4` and diag-response
  `(YYYY)` at `+2`; absent slot → `0xFFFF`. RAM bounds also published to
  `<<1>>0x0220..0x022a`. This also **relocates the PSA into RAM** (`<<1>>0x0000`).
- **`0x065c`** — **IPL device search + load**. Boot order chosen by the **ISL
  switch = `0xFF41` bit 1** (set → HDU-first list `0x6e6`, clear → FDU-first
  `0x6e8`). Priority list (nome logico): `E4`(HDU) `EF`(GIPO/IEEE-488→DCU) `E1`(FDU)
  `E0`(MFDU) `E6`(STC). For each type, scan the config table for a match, then call
  its handler from the table at `0x6ee`:
  - **`0x0eae` = FDU/MFDU floppy loader** (the M2/M3 target),
  - `0x1a5e` = GIPO/HDU loader, `0x1e2c` = STC loader, `0xffff` = HDU-direct (via GIPO).
  Retries until `<<1>>0x0308 == 0x5555` (boot ok).
- **`0xFF41` bitmap so far**: bit 0 = BBU-valid, bit 1 = ISL boot-order, bit 6 = probe.
- Next: trace the **floppy loader `0x0eae`** for the FDU governo command/DMA interface.

## 5. Open items / next steps

- [x] **Test ROM / CRC** — DONE (`0x01be`–`0x01e6`, annotated). Two interleaved
      16-bit sums-with-end-around-carry over the ROM (even bytes→sum1, odd→sum0),
      each byte XORed with its offset low byte, compared to the 4-byte value at the
      top (`0x1ffc`). **Verified in `tools/` model: reproduces `d977 e802` (4.1) and
      `c0fe d787` (6.0).** So the trailing word IS the checksum. Mismatch → hang.
- [x] **Z8010 MMU test** — DONE (`0x0220`–`0x0258`): write `0x00` to all 256
      descriptor bytes, read-back/compare (hang on fail), then fill `0xFF` (invalidate).
- [x] **MMU map** — DONE (table at `0x00f6`, loaded `0x025c`): seg 0 → phys
      `0x000000` (ROM), seg 61/62 → phys `0xFF0000`/`0xF00000` (64 KB video windows);
      mode `0xC0` enables translation.
- [x] **CPU (Z8001) test** — none present. Matches the manual ("per ora non è
      implementato"). Reset goes init → checksum → timer → MMU → slot scan.
- Correction: the seg-61 video-RAM test (`0x0c0c`) **walks 4 KB** — `rr2`'s offset
  half (`r3`) is incremented by 2 each pass; it is NOT a single cell (earlier note fixed).
- [x] **8253 timer test** — DONE (`0x01e8`–`0x021e`): counter0 (mode2) prescales
      counter1 (mode0, preload `0x03be`); poll-latch until it counts through 0, and
      the CPU poll-count must be in `[0x28,0x100)` — too fast hangs `0x21e`, too slow `0x206`.
- [x] **Video is CHARACTER-mapped, 80×25** — DONE (CRTC init table `0x0c44`). Each
      per-monitor block = 2 control bytes + a **6845-family CRTC** R0..R15. Decoded:
      R1=`0x50`(80 cols), R6=`0x19`(25 rows) for the standard types; R1=`0x28`(40),
      R6=`0x0d`(13) for the 40-col alternate. Char cell R9+1 = 12/16/17 scanlines by
      monitor → pixel raster ≈ 640×300..425. Video RAM = seg 61 / phys `0xFF0000`,
      **2 bytes/cell (code+attribute)**; 80×25 = 2000 cells (the RAM test walks 2048).
      CRTC accessed via I/O register-select `0x41` (address) / `0x43` (data); status/type
      at `0x81` (low 3 bits pick the monitor block).
- [x] Identify the `0xFF80–0xFF8F` device — **MB15652 bus/DMA arbiter**, decoded
      from disk-A UCO.71 BUS ARBITER TEST.
- [ ] Identify `0xF0E0/0xF0E2` (the only non-FF I/O) — suspected system/bus latch.
- [ ] Follow the "ricerca governo di caricamento" slot scan and how governo memory
      windows are assigned per slot (this is where slot number enters addressing).
- [ ] Diff `REL 4.1` vs `REL 6.0` control flow (HDU/STC IPL support → the size jump).
```
