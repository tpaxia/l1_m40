# PROVISIONAL experiment — zero-distance uPD7261 SEEK completion timing

The NEC manual, printed page 6-21 (PDF page 19), says a soft-sector
normal-stepping SEEK with polling disabled completes when the drive asserts
SKC. The current sector-image abstraction has no drive SKC line and models
completion using only the calculated step-pulse duration.

For ERMAP's final SEEK to its already-current cylinder `0x039c`, that duration
is zero. A first experiment substituted the controller's ordinary 400 ns
execution delay. It did not fix the timeout: ERMAP reached selector state
`0x05`, but its callback and completion-flag writer were not invoked.

The disposable sweep tried 400 ns, 10 microseconds, and 1 millisecond for the
zero-distance case only.

Success criterion:

1. after the final command issue (`r1=0x0068`), breakpoint logs show callback
   `0x030efc` and flag writer `0x030f22`;
2. sampled PCs leave `0x0312be`/`0x0312c6`;
3. no interrupt storm is introduced;
4. the same value must then be checked against ERMAP option 2, Standard 24,
   and HDC505 before it can be retained.

All three values failed identically: after the final `0x68`, no ERMAP callback
or completion-flag write occurred, sampled PCs remained in the wait loop, and
the CHD stayed byte-identical. The timing hypothesis is rejected. No timing
change from this experiment should remain in the external MAME tree.
