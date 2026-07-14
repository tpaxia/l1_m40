# L1WSE — Olivetti M24 "L1 Work-Station Emulator"

Reverse-engineering notes on `L1WSE.EXE` and its companion drivers.

> **Status:** living document. Findings are derived by static disassembly
> (`ndisasm`, 16-bit real mode) and data inspection of the binaries. Unless noted,
> addresses are **segment offsets** as the program sees them (load-module base =
> file offset `0x200`, so `file = seg + 0x200`).

## Contents

- [Part I — The emulator (`L1WSE.EXE`)](#part-i--the-emulator-l1wseexe)
  - [1. Overview](#1-overview)
  - [2. Executable format](#2-executable-format)
  - [3. Driver architecture & interrupt map](#3-driver-architecture--interrupt-map)
  - [4. Host connection & block protocol](#4-host-connection--block-protocol)
  - [5. Host-byte → OSKAR-screen interpreter](#5-host-byte--oskar-screen-interpreter)
- [Part II — The driver suite](#part-ii--the-driver-suite)
  - [6. OSKAR display driver (`OSKEM.EXE`)](#6-oskar-display-driver-oskemexe)
  - [7. Keyboard extension (`T_KEYB.COM` + `KEY*.TIB`)](#7-keyboard-extension-t_keybcom--keytib)
  - [8. Async line driver (`ASYNC2.EXE`)](#8-async-line-driver-async2exe)
- [Appendix A — file inventory](#appendix-a--file-inventory)
- [Appendix B — key data offsets in `L1WSE.EXE`](#appendix-b--key-data-offsets-in-l1wseexe)

---

# Part I — The emulator (`L1WSE.EXE`)

## 1. Overview

`L1WSE.EXE` turns an **Olivetti M24** PC into a graphics **workstation / terminal**
that talks to a host machine through a cluster-style communications controller.

The emulator itself does **no serial, screen, or keyboard I/O**. At startup it
verifies four resident drivers are present and then drives them through software
interrupts. It is the front-end that ties those drivers into a terminal session.

### 1.1 Companion drivers

All are resident TSRs shipped in the same directory.

| File | Vector | Banner string | Role |
|------|--------|---------------|------|
| `OSKEM.EXE`  | **INT 60h** (AH=01–0Dh) | `OSKAR driver installed`        | screen / graphics workstation output |
| `ASYNC2.EXE` | **INT 14h** (AH=40–4Bh) | `ASYNC COMM.2 driver installed` | RS-232 serial line to host |
| (parallel)   | **INT 17h** (AH=40–43h) | printer driver                  | print / `SCRPRT` screen-copy |
| `T_KEYB.COM` | INT 9/16 hook + `.TIB`  | `TIB KEYBOARD HANDLER`          | national / terminal keyboard remap |
| `HCBDRV`     | **INT 60h** block mode + INT 5 hook | signature `HCBDRV`  | Host Communications Block link to controller |

### 1.2 Startup driver probes

| Resource | Probe | Success condition |
|----------|-------|-------------------|
| OSKAR display | `INT 14h AX=4800` + M24 video ext `INT 10h AX=48xx/49xx/4Axx` | `AH=FF01/FF02/FF03` |
| Printer | `INT 17h AX=4300` | driver present |
| Async comm | `INT 14h AX=4800` | driver present |
| National keyboard | keyboard-table presence check | table loaded |

If a probe fails, the emulator aborts with a fatal message:

```
FATAL  error :OSKAR driver not installed
FATAL  error :OSKAR graphics driver not installed
FATAL  error :printer driver (parallel interface) not installed
FATAL  error :ASYNC COMM   driver not installed
FATAL  error :NATIONAL KEYBOARD not specified
```

## 2. Executable format

| Property | Value |
|----------|-------|
| Type | 16-bit real-mode MS-DOS `MZ` executable |
| Size | 10,557 bytes |
| Memory model | tiny (single code+data segment) |
| Relocations | 20 |
| Entry point | `CS:IP = 0000:0434` |
| Source language | hand-crafted 8086 assembly (no HLL runtime) |

The single segment interleaves code and data; the program reads its own
configuration bytes at fixed low offsets and carries character-translation tables
inline.

## 3. Driver architecture & interrupt map

### 3.1 Interrupt map

| Vector | Direction | Purpose |
|--------|-----------|---------|
| `INT 60h` | L1WSE → OSKAR / HCBDRV | display driver **and** host block driver; function in `AH`, `AL=0` |
| `INT 14h` | L1WSE → ASYNC2 | extended async line driver |
| `INT 17h` | L1WSE → printer | extended printer driver |
| `INT 10h` | L1WSE → M24 video BIOS | Olivetti video mode / attribute calls |
| `INT 05h` | — | print-screen; also used to detect `HCBDRV` by signature |
| `INT CEh` | L1WSE **exports** | 13-function host-link device API (installed by L1WSE) |
| `INT 21h` | L1WSE → DOS | console, file, device I/O |

Interrupt-use histogram (whole binary): INT 21h ×22, INT 10h ×13, INT 60h ×11,
INT 14h ×8, INT 17h ×6, INT 5 ×3, INT CEh ×2.

### 3.2 INT 60h driver-stub library (`0x2276`–`0x2400`)

A bank of far procedures (`retf N`, HLL far-call convention) marshal stack
arguments into registers and issue `INT 60h` with a function number in `AH`.

| `AH` | stub | Purpose |
|------|------|---------|
| 01 | `0x2276` | init / open |
| 02 | `0x2289` | **block send** — scatter/gather from a `{count, ptr…}` descriptor array (≤`0xC8` bytes) |
| 03 | `0x2284` | **block receive** |
| 04 | `0x227F` | block variant |
| 05 | `0x2343` | positioned op (4 args) |
| 06–0A | `0x236E`–`0x2392` | simple ops (get/put/status) |
| 0B | `0x239B` | control |
| 0C | `0x23A4` | control (args) |
| 0D | `0x23C9` | control |

### 3.3 INT 14h ASYNC2 line functions (as used by L1WSE)

| `AH` | Meaning | Args |
|------|---------|------|
| 40 | open line | `BX`=line, `CX:DX`=params (`[0x00]`,`[0x02]`,`[0x04]`) |
| 41 | **transmit one byte** | `AL`=char |
| 42 | **receive one byte** | returns `AH=0` byte in `AL` / `AH=1` no-more / else error |
| 43 | line control | `BX`=line |
| 44 | status / flush | `BX`=line |
| 45/46/47/4B | extended status | `BX`=line |
| 48 | presence check | returns `AX=FF02` |

Received bytes drain into a ring buffer at `[si+0x432]` (count `[0xC32]`, read
cursor `[0xC34]`; fill routine `0x17DF`).

## 4. Host connection & block protocol

**Model:** named-host, block request/response through a cluster controller — not a
point-to-point serial pipe.

### 4.1 Connect handshake (`0x12C7`–`0x134C`)

| Step | Action |
|------|--------|
| 1 | Print `"name of HOST machine  : "` (`INT 21h/AH=09`, string `0xCFC`) |
| 2 | Read the name into `[0xD89]` (`INT 21h/AH=0A`, max `0xFF`, length `[0xD8A]`) |
| 3 | Space-pad the name to a fixed **14-character** field; set block length `[0xC34]=0x10` |
| 4 | Send the **connect block** (padded name) to the controller (`0x199C`, INT 60h func 7) |
| 5 | Issue link-control commands `[0xC44]` ← `0x0A`, `0x0B`, opt. `0x09` (`0x1ADC`) |
| 6 | Send **terminal-config block** (`[0xD89]=0x000B`) packing mode bytes `[0x0D]`/`[0x0E]` |

Command codes select pre-built command blocks (map at `0x193D`):

| `[0xC44]` | command block |
|-----------|---------------|
| `0x0A` | `[0xEA1]` |
| `0x0B` | `[0xEA9]` |
| `0x0C` | `[0xEB1]` |
| other  | `[0xEB9]` |

### 4.2 Block protocol (`0x181C`–`0x1927`, dispatcher `0x1B27`)

| Aspect | Detail |
|--------|--------|
| Send | INT 60h **func 2** writes block (`[0xD89]`, length `[0xC34]`) |
| Receive | INT 60h **func 3** reads a reply block (buffer `0x28`=**40 bytes**) into `[0xD89]`; descriptor `[0xECF]` gives count+ptr |
| Flow control | driver busy `0x80` normalized to **`0x91`** (`0x1B32`); on `0x91`, decrement retry counter `[0xC38]` and loop |
| Framing | 4-byte block header copied to `[0xE89]` / `[0xE91]` (two 16-bit fields) |
| Ack/release | INT 60h **func 7** then **func A** (`0x1927`/`0x1932`) |
| Errors | single letter in `[0x419]`, shown as `LINE ERROR : <O/S/B/I/R…>` |

### 4.3 DOS-device veneer — L1WSE's INT CEh driver (`0x1E80`)

L1WSE installs its own **INT CEh** handler (ends in `iret`): a **13-entry jump
table** (`call [bx+0x1DBD]`, function in `AL≤0x0C`) mapping the block link onto DOS
semantics, returning through a tail that sets **CF from AH** (carry = error).

| Function | Action |
|----------|--------|
| connect | command `0x0C`, polled (`0x91`); set `[0x1DBC]=1`; `INT 21h AX=3D88` (open host for **read**, mode `0x88`) |
| disconnect | command `0x0B`; clear `[0x1DBC]`; `INT 21h AX=3D89` (open **write** side, mode `0x89`) |
| read / write / seek(5) / status | in between |

Once connected, the host session behaves like an **openable named device with a
read handle and a write handle**.

### 4.4 Two interchangeable transports (config byte `[0x0C]`)

| Transport | Path | Notes |
|-----------|------|-------|
| **`HCBDRV`** | INT 60h block mode | Host Communications Block. Detected by matching the 6-byte signature `"HCBDRV"` at the INT 5 handler+3 (`0x1B9B`, `repe cmpsb`), setting `[0x431]` |
| **`ASYNC2`** | INT 14h serial | plain RS-232, char-at-a-time into the `[0x432]` ring buffer |

## 5. Host-byte → OSKAR-screen interpreter

The core of the emulator is a state machine that consumes the received host stream
and re-encodes it into OSKAR display-control sequences. It is RX-driven: the main
loop enters it only when received-byte count `[0xC32] > 0`.

### 5.1 Data flow

```
 controller/host ─► receive buffer [0x432]            refilled by:
        │              (count [0xC32], cursor [0xC34])   INT 60h func 3 (block) or
        ▼                                                INT 14h AH=42 (serial)
 fetch next byte  (0x1AB5 → 0x1789)
        ▼
 dispatch on control byte  (interpreter @ 0x1360)
        ▼
 build OSKAR ESC sequence in [0xD89] block
        ▼
 emit to OSKAR ─►  block mode ([0xC]≠0): INT 60h func 2  (0x19BE)  ← local OSKAR driver
                   char  mode ([0xC]=0): INT 14h AH=41   (0x1737)  ← serial OSKAR terminal
```

### 5.2 Session modes (`[0xC44]`)

| `[0xC44]` | entry | sub-language |
|-----------|-------|--------------|
| `0x0A` | `0x14F5` | **structured field records** (attributes / field defs) |
| `0x09` | `0x1630` | secondary record mode |
| other  | `0x13A4` | **character / cursor-positioning** stream |

### 5.3 Character / cursor stream (`0x13A4`–`0x14DC`)

Fetch a host byte (`0x1AB5`) and dispatch:

| Host byte | Handler | Action |
|-----------|---------|--------|
| `0x14` | `0x14DD` | local op (status/print; sets error `F`=0x46 on failure) |
| `0x19` | `0x1B3A` | driver op (INT 60h func 7/A path) |
| `0x1A` | `0x1B4B` | driver op |
| `0x1C` | `0x1B82` | driver op (INT 60h func 5) |
| `0x45` `'E'` | `0x1BB7` | block send (field transmit) via INT 60h func 2 |
| `0x6A` `'j'` | `0x1409` | **cursor / position command** (reads 1 parameter byte) |
| `0xA9` | `0x13D0` | prefixed variant — fetch one more byte, then re-dispatch |
| else | `0x14D0` | treated as displayable data |

### 5.4 OSKAR escape encoding (built at `0x1409`)

The `0x6A` position command reads a sub-type into `[0xC47]` and emits:

```
ESC(0x1B)  0x04  <subtype + 0xF0>  <operand…>
```

| Element | Encoding |
|---------|----------|
| Command opcode | `0x04` |
| Sub-type byte | biased **`+0xF0`** |
| Coordinates | word biased **`+0x2020`** (row and column each `+0x20`) — printable/space-offset encoding, cf. VT52 `ESC Y row+0x20 col+0x20` |
| Sub-type `2` | operand is literal `0x5F` (`'_'`) |
| other sub-types | three raw operand bytes (`CH,CL,DL`) |

The sequence is assembled in the `[0xD89]` block (length byte `[0xD8A]`, payload
from `[0xD8B]`), then shipped as a block to OSKAR (INT 60h, `0x19BE`) or written
byte-by-byte over the serial line (INT 14h AH=41, `0x1737`).

### 5.5 Structured field records (mode `0x0A`, `0x14F5`)

Reads a count/parameter into `[0xC38]`, then a record type into `[0xC45]`:

| Type | Entry | Meaning (inferred) |
|------|-------|--------------------|
| `0x0C` | `0x1542` | write field (emits `ESC … 0x05`, len-5 block) |
| `0x0E` | `0x159E` | field / attribute op |
| `0x0F` | `0x1581` | field / attribute op |
| `0x11` | `0x15EB` | field / attribute op |
| `0x12` | `0x15F9` | field / attribute op |
| `0xFF` | `0x1532` | **record terminator / sync** — next byte must be 0, else fatal `LINE ERROR : I` and restart |

A hex-encode helper (`0x17FC`: nibble → `'0'`–`'9'`/`'A'`–`'F'`) formats status and
coordinate bytes as ASCII where the protocol carries them as text.

> **Direction note.** In block mode the mapping is unambiguously host-stream → OSKAR
> screen (distinct INT 60h functions for receive vs. paint). In serial (char) mode
> the same codec emits over INT 14h AH=41; ASYNC2's own dispatch confirms `AH=41`
> transmit / `AH=42` receive.

---

# Part II — The driver suite

## 6. OSKAR display driver (`OSKEM.EXE`)

`OSKEM.EXE` is the resident **OSKAR** display driver. L1WSE only *produces* the
OSKAR control stream; OSKEM executes it — glyph rendering, cursor motion, erase and
attribute handling — by calling the Olivetti M24 video BIOS.

### 6.1 Module facts

| Property | Value |
|----------|-------|
| Type | 16-bit real-mode `MZ` executable (TSR) |
| Size | 6,691 bytes |
| Install entry | `CS:IP = 0178:000E` (transient install code at the tail) |
| Resident part | start of load module (the two interrupt handlers) |
| Character generators | two full 32–126 charsets embedded |

Interrupt-use histogram: INT 10h ×17, INT 21h ×4, INT 16h ×2, INT CEh ×2, INT B0h ×1.

### 6.2 Two interrupt surfaces

OSKEM installs **two** handlers:

| Surface | Range | Role |
|---------|-------|------|
| **INT 60h — OSKAR API** | `AH = 01–0Dh` | the interface L1WSE drives (write/cursor/scroll/field) |
| **INT 10h hook — M24 video extensions** | `AH = 40–4Ch` | adds Olivetti/OSKAR video functions; `AH<40h` chains to the ROM BIOS (`jmp far [cs:…]`) |

Both handlers are the same shape as the other drivers: range-check `AH`, chain out
if outside range, otherwise index a jump table and `iret`.

### 6.3 Display-control pipeline (write path `0xD5D`)

Every byte OSKEM renders passes through the same pipeline:

| Stage | Detail |
|-------|--------|
| 1. Fetch | read next stream byte into `AL` (`0x1610`) |
| 2. Translate | `AL` → **translation table at `0x607`** (identity for `0x00–0x5F`); in **graphics mode** (`[0x11]==2`) bytes `0x60–0x7F` are remapped via table `0x907` to IBM box-drawing glyphs (`0xB3,0xC4,0xDA,0xBF,…`) |
| 3. Classify | branch on the translated value `AH` |

Classification (`0xD85`):

| Translated value | Meaning | Path |
|------------------|---------|------|
| `> 0x1B` | **displayable glyph** | write at cursor + advance (`0xD9E`) |
| `0x00–0x1A` | **C0 control function** | shared handler `0xE62` |
| `0x1B` (`ESC`) | escape introducer | fetch next byte, extended-opcode dispatch (`0xE38`) |

Cursor state is `DH`=row / `DL`=column; on glyph write the cursor advances with
line width `[0x4F7]`, bottom row `[0x15]`, and scroll on overflow (`0xDDB`–`0xDEB`).

### 6.4 Control-function handler (`0xE62`) — shared by C0 and the INT 60h API

The same executor services both a **C0 control byte** in the stream and an **INT 60h
API call** (`AH` = function). `AH` selects the operation:

| `AH` / C0 | Handler | Operation (traced / inferred) |
|-----------|---------|-------------------------------|
| 01–06 | `0xD9E` | write / control |
| 07 | `0xB0E` | write string / block |
| 08 (`BS`) | `0xE82` | cursor left / set position (`DH`,`DL`) |
| 09 (`HT`) | `0xEA0` | tab — advance to next stop over the row |
| 0A (`LF`) | `0xEBB` | **line feed / index** — bounds row against `[0x15]`/`[0x13]`, scroll |
| 0B–0C | `0xE55` | store/state (`DL` → `[0x4FC]`) |
| 0D (`CR`) | `0xECC` | carriage return (col ← `[0x4FC]`, then `0`) |
| >0Dh | — | out of range → ignore |

### 6.5 Rendering primitives

OSKEM paints two ways — the M24 video BIOS **and** direct writes to text video RAM
at `B800:` (`0xD53`).

| INT 10h call | Use |
|--------------|-----|
| `AH=00` | set video mode |
| `AH=01` | set cursor type |
| `AH=02` | set cursor position |
| `AH=08` | read char + attribute at cursor |
| `AH=09` | write char + attribute |
| `AX=4A00` | Olivetti M24 video extension |

### 6.6 The OSKAR escape set — `ESC <byte>`, byte `0x52–0xAB`

After an `ESC` (`0x1B`), OSKEM fetches the next byte and dispatches it — **only
codes `0x52–0xAB`** (`0xE3B`: `cmp ax,0x52` / `cmp ax,0xAC`); anything else is
ignored (a bare `0x52`=`'R'` without the leading `ESC` just prints `R`). Dispatch
is a 90-entry near-pointer table: `index=(code-0x52)*2`, `call [cs:bx+0x5E9]`.

**Resolving the table.** The table is CS-relative and OSKEM's relocation table
shows the resident code segment is based at **paragraph `0x95`** (relocs [0–10] use
base `0x0095`), so `cs:0x5E9` = file `0xB50 + 0x5E9 = 0x1139`. With that base the
90 entries resolve to real handlers; the common target `cs:0x05D3` (34 codes) is
the ignore/no-op stub.

**Cursor movement & addressing**

| `ESC` code | Char | Handler | Action |
|------------|------|---------|--------|
| `0x52` | `R` | `0x77F` | cursor up (clamp/wrap at region top `[0x12]`) |
| `0x53` | `S` | `0x791` | cursor down (wrap bottom `[0x13]` → top) |
| `0x54` | `T` | `0x7A3` | cursor right (clamp at width `[0x4F7]`) |
| `0x55` | `U` | `0x7AE` | cursor left (wrap col 0 → width) |
| `0x5A` | `Z` | `0x7BF` | home — cursor to region top-left |
| `0x5C` | `\` | `0x175` | absolute address (row,col params, bounds-checked) |
| `0x58` | `X` | `0x9D2` | direct address variant |
| `0x59` | `Y` | `0x9CD` | direct address (row,col) |
| `0x5F` | `_` | `0x9C7` | address variant |

**Erase / edit**

| `ESC` code | Char | Handler | Action |
|------------|------|---------|--------|
| `0x5B` | `[` | `0x803` | clear screen, home, reset attributes/flags |
| `0x65 0x6B 0x6E 0x6F 0x7A 0x7B 0x86 0x9F` | `e k n o z { …` | `0x7FF` | erase (fill-with-space via `0xC7D`/`0x83D`) |
| `0x70 0x71 0x73` | `p q s` | `0x7FC` | erase (double region) |
| `0x64` | `d` | `0x7C8` | write / insert run of translated characters |
| `0x57` | `W` | `0x890` | fill / repeat character (count, char, attribute) |

**Attributes & modes**

| `ESC` code | Char | Handler | Action |
|------------|------|---------|--------|
| `0x6D` | `m` | `0x5D6` | set attribute — param `0` clears, else OR into attribute byte `[0x18]` |
| `0x5D` | `]` | `0x884` | set mode (`[0x9]=1`, `[0xF]`←param) |
| `0x5E` | `^` | `0x87E` | reset mode (`[0x9]=0`) |
| `0x68` | `h` | `0x717` | set mode (conditional on `[0x7]`) |
| `0x6C` | `l` | `0x967` | mode / status request with sub-function |
| `0xA1` | — | `0x877` | select character set → `[0x11]` (drives the graphics remap of §6.3) |

**Cursor save/restore, tabs, scroll, colour, download**

| `ESC` code | Char | Handler | Action |
|------------|------|---------|--------|
| `0x67` | `g` | `0x732` | save cursor + hide (INT 10h AH=01, cursor off) |
| `0x66` | `f` | `0x726` | restore cursor |
| `0x56` | `V` | `0x75B` | clear/set tab stops (40-column table at `[0x19]`) |
| `0xA8 0xAB` | — | `0x5B9` | back-tab to previous stop |
| `0x63` | `c` | `0x74C` | set scrolling region (top `[0x14]`, bottom `[0x15]`) |
| `0xA4` | — | `0x69D` | scroll (param count) |
| `0xA3` | — | `0x6AB` | set colours (3 params → `[0x501]/[0x503]/[0x505]`) |
| `` 0x60 0x61 0x62 `` | `` ` a b `` | `0xA1D/0xA16/0xA0F` | download / define sequence (mode `0x60/0x61/0x62`) |
| `0x69 0x6A 0x75 0x77 0x78 0x7C 0x7E 0x7F …` | `i j u w x …` | `0x4AE` | common exit (save cursor, return via internal stack) |

> All codes outside the active set above point at the ignore stub `cs:0x05D3`.
> The separate `ESC <letter>` table at seg `0x77D` (`A B C D H J K Y …`) is a
> *different* set — not consulted by this display path — and is most likely a
> function-key output table.

### 6.7 Low-level video primitives

The opcode handlers reach the screen through a small set of primitives:

| Routine | Function |
|---------|----------|
| `0x1A0` | position cursor from `DH`/`DL`, compute video-RAM offset `DI` |
| `0x1DE` | read char at `DI` — CGA horizontal-retrace synced (snow-free) |
| `0x1F1` / `0x20B` | write char / char+attr word at `DI`, retrace-synced |
| `0x225` / `0x24F` | copy char+attr / `movsw` block, retrace-synced |
| `0x83D` | erase region — fill with space + current attribute `[0x4F9]` |
| `0x1BE` | **bell** — PIT channel 2 (`OUT 43h/42h`) + speaker gate (`OUT 61h`) |

Video memory is addressed directly at `B800:` (`0xD53`), in parallel with the
INT 10h BIOS calls of §6.5.

## 7. Keyboard extension (`T_KEYB.COM` + `KEY*.TIB`)

L1WSE does **not** load the `.TIB` files; it only checks a national keyboard is
present. The resident **`T_KEYB.COM`** ("TIB KEYBOARD HANDLER") loads a `.TIB` file
and **replaces the M24's native keyboard translation**, providing layouts and
special key codes the stock M24 keyboard BIOS cannot produce.

### 7.1 `.TIB` table format (e.g. `KEYUK1.TIB`, 703 bytes)

| Field | Layout |
|-------|--------|
| Header | **14 bytes**: `[0]` = plane id (`02` for `…1`, `01` for `…2`); `[1..0C]` = `FF` padding; `[0D]` = `00` |
| Records | **53 fixed 13-byte per-key records**, in ascending PC scancode order |
| Record | **six 2-byte plane slots** + **1 flag byte** |
| Slot | `(character, scancode)` — the BIOS keystroke to inject (`AL`=char, `AH`=scancode); `FF FF` = plane undefined |
| Flag byte | per-key attribute; **`0x80` = Caps-Lock-sensitive** (set on alphabetic keys), else `00` |

The `(character, scancode)` order is confirmed by the `Esc` record `1B 01`
(char `0x1B`, scancode `0x01`) and by `Ctrl+2` = `00 03` (NUL, scancode `0x03`).

### 7.2 The six planes

| # | Plane | Notes |
|---|-------|-------|
| P1 | **Base** | unshifted character |
| P2 | **Shift** | e.g. UK `Shift+3` = `9Ch` (`£`) |
| P3 | **Ctrl** | control codes for letters (`Ctrl+A`=`01h` … `Ctrl+Z`=`1Ah`); `Ctrl+2`=NUL, `Ctrl+6`=`1Eh`, `Ctrl+-`=`1Fh` |
| P4 | **Alt** | `Alt`+digit → IBM extended scancodes `78h–83h`; `Alt`+letter → `(00, key-scancode)` |
| P5 | *(reserved)* | unused in the shipped tables (`FF FF` everywhere) |
| P6 | **AltGr** | national/graphic layer — equals P4 where no national char exists; in `KEYGR1` (German) `AltGr+2`=`@`, `AltGr+ü`=`[`, etc. |

### 7.3 Full keymap — `KEYUK1.TIB`, plane 1

All 53 key records. Notation: `` `c` `` printable char, `NNh` byte code,
`scNN` output scancode (char `00`), `⎇scNN` Alt extended scancode, `—` undefined.
Rows `28`/`41` are the modifier-key slots (`LCtrl` sc `1D`, `LShift` sc `2A`) and
emit nothing.

| # | Scan | Base | Shift | Ctrl | Alt | AltGr | Caps |
|---|------|------|-------|------|-----|-------|------|
| 0 | 01 | ESC | `1Bh` | `1Bh` | — | — |  |
| 1 | 02 | `1` | `!` | — | ⎇sc78 | ⎇sc78 |  |
| 2 | 03 | `2` | `"` | sc03 | ⎇sc79 | ⎇sc79 |  |
| 3 | 04 | `3` | `9Ch` (£) | — | ⎇sc7A | ⎇sc7A |  |
| 4 | 05 | `4` | `$` | — | ⎇sc7B | ⎇sc7B |  |
| 5 | 06 | `5` | `%` | — | ⎇sc7C | ⎇sc7C |  |
| 6 | 07 | `6` | `^` | `1Eh` | ⎇sc7D | ⎇sc7D |  |
| 7 | 08 | `7` | `&` | — | ⎇sc7E | ⎇sc7E |  |
| 8 | 09 | `8` | `*` | — | ⎇sc7F | ⎇sc7F |  |
| 9 | 0A | `9` | `(` | — | ⎇sc80 | ⎇sc80 |  |
| 10 | 0B | `0` | `)` | — | ⎇sc81 | ⎇sc81 |  |
| 11 | 0C | `-` | `_` | `1Fh` | ⎇sc82 | ⎇sc82 |  |
| 12 | 0D | `=` | `+` | — | ⎇sc83 | ⎇sc83 |  |
| 13 | 0E | BS | `08h` | `7Fh` | — | — |  |
| 14 | 0F | TAB | sc0F | — | — | — |  |
| 15 | 10 | `q` | `Q` | `11h` | sc10 | sc10 | ✓ |
| 16 | 11 | `w` | `W` | `17h` | sc11 | sc11 | ✓ |
| 17 | 12 | `e` | `E` | `05h` | sc12 | sc12 | ✓ |
| 18 | 13 | `r` | `R` | `12h` | sc13 | sc13 | ✓ |
| 19 | 14 | `t` | `T` | `14h` | sc14 | sc14 | ✓ |
| 20 | 15 | `y` | `Y` | `19h` | sc15 | sc15 | ✓ |
| 21 | 16 | `u` | `U` | `15h` | sc16 | sc16 | ✓ |
| 22 | 17 | `i` | `I` | `09h` | sc17 | sc17 | ✓ |
| 23 | 18 | `o` | `O` | `0Fh` | sc18 | sc18 | ✓ |
| 24 | 19 | `p` | `P` | `10h` | sc19 | sc19 | ✓ |
| 25 | 1A | `[` | `{` | `1Bh` | — | — |  |
| 26 | 1B | `]` | `}` | `1Dh` | — | — |  |
| 27 | 1C | CR | `0Dh` | `0Ah` | — | — |  |
| 28 | — | — | — | — | — | — |  |
| 29 | 1E | `a` | `A` | `01h` | sc1E | sc1E | ✓ |
| 30 | 1F | `s` | `S` | `13h` | sc1F | sc1F | ✓ |
| 31 | 20 | `d` | `D` | `04h` | sc20 | sc20 | ✓ |
| 32 | 21 | `f` | `F` | `06h` | sc21 | sc21 | ✓ |
| 33 | 22 | `g` | `G` | `07h` | sc22 | sc22 | ✓ |
| 34 | 23 | `h` | `H` | `08h` | sc23 | sc23 | ✓ |
| 35 | 24 | `j` | `J` | `0Ah` | sc24 | sc24 | ✓ |
| 36 | 25 | `k` | `K` | `0Bh` | sc25 | sc25 | ✓ |
| 37 | 26 | `l` | `L` | `0Ch` | sc26 | sc26 | ✓ |
| 38 | 27 | `;` | `:` | — | — | — |  |
| 39 | 28 | `'` | `@` | — | — | — |  |
| 40 | 29 | `#` | `~` | — | — | — |  |
| 41 | — | — | — | — | — | — |  |
| 42 | 2B | `\` | `\|` | `1Ch` | — | — |  |
| 43 | 2C | `z` | `Z` | `1Ah` | sc2C | sc2C | ✓ |
| 44 | 2D | `x` | `X` | `18h` | sc2D | sc2D | ✓ |
| 45 | 2E | `c` | `C` | `03h` | sc2E | sc2E | ✓ |
| 46 | 2F | `v` | `V` | `16h` | sc2F | sc2F | ✓ |
| 47 | 30 | `b` | `B` | `02h` | sc30 | sc30 | ✓ |
| 48 | 31 | `n` | `N` | `0Eh` | sc31 | sc31 | ✓ |
| 49 | 32 | `m` | `M` | `0Dh` | sc32 | sc32 | ✓ |
| 50 | 33 | `,` | `<` | — | — | — |  |
| 51 | 34 | `.` | `>` | — | — | — |  |
| 52 | 35 | `/` | `?` | — | — | — |  |

### 7.4 National variants

| Property | Detail |
|----------|--------|
| Two planes per language | `…1` vs `…2` (header byte `02`/`01`); `KEYUK1` vs `KEYUK2` remaps symbol keys (`=`↔`^`, `[`↔`@`, `]`↔`[`, `'`↔`:`, `#`↔`]`) |
| Layout changes | `KEYGR1` is QWERTZ (Y/Z swapped, scancode `15`=`z`) with an AltGr layer (`@ [ ] { } \` on P6) and national letters (`ü`=`81h`, `ß`=`E1h`, `§`=`15h`) |
| Record count | UK/USA/ITA = 53 records (703 B); German = 57 (755 B); French/Portuguese carry extra trailing bytes (dead-key data) |
| Keypad remap | `T_KEYB` map string `S-J7G8H9I4K5L6M1O2P3Q0R.` binds keypad scancodes (`G..R` = `47h–52h`) to host digits |
| National set | Danish, Finnish/Swedish (FS), French, German, Italian, Norwegian, Portuguese, Spanish (SP/SPA), Swedish (SVR/SVT), UK, USA |

## 8. Async line driver (`ASYNC2.EXE`)

`ASYNC2.EXE` installs the extended **INT 14h** line driver (`ASYNC COMM.2 driver
installed`). Its handler range-checks `AH` in `0x40–0x4B`, chains lower functions
to the original INT 14h (`jmp far [cs:0x22]`), and dispatches `0x40–0x4B` through a
jump table at `cs:0x2684` (index `(AH-0x40)*2`). Presence check `AH=0x48` returns
`AX=0xFF02`. Function directions are as listed in §3.3 (`AH=41` transmit, `AH=42`
receive).

---

## Appendix A — file inventory

| File | Role |
|------|------|
| `L1WSE.EXE` | the emulator (subject of this document) |
| `OSKEM.EXE` | OSKAR display driver (INT 60h); two 32–126 charsets |
| `ASYNC2.EXE` | async line driver (INT 14h) |
| `T_KEYB.COM` | TIB keyboard handler |
| `KEY*.TIB` | national keyboard tables (2 planes each) |
| `CONF.EXE`, `PRT.EXE`, `CONTSW.COM` | support utilities |

## Appendix B — key data offsets in `L1WSE.EXE`

| Offset | Meaning |
|--------|---------|
| `[0x0C]` | transport select (0 = serial, ≠0 = HCB block) |
| `[0x0D]`/`[0x0E]` | terminal mode / plane bytes (sent in config block) |
| `[0x419]` | last line-error letter (`LINE ERROR :`) |
| `[0x431]` | HCBDRV-present flag |
| `[0x432]` | receive ring buffer |
| `[0xC32]` | received-byte count |
| `[0xC34]` | receive read cursor / block length |
| `[0xC38]` | retry counter |
| `[0xC44]` | current command / session mode |
| `[0xC45]`/`[0xC47]` | record type / sub-type |
| `[0xCFC]` | `"name of HOST machine  : "` prompt string |
| `[0xD89]` | shared block buffer (host name, send/recv payload) |
| `[0xE89]`/`[0xE91]` | 4-byte block header fields |
| `[0xEA1]`/`[0xEA9]`/`[0xEB1]` | pre-built command blocks |
| `[0x1DBC]` | INT CEh connected flag |
| `[0x1DBD]` | INT CEh function jump table |
