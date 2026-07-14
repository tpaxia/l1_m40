# L1WSE — Olivetti M24 "L1 Work-Station Emulator"

Reverse-engineering notes on `L1WSE.EXE` and its companion drivers.

> Status: living document. Sections below are derived by static disassembly
> (`ndisasm`, 16-bit real mode) and data inspection of the binaries. Segment
> offsets are given as the program sees them (load module base = file offset
> `0x200`, so `file = seg + 0x200`).

---

## 1. Overview

`L1WSE.EXE` turns an **Olivetti M24** PC into a graphics **workstation / terminal**
that talks to a host machine through a cluster-style communications controller.
It is a small (10,557-byte) **16-bit real-mode MS-DOS `MZ` executable**, written in
**hand-crafted 8086 assembly** (no high-level-language runtime), using a single
code+data segment (tiny model) with 20 relocations and entry point `CS:IP = 0000:0434`.

The emulator does **no serial, screen, or keyboard I/O itself**. At startup it
verifies four resident drivers are present (the "FATAL error … not installed"
messages) and then drives them via software interrupts. It is the front-end that
ties those drivers into a terminal session.

### Companion drivers (all resident TSRs, shipped alongside)

| File | Vector | Banner string | Role |
|------|--------|---------------|------|
| `OSKEM.EXE`  | **INT 60h** (AH=01–0Dh) | `OSKAR driver installed`        | screen / graphics workstation output |
| `ASYNC2.EXE` | **INT 14h** (AH=40–4Bh) | `ASYNC COMM.2 driver installed` | RS-232 serial line to host |
| (parallel)   | **INT 17h** (AH=40–43h) | printer driver                  | print / `SCRPRT` screen-copy |
| `T_KEYB.COM` | INT 9/16 hook + `.TIB`  | `TIB KEYBOARD HANDLER`          | national / terminal keyboard remap |
| `HCBDRV`     | **INT 60h** block mode + INT 5 hook | signature `HCBDRV` | Host Communications Block link to controller |

### Startup driver probes (L1WSE)

- OSKAR display: `INT 14h AX=4800` presence check (expects `AH=FF01/FF02/FF03`),
  plus Olivetti M24 video-BIOS extensions `INT 10h AX=48xx/49xx/4Axx`.
- Printer: `INT 17h AX=4300` presence check.
- Async comm: `INT 14h AX=4800`.
- National keyboard: checks a keyboard table is loaded (else
  `FATAL error : NATIONAL KEYBOARD not specified`).

Fatal-error strings embedded in the binary:

```
FATAL  error :OSKAR driver not installed
FATAL  error :OSKAR graphics driver not installed
FATAL  error :printer driver (parallel interface) not installed
FATAL  error :ASYNC COMM   driver not installed
FATAL  error :NATIONAL KEYBOARD not specified
```

---

## 2. Interrupt / interface map

| Vector | Direction | Purpose |
|--------|-----------|---------|
| `INT 60h` | L1WSE → OSKAR / HCBDRV | display driver **and** host block driver, function selector in `AH`, `AL=0` |
| `INT 14h` | L1WSE → ASYNC2 | extended async line driver (open/close/send/recv/control) |
| `INT 17h` | L1WSE → printer | extended printer driver (open/close/send/status) |
| `INT 10h` | L1WSE → M24 video BIOS | Olivetti-specific video mode / attribute calls |
| `INT 05h` | — | print-screen; also used to detect `HCBDRV` by signature |
| `INT CEh` | L1WSE **exports** | 13-function host-link device API (installed by L1WSE) |
| `INT 21h` | L1WSE → DOS | console, file, device I/O |

Interrupt-use histogram (whole binary): INT 21h ×22, INT 10h ×13, INT 60h ×11,
INT 14h ×8, INT 17h ×6, INT 5 ×3, INT CEh ×2.

### INT 60h — OSKAR / HCB driver stub library (`0x2276`–`0x2400`)

