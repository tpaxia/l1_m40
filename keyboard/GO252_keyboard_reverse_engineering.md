# GO252 keyboard reverse engineering notes

This note captures the current, disassembly-backed model for how `KEYTE1`
receives keyboard characters. It should be read together with
`re/hardware/go252/GO252_KDC_diagnostics.md`; this file focuses only on the keyboard receive
path.

## Current conclusion

`KEYTE1` does not poll a keyboard hardware port inline in the high-level test
loop. The test consumes keyboard bytes from an interrupt-filled circular FIFO in
RAM.

Definite FIFO state:

```text
buffer base:   0x7578
buffer size:   0x80 bytes
count:         0x75fc
read pointer:  0x8750
write pointer: 0x8748
```

MAME-driven tracing of disk B now identifies the missing hardware-facing side:
the loaded resident FE/KDC support code in logical segment `0x1d` services
keyboard/communication interrupts through UC I/O ports `0xff20` and `0xff22`.
The diagnostic monitor's initial input path is vector `0x28`, which enters at
`0x1d:02a4`; that handler calls the callback installed for the active test or
monitor state. In the `KEYTE1` case, the relevant callback is the FIFO enqueue
routine, which receives the byte in `rl0`.

Important caveat: MAME's pass-through I/O tap reports even offsets for these
byte accesses (`0x1f00`, `0x1f40`, `0x1f42`, ...). The disassembly source uses
the Z8001 byte register constants (`rl1 = 0x01`, `0x41`, `0x43`, ...). The notes
below use the source-level low-byte constants unless explicitly labeled as a
MAME trace address.

## Resident FE/KDC support code

After booting disk B in MAME, dumping logical segment `0x1d` shows the resident
FE-device driver that the test programs call. It is not part of the flat
`KEYTE1`/`GRAPH3` payloads that were originally disassembled.

Useful entry points in the dumped segment:

```text
0x02a4  direct UC/KDC byte interrupt entry used by diagnostic-monitor input
0x03f0  FE control/status command helper
0x068e  descriptor-driven FE/KDC interrupt entry
0x08e4  status-change interrupt entry
0x0910  data-ready interrupt entry
0x095a  control/status interrupt entry
0x0a1a  alternate status interrupt entry
0x0a6e  transmit/output helper
```

### FE control/status helper

The routine at segment `0x1d:03f0` operates on the FE slot control register. It
uses the device base in `r1`, keeps a shadow byte at `rr2 + 0x0e`, applies one of
eight mask/set table entries, writes the result with `outb @r1,rl0`, restores
`fcw`, and immediately reads the same register with `inb rl0,@r1`.

Trace evidence from disk B:

```text
W pc=001D0424 io=1F00 reg=00 data=96
R pc=001D0428 io=1F00 reg=00 data=FF
W pc=001D0424 io=1F00 reg=00 data=B6
R pc=001D0428 io=1F00 reg=00 data=FF
```

Source-level code:

```asm
1d:03f0  subb rh6,rh6
1d:03f2  ld r1,rr2(#0x000c)      ; FE slot I/O base/register pointer
1d:03f6  ldb rl6,rr4(#0x0006)    ; command number
1d:03fa  decb rl6,#1
1d:040c  ldar rr8,0x042c         ; mask/set table
1d:0416  ldb rl0,rr2(#0x000e)    ; shadow
1d:041a  andb rl0,rl6            ; clear selected bits
1d:041c  orb rl0,rh6             ; set selected bits
1d:041e  ldb rr2(#0x000e),rl0
1d:0422  outb @r1,rl0            ; FE control write
1d:0426  inb rl0,@r1             ; FE status/readback
1d:0428  subb rh0,rh0
1d:042a  ret
```

Special command number 9 does not use the table; it reads the same FE register
and tests bit 1. If bit 1 is clear it returns error `0x8006`; otherwise it
forces shadow bit 6, writes a byte from the request block through register `0x03`,
then returns through the common readback path.

