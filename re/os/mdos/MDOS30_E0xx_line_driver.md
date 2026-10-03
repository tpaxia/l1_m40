# MDOS30 E0xx wait loop and line-controller evidence

## 2026-07-22 current result: disk loading passes; MDOS waits on E0xx

The earlier first-catalog-read failure was caused by the MAME GO280 model, not
by the MDOS catalog or DMA mapping.  The failing sequence was:

1. GO280 successfully read the FSEL sector into physical byte address
   `0x025146`; the buffer contained `FSEL` and the requested `1KYB` entry.
2. MDOS issued `SENSE DRIVE STATUS` and received `ST3=0x29` (ready).
3. GO280 changed `CONTR` from `0x13` to `0x03`, clearing `DIAGN`.
4. The driver called `upd765::ready_w(true)`, which means **not ready** in
   MAME's inverted external-ready API.
5. The resulting ready-to-not-ready edge raised an FDC interrupt.  GO280's
   interrupt handler issued `SENSE INTERRUPT STATUS`, received the no-pending
   poll values `C0 00`, `C1 01`, `C2 00`, `C3 00`, and overwrote the valid read
   result.  Its request-state byte became `0x33`, which the completion routine
   returned as software error `0x9000`.

The hardware manual says that `DIAGN` can force `RDY10`, but also that RDY10 is
pulled up on the MFDU interface.  Clearing `DIAGN` therefore must not force a
not-ready level.  Keeping MAME's external ready input asserted (`ready_w(false)`)
removes the false edge.

With that correction, the unmodified `MDOS30.IMD` advances through 23 GO280
read commands and 18 seeks in the 120-second verification run.  It loads code
to additional RAM windows, executes segment `0x3e`, and initializes the E0xx
line interface.  The observed line accesses are:

```text
W 3e:014e E008 <- A7
W 3e:0156 E008 <- A7 40 4E 27
W 3e:0160 E0B0 <- 00
R 3e:0164 E000 -> 00
R 3e:0168 E000 -> 00
```

After initialization the CPU spends its time in the MDOS scheduler at
`00:0912..0920`, receiving timer interrupts.  This is an idle/wait state, not
an FDC loop.  The screen remains blank because this disk configuration is now
using the E0xx line/terminal path; the current E0xx stub neither models that
governo nor supplies terminal input.

### Definite E000/E008 device identification: Intel 8251-style USART

The loaded segment `3e` initializes `E008` with this exact sequence:

```asm
ldl  rr6,#a7404e27
outb @e008,#a7       ; one preliminary dummy write
outb @e008,#a7       ; loop byte 1: dummy
outb @e008,#40       ; 8251 command: internal reset
outb @e008,#4e       ; 8251 mode word
outb @e008,#27       ; 8251 command word
```

That sequence and the runtime status tests identify the interface as an
Intel 8251-compatible USART rather than a Z80 SIO register protocol:

```text
E000 read/write  USART receive/transmit data
E008 read        status bit 0 = TxRDY
E008 read        status bit 1 = RxRDY
E008 read        status bit 2 = TxEMPTY
E008 write       mode/command programming
```

The driver polls bit 0 before every byte written to `E000`, tests bit 1 before
reading `E000`, and tests bit 2 before the word-transfer path at `3e:04a6`.
Ports `E080`, `E090`, `E0A0`, `E0B0`, `E0C0`, and `E0D0` are surrounding
governo timer/interrupt/DMA glue; their exact devices and bit meanings are not
yet proven.

Posting ENTER after initialization proves that the receive and interrupt path
is active.  The stub queues ASCII `0x0d`, asserts the line VI, and segment `3e`
performs the following exchange:

```text
R 3e:02d4 E008 -> 03   ; TX-ready + RX-ready
R 3e:02f6 E000 -> 0D   ; consume ENTER
W 3e:03d2 E000 <- 23 31 31 0A   ; "#11\n"
W 3e:0342 E0D0 <- 03
```

A second ENTER repeats the same response.  The meaning of `#11` is not yet
decoded, but it is transmitted terminal text, not video RAM.  Rendering bytes
written to `E000` in a serial-terminal view (and feeding its input back to the
line FIFO) is the next useful integration step.

Verification artifacts:

```text
runs-archive/20260722-184254-mdos30-ready-fix/
runs-archive/20260722-184411-mdos30-ready-state/
runs-archive/20260722-184604-mdos30-ready-input/
runs-archive/mdos30-ready-line.log
```