A bank of far procedures (`retf N`, HLL far-call convention) marshal stack
arguments into registers and issue `INT 60h` with a function number in `AH`:

| `AH` | stub | notes |
|------|------|-------|
| 01 | `0x2276` | init / open |
| 02 | `0x2289` | **block send** — scatter/gather from a caller `{count, ptr…}` descriptor array (copies ≤`0xC8` bytes) |
| 03 | `0x2284` | **block receive** |
| 04 | `0x227F` | block variant |
| 05 | `0x2343` | positioned op (4 args) |
| 06–0A | `0x236E`–`0x2392` | simple ops (get/put/status) |
| 0B | `0x239B` | |
| 0C | `0x23A4` | (args) |
| 0D | `0x23C9` | |

### INT 14h — ASYNC2 line driver (extended)

| `AH` | meaning | args |
|------|---------|------|
| 40 | open line | `BX`=line, `CX:DX`=params (`[0x00]`,`[0x02]`,`[0x04]`) |
| 41 | close line | `BX`=line |
| 42 | **receive one byte** | returns `AH=0` byte in `AL` / `AH=1` no-more / else error |
| 43 | line control | |
| 44 | status / flush | |
| 45/46/47/4B | transmit & status | |

Received bytes are drained into a local ring buffer at `[si+0x432]`, count in
`[0xC32]`, read cursor in `[0xC34]` (fill routine `0x17DF`).

---

## 3. Host connection & block protocol

**Model: named-host, block request/response through a cluster controller** — not a
point-to-point serial pipe.

### Connect handshake (`0x12C7`–`0x134C`)

1. **Prompt / capture host name.** `INT 21h/AH=09` prints
   `"name of HOST machine  : "` (`0xCFC`); `INT 21h/AH=0A` reads it into `[0xD89]`
   (max `0xFF`, length in `[0xD8A]`).
2. **Normalize** the name to a fixed **14-character, space-padded** field; block
   length `[0xC34]` set to `0x10` (16).
3. **Send the connect block** (`call 0x199C`) — the padded host name goes to the
   controller via INT 60h func 7.
4. **Link-control commands.** `[0xC44]` ← `0x0A`, `0x0B`, and conditionally `0x09`
   (`call 0x1ADC`), selecting pre-built command blocks at `[0xEA1]/[0xEA9]/[0xEB1]`
   (map at `0x193D`).
5. **Terminal config block** (`[0xD89]=0x000B`) packing mode bytes `[0x0D]`/`[0x0E]`.

### Block protocol (`0x181C`–`0x1927`, dispatcher `0x1B27`)

- **Send:** INT 60h **func 2** writes block (`[0xD89]`, length `[0xC34]`).
- **Receive:** INT 60h **func 3** reads a reply block (buffer `0x28` = **40 bytes**)
  into `[0xD89]`; descriptor `[0xECF]` gives count + pointer.
- **Poll/flow control:** driver busy status `0x80` normalized to **`0x91`**
  (`0x1B32`); on `0x91`, decrement retry counter `[0xC38]` and loop until answered.
- **Framing:** 4-byte block header copied to `[0xE89]` / `[0xE91]` (two 16-bit fields).
- **Ack/release:** INT 60h **func 7** then **func A** (`0x1927`/`0x1932`).
- **Errors** → single letter in `[0x419]`, shown as `LINE ERROR : <O/S/B/I/R…>`.

### DOS-device veneer — L1WSE's own INT CEh driver (`0x1E80`)

L1WSE installs an **INT CEh** handler (ends in `iret`): a **13-entry jump table**
(`call [bx+0x1DBD]`, function in `AL≤0x0C`) that maps the block link onto DOS
semantics, returning through a common tail that sets **CF from AH** (carry = error):

- **connect** = command `0x0C`, polled (handles `0x91`), sets connected flag
  `[0x1DBC]=1`, then `INT 21h AX=3D88` (open host for **read**, mode `0x88`).
- **disconnect** = command `0x0B`, clears flag, `INT 21h AX=3D89` (open **write**
  side, mode `0x89`).
