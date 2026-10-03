# scripts/

Launchers and regression tests for the Olivetti M40 in MAME. Every script
works on disposable copies of the disk images and gives each run its own
folder under `runs/` (created if missing; git ignores it) with private NVRAM
and settings; the original media are never written. Run them from anywhere,
e.g. `sh scripts/test-m40-fdu.sh`. Each prints its run folder first.

The scripts find the project folder from their own location. Paths outside
the project are fixed to this machine: the MAME binary is
`/Users/paxia/Projects/mame_latest/mame/m40` and the ROMs come from
`/Users/paxia/Projects/mame_latest/mame/roms` (which must hold
`m40/m40rom-6.0.bin` and the character generator `m40/9428ds-2067.bin`).

All scripts were last run against the current build on 2 October 2026.

## Interactive sessions

| Script | What it starts |
|---|---|
| `run-m40-ese-interactive.sh` | ESE 3.1 from floppy in a visible window. Boots unthrottled, then switches to real time at `READY`. |
| `run-m40-bcos-interactive.sh [--keyboard-disk]` | The BCOS II 3.3 configurator disk (K02733) in a visible window. `--keyboard-disk` also mounts the keyboard disk (K02741) in drive 2. |

Both use `-uimodekey F12 -ctrlr m40-ui`: **F12** turns the MAME UI controls
on and off, so all other keys reach the M40. `m40-ui.cfg` is that control
profile (the same file is published in `mame_disks`).

## Regression tests

| Script | What it checks | Expected result |
|---|---|---|
| `test-m40-host-keymap.sh` | Host keyboard to M40 ANK key mapping, including Shift, Control and the host Alt layer (`scripts/lua/mame_m40_host_keymap_test.lua`) | `RESULT PASS 218 cases` in the run folder's `result.log` |
| `test-m40-ram-config.sh` | Automatic RAM sizing (all nine sizes), every explicit RAM board, a 640 KB mix, and rejection of invalid combinations, using the ROM's own memory test (`m40-rom-test.lua`) | `All M40 RAM configuration tests passed.` Logs go to a temporary folder named in the output. `M40_MAME_BIN` and `M40_ROMPATH` override the binary and ROM path |
| `test-m40-fdu.sh [keys] [seconds] [drives]` | DCOS floppy diagnostic XU6030 (disk D, code 007), through the harness `tools/m40_harness.py` | The final `screen.png` shows the tests running with no error. `drives` = 1, 2 (default) or 4 inserted images |
| `test-m40-uc.sh [keys] [snapshot-time] [seconds]` | DCOS UC3003 central-unit diagnostic (disk A, code 008) | The default keys stop at UC3003's first parameter prompt; pass keys to run the tests. `test-m40-uc.sh aliases` instead runs `m40-uc-alias-test.lua`, which exercises the UC VIENO register aliases |
| `test-m40-keyte1-leds.sh [keys] [seconds]` | DCOS keyboard diagnostic KEYTE1 (disk B, code 013) and the keyboard LEDs (`scripts/lua/mame_keyte1_leds.lua`) | Screenshots end at KEYTE1's `KEYBOARD LAYOUT SELECT` menu |
| `test-m40-os.sh <mode>` | Boots an operating system with the floppy IPL switch set (`m40-os-observe.lua`). Modes: `mdos`, `mdosutil`, `mdos20`, `mdos31`, `mdos32`, `ese`, `bcos33`, `bcos33-config`, `bcos50`, `mos`, `mos-nohd`, `mos-nomedia` | `ese`, `mdos`: `READY`. The `mos` modes predate the hard-disk work: they attach a blank disk with the wrong geometry. Use the hard-disk image from `mame_disks` instead |
| `test-m40-bcos-single.sh fd1` | BCOS II 3.3 configurator alone in drive 1 (`scripts/lua/mame_bcos_state.lua`) | `DATE YYMMDD` |
| `boot-m40-bcos.sh` | BCOS II 3.3 configurator with the companion disk, 76 s, timed screenshots (`scripts/lua/mame_m40_snapshot_series.lua`) | Exits normally; screenshots in the run folder |
| `test-m40-generated-boot.sh` | The generated BCOS LOAD/RUN pair, including the disk swap (`scripts/lua/mame_bcos_generated_boot.lua`) | Exits normally; screenshots in the run folder |
| `test-m40-kdc-bit4.sh <config\|resident\|gardini>` | Boots BCOS (configurator or all-resident) or the Gardini utility disk while recording the keyboard-port control writes (`scripts/lua/mame_kdc_bit4_probe.lua`). Kept as a keyboard-port regression (`re/evidence/go252-kdc-master-reset-evidence.md`) | `config`: `DATE YYMMDD` |

