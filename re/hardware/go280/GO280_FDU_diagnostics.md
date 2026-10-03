# GO280/FDU diagnostic reverse engineering notes

This note collects the disk/manual evidence and the useful disassembly anchors for
reverse engineering the communication between the CPU and the FDU/MFDU governo
board (GO280/G0280 family).

## Relevant manual tests

### Four-unit numbering audit (2026-09-10)

Ran DCOS D.IMD program007 (`6030T6`, XU6030 RUNNING TEST), slot2,
separately selecting PU1,2,3,4. All four MAME FDC connectors were populated
with disposable copies of the same diagnostic disk. No guest RAM patches
or native emulation changes were used. Tests are bounded at230 seconds:
these results cover compatibility, not the entire read/write suite.

| Displayed PU | Run under runs-archive/fdu-validation.* | Controller selector | Result at test5 |
|---|---|---|---|
| 1 | BLu4DD | 01 | identifies unit1, MFM256, no defective tracks |
| 2 | BZYVDi | 02 | identifies unit2, MFM256, no defective tracks |
| 3 | 1P16nc | 03 | identifies unit3, MFM256, no defective tracks |
| 4 | B79o14 | 04 | POSITIONING ERROR / UNKNOWN HD POSITION |

PU4 trace at210.4709675 sends RECALIBRATE `07 04`, followed by SENSE
INTERRUPT `08` returning `20 00` (unit0, seek complete, cylinder0).
It then sends READ DATA `06 04 00 00 05 00 1A 0B FF` and receives
`44 01 00 00 00 05 00`. Selector04 includes HD=1 and US=00, although
the requested sector-ID H parameter is00. The image's physical C0/H1 is
MFM256 whereas this is an FM/128-byte read. This is not a successful PU4
mapping test and must not be described as one.

These independent diagnostics corroborate that software passes one-based
PU numbers directly to the FDC for1–3, and that4 wraps at the two-bit unit
field. They do NOT establish that fourth-drive handling is correct. In
particular the diagnostic's unmasked04 and BCOS's observed00 are distinct
command bytes; do not conflate their head-selection behavior. Further
work must explain the diagnostic's PU4 command construction before any
MAME image-device renumbering. No evidence here justifies changing the
765's two-bit unit decode.

Temporary instrumentation: re/hardware/go280/leftovers/mame_fdu_unit_trace.lua wraps the existing
timed-key script, records FIFO accesses after130s and screenshots every20s
from120–220. scripts/test-m40-fdu.sh accepts optional M40_FDU_SCRIPT;
default behavior is unchanged. Logs are screen.png.fdc.log in each run.

The functional-checks manual chapter 10 is the best map for the floppy/minifloppy
diagnostics:

- `7032E5` - FDU/MFDU error-rate program. Hardware list includes an MFDU or
  XU6030 FDU with `G0280/B-D` controller.
- `FDUMA2` - FDU alignment/eccentricity check. Hardware list includes XG6030
  FDU, `G0280/B-D`, and DAT82/MFM256 or DF128 test disk media.
- `6030T6` - XU/XG6030 FDU peripheral test. Hardware list includes XG6030 FDU,
  `G0280/B-D`, and scratch disk standard 20.

For reverse engineering GO280 communication, `6030T6` is the most valuable target.
It has explicit controller communication, timer, interrupt, DMA, format, seek,
read/write, deleted-data, control-mark, and cylinder tests. `FDUMA2` is useful
after the basic protocol is understood, because it exercises margin/alignment
flows rather than starting from controller primitives.

The older Italian collaudi OCR has related but less directly useful entries:

- `MPFDER` - FDU error-rate program, with hardware including CPU, RAM, governo
  floppy-minifloppy, and FDU.
- An overlap test using FDU/MFDU/HDU/video/keyboard/printer, which is more of a
  system integration test than a controller protocol reference.

## Disk image and catalog evidence

The relevant image is disk D:

```text
reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/D.IMD
```

Extracted flat image:

```sh
python3 tools/imd.py \
  "reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/D.IMD" \
  extract /tmp/diskD.bin
```

