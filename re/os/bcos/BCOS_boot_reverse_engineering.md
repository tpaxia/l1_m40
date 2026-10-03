# BCOS II boot reverse engineering (M30/M40)

## Latest verified result: 2026-09-10

The date-to-SYS path now executes commands, not merely displays a prompt.
Native KUSA inputs restored after withdrawing the photo-driven replacement.
Run `2xKETx`: keypad date 860909 + Enter, then SYS + Enter, **without Ctrl+J**,
loads the SYS Operating System Generator. Run `8GLYpT` with Ctrl+J instead
attempts JSYS and reports ERR.153. Current instructions: [re/os/bcos/BCOS_BOOT.md](BCOS_BOOT.md).
The historical failures and generic OSLEM instructions below are not the
operating sequence for the now-working SYS prompt.

This note records verified boot behavior so that the same media and prompt mistakes
are not repeated. Evidence is from BCOS II manuals, strings in the disk images, CPU
and board-I/O traces, and live MAME runs.

## BCOS II 3.3 all-resident image

Image used:

`BCOS_II_3.3_FD_ALL_RESIDENT.imd`

Observed clean boot timeline on the M40 model:

- about 0–15 s: ROM RAM test;
- about 16–25 s: floppy load;
- about 26–27 s: loaded-system initialization;
- about 28 s onward: the kernel is alive in the interrupt-enabled scheduler idle loop
  at logical `02:0912`.

The displayed `SYS=...` / `PUS=DISK` page is a system-environment status page.
`PUS` means **Peripheral Unit**; `PUS=DISK` says that module is disk-resident. It is
not a prompt. A real CONTROL+J chord was tested: the handler consumed scancodes
`0x70` (CONTROL make), `0x1a` (J), and `0x78` (CONTROL break), returned normally, and
the display remained byte-for-byte unchanged. Ctrl+J belongs to the later `/SYS`
Ready command environment described in the BCOS manuals.

The idle loop is not a CPU or MMU crash. Its core is `ei nvi,vi`, followed by a queue
test and a branch back to `02:0912`. Tasks run from it to draw the environment page.

The CPU-board PIT is deliberately stopped by BCOS during the transition. At
`39:0620` the loaded code executes `outb #0xffc7,rl0` with `rl0=0x70`, then calls
three board-enumeration/initialization routines. This is an OS write, not a stray
8253 side effect. A diagnostic experiment that ignored just this control write
kept the old periodic tick running: BCOS advanced from `PUS=DISK` to later library
status text, but repeated the transient display work until the screen degraded.
Therefore preserving the timer is not a fix; the original stop is intentional and
the remaining problem is still the missing matching BCS431 runtime/configuration.

## Keyboard path found during this boot

BCOS initializes the GO252 vector to `0x06` and writes keyboard control `0x16`.
GO252 control bit 4 therefore has to enable normal receive interrupts. With a keypad
ENTER byte (`0x61`) queued, the verified handler sequence is:

```
003B:069E  read GO252 status -> 0x06
003B:06CE  read GO252 data   -> 0x61
003B:06E4  write control     -> 0x16
```

The handler returns cleanly to the scheduler. The same result was obtained with the
`J` scancode (`0x1a`). The KEYTE1 diagnostic was rerun after modeling bit 4 and its
existing bit-7 diagnostic mode continued to deliver keys normally.

## K02733 is a boot disk, not the all-resident disk's companion

`K02733_BCOS_II_3.3_CONFIGURATOR` is itself a configurator boot disk. It is not the
run-time companion for the all-resident load disk. An earlier experiment replaced the
load disk with K02733 at emulated second 15, while the loader was still reading it;
the resulting mixed execution and screens are invalid evidence.

The all-resident image contains the message:

```
DISMOUNT LOAD-TIME DISK
MOUNT RUN-TIME DISK
AFTER ANY KEY : GO
```

but a clean boot has not reached that message; it first remains on the system
environment/PUS status page. Do not change disks merely because `PUS=DISK` is shown.

### Direct K02733 boot (2026-09-03)

