# KDC — GO252 video / keyboard governo (behavioral & emulation model)

The **GO252** (nome logico **`FE`**) is the standard L1 alphanumeric video + keyboard
board — the *KDC* (keyboard/display controller). [HARDWARE.md §5](HARDWARE.md) covers
its physical inventory, CRTC register map, and screen geometry. **This document covers
the behavioral model** reverse-engineered during MAME bring-up: the interrupt path, the
keyboard serial protocol and scancodes, the two ANK keyboards, and the character-cell
attribute encoding.

Provenance tags as in HARDWARE.md: **[ROM]** boot ROM, **[DISK]** disk diagnostic
(KEYTE1 / CRTAN5), **[MAN]** manual, **[EMU]** emulation-model decision,
**[PHOTO]** board/keyboard photo.

---

## 1. Register interface (behavioral view)

Accessed at the board's slot I/O window (address bits 15-12 = slot, low byte =
register). Video/geometry registers are in HARDWARE.md §5; the keyboard/interrupt
side is:

| Reg (low byte) | Dir | Function |
|---|---|---|
| `0x00/0x01` | R | **status** — bit1 = TX ready (transmitter empty), bit2 = RX byte available **[DISK]** |
| `0x01` | W | **control** — bit5 = TX/completion IRQ enable, bit6 = direct-send handshake, bit7 = RX IRQ enable **[DISK]** |
| `0x02/0x03` | R/W | **data** — keyboard byte in / command byte out **[DISK]** |
| `0x20/0x21` | W | **interrupt vector** latch (value returned on VI-ACK) **[EMU]/[DISK]** |
| `0x41/0x43` | W | MC6845 address / data (HARDWARE.md §5.1) |
| `0x81` | R | status / monitor type + live-signal bit 3 (HARDWARE.md §5.1) |
| `0xFF` | R | type-ID → **`0xFE`** (routes boot to the video self-test) **[ROM]** |

The resident FE/KDC keyboard handler also uses the fixed latches **`0xFF20`**
(status/control) and **`0xFF22`** (byte-data) — see HARDWARE.md §4.

---

## 2. Interrupt model — vectored interrupt (VI)

The KDC drives the Z8001 **VI** line (vectored interrupt, line 1) — the **same line the
FDU governo uses**. Two *independent* enables live in control register `0x01`:

- **bit 7 = RX interrupt enable** → raise VI when a keyboard byte is available
  (status bit 2). This is the analogue of the FDU's `EN100` enable.
- **bit 5 = TX / completion interrupt enable** → raise VI when the transmitter is empty
  (command accepted / completion), so a send handshake can post its completion.

On the CPU VI-ACK cycle the KDC supplies its **vector** (programmed via `0x20/0x21`).

**Two emulation lessons (both were bugs first):**

1. **The interrupt must be gated on the hardware enable bits**, not on a software flag.
   An early model armed the KDC IRQ from the *vector write*; that is wrong — real
   hardware raises an interrupt purely from register state / a bus side-effect. The
   correct gate is `control(0x01).bit7` (RX) or `.bit5` (TX). **[EMU]**
2. **KDC and FDU share the VI line**, so the VI-ACK handler must return the KDC vector
   **only when a KDC source is enabled *and* pending**, otherwise fall through to the
   FDU. A missing check let the KDC hijack the FDU's vector and stall the floppy path.
   **[EMU]**

---

## 3. Keyboard serial protocol

The keyboard is a microprocessor unit on a serial link; the KDC presents it to the CPU
as the status + data registers above. **[DISK]/[MAN]**

- **Make/break:** the keyboard MCU sends a **1-byte positional scancode** on key *make*.
  Modifier keys additionally send a *break* code on release (see §4).
- **Read-ID command:** host writes **`0x02`** to the data path; the keyboard replies
  **`0xFB`** followed by a **configuration byte** encoding the layout + strap options.
  Observed reply `0xF1` = **USA ASCII layout**. **[DISK]**
- **Direct-send handshake:** control-reg bit 6 gates a direct host→keyboard byte.
- The host translates positional scancodes → characters via a language table; the
  diagnostics compare raw scancodes directly.

---

## 4. Scancodes (positional)

Scancodes are **positional, not glyph-based** — a given physical key emits the same
byte on every ANK variant. Three confidence tiers:

- **Table-verified** — the *values* are extracted verbatim from ROM/diagnostic tables;
  the **keypad** char mapping is verified against a parallel scancode→ASCII table.
- **Geometry-grounded** — letter/digit → key from the on-screen diagram position table
  overlaid on the physical keyboard (a QWERTY board). Solid, not echo-tested.
- **Inferred** — row-tail punctuation and special keys (labelled by eye; verify before
  trusting).

**Numeric keypad (verified):**

| 7 `4F` | 8 `50` | 9 `4D` | | 4 `57` | 5 `58` | 6 `55` |
|--------|--------|--------|-|--------|--------|--------|
| **1 `5F`** | **2 `60`** | **3 `5D`** | | **0 `67`** | **. `62`** | **− `59`** |

Keypad **RETURN = `52`** (this is the CR the boot/menu accept — see the note below).

**Alpha block letters / digits (geometry-grounded):**

```
A 02  B 1C  C 10  D 0F  E 08  F 0D  G 18  H 15  I 25  J 1B  K 1A  L 28  M 27
N 16  O 26  P 30  Q 03  R 1F  S 09  T 11  U 19  V 20  W 0C  X 0E  Y 14  Z 0B
1 01  2 04  3 07  4 17  5 1D  6 1E  7 13  8 21  9 24  0 2E
SPACE 12   TAB 05   DEL 06   ↵RETURN 38   green-key 37
```