- read / write / seek (func 5) / status in between.

Once connected, the host session behaves like an **openable named device with a
read handle and a write handle**.

### Two interchangeable transports (config byte `[0x0C]`)

- **`HCBDRV`** — Host Communications Block, INT 60h block mode. Detected by reading
  the **INT 5** vector and matching the 6-byte signature `"HCBDRV"` at handler+3
  (`0x1B9B`, `repe cmpsb`), setting `[0x431]`.
- **`ASYNC2`** — plain RS-232 (INT 14h), char-at-a-time into the `[0x432]` ring
  buffer, when no block controller is present.

---

## 4. Keyboard extension (`T_KEYB.COM` + `KEY*.TIB`)

L1WSE does **not** load the `.TIB` files; it only checks a national keyboard is
present. The resident **`T_KEYB.COM`** ("TIB KEYBOARD HANDLER") loads a `.TIB` file
and **replaces the M24's native keyboard translation**, providing layouts and
special key codes the stock M24 keyboard BIOS cannot produce.

### `.TIB` table format (e.g. `KEYUK1.TIB`, 703 bytes)

- 14-byte header; first byte = plane id (`02` for `…1`, `01` for `…2`).
- **53 fixed 13-byte per-key records**. Each record: a lead byte (the key's base
  character) + **six shift-state slots**, each a `(scancode, character)` pair
  (`FF FF` = no output / pass through). States ≈
  *normal / shift / ctrl / alt / graph / alt-shift*.

### Evidence of extension beyond stock M24

- **Extra output codes** in the Alt/graph planes (`7Fh, 80h–83h`) = OSKAR
  character-generator glyphs (national / graphic) not typeable on stock M24.
- **Two switchable planes per language** (`…1` vs `…2`); diffing `KEYUK1` vs
  `KEYUK2` shows symbol keys remapped (`=`↔`^`, `[`↔`@`, `]`↔`[`, `'`↔`:`, `#`↔`]`).
- **Keypad/function remap in `T_KEYB`** — embedded map string
  `S-J7G8H9I4K5L6M1O2P3Q0R.` binds keypad scancodes (`G..R` = 0x47–0x52) to host digits.
- **Large national set** (each in two planes): Danish, Finnish/Swedish (FS),
  French, German, Italian, Norwegian, Portuguese, Spanish (SP/SPA), Swedish
  variants (SVR/SVT), UK, USA.

---

## 5. Host-byte → OSKAR-screen interpreter

The core of the emulator is a small **state machine that consumes the received host
data stream and re-encodes it into OSKAR display-control sequences.** It is RX-driven:
the main loop only enters it when received-byte count `[0xC32] > 0`.

### Data flow

```
 controller/host ─► receive buffer [0x432]          (refilled by:
        │                (count [0xC32], read cursor [0xC34])   INT 60h func 3 block, or
        ▼                                                       INT 14h AH=42 serial)
 fetch next byte  (0x1AB5 → 0x1789)
        ▼
 dispatch on control byte  (interpreter @ 0x1360)
        ▼
 build OSKAR ESC sequence in [0xD89] block
        ▼
 emit to OSKAR ─►  block mode ([0xC]≠0): INT 60h func 2   (0x19BE)  ← local OSKAR driver
                   char  mode ([0xC]=0): INT 14h AH=41    (0x1737)  ← serial OSKAR terminal
```

### Session modes (`[0xC44]`)

The interpreter runs one of three sub-languages selected by the mode byte `[0xC44]`:

| `[0xC44]` | entry | sub-language |
|-----------|-------|--------------|
| `0x0A` | `0x14F5` | **structured field records** (attributes / field defs) |
| `0x09` | `0x1630` | secondary record mode |
| other  | `0x13A4` | **character / cursor-positioning** stream |

### Character / cursor stream (`0x13A4`–`0x14DC`)

Fetch a host byte (`0x1AB5`) and dispatch:

