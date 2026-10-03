# uPD7261 Read Data completes too early: HDC5F5 ETF timeout (2026-09-26)

## Symptom

`1003.HDC5F5` prints `STANDARD NO. 24 READ PHASE ...`, `ETF READ PHASE ...`
and then `ERR.0001 HARDWARE FAILURE / TIME OUT DURING I/O OPERATION`. The
uPD7261 `0xb0` READ DATA at cylinder 924 ends with normal status, and its
256-byte DMA reaches memory (`re/evidence/go363-post-read-completion-evidence.md`).

## Primary hardware documentation

NEC, *uPD7261A/B Hard-Disk Controllers*, `reference/datasheets/NEC_uPD7261B_datasheet.pdf`:

- Printed page 6-23 (PDF page 21), "Read Data", items (1), (2), (9) and
  (12): the HDC reads the sector named by LCNH/LCNL/LHN/LSN *from the disk*.
  It has to find that sector's ID field on the rotating track, which can take
  up to three index pulses before ND. It then synchronizes on the data
  field's address mark and transfers the data by DMA. Only after the sector
  count reaches zero does it set the result bytes and signal completion
  (page 6-24, item (11)).
- Printed page 6-17 (PDF page 15), "ST506-Type Interface": in ST506 mode
  the controller performs MFM encoding and decoding "at data rates to
  6 MHz". The Olivetti *L1 Functional Checks Manual* (January 1987)
  identifies WREN1/2 as ST506 drives on G0363, e.g. its hard-disk
  configuration tables ("WREN1/2 (XU1707/1709) 27/65 MB G0363 (ST506)").
- Printed page 6-7 (PDF page 5), AC Characteristics, "ST506-Type
  Interface": R/W CLK cycle period `tRWCY` is at least 83 ns; R/W DATA is
  sampled against R/W CLK (page 6-10, "Data Read/Write Timing"). This
  corroborates that disk data arrives serially at a bounded rate.

Reasoning: every bit of the data field comes off the disk serially. At the
highest documented ST506 data rate (6 Mbit/s), a 256-byte data field takes
at least `256 × 8 / 6 MHz ≈ 341 µs`. The command cannot complete before
that. This ignores the ID field, the gaps and rotational latency, all of
which add more time. It is a documented **lower bound**, not a measurement
of the WREN2/GO363 path. The drive's actual rotation speed and data rate are
not in the documents available here, so no rotational latency is modelled.

## Current emulator behavior

External MAME, `src/devices/machine/upd7261.cpp` at `2eef3161383`: command
`0xb` sets `EXECUTE_READ` and schedules `execute` (400 ns). `state_step()`
then reads the CHD sector and raises DREQ at once. The GO363 DMA drains the
buffer synchronously, and `data_r()` advances the state machine with zero
delay to `RESULTS_bcdef` / `COMPLETE` / INT. In the device log the VI is
acknowledged at `0x219270`, the instruction after the command write at
`0x21926e` (`runs-archive/formatter-wren2-20260926/error.log`).

## Why DCOS fails with an instantaneous read

The original DCOS 8.4 Disk G image is
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`.
HDC5F5's shared runtime is loaded so that `flat = loaded − 0x1d3200`. All of
the following were verified byte-identical between the extracted image and
the runtime dump `runs-archive/formatter-wren2-20260926/hdc5f5-runtime-218000.bin`:

| Loaded | Flat Disk G | Role |
|---|---|---|
| `0x21b6da` | `0x484da` | Task level: `ldb 0xf6aa,#1` (operation busy) before starting a seek+read |
| `0x21baa4`–`0x21bafa` | `0x488a4` | Wait loop: poll `0xf6aa` until 0 or I/O timeout (~6 s) |
| `0x21bf90` | `0x48d90` | Seek-complete interrupt handler (source 1, mode 2) calls `0x21a58a` to start the read |
| `0x21926e` | `0x4606e` | `out` of uPD7261 command `0xb0`, followed by board command `0x1100` |
| `0x21c00a`–`0x21c0ac` | `0x48e0a` | Read-complete handler (source 2): parses the result and clears `0xf6aa` |
| `0x21bfec`–`0x21bff8` | `0x48dec` | Back in the seek handler: `0xf6aa = (status == 0)`, i.e. "read now in progress" |

Timestamped trace (`runs-archive/hdc5f5-timeout-20260926/breakpoints.log`):

```text
[320.0657] WAIT enter f6aa=01 ab=01 ac=02           seek to cyl 924 started
[320.1184] SEEK-ISR calls a58a (start read) f6aa=01
[320.1184] CLR f6aa (read done) cur=01               nested read completion
[320.1184] SEEK-ISR a58a returned r7=0000 f6aa=00
[320.1184] SET f6aa<-01 (f6ad=00) cur f6aa=00 ab=02  stale "in progress"
[326.1624] WAIT exit f6aa=01 r7=0002                 timeout -> ERR.0001
```

DCOS starts the ETF read from inside the seek-complete handler. Its
completion interrupt then nests inside that handler, before the handler
records "read in progress". The later write leaves the busy flag set, and no
further completion arrives. The earlier Standard 24 and `VOL1` reads are
started from task level (`0x21b6da` sets the flag first), so the same
instantaneous completion is harmless there. With a real sector time
(at least 341 µs, per the above), the seek handler reaches `0x21bff8` first.
The measurement below shows this needs about 180 µs.

