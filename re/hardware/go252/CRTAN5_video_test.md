# CRTAN5 (011) — video / character / attribute test

Program code **011** on disk B, "**CRTAN5 · *TEST VIDEO***". Alphanumeric
MC6845 / character-generator / attribute display test for the GO252 board.

Analysis so far is from the **load descriptor + embedded strings** (disk-B flat
image `0x74b00`) and the emulator's video model. Full opcode disassembly is still
pending: CRTAN5 relocates into **segment `0x21`** and I have not yet gotten the
monitor's LOAD flow to complete under the automated harness (natural-keyboard
navigation into `1`→`ENTER`→`011`→`ENTER` is timing-fragile), so seg-0x21 dumps
came back empty. The descriptor evidence below is primary, not inferred.

## Load descriptor (disk-B `0x74b00`, the 256-byte catalog entry)

```
+0x000  00 00 00 ff 00 00 0f a0                 header
+0x008  "    CRTAN5    *TEST VIDEO*"            title
+0x03a  04 00                                   (count / flags)
+0x03c  a1 00 0b 42  a1 00 1a e2  a1 00 01 24    load map: <<0x21>>0b42, 1ae2, 0124,
        a1 00 01 20  a1 00 01 00  a1 00 0b 40              0120, 0100, 0b40
+0x074  01 01 02 01 03 01 04 01 05 01 06 01 07 01   7× (loc,len) code-sector table
+0x0c4  "TEST1" … "TEST2" … "TEST3" … "TEST4"    four sub-tests
```

`a1 00 hh ll` = a Z8001 segmented pointer `<<0x21>>0xhhll` (0xA1 = seg 0x21 with the
long-offset flag). So CRTAN5's code + data land in **segment 0x21** — same segment
KEYTE1 uses.

## Sub-tests and their display strings (all extracted verbatim)

```
TEST1  VIDEO FEATURES:
         TYPE...........=      ROWS NO........=
         TOTAL CRT.NO...=      ROW LENGTH.....=
       prompt:  IF OK THEN ENTER ELSE SKIP:
       error :  UNIDENTIFIED ERROR.

       CRT ROM PATTERN          (character-ROM sweep, operator compares visually)

TEST4  attribute matrix:
         O HIGH LINE:   LOW LINE:   LEFT LINE:   RIGHT LINE:
         BLINKING(BL):  HIGH LIGHT(HL):  REVERSE VIDEO(RV):
         LINES + BL:    LINES + HL:      LINES + RV:
```

## Why TEST1 reports an error even when you press "OK"

`IF OK THEN ENTER ELSE SKIP` is the *operator* confirmation for the displayed
pattern — but `UNIDENTIFIED ERROR.` is a **separate automatic check of the video
type**, printed when the type/config read back from the GO252 registers isn't one
CRTAN5 recognises. Pressing ENTER (OK) can't clear it because the type was already
rejected.

Root cause in the emulator (`m40.cpp` `vid_r`):
- reg `0x80/0x81` returns monitor **type 0** + a toggling live-signal bit (`0x08`);
- **every other video register hits `default: return 0xff`.**

TEST1 reads TYPE / ROWS NO / TOTAL CRT.NO / ROW LENGTH from GO252 config registers.
Whichever register holds the type/geometry that CRTAN5 validates is unimplemented
(returns `0xff`), so it fails the "known type" match → `UNIDENTIFIED ERROR`,
independent of the keypress. **Fix needs the exact register + expected value from the
seg-0x21 disassembly** (the remaining blocked step).

## Why TEST4 (attributes) shows nothing — it is NOT the MC6845

The M40 text cell is **two bytes**: a character code + an **attribute byte**. Every
effect TEST4 exercises — high/low/left/right line, blinking, highlight, reverse video
— is encoded in that attribute byte and decoded by the **GO252 board's attribute
logic** downstream of the CRTC. The **MC6845 has no part in per-character attributes**
(it only does addressing/timing/sync and a *cursor* blink).

The emulator's renderer drops all of it (`m40.cpp` `crtc_update_row`):
```c
uint8_t const ch = m_vram[(((ma + col) << 1) + 1) & 0xffff];  // reads ONLY the char (odd) byte
uint8_t bits = (ch >= 0x20 && ch < 0x80 && ra < 16) ? s_chargen[(ch-0x20)*16 + ra] : 0;
```
- the **even/attribute byte is never read** → no reverse/blink/highlight/line ever renders;
- `s_chargen` is an ASCII-0x20..0x7F **placeholder** font → the CRT-ROM sweep and any
  non-ASCII glyph render blank.

