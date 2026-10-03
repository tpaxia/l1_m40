# GO363 post-read completion hypothesis (2026-09-26)

## Primary documentation and original programs

Olivetti, *L1 Functional Checks Manual, Concise Version*, January 1987,
sections 17.1.1–17.1.2 (printed pp. 17-1–17-3) says HDC5F5 reads Standard
24, then the manufacturer's ETF; an unreadable ETF must lead to the operator's
"format without ETF" choice, followed by formatting. Section 17.6.1
(printed p. 17-28) says HDC5X3 reads Standard 24 to locate and display or
write ERMAP. NEC, *uPD7261A/B Hard Disk Controller*, printed pp. 6-15 and
6-23–6-25, defines `0xb0` as a DMA Read Data operation ending in result
status; the observed seven result bytes `00 00 03 9c 00 01 00` are normal.

The original DCOS 8.4 Disk G image is
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`.
The extracted flat bytes are `/tmp/G.bin`. In HDC5F5's loaded shared runtime,
`0x21924a` sets up the DMA, `0x21926e` issues uPD7261 `0xb0`, and
`0x219272` writes GO363 command `0x1100`. Following the chip interrupt and
normal result, `0x219352`–`0x21936c` acknowledges the chip, writes board
data `0x000c`, `0x0018`, `0x0003`, and issues board command `0x2400`.
The exact `out @r2,r7` at `0x21936a` is byte-identical to flat Disk G offset
`0x4616a` (`3f27`); HDC5F5's source-2 handler is at loaded `0x21c00a`,
flat offset `0x48e0a`. Its `0x21c022` call parses the chip result, and
`0x21c0b2` returns with no pending higher-level notification. Trace:
`runs-archive/formatter-wren2-20260926/breakpoints.log` and `error.log`.
The diagnostic then waits on DCOS completion flag `0x030166` at
`0x0312be`/`0x0312c6` and reports ERR.0001 after the timeout.

Independent DCOS path: HDC5X3 option 2 in the same Disk G image issues
`0x90` READ ID commands, then board command `0x2401`, and later times out
waiting for a board completion. HDC5X3's shared command issue is loaded at
`0x215384`, flat offset `0x96f84`; its post-operation board-command writer
is loaded at `0x215482`, flat offset `0x97082`. Earlier HDC5X3 option-1
operations use the same common dispatcher and return to the application,
providing a comparison for the selector/callback flow.

## Inference and test boundary

The two programs use the `0x24xx` family after a completed chip read and
then depend on a GO363 completion indication. The current GO363 model records
`0x24xx` but gives it no side effect, so it cannot deliver such an indication.
The proposed experiment is a delayed, single board pending/VI completion for
`0x24xx`, with the command value captured when issued. The exact hardware
delay and whether the low byte changes the response are not documented; those
details remain provisional. A disposable HDC5F5 run must leave the ETF wait
and either offer the documented no-ETF prompt or enter formatting. HDC5X3
option 2 and the completed Standard 24/ERMAP option-1 paths must remain
usable. If these checks fail, revert the experimental emulator change.

No 0x26xx behavior is inferred here: only the ERMAP option-3 writer has been
observed using it, so that behavior stays in this project pending another
independent path.

## Experiment result: rejected

A one-millisecond deferred board pending/VI for `0x24xx` was built and tested
on `wren2-postread-experiment.chd`. HDC5F5 stopped earlier, just after the
Standard 24 phase, with `INTERRUPT NOT DISABLED!!!` and `HARDWARE FAILURE`.
This additional interrupt is not the missing completion; the experimental
change was removed. No `0x24xx` completion behavior should be retained from
this hypothesis.

Read-only DMA logging in a later build showed the formatter receives the
actual data: `UNITDESC` at physical address `0x070270`, `VOL1` at
`0x0773fa` for its first read in the ETF phase (track 0, sector 7), and
`01 01 86 78 20 4c 31 20` from the synthetic ERMAP at the same DMA
address after SEEK to cylinder 924. The synthetic record was produced by
HDC5X3 option 3. The logging edit was also removed. These results rule out
missing DMA bytes as the immediate cause; they do not validate the ETF
record or the later DCOS callback sequence.