## Current MDOS30 boot state

The following section records the earlier state before the READY correction
and other MMU/Z8000 fixes.  It is retained to explain the investigation, but it
is no longer the current execution boundary.

There are three distinct blockers.  They must not be collapsed into one FDU
failure:

1. With ROM 6.0, the ROM fingerprint changes the startup-library key from
   `J0XP` to `J0XJ`.  The disk exports `J0XP`, not `J0XJ`, and the loader stops
   in its intentional `#NO#` loop at `03:05c6`.
2. With the locally archived ROM 4.1, the key remains `J0XP`.  The resident FDU
   path then requires RDGNN bit 0 (`WREN1`) to be clear after vector `08` is
   installed.  The experimental driver setting used for this is
   `M40_FDU_RDGNN_VEC08=0xfe`.
3. After those two conditions, the stock MDOS30 startup loader stops in its
   explicit `#OVF# SG2#` loop at `03:073e`.  This is not an FDC timeout.

The previously observed `3e:0470` E0xx wait loop is reachable only after the
SG2 allocation issue is bypassed.  The rest of this document describes that
later state.

### SG2 symptom and GO280 root cause

The `J0XP` loader's module loop is at `03:068e..075c`.  Its overflow check is
valid when the module header has survived the load:

```asm
03:06f4  ld   r10,rr2(#6)       ; module byte length from library table
03:06f8  ld   r1,r12
03:06fa  add  r1,r10            ; reject file if it cannot fit
...
03:0718  ld   r0,rr6(#0x0c)     ; expanded allocation size
03:071c  or   r0,r0
03:071e  jr   nz,03:0724
03:0720  ld   r0,rr6(#0x0a)     ; fallback size
03:0724  add  r0,#0xff
03:0728  xorb rl0,rl0           ; round to 256 bytes
03:072a  add  r12,r0
03:072c  jr   nc,03:0740
03:072e  print "OVF#" / "SG2#" and stop
```

The earlier interpretation was that KER was a special headerless root module and
that JLD incorrectly applied the normal header rule.  A trace of both the FDC data
and AM9517 register accesses disproved that interpretation.  The header is meant to
remain at the module base; it was being overwritten by the next disk extent.

BCOS JLD0 A.02 reads KER0 A.02 in two FDC commands.  The first transfers `0x1300`
bytes to physical `0x027d00` and includes the intact `KER0A.02` header.  The second
transfers `0x0c00` bytes.  The BCOS FDU driver at `3b:17b6` reads back the AM9517
channel-1 current address after the first command and uses it as the next destination.
On the real GO280, every pair of channel-2 byte cycles requests one address-only
channel-1 cycle, so that current address advances by one word.  The first transfer
therefore changes channel 1 from `0x3e80` to `0x4800`, and the second extent belongs
at physical `0x029000`.

The old GO280 emulation moved the bytes with a private cursor but never generated
those channel-1 cycles.  The AM9517 current-address register remained `0x3e80`, so
BCOS started the second extent at `0x027d00` again.  This overwrote the header and
first executable extent.  JLD then correctly read header field `+0x0c`, but found
executable opcode `0xed06`; rounding it to `0xee00` made the following KIO0 allocation
carry and produced blinking `OVF#SG2#`.

The fix makes each channel-1 DREQ self-clearing and raises it after every second
channel-2 byte in both transfer directions.  The unmodified all-resident BCOS 3.3
image then loads subsequent modules and reaches its resident-system display.  The
temporary JLD size patches were useful probes because they bypassed the corrupted
field, but they are not fixes and are no longer needed.

The same mechanism is a strong candidate for the analogous MDOS30 stop, but that
ROM-4.1 path still has its separate ROM-key and `WREN1` prerequisites and must be
retested independently before declaring MDOS fixed.

### BCOS 3.3 comparison with DCOS and the Z8010

A direct MMU-command trace rules out the recent Z8010 descriptor-selection-counter
change as the cause.  Both the working DCOS 8.4 diagnostic boot and BCOS 3.3 program
their live maps with command `0x0f`; neither executes command `0x0b` on the path to
the old overflow.  The recent MAME change only makes the two-bit DSC wrap from
attribute byte 3 back to base-high byte 0 for the non-SAR-incrementing commands.
This agrees with the Z8010 data sheet and with UCV305's exhaustive DSC test.

