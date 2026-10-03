# GO252 / ANK keyboard — scancode map

The keyboard's Intel 8049 sends a 1-byte **positional scancode** per key on make;
special/auxiliary inputs send make+break (see below). The recovered ROM proves the
normal scanner is 13×8 and emits raw 1-based matrix positions in `0x01`–`0x68`,
with no ROM translation table. The current MAME table has 101 unique populated
ordinary positions; `0x32`, `0x33`, and `0x45` are absent. The host translates scancode→character via a language
table; the diagnostics compare raw scancodes directly. Because the codes are
**positional, not glyph-based**, every ANK variant that shares the physical key grid
uses the same scancodes — only the printed legends and the present/absent key subset
change.

## Keyboard variants (Olivetti L1 line)

Both keyboards are single-board Olivetti "L1" units (embossed `olivetti L1`) using
the GO252 KDC serial protocol. The dumped large-keyboard controller is an Intel 8049,
not the previously hypothesized MC6801-class MCU. Whether every ANK variant uses the
same controller image/wiring remains to be verified; the diagnostic positional tables
are the authority for the emulated layouts.

### ANK 1426 — 105 keys (the one emulated)

- KEYTE1 layout-select **option 3** ("105 keys, LED lights, no lock keys"); the
  default this driver reports. Photos: `re/ANK1426*.jpg`.
- Function/editing block legended with **BASIC keywords** (RUN, DRAW, OLD, LIST, RES,
  FETCH, EXIT, …) plus **F1–F8** and **S2–S5**.
- This is the layout the scancode tables below were extracted from.

### ANK 1427 — 99 keys (Spanish-legend terminal variant)

- Photographed unit (`re/ANK1427*.jpg`, imgur album `hCxgVMF`): **Spanish legends**
  (`¿Ç`, `Ñ`, `¡`, `£`, `§`), otherwise an **identical physical layout** to the 1426 —
  same QWERTY block, same `*+ / §~ / |← (back-tab)` cluster, same green key + hooked
  `↵` RETURN, same `REPEAT`, `CONTROL`, `> <` and `DEL`/`TAB` edge keys.
- Numeric keypad identical: `CLEAR`(red) `7 8 9 / − 4 5 6 / . 1 2 3 / 0 00 000` and a
  tall keypad-RETURN, same scancodes as the 1426 keypad table below.
- Differs only in the **function/editing block**: **F1–F6** + **S2–S5** (two fewer F-
  keys than the 1426), and a terminal/editing legend set — **RUN, INQ, DEL CHAR, INS
  CHAR, HARD COPY**, back-tab keys, and cursor **↑ ↓ ← →**. This block, plus the
  absent F7/F8, is where the "99 vs 105" (6-key) difference lives.
- Front-panel LEDs: **POWER-ON, READY, L1, L2**.
- **Emulation:** no new mapping needed — the `codes[4][16]` matrix in `m40.cpp` already
  covers every ANK 1427 key; the 1427 is a strict subset of the 1426 positions.

The scancodes below are the **shared, positional** truth for both keyboards.

## ⚠ The diagnostic UI is driven by the numeric KEYPAD, not the main row

The boot prompt (`HIT "ENTER"`) and the monitor menu (`HIT 1..4 + "ENTER"`) read
**keypad** scancodes: 1..0 = `5f 60 5d 57 58 55 4f 50 4d 67`, Return = `52`. The
main number row (`01 04 07 …`) and the alpha RETURN (`38`) are **not** accepted there.
So in the emulator the PC number-row keys and Enter are mapped to the **keypad**
codes (not the physically-faithful main-row codes) — otherwise you cannot select a
menu item or boot. Verified: typing `3` echoes `:3` at the menu; `0x52` boots.

Consequence: KEYTE1's alphanumeric test walks the *main* number row (`01 04 07 …`),
which the current mapping does not emit (the PC digit keys send keypad codes). That
one test row is unreachable unless the PC numpad is repointed at the main-row codes.
Everything else (letters, punctuation, keypad) is unaffected.

## Confidence — read this before trusting a mapping

