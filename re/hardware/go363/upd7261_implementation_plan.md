# µPD7261AD in MAME — Implementation Plan

**Verdict up front:** do *not* fork another controller's source file. Write `upd7261.cpp` as a fresh
device, but steal three specific things from existing code: the **command-packet state machine
pattern** from `xt_hdc_device`, the **drive attachment and devcb wiring** from `pdc_device` /
`wd2010`, and the **bus/embedding wrappers** from `p1_hdc_device`. This is also how MAME devs
actually work — new chip devices are written fresh against the datasheet, with neighboring devices
open in another window as pattern references, because a forked file drags in decades of legacy
quirks that reviewers will reject in a PR.

Why not fork `xt_hdc` literally:

- Its own source calls its DMA implementation "an abomination ... a relic of the old crappy DMA
  implementation." That code predates modern devcb DMA and would be flagged in review.
- The XT HDC is a *board* (Xebec 1210 + SASI protocol), not a chip. The µPD7261 is a chip. The
  abstraction boundary is different: your device must expose chip pins (register selects, IRQ,
  DRQ, DACK), not board behavior.
- Status/command semantics differ enough that a fork becomes a rewrite with leftover dead code.

What each reference contributes:

| Reference | Take | Leave |
|---|---|---|
| `bus/isa/hdc.cpp` (xt_hdc) | Multi-byte command accumulation, timer-deferred execution, CHS unpack, sector-advance logic, PIO fallback | Old DMA style, ISA scaffolding, status bit layout |
| `machine/pdc.cpp` | `MFM_HD_CONNECTOR` drive options, devcb IRQ/DRQ wiring style | Z80-with-firmware modelling (7261 microcode is not dumpable; model behavior in C++) |
| `machine/wd2010.cpp` | Modern register-level HDC device structure, clean `read(offset)`/`write(offset)` interface, input-line devcbs (`in_drdy`, `in_tk000`, ...) | Task-file register model (7261 is packet-based, not task-file) |
| `bus/isa/p1_hdc.cpp` | Thin bus-card wrapper pattern | Nothing else — it's 139 lines |

---

## Phase 0 — Documentation and Ground Truth (do this before any code)

The single biggest project risk is that the register map and command encodings in circulation
(including in my earlier documents) are **reconstructed, not verified**. Every downstream decision
depends on the datasheet.

0.1. **Acquire and OCR the 35-page D7261AD datasheet.** Mirrors: datasheetq.com, datasheetbank.com
     (image-only pages). Download the PDF, OCR it, and transcribe into a reference file
     (`docs/upd7261_registers.md` in your working notes). Check bitsavers
     `components/nec/_dataSheets/` for a cleaner scan.
0.2. **Get the WESCON 1983 paper** ("The uPD7261 hard disk controller," Wescon Conf. Rec. vol. 27,
     pp. 5.2.1–5.2.5, NEC Electronics USA) — J-GLOBAL index 200902000200264012, likely via IEEE
     Xplore or ILL. Papers of this type usually include the command table and a host-interface
     timing diagram that the datasheet buries.
0.3. **Identify a real host system with dumpable firmware.** This is the *validation oracle*. A
     device with no software that exercises it cannot be tested and will not be accepted upstream
     as anything but skeleton. Candidates to research: NEC APC/APC-III Winchester option ROMs,
     NEC N5200 HDC, PC-98 early SASI/HDC boards, S-100 Winchester controllers. Find the ROM dump
     and disassemble the driver code — the firmware's register accesses are the authoritative
     spec of what the chip must do, and frequently reveal undocumented behavior the datasheet
     omits.
0.4. **Pin down the variant differences** (µPD7261A vs B — the datasheet covers both; they differ
     in supported drive interface types). Decide which variant your target system used, implement
     that one first, and structure the class so the sibling is a one-line subclass.

**Exit criteria for Phase 0:** verified register map, verified command opcode table with per-command
parameter byte counts, verified status/error bit definitions, and at least one host ROM that
drives the chip.

---

## Phase 1 — Skeleton Device (compilable, does nothing)

