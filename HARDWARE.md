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

### 1.1 Identified boards (from photos)  ⭐

Chipsets read off physical boards in the spares set:

| Board | Function | Key chips | MAME-relevant |
|-------|----------|-----------|---------------|
| **UC042** | central unit | Z8001 + Z8010 + 8253 + 6850 ACIA + 2×27128 + **MB15652** gate array; 32 MHz osc | §0 |
| **GO280** | **FDU / MFDU floppy** | **µPD765** (`FDC765AC`) + **8237/9517 DMA** + 8253 + 2× TI gate arrays (`GA04-CF11051`, `CF11050P-GA03`) | `upd765`+`i8237`+`i8253` (M2/M3) |
| **GO363** | **HDU — ST506 interface** | **NEC µPD7261** HDC + 8253 + `TC5565` 8K SRAM buffer + 20 MHz osc + `MC3466` data sep | µPD7261 (M4) |
| **GO252** | **video / keyboard (KDC)** | **MC6845** CRTC (`MC68B45P`) + **MB15651** gate array + 2× `TMM2016` video SRAM + GI char-gen | mc6845 (video) |
| **GO200X** | **STC — streaming tape** (`E6`; IPL handler `0x2814`) | **Zilog Z8002** CPU + **AM9517 DMA** + 2× 6116 SRAM + firmware EPROM pair (rel "R6.1"); `COD.339192` | local Z8002 subsystem |
| **GO151** | **serial line governo** (2× async; `D?`); `COD.339096` | **Z80 DART** (`Z8470`) + 8253 + 4.9152 MHz baud clock; non-intelligent (host-driven) | z80dart |
| RAM boards | memory | DRAM arrays + a gate array | (not chip-ID'd) |

Notes: **GO252 physically confirms the MC6845 video model** (§5). **GO363 gives the
HDU path** (µPD7261) for M4. **GO200X** (the STC governo, IPL device `E6`) runs its
**own Z8002** with local ROM/RAM/DMA — an intelligent board modelled as a sub-CPU,
not just registers. **GO151** is an M30/M40-generation line board (in the M40 parts
catalog *"GO252-GO151"*, code `3963260 Y`; absent from the newer M34/M44 *nome
logico* table, where it is superseded by `GO236`-type governi). Governo silkscreens
follow *"OLIVETTI MADE IN ITALY S3000 GOxxx P001 A COD.33xxxx"*. **[PHOTO]**

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
| `0x000000`… | **ROM** (16 KB, `REL 6.0`) | [ROM] |
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
| `0xFF41` | **NMI / READY control + status** | read+cleared in NMI handler; **bit 0 = BBU-valid**, **bit 1 = ISL boot-order switch**, bit 6 = probe outcome. Likely in the **MB15652 gate array** | [ROM/INF] |
| `0xFFA0` | config / jumper read | read once at init | [ROM] |
| `0xFF20` | control latch | written `0x03` at init | [ROM] |
| `0xFF01` | control latch | written at init | [ROM] |
| `0xFF80`–`0xFF8F` | **MB15652 bus/DMA arbiter** — 4 channels × 4 register groups (see §4.1) | `0xFF80–83` = arbitration **acknowledge** (`0xFF81` reads back the **grant**); `0xFF84–87` = DMA **request/gate** (`0xFF84` boot); `0xFF8C–8F` = DMA **control** (`0xFF8C` boot). Inits all 16 at `0x2a6`; raises the **NVI** on a grant | [ROM]+[DISK] |
| `0xF0E0`,`0xF0E2` | *= `0xFFE0/E2`* (bits 11–8 don't-care) — clears the console latch at reset | [ROM] |

Chips to instantiate for the UC board (all confirmed on the UC042 photo, §0):
**Z8001**, **Z8010**, **i8253 PIT**, **6850 ACIA**, the **MB15652 gate array** (bus /
READY-NMI / decode / the `0xFF80` block), and the diagnostic-console latch. **[PHOTO]**

### 4.1 UC registers revealed by the L1 diagnostic (disk A)

The boot ROM touches only what booting needs; the **A diagnostic** (central-unit /
RAM, DCOS 8.4) exercises far more of the `0xFF__` space. Extracted by scanning the
disk image for `0xFF__` port accesses; functions inferred from the access pattern.
**[DISK]** (bit-detail **[?]** unless noted).

**Bus/DMA arbiter `0xFF80–8F` (MB15652)** — decoded from the *BUS ARBITER TEST* ISR:
- **`0xFF81` read = grant register**: bit 7/6/5/4 set = channel 0/1/2/3 was granted
  (e.g. `0x90` = channels 0 **and** 3 pending).
- **`0xFF80–83` write = per-channel acknowledge** (`0xFF80`→ch0 … `0xFF83`→ch3); the
  ISR reads `0xFF81`, then acks the granted channel(s).
- `0xFF84–87` = DMA request/gate (ch0 = `0xFF84`, the boot gate); `0xFF8C–8F` = DMA
  control/mask (ch0 = `0xFF8C`). The arbiter interrupt is serviced, `0xFF81` read,
  and the channel acked — so a MAME model needs an arbiter that grants a channel,
  raises the interrupt, exposes the grant at `0xFF81`, and clears on the ack write.

**Other UC registers the diagnostic touches** (not seen from the ROM):

| Port(s) | Observed use | Guess |
|---------|--------------|-------|
| `0xFF00`–`0xFF02` | control latches (heavy `0xFF00` use) | UC control |
| `0xFF20` / **`0xFF22`** | `0xFF22` very heavily read/written | UC status/control pair |
| `0xFF11`, `0xFF19`, `0xFF40`, `0xFFB1`, `0xFFF0`, `0xFFFE` | scattered | misc control/status |
| **`0xFF50`,`0xFF51`,`0xFF54`–`0xFF5F`** | **multiprocessor / master-slave signaling** (disk-A `UCY` = *UCO.71 MULTIPROCESSOR UC TEST*, the "MASTER AND VIENO SIGNAL" test): `0xFF51` = status (bit 0 polled), `0xFF54`/`55`/`58`/`5E`/`5F` = signal/control | **master-slave (multiprocessor)** |
| `0xFF60`–`0xFF6F` | indicator (`0xFF60+n`), read-back | diagnostic console (extends §4 rows) |
| `0xFFA0`,`0xFFA5`,`0xFFAA` | config/jumper block | UC config |
| **`0xFFC0`**–`0xFFC7` | 8253 (adds counter-0 data at `0xFFC0`) | 8253 (extends §4) |
| **`0xFFD0`–`0xFFDB`** | **cache-memory controller** — the optional Fujitsu **S3000SV cache** (disk-A `FJCAC1`/`WRCAC` "CACHE TEST"): `0xFFD1` = status (bits 6–7 = tag **hit/miss**, bit 0 = flag), `0xFFD2–DB` = tag / data / associative-memory access + watch-dog | **cache (optional board)** |

**UC component list, from the `UCY`/`UCO.71 MULTIPROCESSOR UC TEST` menu.** The disk-A
UC test enumerates its own sub-tests, which name the full on-board component set —
several of which the boot ROM never exercises: **[DISK]**

> `1) SLOT` · `2) MMU2 AND MMU1` · `3) MASTER AND VIENO SIGNAL` · `4) TIMER` ·
> `5) ACIA` · `6) INTERRUPT` · `7) ABORT (MMU)` · `8) ROM` · `9) EAROM` ·
> `10) SWITCHES` · `11) CACHE` · `12) WATCH-DOG` · `13) BUS ARBITER` · `14) RESET`

New facts for the UC model: **two Z8010 MMUs** (MMU1 + MMU2 — the ROM programs only
one at boot), a **6850 ACIA** that is real and tested (the ROM just never uses it), an
**EAROM**, board **config switches**, a **watch-dog** timer, and the (optional) cache.
This is the on-disk confirmation of the disk-A test set (BUS ARBITER = §4.1 above,
etc.). Register-level detail for `0xFF5x` still needs the sub-test disassembled.

---

## 5. Video / keyboard board (nome logico `FE`)

### 5.1 CRTC (6845-family)

> Physically confirmed: the video board **GO252** carries an **`MC68B45P` (MC6845)**
> CRTC plus an `MB15651` gate array and `TMM2016` video SRAM. **[PHOTO]**


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
records the machine's configuration into system RAM **[ROM]** (format & the
`%0000`/`%FFFF` video-response confirmed by the *Manuale dei Collaudi* §1 **[MAN]**):

- For each slot it reads the type-ID at register `0xFF` and writes a **4-byte
  entry**:
  - **`+0` = `type (XX)`** — one byte, the *nome logico* (`0xFF` UC, `0xFE` video,
    `0xE4` HDU, `0xE1` FDU, `0xE0` MFDU, `0xE6` STC, …).
  - **`+2` = `diagnostic-response (YYYY)`** — a **pass/fail** word: **`0x0000` =
    present/OK**, `0xFFFF` = fault. Non-video boards are only probed for presence, so
    they always read `0x0000`. A **video board (`0xFE`)** is the one that runs a live
    functional check (`0x0996` → `0xbc6`): select the CRTC init string by controller
    type (reg `0x81` & 7 → table `0xc44`), program the CRTC, size the framebuffer, and
    confirm the status/retrace bit (reg `0x81` bit 3) **toggles** — **`0x0000` if the
    video is alive, `0xFFFF` if it is dead**. An **absent slot faults (no `READY` →
    NMI) and is written `0xFFFF/0xFFFF`**.
- The video board's *detailed* config is captured **separately**, not in this table:
  slot → `<<1>>0x0355`, a "video-found" flag → `0x0357`, framebuffer extent →
  `0x035a`. This 16×4-byte table is the data behind the *"NLS 30000 SYSTEM
  ENVIRONMENT"* screen, and the two-stage boot loader reads it directly (no re-scan).
  The RAM start/end are also published to `<<1>>0x0220..0x022a`.

**Nome-logico (type-ID) table** — the full set, from the *Manuale dei Collaudi* §1.
The UC is always slot 15 (16th position). **[MAN]**

| ID | Board | ID | Board |
|----|-------|----|-------|
| `FF` | Unità centrale (UC) | `D5` | line X24 |
| `FE` | video / keyboard governo | `D7` | line "lion 9.6" |
| `E1` | FDU | `CF` | Twin RS232 / Current Loop |
| `E0` | MFDU | `B0` | Pin-Pad / Badge Reader |
| `E4` | HDU | `EF` | GIPO (IEEE-488) |
| `E6` | streaming-tape cartridge (STC) | `D1` | line "TTL" |
| `D2`/`D3` | line V24 (unattended / normal) | `D4` | line X24 (unattended) |

### 6.2 IPL device search & load (`0x065c`) — how the machine boots  ⭐

With the config table built, the ROM selects a boot device and loads the first
stage **[ROM]**:

1. **Boot order is set by the ISL switch = `0xFF41` bit 1**: set → HDU-first list
   (`0x06e6`), clear → FDU-first list (`0x06e8`). The priority list is a sequence of
   *nome logico* bytes: **`E4`(HDU) `EF`(GIPO/IEEE-488 → DCU) `E1`(FDU) `E0`(MFDU)
   `E6`(STC)** (`0x00` terminates). This matches the manual's IPL order.
2. For each device type in the list, **scan the config table** (`<<1>>0x0230`) for a
   slot of that type.
3. When found, look up its **handler** in the table at `0x06ee` (`{param, handler}`
   per device) and **call it** to load the boot program:

   | Device | Handler | Notes |
   |--------|---------|-------|
   | FDU / MFDU (`E1`/`E0`) | **`0x0eae`** | floppy loader — the path to **M2/M3** |
   | HDU direct (`E4`) | **`0x1e58`** | direct disk-controller governo — the path to **M4** |
   | GIPO / HDU (`EF`) | `0x1a5e` | IEEE-488 / DCU / HDU loader |
   | STC (`E6`) | `0x2814` | streaming-tape loader |

4. **Retry** the whole search until a boot succeeds (`<<1>>0x0308 == 0x5555`),
   showing a "waiting for IPL" indication otherwise.

So for the MAME model, the FDU/HDU governi are reached here. The **floppy loader
`0x0eae`** is the next routine to trace toward **M2** — it will show exactly how the
FDU governo's command/DMA interface works.

### 6.3 FDU floppy governo — board **GO280** (from a board photo)  ⭐

Board **GO280** (silkscreen *"S3000 GO280 P001 A COD.339200 S-03"*, label
*"337366 H G0280 B"*), the FDU/MFDU controller (nome logico `E1`/`E0`). Chipset:

| Device | Part (marked) | Role | Tag |
|--------|---------------|------|-----|
| **FDC** | `FDC765AC` (SMC) | **µPD765-compatible floppy disk controller** | [PHOTO] |
| **DMA** | `D8237AC-5` (NEC) | **8237 DMA controller** — moves sectors to/from system RAM | [PHOTO] |
| **PIT** | `P8253-5` (AMD) | 8253 timer | [PHOTO] |
| Gate arrays | `GA04-CF11051`, `CF11050P-GA03` (TI) | custom **data separator / bus glue** | [PHOTO] |
| Misc | `AM25LS2521` (comparator), `MC3448AP` (bus xcvr), `74145` (drive decode), `LM317`/`LM340` | | [PHOTO] |
| Config | 4-position DIP switch | drive / mode select | [PHOTO] |

**MAME impact — this de-risks M2/M3 a lot.** The floppy path is buildable from
**stock MAME devices**: `upd765` (FDC) + `i8237` (DMA) + `i8253`, with the TI gate
arrays doing data separation (mostly internal to MAME's `upd765`). The Z8001 host
drives the FDC/DMA through the governo's register window (`E0`/`E1` slot) and the
8237 DMAs sectors into system RAM — exactly what the IPL handler `0x0eae` exercises.
Confirms the governi work in DMA. **[PHOTO]/[INF]**

#### Host-side register map — authoritative  ⭐

The governo is addressed at the found FDU slot (high byte saved at `<<1>>0x0302`);
the **low byte selects a register**. The full map is documented in the Olivetti
*"M30/M40/M31 Governi Mini-Floppy/Floppy — Descrizione di funzionamento"* (doc.
`3963590`), which describes this exact board (it lists `GO280/A`, the CF11050/CF11051
gate arrays, and the AM9517 DMAC). It matches the ROM RE. **[MAN]+[ROM]**

| Reg (low byte) | Chip / function |
|----------------|-----------------|
| `0x1D` | **FDC (µPD765/NEC765) Main Status** (read; poll RQM) |
| `0x1F` | **FDC data register** (command / result bytes) |
| `0x40`–`0x5E` | **AM9517 DMAC** internal registers: `40/42`=ch0 addr/count, `44/46`=ch1, `48/4A`=**ch2** addr/count (the FDC data channel), `4C/4E`=ch3, `50`=command(w)/status(r), `52`=request, `54`=single-mask, `56`=mode, `58`=clear byte-ptr, `5A`=master-clear/temp, `5E`=channel mask |
| `0x9x` | **8253 timer** (counters + control) — motor spin-up 500 ms, motor-off 2 s, **read/write time-out 800 ms** (4 disk revolutions) |
| `0xE7` | **control register `CONTR`** (write): `EN10`=IRQ enable, `RESFD`=reset FDC, `MOTO1/MOTO2`=drive-motor enable, `SCRVO`=direction (1=write/0=read), `DIAG`/`SCAN`/`ERRO1` |
| `0xED`, `0xEF` | diagnostic ports (read); `0xEF` also = interrupt-vector write (`VETTN`) |
| `0xF6` | **DMA address high byte** (`ADRLN`, bits ADD16–23) — see below |
| `0xF7` | **interrupt status** (read): `INTMO`(8253), `INTOO`(FDC), `PERRO`(parity), **`FUMEO`(DMA "out-of-memory" time-out)** |
| `0xFF` | **identifier / nome logico** (read): `E0`=MFDU, `E1`=FDU, selected by the **NOM10 jumper** — *this is where the `E0`/`E1` type ID comes from* |

The boot read is a **µPD765 READ DATA** command (templates `0x17dc`/`0x17e6`:
`06`(READ) `HDUS` `C=0 H=0 R=1` `N` `EOT` `GPL` `DTL` — **cylinder 0, head 0, sector 1**;
two disk formats, EOT `0x10`/`0x1a`).

#### DMA model (manual §3.3)  ⭐

The **governo's own AM9517 DMAC** moves the sector data — the UC `0xFF80..0xFF8F`
block is only the **system-bus arbitration** the governo requests (via `BAXXN`/`REQOO`;
`0xFF84`/`0xFF8C` are the UC-side gate). The DMAC runs an "anomalous" **two-channel**
scheme: **channel 1** sets up the address for the next cycle (no data), **channel 2**
does the FDC↔memory transfer — and because the FDC bus is 8-bit, **2 channel-2 cycles
per 16-bit word**. On write `SCRVO=1`; on read `SCRVO=0` (channel-1 cycle skipped).

**Physical DMA address = 24 bits (§3.3.4):** the low **16 bits come from the DMAC
channel-2 address register** (`0x48`), the **high 8 bits (ADD16–23) from register
`0xF6`** (board logic, auto-incremented across 64 KB blocks). So the destination **is**
software-programmed. A **2 µs no-`READY` time-out** raises `FUMEO` ("fuori memoria").

**Where the track lands (`0x85e`):** the driver programs the DMAC ch2 address + `0xF6`
so the transfer targets **logical segment 60** (physically = whatever MMU descriptor 60
maps). It then validates the boot image and jumps:

1. magic: the first 4 bytes at `<<60>>0x0000` must be **`"SYS0"`** (`0x53595330`);
2. **entry point** = the longword at `<<60>>0x0004`;
3. reprogram MMU/PSA, then **`jp @rr4`** to that entry.

So the boot image is self-describing: **`"SYS0"` + 4-byte entry address + code**, and
the destination is fully known. **[MAN]+[ROM]**

> To model: `upd765` (`0x1D`=status, `0x1F`=data) + `i8253` (`0x9x`) + **`am9517` DMAC
> (`0x40-5E`)** with an extra high-address latch (`0xF6`), a control reg (`0xE7`), an
> interrupt-status reg (`0xF7`), and the `0xFF` type ID — all stock MAME devices plus a
> thin gate-array wrapper. The manual `3963590` is the reference. **[MAN]**

**Completion signaling — FDU boot = polled.** The boot read runs with **VI masked**
(`di vi` at `0x0ec8`; FCW restored at `0x0f12`) and detects transfer completion by
**polling the governo interrupt-status register** — reg `0xFF` bit 0 (fallback reg
`0xED` bit 0), routine `0x0f2e` — plus µPD765 RQM (reg `0x1D`). A full VI handler
(`0x1304`–`0x137a iret`, records status to `<<1>>0x034a`/`0x034e`, sets ready bit
`0x0354.0`) exists for interrupt-driven runtime use, but the ROM boot path does not
use it. So the model needs a readable **INT-pending bit at `0xFF`/`0xED` bit 0**. **[ROM]**

### 6.4 HDU hard-disk governo — board **GO363** (µPD7261 / ST506)  ⭐

The direct-HDU boot handler **`0x1e58`** (IPL type `E4`) is traced. It is called with
`rr2` → an 11-byte device parameter block (drive geometry + start LBA + destination),
which it copies to `<<1>>0x0354`, identifies the drive (`0x21d4` → reads drive
parameters to `<<1>>0x0318`, selects a geometry: 621 cyl/58 or 425 cyl/32),
converts the start block **LBA → C/H/S** (`divl`/`div`), then seeks and reads the boot
block into the destination via DMA. As with the FDU, the governo is addressed at the
slot window (`<<1>>0x0302` high byte); the low byte selects a register:

| Reg | Dir | Meaning |
|-----|-----|---------|
| `0x80` | W word | **DMA address counter**, low word (word-granular = `addr>>1`) |
| `0x82` | W word | DMA address counter, high word |
| `0x83` | W | **DMA / command start strobe** (written with the command word to launch the transfer) |
| `0x90` | R | **status** (polled; bit 0 = error / not-ready) |
| `0xb0` | W word / R | **µPD7261 command + control latch** — high byte = opcode (`0x09` SEEK, `0x0a` READ, `0x02`/`03`/`08`/`0b` specify/recal/identify), low byte `0x10`/`0x18` control; bits 11 & 4 pulsed as strobes; read back for status |
| `0xe0`,`0xe1` | W | drive + cylinder/head select (two bytes) |

This matches the **disk-G** diagnostic test names (`PROGRAM 'NEC'` = µPD7261,
`DMA & RAM & ADDRESS COUNTER` = the `0x80`/`0x82` counter, `8253 TIMER & DMA`), so
the governo is the **GO363** (NEC µPD7261 HDC + 8253 + SRAM buffer). This handler is
the path to **M4** (detect/boot the hard disk). **[ROM]** / register bit-detail **[?]**

**Completion signaling — HDU boot = interrupt-driven.** Unlike the FDU, the HDU path
leaves **VI enabled**. The command executor (`0x2266`, sibling `0x1cbc`) sets a busy
flag `tsetb <<1>>0x0316`, issues the command, then **spin-waits on that flag** until
the governo's **vectored-interrupt ISR** (`0x22ca` / `0x1cf8`, each `clrb 0x0316;
iret`) clears it on completion — bounded by an **8253-tick timeout** (`<<1>>0x030f`,
decremented by the timer ISR `0x0e56`…`0x0e5e iret`). So the model must have the HDU
governo **assert a backplane vectored interrupt** on command completion (via the
`0xFF80–8F` arbiter), and the 8253 tick must run. **[ROM]**

> To model: a `upd7261`-class HDC behind a gate-array wrapper exposing the register
> map above — a 32-bit word-granular DMA address counter (`0x80`/`0x82`), a start
> strobe (`0x83`), a polled status (`0x90`), a command/control latch (`0xb0`), and a
> drive/CHS select (`0xe0`/`0xe1`). Geometry and the exact strobe bits are still open.

### 6.5 Interrupt / ISR model  ⭐

How governo completions reach the CPU (the M4 interrupt loop). **[ROM]**

**Fixed CPU exceptions** (PSA at `<<0>>0x0000`, copied to RAM at boot):
- **Reset** → `<<0>>0x0106`. **Traps** (unimplemented / privileged / system-call /
  segment) are **unhandled** — the banner text occupies their PSA slots.
- **NMI** → `<<0>>0x00ce` — the **enumeration probe-fault** handler: an empty slot /
  no-`READY` faults here and is **resumed via `jp @rr12`** (a resume address staged
  before the risky access; this is how the slot scans tolerate empty slots). Special
  case `0xFF41` bit 6 → `jp 0xada` (power-fail / BBU).
- **NVI** → `<<0>>0x00f2` — minimal resumable handler (`jp @rr12`), used by the
  bus-arbiter self-test.

**Governo completion interrupts** use a **16-entry vector table at `<<1>>0x01c0`**
(4-byte `{seg,off}` ISR pointers, indexed by **vector × 2** so vectors are even).
It is built at `0x0516`, default-filled with a stub `<<0>>0x00b4`; then each governo,
in its init/boot handler, is **assigned a vector via a governo register** and
**installs its own ISR**:

| Device | Vector | Vector reg | ISR | ISR action on completion |
|--------|--------|-----------|-----|--------------------------|
| 8253 tick | 2 | (UC 8253) | `0x0e2e` | decrement the command timeout `<<1>>0x030f` |
| FDU / MFDU | 4 | governo `0xEF` | `0x12ec` | set ready bit `0x0354.0`, status `0x034a`/`0x034e` |
| HDU (GO363) | block of 8 | governo `0xaa` | `0x1cf8` / `0x22ca` | `clrb <<1>>0x0316` (busy flag) |
| STC | — | — | `0x298e` | — |

On completion the governo raises its interrupt **carrying its vector**; the CPU
vectors through `0x01c0[vector×2]` to the ISR, which records status / clears the busy
flag and `iret`s, releasing the foreground spin-wait (§6.3/§6.4). Unassigned vectors
land on the stub `0x00b4`.

> To model M4: the `l1_hdgov` device needs a writable **vector register (`0xaa`)** and
> must **assert the backplane interrupt carrying that vector** on command complete;
> the machine routes the backplane INT to the Z8001 VI, which vectors through the
> `0x01c0` table. (The FDU boot path masks VI and polls instead — §6.3 — but the
> runtime/interrupt-driven mode uses vector 4 → `0x12ec`.)

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
8. Init the **UC DMA/interrupt controller** (`0xFF80..0xFF8F`) via the NVI-paced
   sequence — the backplane-DMA arbiter the FDU/HDU transfers use. **[ROM]**
9. Show step 2 → **RAM sizing**; map RAM into segments (`0x0b0e`); BBU warm-start
   check; **memory pattern test** (`0x03ba`). **[ROM]**
10. Build the **config table** (`0x0590`); **IPL device search + load** (`0x065c`):
    pick order by ISL switch, find a controller, call its handler; the **floppy
    loader `0x0eae`** is the remaining piece toward M2. **[ROM]** / handler internals **[?]**

Any failing step in 4–7/9 **hangs** (e.g. `jr self`) or shows a numeric code on the
diagnostic console; there is no graceful degradation. **[ROM]**

### 8.1 Diagnostic codes & halt map (for debugging an M1 hang)  ⭐

The ROM has **no text messages** (only the banner, `$BBU ON`, `SYS0`); diagnostics
are **numeric**, and the service manual (*Manuale dei Collaudi* §1) defines them. **[MAN]+[ROM]**

**Non-blinking codes** — a single digit on the `0xFFE0` console latch + `0xFF64..67`
indicator (written by `0x0baa`, code in `rl7`). The ROM shows the code for the phase
it is **about to run**, so a hang leaves the failed phase's code up:

| Code | Meaning | Shown at |
|------|---------|----------|
| `1` | **UC-board fault** (CPU / ROM-CRC / Z8010 / 8253 / arbiter) | reset entry `0x011c` |
| `2` | **system-RAM fault** (absent, or < 16 KB) | before RAM sizing `0x0338` |
| `3` | unexpected interrupt-time vector | — |
| `4` | no IPL controller found | IPL search |
| `5` | waiting for the first IPL attempt | IPL search |

**Blinking codes** — for UC↔IPL-controller dialogue errors: four values `X Y Z`, also
shown on video as `X Y Z  REL 6.0`. `0x0d10` builds them from `rl7` + the boot slot
(`0x0302`) + unit (`0x0303`): **X** = `1` controller / `2` peripheral / `4` media-read
error / `8` no media or no OS; **Y** = controller slot; **Z** = unit. `0x0d10` also
carries two states in `<<1>>0x0308`: `0x4444` (enumerating), `0x5555` (booted OK — the
boot-success value).

Because the UC self-tests **halt in place** on failure (code `1` stays up), the **PC
of the spin identifies which** UC test failed — the map that helps when an M1 bring-up
freezes:

| Halt PC | Failed test |
|---------|-------------|
| `0x01e6` | **ROM checksum** mismatch (`0x01c0` sums the image, compares at `0x01e4`) |
| `0x0206` | **8253 timer** count/overflow test |
| `0x021e`, `0x023e` | further **timer / counter** checks |
| `0x02f0`, `0x0300`, `0x0310`, `0x0320` | **bus-arbiter interrupt test** — the expected NVI from an `0xFF80–8F` write never arrived |
| `0x06be` | *not a fault* — the normal IPL "wait for load complete" spin on `<<1>>0x02fc` |

So in MAME: watch the **`0xFFE0` latch** and the **CPU PC** — a spin at one of the
rows above names the missing/mis-modeled device
(ROM image, 8253, or the `0xFF80–8F` arbiter's NVI), and a latch stuck on `1` vs `2`
brackets it to the pre- vs post-RAM phase. **[ROM]**

---

## 9. Open questions blocking a complete model

| # | Question | Needed for |
|---|----------|------------|
| 1 | CPU-clock **divisor** from the 32 MHz master (photo gives the master, not the divide) | timing accuracy |
| 2 | ~~`0xFF80..0xFF8F` arbiter bit meanings~~ — **decoded** from disk-A's BUS ARBITER TEST (§4.1): `0xFF81` = grant (bit 7–4 = ch 0–3), `0xFF80–83` = per-channel ack, `0xFF84–87` = DMA request, `0xFF8C–8F` = DMA control. Remaining: the governo-side `0xe7`/`0xff` and HDU `0xb0` strobe bits | M2/M4 (DMA) |
| 3 | Precise **`0xFF41`** bit map (READY/NMI control; incl. the BBU-valid bit 0) | M1 (RAM/slot probing) |
| 4 | **RAM base/size** and bank granularity on real boards | memory model |
| 5 | ~~FDU + HDU register maps~~ — **documented** (FDU §6.3 from manual `3963590`; HDU §6.4 from handler `0x1e58`). Remaining: exact `0xb0` strobe bits + geometry-select logic | M4 (install) |
| 6 | Character **cell width** (font ROM) | exact video raster |
| 7 | Confirm the **slot I/O decode** (slot = bits 15–12, register = low byte) against schematics | bus model |

> Two settled negatives (simplify the model): CPU **traps are unhandled by the ROM** —
> the segment / privileged-instruction / system-call PSA slots hold the banner text,
> so the ROM assumes none fire during self-test (the *loaded* diagnostic does install
> them — it has `*** SEGMENT TRAP ***` / `*** PRIVILEGED INSTRUCTION TRAP ***`
> handlers); and there is **no serial console** —
> the on-board 6850 ACIA is never touched, all diagnostic output is the `0xFFE0`
> code latch + `0xFF64` indicator + video. **[ROM]**

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
- [ ] FDU governo (GO280): `upd765`(`0x1D/1F`) + `am9517` DMAC(`0x40-5E`, +`0xF6` addr-high) + `i8253`(`0x9x`) + control(`0xE7`)/status(`0xF7`)/ID(`0xFF`) → floppy image (M2/M3). Register map: manual `3963590`.
- [ ] HDU governo (GO363, ST506): NEC µPD7261 HDC + 8253 + SRAM buffer → hard-disk image (M4).

*This document tracks the disassembly; update it as `re/` annotations advance.*