Not every entry here has the same backing. Three tiers:

1. **Table-verified (trust fully).** The scancode *values* — every byte in the tables
   below — are extracted verbatim from ROM: keypad `seg03:0x00a4`, alpha
   `seg21:0x03c0`. The **keypad char mapping** is verified against the *parallel
   ASCII table* right after `seg03:0x00a4` (`67 68 65…` → `000123456789-.`). And
   **`0x52` = RETURN/CR** is verified empirically (it boots the monitor).
2. **Geometry-grounded (trust for letters/digits).** Letter/digit → key comes from
   the position table `seg21:0x2b40` (row-major diagram cells, parallel to the
   scancode table) overlaid on the physical photos (a QWERTY board). Solid, but not
   echo-tested char-by-char.
3. **Inferred by eye (VERIFY before relying).** Row-tail and special keys — RETURN,
   the green key, `* § ¿Ç`, and the punctuation. I labelled these from the diagram by
   inspection. **This tier is where errors live:** I originally mislabeled `0x37`
   (green key) as RETURN, which broke booting. Cross-checking the position table:
   `0x37` is at row-2 tail (**green**), `0x38` at row-3 tail (**↵ RETURN**).

To promote tier-3 to verified: run KEYTE1's alphanumeric test (now bootable again),
press each highlighted key, and confirm expected==received on screen.

## Sources (live disk-B dump `runs-archive/keyte1-watch-dump/`)

- **Numeric keypad**: monitor xlate table `seg03:0x00a4` (scancodes + parallel ASCII),
  KEYTE1 numeric-test table `seg21:0x308c` — identical.
- **Main alpha block**: KEYTE1 expected-scancode table `seg21:0x03c0` (diagram order),
  paired index-for-index with the position table `seg21:0x2b40` (rows y=1/4/7/10/13).
  `0xFF` = a diagram gap (an untested modifier: SHIFT/CONTROL/KB-MODE/CLEAR).
- **Special/modifier make-break codes**: functional-checks manual (tier 3).

## Numeric keypad (verified exact)

| key | scan | key | scan | key | scan |
|-----|------|-----|------|-----|------|
| 7 | `0x4F` | 8 | `0x50` | 9 | `0x4D` |
| 4 | `0x57` | 5 | `0x58` | 6 | `0x55` |
| 1 | `0x5F` | 2 | `0x60` | 3 | `0x5D` |
| 0 | `0x67` | . | `0x62` | − | `0x59` |
| 00 | `0x68` | 000 | `0x65` | ↵ (numpad, green) | `0x52` |

## Main alpha block (from `seg21:0x03c0` in diagram/physical order)

Row-by-row, left→right, as the diagram (= physical keyboard) is laid out:

```
Row 1 (numbers): DEL=06  1=01  2=04  3=07  4=17  5=1D  6=1E  7=13  8=21  9=24
                 0=2E  '=2C  \=2B  ←(backtab)=31
Row 2 (QWERTY):  TAB=05  Q=03  W=0C  E=08  R=1F  T=11  Y=14  U=19  I=25  O=26
                 P=30  ?=2A  *=36  GREEN=37
Row 3 (ASDF):    [KB-MODE=gap]  A=02  S=09  D=0F  F=0D  G=18  H=15  J=1B  K=1A
                 L=28  ñ/;=22  i/:=2F  §=34  ↵RETURN=38
Row 4 (ZXCV):    [SHIFT=gap]  /=0A  Z=0B  X=0E  C=10  V=20  B=1C  N=16  M=27
                 ,=23  .=2D  -=29  [gap]  )=35
Row 5:           [gap]  SPACE=12  [gap]
```

Consolidated letters/digits (the reliable, most-used subset):

```
A 02  B 1C  C 10  D 0F  E 08  F 0D  G 18  H 15  I 25  J 1B  K 1A  L 28  M 27
N 16  O 26  P 30  Q 03  R 1F  S 09  T 11  U 19  V 20  W 0C  X 0E  Y 14  Z 0B
1 01  2 04  3 07  4 17  5 1D  6 1E  7 13  8 21  9 24  0 2E
SPACE 12  TAB 05  DEL 06  ↵RETURN 38  GREEN 37  keypad-RETURN 52
```

