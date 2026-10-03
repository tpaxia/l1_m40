# GO363 behavior recovered from DCOS

## Sources and scope

The contemporary *L1 Functional Checks Manual*, sections 17.5 and 17.8,
identifies HDC505 and S24W25 as GO363/XU1709 diagnostics and describes their
interrupt, controller, DMA, and Standard 24 tests. The original diagnostic
programs are on `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1
dcos 8.4/G.IMD`. The Disk G catalogue locates `006.HDC505` at flat image
offset `0x7e300` and `009.S24W25` at `0xa8900`. The shared HDC5 runtime is
loaded into DCOS segment `0x21`; the addresses below are observed CPU
addresses in `runs-archive/standard24.DNBqWL/s24w25-pu.trace`, not file offsets.

The NEC *uPD7261A/B Hard Disk Controller* manual applies only to the
controller chip. Its DMA timing and multisection operation are discussed in
`re/evidence/UPD7261_DREQ_EVIDENCE.md`. The GO363 host register meanings below come from
DCOS, not the NEC manual.

## Register names and scope

HDC505 writes words to GO363 `0x48/0x49` and `0x4c/0x4d` during its tests.
S24W25 uses those same ports in its ordinary read and format sequence:
`21594C`–`21595A` supplies a controller request and issues `0x1100`, and
`21504C`–`21505C` supplies three words and issues `0x0e00`. The GO363
implementation's `m_diagnostic_*` names therefore incorrectly suggest a
diagnostic-only hardware path. These are the board's data, command, FIFO,
pending, VI-enable, and VI-request states. Rename them to board/interface
terms without changing the observed protocol. Command-specific handling is
hardware opcode decoding, not a branch on whether DCOS is running a test.

## Board interrupt status and VI acknowledgement

- At `2158B2`, DCOS reads the GO363 word at `0x4a/0x4b` and tests bit 3
  before issuing a board command. At `215998`, it reads the same status and
  compares masked result with `0x28` after completion.
- HDC505 test 2 generates a pending interrupt with command `0x0b00`, polls
  `0x4b` bit 5, enables VI with `PROINT`, and tests the vectored interrupt.
  Its handler writes `xx02` to `0x48/0x49` to acknowledge VI; the test still
  expects the board pending indication afterward. The instruction-level
  sequence and observed checks are in `re/hardware/go363/GO363_HDC5_diagnostics.md`,
  “HDC505 tests 1 and 2”.
- S24W25's controller initialization uses the same HDC5 status helper after
  the uPD7261 `SPECIFY` command. Under the old emulator behavior, VI
  acknowledgement cleared `m_hdc_interrupt`, so the post-acknowledge pending
  read failed and test 0 reported controller initialization error.

**Inference:** GO363's pending source and asserted VI request are distinct
states. VI acknowledge drops the VI request without clearing the controller
pending indication. This is checked by both HDC505's interrupt test and the
S24W25 initialization path. The implementation uses separate pending/VI
latches and lets the uPD7261 line clear the pending source.

## Unit status word

The common HDC5 routine in the S24W25 trace executes:

```text
2158D0  select register 0x40
2158D2  write selected physical unit
2158D4  select register 0x48
2158D8  write command data
2158DA  select register 0x42
2158DC  read word from 0x42/0x43
2158E8  test bit 0 of status word
2158FA  test bit 4
215902  test bit 5
21590C  test bit 2
```

Those tests occur inside HDC5's common physical-unit status helper. For
physical unit 0, the diagnostic proceeds when the low status byte has bits
0, 2, and 4 set and bit 5 clear. For physical unit 1, the corresponding bits
are shifted one position. The direct meaning of each bit remains an
inference; the observable DCOS acceptance pattern is exact. The old emulator
always returned zero for `0x42/0x43`, which cannot pass a present unit.

**Implementation hypothesis:** return low-byte `0x15` for an attached unit
0, `0x2a` for unit 1, and zero for an unattached unit. The disposable-image
S24W25 test is the independent check: it must pass test 0 with a mounted
WREN2 unit and must not report a present unit when the drive is absent.

## DMA address and controller data phase

