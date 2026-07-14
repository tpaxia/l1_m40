# Olivetti M30 / M40 (L1) — ROM Reverse-Engineering & MAME Bring-Up

## 1. Project goal

Reverse-engineer the Olivetti **M40** boot ROM (a **Zilog Z8001** program) to
establish, in as much detail as possible, **how each board is detected and
tested** by the resident power-on autodiagnostic — and from that, derive the
**minimum set of hardware needed to run the self-test and start an IPL**.

That hardware is then reimplemented in **MAME**, and the machine is driven
through a fixed sequence of milestones:

1. execute the **BIOS / resident autodiagnostic** to completion,
2. perform an **IPL** (initial program load),
3. **boot from floppy**, and
4. **detect the hard disk** (as required for installation).

The M40 is the segmented-CPU member of the Olivetti **L1** line; the M30 is its
sibling and shares this ROM family. Two ROM builds are in scope, `REL 4.1` (8 KB)
and `REL 6.0` (16 KB), both banner-dated *17 DEC 82*.

> The service manual splits the resident firmware into **ROM 151** (on
> central-unit boards produced up to Nov 1982) and **ROM 152** (from Nov 1982) — a
> board/hardware generation, *distinct* from the `REL x.x` loader-release number.
> The manual does not tie either REL to 151/152; the Dec-1982 date only *suggests*
> these dumps belong to the 152 era. Treated here as unconfirmed.

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
- A UC042 board photo shows a **32.000 MHz master oscillator**; the CPU clock is a
  divided value (divisor TBD — `/8`→4 MHz likely for this pre-8 MHz generation).
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
  - **Diagnostic console**: code latch `0xFFE0` + a 4-bit indicator at `0xFF64..0xFF6F`.
  - **NMI / READY logic** at `0xFF41`.
  - Config/jumper reads (`0xFFA0`), control latches (`0xFF20`, `0xFF01`).
  - `0xFF80..0xFF8F` — 16-register device, not yet identified (NVI source).
  - `0xF0E0/0xF0E2` = the console latch (`0xFFE0/E2`) via the don't-care bits;
    the reset writes them to clear the console indicator.
  - `0xF0E0/0xF0E2` — a UC latch (the only non-`FF` immediate I/O), to be identified.

### 3.5 Video — **6845-family CRTC**, character display
- Register-select `0x41` (address) / `0x43` (data); type/status at `0x81`.
- **80 × 25** character text (40 × 13 alternate); character cell height
  12/16/17 scan lines depending on monitor type (→ 300/400/425 active lines). The
  character *width* in dots is not yet determined, so horizontal dot count is open.
- Framebuffer at **seg 61 / phys `0xFF0000`**, 2 bytes per character cell.

### 3.6 FDU — floppy governo (IPL source)
- The IPL device search (`0x065c`) is traced: order set by the **ISL switch**
  (`0xFF41` bit 1), priority list `E4`(HDU) `EF`(GIPO) `E1`(FDU) `E0`(MFDU) `E6`(STC),
  each dispatched to a handler. The **FDU/MFDU boot handler is `0x0eae`** — tracing
  its governo command/DMA interface is the next step toward M2/M3.

### 3.7 HDU — hard-disk governo (IPL source + installation target)
- In the IPL search as types `E4` (direct) / `EF` (via GIPO/IEEE-488); highest
  priority when ISL selects HDU-first. Handler `0x1a5e`. Detection needed for M4.

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

| # | Milestone | Done when |
|---|-----------|-----------|
| **M1** | Resident autodiagnostic runs clean | CPU + MMU + RAM + 8253 + video pass; no diagnostic hang; reaches the IPL stage |
| **M2** | IPL | ROM selects an IPL controller and loads the first stage per the priority order |
| **M3** | Boot from floppy | FDU governo modeled well enough to load the OS/monitor image |
| **M4** | Detect HD for installation | HDU governo enumerated and readable so install can target it |

IPL device priority (from the service manual, absent the ISL switch): HDU 5010 →
HDU 6813 → DCU 9448 (fixed) → FDU → MFDU → STC → DCU 9448 (removable).

## 5. Method

- **Round-trippable disassembly.** Each ROM is disassembled to a form that
  reassembles to a **byte-identical** image, so annotations can be added freely
  and always re-verified against the original.
- **Annotate outward from reset**, block by block, keeping every change
  byte-neutral.
- **Model in MAME** device-by-device, matched to exactly what the annotated ROM
  touches, and re-run the milestones after each addition.

## 6. Related work

**L1WSE — Olivetti M24 "L1 Work-Station Emulator"** (see `L1WSE.md`). A separate
reverse-engineering effort on the DOS-side software that turns an Olivetti M24
PC into an L1 graphics workstation / terminal. Different CPU (8086, real mode) and
a different artifact, but the same L1 ecosystem — useful for the host-link
protocol, the display model, and the terminal/keyboard behaviour an L1 host
expects.

## 7. Status

Reverse-engineering is under way from the reset vector outward. Characterised so
far: the reset path and Program Status Area, the diagnostic console + video
display, video-controller detect/init, the **ROM checksum** (algorithm confirmed
to reproduce the stored word), the **Z8010 MMU test + map**, the **8253 timer
test**, and the **video geometry** (80×25 CRTC). Next: the backplane slot scan /
config-table build, then the FDU and HDU governi toward the IPL milestones.
