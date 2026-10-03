# UC3003 (008, disk A) — S3000 UC central-unit test: analysis & emulator fixes

`UC3003` = "S3000 UC((UC036/UC051)NO GATE ARRAY)TEST". Parameters: UC TYPE (0=UC036,
1=UC051), ROM SIZE (0=4K8, 1=8K8), DIAG LOOP (ACIA loopback plug). 8 subtests:
TRAP, VIENO, TIMER, ACIA, NVI, VI, ROM, EAROM(skipped). Loaded in **seg 0x21**
(disasm: `re/disassembly/diagnostics/runtime/seg21_uc3003_loaded.dis`); monitor services in seg 02/03/04
(`seg02_diskA_monitor_52xx.dis`, `seg04_diskA_monitor_*.dis`).

## Ground-truth discoveries (from the test code)

### ENTER vs SKIP are two different scancodes
Monitor classifier (disk-A `seg03:0x1bf2`): raw scancode **`0x61` = ENTER** (go-on
flag 1), **`0x52` = SKIP** (flag 2). Both terminate line input (why boot/menus worked
with 0x52) but go/skip prompts distinguish them. The emulator's PC-Enter sent 0x52 →
UC3003's "HIT ENTER TO GO ON / SKIP TO GO BACK" silently skipped back to the menu with
**zero output** — the original "tests never run" mystery. *Fix: PC-Enter → 0x61;
PC-numpad-Enter → 0x52 (SKIP).*

### TRAP REQUEST TEST = Z8010 MMU violation semantics (TST 01)
Installs a handler at PSA+0x20 (segment trap), then provokes violations one at a time
on segment `[0x3241]`(=0x22) and validates the MMU status registers (special-I/O reads
`0xNNfc`, N=reg): reg02=VTR, 03=viol seg, 04=viol off-hi, 05=**Bus Cycle Status**,
06/07=**instruction seg/off-hi**. Sub-cases and expected VTR:

| # | descriptor attr | access | expected VTR | expected BCS |
|---|---|---|---|---|
| 1 | 0x01 read-only | system write | 0x01 | **0x08** |
| 2 | 0x02 system-only | **normal-mode** write | 0x02 | **0x28** |
| 3 | none, offset 0x0AAA > limit | write | **0x04 = length viol** | 0x08 |
| 4 | 0x04 cpu-inhibit | write | **0x08** | 0x08 |
| 5 | 0x08 execute-only | data write | **0x10** | 0x08 |
| 6 | 0x20 stack/DIRW, off=limit | write | PWW (flag bit5) | — |
| 7+ | repeat w/o clearing VTR | write | FATL accumulation | — |

**VTR bit order (verified): 01=RDV, 02=SYSV, 04=SLV, 08=CPUIV, 10=EXCV**, 20=PWW,
40=SWW, 80=FATL. Attribute bits ≠ VTR bits (SLV has no attribute).
**BCS latches the pin levels: N/S̄ LOW=system, R/W̄ LOW=write** → system write =
`0x08` (ST_REQ_DATA), normal write = `0x28`. The violation register set (VTR, seg,
off, BCS, instr) **freezes on violation until VTR is cleared (reg 0x11 write)**.

### VIENO SIGNAL TEST (TST 02) — arbiter bit decoded
`0xFF81` **bit 3 = VIENO flip-flop**: expect 0 at entry → write `0xFF8C` → expect 1 →
write `0xFF84` → expect 0. Reconciled with the UCY805 arbiter test (0x0F after
8D/8E/8F+acks, 0xF8 with grants): **bit3 = VIENO-FF OR any-grant; VIENO set by any
0xFF8C-8F write, cleared by any 0xFF84-87 write; bits 0-2 = idle marker (0x07),
cleared while any grant active.**

### TIMER TEST (TST 03)
Counter 0: polled via `0xFFC1` (passes). Counter 1: **expects an interrupt from 8253
channel 1** — "COUNTER 1 INTERRUPT FAULTING" = the ch1-out → UC interrupt path is not
modeled. (Body at seg21:0x3a40+; not yet fully decoded.)

## Emulator fixes applied (verified by rerunning UC3003)

1. **m40.cpp:** wire `m_mmu->out_segt_cb()` → Z8001 `SEGT_LINE`; bind `segtack()` →
   `m_mmu->segtack_r()` (both existed unbound — no violation could ever trap).
