# Reproducible unattended K02733 BCOS boot on macOS

## 2026-09-10: command execution verified

See [re/os/bcos/BCOS_BOOT.md](BCOS_BOOT.md) for the current sequence. After the date,
SYS already accepts commands. Run `2xKETx` submits SYS and keypad Enter without
Ctrl+J and launches the Operating System Generator menu. Ctrl+J followed by SYS
instead produced ERR.153 JSYS (`8GLYpT`). Historical Ctrl+J experiments below
must not be used as instructions for this working prompt.

## 2026-09-09: keyboard initialization and interactive input

The GO252 receive-interrupt status must report RDRF and IRQ (status 83 with
TX-ready), not bit 2 for every byte. The latter makes IKYB restart; omitting IRQ
then makes runtime 1KYB confuse received data with completion events. The native
correction is in `go252.cpp`; no ROM/disk patches or forced commands are needed.

Bounded background verification, using disposable disk copies and a test date:

```sh
BCOS_KEYPAD=1 BCOS_BOOT_SECONDS=160 \
BCOS_BOOT_SCRIPT=scripts/lua/mame_bcos_state.lua BCOS_KBD_TRACE=1 \
BCOS_TYPE=$'860909\n' scripts/boot-m40-bcos.sh
```

The observer captures the date prompt at 90 seconds; at 100 seconds it types
860909 and ENTER using the numeric keypad. This disk's KITA layout does not
map the emulated top-row legends as expected, and alpha RETURN is not the keypad
terminator. Do not use Ctrl+J to bypass the date prompt. Screens and read-only
keyboard logs go to the printed run directory; MAME exits at 160 seconds.
Native-only run `runs-archive/bcos-boot.rcwPJZ/` ([screen](../../evidence/screenshots/bcos-boot.rcwPJZ.png)) reaches the date prompt, accepts the
keypad date and reaches SYS, still visible at 159 seconds. No status overrides
remain in the script, and no Ctrl+J is used in this verification. Full configurator
operations beyond this prompt are not yet validated.

## Current launcher after the 2026-09-09 cleanup

Run `scripts/boot-m40-bcos.sh`. It copies both images into a unique run directory,
uses fresh NVRAM, sets `SDL_MAC_BACKGROUND_APP=1`, selects the null video/audio
outputs, captures the screen/CPU state at 74 seconds, and exits at 76 seconds.
It does not inject keys or enable native tracing. The old
`scripts/trace-bcos-boot.sh` has been replaced, and all driver-side
`M40_CPU_TRACE*`, `M40_CPU_DUMP*`, `M40_VRAM_TRACE`, and `M40_FDU_TRACE` hooks
have been removed. Commands and native trace examples below are historical;
use the current launcher for disposable media and bounded execution.

## Historical investigation procedure

This is the verified unattended launch procedure for investigating the boot of
`K02733_BCOS_II_3.3_CONFIGURATOR` on the current M40 MAME build. Reaching the
interactive configurator is not yet verified. It captures the
emulated GO252 screen to a PNG and does not create an emulated display window.

On macOS, `-video none` alone is **not headless**: this SDL3 build still selects
the Cocoa video driver, initializes the physical monitor/window subsystem, and
may foreground an application named MAME. Set `SDL_MAC_BACKGROUND_APP=1` before
launching MAME so SDL does not force it to the foreground. The process still uses
the Cocoa backend internally, so "background/unattended" is more accurate than
"headless" for this build.

Do not use `-videodriver dummy` or `-videodriver offscreen`. Both are present in
SDL3 but fail here with `The video driver did not add any displays`; MAME requires
SDL to expose a display even when `-video none` selects the null renderer.

## Required drive order

- `-flop2`: `K02733_BCOS_II_3.3_CONFIGURATOR.imd` (GO280 unit 1, the boot unit)
- `-flop1`: `reference/Disk Images/K02737_BCOS_II_3.3.imd` (GO280 unit 0)

Swapping these arguments does not boot K02733.  The traced boot commands select
uPD765 unit 1.  No unit-0 read has yet been observed during the verified boot, so
K02737 must not be described as a proven run-time companion.

## Exact no-key baseline command

Run from `/Users/paxia/Projects/L1_M30_M40`:

`re/os/bcos/leftovers/mame_m40_snapshot.lua` has been removed; recover it with
`git show re-leftovers-archive:re/os/bcos/leftovers/mame_m40_snapshot.lua`.

```sh
mkdir -p runs-archive/k02733-baseline/nvram

SDL_MAC_BACKGROUND_APP=1 \
M40_SNAPSHOT_DELAY=60 \
M40_SNAPSHOT_SETTLE=30 \
M40_SNAPSHOT=/Users/paxia/Projects/L1_M30_M40/runs-archive/k02733-baseline/screen.png \
M40_SNAPSHOT_STATE=/Users/paxia/Projects/L1_M30_M40/runs-archive/k02733-baseline/state.txt \
M40_FDU_TRACE=/Users/paxia/Projects/L1_M30_M40/runs-archive/k02733-baseline/fdu.log \
/Users/paxia/Projects/mame_latest/mame/m40 m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  -flop1 'reference/Disk Images/K02737_BCOS_II_3.3.imd' \
  -flop2 'reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' \
  -autoboot_script re/os/bcos/leftovers/mame_m40_snapshot.lua \
  -nvram_directory runs-archive/k02733-baseline/nvram \
  -nomouse -video none -sound none -nothrottle -seconds_to_run 95
```