At the failing BCOS read, segment 2 had descriptor `02 7d ff c0`, so logical
`02:000c` translated to physical `0x027d0c`.  The MMU returned exactly the bytes
that the overlapping second DMA extent had placed there.  Translation was correct;
the corruption occurred before the CPU access.  Increasing configured RAM could
not help because the apparent overflow was a bogus 16-bit allocation value, not a
physical-memory shortage.

DCOS remains a useful hardware-path control but not a JLD allocation-format control.
Its `SYS0` stage loads one fixed `0x0e00`-byte monitor image directly into segment 25
and later loads diagnostic overlays.  It does not boot through the JLD0/KER0 module
loop.

The Z8010 audit did expose two separate edge cases worth testing independently:

* `INC_SAR` and `INC_DSC_SAR` currently saturate SAR at descriptor 63, although
  SAR is a six-bit hardware counter and may need to wrap to zero.  The observed
  BCOS/DCOS boot sequences do not depend on the post-descriptor-63 value.
* The S8000 wrapper invalidates CPU address-space caches after every MMU command,
  while the M40 wrapper invalidates them only on mode changes.  Descriptor remaps
  followed by execution at an already-cached logical address need a focused test.
  Data reads such as the BCOS `02:000c` allocation operand still pass through the
  correct live translation, so this does not explain the present overflow.

Earlier E0xx run form:

```sh
python3 tools/m40_harness.py run \
  --mame-bin "$M40_MAME_BIN" \
  --disk 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/MDOS30.IMD' \
  --name mdos30-post-fixes --seconds 240 --vram-trace --fdu-trace   # options since removed
```

The final FDU event is a successful `READ DATA` completion:

```text
RESULT READ DATA [MT MFM] bytes=05 00 00 01 01 06 01
CONTR=00(none)
```

This later failure is no longer in FDU boot loading.

## Stuck code path

A PC probe after the SG2 bypass shows a tight loop in segment `0x3e` around
offset `0x0470`:

```text
pc=003E0470/0474/0476/0478/047A fcw=D804/D844
r0=070A r1=E09E r2=0000 r3=0004 r4=005A r5=005A r6=B800 r7=00D8
r14=0700 r15=E09A
```

Disassembly of the dumped segment:

```asm
3e046e: calr 0x3e051a
3e0470: bit  0x3e000024,#0x5
3e0474: jr   ne,0x3e0496
3e0476: ldctl r8,fcw
3e0478: bit  r8,#0xc
3e047a: jr   ne,0x3e0470
3e047c: inb  rl0,#0xe008
3e0480: bitb rl0,#0x1
3e0482: jr   eq,0x3e0470
3e0484: ldctl r8,fcw
3e0486: ldar rr4,0x3e0470
3e048a: pushl @rr14,rr4
3e048c: push  @rr14,r8
3e048e: push  @rr14,r8
3e0490: ldar rr10,0x3e02a2
3e0494: jp   t,@rr10
3e0496: res  0x3e000024,#0x1
3e049a: res  0x3e000024,#0x5
3e049e: jr   t,0x3e0528
3e04a8: inb  rl0,#0xe008
3e04ac: bitb rl0,#0x2
3e04ae: jr   eq,0x3e04a8
```

The surrounding code also accesses:

```asm
3e02d0: inb  rl0,#0xe008
3e02d8: outb #0xe0c0,rl0
3e02f2: inb  rl0,#0xe000
3e033e: outb #0xe0d0,rl0
3e03c4: inb  rl0,#0xe008
3e03ce: outb #0xe000,rl0
```

This is the strongest current anchor: the routine has an `E0xx` I/O path, but
the live hang does **not** currently reach the `inb #0xe008` at `3e047c`. A
focused trace shows the CPU cycling through `3e0470..3e047a` with FCW bit 12 set.
In MAME's Z8000 source, FCW bit 12 is `F_VIE` (`0x1000`, vectored interrupt
enable). The loop therefore behaves as:

1. if local flag bit 5 is set, take the service path;
2. otherwise, if vectored interrupts are enabled, keep waiting for interrupt-driven
   service;
3. only when vectored interrupts are disabled, poll `E008` bit 1 and synthesize
   the service path manually.

So the current live hang is "waiting with VI enabled and no relevant VI service",
not "polling `E008` and seeing the wrong status bit".

## Important interpretation: E0xx is a governo I/O window, but not yet proven as physical slot E

The ROM slot scan uses the high nibble of the I/O address as the physical governo
slot/window. The board logical type is read from the slot's type register, not
encoded by the CPU port high byte.