**RETURN / CR — the boot-critical one is `0x52`.** There are three "enter"-ish keys:
the alpha-block big `↵` (**0x38**), the **green** key beside it (**0x37**), and the
numeric-keypad RETURN (**0x52**). The boot `HIT "ENTER" FOR DIAGNOSTIC MONITOR`
prompt and the language translation accept **`0x52`** as CR — `0x37` (green) is *not*
accepted (this is why mapping PC-Enter→0x37 broke booting). The emulator maps PC
**Enter → `0x52`**. (Whether the alpha `↵`=0x38 also yields CR is untested; 0x52 is
the verified path.)

## Auxiliary / modifier inputs (make / break)

| key | make | break |
|-----|------|-------|
| LK (lock) | `0x6F` | `0x77` |
| SH (shift) | `0x6E` | `0x76` |
| CN (control) | `0x70` | `0x78` |
| simultaneous-keys marker | `0xFE` | — |

The firmware independently proves the encoding: its auxiliary pass suppresses
`0x69/0x71` and emits `0x6A`–`0x70` on stable make, `0x72`–`0x78` on stable break.
It does not identify the physical inputs. In particular, the PCB photo also shows
six microswitches beside three rotary controls, so the remaining assignments need a
continuity test or schematic. The ANK1426 (option 3) is "**no lock keys**" — it does
not expose LK in the KEYTE1 diagram.

## EXIT / abort key = `0x3D` (verified)

Every KEYTE1 test loop reads a key and does `cpb rl0,#0x3D ; jp z,<abort>` — at
`0x06e6`/`0x0712`→`0x0850` (back to menu) and `0x09c2`/`0x0a8c`/`0x0afa`/`0x0cb0`
→`0x1236` (cleanup+exit). So **`0x3D` is the EXIT key** and is the clean way to
leave any test. Its diagram cell is fn row 2 position 7 (`seg21:0x2df8` entry
15) — the M40 keyboard has EXIT mid-row-2, where the BASIC-cap variant reads
"LIST". Mapped to PC **End**.

## PC → M40 press table (L1WSE mapping — CURRENT emulator build)

What each PC key sends now, per the official L1 MOS PC-keyboard table (KEYMAP.md).
Use this while driving KEYTE1. `✗` = scancode known but no PC key wired yet.

### Alphanumeric test (walks the ALPHA block, diagram order)
| M40 key highlighted | scancode | press on PC |
|---|---|---|
| DEL | `06` | **Backspace** |
| main-row 1…0 | `01 04 07 17 1D 1E 13 21 24 2E` | **top-row 1…0** (now reachable!) |
| ' | `2C` | **'** |
| \ | `2B` | **\** |
| ← back-tab | `31` | **Left-arrow** |
| TAB | `05` | **Tab** |
| Q W E R T Y U I O P | `03 0C 08 1F 11 14 19 25 26 30` | **q…p** |
| ¿Ç / ? | `2A` | **[** |
| *＋ | `36` | **]** |
| 🟩 green | `37` | ✗ |
| A S D F G H J K L | `02 09 0F 0D 18 15 1B 1A 28` | **a…l** |
| Ñ / ; | `22` | **;** |
| ¡ / : | `2F` | ✗ |
| § | `34` | ✗ |
| ↵ RETURN (alpha) | `38` | ✗ |
| / Z X C V B N M , . | `0A 0B 0E 10 20 1C 16 27 23 2D` | **/ z x c v b n m , .** |
| − (alpha row) | `29` | ✗ |
| ) | `35` | ✗ |
| SPACE | `12` | **Spacebar** |
| SHIFT (make/break) | `6E`/`76` | **LShift** (⚠ make only — break codes not sent) |
| LOCK / CONTROL | `6F/77` / `70/78` | ✗ |