1.1. Create `src/devices/machine/upd7261.cpp` / `.h`:
     - `DEFINE_DEVICE_TYPE(UPD7261A, ...)`, `DEFINE_DEVICE_TYPE(UPD7261B, ...)` as subclasses of a
       common `upd7261_device`.
     - Host interface: `uint8_t read(offs_t offset)` / `void write(offs_t offset, uint8_t data)`
       plus an `address_map` helper `map()` — both, so drivers can use either style (wd2010 does
       exactly this).
     - Output devcbs: `irq_handler()`, `drq_handler()`.
     - DMA handshake methods: `dack_r()`, `dack_w()`, and a `tc_w(int)` terminal-count input if
       the datasheet shows a /TC-equivalent pin.
     - `save_item` every state variable from day one — retrofitting save states is painful.
1.2. Add to the build (`src/devices/machine` in `scripts/src/machine.lua` — note MAME uses
     GENie/lua scripts, not CMake).
1.3. Log every register access with `LOGMASKED` channels (`LOG_CMD`, `LOG_DATA`, `LOG_DMA`,
     `LOG_STATE`) from the start. When you run real firmware in Phase 5, this log *is* your
     debugging tool.

---

## Phase 2 — Command State Machine

Borrow the shape from xt_hdc, implemented cleanly:

2.1. **States:** `IDLE → CMD_RX (accumulating parameter bytes) → EXEC (timer-deferred) →
     XFER (DRQ active, data phase) → RESULT (status/IRQ posted) → IDLE`.
2.2. **First-byte dispatch table** mapping opcode → parameter count (verified in Phase 0). Commands
     with zero parameters execute immediately; others count down bytes like xt_hdc's `m_data_cnt`.
2.3. **Timer-deferred execution** (`timer_alloc` + `TIMER_CALLBACK_MEMBER`): never execute a
     command synchronously inside the register write. Real firmware polls BSY after issuing a
     command; if the command completes in zero time, polling loops that also check other flags can
     misbehave. Start with a fixed ~1 ms latency (xt_hdc uses this), refine to per-command
     realistic timing later (seek: buffered step timing per datasheet; read: rotational latency).
     Realistic timing is a *later* refinement — get correctness first.
2.4. Implement in this order (each one testable before the next):
     1. RESET / soft reset semantics
     2. Status register reads (BSY/CMD bits toggling correctly around a dummy command)
     3. SET PARAMETERS (pure state, no drive I/O)
     4. RESTORE + SEEK (updates internal cylinder, checks bounds, posts IRQ)
     5. READ SECTOR (data phase, PIO)
     6. WRITE SECTOR
     7. VERIFY, READ ECC, FORMAT TRACK, DIAGNOSTIC
2.5. **Error model:** implement the error/status codes the datasheet defines (not-ready, seek
     error, sector-not-found, ECC error, write fault). Firmware error paths are often the first
     thing that breaks on a new emulation; getting sector-not-found right matters as much as the
     happy path.

---

## Phase 3 — Data Path

3.1. **PIO first.** Data register read/write against an internal sector buffer
     (`std::unique_ptr<uint8_t[]>`, one sector; grow to multi-sector later). DRQ status bit set
     while the buffer has data (read) or space (write). This is testable from the MAME debugger
     with zero DMA infrastructure.
3.2. **DMA second.** Assert `m_drq_handler(1)` when a burst is ready; host DMA controller calls
     `dack_r()`/`dack_w()` per byte. Model it the modern way (like wd_fdc / upd765 do): DRQ is a
     level signal, DACK transfers one byte, TC or byte-count exhaustion ends the transfer and
     posts completion IRQ. Do *not* copy xt_hdc's `hdcdma_*` pointer juggling.
3.3. **Multi-sector transfers:** sector-advance logic (sector → head → cylinder rollover) — this
     part *is* worth lifting nearly verbatim from xt_hdc's `dack_r`, it's correct there.

---

## Phase 4 — Drive Backend

Two-stage approach:

4.1. **Stage 1: `harddisk_image_device` (CHD, LBA-level).** Compute
     `lba = (cyl * heads + head) * sectors_per_track + sector` from the geometry that SET
     PARAMETERS declared, and `read()`/`write()` whole sectors. This is what xt_hdc and the vast
     majority of MAME HDCs do. It is sufficient to boot operating systems and will satisfy 95% of
     use cases.