```asm
1d:043c  inb rl0,@r1
1d:043e  bitb rl0,#1
1d:0440  ld r0,#0x8006
1d:0444  ret z
1d:0448  ldb rl0,rr2(#0x000e)
1d:044c  resb rl0,#5
1d:044e  setb rl0,#6
1d:0450  outb @r1,rl0
1d:0452  ldb rl1,#0x03
1d:0454  ldb rl0,rr4(#0x0007)
1d:0458  outb @r1,rl0
1d:045a  ldb rl1,#0x01
1d:045c  jr 0x0424
```

This is strong evidence that the FE low-byte `0x01` register is a combined
keyboard/video control/status latch. The exact electrical meaning of every bit is
not yet fully assigned, but bits 5/6/7 are repeatedly manipulated by the keyboard
support code.

### Interrupt-time byte path

The resident interrupt entries use UC ports `0xff20` and `0xff22` as the
status/control and byte-data path.

The active PSA loaded by disk B puts vector `0x28` at `0x1d:02a4`. With PSAP at
logical segment 0 offset `0x0200`, the Z8001 vector table base is `PSAP + 0x3c`;
vector `0x28` therefore reads the entry at `0x028c`, which was dumped as
`9d00 02a4` (`0x1d:02a4`). Nearby entries observed in the same live dump were
`0x2a -> 0x1d:031c` and `0x2c -> 0x1d:068e`.

Two handlers show the core receive behavior:

```asm
; Segment 0x1d, direct UC/KDC byte path used by diagnostic-monitor input
02b4:  inb rh0,#0xff20
02b8:  bitb rh0,#2
02c6:  inb rl0,#0xff22       ; received byte -> rl0
02ca:  ldl rr6,@rr2
02cc:  call @rr6             ; active callback, KEYTE1 FIFO producer
02fc:  outb #0xff22,rl0

; Segment 0x1d, later descriptor-driven FE interrupt style
069e:  ld r1,<<0>>0x000c(r3)
06a2:  inb rh0,@r1           ; status through the active descriptor's register
06b2:  ldl rr6,rr2(#0x0004)
06b6:  call @rr6             ; callback when no byte/status bit matched
06d0:  ldb rl1,#0x03
06d2:  inb rl0,@r1           ; received byte/status byte through selected reg
06d4:  ldl rr6,@rr2
06d6:  call @rr6             ; active callback
06cc:  outb @r1,rl0
```

The later status-change/data-ready entries follow the same pattern: select a
status/data subregister, read a byte into `rl0`, and dispatch through callback
pointers in the active device/test descriptor.

```asm
0910..0958  data-ready entry: inb rl0,@r6; call callback at <desc>+0x0004
095a..0a18  reads alternate status, dispatches callbacks at +0x0016/+0x001a/+0x001e
0a1a..0a6c  selects status command 0x01, checks bits 5/6, dispatches callback +0x0012
0a6e..0aa4  output helper calls callback, then outb @r6,rl0 or toggles FE handshake
```

This establishes that `rl0` is not magic state created by `KEYTE1`; it is the
byte read by the resident interrupt service code immediately before invoking the
test's installed callback.

The UC ports are byte ports on the high byte lane of an even Z8000 I/O word
cycle. In MAME this must be modelled as `0xff20..0xff21` and `0xff22..0xff23`
with `umask16(0xff00)`, not as a one-byte exact address. Trace evidence for a
posted Enter key is:

```text
UC-KDC R pc=001D02B8 addr=FF20 reg=20 data=04 raw=04FF mask=FF00
UC-KDC R pc=001D02CA addr=FF22 reg=22 data=0D raw=0DFF mask=FF00
UC-KDC W pc=001D02DA addr=FF20 reg=20 data=00 raw=0000 mask=FF00
```

The currently emulated status bit with direct evidence is bit 2 of `0xff20`:
when set, the direct handler reads one byte from `0xff22`.

The monitor does not receive ASCII for the numeric keys. A live dump of segment
`0x03` after entering the monitor has the raw-to-character translation table at
offset `0x00a4`:

```text
raw:   67 68 65 5f 60 5d 57 58 55 4f 50 4d 59 62
ascii: 30 30 30 31 32 33 34 35 36 37 38 39 2d 2e
```

Therefore the current MAME monitor-input table emits:

