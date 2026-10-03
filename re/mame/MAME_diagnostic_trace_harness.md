# MAME diagnostic trace harness

This note documents the current reusable infrastructure for running M30/M40
diagnostic disks under MAME, injecting operator input, tracing board I/O, dumping
loaded overlays, and using the video screen as a future synchronization point.

The working MAME tree is outside this repository:

```text
/Users/paxia/Projects/mame_latest/mame
```

The current driver source is:

```text
/Users/paxia/Projects/mame_latest/mame/src/mame/olivetti/m40.cpp
```

## Current driver shape

The driver remains a single machine driver rather than separate slot-card devices,
but it now models the full M1–M3 path: Z8001/Z8010 translation and suppression,
READY/NMI probing, UC timers/ACIA/arbiter, GO252 text video and complete ANK 1426
keyboard protocol, and GO280 µPD765 + AM9517 DMA + timer/VI. It boots the DCOS 8.4
monitor and runs KEYTE1, CRTAN5, UC3003, UCV305, MEM813, RAMVID and the applicable
6030T6 subset. The exact implemented behavior and known approximations are collected
in [`doc/MAME_DRIVER.md`](../../doc/MAME_DRIVER.md).

The UC keyboard/ACIA byte ports occupy the high byte lane of even Z8001 I/O word
cycles. They are mapped as `0xff20..0xff21` and `0xff22..0xff23` with
`umask16(0xff00)`. Queued keyboard data overlays RDRF/byte-ready on the real 6850
status and takes priority on data reads; otherwise UC3003 sees the ACIA loopback.

## Trace script

The preferred outer driver is now:

```text
tools/m40_harness.py
```

It launches MAME with the Lua probe, creates a deterministic run directory, keeps
the MAME stdout and command line, parses the trace, and writes a `summary.json`.
The Lua script remains the in-emulator probe because it can install I/O taps and
post natural keyboard input at emulated time.

List known DCOS 8.4 diagnostic disks:

```sh
python3 tools/m40_harness.py disks
```

Boot disk B headlessly and summarize the trace:

```sh
python3 tools/m40_harness.py run --diag B --name kdc-boot --seconds 60
```

The harness defaults to `-flop2`. In the current M40 configuration GO280 has two
fitted drives, and the bootable L1 media use uPD765 unit 1. Overriding this with
`--flop-name=-flop1` selects the other physical drive and can produce the monitor's
`ERROR ON UNIT 4` rather than testing the requested diagnostic.

For Gardini/BCOS boot experiments, use `re/hardware/go252/leftovers/mame_m40_keyboard_probe.lua` (removed; in tag `re-leftovers-archive`) with the
native `M40_VRAM_TRACE` and `M40_FDU_TRACE` logs. The broad diagnostic script's
whole-slot Lua taps currently crash during the ROM's second GO252 alias pass on
these media, while both an uninstrumented run and the narrow `0x1000-0x1003`
keyboard probe boot normally. Screen reconstruction folds trace offsets to the
GO252's real 4 KiB aperture, so mirrored writes through `FF2xxx` are visible.

Boot disk B, press Enter at the diagnostic-monitor prompt, and parse the KDC byte
path:

```sh
python3 tools/m40_harness.py run --diag B --name kdc-enter \
  --seconds 60 --keys '\n' --key-delay 28
```

Dump resident segments after the same key sequence:

```sh
python3 tools/m40_harness.py dump --diag B --name kdc-dump \
  --seconds 45 --keys '\n' --key-delay 28 --post-key-wait 2 \
  --segments 00,1d,1e
```

Summarize an existing trace:

```sh
python3 tools/m40_harness.py parse /path/to/trace.log
```

Current known timing caveat: bounded runs with `-seconds_to_run` are reliable,
while live unbounded runs have been observed to stall at console code `0x44`.
The Python harness defaults to bounded runs for that reason. For live work, use a
large bounded value rather than omitting `-seconds_to_run`.

Reusable script:

```text
scripts/lua/mame_m40_diag_trace.lua
```

It installs I/O taps for:

```text
GO252 slot window      0x1000..0x1fff
GO280 FDU slot window  0x2000..0x2fff
UC/KDC byte ports      0xff20..0xff23
console latch          0xffe0
```

