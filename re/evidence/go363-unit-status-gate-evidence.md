# GO363 unit status is gated by auxiliary code `0D` (HDC505 test 2 regression)

Recorded 3 October 2026, before any change to `src/devices/bus/olivetti_l1/go363.cpp`
in the external MAME tree. **Provisional:** no GO363 hardware documentation
describes these registers; the behaviour is recovered from two DCOS programs
(AGENTS.md, GO363 rule).

## Symptom

DCOS `006.HDC505` (disk G) fails test 2, "generate interrupt and test vectors",
on the current build:

```text
ERR.0001 *PGM HDC505 *TST 02 *CYC 00001
'STATUS' ERROR AFTER RUN-COMMAND
UNSE0 STUCK AT 1   SKEN0 STUCK AT 1   UPR00 STUCK AT 1
```

([screen](screenshots/hdc505-20261003-test2-failure.png)). On 20 September
(`576ccea57ec`) tests 1–3 passed with the same disk, image and keys. The saved
1 October binary already fails, so the cause lies in the 21–26 September commits
(`doc/MAME_DRIVER.md` §9).

## Cause in the model

Commit `2eef3161383` (26 September) made GO363 register `43`, the low byte of the
unit status word at `42`/`43`, return `0x15` whenever unit 0 has a disk attached
(`0x2a` for unit 1), unconditionally. It was added for S24W25 (see
`doc/GO363_DCOS_RECOVERY.md`, "Unit status word"). The status bits are named in
the HDC5 runtime's message table on disk G (flat-image offset `0x90f80`):
`UNSE0 UNSE1 SKEN0 PIZE0 UPR00 ERWR0 POSF1 ERBUI PAER0 RESEB PRIN0`, bit 0 first.
`0x15` is bits 0, 2, 4: `UNSE0`, `SKEN0`, `UPR00`, exactly the three reported
stuck at 1.

## DCOS evidence

Original DCOS 8.4 disk G,
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`.
Runs on disposable copies; I/O traced with a Lua tap on `io_std` `0x3000`–`0x3fff`,
instructions with the MAME debugger `trace`.

**Path 1, the common HDC5 unit-status helper** (S24W25, loaded at `0x2158D0`,
traced in `runs-archive/standard24-dcos-clear-20260925/s24w25-pu.trace`):

```text
2158D0  ldb rl2,#0x40 ; out @r2,r0     write the physical unit to register 40
2158D4  ldb rl2,#0x48 ; ldb rl1,#0x0d ; out @r2,r1     auxiliary code 0D (port 48/49)
2158DA  ldb rl2,#0x42 ; in  r1,@r2     read the unit status word
2158DE  ldb rl2,#0x48 ; ldb rl0,#0x0c ; out @r2,r0     auxiliary code 0C
2158E4  bit r1,0 / bit r1,4 / bit r1,5 / bit r1,2     unit 0 present when 0,2,4 set, 5 clear
```

The byte sequence `ca40 3f20 ca48 c90d 3f21 ca42 3d21 ca48 c80c 3f20` occurs
twelve times on disk G (flat offsets `0x1e430`, `0x45fe2`, `0x59a22`, `0x7c4d0`,
`0x8e2be`, `0x96ef8`, `0xa24d0`, `0xafad0`, `0xbd0d0`, `0xca6d0`, `0xd7cd0`,
`0xe52d0`): every HDC5 program carries this helper. The I/O log of a rerun on the
current build shows `W 3840=0000`, `W 3848=000D`, `R 3842=0015`, `W 3848=000C`.

**Path 2, HDC505 test 2's response array** (loaded at `0x21CA3A`, traced on the
current build):

```text
21CA3A  ldb rl2,#0x42 ; in r1,@r2      read the unit status word directly
21CA3E  xor r0,r0 ; bit r1,0 ; ...     store bits 0–5 into the response array
21CA84  ldb rl2,#0x4a ; in r1,@r2      then the board status word
```

The I/O log of the test: board command `3900` (diagnostic reset), `W 3810=0100`,
board command `0100`, `R 3842`, `R 384A`, board command `0500`. There is no
write to register `40` and no `0D` before the read, and the diagnostic requires
`UNSE0`, `SKEN0` and `UPR00` to be 0 there.

## Inferred behaviour

The unit status bits are driven only while auxiliary code `0D` is in effect: `0D`
on port `48`/`49` enables them, `0C` disables them, and they read 0 otherwise
(including after reset). This agrees with how ST506 drives behave: their READY,
SEEK COMPLETE and fault outputs are only driven while the drive is selected.
Which unit's bits appear is left as now (unit 0 in bits 0/2/4, unit 1 in
1/3/5); the value written to register `40` is not modelled.

## Change made (3 October 2026, MAME working tree, uncommitted)

In `go363.cpp`: a latch `m_unit_status_enabled`, set by a low-byte `0D` write to
register `49`, cleared by `0C`, by board command `3900` and at reset, and saved
in save states. Register `43` returns the attached-unit bits only while it is
set.

Board command `39` clearing the latch comes from a second HDC505 trace on the
first version of the change, which cleared it only on `0C` and reset. Test 2's
first read then returned `0000`, but test 2 continues with `W 3848=0005`,
`W 3848=000D` (data for `GENINT`, command `0B`), board command `3900`, and reads
`42` again, expecting the bits clear; it got `0015`. S24W25 issues no `39`
between its `0D` and its read, so both paths agree with `39` clearing the latch.

## Checks

- HDC505 tests 1–3 must pass again (path 2).
- S24W25 must still find unit 0 and record Standard 24 (path 1).
- HDC5F5 must still format; `scripts/test-m40-hd.sh` (BCOS and MOS hard-disk
  boots, whose drivers may read the unit status) must still pass.

## Results (3 October 2026, rebuilt `m40`)

- HDC505: tests 1, 2 and 3 pass. Test 4 now stops at step 1, `HDC5.CONTIMER`,
  `NOT GENERATING INTERRUPT (PRINO = 0)`
  ([screen](screenshots/hdc505-20261003-after-unit-gate.png)); on 20 September it
  reached step 3. That is a separate regression in the board timer interrupt,
  not yet investigated.
- S24W25: finds unit 0 (`R 3842=0015` inside the `0D`/`0C` window) and ends
  `STANDARD 24 RECORDED`, 0 errors.
- `scripts/test-m40-hd.sh`: BCOS and MOS PASS.
- HDC5F5: the archived start-up sequence (`runs-archive/hdc5f5-timeout-20260926/run.lua`,
  shifted 30 s) loads it, accepts slot 3 and PU 0, and reaches `HIT 451 TO
  CONTINUE`; a full format was not rerun, because the archived schedule ends there.
