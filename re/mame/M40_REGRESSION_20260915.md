# M40 regression — 2026-09-15

Tested rebuilt `mame_latest/mame/m40` on `olivetti_m40` at `e05bfe582c7`,
with pending GO252 bit-4 removal, UC trace removal, and restored BIOS choices.
All tests below use the default BIOS (6.0), headless execution and separate
configuration/NVRAM. Disk tests use disposable copies. No guest RAM patches.

## Results

- Keyboard: **PASS, 210 cases**, including Alt layer, Shift/Control combinations
  and F12 UI profile. `runs-archive/host-keymap.FuU6OD/result.log`.
- RAM: **PASS**, default 512 KB plus all nine automatic sizes complete the
  resident ROM memory phase; eight explicit card startup mappings pass;
  explicit mixed 640 KB completes the memory phase; mixed automatic/explicit
  and misplaced-card configurations are rejected.
  Logs: `/var/folders/vn/z84k1rsd4c18hnk8by2tlx280000gn/T/m40-ram-test.SyL10h`.
- BCOS K02733: keypad date entry and `sys` plus Enter reach the generator's
  Continue/Exit screen. `runs-archive/kdc-bit4-config.rTQy1C/159-screen.png`.
- Generated BCOS LOAD: eject at second 90, insert RUN at 92, main Enter at 95;
  reaches the password prompt. `runs-archive/bcos-generated-boot.3QZ3zl/159.png`.

The two BCOS endpoints match the previously observed successful stages by
visual inspection; PNG file hashes differ, so no byte-identical claim is made.
No post-login BASIC program or complete disk-generation cycle was tested.

All completed regression processes exited successfully. Initial sandbox runs
failed before emulation because SDL could not initialize macOS display services;
tests were rerun with permission outside the sandbox, still with video disabled.
An initial configurator invocation used literal backslash-n instead of Enter;
that harness invocation was corrected and the run above completed successfully.

An additional older-BIOS startup sweep was started, then cancelled at the user's
request. It is not part of the acceptance results and no further older-BIOS
testing is planned. No MAME source changes were made by these tests.

## BASIC follow-up

The older `HpSmLA/swap.sta` did not restore on this build: the first snapshot
showed ROM startup instead of `/SYS`. That attempt is not a BASIC result.

Used the fresh `bcos-generated-boot.3QZ3zl/swap.sta` password-prompt state
from the current regression instead. Verified restoration, then supplied the
user's password (not recorded here), keypad date 860909 and keypad Enter.
Ordinary Ctrl+F8 enabled TEST, followed by `basic` and keypad Enter.

- Login reached `/SYS`.
- TEST lit the firmware-controlled L2 indicator.
- BASIC launched and displayed `EDIT`.
- Tried `10 PRINT 123`, `20 END`, and `RUN`, each with keypad Enter. The first
  line produced `EDIT-ERR.206`; subsequent input did not advance past it.
  This reproduces the previously recorded program-entry limitation, not a
  newly established regression. Successful BASIC program execution remains
  unverified.

Evidence: `runs-archive/basic-regression-20260915/700.png` (`/SYS`) and `2100.png`
(`EDIT`, first line, error 206, L2 on). `1100.png` captures the intervening
BASIC startup screen before EDIT appears. The test script and process log
are alongside the screenshots; neither contains the password or I/O tracing.
Runtime files and copied media: `/private/tmp/m40-basic-regression.p2hsvZ`.
The bounded headless process exited successfully. No guest memory patches
or native MAME changes were used. Updated the older replay shell harness
from `-ramsize 2048K` to `-ram 2m` for the current MAME interface.