2. **m40.cpp:** PC-Enter scancode 0x52→**0x61**; numpad-Enter = SKIP (0x52).
3. **z8010.cpp:** BCS **pin polarity** (N/S̄, R/W̄ active-low) — was reading 0x38 for a
   system write, test wants 0x08.
4. **z8010.cpp:** **freeze BCS** while a violation is latched (until VTR clear).
5. **z8010.cpp/h:** VTR bit order fixed (SLV=0x04, CPUIV=0x08, EXCV=0x10) + explicit
   attr→VTR mapping (was `viol &= attr`, assuming 1:1).
6. **z8010:** latch **instruction seg/off** on violation (`translate()` gained an
   `iaddr` param; m40 passes the PC).
7. **m40.cpp:** pass the CPU's real **N/S̄ state** (FCW bit 14) to translate() instead
   of hardcoded system (validated by sub-case 2).
8. **m40.cpp:** arbiter `0xFF81` low nibble remodeled per VIENO (item above); UCY805
   power-on/boot still pass.

**Result:** TST01 sub-cases 1-6 pass; TST02 VIENO passes; TST03 counter 0 passes.

## Additional fixes (second round, all verified)

9. **FATL semantics** (z8010): a violation while one is latched records **only FATL**
   — the new violation's type bits are NOT accumulated (TST01 checks SYSV flag clear,
   FATL flag set on the double-violation).
10. **Suppression gate** (m40): reading UC reg **`0xFF00` disables** the
    MMU-violation write suppression (the violating write reaches memory); reading
    `0xFFA0` restores it ("DISABLE INHIBITION MEMORY" sub-case).
11. **Timer VI** (m40): decoded TST03 counter-1 (seg21:0x3a5c): the vector is written
    to UC reg **`0xFF01`**, and **8253 ch1 OUT raises a VI gated by the VIENO
    flip-flop** (hence the name: VI-ENable). Wired `out_handler<1>` → VI level, ack
    returns the 0xFF01 vector (lowest priority on the shared line).

## Scorecard (current)

| test | result |
|---|---|
| 1 TRAP REQUEST | ✅ all sub-cases |
| 2 VIENO SIGNAL | ✅ |
| 3 TIMER (counters 0/1/2) | ✅ |
| 4 ACIA | ❌ — the UC's **EF68B50P (6850) is not modeled**; polling + TX-int sub-tests fail |
| 5/6 INT NOT-VECTORED / VECTORED | not yet reached past the ACIA errors |
| 7 ROM | ✅ (observed passing in an earlier run) |
| 8 EAROM | skipped by the test itself |

## ACIA — ports confirmed, integration design (attempt 1 reverted)

Test-4 bodies (via seg21:0x04a0 → 0x0b18 → sub-tests): the **polling-sequence test
(0x3c62) writes control to `0xFF20` and data to `0xFF22`** — the ACIA IS at
0xFF20/22. The "self-diagnostic signal" sub-test (0x3b7c) instead exercises the
**0xFF60-6F diagnostic-indicator latches** (write 61/62/64/68/69/6a, read back 60)
plus one 0xFF20 status read.

Attempt 1 (plain acia6850 swap) broke the machine because **the keyboard feeds the
ACIA's RX**: the resident keyboard ISR reads scancodes from the ACIA data register
(0xFF22). Correct integration:
1. `acia6850` at 0xFF20/22 (status/control, data).
2. Keyboard scancodes → serialize into the ACIA RX (e.g. push bytes via a small
   fifo → `write_rxd` bit timing, or set the received-data register directly).
3. TX → RX loopback for the test plug path (and check what TXD really drives —
   possibly the keyboard's serial input).
4. ACIA IRQ → shared VI (vector: check whether test 4 writes 0xFF01 or another
   latch before enabling interrupts).
5. Reconcile the resident ISR's status-bit usage (re-verify the "bit 2" claim
   against a real 6850: RDRF=bit0, TDRE=bit1, /DCD=bit2).
6. The 0xFF60-6F readback loop must return the last written indicator value
   (currently likely write-only) for the self-diagnostic sub-test.
Then re-run UC3003 tests 4-6 (NVI/VI tests follow the ACIA in sequence).