Catalog summary:

```text
catalog offset=0x31500 sectors=8 special=UTILY884871127
idx ext loc   len  flat_sec  flat_off  bytes  name
  2  00   106c  01       927  0x39f00    256  HDFDU784870331
  3  00   122c  05       967  0x3c700   1280  7032E584870331
  4  00   12f8  31      1171  0x49300  12544  FDUMA280840810
  5  00   17aa  25      1353  0x54900   9472  4301T483851212
  6  00   1aca  33      1541  0x60500  13056  4305T684870331
  7  00   1ece  2d      1753  0x6d900  11520  6030T683861117
  8  00   22ca  2b      1957  0x7a500  11008  SCT30381850329
```

The menu embedded in `6030T6` confirms it is the right test:

```text
6030T6 XU6030 RUNNING TEST
1) CONTROLLER COMMUNICATION TEST
2) TIMER TEST
3) INTERRUPT TEST
4) DMA TEST
5) COMPATIBILITY TEST
6) SPEED MEASUREMENT TEST
7) SEEK TEST
8) FORMAT TEST
9) READ TEST
10) WRITE & READ SECTOR TEST
11) WRITE & READ DELETED TEST
12) CONTROL MARK TEST
13) WRITE & READ CYLINDER TEST
```

`4301T4` and `4305T6` contain very similar menus for MFDU variants. They are good
comparison binaries after `6030T6` is mapped.

## Useful disassembly files

These scratch disassemblies were produced with `tools/z8kdisrom`:

```sh
tools/z8kdisrom /tmp/diskD.bin 6d900 7c780 > /tmp/diskD_6030_6d900_7c780.dis
tools/z8kdisrom /tmp/diskD.bin 60500 63700 > /tmp/diskD_4305_60500_63700.dis
tools/z8kdisrom /tmp/diskD.bin 49300 52400 > /tmp/diskD_FDUMA2_49300_52400.dis
```

Repository copies:

```text
re/disassembly/diagnostics/diskD_6030T6_6d900_7c780.dis
re/disassembly/diagnostics/diskD_4305T6_60500_63700.dis
re/disassembly/diagnostics/diskD_FDUMA2_49300_52400.dis
```

The most useful low-level routines are in `6030T6` around image offsets
`0x79300..0x7ac96`. In the disassembler output these appear as segment `<<33>>`
runtime addresses with the low 16 bits, for example image `0x79324` is shown as
`<<33>>0x9324`.

## Port addressing convention

The FDU routines repeatedly use this pattern:

```asm
ldb     rh2,rl2
ldb     rl2,#PORT
inb/outb ...,@r2
...
ldb     rl2,rh2
```

The caller appears to pass the controller slot/select byte in `rl2`. The routine
copies that into `rh2`, then puts the register number in `rl2`. The 16-bit `r2`
therefore becomes:

```text
r2 high byte = controller slot/select
r2 low byte  = board register/port
```

This is why the code can access the same low register numbers (`0xe7`, `0xff`,
`0x1d`, `0x1f`, etc.) while preserving a variable high-byte controller address.

## GO280 register anchors

These agree with `re/hardware/go280/FDU_governo_3963590.md` and with the diagnostic code:

```text
0x1d  uPD765 main status register, read
0x1f  uPD765 data register, read/write
0x40..0x5e  AM9517/8237-style DMA controller registers
0xe7  CONTR board control register
0xed  diagnostic/readback port used by GO280 routines
0xef  vector/diagnostic related port; VETTN write in the hardware notes
0xf6  DMA high-address latch
0xf7  interrupt-status/readback register
0xff  ID/E01NT/interrupt strobe related register
0x99,0x9b,0x9d,0x9f  timer/counter register group used by the tests
```

## Embedded mfior routine names

The `6030T6` image contains C/Pascal-style external signatures for the FDU I/O
runtime. These are the useful names to align with disassembly:

```text
mfior_contrinit~WWP
mfior_fdcreset~WP
mfior_homesend~WWP
mfior_homeend~WP
mfior_dmaend~WP
mfior_dmasend~WWL
mfior_timersend~WWW
mfior_timerend~WWP
mfior_intrdisab~WP
mfior_intrenab~WP
mfior_intrtype~WP
mfior_motorend~WP
mfior_motorsend~WWP
mfior_motorstop~WP
mfior_contrtype~WP
mfior_drivstsend~WWP
mfior_drivstend~WP
mfior_contrreset~WP
mfior_timerreset~W
mfior_timerintr~WP
mfior_dmareset~W
mfior_dmaregisters~W
mfior_dmadynamic~WWL
mfior_exhwtest~WP
mfior_intrtest~W
mfior_settd~WP
mfior_resettd~WP
mfior_diagportread~WP
mfior_samplespeed~WWPP
```

The signatures are also a good hint about argument widths:

- `W` - 16-bit word argument.
- `L` - 32-bit long argument.
- `P` - pointer/result buffer.

## 2026-09-08: verified execution and current interrupt failure

Use `scripts/test-m40-fdu.sh` for a bounded background-only run using copies
of disk D. Main-monitor LOAD of `007` activates the program directly: input
slot `2`, accept default PU, then at the runtime menu select `1` and confirm
with Enter. Do not send monitor GO after LOAD, or type `3-1` at the runtime
menu. Functional Checks Manual 4102230 T(0), sections 1.2.3.3 and 1.2.5,
distinguishes main-monitor LOAD from HELP LOAD and explains the runtime menu.

Verified baseline run: `runs-archive/fdu-validation.dWB3HX/20260908-233924-fdu/`.
Controller communication and timer tests advance without a reported error;
test 3 stops with `FDC INTERRUPT NETWORK FAULT`. This is an executed failure,
not a menu capture. The diagnostic reads `F7=02` at runtime `21:A282` just
after EO1NT. The corresponding image routine is `7AA78`; it returns `r7=30`
when the FDC indication remains set.

Before that, at 161.330493 s, enabling CONTR=13 also enables DIAGN. A new
FDC IRQ arrives at 161.330749 s and the handler sees both cause bits (`03`).
The earlier timer pulse has already fallen, but its cause is still captured.
This exposes two separate questions: delivery of the captured timer cause,
and DIAGN/READY generating an FDC cause which survives the reset-strobe check.
Neither is proved fixed by merely suppressing VI re-entry in BCOS.

## 2026-09-09 final result: normal FDU READY wiring

**Supersedes the provisional timer-latch interpretation below.** The retained
fix removes the global READY override from CONTR bit 4. Normal FDU READY stays
connected to the selected drive. The timer-promotion experiment is reverted;
both timer and FDC enable promotion use live sources as before this investigation.

Causal controls:

| Model / media population | Result |
| --- | --- |
| Old global READY override, two disks | Test 3: FDC INTERRUPT NETWORK FAULT |
| Old override, four disks | Full vector sweep and DMA test complete without warning |
| Corrected normal READY, two disks | Same clean result; tests 1–6 advance to test 7 |
| Corrected normal READY, only boot disk | Same clean result |

Evidence: four-disk control `runs-archive/fdu-validation.MzdHrY/20260909-064315-fdu/`;
corrected two-disk run `runs-archive/fdu-validation.5rPNeZ/20260909-064718-fdu/`;
boot-disk-only run `runs-archive/fdu-validation.Vg2woa/20260909-064908-fdu/`.
All end normally after 230 emulated seconds. This is not a claim that tests
7–13 completed: the final screen is in test 7. The prior `interrupt not disabled`
warning is absent. The full timer-driven vector sweep, not just entry to test 3,
is covered before test 4 starts.

The old mapping made unused controller units 2/3 change READY when normal
software wrote CONTR=13/1B. uPD765 polling correctly raised attention IRQs
for these **artificial input transitions**. Those IRQs caused both the static
diagnostic failure and BCOS's nested interrupt. Keeping four actual drives
ready masked the bug; changing the timer latch also masked the first symptom
but introduced a later warning. Neither is the fix.

