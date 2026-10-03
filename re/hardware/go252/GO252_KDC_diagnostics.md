# GO252 / KDC video-keyboard diagnostic reverse engineering notes

This note collects the photo evidence, ROM anchors, collaudi/manual mapping,
disk-B catalogue, and initial disassembly anchors for the GO252 video/keyboard
governo. GO252 is the standard alphanumeric video/keyboard board for the target
M30/M40 path; disk B also contains tests for related graphics/color/workstation
video-keyboard hardware, so those are called out separately.

## Board photo

Photo index:

```text
reference/Pictures (M40 + spares)/BOARD_INDEX.md
reference/Pictures (M40 + spares)/IMG-20260620-WA0116.jpg
```

`BOARD_INDEX.md` identifies this as:

```text
GO252 - Video / keyboard (KDC), type FE
MC68B45P (MC6845 CRTC), MB15651 gate array (GA 01),
2x TMM2016AP-15 video SRAM, GI 9428DS-2067 MK3L character generator
```

Visible/significant ICs:

- `MC68B45P` - MC6845-family CRT controller.
- `MB15651` - large gate array/custom glue device.
- `TMM2016AP-15` x2 - video SRAM.
- `GI 9428DS-2067 MK3L` - character generator mask ROM.
- Many 74LS/74S glue devices.

The character generator is the board's only ROM-like device. There is no CPU
firmware on GO252; the UC programs the board directly.

## Hardware applicability from manual

The concise Functional Checks hardware list identifies the alphanumeric
video/keyboard controllers as:

```text
VIDEO/KEYBOARD CONTROLLER: G0157, G0252, G0224 (A/N)
                           G0207 + G0157       (Graphic)
                           G0255 + G0252       (Graphic)
```

So GO252 is directly relevant to the standard alphanumeric video/keyboard path,
and may also be paired with a separate graphics board in some configurations.
Color graphics controllers (`G0259 + G0260 + G0261`) are not the physical GO252
board in the photo.

## ROM anchors

ROM `m40rom-6.0` gives the minimal boot/display model:

```text
reference/roms/m40rom-6.0
```

Important routines:

```text
0x0280  early scan: read slot register 0xff, if value is 0xfe run video test
0x0594  configuration scan: read slot register 0xff for every slot
0x0bc6  video self-test / CRTC init
0x0c44  per-monitor-type CRTC tables
```

Definite ROM register map:

```text
0xff  type-ID register; GO252 returns 0xfe
0x81  status/type; low 3 bits select one of 8 CRTC tables, bit 3 is a live
      signal/retrace bit polled for a change
0x41  MC6845 address register
0x43  MC6845 data register
0x01  control; ROM writes 0x03 before live-signal polling
0x6a  enable normal video after successful self-test
```

ROM `0x0bc6` sequence:

```asm
0bc6: rl1 = 0x81; inb rl2,@r1; r2 &= 7
0bd0: choose CRTC table from 0x0c44
0bee: rl1 = 0x41; outb register index
0bf6: rl1 = 0x43; outb register value
0bfe: rr2 = seg 61 offset 0x0000
0c0c: write/read-test video framebuffer
0c1c: rl1 = 0x01; rl0 = 0x03; outb control
0c22: rl1 = 0x81; poll bit 3 for a toggle
0c3c: rl1 = 0x6a; outb enable-normal-video
```

The framebuffer is MMU segment 61, physical `0xff0000`, with 2 bytes per
character cell. ROM tests `0x0800` words, i.e. `0x1000` bytes. For the normal
80x25 display, 2000 cells x 2 bytes = 4000 bytes, matching that window.

## Relevant manual tests

The concise Functional Checks chapter 6 is the relevant section:

```text
6. VIDEO/KEYBOARD TEST PROGRAM
6.1 RAMVID  video RAM test
6.2 CRTAN5  trivalent alphanumeric video test
6.3 CRTGR2  graphic video test
6.4 KEYTE1  keyboard test
6.5 GRAPH3  colour video controller test
6.6 T31103  graphic colour video regulation/test
6.7 TKEY04  line-1 keyboard test using graphic 14-inch colour display
```