## FINAL RESULT: UC3003 passes with ZERO errors (all 8 tests, EAROM skipped by design)

The last three defects, each decoded from the test code:
1. **SUP-dispatch corruption (the real cause of every post-SUP "flaky" run):** the
   SUP-scope suppression window (violating pc) stayed live through the segment-trap
   dispatch — the PSA vector fetch and trap-frame pushes still execute with
   pc == the violating instruction, so they were eaten → PC loaded garbage → NMI →
   the diagnostic's fatal catcher (seg21:0x1718 installs PRIV/SEGT/NMI catchers at
   PSA+0x14/0x24/0x2c that print `*** ... ***` and spin at 0x1772 `jr $`). The
   "index polling at 0x1772" was the driver's index logger timestamping a dead CPU.
   Fix: clear the suppression window in segtack_r()/nmiack_r() — the acknowledge
   ends the violating instruction, exactly where the real SUP releases.
2. **Timer VI was level-held** → edge-latched on ch1-OUT rise, cleared by the ack.
3. **The ACIA VI has its OWN vector latch: `0xFFA0` (write side)** — test 6 phase 2
   (`seg21:0x497a: outb #0xffa0,rl4`) loops vectors through it; `0xFF01` is the
   timer's. vi_ack now serves m_timer_vector for the timer cause and m_acia_vector
   for the 6850 IRQ. (0xFFA0 read side remains config/jumpers + suppress re-enable.)

**UC vector architecture (final):** shared Z8001 VI line; per-source vector latches —
FDU governo reg 0xAA, KDC/FE via its vector reg, UC timer 0xFF01 (VIENO-gated,
edge), UC ACIA 0xFFA0 (6850 IRQ, self-clearing). Priority: FDU/KDC > timer > ACIA.

## (superseded) Session diagnosis notes: shared-VI level-source storms

UC3003 runs are **timing-luck sensitive on the committed HEAD**: sometimes green,
sometimes stuck at the TRAP banner ending in NMI. PC probes + fdu.log show the CPU
trapped in an interrupt re-entry loop at seg21:0x1772 (an index-poll routine reached
via the VI vector) between the trap test's MMU setup writes. Two synthetic **level**
VI sources cause it when UC3003 has re-pointed the VI table:
1. timer: ch1-OUT && VIENO held → storm (edge-latch fix written, uncommitted:
   latch on OUT rising edge, clear when the ack serves 0xFF01) — necessary but not
   sufficient;
2. **KDC TX (ctrl bit5) level**: the gate-ENTER echo sequence (LED bytes 0D/04/05/06)
   raises TX VIs; if the diag's VI table receives them, the clearing ISR never runs,
   bit5 stays set → VI held → re-entry storm at whatever the vector points to.

Green runs = the echo drained before the test started (keystroke timing).
**Proper fix = the real-ACIA integration** (TDRE/TIE + true vector routing) instead
of the synthetic bit5-level heuristic. WIP state: `git stash` "combined ACIA +
foreign 4-drive WIP" + `/tmp/m40_combined_wip.patch` (NOTE: contains interleaved
FOREIGN changes — 4-drive floppy + FDC ST0_ABRT irq — from the parallel workstream;
separate before applying). The ACIA hybrid booted both disks; its remaining blocker
was this same storm plus the undecoded ACIA VI vector source.

## Note: UC3003 targets UC036/UC051 (no gate array)
Our machine is a UC042 (MB15652 gate array). UC3003 still runs (the tested facilities
overlap), but **UCY805** (dated 880222) is the arbiter/gate-array-era UC test. The
UC-type-specific expectations (e.g. EAROM skip) come from the UC TYPE parameter.

---

# UCV305 (010, disk A) — S.3000 V/SV UC test: PASSES (M40-applicable subtests)

Parameters: UC TYPE (0=3000V/1=3000SV — SV is the cache variant), ROM SIZE
(0=16K8/1=32K8 → 0 for the 27128 pair), IS THERE EAROM (0), EAROM TYPE, +extra
yes/no prompts. Disasm: `re/disassembly/diagnostics/runtime/seg21_ucv305_loaded.dis`.