```text
Enter 0x52
0     0x67
1     0x5f
2     0x60
3     0x5d
4     0x57
5     0x58
6     0x55
7     0x4f
8     0x50
9     0x4d
```

Trace evidence from `runs-archive/20260716-175310-load-keyte1-013-rd1nt-or-B` shows
the `LOAD` sequence `Enter`, `1`, `Enter`, `0`, `1`, `3`, `Enter` was consumed
as:

```text
52 5f 52 67 5f 5d 52
```

This verifies input delivery into the monitor. Later runs now verify that the
disk-resident loader can enter the keyboard diagnostics too; the current blocker
is the KDC byte queue/latch semantics described below.

## Current keyboard diagnostic execution status

The monitor `LOAD` path is now usable after the Z8000 segmented block-I/O and
FDU/Lua tracing fixes. The monitor loader expects the three-digit MAP code, so
disk-B keyboard-related programs are loaded as:

```text
KEYTE1  code 013
TKEY04  code 016
WSKEY6  code 020
```

The unpadded form (`13`) is not accepted by the monitor loader; use `013`.

Observed MAME/harness runs:

```text
KEYTE1  runs-archive/20260716-225619-b-keyte1-keyboard-test
TKEY04  runs-archive/20260716-230719-b-tkey04-run-no-keys
WSKEY6  runs-archive/20260716-232319-b-wskey6-continue-params
```

`KEYTE1` loads and enters a keyboard-test display surface. The reconstructed
text screen only shows a bordered blank area:

```text
Z                                                                              Z
Z                                                                              Z
```

This means the loader/FDU path is no longer the blocker. `KEYTE1` is now likely
waiting in an interactive keyboard/display phase, or it is using a display mode
not fully represented by the simple VRAM text reconstruction.

`TKEY04` reaches its parameter screen and test menu:

```text
TKEY04 PROGRAM
KEYBOARD L1 TEST BY COLOUR GRAPH.14"
SLOT ALPHA ?        (0-15)    11
SLOT GRAPH ?        (0-15)    10
KANA KEYBOARD ?     (0-1)     0
ARE THERE KEYS ?    (0-1)     0
TIME OUT ?        (1"..640")  10

1)  SELF DIAGNOSTIC TEST
2)? LEDS AND BUZZER TEST
3)  NUMERICAL KEYBOARD TEST
4)* DIODE STATUS TEST
5)* KEYS TEST
6)* ALPHABETICAL KEYBOARD TEST
```

`WSKEY6` is not the bare GO252 keyboard path. It advances into workstation/line
keyboard parameters, including serial-style settings:

```text
WSKEY6 PROGRAM
ELB3684 WS685/M KEYBOARD TEST
SLOT NUMBER ? (0-31) 11
LINE NUMBER ? (0-3) 0
SPEED ... 13 = 9600 BPS
LENGTH ... 4 = 8 BITS
PARITY ...
BIT STOP ...
```

### Current input-model problem

The newest diagnostic runs exposed a real KDC input-latching bug. The monitor
command byte used for `GO` (`4`, raw KDC byte `0x57`) can leak into the first
parameter prompt of the loaded diagnostic. Examples:

```text
TKEY04:
SLOT ALPHA ?        (0-15)    11     4

WSKEY6:
SLOT NUMBER     ? (0-31)     11      4
```

Attempts to avoid this by issuing monitor `4` without a following Enter changed
the phase but did not fully solve it; later parameter bytes were still consumed
out of phase. This matches the interactive symptom where characters appear to be
accepted by the emulator but the diagnostic immediately re-prompts or returns to
the menu.

The next emulator fix should therefore focus on keyboard queue/latch/ack
semantics, not on the FDU loader. The likely area is the interaction between the
GO252 FE data handshake, the UC `0xff20`/`0xff22` path, `m_kdc_pending`, and when
a byte is popped/acknowledged by the interrupt handler versus by FE register
reads.

## FIFO initialization

In `re/disassembly/diagnostics/go252/diskB_GRAPH3_77b00_7a600.dis`, the routine at `0x782d2`
initializes the keyboard receive FIFO:

```asm
782d2:  ldm <<33>>0x1740,r2,#4
782da:  ldar rr2,0x7578
782de:  clrb rl4
782e0:  di vi
782e2:  ldrl 0x8750,rr2   ; read pointer = buffer base
782e6:  ldrl 0x8748,rr2   ; write pointer = buffer base
782ea:  ldrb 0x75fc,rl4   ; count = 0
782ee:  ei vi
782f0:  ldm r2,<<33>>0x1740,#4
782f8:  ret
```

## FIFO producer

The enqueue routine starts at `0x77fd6`. It expects the received keyboard byte
already in `rl0`, then stores it at the write pointer if the FIFO is not full:

```asm
77fd6:  ldrb rl5,0x75fc
77fda:  cpb rl5,#0x80       ; full?
77fde:  jr nz,0x7fe4
77fe0:  resflg z
77fe2:  ret

77fe4:  ldrl rr8,0x8748     ; write pointer
77fe8:  ldar rr10,0x7578
77fec:  add r11,#0x0080     ; end = base + 0x80
77ff0:  ldb @rr8,rl0        ; enqueue received byte
77ff2:  incb rl5,#1
77ff4:  ldrb 0x75fc,rl5     ; count++
77ff8:  inc r9,#1           ; write pointer++
77ffa:  cpl rr10,rr8
77ffc:  jr nz,0x8002
77ffe:  ldar rr8,0x7578     ; wrap
78002:  ldrl 0x8748,rr8
78006:  resflg z
78008:  ret
```

This proves the diagnostic runtime has an interrupt/service path feeding a
software FIFO, and the resident segment-`0x1d` code now explains where the byte
comes from: a UC `0xff20`/`0xff22` status/data path wrapped by FE/KDC handshake
logic.

## FIFO consumer

The dequeue routine starts at `0x782a2`. It waits for a nonzero count, disables
maskable vector interrupts, removes one byte, returns the byte in `rl1`, and
decrements the count:

```asm
78284:  ldrb rl0,0x75fc
78288:  testb rl0
7828a:  jr z,0x8284         ; wait for byte available

782a2:  calr 0x8284
782a4:  di vi
782a6:  ldrl rr8,0x8750     ; read pointer
782aa:  ldb rl1,rr8(#0)     ; received byte -> rl1
782ae:  inc r9,#1           ; read pointer++
782b0:  ldar rr10,0x7578
782b4:  add r11,#0x0080     ; end = base + 0x80
782b8:  cpl rr8,rr10
782ba:  jr nz,0x82c0
782bc:  ldar rr8,0x7578     ; wrap
782c0:  ldrl 0x8750,rr8
782c4:  ldrb rh1,0x75fc
782c8:  decb rh1,#1
782ca:  ldrb 0x75fc,rh1     ; count--
782ce:  ei vi
782d0:  ret
```

Several test paths call this consumer rather than reading the keyboard hardware
directly. This is why the high-level `KEYTE1` code initially looked like it was
using monitor abstractions.

## Test-level byte handling

The keyboard test compares bytes from test tables with bytes received from the
FIFO. Relevant table/control markers in the same overlay include:

```asm
78368:  ldb rl5,@rr8
7836e:  cpb rl5,#0xff       ; table terminator
7837a:  cpb rl5,#0xfd       ; special control marker
78380:  cpb rl5,#0xfe       ; indirect/alternate expected byte marker
78396:  ldrb 0x8761,rl5     ; expected byte
783a4:  calr 0x8284         ; wait until FIFO count nonzero
783ae:  calr 0x800a         ; dequeue path, returns received byte in rl5/rl1 context
783ca:  ldrb rl5,0x8761
783ce:  cpb rl5,rl1         ; compare expected vs received
```

The manual-documented special key values remain:

```text
LK press/release = 0x6f / 0x77
SH press/release = 0x6e / 0x76
CN press/release = 0x70 / 0x78
simultaneous keys = 0xfe
```

## What MAME made evident

Disk B can be mounted in the current MAME tree and traced headlessly. The useful
trace points are:

```text
0x75fc          FIFO count
0x8748          FIFO write pointer
0x8750          FIFO read pointer
0x7578..0x75f7  FIFO buffer
0x77fd6         enqueue routine, with received byte expected in rl0
0x782a2         dequeue routine, returns received byte through rl1
0x1d:03f0       FE control/status command helper
0x1d:02a4       direct UC/KDC byte interrupt entry, VI vector 0x28
0x1d:068e       descriptor-driven FE/KDC interrupt entry, VI vector 0x2c in the observed PSA
0xff20/0xff22   UC status/data byte path
```

The remaining unknown is narrower: the full bit meaning of `0xff20` status plus
the FE register-`0x01` shadow byte, the complete keyboard byte table, and the
exact descriptor state installed by each individual GO252 test once selected.

## KEYTE1 four-corner Z wait

The disk-B `KEYTE1` test can currently be loaded and started from the diagnostic
monitor with code `013` followed by `GO`. The observed screen containing a `Z`
in each corner is not a prompt for `ENTER`, right-arrow, or another keyboard
byte. A live watchpoint trace shows the CPU spinning in the test's GO252 command
completion wait before it reaches its keyboard-input phase.

Current trace artifacts:

```text
runs-archive/20260719-222850-keyte1-watch-flags3/
runs-archive/keyte1-watch-dump/extra3.log
runs-archive/keyte1-watch-dump/m40_seg_21.bin
runs-archive/keyte1-watch-dump/m40_seg_1d.bin
```

The blocking loop in live segment `0x21` is:

```asm
21:126e  ldrb 0x21:175f,rl0      ; command byte
21:1272  set  0x21:1730,#0       ; mark command busy
21:1278  calr 0x21:131a          ; submit GO252 command descriptor
21:127a  bit  0x21:1730,#0
21:1280  jr   ne,0x21:127a       ; wait until completion clears bit 0
21:1282  ret
```

The first command that reaches this wait is command byte `0x06`:

```text
WATCH keyte1_cmd_21175f   pc=00211272 addr=21175E data=0606
WATCH keyte1_flags_211730 pc=00211278 addr=211730 data=0001
WATCH keyte1_desc_2116e6  pc=0021130E addr=2116EC data=0100
PC sample                 pc=00211280
```

No later write clears bit 0 of `0x21:1730`. That is why interactive key presses
do not advance this screen. Earlier in the same run, the trace does observe
`0x21:1730` being cleared for a different temporary flag, so the watchpoint is
valid; the missing event is specific to this GO252 command completion path.

The command is submitted through the generic governo service:

```text
21:131a -> 21:1306 -> call 0x04:0018
04:0018 -> 03:0ddc
03:0ddc -> call through 0x00:0008
0x00:0008 currently points at 0x1d:0052
```

The descriptor-driven FE/KDC VI handler remains installed at vector `0x2c`
(`0x1d:068e`). The current MAME model is sufficient for diagnostic monitor
keyboard input, but it does not yet model the non-key asynchronous GO252 command
completion that should re-enter this service path and clear the diagnostic's
busy bit.

The vector-`0x2c` interrupt handler separates keyboard/data-ready interrupts
from command-completion interrupts:

```asm
1d:068e  ...                         ; vector 0x2c entry
1d:069e  ld r1,0x00:000c(r3)         ; FE register base
1d:06a2  inb rh0,@r1                 ; read FE/KDC status
1d:06a4  bitb rh0,#2
1d:06a6  jr nz,0x1d:06d0             ; data-ready path

1d:06b2  ldl rr6,rr2(#4)             ; no-data/completion callback
1d:06b6  call @rr6
1d:06be  ldb rh0,rr2(#0x0e)
1d:06c2  resb rh0,#5
1d:06c8  outb @r1,rh0
1d:06ca  ldb rl1,#3
1d:06cc  outb @r1,rl0                ; command/result byte

1d:06d0  ldb rl1,#3
1d:06d2  inb rl0,@r1                 ; read FE/KDC data byte
1d:06d4  ldl rr6,@rr2                ; data callback
1d:06d6  call @rr6
1d:06de  ldb rl0,rr2(#0x0e)
1d:06e2  resb rl0,#7
1d:06e8  outb @r1,rl0
```