For the photographed GO252 board, the highest-value tests are:

```text
RAMVID  - writes character sequences into video RAM and displays a grid pattern.
CRTAN5  - alphanumeric MC6845/character/attribute display test.
KEYTE1  - keyboard microprocessor code correspondence and LED tests.
```

`CRTGR2`, `GRAPH3`, `T31103`, `TKEY04`, `WSVID6`, and `WSKEY6` are still useful
context, but include graphics/color/workstation hardware beyond bare GO252.

Manual highlights:

```text
RAMVID:
  Checks video controller RAM by writing a character sequence into RAM and
  displaying the resulting test pattern. Errors name RAM chip and bank.

CRTAN5:
  Displays video type, number of rows, total characters, and row length.
  Tests ROM character sequence, screen fills, and attributes:
  high/low/left/right line, blinking, highlight, reverse video, and combinations.

KEYTE1:
  Checks correspondence between bytes from the keyboard microprocessor and
  requested characters, plus LED indicators. It tests alpha keys, function/numeric
  keys, LEDs/special keys, and shift behavior. Special key codes documented:
  LK press/release = 0x6f/0x77, SH = 0x6e/0x76, CN = 0x70/0x78,
  simultaneous keys = 0xfe.
```

## Disk image and catalogue

Relevant image:

```text
reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD
```

Extraction and catalogue:

```sh
python3 tools/imd.py \
  "reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD" \
  extract /tmp/diskB.bin
python3 tools/dml_catalog.py list /tmp/diskB.bin
```

Relevant catalogue entries:

```text
idx ext loc   len  flat_sec  flat_off  bytes  name
 10  00   2182  1b      1833  0x72900   6912  RAMVID80840810
 11  00   2408  01      1867  0x74b00    256  CRTAN581841109
 12  00   2410  09      1875  0x75300   2304  CRTGR281841109
 13  00   2412  19      1877  0x75500   6400  KEYTE183851212
 14  00   2438  2b      1915  0x77b00  11008  GRAPH381850329
 15  00   2582  2f      2041  0x7f900  12032  T3110381850329
 16  00   2896  15      2217  0x8a900   5376  TKEY0483851212
 19  00   33f2  07      2881  0xb4100   1792  WSVID684880222
 20  00   3790  29      2991  0xbaf00  10496  WSKEY684880222
```

Note that the disk-B DML layout overlaps some video/keyboard regions. `KEYTE1`
starts inside the area covered by `CRTGR2` if interpreted as simple flat
contiguous files. Treat these as diagnostic overlays/shared regions, not as
fully independent modern files.

## Generated disassemblies

Repository-local disassemblies:

```text
re/disassembly/diagnostics/go252/diskB_RAMVID_72900_74400.dis
re/disassembly/diagnostics/go252/diskB_CRTAN5_74b00_74c00.dis
re/disassembly/diagnostics/go252/diskB_CRTGR2_75300_75c00.dis
re/disassembly/diagnostics/go252/diskB_KEYTE1_75500_76e00.dis
re/disassembly/diagnostics/go252/diskB_GRAPH3_77b00_7a600.dis
re/disassembly/diagnostics/go252/diskB_T31103_7f900_82800.dis
re/disassembly/diagnostics/go252/diskB_TKEY04_8a900_8be00.dis
re/disassembly/diagnostics/go252/diskB_WSVID6_b4100_b4800.dis
re/disassembly/diagnostics/go252/diskB_WSKEY6_baf00_bd800.dis
```

The current disassembly set is about 17k lines.

## Disk-B string evidence

Embedded program strings confirm the tests and behavior:

```text
RAMVID     *TEST RAM-VIDEO BY MARCH*IS RUNNING
CHANGE CHIP RAM  XXXX BANK XX

CRTAN5    *TEST VIDEO*
CRT ROM PATTERN
VIDEO FEATURES : TYPE= ROWS NO= TOTAL CRT.NO= ROW LENGTH=
HIGH LINE / LOW LINE / LEFT LINE / RIGHT LINE
BLINKING(BL) / HIGH LIGHT(HL) / REVERSE VIDEO(RV)

KEYTE1 KEYBOARD TEST PROGRAM - R:25.11.1985
ALPHANUMERICAL SECTION TEST
FUNCTIONS-NUMERICAL SECTION TEST
LAMPS AND SPECIAL KEYS TEST
FREE RUNNING KEYBOARD
KEYBOARD LAYOUT SELECT
KEYBOARD JUMPERS STATUS
RECEIVED BYTE(S) FROM KEYBOARD
```

The `KEYTE1` payload also includes national keyboard table names and layout
variants, including international, Latin/Farsi, Latin/Arabic, Germany, Portugal,
Spain, Denmark, France, Greek, Hebrew, Italy, Japan, Norway, Sweden/Finland,
Switzerland, USSR, Great Britain, USA ASCII/OCA, and Kana variants.

## Low-level disassembly anchors

### CRTC register access

Disk-B video code repeats the ROM CRTC access convention. In
`diskB_CRTGR2_75300_75c00.dis` and the overlapping `KEYTE1` area:

```asm
75686: rl1 = 0x41
75688: outb @r1,rl5    ; select MC6845 register
7568a: rl5++
7568c: rl1 = 0x43
7568e: ret             ; caller writes/reads MC6845 data through 0x43

75690: rl5 = 0x10
75692: call helper above
75694: inb rh7,@r1
75696: call helper above
75698: inb rl7,@r1
```

This independently confirms:

```text
0x41  MC6845 address register
0x43  MC6845 data register
```

The same area also reads `0x81`:

```asm
756ea: rh1 = 0x81
756ec: rr2 = display string/table pointer
756f2: call common helper
```

### Video RAM / framebuffer path

`RAMVID` exercises a mapped memory window, not just the CRTC ports. It writes and
reads display data, then uses the monitor/runtime output helpers to render and
compare the RAM test pattern.

Useful `RAMVID` anchors:

```asm
72d50..72d5a:
  clear/write repeated words through rr2 target pointer

72d5c..72d8a:
  use selected output/input helper ports and update bits in target RAM

72d9a..72dea:
  validate an address range, read four bytes from an I/O-selected path, return
  nonzero on mismatch

72e72..72ea4:
  write four bytes, read four bytes back, compare with cpsdrb
```

This aligns with the manual's RAMVID description and the ROM's segment-61
framebuffer test. The monitor/runtime helpers obscure whether all RAMVID accesses
go directly to physical `0xff0000` or via a diagnostic abstraction; the ROM path
is the clean source for the boot framebuffer address.

### Keyboard test payload

`KEYTE1` contains large keyboard layout and national-table data plus strings for
operator-guided key tests. Strong facts from manual + strings + MAME resident
driver tracing:

```text
The keyboard has its own microprocessor.
The host receives positional/key bytes from that keyboard path.
KEYTE1 validates key byte correspondence and LED control.
Special key make/break byte values:
  LK 0x6f / 0x77
  SH 0x6e / 0x76
  CN 0x70 / 0x78
  simultaneous keys 0xfe
LEDs checked: READY, L1, L2, SHIFT
```

The standard GO252 keyboard path is no longer completely opaque. MAME tracing of
disk B shows resident FE/KDC support code in logical segment `0x1d`:

```text
0x1d:03f0  FE control/status helper
0x1d:02a4  direct UC/KDC byte interrupt entry, VI vector 0x28
0x1d:068e  descriptor-driven FE/KDC interrupt entry, VI vector 0x2c in the observed PSA
0x1d:0910  data-ready interrupt entry
0xff20     UC/KDC status-control path used by the handler
0xff22     UC/KDC byte-data path used by the handler
```