### Functions-numerical section test
| M40 key | scancode | press on PC |
|---|---|---|
| F1…F8 | `44 46 63 5B 53 4B 56 5A` | **F1…F8** |
| S2…S5 | `42 43 41 47` (geometry) | ✗ |
| CLEAR (red) | `49` | **F9** |
| keypad 7 8 9 / 4 5 6 / 1 2 3 | `4F 50 4D / 57 58 55 / 5F 60 5D` | **numpad 7-9 / 4-6 / 1-3** |
| keypad 0 / . / − | `67 62 59` | **numpad 0 / . / −** |
| 00 / 000 | `68 65` | **Ins / Home** |
| ENTER (tall) | `61` | **Enter** or **numpad-Enter** |
| SKIP (tall) | `52` | **PgDn** |
| EXIT | `3D` | **End** (aborts any test cleanly) |
| row-2 unknowns | `39 48 54 5C` | ✗ |
| left tall column | `3A 3B 3C 3E` | ✗ (arrow candidates) |
| right pair column | `51 5E 66 64` | ✗ |
| far-right column | `4C 4E 4A 40` | ✗ (DEL CHAR / INS CHAR / HARD COPY candidates) |
| off-diagram | `3F` | ✗ (REPEAT?) |

## ▶ PRESS SEQUENCE — ANK 1426 physical layout, every key wired

Every M40 key has a PC key. Physical-row order (the tests may walk any order —
press whatever the highlighted cell corresponds to):