4.2. **Stage 2 (optional, later): `MFM_HD_CONNECTOR` (track-level, like pdc/hdc9224).** Only
     needed if (a) some guest software formats tracks with nonstandard interleave/sector sizes
     and reads them back expecting real track structure, or (b) you want the format command to be
     more than a no-op. Design the drive-access layer behind a small internal interface so stage 2
     can replace stage 1 without touching the command state machine.
4.3. Geometry sanity: reject/flag mismatches between the CHD metadata geometry and the guest's
     SET PARAMETERS values in the log — the classic "boots but corrupts" failure mode.

---

## Phase 5 — Host Integration and Validation Driver

5.1. Write (or extend) the machine driver for the Phase-0 host system. Wire:
     - registers into the address map (`.m(m_hdc, FUNC(upd7261_device::map))`, with `umask16`
       byte-lane care on 16-bit hosts),
     - IRQ → PIC or CPU input line (check polarity/inversion on the schematic),
     - DRQ → DMA channel, DACK callbacks → `dack_r`/`dack_w`,
     - two drive slots with a default CHD option.
5.2. **Validation ladder:**
     1. Host firmware POST passes its HDC presence/diagnostic check.
     2. Firmware can read sector 0 (boot attempt reaches the boot sector).
     3. Guest OS boots from CHD.
     4. Guest OS survives a write-heavy workload (copy files, verify, reboot, re-verify).
     5. Format utility runs (even if FORMAT TRACK is a stub that zeroes sectors, it must return
        plausible status).
5.3. Use the MAME debugger `wpset` on the HDC register range plus the LOGMASKED channels to
     diff firmware expectations against device behavior. Every divergence traces to either a
     datasheet misreading or an undocumented behavior — document both in the source header
     comment.

---

## Phase 6 — Upstreaming

6.1. MAME PR requirements to hit: BSD-3-Clause header, `copyright-holders:` line, datasheet and
     paper citations in the header comment, no dead code, save states working, and — critically —
     **a system in the tree that uses the device**. Chip devices with no consumer are usually
     rejected or parked.
6.2. Mark the driver `MACHINE_NOT_WORKING`/`MACHINE_IMPERFECT_*` honestly for whatever remains
     stubbed (e.g., ECC correction, format interleave).
6.3. Note in the header what is verified-against-firmware vs. inferred-from-datasheet vs.
     guessed — MAME source doubles as hardware documentation, and reviewers value that honesty.

---

## Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| Register map in circulation is wrong (reconstructed) | Rework of Phases 2–3 | Phase 0 gates all coding; firmware disassembly is the oracle |
| No dumpable host firmware found | Cannot validate; PR stalls | Choose target system *by ROM availability*, not by preference |
| A/B variant confusion (different drive interface types) | Wrong data-path assumptions | Implement the variant your target system used; subclass the other |
| Datasheet omits multi-byte command edge cases (abort mid-packet, command while BSY) | Firmware hangs | Log-and-compare against firmware behavior; xt_hdc's "ignore while busy" is a reasonable default |
| CHD geometry mismatch corrupts test images | Wasted debug time | Log mismatch loudly (Phase 4.3); keep golden CHDs read-only, work on copies |
| Timer granularity too coarse for firmware polling loops | Spurious timeouts in guest | Per-command timing tunable from one constants table |

---

## Effort Estimate

| Phase | Size |
|---|---|
| 0 — Documentation | The long pole; days to weeks depending on firmware hunt |
| 1 — Skeleton | Half a day |
| 2 — Command FSM | 2–3 days against a verified spec |
| 3 — Data path | 1–2 days (PIO), 1 day (DMA) |
| 4 — Drive backend stage 1 | 1 day |
| 5 — Host driver + validation | Dominated by firmware debugging; 1–2 weeks realistic |
| 6 — Upstreaming | A review cycle or two |

The code is the small part. The datasheet transcription and the firmware-driven debugging in
Phase 5 are where the project actually lives — which is exactly why starting from a verified
spec (Phase 0) rather than from another controller's source is the right call.