Result with UC TYPE=0, ROM=16K8, EAROM=NO: **every M40-applicable subtest passes** —
TRAP, MASTO & VIENO, TIMER (counters 0/1/2), MMU1*, (5), ACIA ×4 interrupt modes,
NVI, VI, ROM; DIP-SWITCHES and RESET self-skip with warnings. The single counted
"error" is **test 4 "MMU1 TEST: M.44" self-skipping** ("TEST SKIPPED (PHYS. RAM
ADDRESS OUT)") — it targets the M44/UC048 memory window and skips on an M40
regardless of RAM size (verified at 448K and 1024K).

## New UC hardware decoded from UCV305 (and wired in m40.cpp)

- **MASTO flip-flop** (test 2, seg21:0x5b16): master/slave master-out signal.
  **SET by writing `0xFF19`, CLEARED by writing `0xFF11`, read back at `0xFFB1`
  bit 6.** Reset state = 1 (master). Was "MASTO STUCK AT 1" while 0xFFB1 was
  unmapped (0xFF reads).
- **8253 ch1 OUT latch = `0xFF41` bit 4** (test 3, ISR at seg21:0x5c20 captures
  0xFF41 at interrupt time; check at 0x5cba expects bit 4 set): the UC latches the
  counter-1 output level readably. Was "LATCH OUTPUT CNT1 FAULT".

---

# Test-sweep session 2: MEM813 PASSES; RAMVID hang under investigation

- **MEM813 (A-014)**: interactive memory workbench (menu; 8=go-to-test). Auto-detects
  the RAM block %00020000-%0005FFFF; warns "block 1: on monitor address space"
  (answer 0=GO ON). **END CYCLE 00001 ERR 00000 — memory pattern suite passes.**
- **RAMVID (B-010)**: "*TEST RAM-VIDEO BY MARCH*". Prints the static banner
  "MARCH BANK 1B0000 1B0FFF" then never completes cycle 1 (2500 emulated s), no
  errors, not a keyboard wait (ENTER pacing didn't help). Established facts
  (disasm `re/disassembly/diagnostics/runtime/seg20_ramvid_loaded.dis` and `seg21_ramvid_loaded.dis`; code in **seg 0x21**,
  strings/descriptor in seg 0x20):
  - Marches logical **<<0x1B>>0x0000-0x0FFF** (one 4KB bank = the real board's
    2×TMM2016); seg 0x1B verified mapped to the VRAM (dump shows 00/20 cell pairs).
  - Window adjusted by monitor config bytes `<<4>>0x0178/0x0179` (video type);
    with type 0 the adjustment is neutral.
  - Primitives: fill 0x02b4, converging two-pointer march 0x02ce/0x031c (bounded,
    parity-correct), inter-pass delay 0x029c (~0.6 s), mismatch path 0x0366-0x03c0
    (prints expected/actual/XOR via monitor svc <<4>>0x0024 — never printed).
  - **Next step:** add RAMVID PC probes (0x2102b4/0x2102da/0x21031c/0x210366 and
    the caller 0x21018c) to the M40_DEBUG_TRACE switch and rerun to see where it
    actually spins; suspects: a verify against the CRTC-side (reg 0x81 live-bit
    toggling mid-march?), or the config-adjust producing a >4KB window in this
    monitor's variables.

## RAMVID hang — root-cause chain (session 3)

PC probes + `-log` (246 MB) nailed it:
1. March fill/verify: **first verify miscompares at cell 0** (`rv-mismatch-a`,
   rr2=<<0x1B>>0x0000, expected 0x00) → error-print path entered (`rv-errprint`).
2. Control then ends up at **`<<1>>0x0137` executing DATA**: the log shows
   **`Z8000 invalid opcode 810137: 0dfc` ×5.4 million** — an infinite loop because
   MAME's Z8000 core logs invalid opcodes and continues as NOP instead of taking
   the **unimplemented/extended-instruction trap** through the PSA (which is how
   the real CPU + monitor would recover/report).

Open questions, in order:
- Why the cell-0 miscompare: what does the read of <<0x1B>>0x0000 return vs the
  0x00 fill? (Alias test of phys 0xF00000→VRAM broke boot — RAM sizing then sees
  the window respond — so the second-window model needs decode-side care; seg
  0x1B's actual descriptor base is still unconfirmed: the z8010 VERBOSE log lines
  did NOT appear in error.log — check why logmacro output is missing before
  relying on it.)
- Why the error-print path lands in <<1>>0x0137 (stack/service-context corruption
  after the mismatch handler? needs the 0x038a→<<4>>0x0024 service trace).
- Core gap regardless: implement the Z8001 unimplemented-instruction trap
  (PSA entry at +0x08) instead of nop-continue — any wild jump then recovers
  through the monitor instead of hanging silently.

### Unimplemented-instruction trap experiment: DISPROVEN, reverted
Routing invalid opcodes to the EPU/PSA trap made things worse: the L1 monitors
install handlers only for PRIV/SEGT/NMI (PSA+0x14/24/2c) — the EPU slot holds
banner text — so the trap recursed into text and killed the machine entirely
(not even the KDC idle loop ran). Also 0x0DFC is a hole in the 0x0D group, not an
EPA-group opcode; real silicon does not fire the extended-instruction trap for it.
Core reverted to log-and-continue. The real RAMVID bug remains **layer 1: the
cell-0 miscompare on <<0x1B>>** (fix that and the error path/wild jump never runs).

## RAMVID — RESOLVED: MAME Z8000 core bug in COMB @Rd

`Z0C_ddN0_0000` (COMB @Rd) used `GET_DST(OP0,NIB3)` — the sub-opcode nibble
(always 0) — instead of NIB2, so `comb @rr2` complemented the byte addressed by
**RR0** (garbage): the march's complement never landed in VRAM (→ cell-0
"mismatch") and random memory was corrupted (→ the wild execution at <<1>>0x0137).
Every sibling 0x0C/0x0D handler uses NIB2; this was the lone typo, exposed by the
first program to ever execute COMB @Rd (a march test complements in place).
Fix: one nibble. **RAMVID now: END CYCLE 00001 ERR 00000.**