Causal check (debugger only, no source change): making the `0x21bff8` store
keep `0xf6aa = 0` when it was already 0 let HDC5F5 pass the ETF read and
print `FORMAT PHASE ...`. That run then failed later with `ERR.0001 HARDWARE
FAILURE`, `FROM CYL: 919 TO CYL: 901`, after Seek, `0x0e00`, Format `0x70`
and Verify ID `0x80`. That is a separate, not-yet-analyzed issue.

## Change to external MAME

`src/devices/machine/upd7261.cpp` (uncommitted, on branch
`m40_z8010_sup_test` after `2eef3161383`): new constant
`ST506_MAX_DATA_RATE = 6'000'000` citing page 6-17. In `EXECUTE_READ`,
before each sector is transferred, the state timer waits
`dtl() × 8` bits at that rate (timer parameter 1). Only then is the CHD
sector read and DREQ raised. For 256-byte sectors this is about 341 µs. The
delay applies per sector, because each sector is read from the disk
separately (page 6-24, item (11)). Error paths (no unit, ND) and result
generation are unchanged. No GO363 behavior is changed, and no
DCOS-specific timing is introduced. The unrelated local
`src/mame/olivetti/m20.cpp` edit is preserved.

A first attempt used the R/W CLK bound (`dtl × 8 × 83 ns ≈ 170 µs`). The
race moved, but the completion still landed inside `0x21a58a` (VI at
`0x21a65a`), because that routine unmasks the HDC interrupt and runs about
180 µs of further code before returning. That weaker bound was replaced by
the page 6-17 data-rate bound above.

## Results (2026-09-26, rebuilt `m40`)

1. **HDC5F5**, disposable copy of `wren2-synthetic-etf.chd`
   (`runs-archive/hdc5f5-timeout-20260926/`): the seek-ISR's `0x21a58a` returns
   725 CPU cycles after the `0xb0` write, and the read completes 4,147 cycles
   after it. `0xf6aa` is set to 1 before the completion clears it, and the
   wait exits normally. The formatter passes `ETF READ PHASE ...` and prints
   `FORMAT PHASE ...`. **The ETF timeout is fixed.** It then stops with
   `ERR.0001 *PGM HDC5F5 *TST 01 / HARDWARE FAILURE`,
   `FROM CYL: 919 TO CYL: 901`, after Seek, board `0x0e00`, Format `0x70`
   and Verify ID `0x80`. The CHD is unchanged. This format-phase failure is
   a separate, not-yet-analyzed issue. It is identical to the
   debugger-forced experiment above.
2. **ERMAP option 1** (`runs-archive/readtiming-regression-20260926/opt1/`,
   copy of `wren2-service-finalcheck.chd`): all cycles complete and it
   returns to `HIT "ENTER" TO GO BACK TO MENU`. The resulting CHD is
   byte-identical to `wren2-service-finalcheck.chd`.
3. **HDC5X3 option 2** (independent DCOS path; `.../opt2/`): no longer
   `TIME OUT`. It now reports `ERR.0001 *PGM HDC5X3 *TST 00` /
   `ERMAP ABSENT !!!`. That is consistent with the service track holding
   only option 1's test pattern, not a factory ERMAP. The CHD is unchanged.
4. **Standard 24** (`.../s24/`, blank 65,549-byte CHD from
   `standard24-nec-verify-20260925`): the resulting 77,824-byte CHD is
   byte-identical to the preserved
   `standard24-nec-physical-20260925/blank-wren2-65.chd`. The replay
   script's events after 85 s were shifted by +60 s, and an ENTER was added
   at 112 s, to match the current Diagnostic Monitor boot timing used by
   the ERMAP and formatter harnesses.

## Extension to WRITE DATA and VERIFY DATA (2026-09-26)

HDC5F5's WRITE & VERIFY DATA FIELD phase timed out in the same way. At
490.91 s the seek-complete handler (mode 3, write) set `0xf6aa` back to 1
after the nested completion of an instantaneous WRITE DATA (`0xf0`,
32 sectors) had already cleared it. The wait timed out at 496.96 s. The
device log showed the VI taken while `0xf0` was being issued (`0x21926e`),
before board command `0x1200`.

The same datasheet bound applies: the data field is written to (WRITE DATA,
printed pp. 6-24–6-25) or read from and compared (VERIFY DATA, p. 6-24)
the disk serially, at no more than 6 Mbit/s (p. 6-17). `EXECUTE_WRITE` now
waits `dtl() × 8` bits at 6 MHz before writing each buffered sector.
`EXECUTE_VERIFY` waits the same time before loading each sector for
comparison. Both use the same timer-parameter mechanism as `EXECUTE_READ`.

After this, WRITE DATA and VERIFY DATA completed on cylinder 907, heads
0–7. Head 8 then needed the GO363 head-select fix
(`re/evidence/go363-format-id-buffer-evidence.md`). With both, HDC5F5 formats the
disk completely. ERMAP option 1 and Standard 24 regressions are unchanged.