The current build still initializes macOS/SDL with `-video none`. The
`SDL_MAC_BACKGROUND_APP=1` environment hint must be present before SDL starts;
adding it after launch is ineffective.

Expected stable CPU state is the scheduler loop around `02:0912..091e`, with
`FCW=D860` and no pending CPU interrupt.  The screen includes `PUS=DISK OK`,
`LDK=E100`, `TIMEOK==KEYB`.

The September 9 READY-wiring correction also gets the 2048 KB configuration
past the former `03:05c6` error path and through configuration initialization.
Run `runs-archive/bcos-trace.ymwpJM/` ([screen](../../evidence/screenshots/bcos-trace.ymwpJM.png)) preserves rr6=8300:5000 at 03:058c and
reads the valid count 7 at 03:0b64; its 74-second snapshot is in the scheduler.
Neither scheduler observation proves arrival at the configurator UI.

The old companion path `/tmp/K02737.imd` was lost between sessions. Its persistent
replacement was regenerated from the archived SCP with:

```sh
disk-analyse 'reference/Disk Images/K02737_BCOS_II_3.3_BCS433-BCS533-BCS633-BCS833-UTS233.scp' \
  'reference/Disk Images/K02737_BCOS_II_3.3.imd'
```

For isolated 2 MB trace runs, `scripts/trace-bcos-boot.sh 0003075E 70` (since removed) copied both
images into a fresh run directory and creates new NVRAM. On this macOS host,
SDL initialization requires running outside the filesystem sandbox even with
video disabled; otherwise it reports that the video driver added no displays.

## Key experiments

Add exactly one of these environment variables to the command:

```sh
M40_SNAPSHOT_KEYPAD_ENTER=1
M40_SNAPSHOT_CTRL_J=1
M40_SNAPSHOT_ALPHA_RETURN=1
```

For an OSLEM experiment, `M40_SNAPSHOT_COMMAND=SYS` waits one emulated second
after the selected key action and physically presses S, Y, S, and alpha RETURN.
Combine it with `M40_SNAPSHOT_CTRL_J=1`; the BCOS manual says Ctrl+J enables
Ready and a utility is then launched by typing its library name. MAME's natural
keyboard is unsuitable here: it cannot synthesize the upper-case letters for
this matrix and maps newline to keypad ENTER (`61`) rather than alpha RETURN
(`35`).

`M40_SNAPSHOT_DELAY=45` injects the key after the stable screen is reached;
`M40_SNAPSHOT_SETTLE=15` is enough for a first comparison.  The Lua harness holds
each input state across two input-update intervals.  For keypad verification also
set an absolute debug path:

```sh
M40_SNAPSHOT_INPUT_DEBUG=/Users/paxia/Projects/L1_M30_M40/runs-archive/k02733-key/input.txt
```

`M40_SNAPSHOT_FORCE_KBD_START=1` is a deliberately intrusive experiment: just
before the key it writes MCU command `00` to GO252 data register `02`, then restores
KDC control `16`.  Never describe a run using it as an unmodified K02733 boot.

`M40_SNAPSHOT_EARLY_KBD_START=18.1` is a second deliberately intrusive timing
experiment. It sends the same command immediately after the observed BCOS read of
startup byte `FC`, before the later key injection. This distinguishes a missed
startup handshake from a key-delivery failure; it is not evidence that real
hardware automatically sends command `00`.

As of 2026-09-04, keypad Enter was physically asserted and released in the MAME
matrix, but caused no screen change.  A corrected Ctrl+J run also caused no change.
These are not yet valid tests of BCOS command handling: BCOS reads the startup `FC`
and disables KDC control without sending MCU command `00`, so the recovered keyboard
firmware remains in its announcement loop rather than scanning keys.

## Important pitfalls

- Do not use `-window` for unattended runs. MAME then displays its
  “machine not working; press a key” warning and pauses before the autoboot Lua
  script runs.
- `-skip_gameinfo` does not bypass that warning reliably.
- Use `SDL_MAC_BACKGROUND_APP=1` and
  `-video none -sound none -nothrottle -seconds_to_run ...` exactly as above.
- Use an absolute `M40_SNAPSHOT` path.  A relative path is placed beneath MAME's
  configured `snap/` directory.
- `M40_FDU_TRACE` is the trace filename itself.  There is no separate
  `M40_FDU_TRACE_PATH` variable.
- Do not run two tests concurrently against the same writable IMD files.