So TEST4 is blank because attribute rendering is *unimplemented*, not because of the
missing char ROM.

## How blinking must be implemented (checked against MAME MC6845 drivers)

Blink is **not** the char ROM and **not** the CRTC's character path. On real hardware
it's an attribute-byte bit gated by a **blink flip-flop clocked by the CRTC's VSYNC**
(field rate, divided down). The 6845 only contributes the field timing (and can blink
the *cursor* via R10/R11 bits) — the character blink is external attribute logic.

In MAME the idiom is: derive the blink phase from the frame counter inside
`MC6845_UPDATE_ROW`, and gate the cell on the attribute's blink bit. Confirmed patterns
in-tree:
- `apple/apple2video.cpp`: `m_flash = screen.frame_number() & 0x10;`  (~1.5 Hz)
- `commodore/c65.cpp`:     `blink = (screen().frame_number() & 4) == 4;`
- `falco/falco500.cpp` (a terminal): `bool blink = screen().frame_number() & 0x10;`
- `televideo/tv950.cpp`: attribute byte decoded per-cell in the UPDATE_ROW callback.

Sketch for the M40 renderer (once the attribute-bit layout is decoded from CRTAN5):
```c
uint8_t const attr = m_vram[((ma + col) << 1) & 0xffff];   // even byte = attribute
bool const blink_phase = screen().frame_number() & 0x10;
if (BIT(attr, BLINK_BIT) && blink_phase) bits = 0;         // blink off-phase → blank
if (BIT(attr, REVERSE_BIT))              bits ^= 0xff;      // reverse video
uint8_t fg = BIT(attr, HILIGHT_BIT) ? PAL_BRIGHT : PAL_NORMAL;
// high/low/left/right line = force a run of pixels at the cell edge for this ra/col
```
The exact bit positions (`BLINK_BIT`, `REVERSE_BIT`, …) come from TEST4's
attribute-fill code in seg 0x21 — the same disassembly TEST1 needs.

## Char-ROM reconstruction — not possible from CRTAN5

The "CRT ROM PATTERN" test writes character **codes** to the screen for the operator
to eyeball against a printed reference; it contains **no glyph bitmaps**. So the real
GI 9428DS-2067 font cannot be reconstructed from the test — it needs a physical ROM
dump or a photo of the pattern on real hardware to transcribe. Making the placeholder
font cover more codes is possible but would not match the real ROM.

## Attribute rendering — IMPLEMENTED (provisional bit map)

`crtc_update_row` now decodes the attribute (even) byte and renders all seven
effects; a 3-level palette (off / normal / high-light) and a field-rate blink phase
(`m_screen->frame_number() & 0x10`) were added. Provisional bit map (named constants
`ATTR_*` in `m40.cpp`):

| bit | mask | effect |
|-----|------|--------|
| 0 | 0x01 | HIGH LINE (top edge) |
| 1 | 0x02 | LOW LINE (bottom edge) |
| 2 | 0x04 | LEFT LINE |
| 3 | 0x08 | RIGHT LINE |
| 4 | 0x10 | BLINKING |
| 5 | 0x20 | HIGH LIGHT (bright pen) |
| 6 | 0x40 | REVERSE VIDEO |

Basis: the CRTAN5 attribute-list order + the monitor's observed attribute writes
(`0x00` normal, `0x20`, `0x40`, `0x50`=`0x40|0x10`). **Confirm the exact bit→effect
mapping against CRTAN5's seg-0x21 attribute-fill code** — the line-bit order in
particular is a guess.

## Open / blocked
1. **Disassemble seg 0x21 CRTAN5** — blocked on completing the monitor LOAD under the
   harness. Needed to (a) confirm/correct the attribute bit map above and (b) find
   TEST1's exact type register + expected value.
2. **TEST1 `UNIDENTIFIED ERROR`** — still open: return the correct video-type/geometry
   from `vid_r` (currently non-`0x80/0x81` video regs return `0xff`).
3. Char ROM: obtain a dump or a photo of the CRT-ROM pattern to transcribe glyphs.
