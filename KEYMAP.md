# L1 MOS keyboard ↔ PC keyboard mapping

Transcribed from **MOS Programmer Guide** (doc `4002570 L`), §7 *"Emulation of the
L1 MOS keyboard"*, pages 7-14 … 7-16 (scan: `re/L1WSE_KEYS.pdf`). This is the
**official Olivetti mapping** used by the L1WSE / WSELAN / OL1EMU emulators to
drive an L1 host from a standard IBM/Olivetti PC keyboard — and therefore the
reference layout for the MAME driver's PC-keyboard mapping.

Per the manual: the keyboard version (one of 14 national layouts, or the PB
105-key with the `T_KEYB` driver) is selected in CONF / WSECONF / OLICONF.
**Note 1: any key not listed below has the same function on both keyboards**
(letters, digits, ENTER, the two digit groups, etc. map 1:1).

## Tab. 7-3 — Correspondency between the L1 MOS and PC keyboards

### Editing / control keys (p. 7-14)

| L1 keyboard | PC keyboard |
|---|---|
| →\| (tab) | SHIFT F10 |
| CNTL →\| | ALT PGUP |
| \|← (back-tab) | SHIFT F9 |
| CNTL \|← | ALT PGDN |
| CNTL ↓ | CTRL F10 |
| CNTL ← | CTRL F7 |
| CNTL → | CTRL F8 |
| CNTL ↑ | CTRL F9 |
| CNTL CL_ERR | CTRL F6 |
| CNTL HOME | ALT HOME |
| CHANGE WINDOW | ALT F7 |
| CLEAR | ALT F6 |
| DC (delete char) | DEL |
| DL (delete line) | SHIFT F8 |
| ERASE | ALT F5 |
| **EXIT** | **END** |
| CNTL EXIT | CTRL END |
| HALT PRG | ALT → |
| CNTL HALT PRG | ALT ← |
| HARD COPY | ALT F10 – SHIFT SCR PRT |

### Function / program / soft keys (p. 7-15)

| L1 keyboard | PC keyboard |
|---|---|
| IC (insert char) | INS |
| IL (insert line) | SHIFT F7 |
| SEND | CTRL F5 |
| **SKIP** | **SHIFT TAB** |
| F5 | F5 – PGDN |
| F6 | F6 – PGUP |
| F11 … F16 | SHIFT F1 … SHIFT F6 |
| F17 | ALT END |
| F18 | ALT 5 |
| F19 | ALT ↓ |
| F20 | ALT ↑ |
| F21 / F23 / F25 / F27 | CTRL F4 / F3 / F2 / F1 |
| F22 / F24 / F26 / F28 | ALT F4 / F3 / F2 / F1 |
| P1 / SHIFT P1 | ALT ↓ / CTRL PGDN |
| P2 / SHIFT P2 | ALT ↑ / CTRL PGUP |
| P3 / SHIFT P3 | ALT PGDN / CTRL HOME |
| P4 / SHIFT P4 | ALT PGUP / CTRL → |
| P5 / SHIFT P5 | ALT HOME / CTRL ← |
| S2 / CNTL S2 | CTRL F4 / ALT F4 |
| S3 / CNTL S3 | CTRL F3 / ALT F3 |
| S4 / CNTL S4 | CTRL F2 / ALT F2 |
| S5 / CNTL S5 | CTRL F1 / ALT F1 |

> Transcription caveats (scan quality): the F19/F20 vs P1/P2 rows and the
> F21-F28 vs S2-S5 rows carry the same PC combinations in the scan — on the L1
> keyboards the S-keys and the high F-numbers are overlapping names for the same
> functions on different models. Verify against `re/L1WSE_KEYS.pdf` before
> relying on an individual ambiguous row.

### Notes (p. 7-16, abridged)

1. Keys not specified have the same function on each keyboard.
2. PC **ALT F8** saves the screen page to the MS-DOS file `SCRPRT` (append mode;
   not available in graphics mode).
3. Under CONTSW, **SHIFT SHIFT** passes control between MS-DOS and the emulator.
4. PC **ALT F9** exits the emulator to MS-DOS (not possible under CONTSW).
5. **BREAK** has no effect under L1WSE/WSELAN; under OLIEMU it causes an error.
6. PC **ALT F10** makes an alphanumeric hard copy on the PR/A (OLIEMU) or PR/B
   (WSELAN) printer.
7. **SHIFT SCR PRT**: with the HCBC/HCBM driver loaded, alphanumeric or graphic
   hard copy on the /B printer; without it, the standard MS-DOS hard copy.

## The physical keyboard: ANK 1426 (US layout, "KUSA02")