Environment variables:

```text
M40_TRACE_LOG          output log, default /tmp/m40_diag_trace.log
M40_KEYS               natural-keyboard string to post, e.g. '\n' or '\n5\n0\n'
M40_KEY_DELAY          seconds before first key, default 8.0
M40_INTER_KEY_DELAY    seconds between posted keys, default 0.05
M40_SCREEN_INTERVAL    if >0, periodically log changed logical text snapshots
M40_SCREEN_SEG         logical segment for text decode, default 3d
M40_SCREEN_COLS        text columns, default 80
M40_SCREEN_ROWS        text rows, default 25
M40_VRAM_TRACE         driver-side framebuffer/CRTC trace, parsed by harness
M40_FDU_TRACE          driver-side GO280/FDC trace, parsed manually for now
```

Basic disk-B run:

```sh
cd /Users/paxia/Projects/mame_latest/mame
env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
  M40_TRACE_LOG=/tmp/m40_B_enter.log \
  M40_KEYS='\n' \
  M40_KEY_DELAY=28 \
  ./mame m40 \
  -flop '/Users/paxia/Projects/L1_M30_M40/reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD' \
  -autoboot_script /Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua \
  -seconds_to_run 60 -video none -sound none -nomouse -nothrottle
```

Add experimental logical text snapshots:

```sh
M40_SCREEN_INTERVAL=1.0
```

The harness once offered driver-side traces (`--vram-trace` to rebuild the
screen from GO252 framebuffer writes, `--fdu-trace` for a µPD765/DMA timeline,
and the `screen` and `fdu` subcommands to decode them). They depended on trace
hooks that were removed from the driver in September 2026, and the options were
removed from the harness in October; the runs that used them are in the run
archive. For screens, use the periodic snapshots above, or run with
`--trace-script scripts/lua/mame_m40_timed_keys.lua` and `M40_FINAL_SNAPSHOT`
for a real screenshot, as `scripts/test-m40-uc.sh` and `test-m40-fdu.sh` do.
For controller activity, use MAME debugger breakpoints or Lua I/O write taps
(`DEBUGGING_STRATEGY.md`).

The first diagnostic prompt wants Enter. Therefore scripted monitor/test runs
should start their `M40_KEYS` sequence with `\n` unless the target disk has been
shown to behave differently.

## Current monitor-input map

The monitor expects raw KDC key bytes, not ASCII digits. The current driver maps
natural keyboard input as follows:

```text
keypad Enter 0x61
SKIP         0x52
alpha Return 0x35 (typing key, not a monitor terminator)
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

This table is backed by the live segment-3 monitor table dump:

```text
raw:   67 68 65 5f 60 5d 57 58 55 4f 50 4d 59 62
ascii: 30 30 30 31 32 33 34 35 36 37 38 39 2d 2e
```

The monitor sequence for MAP is:

```sh
python3 tools/m40_harness.py run --diag B --name map-option2 \
  --keys '\n2\n' --key-delay 70 --inter-key-delay 8 \
  --seconds 430
```

The disk-resident library path is now operational. The historical `ac_mmulogfi: 02`
and `ERROR ON UNIT 1` traces remain useful as development evidence, but no longer
describe current driver status. The working latch/READY/DMA model is summarized in
`doc/MAME_DRIVER.md` §5 and verified by the diagnostic scorecard in `doc/DIAGNOSTICS.md`.

For the keyboard diagnostic specifically, disk B's DML catalog contains
`KEYTE183851212` at catalog row/index `13`, loc `0x2412`, length `25`; monitor code
`013` loads and runs KEYTE1.

## Segment dump script

Reusable script:

```text
scripts/lua/mame_m40_dump_segments.lua
```

Environment variables:

```text
M40_DUMP_DELAY         seconds before dumping if no keys are posted, default 12
M40_DUMP_DIR           output directory, default /tmp
M40_DUMP_SEGMENTS      comma-separated logical segments, default 01,1d,1e,21
M40_KEYS               optional natural-keyboard string to post before dumping
M40_KEY_DELAY          seconds before posting keys, default 0
M40_POST_KEY_WAIT      seconds after posted keys before dumping, default 2
```

Use it to capture resident code and loaded overlays after a deterministic key
sequence. For example, after booting disk B and pressing Enter:

```sh
cd /Users/paxia/Projects/mame_latest/mame
env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
  M40_KEYS='\n' \
  M40_KEY_DELAY=28 \
  M40_POST_KEY_WAIT=5 \
  M40_DUMP_DIR=/tmp \
  M40_DUMP_SEGMENTS=00,01,1d,1e,21,3d \
  ./mame m40 \
  -flop '/Users/paxia/Projects/L1_M30_M40/reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD' \
  -autoboot_script /Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_dump_segments.lua \
  -seconds_to_run 90 -video none -sound none -nomouse -nothrottle
