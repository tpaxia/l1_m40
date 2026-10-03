# GO252 character generator: dumped ROM replaces the built-in font

Recorded 2026-10-02, before editing `src/devices/bus/olivetti_l1/go252.cpp`
and `go252.h` in the external MAME tree. The user directed the change.

## Behaviour being changed

The GO252 model drew text from a hand-made 96-character table (codes
`0x20`–`0x7F`, 16 rows each) marked in the source as a "provisional
substitute for the undumped GO252 character generator"; every other code was
drawn blank. The change loads a 4 KB character ROM instead and uses all 256
codes: row `ra` of character `c` is ROM byte `c * 16 + ra`, inverted (the ROM
stores lit pixels as 0).

## The ROM

`reference/roms/ROM L1 M40 BC` is a zip archive (no extension) of six files named
after their own CRC32. One of them, `7096b8f1.bin`, is 4096 bytes: 256
characters × 16 rows, 8 pixels wide, inverted. Rendered, it holds control
symbols at `0x00`–`0x1F`, ASCII at `0x20`–`0x7F`, block and line graphics at
`0x80`–`0x9F`, and accented, Greek and Cyrillic letters above `0xA0`;
unprogrammed positions hold a repeated filler pattern. Glyphs use rows 2–10.

The same archive holds the two halves of the M40 system ROM 6.0 (even and
odd bytes), dumped with data bit 3 stuck at 1: each equals our
`m40rom-6.0` lane with bit 3 forced on. The character ROM does not show that
fault (bit 3 is 0 in many bytes and the glyphs are intact).

## Evidence that it is the GO252 ROM

1. **Hardware.** `reference/Pictures (M40 + spares)/BOARD_INDEX.md`, photo
   `IMG-20260620-WA0116.jpg`: the GO252 carries one ROM, the character
   generator `GI 9428DS-2067`, a 24-pin mask ROM, which suits a 4 KB part.
   The board has no CPU or firmware.
2. **Geometry.** The M40 text screens are 25 rows on a 16-line pitch (CRTAN5
   reports `ROWS NO = 25`, `ROW LENGTH = 80`), matching 16 rows per
   character.
3. **Software.** The DCOS diagnostic CRTAN5 ("TEST VIDEO", disk B, code
   `011`) has a "CRT ROM PATTERN" step that writes every code `0x00`–`0xFF`
   for the operator to inspect, so the original ROM has 256 characters.
   With the dumped ROM the full set displays
   (`runs-archive/chargen-20261002/crtan5-rom-pattern.png` ([screen](screenshots/chargen-20261002__crtan5-rom-pattern.png))); with the built-in
   table everything outside `0x20`–`0x7F` was blank.
4. **The built-in font was copied from this design.** Of its 96 glyphs, 69
   are identical to the ROM's apart from a one- or two-row downward shift;
   the other 26 differ in small details.
5. **Provenance.** It came in the same archive as the M40 system ROM halves.

## What is not established

- The archive's origin ("ROM L1 M40 BC") does not name the machine or board.
- There is no photograph of a real M40 screen to compare with.

## Tests (temporary build, `runs-archive/chargen-20261002/`)

- BCOS II and MOS login screens from the hard disk render correctly
  (`compare.png` shows old and new fonts side by side).
- CRTAN5 runs through its tests, including the ROM pattern.