Identified from the deskthority photo set (viewtopic t=14649, badge "olivetti
L1" / "ANK 1426 made in italy") and cross-checked against KEYTE1's on-screen
expected-code grids. Key fronts carry the L1 BASIC keywords (REM, IF, THEN,
GOTO, PRINT…). Layout:

| Row | Keys |
|---|---|
| 0 | DEL · `!1 "2 #3 $4 %5 &6 '7 (8 )9 ⌀0` · `−=` · `~↑` · BS |
| 1 | TAB · `Q…P` · `@´` · `{[` · CLEAR (red) |
| 2 | KB MODE · `A…L` · `+;` · `*:` · `}]` · RETURN `↵` |
| 3 | SHIFT · `/` · `Z…M` · `, .` · `?` · SHIFT · `↵` |
| 4 | CONTROL · SPACE · REPEAT |
| fn | `F9/F1 … F16/F8` · EXIT / `\ E↑ ( )` ERASE SAVE LIST FETCH · DEL LINE |
| pad | `* 7 8 9 / − 4 5 6 / + 1 2 3 / 0 , .` · ENTER (tall) · SKIP (tall) |
| col | RES `\|←` `→\|` / AUTO# `↑` `↓` / OLD `←` `→` / RUN DRAW PR ALL·NO PR |

No S-keys, no P-keys, no LOCK, no 00/000 keys on this layout (those belong to
other L1 keyboards, e.g. the ANK 1427 WP variant — LK's `6F/77` make/break
codes are ANK 1427). F9–F16 are the *shifted level* of the F1–F8 keys.

## Realization in the MAME m40 driver

MAME maps *physical* PC keys to M40 **positional scancodes** (see
[KDC.md](KDC.md) §4), 1:1 by character/position per Note 1; combination-only
rows of Tab. 7-3 get single-key stand-ins. Verified codes (KEYTE1 grids + live
echo):

| M40 key | scancode | PC key |
|---|---|---|
| digits `1…0` | `01 04 07 17 1D 1E 13 21 24 2E` | top row 1…0 |
| letters | Q`03` W`0C` E`08` R`1F` T`11` Y`14` U`19` I`25` O`26` P`30` A`09` S`0F` D`0D` F`18` G`15` H`1B` J`1A` K`28` L`22` Z`0B` X`0E` C`10` V`20` B`1C` N`16` M`27` | same letter |
| DEL / TAB / BS | `06` / `05` / `31` | Delete / Tab / Backspace |
| `−=` / `~↑` | `2C` / `2B` | `-_` / `=+` |
| `@´` / `{[` / `}]` | `2A` / `36` / `38` | `` `~ `` / `[{` / `]}` |
| `+;` / `*:` | `2F` / `34` | `;:` / `'"` |
| `/` (left of Z) / `?` | `0A` / `29` | 102nd key (`\|` next to LShift) / `/?` |
| `, .` SPACE | `23 2D 12` | same |
| RETURN `↵` | `35` | Enter (accepted by the monitor as terminator) |
| KB MODE | `02` | F11 |
| CLEAR | `49` | F9 |
| SHIFT / CONTROL | `6E/76` / `70/78` | Shift / LCtrl (make/break emulated) |
| keypad `7 8 9 / 4 5 6 / 1 2 3 / 0 . −` | `4F 50 4D 57 58 55 5F 60 5D 67 62 59` | numpad (digit chars live here — the monitor menus read the keypad) |
| keypad ENTER / SKIP | `61` / `52` | numpad Enter / PgDn |
| F1–F8 (F9–F16 shifted) | `44 46 63 5B 53 4B 56 5A` | F1–F8 (Shift+Fn = F9–F16, matching Tab. 7-3's F11…F16 → SHIFT F1…F6) |
| EXIT | `3D` | End |
| REPEAT | none | unbound (PC auto-repeat; per L1WSE) |

**Function/editing block — complete** (per `re/SCANCODES_NUMERIC.png`, the full
TEST 2 expected-code grid; legends per the deskthority ANK 1426 photos):

| M40 key | code | PC key |
|---|---|---|
| fn row 2: `\` `E↑` `(` `)` ERASE **EXIT** LIST FETCH DEL LINE | `42 43 41 47 48` **`3D`** `54 5C 3B` | RAlt F10 F12† PrtScr Ins **End** ScrLk Pause Menu |
| top-right key (right of F16/F8) | `39` | Esc |
| keypad top-left `*` / `.` / 00 / 000 | `49` / `62` / `68` / `65` | numpad `*` / numpad `.` / numpad `+` / NumLock |
| SKIP (upper tall) / ENTER (lower tall) | `52` / `61` | PgDn / numpad Enter |
| RES, `\|←`, `→\|` | `51 4C 3A` | RCtrl, Home, PgUp |
| AUTO#, `↑`, `↓` | `5E 4E 3C` | numpad `/`, Up, Down |
| OLD, `←`, `→` | `66 4A 3E` | LWin, Left, Right |
| RUN, DRAW, PR ALL/NO PR | `64 40 3F` | RWin, LAlt, CapsLock |

† **MAME UI-mode key = F12** (`uimodekey F12` in `mame.ini`): on macOS MAME's
default UI toggle is Delete, which would swallow the M40 DEL key (06). The map
uses every key of a 104-key board, so the toggle must orphan one M40 key — F12
is the chosen donor because its `(` (41) duplicates Shift+8. While set, the fn
`(` cell needs a temporary remap (Tab → Input) if a KEYTE1 run demands it.

Also: the alpha `\` left of Z (0A) sits on both PC `\|` and the ISO 102nd key;
the fn-row `\` (42) is on RAlt.

Corrections against earlier guesses: **CLEAR = `37`** (alpha row 1 tail, the
red key; `49` is the keypad `*`), the keypad **00/000 keys are real** (`68`/
`65` — translate table `seg21:0x300c` maps them to 0xEE/0xED and `62`→`'.'`),
EXIT `3D` sits at fn row-2 position 6, and there is **no LOCK key** (no cell
carries `6F`; the SHIFT/CONTROL make/break pairs `6E/76`, `70/78` are
emulated).