Manual audit: 3963590 R(2), p. 3-9 calls the diagnostic READY source `DIAG0`;
p. 3-5 names CONTR bit 4 `DIAGN`; p. 4-6 distinguishes normal FDU G10=0111
from diagnostic-test G10=1101. The earlier note equating bit 4 with an
unconditional four-unit READY override was not established by these pages.
The exact diagnostic-test gate wiring remains unimplemented; do not claim
that all board jumper modes are now verified. The retained change applies to
the normal FDU configuration tested here, and does not suppress genuine drive
READY transitions or FDC interrupt callbacks.

BCOS with the corrected **two-drive** configuration:
`runs-archive/bcos-trace.ymwpJM/`. At 03:058c, rr6 remains 8300:5000. At 03:0b64,
r1=7 (not zero), so initialization subtracts four correctly and completes
instead of overrunning memory. At 74 seconds PC is in the 02:09xx scheduler.
This resolves the traced register corruption, but does not establish arrival
at the configurator's interactive screen.

Gardini regression: `runs-archive/gardini-regression.EpXrHx/20260909-065633-gardini/`
exited normally after 95 emulated seconds with only the boot disk loaded. The
reconstructed display reaches the KUSA02.1 utility menu (COPY-DISK, FORMAT-DISK,
LOAD, MODIFY, etc.). This used the corrected build, fresh NVRAM, disposable media,
and the background/headless launch configuration; no GUI display was needed.

Use `scripts/test-m40-fdu.sh`; default duration is 230 seconds. Optional
arguments: timed key string, emulated seconds, and loaded-disk count (1/2/4).
Input is frame-scheduled and traces are native; no Lua memory taps or wait
coroutines. All media are disposable copies. Runs with speed test 6 produce
large native diagnostic-port polling logs.

## 2026-09-09 provisional experiment: captured timer cause (reverted)

Temporarily tested one functional change in `go280.cpp`: on interrupt enable, promote
`m_timer_latched` rather than only `m_timer_interrupt`. FDC promotion still
uses the live FDC source. This is a diagnostic-supported partial correction,
not proof of the complete hardware latch topology.

The masked timer pulse falls at runtime `21:9304`; enabling CONTR=13 at
`21:A2B2` must not lose its captured cause. In the corrected run it produces
vector 30 immediately, with timer cause=1, timer pin=0 and FDC cause=0.
The later EO1NT/readback check returns F7=00 instead of the previous 02.

Same frame-scheduled input harness, unchanged disk copies and slot parameters:

- Original live-timer behavior: `runs-archive/fdu-validation.enoxAq/20260909-063235-fdu/`
  stops at test 3 with FDC INTERRUPT NETWORK FAULT.
- Captured timer behavior: `runs-archive/fdu-validation.PZ8Ulj/20260909-063128-fdu/`
  advances through interrupt test 3 and DMA test 4, then compatibility and
  speed tests. It prints `interrupt not disabled!!!!` around the test-4/5
  transition and eventually stops at test 7, FDC CHARACTER EXCHANGE ERROR.
  Do not call this an all-pass diagnostic run.
- BCOS: `runs-archive/bcos-trace.UpiUQI/` still returns to `03:058c` with
  rr6=FA00:0000. This change does not fix the BCOS boot.

The old SIGSEGV is not a valid hardware-test result: the macOS crash report
`m40-2026-09-08-234218.ips` identifies `lua_gettop` inside a memory-tap callback.
A no-tap coroutine run also crashed during task resumption. The FDU wrapper
now uses `scripts/lua/mame_m40_timed_keys.lua`: frame-scheduled input, no emu.wait and
no Lua memory taps. Native FDU/VRAM logging remains enabled. Its generic
summary parser's zero IRQ counts / missing monitor detection do not parse
this native trace format; use native `FDU VIACK` records and reconstructed
screen text. Default duration is now 180 emulated seconds to limit trace size;
260 seconds exercised the later tests above.

## Low-level communication routines in 6030T6

### Controller init / type / reset

Image `0x79324..0x7939e` is a controller initialization path:

```asm
79324  push r3
79326  calr 0x93a0
79330  ldb rh2,rl2
79332  ldb rl2,#0xef ; outb @r2,rl3
79336  ldb rl2,#0x9f ; outb 0x3e,0x98
79340  ldb rl2,#0x99 ; outb 0x10,0x27
7934a  ldb rl2,#0x50 ; outb 0x20
79350  ldb rl2,#0xff ; outb 0x20
79358  call/check controller type via 0x93be
79362  compare type/result with 0x01e0 and 0x00e0
7938c  call 0x956c
79392  call 0x9532; if OK call 0x9748
```

This writes the interrupt/vector/timer/DMA setup ports, probes controller type,
then does an FDC reset/check sequence.

Image `0x793be..0x793d0` reads controller type/status:

```asm
ldb     rh2,rl2
ldb     rl2,#0xff
inb     rl7,@r2
ldb     rl2,#0xed
inb     rh7,@r2
andb    rh7,#0x01
ld      @rr4,r7
clr     r7
```

This combines the `0xff` ID/status byte with bit 0 from diagnostic port `0xed`
and stores the resulting word in the caller's result buffer.

Image `0x79532..0x79562` resets the FDC through the board control register:

```asm
clear CONTR bit 1 at 0xe7
short delay
set CONTR bit 1 at 0xe7
wait
read uPD765 MSR at 0x1d
return OK only if MSR == 0x80
```

### uPD765 command and status protocol

Image `0x7968a..0x796a8` is the main-status poll:

```asm
r7 = 5
timeout = 0x30
loop:
  inb rl0,@(slot:0x1d)
  if bit 7 set: r7 = 0; return
  decrement timeout
return r7
```

The code treats uPD765 MSR bit 7 (`RQM`) as the ready condition.

Image `0x79564..0x79688` is the FDC command-send loop. Important behavior:

- Selects a diagnostic/test byte pattern (`0xaa` or `0x55`) based on `r8`.
- Polls `0x1d` before each transfer.
- Treats MSR bit 4 as an error/busy condition.
- Requires MSR bit 7 set and bit 6 clear before writing a command/data byte.
- Writes command bytes to `0x1f`.
- Sources up to 9 command bytes from registers in this order:
  `rh0`, `rl0`, `rh1`, `rl1`, `rh3`, `rl3`, `rh4`, `rl4`, `rh5`.
- Sets/clears bit 2 in `CONTR` (`0xe7`) around the transfer.

Image `0x794c2..0x79508` reads FDC result/status. It polls RQM, reads `0x1f`,
then decodes status bits into words in the caller result buffer.

### DMA setup

Image `0x79402..0x79430` configures board control and DMA mode:

```asm
rl0 = saved_control & 0xaf
outb rl0 -> 0xe7
outb 0x46 -> 0x56
outb 0x41 -> 0x56
read 0xe7, set bit 4, write back
outb 0x09 -> 0x5e
save control state
```

Image `0x79432..0x7946c` programs DMA address/count registers:

```asm
outb -> 0x58              ; clear byte pointer / reset flip-flop
outb 0x0f -> 0x5e         ; mask/setup
outb 0xff,0xff -> 0x48
out count-1 low/high -> 0x4a
shift long address right one bit
out high address latch -> 0xf6
out address low/high -> 0x44
out adjusted count low/high -> 0x46
```

This is the clearest evidence that DMA buffer addresses are handled as word-ish
bus addresses: the long address is shifted right by one before being split across
the high-address latch and DMA address registers.

Images `0x7946e..0x79492` and `0x79494..0x794c0` are DMA end/control variants.
They update `CONTR`, write DMA mode values (`0x4a` etc.), and use `0x5e` for DMA
mask/control.

Image `0x793d2..0x79400` reads DMA status/registers:

```asm
outb -> 0x58
read 0x44 twice, combine/shift, store result
read 0x4a twice, combine/increment, store result
read 0x50 and test bit 2
```

### Live `4305T6` DMA-test result

The loaded `4305T6` test-4 routines identify two pieces of GO280 glue that a
plain AM9517 model does not provide:

- `mfior_exhwtest` masks channel 1, sets `CONTR.SCRVO`, reads port `0xe7`, and
  expects AM9517 status `0x20`.  The ignored read is the documented `VERFN`
  preset strobe; in write direction it raises the channel-1 request.