### TEST 1 — alphanumerical (alpha block)
```
Delete   1 2 3 4 5 6 7 8 9 0   -   =   Backspace
Tab   q w e r t y u i o p   `   [   F9(=CLEAR)
F11(=KB MODE)   a s d f g h j k l   ;   '   ]   Enter(=RETURN 35)
Shift   \|-102nd-key(=/ left of Z)   z x c v b n m   ,   .   /(=?)
LCtrl(=CONTROL)   Space
REPEAT: no binding needed — the RP cell is display-only (repeat sends no code)
```

### TEST 2 — functions.numerical (F row + keypad)
```
F1 F2 F3 F4 F5 F6 F7 F8      (= M40 F9/F1 … F16/F8; Shift+Fn = F9–F16)
End(=EXIT 3D)
numpad-*(=49 top-left)  numpad-7 8 9
numpad--(=59)  numpad-4 5 6
numpad-.(=62)  numpad-1 2 3
numpad-0(=67)  numpad-+(=00, 68)  NumLock(=000, 65)
numpad-Enter(=tall ENTER 61)   PgDn(=tall SKIP 52)
```

### Function/editing block — COMPLETE (from `photos/SCANCODES_NUMERIC.png`, the
### full TEST 2 grid; legends per the deskthority ANK 1426 photos)
```
row 1:  F9/F1..F16/F8 = 44 46 63 5B 53 4B 56 5A   top-right key = 39 (Esc)
row 2:  \=42(RAlt)  E^=43(F10)  (=41(F12*)  )=47(PrtScr)  ERASE=48(Ins)
        EXIT=3D(End)  LIST=54(ScrLk)  FETCH=5C(Pause)  DEL LINE=3B(Menu)
  * F12 is the MAME UI-mode key (uimodekey F12 in mame.ini, replacing the
    macOS default Delete so M40 DEL=06 works). The fn "(" duplicates Shift+8;
    remap temporarily in Tab->Input if a test demands its cell.
alpha \: left-of-Z (0A) = PC \| (also the ISO 102nd key)
keypad: 49(*)  7 8 9 = 4F 50 4D
        59(−)  4 5 6 = 57 58 55
        62(.)  1 2 3 = 5F 60 5D
        67(0)  00=68(numpad +)  000=65(NumLock)
tall:   upper = SKIP 52 (PgDn)   lower = ENTER 61 (numpad Enter)
right block:  RES=51(RCtrl)  |←=4C(Home)   →|=3A(PgUp)
              AUTO#=5E(numpad /)  ↑=4E(Up)  ↓=3C(Down)
              OLD=66(LWin)   ←=4A(Left)    →=3E(Right)
              RUN=64(RWin)   DRAW=40(LAlt) PR ALL/NO PR=3F(CapsLock)
```

## ⚑ Remaining checks

1. **Modifier test**: SHIFT/CONTROL send make+break (6E/76, 70/78) — the `78`
   the alpha screen showed in the CONTROL cell now clears on key release. No
   LOCK key exists (6F is ANK1427-only).
2. The 3D key sits at fn row-2 position 6 (BASIC caps say SAVE there); the M40
   caps presumably read EXIT — it both clears its cell and aborts tests.

## Open items
- **Function/editing block** (F1-F8, S2-S5, RUN, DRAW, OLD, LIST, RES, FETCH,
  AUTO#, DEL-LINE, ERASE, SAVE, arrows, CLEAR): separate scancodes, tested by
  KEYTE1's "FUNCTIONS-NUMERICAL SECTION TEST" — not yet extracted (EXIT `0x3D`
  above is now known).
- A few punctuation identities in rows 3-4 depend on the language legend
  (ñ/;, i/:, §, the `*`/`?` keys) — the *scancode* is exact; the glyph is
  layout-dependent.
- Row/physical correlation confirmed by pairing `0x04c0`↔`0x2b40`; a run of the
  alphanumerical test (labels on the diagram) is the final visual check.

## Mapping revision (L1WSE-faithful)
The emulator now follows the official L1 MOS PC-keyboard table (MOS Programmer
Guide §7, `L1WSE_KEYS.pdf`): PC top row → main-row codes 01 04 07 17 1D 1E 13
21 24 2E; PC numpad → keypad codes 4F 50 4D / 57 58 55 / 5F 60 5D / 67 62 59,
numpad-Enter=61, Ins=00(68), Home=000(65); both Enters → 61; **EXIT = End (3D)**;
**SKIP = PgDn (52)** (officially Shift+Tab); DEL = Backspace (06). Digit
PORT_CHARs live on the numpad so natural-keyboard typing reaches the monitor.
Function/editing-block scancodes (arrows, F-keys, S2-S5, CLEAR, IC/DC…) are still
unextracted — needed to complete the manual's table (candidate table structures
near seg21:0x2e6d in the KEYTE1 dump).

## Function/numeric section — EXTRACTED (KEYTE1 tables @ seg21:0x2df8/0x2e5a)

49 keys: scancode list at `seg21:0x2e5a`, (y,x) position pairs at `0x2df8`,
identity by diagram geometry against the ANK1426/1427 photos (the test itself
addresses keys as ROW/COLUMN — "EXIT KEY ROW/COLUMN" strings at 0x1f32/0x1f60).

| block | keys → scancodes | confidence |
|---|---|---|
| F-row (y1, 8 keys) | **F1=44 F2=46 F3=63 F4=5B F5=53 F6=4B F7=56 F8=5A** | geometry (photo: F1-F8 across the section top) |
| second row (y3, 9) | `39`, **S2=42 S3=43 S4=41 S5=47**, `48`, **EXIT=3D** (behaviorally verified), `54`, `5C` | S2-S5 geometry; 39/48/54/5C labels open |
| left tall column (x1) | `39`(y3) `3A/3B`(y6) `3C/3E`(y10) | codes exact; labels open (arrow/editing candidates) |
| keypad | **CLEAR=49** (the red key — new), `−=59 .=62`, digits/00/000 as verified | CLEAR by photo position (top-left of keypad) |
| right tall pair column (x27) | `51`, **SKIP=52** (tall, verified), `5E`, **ENTER=61** (tall, verified), `66`, `64` | 51/5E/66/64 labels open |
| far-right column (x33) | `5C`(y3) `4C`(y5) `4E`(y7) `4A`(y9) `40`(y11) | codes exact; labels open (DEL CHAR/INS CHAR/HARD COPY/arrows candidates per the 1427 photo) |
| position-less entry | `3F` | 49th code, off-diagram (REPEAT?) |

Scancode→token map candidate at `0x2ec0` (values 0xE0-0xF2 = monitor function
tokens) — decode pending. Label closure: run KEYTE1's function-section test and
read each highlighted key's row/column on screen.
