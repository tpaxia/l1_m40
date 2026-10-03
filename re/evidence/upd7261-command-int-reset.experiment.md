# uPD7261 command-acceptance INT recomputation experiment

Date: 2026-09-26.

Status: **tested; does not fix ERMAP; external source restored**.

## Primary hardware evidence

The NEC *uPD7261A/B Hard-Disk Controllers* manual,
`reference/datasheets/NEC_uPD7261B_datasheet.pdf`, printed page 6-20 / PDF page 18,
defines the interrupt output as:

```text
INT = CEH + CEL + SRQ * !SRQM
```

The same page states that both command-end bits, CEH and CEL, are cleared by
a disk command. Therefore accepting a new disk command must recompute INT
after clearing CEH/CEL. If SRQ is not active (as in ERMAP's polling-disabled
SEEK), INT must become inactive until the new command terminates.

Printed page 6-21 / PDF page 19 independently describes soft-sector normal
stepping with polling disabled: SEEK terminates when the drive asserts SKC;
CEH is then set and IST is returned as the result byte. SRQ is not set in
this mode.

## Current emulator behavior

External source:

```text
/Users/paxia/Projects/mame_latest/mame/src/devices/machine/upd7261.cpp
```

In `upd7261_device::command_w`, disk-command acceptance currently executes:

```cpp
m_status &= ~(S_CEH | S_CEL | S_NCI);
m_status |= S_CB;
```

but does not call `set_int(...)`. `set_int` only calls the GO363 callback when
the level changes. Thus a previous command-end INT can remain high in the
emulator even though CEH/CEL were cleared by the new command.

## DCOS evidence and connection to ERMAP

Original DCOS image:

```text
reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD
```

Program: `007.HDC5X3`; executing ERMAP body mapping:

```text
file = 0x15300 + (linear - 0x30000)
```

The final failing path issues uPD7261 SEEK `0x68` at linear `0x215384`,
selects ERMAP states `0x0d`, `0x04`, and `0x05`, then waits at
`0x0312be`/`0x0312c6` for the callback to set `0x030166`.

Focused trace:

```text
runs-archive/ermap-breakpoints-20260925/option1-seek68-focused.trace
runs-archive/ermap-breakpoints-20260925/option1-seek68-focused.breakpoints.log
```

The only accepted interrupt dispatches DCOS source 5 to `0x2184e6`. Neither
source-2 producer (`0x217868` or `0x21808a`) executes, and DCOS never reaches
the controller status/result reads at `0x2153ae`/`0x2153b6` or ERMAP callback
`0x030efc`.

The GO363 model turns a uPD7261 INT transition into an HDC VI request. GO363
VI acknowledge clears the one-shot VI latch while preserving the controller
pending level. If the uPD7261 INT level is incorrectly retained across disk
command acceptance, later command termination has no low-to-high transition
with which to notify GO363.

## Proposed minimal correction

Immediately after clearing CEH/CEL for an accepted disk command, recompute
the output from the remaining unmasked source represented by the current
model:

```cpp
m_status &= ~(S_CEH | S_CEL | S_NCI);
set_int(m_status & S_SRQ);
m_status |= S_CB;
```

This does not invent SEEK timing or GO363 protocol. It implements the NEC
interrupt equation and the documented disk-command side effect. The current
model does not retain SRQM as a separate state; preserving an active SRQ in
this expression is more accurate than unconditionally dropping INT.

## Independent checks

1. ERMAP option 1 must receive a post-SEEK source-2 event, reach
   `0x2153ae`/`0x2153b6`, call `0x030efc`, write `0x030166`, and leave the
   wait loop.
2. ERMAP option 2's SEEK/Read Data/Read ID sequence must not regress.
3. Standard 24's completed image and HDC505 controller interrupt tests must
   continue to pass.
4. The experiment must run only on disposable CHD copies. HDC5F5 remains
   prohibited until ERMAP writes successfully.

## Result

The correction was applied to the existing external MAME worktree, M40
rebuilt successfully, and ERMAP option 1 replayed with the focused breakpoint
harness.

The result was byte-for-byte and event-for-event unchanged:

```text
trace-issue pc=215384 r1=0068 state=06 done=01 src=05
irq-entry  pc=217f5e src=05
dispatch   pc=217fee src=05 table=29c8 target=2184e6
```

Neither source-2 assignment executed. There was no read at `0x2153ae` or
`0x2153b6`, no callback at `0x030efc`, and no write at `0x030f22`.
The trace again counted 3,580,476 instructions in the ERMAP wait loop before
the source-5 IRQ. The disposable CHD remained byte-identical:

```text
19451e6ee6db17aa7941fcef9e4e32f326c811d08054738e8e8dca7301107a9d
```

Therefore stale CEH/CEL-derived INT across disk-command acceptance is not the
cause of this ERMAP timeout. The datasheet evidence still identifies a general
accuracy issue in the controller model, but retaining that unrelated fix is
outside this focused experiment. The added line was removed and M40 rebuilt
from the restored source.