For the stuck `KEYTE1` run, the relevant completion callback is visible in the
loaded test:

```asm
21:0f9c  ldrb rl0,0x21:175f          ; return last command byte
21:0fa0  res  0x21:1730,#0           ; clear command-busy bit
21:0fa6  setflg z
21:0fa8  ret
```

So the expected sequence after command `0x06` is not a key press. GO252 should
assert the KDC VI with status arranged so `1d:068e` takes the completion branch
at `1d:06b2`, calls the `21:0f9c` callback, clears `0x21:1730` bit 0, and lets
the initialization sequence continue to the next commands (`0x08`, `0x0a`,
`0x0c`, `0x10`, then `0x02`). The current emulator only asserts KDC VI for
queued keyboard bytes, which drives the `1d:06d0` data-ready branch and cannot
clear the command-busy bit.

## KDC control/status register — fully decoded (2026-07-20)

Fresh full disassemblies of the live segments are now in the repo (written from
`runs-archive/keyte1-watch-dump/`):

```text
re/disassembly/diagnostics/runtime/seg1d_fe_kdc_driver.dis   resident FE/KDC driver (seg 0x1d)
re/disassembly/diagnostics/runtime/seg21_keyte1_loaded.dis   loaded KEYTE1 (seg 0x21)
```

### Service-command mask/set table (1d:042c, used by the helper at 1d:03f0)

Each entry is a word `{OR set (high byte), AND mask (low byte)}` applied to the
FE control-register shadow and written to reg `0x01`:

| service cmd | word | effect on ctrl |
|---|---|---|
| 1 | `0x20FF` | **set bit 5** — TX/completion interrupt enable |
| 2 | `0x80FF` | **set bit 7** — RX (keyboard-data) interrupt enable |
| 3 | `0x007F` | clear bit 7 |
| 4 | `0x00FF` | no-op (re-write shadow) |
| 5 | `0x16F6` | mode: clear bits 0,3; set bits 1,2,4 (the boot's `0x16`) |
| 6 | `0x1DFD` | mode: clear bit 1; set bits 0,2,3,4 |
| 7 | `0x60FF` | set bits 5,6 |
| 8 | `0x009F` | clear bits 5,6 |
| 9 | special | require status bit 1 (TX ready) else error `0x8006`; ctrl: clear bit 5, set bit 6; write byte to reg `0x03` (direct send) |

`KEYTE1`'s submit (`21:131a`, `r0=0x0100` on descriptor `21:16e6`, device ID
`0xFE01`) is **service command 1 = set ctrl bit 5**.

### Vector-0x2c handler (1d:068e) — complete branch logic

```asm
inb  rh0,@r1              ; read FE status (reg 0x01)
bitb rh0,#2 ; jr nz RX    ; bit 2 set -> RX data path
bitb shadow,#7 ; z -> TX  ; if RX armed (bit 7) and
bitb rh0,#0 ; jr nz RX    ;   status bit 0 set -> RX path too
TX:  call cb(+4)          ; completion callback (KEYTE1: 21:0f9c ->
                          ;   rl0 = command byte, busy cleared, Z = last byte)
     jr nz, send          ; NZ = more bytes follow, keep bit 5
     ctrl &= ~bit5; outb  ; Z  = last byte: disable TX interrupt
send: outb reg3, rl0      ; ALWAYS transmit the callback's byte
RX:  inb rl0, reg3        ; pop the received byte
     call cb(+0)          ; data callback (FIFO enqueue)
     if Z: ctrl &= ~bit7  ; callback may disarm RX
```

So the register model, now definitive:

```text
FE reg 0x01 write (control): bit5 = TX-VI enable, bit6 = direct-send handshake,
                             bit7 = RX-VI enable, bits0-4 = mode
FE reg 0x01 read  (status):  bit1 = TX ready, bit2 = RX byte available,
                             bit0 = alternate RX condition (when bit7 armed)
FE reg 0x03:                 data — read pops the RX byte, write transmits a
                             byte (command) to the keyboard MCU
```

### Why the four-Z screen stalled, definitively