K02733 was also tested correctly as the power-on boot disk, rather than as a
mid-load replacement. MAME cannot mount SCP directly, so
`K02733_BCOS_II_3.3_CONFIGURATOR.scp` was converted to IMD with `disk-analyse` and
mounted on GO280 unit 1 (`-flop2`). The recovered geometry is the normal L1 layout:
track 0 has 26 x 128-byte FM sectors and cylinders 0-76 thereafter have 26 x
256-byte MFM sectors.

The disk **does boot**: ROM IPL emits both `0x55` success markers, unit-1 FDU reads
complete normally, BCOS writes GO252 keyboard control `0x16`, and the display reaches
the environment page beginning:

```text
SYS=  0 X      IPL= E100      JLD0 A.02 PDB= .440 NDB= .540 1DB= .700 SRA= .6D5
     LIB= ...1
```

With corrected GO280 interrupt masking it advances to the complete load-time status
page (`PUS=DISK OK`, `LDK=E100`, `TIMEOK==KEYB`) and remains in the normal scheduler.
It does not yet advance into the On-Line Generator pages whose text is present on
K02733. Evidence is in `runs-archive/20260903-k02733-ens00-fix/` ([screen](../../evidence/screenshots/20260903-k02733-ens00-fix.png)).

A physical Ctrl+J chord was then driven through the matrix inputs. The recovered
8049 firmware and KEYTE1 tables establish the byte sequence as CONTROL make `70`,
J make `1A`, CONTROL break `78`; ordinary matrix keys do not emit break bytes.

The first 512 KB run had already gone off course before the chord: its FCW had VI
disabled and GO252 retained the bytes. A RAM-size sweep is therefore essential for
this configurator image:

- with 1 MB, startup reaches `OK==LDK=E100`, `TIMEOK==KEYB`; the resident KDC
  handler consumes `70 1A 78`, but control then enters unmapped segment `34:6160`.
  Z8010 VTR becomes `9C` (length + CPU-inhibit + execute violation, then fatal);
- with an explicit 1.5 MB RA57/B, the same three bytes are consumed and the KDC
  latch is rearmed after each, with VTR remaining zero, but startup itself remains
  at `TIME` and does not enter the On-Line Generator during the observed run;
- 640/768/896 KB and the tested 2 MB setup do not improve the boot.

Those Ctrl+J experiments predate the GO280 ENSOO fix and ran after the false nested
floppy interrupt had damaged BCOS state.  They remain useful keyboard-path probes,
but are invalid evidence about normal K02733 startup.  They also did **not** prove
that Ctrl+J was valid at that point in K02733 startup.
The BCOS manual says Ctrl+J enables OSLEM's `READY` state, identified by
`0X COMMAND:` on display line 23.  K02733 has not reached that state in the runs
below, so Ctrl+J is not an IPL or configurator-start command.

### K02733 completion and two-drive experiment (2026-09-03)

Longer traces established the asynchronous wait and exposed one real emulator fault:

- the loop at `03:281c` is `tset` on an asynchronous completion semaphore; its
  callback clears the semaphore and returns normally;
- an FDC pulse occurring while ENSOO was masked remained in MAME's historical
  diagnostic latch.  Re-enabling CONTR incorrectly promoted it to INTP1, nested the
  non-reentrant BCOS floppy handler, overwrote its global register-save area, and
  corrupted `rr2` before the outer `iret`;
- the GO280 manual says ENSOO conditions formation of INTP1.  MAME now promotes
  only a live source on the enable edge, not a pulse that ended while masked;
- after that correction, the final GO280 channel-1 timeout fires, vectors, and is
  acknowledged normally.  The CPU remains in `02:0912..091e` scheduler idle.

Consequently, the old open-bus execution was neither a keyboard failure nor a
missing timer: it was downstream of a false nested GO280 interrupt.

Drive order is proven: K02733 must be in MAME connector 1 (`-flop2`), the uPD765
unit selected by this ROM configuration.  Swapping only the two volumes does not
boot K02733.  Decoded FDC commands during the verified boot all address unit 1;
no unit-0 command was observed.  The earlier apparent differences among K02733,
K02736, K02737, K02738 and K02739 in connector 0 were measured before the ENSOO fix
and are not evidence of a companion-volume requirement.  K02737 remains mounted in
the reproducible baseline only to preserve the known run configuration.

