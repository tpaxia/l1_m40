# M40 rebase onto mamedev — 2026-09-15

Upstream: https://github.com/mamedev/mame, master at
`070569f87d147b5574e664006138089bdfd8701b`.

Backup: `backup/m40-before-mamedev-rebase-20260915`, at `f13ab5ed3a3`.
The isolated Z8010 descriptor-counter wrap was committed before rebasing.
All 51 commits replayed without conflicts, and git range-diff reported every
one patch-equivalent. Rebased Z8010 commit: `c59c9365213`.

Compilation exposed upstream change `2d0a09baefc`: ram_device is now a slot,
and emu_options no longer provides OPTION_RAMSIZE or ram_size(). The M40 bus
now checks whether the RAM slot option was explicitly specified. The rule
rejecting total-size selection combined with explicit RAM cards is retained.
This compatibility adaptation is a separate commit after the rebase.

## Build and launch changes

Regenerate/build on this Mac with:

```sh
make SUBTARGET=m40 SOURCES=src/mame/olivetti/m40.cpp OSD=sdl3 USE_LIBSDL=1 SDL_INSTALL_ROOT=/opt/homebrew REGENIE=1 -j6
```

The initial attempt used an obsolete USE_SDL option and could not locate
SDL3 via the default pkg-config path; the command above uses the existing
Homebrew installation. No SDL source workaround was introduced.

**Use `-ram 2m` instead of `-ramsize 2048K` with the rebased executable.**
Other normalized choices: 256k, 384k, 512k, 640k, 768k, 896k, 1m, 1536k.
The already published guides target the pre-rebase executable; they must be
updated alongside publication of the rebased branch. Older local scripts
using -ramsize also require updating before reuse.

## Verification

- Rebuilt successfully after the RAM API adaptation.
- `runs-archive/host-keymap.94m6jr`: all 210 logical-input cases passed, including
  Alt+H and the F12 controller profile/screenshot-conflict checks.
- `runs-archive/bcos-generated-boot.jSApre`: fresh BCOS LOAD boot, disposable
  media, confirmed floppy IPL, expected request to mount RUN at 119 seconds.
  This was a boot smoke test, not a full BASIC session or saved-state replay.
- RAM configuration suite updated to use the new normalized slot choices.
  All checks passed: default and nine automatic sizes ran the resident ROM
  memory test; eight explicit board types passed startup/mapping checks;
  explicit 640 KB passed the ROM test; mixed and misplaced selections were
  rejected. Logs: `/private/var/folders/vn/z84k1rsd4c18hnk8by2tlx280000gn/T/m40-ram-test.HOEX9a`.

No force-push has been performed. Older binary save states have not been
validated against the new upstream RAM device layout.