- `mfior_dmadynamic` uses AM9517 software requests on channels 1 and 2 to test
  terminal-count, address and count progression.  These requests exercise the
  controller registers, but do not represent an FDC-requested data cycle and
  therefore must not read the FDC or modify system memory.  Only a channel-2
  DACK caused by an asserted FDC DRQ opens the GO280 data-transfer gates;
  channel 1 is address-only.

With these rules modeled, `4305T6` test 4 completes both dynamic DMA paths,
prints its completion line and advances to test 5.  The earlier implementation
failed the `0x20` request-status check; simply asserting DRQ1 continuously then
allowed channel-2 software requests to overwrite live diagnostic RAM when the
high-address sweep reached it.

### Interrupt and timer paths

Image `0x7aa78..0x7aaa2` decodes interrupt status:

```asm
outb -> 0xff
inb rl0,@(slot:0xf7)
bit 0 -> error/result 0x2f
bit 1 -> error/result 0x30
bit 2 -> error/result 0x31
bit 3 -> error/result 0x32
```

Image `0x7aaa4..0x7aab8` enables interrupt/control bits:

```asm
rl0 = saved_control | 0x11
outb rl0 -> 0xe7
save control
```

Image `0x7ac1c..0x7ac30` disables/clears those bits:

```asm
rl0 = saved_control & 0xee
outb rl0 -> 0xe7
save control
```

Image `0x7ac32..0x7ac7c` is an interrupt test:

```asm
program timer group:
  0x9f = 0x3e
  0x99 = 0x1027
call controller/vector setup at 0x9322
delay
read 0xf7
if bit 0 is not set: return 0x21
restore timer/vector state
```

Image `0x7ac7e..0x7ac96` reads timer interrupt state:

```asm
outb 0x70 -> 0x9f
inb rh0,@(slot:0xf7)
if bit 0 set: return 0x1b
else return 0
```

### Diagnostic port and speed sampling

Image `0x79aee..0x79b20` reads interrupt/timer state:

```asm
inb 0xf7
if bit 0 set: r7 = 0x0d
program 0x9f with 0x70 then 0x80
read 0x9d
program 0x9f with 0x90
store timer value/result
```

Image `0x7aaba..0x7ac1a` is the most useful diagnostic-port/speed routine:

- Uses timer ports `0x9f`, `0x9d`, `0x99`, and `0x9b`.
- Polls diagnostic port `0xed` bit 2.
- Reads two bytes from `0x9b`.
- Returns `0x33` on timeout.
- Restores timer state at the end with `0x99 = 0x1027`.

This likely underlies the "speed measurement" and/or diagnostic-port tests.

### Live `4305T6` media-test result

The surviving diagnostic IMD is not itself a complete scratch disk: its last
track is cylinder 44, head 0.  Test 7 consequently failed at cylinder 45 with
uPD765 status `ST0=41`, `ST1=05` until the image was extended for destructive
testing.  A disposable MFM256 image with 77 cylinders, 2 heads and 26 sectors of
256 bytes per track allows the suite to exercise its intended geometry.

Four populated connectors are required because test 5 explicitly selects
uPD765 unit 1.  With the extended image mounted in all four drives:

- tests 1–5 pass, and compatibility reports `identified disk on unit 1 : MFM256`;
- test 6 passes with 166.65–166.67 ms samples (166.66 ms average, nominal
  166.67 ms, tolerance 1.5%);
- tests 7–10 pass (seek, format, read, and write/read sector);
- test 11 reports `MAIN MEMORY DATA COMPARE ERROR`;
- choosing `0  GO ON` proves tests 12 and 13 pass, and the suite ends with only
  the single test-11 error.

Test 6 polls port `0xed` bit 2, not bit 6.  The hardware manual calls bit 2
`DAW00`, the rotational data-window signal.  Driving it from the selected
floppy's index-derived rotational state produces stable 166.66 ms measurements.