After controller initialization passed, a fresh disposable WREN2 run reached
the S24W25 formatting phase, then timed out on its first read operation. The
GO363 log shows the DCOS instruction sequence at `215928`–`215946`:

```text
21592E  srll rr8,#1       ; system byte address -> board word address
215932  select 0x57; write 0xb0 to configure timer channel 2
215938  select 0x56; write transfer count bytes
21593E  select 0x42
215940  out @r2,r9        ; word-address low half to 0x42/0x43
215942  select 0x44
215944  out @r2,r8        ; word-address high half to 0x44/0x45
```

In this run the two words were `0x99fc` and `0x0003`, yielding board word
address `0x000399fc` and system byte address `0x000733f8`. At
`21594C`–`21595A`, DCOS writes a six-byte request through port `0x01`, issues
uPD7261 command `0xb0` through `0x11`, and starts board command `0x1100`
through `0x4c/0x4d`. The NEC datasheet, Table 2, printed page 6-15 (PDF
page 13), identifies `1011X` as Read Data and `1111X` as Write Data. Its
Read/Write Data descriptions on printed pages 6-23–6-25 specify DMA data
transfer. HDC505 tests 4–5, per the Olivetti manual, exercise DMA logic and
board RAM addressing. The GO363 service manual identifies 8 KB RAM on the
board.

**Implementation hypothesis:** on uPD7261 DREQ for Read Data, move the
sector bytes from the chip data port to system memory beginning at the
programmed word address times two; for Write Data, reverse the direction.
Advance the system address across sector requests. A timer callback services
DREQ after the uPD7261 callback returns so its state timer can advance after
each sector. This is a functional abstraction of the documented board RAM
and DMA paths; exact gate-array buffering/timing remains unknown. The
disposable S24W25 run must complete the read phase without timeout and the
CHD must be inspected for the documented Standard 24 sectors.

## Board timer scope after the read phase

The fresh run with DMA service transferred all 16 sectors and returned NEC
completion status `0x40`. DCOS then acknowledged/cleared the HDC, used board
commands `0x2400` and `0x1100`, and asked for two operator confirmations.
After `451` was entered, it failed with `HARDWARE FAILURE`. A trace of that
path shows `215020` preparing command `0x0e00`, followed by the pre-command
check at `2158B2`–`2158BA`. The check sees GO363 status bit 3 set and returns
error `0x12` before issuing the command. The emulator log shows why status
was set: `timer done command=1100 vi=0` after the completed read, and the
current model sets `m_timer_interrupt` for every 8253 expiry. This left status
`0x28` even though the active board command was `0x1100`.

HDC505 test 4 is the independent DCOS use of the board timer. Per the
Olivetti manual it tests the 8253 and DMA transfer logic; its observed
`HDC5P_CONTIMER` setup issues command `0x4100` for polled timing and
`0x4000` for the long interrupt case (see
`re/hardware/go363/GO363_HDC5_diagnostics.md`, “Test 4”). Its `PRIN0` timer completion
checks apply to those commands. S24W25 does not issue either timer-test
command while reading the track.

**Implementation hypothesis:** let the 8253 count run, but publish its
expiry as GO363 `PRIN0` only while board command `0x4000` or `0x4100` is
active. In ordinary disk commands the timer is a watchdog, not a successful
controller completion. Validate by rerunning S24W25 past the `0x0e00`
pre-command check and confirming HDC505 test 4 still observes timer `PRIN0`.

## Format setup command `0x0e00`

After the timer-scope correction, S24W25 passes the pre-command check and
issues `0x0e00` through `0x4c/0x4d`, but then times out. The DCOS trace at
`runs-archive/standard24-dcos-formatcmd-20260925/format-failure.trace` shows:

```text
215020  load board command 0x0e00
215030  copy requested address
21504A  program timer and DMA address at 0x56, 0x42, 0x44
21504C  write three parameter words through 0x48/0x49
21505C  issue board command through 0x4c/0x4d
2173AE  call wait/timeout helper 2161BE
2161BE  install a UC timer and poll for controller completion
```

