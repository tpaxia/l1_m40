# MAME work

The emulator lives outside this repository, in the `m40_z8010_sup_test`
branch of [tpaxia/mame](https://github.com/tpaxia/mame/tree/m40_z8010_sup_test).
The implementation notes are in [`../../doc/MAME_DRIVER.md`](../../doc/MAME_DRIVER.md).

## Tools

| Note | Contents | Status |
|---|---|---|
| [MAME_diagnostic_trace_harness.md](MAME_diagnostic_trace_harness.md) | Running the DCOS diagnostic disks under MAME: operator input, I/O tracing, overlay dumps (`tools/m40_harness.py`) | Current; the screen and FDU trace options no longer work |
| [MAME_diagnostic_disk_trace_plan.md](MAME_diagnostic_disk_trace_plan.md) | The plan that led to the harness: pinning down the DCOS disk format and the monitor's overlay model | Historical (carried out) |

## Branch history (14–20 September 2026)

Dated records of reorganising the MAME branch. They explain commits in the
branch history; none describes current behaviour that is not also in
`doc/MAME_DRIVER.md`.

| Note | Event |
|---|---|
| [M40_UI_RESERVATION.md](M40_UI_RESERVATION.md) | 14 Sep: Scroll Lock left to Windows; explicit UI toggle (later replaced by F12) |
| [MAME_REBASE_20260915.md](MAME_REBASE_20260915.md) | 15 Sep: the branch rebased onto mamedev master |
| [MAME_HD_BRANCH_SPLIT.md](MAME_HD_BRANCH_SPLIT.md) | 15 Sep: GO363 split into its own branch |
| [M40_MMU_CACHE_INVALIDATION_20260915.md](M40_MMU_CACHE_INVALIDATION_20260915.md) | 15 Sep: unneeded MMU cache invalidations removed |
| [M40_REGRESSION_20260915.md](M40_REGRESSION_20260915.md) | 15 Sep: regression run after those changes |
| [M40_GO363_PORT_20260920.md](M40_GO363_PORT_20260920.md) | 20 Sep: GO363 ported onto the current branch |