Typical before/after use for an emulator change: run the set with the old
binary and the new one, then compare the screenshots pixel by pixel (see
`DEBUGGING_STRATEGY.md`).

## Environment variables

The Lua observers read these; all are optional.

| Variable | Used by | Meaning |
|---|---|---|
| `BCOS_KEYPAD`, `BCOS_TYPE`, `BCOS_TYPE_AT`, `BCOS_COMMAND`, `BCOS_COMMAND_AT`, `BCOS_FOLLOWUP`, `BCOS_FOLLOWUP_AT`, `BCOS_CTRL_J_AT`, `BCOS_ERROR_KEY` | `scripts/lua/mame_bcos_state.lua` (also via `m40-os-observe.lua` and the bit-4 probe) | Text to type into BCOS and when (e.g. `BCOS_KEYPAD=1 BCOS_TYPE=$'860909\n' BCOS_COMMAND=$'sys\n'` enters a date and `sys`) |
| `BCOS_KBD_TRACE`, `BCOS_KBD_EVENTS`, `BCOS_ERROR_TRACE`, `BCOS_STATE_DIR` | `scripts/lua/mame_bcos_state.lua` | Optional traces and where to save states |
| `BCOS_BOOT_SCRIPT`, `BCOS_BOOT_SECONDS`, `BCOS_SERIES_TIMES` | `boot-m40-bcos.sh`, `test-m40-bcos-single.sh` | Replace the observer script, the run length, the screenshot times |
| `BCOS_GENERATED_SECONDS`, `BCOS_GENERATED_SWAP`, `BCOS_GENERATED_DIRECT_SWAP`, `BCOS_GENERATED_ISL2` | `test-m40-generated-boot.sh` | Run length and how the LOAD/RUN swap is done |
| `M40_KEYS`, `M40_KEY_DELAY`, `M40_INTER_KEY_DELAY`, `M40_FINAL_SNAPSHOT`, `M40_FINAL_SNAPSHOT_TIME` | `scripts/lua/mame_m40_timed_keys.lua` (diagnostic tests) | Keys to type (`\n` = Enter, `{WAIT:n}` = pause n s) and a final screenshot |
| `M40_KDC_BINARY` | `test-m40-generated-boot.sh`, `test-m40-kdc-bit4.sh`, `test-m40-keyte1-leds.sh` | Alternative MAME binary (for before/after runs) |

## Lua helpers (`lua/`)

The MAME autoboot scripts the tests load:

| File | What it does | Used by |
|---|---|---|
| `mame_m40_timed_keys.lua` | Types keys on a schedule (`M40_KEYS`) and takes a final screenshot | `test-m40-fdu.sh`, `test-m40-uc.sh`, `mame_keyte1_leds.lua` |
| `mame_bcos_state.lua` | Observes BCOS: screenshots, optional key input, optional read-only I/O taps | `test-m40-bcos-single.sh`, `m40-os-observe.lua`, `mame_bcos_generated_boot.lua` |
| `mame_bcos_generated_boot.lua` | Boots the generated BCOS LOAD/RUN pair, including the disk swap | `test-m40-generated-boot.sh` |
| `mame_m40_snapshot_series.lua` | Screenshots and CPU state at set times | `boot-m40-bcos.sh` |
| `mame_m40_host_keymap_test.lua` | Feeds host key edges and reads what the keyboard interface receives | `test-m40-host-keymap.sh` |
| `mame_keyte1_leds.lua` | Drives KEYTE1 and records the keyboard LED outputs | `test-m40-keyte1-leds.sh` |
| `mame_kdc_bit4_probe.lua` | Records the keyboard-port control writes during a boot | `test-m40-kdc-bit4.sh` |
| `mame_m40_diag_trace.lua`, `mame_m40_dump_segments.lua` | Diagnostic-run trace and segment dump | `tools/m40_harness.py` (`run`, `dump`) |

Some still say "TEMP" in their first line from when they were written; they
are now regular test helpers.

## Dependencies outside this folder

- `tools/m40_harness.py` (used by the UC3003 and floppy tests).
- Disk images in `reference/Disk Images/` and `reference/Disk Images (Stefano Marinelli + others)/`
  (kept out of git: copy them in from the original archive),
  and the generated BCOS media and keyboard disk in
  `/Users/paxia/Projects/mame_latest/mame/flop/`.
- The hard-disk runs (BCOS II and MOS from the GO363) are not here; their
  harnesses are in the run archive, `runs-archive/restore-hd-20260928/` and
  `runs-archive/mos-install-20261002/` (git-ignored, local only).
