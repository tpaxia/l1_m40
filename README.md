# Olivetti M30 / M40 (L1) — ROM Reverse-Engineering & MAME Bring-Up

## 1. Project goal

Reverse-engineer the Olivetti **M40** boot ROM (a **Zilog Z8001** program) to
establish, in as much detail as possible, **how each board is detected and
tested** by the resident power-on autodiagnostic — and from that, derive the
**minimum set of hardware needed to run the self-test and start an IPL**.

That hardware is then reimplemented in **MAME**, and the machine is driven
through a fixed sequence of milestones:

1. execute the **BIOS / resident autodiagnostic** to completion — **done**,
2. perform an **IPL** (initial program load) — **done**,
3. **boot from floppy** — **done** (boots the DCOS 8.4 field-diagnostic disk to its
   interactive monitor and runs standalone diagnostics), and
4. **detect the hard disk** (as required for installation) — **in progress**.

The MAME driver (`src/mame/olivetti/m40.cpp`) already models the Z8001 CPU,
Z8010 MMU, RAM, 8253 timer, the MC6845 video board (GO252 KDC, with keyboard,
character attributes and the L1 font), and the floppy governo (GO280: µPD765 +
AM9517 DMA + the UC bus arbiter) — enough to boot the diagnostic disk and drive its
menus and tests (KEYTE1 keyboard test, CRTAN5 video/attribute test).

The M40 is the segmented-CPU member of the Olivetti **L1** line; the M30 is its
sibling and shares this ROM family. The firmware in scope is **`REL 6.0`** (16 KB
EPROM pair), banner-dated *17 DEC 82* — the build carrying the full set of IPL
device handlers, including the direct hard-disk governo.

> The service manual splits the resident firmware into **ROM 151** (on
> central-unit boards produced up to Nov 1982) and **ROM 152** (from Nov 1982) — a
> board/hardware generation, *distinct* from the `REL x.x` loader-release number.
> The manual does not tie the REL to 151/152; the Dec-1982 date only *suggests*
> this dump belongs to the 152 era. Treated here as unconfirmed.

### Documents

- **[HARDWARE.md](HARDWARE.md)** — the hardware reference / **MAME build spec**:
  confirmed chipset (from board photos), the three address spaces, MMU segment and
  physical memory maps, per-board register maps, the interrupt/boot model, an
  identified-board inventory, and a MAME device checklist.
- **[DIAGNOSTICS.md](DIAGNOSTICS.md)** — the L1 DCOS 8.4 field-diagnostic disk set:
  contents, the two-stage boot flow, and the ROM→bootloader config-table handoff.
- **[KDC.md](KDC.md)** — the **GO252 video/keyboard governo** behavioral model: the
  keyboard VI interrupt path, the keyboard serial protocol and positional scancode
  tables, the ANK 1426 / 1427 keyboards, and the character-cell attribute encoding
  (reverse / high light / blink / line attributes).
- **[KEYMAP.md](KEYMAP.md)** — the official **L1 MOS ↔ PC keyboard mapping**
  (MOS Programmer Guide §7, Tab. 7-3, used by L1WSE) and its realization in the
  MAME driver.
- **[L1WSE.md](L1WSE.md)** — related work: reverse-engineering of the Olivetti M24
  "L1 Work-Station Emulator" (see §6).

## 2. Approach — the ROM defines the minimum to reach IPL

The resident autodiagnostic is a concrete, executable lower bound on the
machine's hardware: at power-on it programs the MMU, sizes RAM, scans the
backplane for boards, tests each one, sets up video for diagnostics, and selects
an IPL device. Reverse-engineering it tells us which devices — and which of their
registers — must exist for the machine to reach IPL.

That is a starting point, not the whole machine. Once an IPL image, standalone
diagnostic, or OS is loaded, it will exercise features the ROM never touches
(fuller disk I/O, interrupts, keyboard, etc.). Those are added to the MAME model
incrementally, driven by what each later stage actually accesses.