The precise keyboard transition is also now known.  In the corrected run BCOS writes
GO252 **control register** `00` with `03`, then `16`, reads the firmware's `FC`
startup byte from **data register** `02`, and at 18.067049 s writes `00` back to the
control register.  That last access was initially mislabelled as keyboard command
`00`; it is not.  No write to data/command register `02` occurs, so BCOS never tells
the recovered 8049 firmware to end its repeated startup announcements and enter
foreground scanning.  A later direct status/data probe returns `03`/`FC`, confirming
that another startup byte is waiting in the polled state.  No automatic-start or
one-shot-`FC` compatibility hack remains in MAME.

Post-fix keypad-Enter and Ctrl+J experiments at 45 s produced neither a screen change
nor a later host GO252 bus read.  The keypad run verified that physical `K5` was held
high and released, but because the MCU remains in its pre-command-`00` announcement
loop, this is not evidence that BCOS rejected the key.  It is evidence of a real
BCOS/8049 protocol mismatch that must be understood before using keys to start the
generator.

Current evidence is under `runs-archive/20260903-k02733-ens00-fix/` ([screen](../../evidence/screenshots/20260903-k02733-ens00-fix.png)) and
`runs-archive/20260904-k02733-keypad-fixed-headless/` ([screen](../../evidence/screenshots/20260904-k02733-keypad-fixed-headless.png)).  The exact unattended invocation
and its pitfalls are recorded in `re/os/bcos/K02733_BCOS_headless_boot.md`.

## What the surviving 3.3 media set contains

The distribution images identify themselves through `HDR1` records and content:

- K02733: configurator with BCS433/533/233/033/633/833 components;
- K02734/35: UTS033/UTS133 subsystem disks;
- K02736: mono-HDU configurator input (BCS033/233);
- K02737/39: BCS and UTS subsystem/library media;
- K02738: multi-disk configurator input;
- K02740: UTB333;
- K02741: JJKEYB;
- K02742: TOCHD;
- K02743: J0XI33 configurator documentation/support.

The all-resident image contains generation identifier `BCS431`. No matching generated
BCS431 run-time volume has yet been identified in this set. The numbered K027xx disks
are distribution/configuration inputs, not automatically interchangeable run-time
companions. A complete run-time system was normally generated by the BCOS configurator
for a particular hardware configuration.

## 2 MB boot follow-up (2026-09-08)

The 2 MB K02733 boot is still incomplete. The stable PC `03:05c6` after the
September 4 UC address-mask change is **an error stop**, not a scheduler or
keyboard wait. Opcode `e8ff` branches unconditionally to itself. This corrects
the earlier session's interpretation of that result and its claim that the
mask change established the cause of the boot failure.

Observation-only traces establish this sequence:

1. At `03:075e`, the library loader has `rr6=8300:5000` (logical `03:5000`).
2. GO280 vectors into `3b:0d28`. Before the handler restores its global register
   save area, writing CONTR `1b` at `3b:1aae` enables another vector `08`.
3. The nested entry overwrites physical `022628..022642` with the outer
   handler's working registers. The outer IRET itself reads a valid frame and
   returns to `03:082e`; it does **not** restore `20:2020` from the stack.
4. The loader resumes at `03:058c` with `rr6=fa00:0000`. `ldl rr0,@rr6` now
   accesses logical `7a:0000`, rather than the library buffer.
5. With the old 22-bit UC mask this aliases descriptor `3a`, faults and vectors
   through an unset PSA entry containing `2020:2020`. With the current 23-bit
   mask, the unqualified MMU access returns `ffff`; execution continues to the
   failed `J0XP` lookup and the permanent error loop at `03:05c6`.

Thus the high-segment access is downstream register corruption, not evidence
that BCOS intentionally probes an upper-range MMU. The 23-bit mask remains in
the checkout from September 4, but successful RAM tests and avoiding the trap
do not establish correct UC board address decoding or successful BCOS boot.

Evidence: `runs-archive/bcos-trace.kiNiYb/` captures `03:058c` onward;
`runs-archive/bcos-trace.VBoySg/` captures the loader call and nested interrupt.
Both contain a physical RAM dump at trace activation. The resumed fixed-PC
trace is in `runs-archive/20260904-k02733-2m-305c6-wait/` (run September 8).