| host byte | handler | action |
|-----------|---------|--------|
| `0x14` | `0x14DD` | local op (status/print; sets error `F`=0x46 on failure) |
| `0x19` | `0x1B3A` | driver op (INT 60h func 7/A path) |
| `0x1A` | `0x1B4B` | driver op |
| `0x1C` | `0x1B82` | driver op (INT 60h func 5) |
| `0x45` `'E'` | `0x1BB7` | block send (field transmit) via INT 60h func 2 |
| `0x6A` `'j'` | `0x1409` | **cursor / position command** (reads 1 parameter byte) |
| `0xA9` | `0x13D0` | prefixed variant — fetch one more byte, then re-dispatch |
| else | `0x14D0` | treated as displayable data |

### OSKAR escape encoding (built at `0x1409`)

The `0x6A` position command reads a sub-type into `[0xC47]` and emits:

```
ESC(0x1B)  0x04  <subtype + 0xF0>  <operand…>
```

- **Command opcode** is `0x04`; the sub-type byte is biased by **`+0xF0`**.
- **Coordinates** are sent as a word biased by **`+0x2020`** (row and column each
  `+0x20`) — the classic printable/space-offset coordinate encoding (cf. VT52
  `ESC Y row+0x20 col+0x20`).
- Sub-type `2` emits a literal `0x5F` (`'_'`) operand; other sub-types emit three
  raw operand bytes (`CH,CL,DL`).

The sequence is assembled in the `[0xD89]` block (length byte `[0xD8A]`, payload
from `[0xD8B]`) and then either shipped as a block to OSKAR (INT 60h, `0x19BE`) or
written byte-by-byte over the serial line (INT 14h AH=41, `0x1737`).

### Structured field records (mode `0x0A`, `0x14F5`)

Reads a count/parameter into `[0xC38]`, then a record type into `[0xC45]` and
dispatches:

| type | entry | meaning (inferred) |
|------|-------|--------------------|
| `0x0C` | `0x1542` | write field (emits `ESC … 0x05`, len 5 block) |
| `0x0E` | `0x159E` | field / attribute op |
| `0x0F` | `0x1581` | field / attribute op |
| `0x11` | `0x15EB` | field / attribute op |
| `0x12` | `0x15F9` | field / attribute op |
| `0xFF` | `0x1532` | **record terminator / sync** — next byte must be 0, else fatal `LINE ERROR : I` and restart |

A hex-encode helper (`0x17FC`: nibble → `'0'`–`'9'`/`'A'`–`'F'`) formats status and
coordinate bytes as ASCII where the protocol carries them as text.

### Where the pixels happen

L1WSE only *produces* the OSKAR ESC stream; the actual glyph rendering, cursor
motion and attribute handling are executed by **`OSKEM.EXE`** (the OSKAR driver on
INT 60h), which carries the two 32–126 character generators. The OSKAR opcode set
(`ESC 04` = position, `ESC 05` = field/write, sub-types biased `+0xF0`, coordinates
biased `+0x20`) is the boundary between this emulator and that driver.

> Direction note: in block mode the mapping is unambiguously host-stream → OSKAR
> screen (distinct INT 60h functions for receive vs. paint). In serial (char) mode
> the same codec emits over INT 14h AH=41; ASYNC2's own dispatch (jump table at
> `cs:0x2684`, functions `0x40`–`0x4B`; `AH=41` transmit, `AH=42` receive, `AH=48`
> → `0xFF02` presence) confirms the function directions.

---

## Appendix A — file inventory

- `L1WSE.EXE` — the emulator (this document's subject).
- `OSKEM.EXE` — OSKAR display driver (INT 60h). Ships two full 32–126 charsets.
- `ASYNC2.EXE` — async line driver (INT 14h).
- `T_KEYB.COM` — TIB keyboard handler.
- `KEY*.TIB` — national keyboard tables (2 planes each).
- `CONF.EXE`, `PRT.EXE`, `CONTSW.COM`, `OSKEM.EXE` — support utilities.