```

## Video detection status

The MAME driver renders GO252 alphanumeric video from its private `m_vram`:

```text
Known:
  80x25 text mode comes from ROM CRTC table type 0.
  Framebuffer is segment 61 / physical 0xff0000.
  Cells are even-byte attribute, odd-byte character.
  Reverse, highlight, blink and four line attributes are rendered.
  LOW LINE follows MC6845 R9, so 17-line boxed cells close correctly.
  The current readable font is derived from the M20/L1 house font.

Unknown/incomplete:
  Exact low-four-bit line-attribute ordering.
  Exact character cell width/dot clock.
  CRTAN5 video-type/config register value.
  Glyph-exact GI 9428DS character ROM and graphics/special characters >0x7e.
```

For automation, screen-aware driving is not solved yet. The trace script has an
experimental logical-segment text logger, but the latest disk-B run showed that
reading logical segment `0x3d` after the monitor is loaded returns the driver's
segment-violation pattern (`0x8d07` words), not the live private `m_vram` backing
the CRTC. That means the current logger is useful only when the diagnostic has a
CPU segment mapped to the framebuffer in the way the script expects.

The desired screen-aware test driver is still:

```text
boot disk
wait until rendered video contains a known prompt/menu string
post the next key sequence
wait until the next prompt/string/test banner appears
dump memory and trace logs
```

This is preferable to fixed wall-clock delays. The current logger records changed
logical text snapshots but is not yet authoritative for the rendered screen. The
next useful upgrade is to expose the driver's `m_vram` to Lua/debugger access, or
add a driver-side debug text dump, then add a small wait-for-string mode, for
example:

```text
M40_WAIT_SCREEN='KEYBOARD TEST PROGRAM'
M40_WAIT_TIMEOUT=60
```

That would let per-test scripts synchronize on real monitor output instead of
guessing delays.

## Running tests on demand

The desired stable run model is one test per MAME process:

```text
1. Boot the selected diagnostic disk.
2. Wait for the first prompt or known menu screen.
3. Post Enter to enter the diagnostic monitor.
4. Wait for the menu/prompt that accepts a test number.
5. Post the component/test selection sequence.
6. Trace GO252/GO280/UC/KDC/FDU I/O and console latch events.
7. Dump resident and test segments at selected checkpoints.
8. Exit MAME and archive the log/dumps under a deterministic name.
```

This is reusable across disks because the disk image path and `M40_KEYS` are the
only run-specific inputs for the basic harness. Component-specific work then adds
focused taps or breakpoints:

```text
FDU/GO280:   FDC command/result, DMA address/count, FDU vector/interrupt ports.
GO252/KDC:   FE slot registers, UC 0xff20/0xff22, segment-61 screen snapshots.
GO363/HDC5:  HDC slot registers once the controller model exists.
UC/arbiter:  UC 0xff80..0xff8f plus NVI acknowledge path.
```

## Current limitations

The infrastructure is good enough to press Enter and collect repeatable traces.
It is not yet a complete diagnostic test runner:

```text
1. Menu selection still needs screen-synchronized driving instead of only delays.
2. The screen logger currently reads a logical segment, not the driver's private
   `m_vram`; latest disk-B testing shows this can read segment-violation filler.
3. Test entry/exit detection still needs per-test PC or screen anchors.
4. The re/ scripts are ignored by the repository's current .gitignore unless
   force-added.
5. The MAME driver changes live in the separate mame_latest checkout, not this
   repository.
```
