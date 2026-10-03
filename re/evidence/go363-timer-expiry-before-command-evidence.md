# GO363 board timer: terminal count before command 4100 (HDC505 test 4)

Recorded 3 October 2026, before changing `src/devices/bus/olivetti_l1/go363.cpp`.
**Provisional** (AGENTS.md, GO363 rule): from two DCOS paths, no board
documentation.

## Symptom

After the unit-status fix (`go363-unit-status-gate-evidence.md`), DCOS
`006.HDC505` passes tests 1–3 and stops at test 4 step 1:

```text
COMMAND NOT CORRECT=   HDC5.CONTIMER
DIAG.COD(EX-VALUE) CMD START=41 END=41
NOT GENERATING INTERRUPT ( PRINO = 0 )
```

([screen](screenshots/hdc505-20261003-after-unit-gate.png)). On 20 September
(`576ccea57ec`) test 4 reached step 3.

## DCOS path 1: HDC505 test 4, `HDC5P_CONTIMER`

I/O log of the current build (`io_std` tap, `0x3000`–`0x3fff`), test 4 step 1:

```text
829.6960  W 3856=36   W 3846=04 W 3846=00     counter 0: mode 3, count 0004
829.6960  W 3856=70   W 3847=01 W 3847=00     counter 1: mode 0, count 0001
829.6960  W 3848=0002 W 3848=00C0 W 3848=000D
829.6960  W 384C=4100                         board command 4100
829.6962  R 3F4A=0000 ... (98,300 reads)      poll for PRIN0 (4b bit 5); never set
```

The sequence and its meaning are already recorded in
`re/hardware/go363/GO363_HDC5_diagnostics.md`, "Test 4: the two distinct 8253
timers": loading the GO363 8253 starts it, as on any 8253, and its terminal
count precedes the later `4000`/`4100` command, which only reports the result.
With counts `0004 × 0001` the model's terminal count (20 MHz, one event) comes
0.2 µs after counter 1 is loaded, before `4100` is written.

## DCOS path 2: the timer as a watchdog during disk commands

`doc/GO363_DCOS_RECOVERY.md` (S24W25 read path, "timer done command=1100"):
during ordinary disk commands the same timer runs as a watchdog, and an expiry
reported as `PRIN0` (status `28`) was taken by DCOS as a completion. That led to
the gate below.

## Cause in the model

`board_timer_done()` (added in `2eef3161383`) returns without effect unless the
current board command is `4000` or `4100`. Path 1's expiry happens while the
previous command is current, so it is lost.

## Change made (3 October 2026, MAME working tree, uncommitted)

A latch `m_timer_expired` records every terminal count; it is cleared when
counter 1 is reloaded, on code `0040`, on command `39` and at reset, and saved in
save states. At expiry:

- with the timer interrupt enabled (`ff02`), the expiry is reported at once
  (`PRIN0`, and VI): test 4 step 3 loads the long count `fffe × 000f`, enables
  the interrupt and issues `4000` only after it has expired (I/O log: load at
  829.6972, expiry 829.7465, `4000` at 829.7466), as the GO363 note already
  recorded ("waiting for the future `4000` command misses the interrupt");
- otherwise it is reported only while `4000`/`4100` is current, or when that
  command is issued and the expiry has not been reported yet.

A first version also re-reported an already-reported expiry when `4000`
arrived. That raised a second VI which code `0040` does not clear; when HDC505
restored its vector table and executed `EI VI` at `21150E`, the stale interrupt
ran the restored handler and ended in a segment trap (CPU trace, IRQ 1 at
`211510`, IRQ 2 at `219E78`). Hence "not reported yet".

## Checks

- HDC505 test 4 passes step 1 and reaches at least step 3 (its 20 September
  state); tests 1–3 still pass.
- S24W25 still records Standard 24; `scripts/test-m40-hd.sh` still passes.

## Results (3 October 2026, rebuilt `m40`)

- HDC505: tests 1–3 pass; test 4 passes steps 1 and 2 and stops at step 3 with
  the same timing error as on 20 September, `TIME MEASURED = 012716`,
  `EXPECTED BETWEEN MIN.07AF00 MAX.07B100`
  ([screen](screenshots/hdc505-20261003-after-timer-fix.png)). That is the known
  open point, the GO363 8253 clock: the model runs it about 6.7 times too fast.
- S24W25: `STANDARD 24 RECORDED`, 0 errors; final screen pixel-identical to the
  run before this change.
- `scripts/test-m40-hd.sh`: BCOS and MOS PASS.