### Controlled interrupt-latch experiment (reverted)

Removing the CONTR-enable promotion of already-high source levels prevents
this nested interrupt. `rr6` stays `8300:5000`, the library lookup succeeds,
and the loader reaches configuration-table initialization. Evidence:
`runs-archive/bcos-trace.Kxo2uO/` ([screen](../../evidence/screenshots/bcos-trace.Kxo2uO.png)).

That run is **not a successful boot**: at `03:0b64`, the count in `r1` is zero;
subtracting four yields `fffc`. The fill loop at `03:0bbc..0bc0` then overruns
memory. This second failure needs its own input/configuration investigation.

The original nested request reports SENSE INTERRUPT statuses `c2`, `c3`
(READY changes for controller units 2 and 3). DIAGN forces READY in the current
FDC model. The manual explicitly allows DIAGN to force READY; this does not
by itself justify suppressing these units or their status changes. Section
3.5 says ENS00 conditions the setting of INTP1, but the prose alone does not
settle source-edge versus enable-edge behavior. The latch experiment was
reverted and MAME rebuilt; the pre-existing GO280 changes were preserved.

The trace script used here, `scripts/trace-bcos-boot.sh`, was removed when the
driver's native trace hooks were (September 2026). For reproducible boots use
`scripts/boot-m40-bcos.sh` (fresh NVRAM, disposable media copies, timed
screenshots); for tracing, the MAME debugger and Lua techniques in
`DEBUGGING_STRATEGY.md`.

## 2026-09-08: manual-guided interrupt A/B regression

Read 3963590 R(2), printed page 3-7 and section 3.5 (3-23/3-24).
Page 3-7 explicitly describes INTOO rising-edge triggering; section 3.5
describes ENS00 masking formation of INTP1 and VCOUT clearing INTP1.
This does **not** establish the position of the enable gate relative to
edge detection. Do not infer that enabling a high source must be ignored.

Repeated the no-unmask-promotion experiment, rebuilt, and ran both BCOS and
the DCOS disk-D loader. BCOS evidence: `runs-archive/bcos-trace.ItaQog/` ([screen](../../evidence/screenshots/bcos-trace.ItaQog.png)).
The library pointer remains `8300:5000` at `03:058c`. The later failure is
precisely `03:0b62` loading zero from `03:411a`, then `03:0b64` subtracting
four, producing `fffc` and overrunning the fill table at `03:0bbc`.
This is progress past one failure, **not a boot or a validated fix**.

The DCOS A/B test rejects the change:

- Edge-only: `runs-archive/20260908-232726-go280-edge-interrupt/` repeats
  INSERT DIAGNOSTIC DISK without loading 6030T6. At `02:bbdc` reset release
  raises FDC IRQ while masked; `02:bde6` writes CONTR=03 with IRQ still high.
- Restored baseline: `runs-archive/20260908-232847-go280-baseline-interrupt/`
  loads 6030T6 with the same disk and key sequence.

The experiment was reverted and the baseline rebuilt. Existing unrelated
MAME modifications were retained. No new functional MAME fix is validated.

Read Functional Checks Manual 4102230 T(0), section 1.2.5, pp. 1-36/1-37:
at `type "0" to help`, `1` runs the program; `2` changes the sequence.
Typing `3-1` directly is **not** a test-3 execution request. Several old
run names/notes are misleading on this point; inspect executed I/O and error
records before counting diagnostic passes. Monitor LOAD activates 6030T6
directly: the next input is slot `2`, then the default PU. Do not send GO
(`4`); that selects slot 4 instead. This differs from LOAD inside HELP.

`scripts/test-m40-fdu.sh` provides a bounded, background-only invocation on
disposable copies of disk D, with direct-LOAD slot-2 input and the actual
run command plus Enter confirmation. The default full sequence may
write/format only those copies.
Optional arguments are a timed key string and emulated duration.