Test 11 is narrowed to a buffer-lifetime/control-mark question rather than data
corruption in the deleted-data commands.  The command sequence is:

1. `C9` WRITE DELETED DATA writes 26 sectors (6656 bytes) from physical
   `0x071ff4`;
2. 26 single-sector `C6` READ DATA commands check the deleted sectors/control
   marks, each DMAing 256 bytes back to physical `0x071ff4`;
3. `CC` READ DELETED DATA reads the full track to physical `0x0739f8`;
4. the diagnostic compares 6656 bytes at logical `A200:0BF4` and
   `A200:25F8`, which the MMU translates to those two physical bases.

The full WRITE DELETED source stream and READ DELETED destination stream are
byte-identical (SHA-256
`7aaebd5993cf0e8cb1e1f1910760a1cc4a1b454ab959f2d1f3b86b233439407b`).
At compare time, however, the first source sector has been replaced by the last
single-sector READ DATA result.  The first mismatch is therefore source word
`001A` versus destination word `0001` at physical `0x071ff8`/`0x0739fc` (the
sector-number field).  Whether real GO280 glue suppresses/redirects those DMA
writes, or this diagnostic expects another controller nuance, is still open;
changing the uPD765 semantics without hardware evidence would be premature.

## CONTR bit evidence

`re/hardware/go280/FDU_governo_3963590.md` gives the schematic/manual names for `CONTR`
(`0xe7`):

```text
bit 0  EN100  1 = enable interrupt requests
bit 1  RESFD  0 = reset FDC, active low
bit 2  SCANO  scan signal, unused on GO229/240/280
bit 3  MOTO1  enable MFDU motor #1
bit 4  DIAGN  diagnostic signal toward drive logic
bit 5  ERRO1  error condition
bit 6  SCRVO  direction, 1 = write to disk, 0 = read
bit 7  MOTO2  enable MFDU motor #2
```

The diagnostic disassembly matches several of these names:

```text
bit 1  toggled low/high by FDC reset at image 0x79532..0x79562
bit 4  set during DMA/FDC setup and diagnostic paths
bit 6  cleared/set by DMA setup variants, matching read/write direction
bit 0  set/cleared with bit 4 by interrupt/diagnostic enable paths
```

The only suspicious use is bit 2: the command-send routine asserts it around
FDC command transfer, while the manual says SCANO is unused on GO280. That may
mean the routine is shared with older governo boards, or that SCANO still gates
an internal diagnostic/handshake path even when the external scan feature is not
used.

## Current protocol model

The CPU-to-governo communication path appears to be:

1. Caller passes controller slot/select in `rl2`.
2. Low-level routine moves that to `rh2`, then selects a board register in `rl2`.
3. Board control register `0xe7` gates reset, interrupt enable, and FDC/DMA
   transfer mode bits.
4. uPD765 command/status uses `0x1d` (MSR) and `0x1f` (data), with explicit RQM
   polling and direction checks.
5. DMA uses the `0x40..0x5e` register group plus high-address latch `0xf6`.
6. Interrupt state is observed through `0xf7`; `0xff` is used as an ID/strobe
   or interrupt acknowledge/setup port depending on routine.
7. Diagnostic and speed paths use `0xed` plus the timer group at `0x99..0x9f`.

## Next useful disassembly work

1. Map the `6030T6` menu dispatch table so test number 1 is tied to the exact
   wrapper sequence that calls `mfior_contrinit`, `mfior_contrtype`, and
   `mfior_fdcreset`.
2. Compare the same low-level ranges in `4301T4` and `4305T6`; shared routines
   should identify generic MFDU/FDU protocol while differences identify media or
   drive-specific behavior.
3. Follow callers of:
   - `0x9324` controller init
   - `0x93be` controller type read
   - `0x9532` FDC reset
   - `0x9564/0x956c/0x9572` FDC command-send variants
   - `0x9432` DMA setup
   - `0xaa78` interrupt status decode
   - `0xaaba` diagnostic speed/sample routine
4. Cross-check every hard-coded `CONTR` mask against the GO280 schematic names,
   especially the shared/unclear use of bit 2 (`SCANO`) in the command path.