## 3. Target machine — minimum hardware to model in MAME

Ordered roughly by the sequence in which the ROM exercises them.

### 3.1 CPU — Zilog **Z8001** (segmented)
- Segmented mode, system/normal split; reset vector at seg 0 (`FCW=0xC000`,
  `PC=<<0>>0x0106`).
- A UC042 board photo shows a **32.000 MHz master oscillator**; the CPU clock is
  **4 MHz** (`32 MHz / 8`).
- Program Status Area at `<<0>>0x0000`; NMI and NVI vectors used (RAM sizing,
  timer). No CPU instruction self-test was found in the reset path.

### 3.2 MMU — Zilog **Z8010**
- Programmed via Special-I/O (mode/SAR/DSC/descriptor opcodes).
- Descriptor R/W self-test (write 0x00 to all 256 bytes, verify).
- Live map loaded from a descriptor table: **seg 0 → phys `0x000000` (ROM)** and
  **seg 61 → phys `0xFF0000`** (video, confirmed by the code); segs 62–63 are also
  set up (`0xF00000` / `0x000000`). Mode `0xC0` enables translation.

### 3.3 Memory
- **ROM** at seg 0. A trailing checksum word (top 4 bytes) is recomputed and
  compared at power-on ("Test ROM").
- **RAM**, contiguous, **≥ 16 KB** minimum; sized by probing `READY`/NMI.

### 3.4 I/O — slot-windowed device selects
- **Decode model** (reconstructed from the slot scans; to confirm against
  schematics): **slot = I/O address bits 15–12**, **register = the low byte**, and
  **bits 11–8 are don't-care** (two scans read the same board register at both
  `0x?FFF` and `0x?0FF`). Each board's **type-ID (*nome logico*) is register `0xFF`**.
  Peripheral registers are addressed register-indirect with the slot's high nibble.