The correctly executed baseline diagnostic is
`runs-archive/fdu-validation.dWB3HX/20260908-233924-fdu/`: tests 1 and 2
advance, test 3 reports `FDC INTERRUPT NETWORK FAULT`. The failing check at
`21:A282` reads F7=02 after EO1NT. Its FDC source arose after CONTR=13
enabled DIAGN, not from a read command. See the new live-test section in
`re/hardware/go280/GO280_FDU_diagnostics.md` and annotations at image `7AA78`, `7AAA4`,
and `7AC32` in `re/disassembly/diagnostics/diskD_6030T6_6d900_7c780.dis`.

Promoting both captured FDC and timer causes on enable was also tested:
`runs-archive/fdu-validation.LZXeFb/20260908-234036-fdu/` failed to reach
the diagnostic parameters (blank screen), and `runs-archive/bcos-trace.lREEdE/` ([screen](../../evidence/screenshots/bcos-trace.lREEdE.png))
still returned with rr6=FA00:0000. It is not a valid general fix either.

Isolating captured timer promotion while retaining live FDC promotion:
`runs-archive/fdu-validation.wsuiyG/20260908-234154-fdu/` reached test 3 but
MAME exited with SIGSEGV (-11), so this did not validate the hypothesis.
All functional experiments in this section were reverted and the original
working-tree baseline rebuilt. The lasting changes are the reproducible
test script, observations, and disassembly annotations, not a boot fix.

## 2026-09-09: partial timer interrupt correction retained

Superseding the previous all-experiments-reverted state: MAME now retains
the timer cause on enable (`m_timer_latched`); FDC enable still uses its live
source. Same-harness A/B diagnostic runs confirm test 3 stops with the old
live-timer behavior and advances to test 4 and beyond with the change.
There is a later interrupt-disable warning and test-7 exchange failure;
this is not a full diagnostic pass. BCOS still fails with rr6=FA00:0000
in `runs-archive/bcos-trace.UpiUQI/` ([screen](../../evidence/screenshots/bcos-trace.UpiUQI.png)). See the September 9 section in
`re/hardware/go280/GO280_FDU_diagnostics.md` for traces and precise limitations.

The diagnostic harness now schedules keys on frame callbacks, avoiding both
the crashing Lua memory-tap path and coroutine resumption path. All runs are
bounded and use background-only SDL settings and disposable disk copies.

## 2026-09-09 final: spurious READY transitions corrected

Supersedes the provisional timer fix above: it is reverted. The actual retained
change removes the unconditional READY override on CONTR bit 4 in normal FDU
mode. Four-drive controls with the old code and two-drive/one-loaded-disk runs
with the corrected code complete the full diagnostic interrupt-vector sweep,
DMA test and tests 5/6, without the interrupt-disable warning. Details and
manual limitations are in `re/hardware/go280/GO280_FDU_diagnostics.md`.

BCOS evidence: `runs-archive/bcos-trace.ymwpJM/` ([screen](../../evidence/screenshots/bcos-trace.ymwpJM.png)) (normal two-drive configuration).
rr6=8300:5000 at 03:058c, r1=7 at 03:0b64, no configuration-table underflow,
and the 74-second CPU snapshot is in the scheduler. The four-drive control
`runs-archive/bcos-trace.A7JlYp/` ([screen](../../evidence/screenshots/bcos-trace.A7JlYp.png)) produces the same improvement without the READY
code change, isolating the artificial unused-unit attention interrupts.
No configurator UI success is claimed. No keyboard injection was needed to
remove the traced register corruption.

Additional rejected models: always-captured single pending latch with raw
RD1NT (`fdu-validation.I1clEe`, `bcos-trace.LqgFX5`) regresses IPL; retaining
the old RD1NT readback with that pending model (`fdu-validation.kWLq5y`,
`bcos-trace.kbbMaz`) regresses the DCOS loader and leaves BCOS corruption.
Neither remains in MAME. The final build preserves the pre-existing live-source
enable promotion and gated source-edge pending logic.

## 2026-09-09 follow-up: UC aliases and complete level-2 gating

The prior 74-second scheduler observation was too early to establish a healthy
idle state. At 74.62819375 s the UC timer interrupted the FDU handler, overwriting
their shared register-save area at 00:0028. The scheduler then received R2=2000
instead of 0000. BCOS used F084/F08C, which the UC's FFxx-only map ignored.
Mirroring bits 11-8 fixes those accesses, consistent with manual 3963590 R(2),
§3.1 p. 3-1 and the firmware's paired F0xx/FFxx strobe usage.