`KEYTE1` submits service cmd 1 (set bit 5). On hardware the empty transmitter
immediately raises the VI (vector `0x2c`); the handler takes the TX branch
(status bit 2 clear), the callback `21:0f9c` clears the busy bit `0x21:1730.0`
and supplies command byte `0x06` (Z = single byte), the handler clears bit 5
and writes `0x06` to reg `0x03` — the actual command to the keyboard MCU. The
emulator previously raised the KDC VI only for queued keyboard bytes (RX), so
the TX/completion interrupt never fired and the busy bit never cleared. It was
never a keyboard-input wait.

The emulator model (m40.cpp) now implements: status = `0x02 | (rx ? 0x04 : 0)`;
VI level = `(rx-pending && ctrl.bit7) || ctrl.bit5`; reg `0x03` writes are
consumed as KDC command bytes (multi-byte commands re-raise the level TX VI
until the driver clears bit 5).

### KDC command 0x02 = read keyboard ID/jumpers (response required)

With the TX VI modelled, the trace shows all six init commands transmitted
(`06 08 0a 0c 10 02`, at `1d:06ce`). The next blocker is `21:062c`:

```asm
062c: calr 0x100a           ; dequeue FIFO byte -> rl5
062e: cpb  rl5,#0xfb        ; wait for the 0xFB marker
0632: jr   nz,0x062c
0634: calr 0x100a           ; second byte = config:
0638: andb rl5,#0x1f        ;   low 5 bits  = keyboard layout code
063c: srlb rh5,#5           ;   high 3 bits = jumper status
```

So command `0x02` elicits a two-byte response from the keyboard MCU: `0xFB`
followed by a config byte. The recovered 8049 ROM now explains the exact path:
command `0x02` sets internal CONTROL bit 1; the foreground sends `0xFB`, clears
the request, then sends the raw P2 sample captured at reset with the matrix row
selector released. Thus the second byte is a strap/input sample, not a firmware
constant. The layout code indexes the name table at `21:22d0`
(`0 INTERNATIONAL, 1 LATIN/FARSI, 2 LATIN/ARABO, 3 DEUTSCHLAND, 4 PORTUGAL,
5 SPAIN-1, 6 DANMARK, 7 FRANCE, 8 LATIN/GREEK, 9 LATIN/JEWISH, 10 ITALY,
11 JAPAN, 12 NORWAY, 13 SWEDEN/FINLAND, 14 SWITZERLAND, 15 USSR, 16 GREAT
BRITAIN, 17 USA ASCII, ...`); layout 11 (JAPAN/Kana) is the `cpb rl5,#0x0b`
special case that selects the 5-row keyboard display. The jumper field indexes
the strings at `21:262e` (`4 = M.F.U., 5 = W.P., 6 = P.M., 7 = D.P.`).

The current emulator responds with `0xFB, 0xF1` (USA ASCII, D.P./KUSA02). The
response value is a selected HLE configuration. Its present sequence recognizer
is not firmware behavior: the 8049 independently dispatches every command from
`0x00` through `0x10`. In particular `0x01` returns its ROM-test byte (`0xFA`
pass/`0xF9` fail), while `0x06 08 0A 0C 10` merely restore the five indicator
outputs to their idle states before KEYTE1 sends `0x02`.

Full ROM-to-diagnostic correlation and the MAME audit are in
`M40_8049_KEYBOARD.md`.

## Emulation implication

For a first functional model, it is reasonable to emulate the diagnostic-visible
behavior as:

```text
GO252 keyboard byte arrives
  -> expose ready/status on the UC 0xff20 path and/or FE control-status latch
  -> assert VI with vector 0x28 for the diagnostic-monitor direct byte path
  -> handler 0x1d:02a4 reads the byte into rl0 from the 0xff22 data path
  -> enqueue at 0x77fd6 into the 128-byte FIFO
  -> KEYTE1 consumes bytes through the dequeue routine
```

This is now more than a pure software model: it identifies the diagnostic-visible
status/data path. It is still not a complete electrical model of GO252 because
the meanings of several handshake bits in the FE control register and `0xff20`
status byte remain to be assigned.