No uPD7261 `FORMAT` command is sent on port `0x11` in this sequence. The NEC
datasheet command table gives `0111` for chip-level Format (printed page
6-15), while this is a GO363 board command. The Olivetti Functional Checks
manual says S24W25 option 1 formats track 0, and HDC505 test 9 also checks
the board's format/read logic. The GO363 board lacks a CPU, so this command
must be handled by its interface logic. The exact hardware formatting
waveform is unavailable; the requested emulation treats formatting as a
no-op.

An immediate pending/VI completion was tested and **rejected**. It produced
repeated VI acknowledgements at PC `80FF03`, left S24W25 in formatting, and
wrote no CHD hunks. That edit was reverted. The trace shows the installer
calls the wait/timeout helper *after* issuing `0x0e00`; the helper installs
its timeout vector and enables VI. An immediate callback is therefore too
early for this DCOS path.

**Next implementation hypothesis:** keep the format operation itself a no-op,
but deliver board completion after DCOS has installed its wait handler. A
short scheduled callback is a timing inference, not a measured GO363 delay.
The callback must set the ordinary board pending status and one VI request,
and VI acknowledgement must end that request. Test first with a short
disposable run to check that S24W25 leaves formatting without an interrupt
storm, then inspect later commands and any CHD writes.

A delayed callback using the board's one-shot VI latch passed that first
check. DCOS acknowledged vector `0x30` once, read status `0x28`, then issued
its post-operation cleanup at `215A3A`–`215A58`: auxiliary writes `0x08` and
`0x02` to the NEC, parameter words `0x000c`, `0x0018`, `0x0003` through
`0x48/0x49`, and board command `0x2100` through `0x4c/0x4d`. The next
pre-command read at `2158B2` still saw `0x28` in the emulator and returned
error `0x12` (busy). The screen reported `HARDWARE FAILURE`.

**Cleanup inference:** for this DCOS format path, `0x2100` clears the GO363
board-completion pending latch after the result has been read. The IRQ was
already acknowledged, so clearing pending must not generate another VI.
This is distinct from HDC505 test 2, which checks that pending persists
*between* VI acknowledgement and its explicit cleanup. A short rerun should
show `0x4b` clear before the next command.

The disposable rerun at `runs-archive/standard24-dcos-clear-20260925/` did show
the next pre-command status read at `2158B6` return zero after `0x2100`.
S24W25 then issued board command `0x1400` at `215960`, but the current model
gave no completion; the screen reported `TIME OUT DURING I/O OPERATION` and
`HARDWARE FAILURE`. This confirms progress beyond the earlier pending-status
failure, but does not establish the full semantics of `0x2100` or `0x1400`.
The delayed `0x0e00` completion and `0x2100` clearing remain provisional
board-protocol hypotheses; neither timing nor all side effects are known.

## `0x1400` wait and the NEC Format command

The same run's register log shows DCOS writing five bytes through `0x01`,
then `0x70` through NEC command port `0x11` at `21595C`, and finally GO363
command `0x1400` through `0x4c/0x4d` at `215960`. The instruction trace
`runs-archive/standard24-dcos-clear-20260925/s24w25-pu.trace` shows the preceding
parameter assembly and the wait that later times out. NEC's command table
identifies `0111S` as Format. The board command follows a chip operation;
the current MAME uPD7261 `case 0x7` merely logs `format (not emulated)` and
does not start a result or completion. This is a chip-level missing command,
not evidence that `0x1400` needs a synthetic board completion.

The NEC manual, printed page 6-22 (PDF page 20), gives the Format command
parameters and the two result bytes `EST` and `SCNT`; it says the operation
terminates normally once sector count reaches zero and the second index pulse
has occurred. Printed page 6-16 (PDF page 14), Table 3, defines normal
completion as `CEH=1`, `CEL=0`, and controller busy clear. For this emulation,
the user requested a media-format no-op: completing the NEC command with
zero remaining sectors and the documented result/status/interrupt sequence
models that no-op without writing a track. The physical index delay is not
yet modeled. This inference can be checked against the independent DCOS
HDC505 format/read test and S24W25's next result/status checks.