The live PSA dumped after disk-B boot had PSAP at logical segment 0 offset
`0x0200`. Since the Z8001 vector table begins at `PSAP + 0x3c`, vector `0x28`
uses the entry at `0x028c`; the observed entry `9d00 02a4` dispatches to
`0x1d:02a4`. That is the path used by the diagnostic monitor's first "press
Enter to boot" keyboard input. A posted Enter was consumed as byte `0x0d` after
`0xff20` returned status bit 2 set; MAME sees these even ports on the high byte
lane (`raw=04ff` and `raw=0dff`, `mask=ff00`).

The FE-slot low-byte `0x01` register is a control/status latch: the helper keeps
a shadow byte, writes it to the FE register, and reads the same register back.
In MAME's I/O tap this appears as even offsets (`0x1f00` for source register
`0x01`, `0x1f40`/`0x1f42` for source `0x41`/`0x43`), so use the disassembly
source constants for the actual Z8001 byte-port values.

The exact bit assignments for the FE latch and `0xff20` status byte are still
being decoded. Some direct I/O in `WSKEY6` is for workstation/ELB keyboard
hardware and should not be folded into the standard GO252 model without a
caller/hardware match.

## Current GO252 model

Defensible model so far:

1. GO252 is the standard alphanumeric video/keyboard governo, type `0xfe`.
2. It contains an MC6845-family CRTC, gate array, two video SRAMs, and a GI
   character-generator mask ROM; it has no board CPU firmware.
3. The board is slot-windowed like other governos: high address selects the slot,
   low byte selects the board register.
4. Minimal boot/display requires:
   - `0xff` type ID returning `0xfe`
   - `0x81` status/type with monitor type in bits 0..2 and a toggling bit 3
   - MC6845 index/data at `0x41/0x43`
   - framebuffer at physical `0xff0000` / segment 61
   - control/enable writes to `0x01` and `0x6a`
5. Disk-B `RAMVID` and `CRTAN5` validate video RAM, character ROM patterns, and
   text attributes.
6. Disk-B `KEYTE1` proves the keyboard is a separate microprocessor-style path
   with positional/key bytes, LEDs, national layouts, and special make/break
   codes. Runtime tracing shows the resident handler takes bytes through the
   `0xff20`/`0xff22` UC/KDC path and FE register-`0x01` handshaking. The
   diagnostic-monitor direct byte path is vector `0x28 -> 0x1d:02a4`; bit-level
   assignments beyond `0xff20` bit 2 as data-ready remain open. `KEYTE1`,
   `TKEY04`, and `WSKEY6` now load under MAME, but the current KDC model can
   leak the monitor `GO` byte into the loaded diagnostic's first parameter; see
   `keyboard/GO252_keyboard_reverse_engineering.md`.
7. Disk-B graphics/color/workstation tests are useful for comparison, but not all
   apply to bare GO252.

## Next work

1. Build a proper call map for `KEYTE1` after separating shared/overlapped DML
   regions from the keyboard-specific payload.
2. Fix the KDC byte queue/latch/ack semantics exposed by the keyboard diagnostics:
   the monitor `GO` byte can be consumed by the loaded diagnostic's first
   parameter prompt.
3. Decode the bit meanings in the FE register-`0x01` shadow byte and `0xff20`
   status byte by tracing a successful `KEYTE1` run and LED commands.
4. Decode the second byte of the 2-byte video character cell into attributes by
   following `CRTAN5` attribute-fill code.
5. Compare `RAMVID` memory operations with ROM segment-61 framebuffer setup to
   separate direct framebuffer writes from monitor/runtime abstractions.
6. Treat `GRAPH3`, `T31103`, `TKEY04`, `WSVID6`, and `WSKEY6` as related but
   non-GO252-primary until their hardware path is explicitly mapped.
