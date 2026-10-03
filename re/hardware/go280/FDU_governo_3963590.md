# FDU/MFDU floppy governo — full reference (manual 3963590 R(2))

*"M30/M40/M31 Governi Mini Floppy-Floppy — Descrizione di Funzionamento"*, 3rd
edition April 1984. Complete translation/summary of the technical content, for
the MAME `olivetti/m40` FDU model. The board on the M40 is **GO280** (functionally
identical to GO240). All governi have **no on-board processor** — the Z8001 on the
CPU board programs everything.

## 1. Variants
- **GO184** — 3 floppy or 2 mini-floppy (festoon).
- **GO217** — 4 floppy or 2 mini-floppy.
- **GO229** — 4 floppy, gate-array based, integrated PLO.
- **GO240** — 4 mini-floppy (like GO229).
- **GO280 / GO280/A** — same functionality as GO240 (**this is the M40's board**).

Common: FDC = **NEC 765** (µPD765), records DF (FM) or MFM; transfers via an
on-board **DMAC (AM9517A)**; **end-of-command events → interrupt on level L2**
(the vectored-interrupt daisy chain). FDC can do multi-track / head-scavenging.

## 2. Selection logic (§3.1)
CPU I/O address format:
```
 15 14 13 12 | 11 10 9 8 | 7 6 5 4 3 2 1 0
  NOME SLOT  | non usati |  governo I/O port
```
- **bits 15-12 = slot name**, compared against the board's slot (NSLX0÷3) → EQU00.
- **bits 7-0 = the governo I/O port (register)**. bits 11-8 unused.
- STA00÷31 (Z8000 status) decoded → SELNN (I/O to governo).
- Data: bus buffers gated on (1) governo I/O select, (2) VIACK interrupt-vector
  cycle, (3) DMA cycle. ADL00 picks which byte lane (odd/even).

## 3. Register / port map  ⭐ (authoritative)

### FDC (µPD765), §3.2.1
| Reg | Function |
|-----|----------|
| `0x1D` | **MAIN STATUS REGISTER** (read, poll RQM/DIO/CB) |
| `0x1F` | **DATA REGISTER** (command / parameter / result bytes) |

Selected by CSFDC + address line ADL10, read READA / write WRTNN.

### AM9517A DMAC, §3.3.5 (internal registers)
| Reg | Function |
|-----|----------|
| `0x40` / `0x42` | ch0 address / word-count |
| `0x44` / `0x46` | ch1 address / word-count |
| `0x48` / `0x4A` | **ch2 address / word-count** (the FDC data channel) |
| `0x4C` / `0x4E` | ch3 address / word-count |
| `0x50` | command (write) / status (read) |
| `0x52` | request register |
| `0x54` | single mask bit |
| `0x56` | mode register |
| `0x58` | clear first/second-byte flip-flop |
| `0x5A` | master reset (write) / temp read |
| `0x5E` | mask bits |

### 8253 timer, §3.4.1
| Reg | Function |
|-----|----------|
| `0x9F` | mode register |
| `0x9D` | **ch2** — index-mask time base / low-freq base |
| `0x9B` | **ch1** — end-of-count INTerrupt (INTMO): motor / time-out |
| `0x99` | **ch0** — index-mask (the ROM's addresses; the manual's table lists 0x89 as ch0) |

(Register-select = `(addr>>1) & 3`: 0x99→0, 0x9B→1, 0x9D→2, 0x9F→3.)

### Governo control / status (§3.1.1)
| Reg | Dir | Name | Meaning |
|-----|-----|------|---------|
| `0xE7` | W | **CONTR** | control register (see below) |
| `0xF6` | W | **ADRLN** | DMA physical-address high byte (ADD16-23) |
| `0xEF` | W | **VETTN** | interrupt vector; (also RD1GN diag read for non-GO280) |
| `0xF7` | R | **RD1NT** | interrupt-status port (see below) |
| `0xFF` | R | **RD1DN** | identifier: `0xE0 | NOM10` → **E1 = FDU**, E0 = MFDU |
| `0xED`,`0xEF` | R | **RDGNN** | diagnostic ports (RDGNN for GO280) |
| `0xFF` | W | **E01NT** | strobe to reset the pending interrupt |
| — | W | **VERFN** | preset the DMA logic |

### CONTR (0xE7) bit map (§3.1.1, fig)  ⭐
| bit | signal | meaning |
|-----|--------|---------|
| 0 | **EN100** | 1 = enable interrupt requests, 0 = mask |
| 1 | **RESFD** | 0 = **reset FDC** (REFDN, active-low) |
| 2 | SCANO | scan signal (unused on GO229/240/280) |
| 3 | MOTO1 | 1 = enable MFDU motor #1 |
| 4 | DIAGN | diagnostic: forces some signals toward the drives (see RDY10) |
| 5 | ERRO1 | error condition (GO229/240/280 only) |
| 6 | **SCRVO** | direction: 1 = write to disk, 0 = read |
| 7 | MOTO2 | 1 = enable MFDU motor #2 (GO240/280 only) |

### RD1NT (0xF7) interrupt-status bit map (§3.1.1 / §3.5)  ⭐
| bit | signal | meaning |
|-----|--------|---------|
| 0 | **INTMO** | interrupt request from the 8253 **timer** |
| 1 | **INTOO** | interrupt request from the **FDC 765** |
| 2 | PERRO | parity error during a DMA exchange |
| 3 | FUMEO | DMA "out of memory": no READY within 2 µs of a DMA cycle |
| 5 | DATNN | (upper bits: DATNN, READN, WRITN) |

### RDGNN (0xED/0xEF) diagnostic bit map (§3.1.1)
| bit | signal | meaning |
|-----|--------|---------|
| 0 | WREN1 | write-gate from the FDC |
| 1 | MFM00 (MFM01) | 0 = DF/FM, 1 = MFM recording |
| 2 | DAW00 | data window (DAW02 = clock from data separator, GO280) |
| 3 | REOLN | reset PLO (REPLN = enable data separator) |
| 4 | M640N | 0 = MFDU 96 TPI, 1 = MFDU 48 TPI |
| 5 | DMARO | DMA request from the FDC |
| 6 | INDXO | index (disk-rotation) signal |
| 7 | LPDGN | 0 = loop the diagnostic tests |

### ADRLN (0xF6) — DMA high address
Two counters whose 7 output bits form the most-significant lines of a DMA
address. **On GO280**: accessible on the DBXXX bus, 8 bits + DMA-indicator; the
other 16 bits come from the DMAC.

## 4. Interrupt logic (§3.5)  ⭐
Sources: INTMO (timer ch1), INTOO (FDC), PERRO (parity), FUMEO (DMA time-out).
- ENSOO (from CONTR EN100) can mask the sources, gating the pending flag **INTP1**.
- The governo drives **VINTA → 0** (request to CPU) when: daisy-chain input
  L2XXN = 1, no other governo's VIACK in progress, and **INTP1 = 1**.
- During interrupt-acknowledge the governo emits its vector (enabling VCOUT) and
  **the vector-enable signal also RESETS INTP1**.  → *model: INTP1 is edge-set by
  a source and cleared by the VI-acknowledge (or the E01NT strobe).*
- Governi use **level L2** (lowest of the 3 CPU priorities — no response-time
  constraint).

### September 9 correction to the earlier masking inference

K02733 alone did not prove the latch topology. Live-source enable promotion still
produced a nested FDC interrupt because the emulator forced unused units READY
when CONTR bit 4 was set. Removing that READY override in normal FDU mode resolves
the traced register corruption and passes the diagnostic interrupt-vector sweep.
Suppressing enable edges or replaying historical causes were rejected as general
fixes. See `re/hardware/go280/GO280_FDU_diagnostics.md` for controlled comparisons. The prose and
older-board block diagram do not constitute the complete GO280 gate netlist.

## 5. DMA operations (§3.3)  ⭐
All DMA under the AM9517A. Direction set by **SCRVO** (1 = write, 0 = read).
The DMAC is used in an "anomalous" 2-channel scheme. Its own **HRQ is looped back
to HACK**. Bus request to the CPU is instead **BAXXN** (active-low, via REQ00) from
the board logic — a **bus hold/grant, NOT an interrupt**. It is associated with the
channel-1 OLIBUS memory transaction; channel-2 FDC/buffer cycles are local.

### Read cycle (§3.3.2)
- SCRVO = 0 → only the initial channel-1 cycle is skipped.  Channel 1 is still
  requested after every complete 16-bit word, so its current address advances.
- Bytes transfer locally on **channel 2**: FDC asserts **DMARO** → request DRQ2; DMAC
  acks **DCK2N**; **2 ch-2 cycles per 16-bit word** (8-bit FDC bus): first cycle
  emits OE1NN (LS byte), the FDC re-requests, second cycle emits OE2NN (MS byte)
  + DOWNN which re-enables ch1 (DRQ10). The resulting ch1 cycle is address-only
  and consumes that request. The gate array uses the ch1 address to perform the
  16-bit OLIBUS write from the two buffers. Two data-confirm strobes STB2N, STB1N.
- Repeats until DMAC emits **TCOUN** (terminal count) → FDC → interrupt to CPU.

### Write cycle (§3.3.1)
- VERFN low pulse presets the DMA logic, enabling DRQ10 (ch1, read/write via
  READA/WRTNN). At the DMAC, ch1 is a verify/address cycle without a peripheral
  byte transfer; the board uses it for the 16-bit OLIBUS read into its two buffers,
  and ch2 subsequently sends those bytes to the FDC. FINON resets the ch1 request
  after the system-memory cycle. As
  on reads, DOWNN requests a new address-only ch1 cycle after each two ch2 bytes.

### DMA time-out (§3.3.3)
- On DASTA a counter starts; if the addressed device gives no READY within
  **2 µs**, FUMEN ("out of memory") ends the cycle as if READY had arrived.

### Memory-block addressing (§3.3.4)  ⭐
- **24-bit physical address**: the DMAC emits 2 bytes (low 16 bits); the **high
  portion** comes from two board counters loaded through `0xF6`. Hardware clocks
  those counters up or down when the DMAC exhausts all addresses in the current
  block. Firmware loads the starting value; it does not perform each carry.

## 6. FDC operation (§3.2)
- FDC = slave processor; receives a byte-string command respecting the protocol.
- **RDY10 (ready)**: the FDC auto-scans it every 1 ms between commands;
  **ready↔not-ready changes raise an interrupt to the CPU**. On MFDU, READY is a
  pull-up (not on the actuator interface). **RDY10 can be forced by DIAG0 during
  resident diagnostics** so commands aren't truncated by an out-of-service drive
  — i.e. the hardware diagnostic path can make the FDC see "always ready".
  The printed source name on p. 3-9 is DIAG0. Equating it unconditionally to
  CONTR bit 4 in normal FDU mode was an unsupported inference and has been
  removed from MAME after the September 9 controlled tests.

### MAME consequence confirmed by MDOS30

MAME's `upd765_family_device::ready_w()` stores an external signal that
`get_ready()` subsequently inverts, so `ready_w(false)` means ready.  A GO280
model must not implement `CONTR.DIAGN=0` as `ready_w(true)`: on the MFDU path
that creates a false ready-to-not-ready transition and therefore a spurious
FDC interrupt.  MDOS30 exposed this directly after each successful
`SENSE DRIVE STATUS`: the false interrupt caused a `SENSE INTERRUPT STATUS`
poll (`C0..C3`) to overwrite the valid read result and produced software error
`0x9000`.  Holding the pulled-up MFDU READY input active removes that failure.
- IND20 = index, maskable via MASKO / IDXCO (timer ch2, first 2 index passes of a
  command masked → prevents the FDC missing the first sector of a track).
- MFM01: 1 = FM, 0 = MFM.
- Boot READ = µPD765 READ DATA (templates ROM `0x17dc`/`0x17e6`): `06 HDUS
  C=0 H=0 R=1 N EOT GPL DTL` → cylinder 0, head 0, sector 1; two disk formats.
- Read/write/seek flow charts: figs 3-5/3-6/3-7. Read completes with the FDC
  raising an interrupt and the CPU reading the 7-byte result phase.

## 7. Timer detail (§3.4)  ⭐
8253, 3 channels, FW-programmed:
- **ch0** — low-freq time base from CLK10 (period 1 µs) → **~10 ms** output.
- **ch1** (INTMO) — MFDU management, three uses:
  1. **Motor spin-up**: loaded ≈ **500 ms** — wait before read/write so speed is
     nominal.
  2. **Motor-off**: **2 s** after the last command (reset by a new command).
  3. **Read/write time-out**: **800 ms** (4 disk revolutions). If the FDC hasn't
     finished the command, the end-of-count interrupt wakes the FW. Needed because
     the drive interface lacks a ready line: a data exchange on a disk-less drive
     otherwise hangs waiting for 2 index passes; the timer interrupt avoids the
     hang.
- **ch2** — masks the FDC index signal (first 2 index passes of a read/write are
  masked; output ANDed with the index).

## 8. Board configuration (§4)

The following is specifically the older GO184 DIP F10 table, not GO280:

| DIP 1-4 | mode |
|---------|------|
| `1111` | configuration for FDU |
| `1101` | **diagnostic-test operation for FDU** |
| `1110` | configuration for MFDU |
| `1100` | diagnostic-test operation for MFDU |

GO280's drawing on manual page 4-6 instead gives DIP G10 as:

| DIP 1-4 | mode |
|---------|------|
| `0111` | FDU, 1 MB media |
| `0011` | MFDU, 1 MB media |
| `1101` | diagnostic-test operation (verified on the original page image) |

GO280, unlike GO280/A, supports both 1 MB FDU and 1 MB MFDU drives. GO280/A is the
320/640 KiB MFDU variant; the different media support comes from its PLO gate array.

## 9. MAME modelling notes
Stock devices: **`upd765`** (0x1D/0x1F), **`am9517a`** DMAC (0x40-0x5E) + the
`0xF6` high-address counters, **`pit8253`** (0x99-0x9F, ch1→INTMO), plus the thin
governo glue: CONTR `0xE7`, int-status `0xF7`, identifier `0xFF`, diag `0xED`,
E01NT `0xFF` write, VETTN `0xEF`. Interrupt: INTP1 edge-latch of {INTMO, INTOO}
gated by EN100 → VI (VETTN vector), cleared on VIACK. DMA read = ch2 transfers
FDC bytes while ch1 supplies and advances the low 16 bits of the word address;
`0xF6` supplies its upper bits. TC → FDC interrupt.

The ch1 advancement must be performed by the emulated AM9517, not hidden solely
in a private byte cursor, because system software reads the ch1 current-address
register between FDC commands. BCOS JLD0 uses the value to continue a split module
read. Without the per-word cycles, the second KER0 extent overwrote the first and
caused the misleading `OVF#SG2#` allocation stop.

Implemented after the complete manual/source audit:

- AM9517 HRQ is looped back to HACK.  The separate gate-array REQ00/BAXXN path
  requests the L1 bus only around a channel-1 memory-word transaction; repeated
  DACK callbacks do not extend ownership beyond that transaction.
- The two hardware byte buffers are explicit.  Channel 2 fills/drains them locally,
  while channel 1 performs the 16-bit physical-memory transaction and advances its
  real AM9517 current-address register.
- The `0xF6` high counter carries/borrows when the channel-1 low word address wraps,
  including decrement mode.
- Direction-dependent terminal sequencing is modeled: reads commit the final pair;
  writes prefetch initially and suppress the otherwise extra post-terminal prefetch.
- Timer channel 2 receives physical index only while FDC head load is active. The
  manual's external MASKO gate then hides the first two index pulses from the FDC.
  MAME currently clocks channel 2 but leaves physical index direct to the FDC until
  the external gate phase can be represented without breaking IPL.
- The hardware diagnostic READY path is not implemented; normal FDU keeps READY
  connected to the drives. FDU spindle motors run continuously. CONTR bit 4 does **not**
  select `IDXC0`: that source belongs to the separate G10 `1101` diagnostic-test
  jumper configuration. `SCANO` is explicitly unused on GO280/"60280".
- FDC/timer edges set diagnostic cause latches; RD1NT includes live source levels.
  Enabled source edges set INTP1, and enabling promotes live sources. Historical
  pulses are not replayed on enable. The previous claim that 6030T6 required
  replay of an ended timer pulse was disproved by the normal-READY controls.

Remaining approximations are confined to signals for which the current machine model
has no producer: an absent physical-memory responder raises FUMEO immediately rather
than after a simulated 2 µs counter delay, RAM parity is not modeled so PERRO remains
clear, the exact GO280 data-separator diagnostic waveform (DAW02) is simplified, and
the external MASKO/IDXC0 index mux is not yet modeled.