**Modifier keys (make / break):** LOCK `6F`/`77`, SHIFT `6E`/`76`, CONTROL `70`/`78`;
simultaneous-keys marker `FE`. These occupy the **left column** of the letter rows and
are checked by KEYTE1's make+break test — they are *not* letters. **[DISK]/[MAN]**

**EXIT / abort key = `3D`** — every diagnostic test loop aborts on this code. **[DISK]**

> **Critical for driving diagnostics:** the boot prompt (`HIT "ENTER"`) and the monitor
> menu (`HIT 1..4 + ENTER`) read the **numeric-keypad** scancodes
> (`1..0 = 5F 60 5D 57 58 55 4F 50 4D 67`, RETURN `52`) — **not** the main number row
> (`01 04 …`) or the alpha RETURN (`38`). A PC keyboard must send keypad codes for
> those keys or menu/boot input does nothing. **[EMU]**

---

## 5. The ANK keyboards

Both are single-board **Olivetti L1** units sharing one physical matrix (hence the same
positional scancodes); they differ only in legends and the present-key subset. **[PHOTO]**

| Model | Keys | Notes |
|---|---|---|
| **ANK 1426** | 105 | LED lights, no lock keys; **BASIC-keyword** function legends (RUN/DRAW/OLD/LIST/RES/FETCH/EXIT, F1-F8, S2-S5). The layout the driver reports (KEYTE1 layout-select option 3). |
| **ANK 1427** | 99 | **Spanish** legends (`¿Ç`, `Ñ`, `¡`, `£`, `§`); terminal/editing function block (F1-F6, S2-S5, RUN, INQ, DEL CHAR, INS CHAR, HARD COPY, cursor arrows). Front LEDs POWER-ON/READY/L1/L2. Identical positional matrix → same scancodes; the emulator mapping covers it as a strict subset. |

The MAME driver maps a standard PS/2 keyboard onto this matrix (letters/keypad/space/
tab, **Esc = EXIT `3D`**), with the PC number-row + Enter routed to the keypad codes so
menu/boot navigation works.

---

## 6. Character-cell attributes (video)

Each screen cell in the seg-61 framebuffer is **2 bytes: even = attribute, odd =
character** (HARDWARE.md §5.3). The attribute effects are decoded by the board's
**`MB15651` gate array**, *not* the MC6845 — the CRTC only does addressing / timing /
cursor. **Blinking is a field-rate (VSYNC-gated) board function**, not a CRTC feature
and not in the character ROM.

CRTAN5's attribute test names the effects: **HIGH/LOW/LEFT/RIGHT LINE, BLINKING,
HIGH LIGHT, REVERSE VIDEO** (+ combinations). **[DISK]**

**Attribute bit map — PROVISIONAL** (from the CRTAN5 effect order + the resident
monitor's observed attribute writes `00/20/40/50`; the line-bit order is a guess
pending the CRTAN5 attribute-fill disassembly): **[EMU]/[DISK]**

| bit | mask | effect |
|-----|------|--------|
| 0 | `0x01` | HIGH LINE (top edge) |
| 1 | `0x02` | LOW LINE (bottom edge) |
| 2 | `0x04` | LEFT LINE |
| 3 | `0x08` | RIGHT LINE |
| 4 | `0x10` | BLINKING (field-rate) |
| 5 | `0x20` | HIGH LIGHT (full-intensity pen) |
| 6 | `0x40` | REVERSE VIDEO |

The MAME renderer implements all seven, with a 3-level palette (off / normal / high
light) and a frame-counter blink phase. The **character generator `GI 9428DS-2067`** is
a mask ROM, **not yet dumped**; the emulator currently renders text with the **Olivetti
M20/L1 house font** (a 5×7 dot-matrix set, ASCII `0x20`–`0x7E`). The M20 is the same L1
product line, and a photo of a live **L1/ESE** console shows the same font — matching
slashed zero (`Ø`) and glyph shapes — so this is very likely the GO252 char set, pending
a ROM dump or a CRTAN5 CRT-ROM-pattern capture to confirm glyph-exact. Codes outside
`0x20`–`0x7E` (graphics/special) still render blank. **[EMU]/[PHOTO]**

---

## 7. Diagnostics that exercise the KDC (disk B)

| Program | Code | What it tests |
|---|---|---|
| **KEYTE1** | — | keyboard-MCU scancode correspondence, LEDs, modifier make/break, layout select |
| **CRTAN5** | **011** | video type/geometry (TEST1 "VIDEO FEATURES"), CRT-ROM character pattern, attribute matrix (TEST4) |
| **RAMVID** | — | video-RAM pattern test |

**CRTAN5 TEST1 shows `UNIDENTIFIED ERROR` even on operator-OK:** the `IF OK THEN ENTER`
prompt is a visual confirm, but `UNIDENTIFIED ERROR` is a *separate* automatic
video-type check. The emulator returns monitor type 0 from `0x81` but `0xFF` for other
video-config registers, so the type CRTAN5 validates is unrecognised → error regardless
of the keypress. Fixing it needs the exact type register + value from CRTAN5's code.
**[EMU]/[DISK]**

---

## 8. Emulation status

**Implemented:** type-ID `0xFE`; MC6845 text video; keyboard VI (gated on control
bits 5/7) + serial status/data protocol + read-ID response; positional scancode matrix
with PS/2 mapping (Esc = EXIT); character-attribute rendering (reverse / high light /
blink / four lines) with a 3-level palette; the M20/L1 house font as the char generator. **Open:** confirm
the attribute bit map and the CRTAN5 video-type register against the seg-0x21
disassembly; verify the font glyph-exact (CRTAN5 CRT-ROM pattern) or dump the
`GI 9428DS` mask ROM; add the graphics/special glyphs above `0x7E`.
