# Olivetti M30 / M40 (L1) — Hardware Reference for Emulation

A structured hardware description of the M40 (and its M30 sibling) intended as the
build spec for a **MAME** machine model. It is synthesised from the boot-ROM
disassembly and the Olivetti service manuals. This document is **separate from the
project goals** (`README.md`); it aims for enough fidelity that a MAME driver can be
written from it directly.

### Confidence tags

Every non-obvious fact carries a tag:

- **[ROM]** — established directly from the boot-ROM disassembly.
- **[MAN]** — stated in an Olivetti service manual.
- **[PHOTO]** — read off a physical **UC042** central-unit board.
- **[INF]** — inferred/derived (reasoning given); plausible but not proven.
- **[?]** — unknown / needs a schematic or further RE.

> Where a value is tagged **[INF]** or **[?]**, the MAME model should keep it
> configurable and revisit it once schematics or more of the ROM are analysed.

---

## 0. UC042 board — confirmed chipset (from a board photo)  ⭐

The M30/M40 central unit is board **UC042** (silkscreen *"OLIVETTI MADE IN ITALY
S3000 UC042 P001 A COD.339136"*). The later M34/M44 UC048 is the 8 MHz successor.
Major devices read off the board:

| Device | Part (as marked) | Role | Tag |
|--------|------------------|------|-----|
| **CPU** | `Z8001B1 SEGCPU` (SGS) | Zilog Z8001 segmented CPU | [PHOTO] |
| **MMU** | `Z8010B1 MMU` (SGS) | Zilog Z8010 MMU | [PHOTO] |
| **PIT** | `P8253-5` (AMD, ©1982) | Intel 8253 timer (`0xFFC1/C3/C5/C7`) | [PHOTO] |
| **ACIA** | `EF68B50P` (SGS/Thomson) | Motorola 6850 serial ACIA — serial console / aux line | [PHOTO] |
| **Boot ROM** | `RM27128A` (AMD) + `M27128A` (SGS), a pair | two 27128 (16 KB) EPROMs = **even/odd byte lanes** of the 16-bit bus | [PHOTO] |
| **Gate array** | `MB15652 … GA 02` (Fujitsu) | **custom Olivetti gate array** — most likely the bus / address-decode / READY-NMI / slot-select logic | [PHOTO]/[INF] |
| **Clock** | `CXO-042C 32.000 MHz` (KSS) | master oscillator; CPU & video clocks divided from it | [PHOTO] |
| Glue | 74LSxx (244/373/161/138/08/02/00/32/04/132/10/26…), `P8436` bus drivers | address/data buffering, decode | [PHOTO] |
| (delay?) | small `5/10` module near the ACIA | possibly a **delay line** for the Z8010's delayed address strobe | [PHOTO]/[?] |

**Takeaways for the model:**
- CPU = Z8001, MMU = Z8010, PIT = 8253 — all three **confirmed exactly** as the ROM
  predicted.
- There is a **6850 ACIA** on the UC — a strong candidate for the *serial diagnostic
  console* (the manual's "console diagnostica") and/or the console char device the
  ROM drives near `0xFF64`. Worth reconciling with the ROM's console ports.
- A **custom Fujitsu gate array (MB15652)** implements glue that isn't a catalogue
  chip — very likely the **READY/NMI generation and slot decode** the ROM leans on
  (empty-slot → NMI, the `0xFF80..0xFF8F` register block, etc.). Its exact behaviour
  needs a schematic.
- **Master clock is 32.000 MHz**; the Z8001 clock is a divided value (`/8` → 4 MHz or
  `/4` → 8 MHz; M30/M40 is the pre-8 MHz generation, so ~4 MHz is likely). A video dot
  clock of 16 MHz (`/2`) is plausible. Still needs the divider from a schematic.

---

## 1. System composition

The machine is a **backplane of up to ~16 board slots** ("cassettiera") driven by a
central-unit (UC) board. Boards ("governi") are memory-mapped and/or DMA devices on
a shared bus. **[MAN]**

Core boards relevant to reaching IPL:

| Board | Role | Nome logico (type ID) |
|-------|------|-----------------------|
| **UC** (unità centrale) | CPU + MMU + on-board I/O | `FF` **[MAN]** |
| Governo **video/tastiera** | CRTC display + keyboard | `FE` **[MAN]** |
| Governo **linea** | serial/comm lines | `D1/D2/D3/D5/D7`, `CF`… **[MAN]** |
| Governo **FDU / MFDU** | floppy | `E1 / E0` **[MAN]** |
| Governo **HDU** | hard disk | `E4` **[MAN]** |
| Governo **STC** | streaming tape | `E6` **[MAN]** |

Full type-ID list: see the M34/M44 *nome logico* table (companion notes). The M40 is
the segmented-CPU variant; RAM boards, video, and mass-storage governi plug into the
backplane.

---

## 2. CPU / MMU subsystem (on the UC board)

| Item | Value | Tag |
|------|-------|-----|
| CPU | Zilog **Z8001** (segmented, 48-pin) | [ROM] |
| Clock | Master oscillator **32.000 MHz** [PHOTO]; the CPU clock is a divided value (`/8`→4 MHz likely, `/4`→8 MHz). M30/M40 is the pre-8 MHz generation. Divisor unconfirmed. | [PHOTO]/[?] |
| MMU | Zilog **Z8010** (single unit → 64 segments, 0–63) | [ROM] |
| Reset FCW | `0xC000` (SEG=1, system mode) | [ROM] |
| Reset PC | `<<0>>0x0106` (seg 0, offset 0x106) | [ROM] |
| PSAP | `<<0>>0x0000` (Program Status Area at ROM start) | [ROM] |

### 2.1 Z8001 reset vector (physical bytes at seg-0 offset 0)

```
0x00: dfbb  (reserved)   0x02: c000 (FCW)   0x04: 8000 (PC seg=0)   0x06: 0106 (PC off)
```
**[ROM]**

### 2.2 Program Status Area (segmented, 8 bytes/entry: rsvd, FCW, PCseg, PCoff)

| PSA off | Vector | Handler | Tag |
|---------|--------|---------|-----|
| `0x00` | reset | `<<0>>0x0106` | [ROM] |
| `0x08`–`0x27` | EPA / Priv / SysCall / Segment traps | *(unused — hold the ASCII banner)* | [ROM] |
| `0x28` | **NMI** | `<<0>>0x00ce` | [ROM] |
| `0x30` | **NVI** | `<<0>>0x00f2` | [ROM] |
| `0x38` | **VI** base | `<<0>>0x0000` (unused) | [ROM] |

### 2.3 Interrupt wiring

| Source | Line | Use | Tag |
|--------|------|-----|-----|
| **`READY` timeout** on a bus access | **NMI** | absent RAM / absent board detection (see §6, §7) | [ROM] |
| **`0xFF80..0xFF8F` device** | **NVI** | paces a device init sequence (device unidentified) | [ROM]/[?] |
| Backplane governi | **VI** + 3 priority levels (L1A/L1B/L2) | normal device interrupts (daisy-chained by slot) | [MAN] |

The NMI and NVI handlers **do not `iret`**; they pop the 8-byte frame (`inc r15,#8`)
and `jp @rr12`, i.e. they *resume execution at a caller-set continuation register*.
This is the core idiom the ROM uses to probe possibly-absent hardware. **[ROM]**

---

## 3. Address spaces

The Z8001 has three distinct spaces. All three must be modelled.

### 3.1 Memory (translated by the Z8010)

Logical `<<segment>>offset` → physical 24-bit, via the MMU descriptor for that
segment (`physical = (base<<8) + offset`). Segment allocation set up by the ROM:

| Segment | Maps to (physical) | Purpose | Tag |
|---------|--------------------|---------|-----|
| **0** | `0x000000` | ROM (this artifact) | [ROM] |
| **1** | top of RAM (~1 KB) | **stack / system** segment (SP → `<<1>>0x01c0`) | [ROM] |
| **2 … N** | RAM banks | **bulk RAM**, one 64 KB descriptor each (last sized to the remainder) | [ROM] |
| **60** | *remapped on the fly* | RAM-sizing **scratch probe window** | [ROM] |
| **61** | `0xFF0000` | video framebuffer (64 KB window) | [ROM] |
| **62** | `0xF00000` | video (second window) | [ROM] |
| **63** | `0x000000` | set up but role unclear | [ROM]/[?] |

After RAM sizing, the ROM maps the contiguous physical RAM into segments **1** (a
small stack/system window near the RAM top) and **2…N** (64 KB each). **[ROM]**

Physical memory map (as the ROM assumes it):

| Physical | Contents | Tag |
|----------|----------|-----|
| `0x000000`… | **ROM** (8 KB REL 4.1 / 16 KB REL 6.0) | [ROM] |
| `0x010000`–`0xEF0000` | **RAM**, in 64 KB banks; contiguous; sized at boot; ≥ 16 KB required | [ROM] |
| `0xF00000` | video window (seg 62) | [ROM] |
| `0xFF0000` | **video framebuffer** (seg 61); 80×25 char cells, 2 bytes/cell | [ROM] |

> RAM sizing probes banks `0x01`…`0xEF` (`rh1` high byte) at 16 KB granularity; the
> RAM base is wherever the first bank asserts `READY`. Exact base/size is
> configuration-dependent. **[INF]**

**Battery Backup Unit (BBU).** RAM can be **battery-backed**. At boot, if `0xFF41`
bit 0 indicates the BBU held RAM and the marker **`"$BBU ON "`** is found at
`<<1>>0x03f8`, the ROM restores a saved MMU descriptor from `<<1>>0x0210` and resumes
at a saved entry point (**warm boot**) instead of cold-starting. The model needs a
battery-backed RAM region plus that "BBU valid" status bit. **[ROM]**

### 3.2 Standard I/O — the backplane device-select model  ⭐

**Key model (derived from the slot scans, §6):**

- **Slot select = I/O address bits 15–12** (the high nibble). 16 slots.
- **Register = the low byte** (bits 7–0).
- **Bits 11–8 are don't-care** (the ROM addresses the same board registers with
  both nibbles: the video/prelim scan reads the ID at `0x?FFF`, the config scan
  reads it at `0x?0FF`, and both hit the same slot+register). **[ROM]**
- The board's **type-ID (nome logico) register is at low byte `0xFF`**. **[ROM]**

So each board is a **256-byte register window** at its slot's high nibble. The
**UC is slot 15**, so its chips live at high byte `0xF_` (canonically `0xFF__`).

> This resolves the earlier `0xF0E0/0xF0E2` puzzle: with bits 11–8 ignored, they are
> the **same registers as `0xFFE0/0xFFE2`** (the console latch). The reset writes
> `0` to `0xF0E0/E2` simply to clear the console indicator. **[ROM]**

Board register I/O is done **register-indirect** (`@r1`), which is why only UC's
`0xFF__`/`0xF0__` addresses appear as *immediate* ports in the ROM — every other
board is reached with a computed high nibble. **[ROM]**

> Modelling note: MAME I/O decode should take **bits 15–12 → slot**, **bits 7–0 →
> register**, ignoring bits 11–8. Still worth a schematic check. **[ROM/INF]**

### 3.3 Special I/O — the Z8010 MMU

Command = **high byte of the Special-I/O port**; low byte = `0x00` (single MMU).
**[ROM]** (opcodes per the Z8010 datasheet)

| Port | Z8010 command |
|------|---------------|
| `0x0000` | mode register (`0x80` = enable/transparent, `0xC0` = enable/translate) |
| `0x0100` | SAR (segment address register) |
| `0x2000` | DSC (descriptor selection counter) |
| `0x0F00` | R/W descriptor byte + auto-increment SAR (used for block loads) |

Descriptor layout (per segment, 4 bytes, loaded high→low): `base_hi, base_lo, limit,
attr`. **[ROM/MAN]**

---

## 4. UC board — on-board I/O register map (high byte `0xFF`)

All confirmed from the ROM. Offsets are the I/O **low byte**.

| Port | Device / function | Notes | Tag |
|------|-------------------|-------|-----|
| `0xFFC1` | **8253** (P8253-5) counter 0 | mode 2 (rate gen); prescales counter 1 | [ROM]+[PHOTO] |
| `0xFFC3` | 8253 counter 1 | mode 0; system-tick / timer test target | [ROM] |
| `0xFFC5` | 8253 counter 2 | mode 3 (square wave) | [ROM] |
| `0xFFC7` | 8253 control | control words `0x34`,`0x70`,`0xB6`; `0x40` latch | [ROM] |
| `0xFFE0` | diagnostic **console code latch** | receives the step/error code | [ROM] |
| `0xFF64`–`0xFF67` | diagnostic console char/indicator | 4 positions — possibly the **6850 ACIA** (EF68B50) registers | [ROM]/[INF] |
| `0xFF6C`–`0xFF6F` | console indicator "set" variants | bit-per-code display | [ROM/INF] |
| `0xFF41` | **NMI / READY control + status** | read+cleared in NMI handler; bit 6 = probe outcome; bit 0 = BBU-valid. Likely in the **MB15652 gate array** | [ROM/INF] |
| `0xFFA0` | config / jumper read | read once at init | [ROM] |
| `0xFF20` | control latch | written `0x03` at init | [ROM] |
| `0xFF01` | control latch | written at init | [ROM] |
| `0xFF80`–`0xFF8F` | **16-register device** (NVI source) | not a catalogue chip → probably part of the **MB15652 gate array** | [ROM]/[INF] |
| `0xF0E0`,`0xF0E2` | *= `0xFFE0/E2`* (bits 11–8 don't-care) — clears the console latch at reset | [ROM] |

Chips to instantiate for the UC board (all confirmed on the UC042 photo, §0):
**Z8001**, **Z8010**, **i8253 PIT**, **6850 ACIA**, the **MB15652 gate array** (bus /
READY-NMI / decode / the `0xFF80` block), and the diagnostic-console latch. **[PHOTO]**

---

## 5. Video / keyboard board (nome logico `FE`)

### 5.1 CRTC (6845-family)

Accessed register-indirect at the board's window (`0x?F..`):

| Reg (low byte) | Function | Tag |
|----------------|----------|-----|
| `0x41` | CRTC **address** register (selects R0..R15) | [ROM] |
| `0x43` | CRTC **data** register | [ROM] |
| `0x81` | board **status / type**; low 3 bits = monitor type 0..7 | [ROM] |
| `0x01` | control (armed with `0x03` during video test) | [ROM] |
| `0x6a` | "enable normal video" after a successful self-test | [ROM] |
| `0xFF` | type-ID register → reports `0xFE` | [ROM] |

### 5.2 Geometry (decoded from the per-type CRTC tables in ROM)

| Monitor types | Columns (R1) | Rows (R6) | Char scan-lines (R9+1) | Active lines |
|---------------|--------------|-----------|------------------------|--------------|
| 0, 1, 3, 4, 7 | **80** | **25** | 12 / 16 / 17 | 300 / 400 / 425 |
| 2, 6 | 40 | 13 | 16 | — |

**[ROM].** Character text is 80×25. Character **cell width in dots is unknown [?]**,
so the horizontal pixel count is open; vertical active lines follow directly from
rows × scan-lines.

### 5.3 Framebuffer

- MMU **segment 61** → physical `0xFF0000`, 64 KB window. **[ROM]**
- **2 bytes per character cell** (character code + a second byte, presumably
  attribute). 80×25 = 2000 cells. **[ROM/INF]**
- Additional video boards get successive `+0x2000`-byte windows. **[ROM]**

### 5.4 Init sequence (per board)

Read type at reg `0x81` → pick one of 8 CRTC register tables (at ROM `0x0c44`) →
load R0..R15 via `0x41`/`0x43` → RAM read/write walk of the framebuffer → poll status
reg for a live-signal (bit 3) toggle → enable (`0x6a`). Result word `0x0000` (OK) /
`0xFFFF` (fail). **[ROM]**

---

## 6. Backplane slot scan (how boards are enumerated)

The ROM enumerates the bus like this **[ROM]**:

1. Step the slot high nibble over the 16 slots.
2. Read the **type-ID** at register `0xFF` of the slot.
3. **An empty slot has no `READY`** → the read faults → **NMI** → the NMI handler
   `jp @rr12`, and `rr12` was pre-loaded with the *next-slot* address. Absent boards
   are skipped for free.
4. Dispatch on the ID: `0xFE` → video init/test; `0xD?` → line board; `0xF0` → (a
   video/uninit variant); etc.

For the MAME model this means: **decode the I/O high nibble → slot; an access to a
slot with no board must generate the CPU's NMI (via the READY/timeout logic)**, not
just read back `0xFF`. The NMI/READY path is load-bearing for enumeration.

### 6.1 Config table ("SYSTEM ENVIRONMENT") — `ricerca governo di caricamento`

After RAM is set up, the ROM runs a second full 16-slot scan (`0x0590`) that
records the machine's configuration into system RAM **[ROM]**:

- For each slot it reads the type-ID and stores **`type (XX)` at `<<1>>0x0230 +
  slot*4`** and a **diagnostic-response `(YYYY)` at `+2`** (for video, fetched via
  a helper; `0x0000` ok / `0xFFFF` fail). An **absent slot → `0xFFFF/0xFFFF`**.
- This 16×4-byte table is the data behind the *"NLS 30000 SYSTEM ENVIRONMENT"*
  screen. The RAM start/end are also published to `<<1>>0x0220..0x022a`.

This is the enumeration half of the manual's *ricerca governo di caricamento*; the
IPL-device **selection + boot load** (choosing HDU/FDU/… by priority and reading the
first stage) is the next part to trace. **[?]**

---

## 7. RAM sizing (how memory is discovered)

`0x0a94`, the manual's *ricerca allocazione fisica RAM* **[ROM]**:

- Uses **segment 60** as a movable probe window; reprograms descriptor 60's base to
  each 64 KB physical bank (`0x01`…`0xEF`) and reads it.
- Absent RAM → no `READY` → **NMI** → resume at the loop checkpoint (`rr12` =
  `0xaa8`/`0xaea`); present RAM records start (`r4:r5`) / end (`r6:r7`).
- Requires the contiguous extent to be **≥ 16 KB**, else returns fault → the ROM
  shows **code 2** (system-RAM fault).

Same `READY`→NMI mechanism as the slot scan; the emulated memory/bus must model
"unpopulated address → NMI".

---

## 8. Reset / boot sequence (order the model must satisfy)

1. Enable MMU transparent; clear `0xF0E0/E2`; show step 1 on the console. **[ROM]**
2. Set DRAM refresh, stack, PSAP; program the 8253. **[ROM]**
3. Preliminary board scan (video/line dispatch). **[ROM]**
4. **ROM checksum** (interleaved end-around-carry sum vs. the top 4 bytes). **[ROM]**
5. **8253 timer** rate test. **[ROM]**
6. **Z8010 descriptor** R/W test; invalidate all; load the live map; enable
   translation. **[ROM]**
7. **Video slot scan** — init/test each video board. **[ROM]**
8. `0xFF80` device NVI-paced sequence. **[ROM]/[?]**
9. Show step 2 → **RAM sizing**; then memory-board test (`0x0b0e`, not yet traced).
   **[ROM]** / **[?]**
10. IPL controller search + program load (not yet traced). **[?]**

Any failing step in 4–7/9 **hangs** (e.g. `jr self`) or shows a numeric code on the
diagnostic console; there is no graceful degradation. **[ROM]**

---

## 9. Open questions blocking a complete model

| # | Question | Needed for |
|---|----------|------------|
| 1 | CPU-clock **divisor** from the 32 MHz master (photo gives the master, not the divide) | timing accuracy |
| 2 | Register semantics of the **`0xFF80..0xFF8F` device** — likely inside the **MB15652 gate array**; is the ACIA/console part of it? | M1 (clean boot) |
| 3 | Precise **`0xFF41`** bit map (READY/NMI control; incl. the BBU-valid bit 0) | M1 (RAM/slot probing) |
| 4 | **RAM base/size** and bank granularity on real boards | memory model |
| 5 | **FDU / HDU governo** register/DMA interface | M2–M4 (IPL, install) |
| 6 | Character **cell width** (font ROM) | exact video raster |
| 7 | Confirm the **slot I/O decode** (slot = bits 15–12, register = low byte) against schematics | bus model |

---

## 10. MAME model checklist (minimum to reach M1→M4)

- [ ] Z8001 CPU core (segmented) — clock = 32 MHz ÷ divisor (TBD).
- [ ] Z8010 MMU: Special-I/O command decode, 64 descriptors, translate/transparent.
- [ ] Memory: ROM at seg-0/phys-0 (2×27128, even/odd); contiguous RAM; **unpopulated access → NMI**.
- [ ] I/O decode: bits 15-12 → slot, low byte → register (bits 11-8 don't-care); **empty slot → NMI**.
- [ ] i8253 PIT with counter0→counter1 cascade.
- [ ] 6850 ACIA (serial console / aux line).
- [ ] MB15652-equivalent glue: **NMI/READY logic (`0xFF41`)** + the **`0xFF80` block** + slot decode — the enumeration backbone.
- [ ] Diagnostic console latch (`0xFFE0`, `0xFF64..6F`).
- [ ] 6845-family CRTC + framebuffer at seg-61/phys-`0xFF0000` (80×25).
- [ ] FDU governo → floppy image (M2/M3).
- [ ] HDU governo → hard-disk image (M4).

*This document tracks the disassembly; update it as `re/` annotations advance.*
