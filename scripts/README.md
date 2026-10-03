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
| `test-m40-os.sh <mode>` | Boots an operating system with the floppy IPL switch set (`m40-os-observe.lua`). Modes: `mdos`, `mdosutil`, `mdos20`, `mdos31`, `mdos32`, `ese`, `bcos33`, `bcos33-config`, `bcos50`, `mos` | `ese`, `mdos`: `READY`. `mos` boots the MOS starter with the formatted WREN2 from `re/checkpoints/mos-install/` and runs 230 s; the 219 s screenshot shows the starter's `ENTER DATE (MM/DD/YY)` prompt |
| `test-m40-hd.sh [bcos\|mos\|all]` | The published hard-disk systems from `mame_disks` on the hd65 ROM: BCOS II to `/SYS` (password, date, time) and MOS to the root menu (login, date, time, login again). The final screen is compared pixel by pixel with `expected/hd-bcos.png` and `expected/hd-mos.png`; `M40_UPDATE_EXPECTED=1` replaces the references after an intended change | `bcos: PASS`, `mos: PASS`; about 2 minutes |
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
- The hard-disk harnesses below use data that is still in the run archive
  (git-ignored, local only); see the next two sections.

## Hard-disk harness (`harness/`)

The scripts used for the GO363 work: BCOS II and OSLEM on the hard disk, the
MOS install, and the arbiter/DMA regression runs. Full reference in
`tools/L1_DISK_FORMATS.md` section 9.

| Script | Use |
|---|---|
| `launch.sh CHD [args]` | Headless MAME with GO363 in slot 5 (`OUT` run dir, `SCRIPT`, `ISL=floppy`, `DEBUG=1`, `ROMPATH`, `RUN_SECONDS`) |
| `launchb.sh` | The same with a selectable binary (`BIN`), for before/after runs |
| `run_keys.lua` | Key steps and periodic screenshots (`STEPS`, `SHOT_STEP`); used by nearly everything else |
| `run_savestate.lua` | Save a state at `SAVE_T` as `SAVE_NAME`, then run `INNER` |
| `state_run.sh`, `bcos_run.sh`, `cos_try.sh` | Resume BCOS II / OSLEM from saved states |
| `reg.sh OUTDIR BIN ROMPATH CHD` | Hard-disk boot regression run with a given binary |
| `diag.sh OUTDIR CODE [BIN]` | Load and run one DCOS diagnostic program from disk A (`DISK` selects another) |
| `build_*.py`, `alias_pound.py` | Image surgery with `tools/l1disk.py`: write data sets onto a CHD, add modules and directory entries |
| `run_*.lua` (others), `pcsample.lua` | Probes from the BCOS/OSLEM investigation: breakpoints, traces, segment dumps, PC histograms |

The patched-ROM runs use `~/Projects/mame_disks/m40/roms/m40-hd65`. Saved
states and disk images are in `re/checkpoints/bcos-hd/`; new runs go to `runs/`.
`build_k02743_fmd.py`, `build_allres_osg.py` and the `build_oslem7_*` scripts
also read a K02743 boot image from `/private/tmp/k02743-probe/`, which no
longer exists.

## MOS install (`mos-install/`)

| Script | Use |
|---|---|
| `step.sh NAME [FROM]` | One stage of the MOS install from the starter disk; saves a state and disk snapshot per stage (`STEPS`, `UNTIL`, `FLOP`) |
| `hdrun.sh NAME [FROM]` | Boot or resume the installed MOS disk on the patched ROM |
| `mksteps.py START 'cmd' …` | Turn typed commands into a `STEPS` string for `run_keys.lua` |

The stage states, disk snapshots, the starter and the formatted starting
disk are in `re/checkpoints/mos-install/`; each run works in `runs/` and adds
its state and snapshot to that store. The finished disk is `m40-mos-hd.chd` in `mame_disks`.
