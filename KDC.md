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

The resident FE/KDC keyboard handler also uses the UC-side interface at **`0xFF20`**
(status/control) and **`0xFF22`** (data) — now identified as the **UC EF68B50P ACIA**
(the keyboard byte stream rides its RX; the UC3003 ACIA test exercises the same chip
with a TXD→RXD loopback). Its VI vector comes from the UC latch `0xFFA0`. See
HARDWARE.md §4.

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

**ENTER = `61` and SKIP = `52`** — two distinct terminator keys by the keypad. Both
end line input (which is why either boots and drives menus), but go/skip prompts
distinguish them: the DCOS monitor (disk-A `seg03:0x1bf2`) decodes raw `61` as
ENTER/go-on and `52` as SKIP/go-back. The alpha RETURN (`35`) is *also* accepted as
a line terminator (boot + menu verified). The emulator maps PC-numpad-Enter → `61`,
PC-Enter → `35`, PgDn → `52`.

**Alpha block — VERIFIED** against KEYTE1's own expected-code grid
(`re/SCANCODES_ALPHA.png`; scancode table `seg21:0x03c0` paired index-for-index with
the cell table `seg21:0x2b40`): **[DISK]**

```
row 0:  DEL 06   1 01  2 04  3 07  4 17  5 1D  6 1E  7 13  8 21  9 24  0 2E
        -= 2C    ~^ 2B    BS 31
row 1:  TAB 05   Q 03  W 0C  E 08  R 1F  T 11  Y 14  U 19  I 25  O 26  P 30
        @' 2A    [{ 36    CLEAR 37 (the red key)
row 2:  KB-MODE 02   A 09  S 0F  D 0D  F 18  G 15  H 1B  J 1A  K 28  L 22
        ;+ 2F    *: 34    ]} 38    RETURN 35
row 3:  SHIFT    \ 0A (left of Z)   Z 0B  X 0E  C 10  V 20  B 1C  N 16  M 27
        , 23     . 2D     ? 29
row 4:  CONTROL   SPACE 12   REPEAT (sends no code — it makes the KDC auto-repeat)
```

Earlier releases of this document listed the letter row shifted by one cell
(`A 02 … S 09 …`); that was a geometry error, corrected here from the live grid.

**Modifier keys (make / break):** SHIFT `6E`/`76`, CONTROL `70`/`78`, LOCK `6F`/`77`;
simultaneous-keys marker `FE`. They occupy the **left column** of the letter rows and
are checked by KEYTE1's make+break test — they are *not* letters. LOCK exists only on
keyboards that carry the key (no ANK 1426 cell emits `6F`). **[DISK]/[MAN]**

**Function / keypad block — VERIFIED** (`re/SCANCODES_NUMERIC.png`, KEYTE1 TEST 2;
tables `seg21:0x2e5a` + `0x2df8`): **[DISK]**

```
F9/F1..F16/F8 = 44 46 63 5B 53 4B 56 5A     top-right key 39
row 2:  \ 42   E^ 43   ( 41   ) 47   ERASE 48   EXIT 3D   LIST 54
        FETCH 5C   DEL LINE 3B
keypad: * 49 / − 59 / . 62 / 0 67 · 00 68 · 000 65 · digits as above
        tall keys: SKIP 52 (upper), ENTER 61 (lower)
right block:  RES 51   |← 4C   →| 3A        AUTO# 5E   ↑ 4E   ↓ 3C
              OLD 66   ← 4A    → 3E         RUN 64     DRAW 40   PR ALL/NO PR 3F
```

**EXIT / abort key = `3D`** — every diagnostic test loop aborts on this code; its cell
is function row 2, position 6. **[DISK]**

> **Critical for driving diagnostics:** the boot prompt (`HIT "ENTER"`) and the monitor
> menu (`HIT 1..4 + ENTER`) read the **numeric-keypad** scancodes
> (`1..0 = 5F 60 5D 57 58 55 4F 50 4D 67`, ENTER `61`, SKIP `52`) — **not** the main
> number row (`01 04 …`) or the alpha RETURN (`38`). A PC keyboard must send keypad
> codes for those keys or menu/boot input does nothing. **[EMU]**

---

## 5. The ANK keyboards

Both are single-board **Olivetti L1** units sharing one physical matrix (hence the same
positional scancodes); they differ only in legends and the present-key subset. **[PHOTO]**

| Model | Keys | Notes |
|---|---|---|
| **ANK 1426** | 105 | LED lights (POWER-ON/READY/L1/L2), no lock keys; **BASIC-keyword** function legends (RUN/DRAW/OLD/LIST/RES/FETCH/AUTO#/ERASE/SAVE/DEL LINE, F9/F1…F16/F8) and BASIC keywords on the alpha key *fronts* (REM/IF/THEN/GOTO/PRINT…). The layout the driver reports (KEYTE1 layout-select option 3; the US unit identifies as `KUSA02`). Photographs: deskthority thread t=14649. **[PHOTO]** |
| **ANK 1427** | 99 | **Spanish** legends (`¿Ç`, `Ñ`, `¡`, `£`, `§`); terminal/editing function block (F1-F6, S2-S5, RUN, INQ, DEL CHAR, INS CHAR, HARD COPY, cursor arrows). Front LEDs POWER-ON/READY/L1/L2. Identical positional matrix → same scancodes; the emulator mapping covers it as a strict subset. |

The MAME driver maps a standard PC keyboard onto this matrix 1:1 by character and
position wherever the PC has the key, per the **official L1 MOS PC-keyboard table**
(MOS Programmer Guide 4002570 L, §7 pp. 7-14…7-16 — the mapping L1WSE itself uses;
Note 1 of that table makes unlisted keys 1:1). Full transcription and the complete
per-key binding list are in **[KEYMAP.md](KEYMAP.md)**. Highlights: **PC top row →
the M40 main number row**, **PC numpad → the M40 keypad** (the two digit groups stay
distinct, as on the real machine), **EXIT on End** (`3D`), **SKIP on PgDn** (`52`;
officially Shift+Tab, which a single matrix key can't express), DEL on Delete (`06`)
and BS on Backspace (`31`), **F1–F8 giving F9–F16 under Shift** exactly as the manual
specifies, since that is the M40's own shift level. The digit *characters* are
declared on the numpad bits so natural-keyboard (automated) typing lands on the
keypad the monitor menus actually read.

On macOS, set `uimodekey F12` — MAME's default UI-mode key there is Delete, which
would otherwise swallow the M40 DEL key. The layout uses every key of a 104-key
board, so the UI toggle must orphan one M40 key; F12 (`(`, `41`) is the cheapest
donor because `(` is also Shift+8. **[EMU]**

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
light) and a frame-counter blink phase. The **LOW LINE** attribute must be drawn on
the cell's *true* last scanline, taken from **MC6845 R9** (the firmware programs
`R9 = 0x10`, i.e. 17-line cells) — a hardcoded line 15 leaves the bottom edge one
scanline high, where it no longer meets the LEFT/RIGHT verticals at the corners.
Visible on any boxed diagnostic screen. **[EMU]** The **character generator `GI 9428DS-2067`** is
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
| **RAMVID** | 010 (disk B) | video-RAM march test — **passes** (`ERR 00000`); marches the 4 KB bank via logical seg `0x1B` → phys `0xFF0000` |

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
