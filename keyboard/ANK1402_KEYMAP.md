# ANK1402 scancodes and US PC keyboard bindings

## Status and host-layout requirement

The host is a standard US PC keyboard. **Do not require QZERTY typing.**
An emulated keyboard's printed legends, transmitted positions and host bindings
are three separate things. Mapping PC W to the position which BCOS translates
as W preserves QWERTY typing even if that position carries W on a QZERTY board.
Punctuation, shifted digits and national-layout selection need separate testing;
a photo-correlated physical map alone does not establish US character behavior.

2026-09-10 correction: the photo-driven MAME replacement has been **withdrawn**.
The committed KUSA/QWERTY mapping remains the baseline, supported by the extracted
diagnostic tables and positional grids. Keycaps can be customized: photographs
do not prove a model's immutable function assignments or national layout.
Existing `KEYMAP.md` contains contradictory CLEAR assignments; do not combine
its legends with those in these photos. No new native mapping changes were
committed or pushed. A complete corrected US 102-key profile is still pending.

## Images actually inspected

- [ANK1402 complete keyboard](<photos/WhatsApp Image 2026-08-30 at 10.00.54.jpeg>)
- [ANK1402 with cover removed](<photos/WhatsApp Image 2026-08-30 at 10.09.02.jpeg>)
- [ANK1402 function/keypad detail](<photos/WhatsApp Image 2026-08-30 at 10.12.48.jpeg>)
- [ANK1426 QWERTY/BASIC keyboard](photos/ANK1426.jpg)
- [ANK1426 QWERTY alpha detail](photos/ANK1426_2.jpg)
- [ANK1427 Spanish QWERTY keyboard](photos/ANK1427_overhead.jpg)

The ANK1426 is QWERTY/US-style, but its punctuation is not a modern PC US ANSI
layout. The ANK1427 shown is Spanish, not US. The photos supplied in ANK1402 show
Italian QZERTY legends; they are the reference for this physical keyboard, not
an instruction to rearrange the user's PC typing.

## Evidence boundaries

- Recovered `80491402.MCU`: normal matrix scan positions produce codes 01–68;
  auxiliary switches use distinct make/break codes. No ASCII or national-layout
  translation table is present in that firmware. See `M40_8049_KEYBOARD.md`.
- [KEYTE1 alpha grid](photos/SCANCODES_ALPHA.png) and
  [function grid](photos/SCANCODES_NUMERIC.png): positional code assignments.
- Photos: key legends at matching physical positions. Correlating the grids to
  another keyboard variant is evidence, not an electrical continuity test of it.
- BCOS K02733 `KITA02.1`: software meanings. This is separate from firmware.
  A different table can assign a different function to the same physical code.

## Function-key correlation

Codes are hexadecimal. Host bindings below describe the **withdrawn proposal**,
not the active MAME bindings. Retained only as an audit trail; do not use this
column as operating instructions. The photo legends identify these particular
specimens, not guaranteed hardware-model differences.

| Code | ANK1402 photo legend / position | ANK1426 photo legend | Withdrawn PC proposal |
|---|---|---|---|
| 06 | ESC | DEL | Escape |
| 31 | Backspace arrow, above Return | BS | Backspace |
| 35 | Alpha Return arrow | Alpha Return arrow | Enter |
| 37 | Green, unlabelled key | Red CLEAR | Unassigned |
| 49 | Red CLEAR | Keypad `*` | Right Ctrl |
| 51 | END | RES | End |
| 3D | EXIT | SAVE | F12 |
| 39 | F18/F17 | EXIT | F9 |
| 52 | Upper white bar, unlabelled | Upper bar | Page Down |
| 61 | Lower black bar, unlabelled | Lower bar | Keypad Enter |
| 44 46 63 5B 53 4B 56 5A | F9/F1 … F16/F8 | Same paired legends | F1 … F8 |
| 54 | F20/F19 | LIST | F10 |
| 48 | HALT PGM | ERASE | Pause |
| 5C | IL/IC | FETCH | Insert |
| 3B | DL/DC | DEL LINE | Delete |
| 4C | Back-tab arrow | Same arrow | Home |
| 3A | Forward-tab arrow | Same arrow | Page Up |
| 4E 3C 4A 3E | Up, Down, Left, Right | Same arrows | Corresponding arrows |
| 5E | S3 | AUTO# | F11 |
| 66 | S4 | OLD | Left Alt |
| 64 | S5 | RUN | Unassigned |
| 40 | H.COPY / CH.WND | DRAW | Print Screen |
| 3F | Diagonal home arrow | PR ALL / NO PR | Unassigned |
| 42 43 41 47 | `/ * - +` | Backslash, E-arrow, `(`, `)` | Corresponding keypad operators |
| 59 | Keypad comma | Keypad minus | Right Alt |
| 62 | Keypad point | Keypad plus | Keypad decimal |
| 68 65 | Keypad 00, 000 | Keypad comma, point | Scroll Lock, Num Lock |

The ANK1426 photo clearly labels **SAVE at 3D and EXIT at 39**. Earlier notes
called 3D EXIT based on its diagnostic abort behavior; software use is not proof
of a particular keyboard's printed legend.

### ENTER and RESET: executable evidence

For K02733 BCOS, physical keypad ENTER **61** translates to **6088**. Physical
CLEAR **49** translates to **609E**. The error loop at **12:22D8–22E6** repeatedly
reads a key and compares its low byte with **9E**, ignoring other keys until it
matches. RES-labelled position **51 on the ANK1426 is not that key**.

Headless run `runs-archive/bcos-boot.EeDOUV/` tested:

`keypad 86 → keypad Enter → physical 49 → keypad 0909 → keypad Enter`

The premature Enter produced the error; 49 acknowledged it, retained the two
digits, and the remaining digits completed the date. The 119-second capture
shows SYS. This tests scancodes, not the newly assigned physical PC bindings.

The BCOS utility manual, PDF page 153 of
`reference/Manuals (Stefano Marinelli + Olivrea)/bcosII.pdf`, describes correction with
cursor keys, DEL CHAR, INS CHAR and RESET, and removal of KE errors using RESET.
Backspace 31 is not a substitute for DEL CHAR in a numeric field.

## Remaining validation

1. Exercise US host letters, punctuation, shifted digits and modifiers through
   the disk's actual keyboard table, not just positional injection.
2. Verify physical PC Right Ctrl produces only 49 and PC keypad Enter only 61.
3. Check error acknowledgement, cursor movement, deletion and successful date
   submission with the final host profile; retain the unmodified firmware codes.
4. Resolve REPEAT's auxiliary input before assigning a scan code. Do not confuse
   the physical REPEAT key with the firmware's repeat token 80.
5. Confirm the unlabelled lock/green keys and provide access to the remaining
   unassigned functions without requiring Windows/Menu keys.

The interactive BCOS launcher does not alias top-row digits or ordinary Enter
to keypad positions. The former convenience profile was removed at the user's
request; main and keypad inputs must remain distinct.