For example, the ROM records a 4-byte config entry for each slot:

```text
+0 = type-ID / nome logico
+2 = diagnostic response word
```

Known type IDs from the collaudi notes include:

```text
FF UC
FE video/keyboard
E1 FDU
E0 MFDU
D1 TTL line
D2/D3 V24 line
D4/D5 X24 line
D7 LION 9.6 line
CF Twin RS232 / Current Loop
E4 HDU
E6 STC
```

Earlier notes treated `E000` / `E008` as proof of "physical slot E". That is no
longer certain. The current MDOS30 trace shows that MDOS builds and consumes a
four-entry active governo table, then uses `E0xx` while running with the MMU/SIO
context installed by the booted monitor. So `E0xx` is definitely an I/O window
access with low registers `00/08/b0/c0/d0`, but it may be a logical/current
governo window selected by the OS rather than a direct statement that the board
is physically in slot E.

Evidence from `M40_MDOS_TRACE` on the run:

```text
runs-archive/20260722-043956-mdos30-driver-mdos-trace
```

The ROM first clears the config/catalog RAM image:

```text
CFGW pc=000003AE ... log=010230..01026E phys=08FE30..08FE6E data=0000
```

Then it fills the table by probing the emulated hardware:

```text
slot 0: FF-0000
slot 1: FE-0000
slot 2: E1-0000
slot 3: FF-0000
```

The writer PCs are:

```text
000005B4 writes the high-byte type ID
000005C4 writes the following diagnostic/auxiliary word
```

At the later MDOS wait loop, the code only reads entries `0..3`:

```text
CFGR pc=003E0474/003E0476 ... log=010230..01023E phys=08FE30..08FE3E
r3=0004
```

The apparent 16-slot `FF FE E1 FF` repetition from the Lua periodic dump is
therefore best treated as an MMU/windowing artifact until proven otherwise. The
active table consumed by the stuck loop is four entries, not a literal sixteen
entry list proving phantom hardware in slots `5/6/9/a/d/e`.

## Disk C line-controller tests

Disk C is the line-controller diagnostic disk:

```text
Image: reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/C.IMD
Catalog special: UTILY884871127
```

Extracted/disassembled local files:

```text
re/disassembly/diagnostics/line/004_LCUX2681850329.bin/.dis
re/disassembly/diagnostics/line/005_TWIN0581850329.bin/.dis
re/disassembly/diagnostics/line/006_W24D0883861117.bin/.dis
re/disassembly/diagnostics/line/007_LIONV481850329.bin/.dis
re/disassembly/diagnostics/line/014_L2V24883861117.bin/.dis
re/disassembly/diagnostics/line/015_V24L2783861117.bin/.dis
re/disassembly/diagnostics/line/017_L9V24483861117.bin/.dis
```

The most relevant catalog entries are:

```text
004 LCUX26  GLAV/LCUX line controller
005 TWIN05  twin/line controller
006 W24D08  V24/current-loop class test
007 LIONV4  LION line controller
014 L2V248  V24/LION200 support test
015 V24L27  V24/LION support test
017 L9V244  LION 9.6/V24 support test
```

`006_W24D0883861117.bin` contains explicit GO151/GO327 diagnostic strings:

```text
DRIVER GO151:(BIT 1-3)BOARD POS.D09
DRIVER GO327:(BIT 0-4)BOARD POS.A10
STATUS REGISTER   ADDRESS %A1 :
DRIVER NAME       ADDRESS %E7 :
SERIAL CONTROLLER SIO/0 ERROR
COUNTER-TIMER 8253 ERROR
CURRENT LOOP INTERFACE
RTS/CTS/DCD/DSR/TXD/RXD signal checks
```

This matches the hardware notes/photo for GO151 as a serial-line governo with a
Z80 DART/SIO-family serial controller, an 8253 timer, and a baud clock. The M34/M44
manual identifies related line governi as:

```text
GO300  V24 external line      logical D3/D2
GO303  X24 line               logical D5
GO333  LION 9.6 line          logical D7
GO327  twin/current loop/RS232 logical CF
```

## Register evidence from the line tests

The line diagnostics do not contain direct accesses to the exact MDOS service
ports `E000`, `E008`, `E0B0`, `E0C0`, or `E0D0`.

The smaller line tests instead use slot-windowed direct or indirect ports with
low offsets typical of a SIO/CTC/8253-style board, for example:

```text
0x6001 0x6003 0x600b 0x6013 0x601b 0x601d
0x6021 0x6023 0x6027 0x602b 0x602d 0x6031 0x6035 0x6039 0x603d
0xa001 0xa003 0xa015 0xa01b 0xa01d 0xa02d 0xa039 0xa047 0xa057
0xc001 0xc003 0xc015 0xc01b 0xc01d 0xc02d 0xc039 0xc047 0xc057
```

That mismatch matters. It means the MDOS30 `E0xx` path is not simply the same
low-level test code talking directly to the raw SIO/8253 register map. It may be:

1. a resident MDOS line/terminal driver abstraction for a board physically in
   slot E;
2. a different subinterface/register bank on a line governo;
3. a configuration-table mistake in emulation causing MDOS to believe a line
   device exists in slot E;
4. a missing READY/NMI/interrupt behavior for an unimplemented governo slot.

## Real ESE machine clue

The real `ESE.jpg` boot photo shows:

```text
L1/ESE-R 3.1
MEMORY SIZE = 192 K BYTES
SYSTEM PRINTER: NO
VIDEO DISPLAY: ALPHANUMERIC
I/O INTERFACES:
DISK UNIT(S) = F1 C0 FDU
               F2 C1 FDU
```

The blank `I/O INTERFACES:` line is important. If this MDOS30 image is intended
for that configuration, it should not need an external line governo to reach a
visible prompt. If the emulated machine is driving `E0xx` as a line interface,
the next suspect is the emulated configuration/slot scan state, not the FDU.

## Current hypothesis

The stuck loop is most likely a console/line-driver wait in MDOS30, not a floppy
read failure. The tests/manuals identify the likely hardware family as the
M30/M40 line-controller group, especially GO151/GO327-class serial/current-loop
hardware, but they do not yet prove the exact semantics of `E000/E008/E0B0/E0C0/E0D0`.

A focused Lua trace (`re/os/mdos/leftovers/mame_m40_mdos30_slot_probe.lua` (removed; in tag `re-leftovers-archive`)) can show the logical
config image later containing repeated `FF FE E1 FF` groups:

```text
0:FF-0000 1:FE-0000 2:E1-0000 3:FF-0000
4:FF-0000 5:FE-0000 6:E1-0000 7:FF-0000
8:FF-0000 9:FE-0000 A:E1-0000 B:FF-0000
C:FF-0000 D:FE-0000 E:E1-0000 F:FF-0000
```

The driver-side physical/logical trace changes the interpretation: the active
loop reads only the first four entries, and `r3=0004` at `003E0474/003E0476`.
So the repeated Lua view is not enough evidence for phantom slots.

The next useful step is not to add a fake board at physical slot E blindly. The
better path is to trace the MDOS interrupt setup around `003E014E..003E047A` and
identify which VI source/vector is expected to set bit 5 at `3e000024`, then compare
that with disk C `W24D08`/`V24L27` line diagnostics under a broad line-board I/O tap.
If those diagnostics show the same low-register protocol (`00/08/b0/c0/d0`) then a
minimal GO151/GO327-style device model is justified.

## 2026-08-15 correction: the historical line path was an emulation artifact

The provisional slot-E line card was removed. A direct comparison with the old
monolithic driver showed why that binary entered segment `3E`: an access to an absent
slot returned a type byte of `FF` followed by a bogus auxiliary word of `0000`. The
current backplane correctly reports an absent device as `FF-FFFF`, matching the
hardware diagnostic behavior. The malformed `FF-0000` configuration entry selected
the historical `3E`/`E0xx` path; it is not evidence that this system needs a line card.

With the normal ROM 6.0, `MDOS30.IMD` loads and remains in the valid scheduler loop at
`02:0912..0920`. It does not access window E. The disk's embedded environment says
`VIDEO DISPLAY: GRAPHIC`, so its blank GO252 display is now treated as a media/configuration
mismatch requiring identification of the expected graphics console, not as a missing
8251 governo.

Forcing the older 4.1 ROM is a separate compatibility failure. That combination loads
a module in segment `4A`, maps it with descriptor `08 DC 34 C0`, obtains entry offset
`4D34` from the module word at `4A:0014`, and immediately takes a segment-length
violation because the mapped limit is `34FF`. The translated target is unpopulated
(`FFFF`). This does not occur with ROM 6.0 and should not be used to infer the normal
MDOS console hardware.