---

# 6030T6 (D-007) — GO280 FDU running test: status & handoff

Driving notes: the monitor GO "4" leaks into the slot prompt → TEMP slot-4 FDU
alias in io_map (do not commit); **pu=1** selects the loaded drive.

| test | result |
|---|---|
| 1 CONTROLLER COMMUNICATION | ✅ |
| 2 TIMER | ✅ |
| 3 INTERRUPT | ✅ |
| 4 DMA | ❌ "DMA CONTROLLER ERROR" |
| 5 COMPATIBILITY | ✅ |
| 6 SPEED MEASUREMENT | ❌ "INDEX PULSES NOT RECEIVED" (2% window) |
| 7 SEEK | ❌ "FDC CHARACTER EXCHANGE ERROR" |
| 8 FORMAT / 9 READ | ❌ (follow-on: "POSITIONING ERROR") |

**Test 4 root cause identified** (disasm `re/disassembly/diagnostics/runtime/seg21_6030t6_dmatest.dis`,
loop at seg21:0x8b30): the test programs the GO280's LOCAL 8253 (regs 0x98/0x99,
count 0x2710) and the DMA (reg 0x50←0x20), strobes reg 0xFF, then expects the
governo to have **DMA'd a value into system RAM at rr4** — compared against
0x01E0 / 0x00E0 (timer-sourced diagnostic DMA transfer). Our model never runs a
DMA in this mode (trace: dma_byte stays 0). Missing behavior: the GO280's
timer/diagnostic DMA source. Decode next: helper 0x8bbe (completion poll via
regs 0xFF/0xED), reg 0xEF's role, and which channel/mode reg 0x50←0x20 selects.
Test 6 needs index pulses countable via the same local-timer path; tests 7-9
(seek exchange) may follow from the same fixes.

### 6030T6 conclusion: the suite targets MFDU hardware (out of current scope)
The DMA test's check `{ED.bit0, reg 0xFF} == 0x01E0` requires **type ID 0xE0 =
MFDU (NOM10 jumper = 0)** — an identity check, not a DMA fault. Experiments:
bit0-as-pending broke boot nondeterministically (the slot scan's type read
races); static 0xE0 sends the IPL down the MFDU path, which applies 5.25"
geometry to the 8" image and boots by lottery. Conclusion: XU6030 = the
MFDU-family unit; running its suite faithfully needs a NOM10 machine-config
option plus a 5.25" MFDU drive model + media. Tests 1/2/3/5 pass regardless
(they are identity-independent); 4/6-9 are MFDU-hardware-dependent.
Future work, alongside the M4 HDU. Reg 0xFF read reverted to static 0xE1.
