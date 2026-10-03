# MAME work

The emulator lives outside this repository, in the `m40_z8010_sup_test`
branch of [tpaxia/mame](https://github.com/tpaxia/mame/tree/m40_z8010_sup_test).
The implementation notes are in [`../../doc/MAME_DRIVER.md`](../../doc/MAME_DRIVER.md).

## Tools

| Note | Contents | Status |
|---|---|---|
| [MAME_diagnostic_trace_harness.md](MAME_diagnostic_trace_harness.md) | Running the DCOS diagnostic disks under MAME: operator input, I/O tracing, overlay dumps (`tools/m40_harness.py`) | Current |
| [MAME_diagnostic_disk_trace_plan.md](MAME_diagnostic_disk_trace_plan.md) | The plan that led to the harness: pinning down the DCOS disk format and the monitor's overlay model | Historical (carried out) |

## Branch history

The dated notes on the September branch work (UI toggle, rebase onto mamedev,
HD branch split, MMU cache-invalidation removal, regression run, GO363 port)
are summarised in [`doc/MAME_DRIVER.md`](../../doc/MAME_DRIVER.md) §10, with the
build command. The notes themselves are in git history.