The fresh disposable run `runs-archive/standard24-nec-format-20260925/` passed
the previous timeout and displayed `CERTIFYING PHASE`. The next log sequence
at `215952`–`215960` sends the six-byte sector request to NEC port `0x01`,
issues NEC `0xe0` (Verify Data) at `0x11`, then GO363 `0x1300` at `0x4c/0x4d`.
The NEC emulator's `case 0xe` likewise only logs “not emulated”, and DCOS
times out. This is another chip command missing its documented data phase,
not evidence for a special `0x1300` board completion.

NEC manual printed pages 6-24–6-25 (PDF pages 22–23), “Verify Data”, specify
the same six request bytes and seven result bytes as Read/Write Data. The
controller reads disk data and compares it with host memory transferred by
DMA, updates sector count/location, and ends normally at zero count. A
mismatch sets the status register's NCI bit and ends abnormally. An emulation
should therefore request DMA for each sector, compare the host bytes with
the disk sector, update location/count, and return the documented result and
interrupt. This can be checked by S24W25's certify pass after its track write.

The first Verify Data run stopped before DMA with `EST=0x04` (no data): DCOS
sent request bytes `00 10 00 00 00 20` for the track-0 operation, and the
existing uPD7261 model used logical cylinder `0x1000` directly as the CHD
physical cylinder. The earlier Write Data run issued the same location and
logged 32 DMA sectors, but the disposable CHD remained 65,549 bytes with no
allocated data hunks. The model did not check the return from `hid.write`, so
the apparent write success was false.

The NEC manual explicitly distinguishes `PHN` (physical head) from `LCNH`/
`LCNL` (logical cylinder ID) in Table 2, printed page 6-15 (PDF page 13),
and says Read Data selects a sector by its logical ID on printed page 6-23
(PDF page 21). The physical cylinder is established by Seek/Recalibrate;
printed pages 6-20–6-21 (PDF pages 18–19) describe the controller's `PCN`
and step pulses. DCOS is formatting physical track 0 while placing logical
ID `0x1000` in the sector request. A CHD has no separate ID fields, so the
functional abstraction must use the controller's current physical cylinder
`m_pcn[unit]` for the CHD LBA and preserve `LCN` for result/status fields.
Apply this consistently to Read, Write, and Verify Data. A fresh run must
then allocate CHD hunks and pass the first Verify Data operation.
The same evidence requires checking CHD read/write return values: a failed
sector access must not be reported as normal command completion. The NEC
manual's Read Data item 9 on printed page 6-23 (PDF page 21) assigns `ND`
(no data) and abnormal termination when the sector cannot be found.

The final fresh run `runs-archive/standard24-nec-physical-20260925/` completed
S24W25 option 1 with zero errors. The screen says `STANDARD 24 RECORDED`
and `FIRST USER SECTOR ON TRACK ZERO IS 17`. The disposable CHD grew from
65,549 to 77,824 bytes. `chdman extractraw` showed nonzero data in track-0
sectors 7–12 and 15; sector 15 begins with `UNITDESCWREN2` and contains the
`0x038b` last-cylinder and `0x0008` last-head fields. Sectors 7 and 10,
8 and 11, and 9 and 12 contain matching copies. Sectors 13–14 remain zero
in this successful installer run. The original Disk G and any earlier hard
disk images were not modified.

This confirms the functional path for DCOS Standard 24, including Format
completion, Write Data, Verify Data, and physical-cylinder CHD access. It
does not prove the precise GO363 `0x0e00` completion delay or all side effects
of board command `0x2100`; those board-command behaviors remain provisional.
The NEC Format implementation deliberately leaves the physical track format
unchanged, as requested. The CHD abstraction does not preserve per-sector
logical ID fields independently of sector data.

An independent readback run selected S24W25 option 2 on a **copy** of the
installed CHD (`runs-archive/standard24-option2-20260925/`). DCOS reported
`SECTOR 15 OF STD 24 REPLACED` with zero errors. Its extracted first track
was byte-identical to the option-1 output; the relative data did not need to
change. This confirms that the installer recognizes and reads the recorded
Standard 24 structure through the emulator. It does not independently
exercise the provisional format command `0x0e00`, which option 2 skips.