- The **UC (central unit) is slot 15**, so its on-board chips live at high nibble
  `0xF_` (canonically `0xFF__`):
  - **8253 PIT** at `0xFFC1/C3/C5/C7` (system tick + a rate/interrupt test).
  - **Diagnostic console**: code latch `0xFFE0` + the 3-bit lamp latch at `0xFF60..0xFF6F`
    (set `0xFF68-6A`, clear `0xFF60-62`, readback).
  - **NMI / READY logic** at `0xFF41`.
  - **EF68B50P ACIA** at `0xFF20/22` (serial keyboard link + UC3003 loopback test);
    VI vector latches `0xFF01` (timer) and `0xFFA0` write-side (ACIA); `0xFFA0` read =
    config/jumpers.
  - `0xFF80..0xFF8F` — the **MB15652/UC bus arbiter** (NVI source): `0xFF81` grant,
    `0xFF80-83` ack, request/release strobe groups (decoded from disk-A's arbiter test).
  - `0xF0E0/0xF0E2` = the console latch (`0xFFE0/E2`) via the don't-care bits;
    the reset writes them to clear the console indicator.
  - `0xF0E0/0xF0E2` — a UC latch (the only non-`FF` immediate I/O), to be identified.

### 3.5 Video / keyboard — **GO252 KDC** (6845-family CRTC) — *modeled*
- Register-select `0x41` (address) / `0x43` (data); type/status at `0x81`.
- **80 × 25** character text (40 × 13 alternate); character cell height
  12/16/17 scan lines depending on monitor type (→ 300/400/425 active lines). The
  character *width* in dots is not yet determined, so horizontal dot count is open.
- Framebuffer at **seg 61 / phys `0xFF0000`**, 2 bytes per character cell (character +
  attribute). Implemented in MAME: the CRTC text display, the **character-cell
  attributes** (reverse / high light / blink / high-low-left-right line), the L1 house
  font, and the **keyboard** (VI interrupt, serial protocol, ANK positional scancodes
  mapped to a PS/2 keyboard). Full behavioural model in **[KDC.md](KDC.md)**.

### 3.6 FDU — floppy governo (IPL source) — *modeled, boots*
- The IPL device search (`0x065c`) is traced: order set by the **ISL switch**
  (`0xFF41` bit 1), priority list `E4`(HDU) `EF`(GIPO) `E1`(FDU) `E0`(MFDU) `E6`(STC),
  each dispatched to a handler. The **FDU/MFDU boot handler is `0x0eae`**.
- Implemented in MAME (GO280 governo): **µPD765** FDC at 500 kbps, **AM9517** DMA with
  the anomalous word-addressed 2-channel scheme, the **8253** command timer, the
  **RD1NT** interrupt-source latch, and the **MB15652/UC bus arbiter** — enough to
  boot the DCOS 8.4 diagnostic disk. Register model cross-checked against manual
  `3963590` and the disk-D `6030T6` diagnostic.

### 3.7 HDU — hard-disk governo (installation target) — *in progress*
- In the IPL search as types `E4` (direct disk-controller governo, handler
  `0x1e58`) and `EF` (via GIPO/IEEE-488, handler `0x1a5e`). The **direct governo
  `0x1e58`** (GO363, **NEC µPD7261** controller) is the M4 target.
- The **µPD7261 device already exists in MAME** (`machine/upd7261.cpp`) and is reused
  as the disk-I/O core; what remains is the **GO363 gate-array wrapper** (opcode/
  parameter translation, board DMA, VI) — the open work for M4.

### 3.8 Interconnect — backplane slot scan & device-select model
- Confirmed mechanism: the ROM walks the 16 slot windows (high bytes
  `0x0F, 0x1F, …, 0xFF`; see §3.4) and reads each board's **type-ID** at window
  offset `0xFF` (port `0x?FFF`); an **empty slot faults (no `READY`) → NMI**, and
  the NMI handler resumes the scan at the next slot. IDs are the *nome logico*
  codes (`FF`=central unit, `FE`=video, …; full table in the service manual).
- Several scans are traced: a preliminary pass (dispatch on board type), a video
  pass (init + self-test each video board), and the **config-table build**
  (`0x0590`) — a full 16-slot scan that records each slot's `type (XX)` +
  diagnostic-response `(YYYY)` into system RAM at `<<1>>0x0230+slot*4` (the
  *"SYSTEM ENVIRONMENT"* table; absent slot → `0xFFFF`). The IPL-device
  **selection + boot load** is the next part to trace.

## 4. Milestones (MAME bring-up)

| # | Milestone | Done when | Status |
|---|-----------|-----------|--------|
| **M1** | Resident autodiagnostic runs clean | CPU + MMU + RAM + 8253 + video pass; no diagnostic hang; reaches the IPL stage | ✅ done |
| **M2** | IPL | ROM selects an IPL controller and loads the first stage per the priority order | ✅ done |
| **M3** | Boot from floppy | FDU governo modeled well enough to load the OS/monitor image | ✅ done (DCOS 8.4 diagnostic monitor) |
| **M4** | Detect HD for installation | HDU governo enumerated and readable so install can target it | 🔶 in progress (µPD7261 in MAME; GO363 wrapper pending) |

IPL device priority (from the service manual, absent the ISL switch): HDU 5010 →
HDU 6813 → DCU 9448 (fixed) → FDU → MFDU → STC → DCU 9448 (removable).

## 5. Method

- **Round-trippable disassembly.** The ROM is disassembled to a form that
  reassembles to a **byte-identical** image, so annotations can be added freely
  and always re-verified against the original.
- **Annotate outward from reset**, block by block, keeping every change
  byte-neutral.
- **Model in MAME** device-by-device, matched to exactly what the annotated ROM
  touches, and re-run the milestones after each addition.

## 6. Related work

**L1WSE — Olivetti M24 "L1 Work-Station Emulator"** (see **[L1WSE.md](L1WSE.md)**). A separate
reverse-engineering effort on the DOS-side software that turns an Olivetti M24
PC into an L1 graphics workstation / terminal. Different CPU (8086, real mode) and
a different artifact, but the same L1 ecosystem — useful for the host-link
protocol, the display model, and the terminal/keyboard behaviour an L1 host
expects.

## 7. Status

**The MAME driver boots the DCOS 8.4 field-diagnostic disk to its interactive
monitor and runs standalone diagnostics** (M1–M3 done; M4 in progress).

Modeled and working: the Z8001 reset path + PSA, Z8010 MMU test + map, ROM checksum,
8253 timer, RAM sizing, the backplane slot scan / config-table build, the UC bus
arbiter, and the **GO280 floppy governo** (µPD765 + AM9517 word-addressed DMA + 8253
+ RD1NT latch) — the machine IPLs from floppy and reaches the diagnostic monitor
(LOAD / MAP / HELP / GO). The **GO252 KDC** is modeled too: MC6845 text video with
character attributes (reverse / high light / blink / lines), the L1 font, and the
keyboard (VI, serial protocol, ANK scancodes → PS/2). It runs the on-disk diagnostics
**KEYTE1** (keyboard) and **CRTAN5** (video/attributes).

The **complete ANK 1426 keyboard** is modeled from KEYTE1's own expected-scancode
grids: every key of the alpha block, function row, keypad and editing block is wired
to a real PC key, with SHIFT/CONTROL make+break, and mapped per the official L1 MOS
PC-keyboard table so a PC keyboard drives the M40 the way L1WSE drives it from an
M24. See **[KEYMAP.md](KEYMAP.md)** and **[KDC.md](KDC.md)** §4–5.

**The factory diagnostic suite passes on every M40-applicable test.**
- **UC3003** (UC central-unit test): zero errors — TRAP (all Z8010 MMU violation
  types, bit-exact VTR/BCS/status semantics), VIENO, TIMER 0/1/2 (incl. the ch1
  vectored interrupt), ACIA (EF68B50P at `0xFF20/22`, polling + interrupt modes),
  INTERRUPT NOT-VECTORED (arbiter NVI) and VECTORED (vector latches `0xFF01`
  timer / `0xFFA0` ACIA), ROM.
- **UCV305** (S.3000 V/SV UC test): all subtests incl. the MASTO master/slave
  flip-flop (`0xFF19`/`0xFF11`/`0xFFB1` bit 6) and the ch1-OUT latch (`0xFF41`
  bit 4); sole counted error = the M44-only MMU1 sub-test self-skipping.
- **MEM813** memory pattern suite and **RAMVID** video-RAM march: zero errors.
  RAMVID exposed a decades-old MAME Z8000 core bug — `COMB @Rd` decoded its
  destination register from the wrong opcode nibble — fixed upstream-ready.
- **6030T6** (disk-D FDU running test): controller-communication, timer,
  interrupt and compatibility tests pass; the remaining subtests verify the
  governo as an MFDU (XU6030, NOM10 jumper) with a 5.25" drive — future work.

- **KEYTE1** (keyboard): the alpha and functions/numerical sections address every
  key by cell and print the scancode each one must return — which makes the test a
  complete keyboard map. Both sections' grids now match the driver key-for-key.

This campaign factory-verified the Z8010 device, the UC interrupt architecture,
the memory and video-RAM subsystems, and fixed two Z8000 core bugs (COMB @Rd,
block-I/O flags) affecting every Z8000 machine in MAME. KEYTE1 additionally
corrected the published scancode map (the letter row was off by one cell) and
exposed a video-attribute bug: LOW LINE was drawn on a fixed scanline instead of
the cell's last one (MC6845 R9), leaving box bottoms a pixel short of their corners.

Remaining high-value work: **M4** — wire the GO363 hard-disk governo (a gate-array
wrapper around MAME's existing **µPD7261** device); confirm the CRTAN5 video-type
register and the character-attribute bit map; and obtain the real `GI 9428DS`
char-gen glyphs. Details in **[HARDWARE.md](HARDWARE.md)** and **[KDC.md](KDC.md)**.