That was not sufficient: at 85.2034115 s the FDU re-entered itself while VIENO was
disabled. The Concise Functional Checks manual 4102230 T(0), §3.1.1 p. 3-1,
explicitly defines VIENO as level-2 vectored-interrupt enable. It must gate all
level-2 sources, not merely the UC timer. The bus now applies it to pending and
acknowledge selection, leaving level 1a/1b available and retaining masked requests.

Validation:

- All 16 VIENO write aliases x 16 read aliases pass, enabled and disabled.
- Isolated pending-source fixtures confirm masked FDU requests survive and are
  exposed on re-enable; GO252 level 1b remains enabled. The test allows deferred
  CPU pin updates to synchronize before checking them.
- UC3003 run `runs-archive/uc-validation.D80ueX/` ([screen](../../evidence/screenshots/uc-validation.D80ueX.png)) passes VIENO, all timer counters and
  ACIA, then reports test 5 NV2 INTERRUPT MASK FAULT. Same fault occurred before
  the level-2 correction. It is not an all-tests pass.
- FDU `runs-archive/fdu-validation.TMV3vw/` ([screen](../../evidence/screenshots/fdu-validation.TMV3vw.png)) advances through interrupt/DMA tests to
  speed measurement, no displayed interrupt fault.
- BCOS `runs-archive/bcos-boot.nP9IdK/` ([screen](../../evidence/screenshots/bcos-boot.nP9IdK.png)) has rr2=0000:12F8 at 119 seconds. The screen
  has cleared except for the bottom-right MOF marker, not a configurator prompt.

Keyboard trace `runs-archive/bcos-boot.dDJtvH/keyboard.log` supersedes the earlier
"host never sends command 00" conclusion: after these interrupt corrections,
BCOS sends 00 then 01 at about 75.56 seconds and receives FA. It retries this
initialization several times. At 95 seconds it consumes CONTROL/J/release bytes
70/1A/78 without a visible prompt. The response-handling path is the next target;
do not force keyboard startup or declare the configurator successfully booted.

All temporary instrumentation and experiments are tracked in `re/os/bcos/BCOS_DEBUG_LEDGER.md`.

## GO252 receive status: progress beyond blank/MOF

The receive callback at 25:0362 clears TX-ready bit 1 from RH0, then posts the
event to the keyboard process. IKYB (segment 01, module at physical 20FC00)
tests RH0 bit 2 at 01:0098 and restarts initialization if set. Reporting status
06 for every byte therefore turns FA into a reset event, not a self-test reply.

Experiment `bcos-boot.u6UnMZ` substitutes RDRF bit 0 for bit 2 when receive
interrupts are enabled (control bit 7). It completes 01/FA, 02/FB/F1, 0C/10,
04/0D and reaches the BCOS mono-user banner with DATE YYMMDD. The native
GO252 correction reproduces that prompt without an override in
`bcos-boot.YBNr8r`. The older bit-4-only behavior remains unchanged.

Input is a separate validation step: status 03 becomes RH0=01, which the
runtime 1KYB handler recognizes as a completion event, not normal input.
An IRQ-status-bit experiment is tracked in the ledger. Top-row key legends
also do not match this disk's KITA translation table, so numeric prompt tests
must use the keypad rather than assume the host's top-row digits are equivalent.

Final native-only verification `bcos-boot.rcwPJZ`: status 83 completes the
handshake and permits numeric keypad date entry; BCOS reaches SYS at 119 seconds
and remains there at 159 seconds. Neither status override nor Ctrl+J is needed.
Both causal override branches were removed from the observer. Launch procedure:
`re/os/bcos/K02733_BCOS_headless_boot.md`. Further configurator operations remain untested.

## Manual/source inventory warning

`reference/ArchiviOlivetti/M30-M40_KDC.pdf` is only a four-page printout of the Archivio
Storico Olivetti catalogue record for archive item 769. It is not a GO252 manual and
contains no board-level technical information. GO252 conclusions must continue to be
marked as ROM, disk-diagnostic, or emulation evidence unless an actual manual is found.
