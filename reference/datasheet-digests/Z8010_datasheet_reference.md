# Z8010 MMU — Technical Reference

Structured technical reference for the Zilog **Z8010 Memory Management Unit**,
compiled from the scanned chapter in `z8010.pdf` (Chapter 9, "The Z8010 Memory
Management Unit"). This is a factual/functional summary — register maps, bit
fields, opcodes, pinout, timing and the translation algorithm — organized for
re-implementing the device when porting the P8000 driver to a new MAME. The
original prose is not reproduced; see the PDF for narrative and figures.

Cross-reference the companion files in this folder:
- `z8010.c` / `z8010.h` — the emulation actually used by P8000emu
- `Z8010_P8000_integration.md` — how the three MMUs are wired into the P8000 board

---

## 1. Overview

- Companion to the **Z8001** segmented CPU; sits between CPU and memory.
- 48-pin LSI, single +5 V supply. 4 MHz, 6 MHz, 10 MHz versions.
- Translates a **23-bit logical address** (7-bit segment number + 16-bit offset)
  into a **24-bit physical address** → 8 MB logical maps into 16 MB physical.
- One MMU manages **64 segments**. Two MMUs cover all 128 Z8001 segments. Any
  number may be placed in a system (e.g. separate MMUs for system vs normal mode,
  or per-task translation tables).
- Only **memory** accesses are translated; I/O and data bypass the MMU.
- Not a Z-Bus peripheral — treated as an extension of the CPU and clocked by the
  same clock. Only the **upper** address/data byte (AD8–AD15) is connected; only
  the upper 16 physical address bits (A8–A23) are outputs. The low byte (A0–A7)
  passes straight through unmodified, which is why segments are quantized to
  256-byte units.

### Three operating states (selected per bus cycle from ST0–ST3, R/W, N/S in T1)

| State | When | Behavior |
|-------|------|----------|
| **Memory management** | qualifying memory transaction (see §6) | translate address + check attributes |
| **Command** | Special-I/O transaction with `CS` asserted | CPU reads/writes MMU registers |
| **Quiescent** | everything else (I/O, refresh, internal, non-matching memory, or `CS` inactive) | ignore; address outputs tri-stated |

---

## 2. Pinout (48-pin DIP)

Functional groups:

- **AD8–AD15** — address/data, upper byte (bidirectional). MMU inputs during translation; command data byte.
- **SN0–SN6** — segment number inputs (from CPU).
- **A8–A23** — translated physical address outputs (16 bits, three-statable).
- **SEGT** — segment trap request output (open-drain, active low).
- **SUP** — suppress output (open-drain, active low).
- **DMASYNC** — DMA/segment sync input (low = DMA controls the bus).
- **AS**, **DS** — address strobe / data strobe (bus timing inputs).
- **CS** — chip select input (selects MMU for a Special-I/O command).
- **ST0–ST3**, **R/W**, **N/S** — CPU status inputs.
- **CLK**, **RESET**, **Vcc (+5 V)**, **GND**.

Pin assignments (per Fig 9.5):

| Pin | Signal | Pin | Signal | Pin | Signal | Pin | Signal |
|----:|--------|----:|--------|----:|--------|----:|--------|
| 1 | CS | 13 | A17 | 25 | SN5 | 37 | AD11 |
| 2 | DMASYNC | 14 | A16 | 26 | SN4 | 38 | AD10 |
| 3 | SEGT | 15 | A15 | 27 | SN3 | 39 | AD9 |
| 4 | SUP | 16 | A14 | 28 | SN2 | 40 | AD8 |
| 5 | RESET | 17 | A13 | 29 | SN1 | 41 | ST3 |
| 6 | A23 | 18 | A12 | 30 | SN0 | 42 | ST2 |
| 7 | A22 | 19 | A11 | 31 | AD15 | 43 | ST1 |
| 8 | A21 | 20 | A10 | 32 | AD14 | 44 | ST0 |
| 9 | A20 | 21 | A9 | 33 | AD13 | 45 | AS |
| 10 | A19 | 22 | A8 | 34 | AD12 | 46 | DS |
| 11 | Vcc | 23 | RESERVED | 35 | GND | 47 | R/W |
| 12 | A18 | 24 | SN6 | 36 | CLK | 48 | N/S |

---

## 3. Address translation

Logical address (from CPU):

```
 22 ........ 16 | 15 ................ 0
  SEGMENT (7b)  |      OFFSET (16b)
```

Physical address (to memory), 24 bits:

```
 23 ................. 8 | 7 ...... 0
   A8..A23 from MMU     | offset low byte (pass-through)
```

Steps:
1. `SN0–SN5` index one of 64 **segment descriptor registers** (`SN6` + the `URS`
   mode bit select *which* MMU — see §6). SN is emitted before the offset, so the
   descriptor is fetched early.
2. The descriptor's **base address** field (16 bits) is the upper 16 bits of the
   segment's 24-bit physical start; its low byte is implicitly `00`.
3. The **high byte of the offset** (arrives on AD8–AD15) is added to the 16-bit
   base → physical bits **A8–A23**.
4. The **low byte of the offset** is concatenated unchanged → physical **A0–A7**.

Equivalent: `physical = (base << 8) + offset`. Because the base low byte is always
0 and the offset low byte bypasses the adder, segments start on 256-byte
boundaries and are sized in 256-byte units.

Worked example from the text (base of segment 5 = `231100h`): logical `<5>1528h`
→ physical `232628h` (add high bytes `2311h + 15h = 2326h`, append low byte `28h`).

---

## 4. Segment descriptor register (32 bits, one per segment, 64 total)

```
 31 ............... 16 | 15 ...... 8 | 7 6 5 4 3 2 1 0
    BASE ADDRESS (16)  |  LIMIT (8)  | attribute bits
```

### Base address field (bits 31–16)
Upper 16 bits of the 24-bit physical base address. Low 8 bits are always 0
(segments begin on a 256-byte boundary). Read/written one byte at a time.

### Limit field (bits 15–8)
Segment size control, value `N`. Compared against the **high byte of the offset**
on every access; out-of-range → segment-length violation.
- `DIRW = 0` (ascending): segment = **N+1** blocks of 256 bytes.
- `DIRW = 1` (descending/stack): segment = **256−N** blocks of 256 bytes.

### Attribute field (bits 7–0)

| Bit | Name | Meaning when set |
|----:|------|------------------|
| 0 | **RD** | Read-only. Writes are prohibited (→ read-only violation). |
| 1 | **SYS** | System-only. Normal-mode accesses prohibited (→ system violation). |
| 2 | **CPUI** | CPU-inhibit. CPU accesses prohibited; DMA still allowed. |
| 3 | **EXC** | Execute-only. Reference only during instruction-fetch cycles (incl. PC-relative loads); other access → execute-only violation. |
| 4 | **DMAI** | DMA-inhibit. DMA accesses prohibited; CPU still allowed. |
| 5 | **DIRW** | Direction & warning. 1 = descending (stack) orientation + write-warning on the lowest valid 256-byte block. 0 = ascending. |
| 6 | **CHG** | Changed (status). Set on any successful (non-violating) write by CPU or DMA. |
| 7 | **REF** | Referenced (status). Set on any successful read or write by CPU or DMA. |

Notes:
- `CPUI` + `DMAI` both set ⇒ segment effectively "not present" (any access violates)
  — usable as the missing-segment marker for virtual memory.
- `REF`/`CHG` support swap decisions (which segments to evict / write back to disk).

---

## 5. Control registers

### 5.1 Mode register (8 bits)

```
 7    6    5    4    3   2 .. 0
 MSEN TRNS URS  MST  NMS   ID
```

| Bit(s) | Name | Meaning |
|-------:|------|---------|
| 7 | **MSEN** | Master enable. 1 = MMU active. 0 = disabled, A8–A23 tri-stated. |
| 6 | **TRNS** | Translate. 1 = translate + check. 0 (with MSEN=1) = transparent mode: AD8–AD15→A8–A15, SN0–SN6→A16–A22, A23=0, no checks. |
| 5 | **URS** | Upper range select. 0 = handle segments 0–63; 1 = 64–127. Must match `SN6` to translate. |
| 4 | **MST** | Multiple segment table. 1 = MMU dedicated to one CPU mode (see NMS). 0 = respond regardless of mode. |
| 3 | **NMS** | Normal-mode select. When MST=1, `N/S` input must match NMS to translate. |
| 2–0 | **ID** | 3-bit identification code. During a seg-trap acknowledge the MMU drives AD8+ID (ID 000→AD8 … 111→AD15) high if it trapped. Each enabled MMU needs a unique ID (≤8 MMUs). |

> Book text note: page 167 prose calls bit 3 the "NMS" bit but at one point mislabels its position; Fig 9.11 is authoritative — order is MSEN(7), TRNS(6), URS(5), MST(4), NMS(3), ID(2–0).

### 5.2 Segment address register — SAR (8 bits)

```
 7 6 | 5 .............. 0
 unused | SEGMENT DESCRIPTOR NUMBER (0..63)
```
Pointer into the 64 descriptors for descriptor-access commands. Bits 7–6 unused.

### 5.3 Descriptor selection counter — DSC (8 bits, only bits 1–0 used)

Points to one byte within the descriptor addressed by SAR:

| DSC[1:0] | Selects |
|:--------:|---------|
| 00 | base address, high byte |
| 01 | base address, low byte |
| 10 | limit field |
| 11 | attribute field |

SAR and DSC together address a single byte; several commands auto-increment them
so descriptors can be block-loaded with the Z8001's repeating Special-I/O
instructions.

---

## 6. Entering the memory-management state

For a given memory transaction the MMU translates **only if all** hold:

- `MSEN = 1` and `TRNS = 1`, and
- `URS = SN6`, and
- `MST = 0`, **or** (`MST = 1` and `NMS = N/S`).

Otherwise it stays quiescent (outputs tri-stated). In a multi-MMU system exactly
one MMU should qualify for any given transaction.

---

## 7. Violations, write warnings, traps

On a qualifying access the MMU checks the descriptor attributes and the limit
against the CPU status lines, in parallel with translation. The translated
physical address is always output regardless of violation.

- **Violation** → assert `SEGT` (trap) and `SUP` (suppress). `SUP` can gate `DS`
  to memory to block the illegal access.
- **Write warning** (DIRW segment, write into lowest 256 bytes) → assert `SEGT`
  only; `SUP` is *not* asserted (the access succeeds; it's an early stack-overflow
  warning).

### 7.1 Violation-Type Register — VTR (8 bits, read via cmd 02, reset via 11/13/14)

```
 7    6   5   4    5    2   1    0
 FATL SWW PWW EXCV CPUIV SLV SYSV RDV
```

| Bit | Name | Set when |
|----:|------|----------|
| 0 | **RDV** | write attempted to a read-only (RD) segment |
| 1 | **SYSV** | normal-mode access to a system-only (SYS) segment |
| 2 | **SLV** | offset high byte exceeds the segment limit |
| 3 | **CPUIV** | CPU access to a CPU-inhibit (CPUI) segment |
| 4 | **EXCV** | non-fetch access to an execute-only (EXC) segment |
| 5 | **PWW** | primary write warning (first, no other VTR flag set) |
| 6 | **SWW** | secondary write warning (a prior-instruction flag set, warning in **system stack** space) |
| 7 | **FATL** | fatal — a new non-SWW violation while a prior-instruction flag is still set (i.e. a violation during trap servicing). While FATL is set, further violations do **not** assert `SEGT` until FATL is reset. |

(There is no VTR flag for DMA-inhibit violations, because DMA accesses don't trap.)

### 7.2 The other five status registers (read-only)

| Register | Read cmd | Holds |
|----------|:--------:|-------|
| Violation Segment Number | 03 | segment number of the violating access (bit 7 = 0) |
| Violation Offset (high byte) | 04 | upper byte of the violating logical offset |
| Bus Cycle Status | 05 | `[0][0][N/S][R/W][ST3..ST0]` at the time of the violation |
| Instruction Segment Number | 06 | segment number of the first word of the instruction executing at the violation (bit 7 = 0) |
| Instruction Offset (high byte) | 07 | upper offset byte of that instruction word |

External latch hardware is needed if the *low* offset byte of the violating
address must be captured (the MMU only stores the high byte).

### 7.3 MMU response summary (Table 9.1)

| Event | CPU access | DMA access |
|-------|-----------|-----------|
| Violation | trap + suppress (SEGT + SUP) | suppress only (SUP) |
| Write warning | trap only (SEGT) | no signal |

`SEGT` and `SUP` assert during **T2**; `SEGT` stays low until a seg-trap
acknowledge appears on ST0–ST3; `SUP` stays low through the offending data
transfer and all subsequent CPU accesses to the end of the current instruction.
Both are open-drain so multiple MMUs wire-OR into one CPU/memory signal.

### 7.4 Trap servicing (Z8001 side)
Z8001 treats `SEGT` like an interrupt: the next fetch is aborted, an ack cycle
runs, and during T3 the CPU reads an identifier word whose upper byte (per each
MMU's ID) marks which MMU(s) trapped. Service routine: read identifier → for each
trapping MMU read VTR → test FATL first, then SWW, then process the original
violation → clear VTR → return. FATL and SWW together stop the handler from
re-trapping itself while saving/restoring program status on the system stack.

---

## 8. Command set (Special-I/O)

Commands arrive as Special-I/O transactions while `CS` is asserted. The **high
byte of the I/O port address** is the command opcode; it enters the MMU on
AD8–AD15. The **low byte** is decoded externally to generate chip selects (AD0
must be 0; for ≤7 MMUs, ADi = chip-select for MMU #i). Data (when any) transfers
in T3 on AD8–AD15, one byte at a time.

### Read/Write commands

| Opcode | Operation |
|:------:|-----------|
| 08 | R/W base field in descriptor |
| 09 | R/W limit field in descriptor |
| 0A | R/W attribute field in descriptor |
| 0B | R/W descriptor (all fields) |
| 0C | R/W base field, **increment SAR** |
| 0D | R/W limit field, **increment SAR** |
| 0E | R/W attribute field, **increment SAR** |
| 0F | R/W descriptor (all fields), **increment SAR** |
| 00 | R/W mode register |
| 01 | R/W segment address register (SAR) |
| 20 | R/W descriptor selection counter (DSC) |

### Read-only status registers

| Opcode | Operation |
|:------:|-----------|
| 02 | Read violation-type register (VTR) |
| 03 | Read violation segment number register |
| 04 | Read violation offset (high byte) register |
| 05 | Read bus cycle status register |
| 06 | Read instruction segment number register |
| 07 | Read instruction offset (high byte) register |

### Set/Reset commands (Special-Output, no data transferred)

| Opcode | Operation |
|:------:|-----------|
| 15 | Set all CPU-inhibit flags |
| 16 | Set all DMA-inhibit flags |
| 11 | Reset violation-type register (VTR) |
| 13 | Reset SWW flag in VTR |
| 14 | Reset FATL flag in VTR |

### Reserved / unassigned
`10`, `12`, `17–1F`, `21–FF`.

### Example programming (Z8001 assembler, from the text)
```
    SOUTB  %00FC, RH0     ; load RH0 into mode register of MMU selected when AD1 low
    SOUTB  %11FC, RH0     ; reset the VTR of that MMU (data ignored)

; Block-load all 64 descriptors of MMU #1 from a table in memory:
    CLR    R0
    SOUTB  %01FC, RH0     ; clear SAR in MMU #1
    LDA    RR4, DESCRIPTORS
    LD     R0, #256       ; count = 64 descriptors * 4 bytes
    LD     R1, #%0FFC     ; port = "R/W descriptor & increment SAR" (0F) for MMU #1
    SOTIRB @R1, @RR4, R0  ; load all descriptors
```
In-memory descriptor layout for the block load (per descriptor, low→high address):
base high byte, base low byte, limit, attribute — repeated for descriptors 0..63.

---

## 9. Reset behavior

`RESET` low clears the **mode**, **DSC**, and **VTR** registers; all other
registers are undefined afterward. The state of `CS` during reset picks the mode:

| CS during RESET | Result |
|-----------------|--------|
| high | MSEN cleared → MMU **disabled**, A8–A23 tri-stated, SUP/SEGT (open-drain) undriven. CPU must later write the mode register and set MSEN. |
| low | MSEN set, TRNS cleared → MMU enabled in **transparent mode** (addresses pass through untranslated). One MMU is usually reset this way so the CPU can run a non-relocatable init routine that programs the MMUs. |

---

## 10. Multiple-MMU systems & DMA

- **Single MMU**: only 64 of the 128 segment numbers; out-of-range segments leave
  the MMU quiescent — external hardware must detect them and force SEGT/SUP.
- **Two MMUs**: cover all 128 segments; `URS` selects which handles 0–63 vs 64–127.
- **More MMUs**: separate translation tables per CPU mode (MST/NMS) or per task
  (enable/disable with MSEN during task switch) — trade MMU count vs reprogramming
  frequency. See Fig 9.25 for a dual-MMU + Z8016 DMA reference wiring; on reset,
  MMU #1 comes up transparent and MMU #2 disabled.
- **DMA**: `DMASYNC` low tells the MMU the cycle is a DMA cycle. DMA violations
  assert `SUP` only (no trap, status registers untouched); DMA write warnings are
  not signaled at all.

---

## 11. Timing / access-time note

The segment number is emitted a cycle early (last state of the preceding cycle),
letting the MMU pre-select the descriptor before the offset appears in T1. The
base+offset add still costs time, so the valid physical address appears later than
the CPU's `AS` rising edge — a memory system generally needs a **delayed address
strobe** derived downstream rather than trusting `AS` to mark a valid physical
address.

---

## 12. Virtual-memory caveat (relevant to emulation fidelity)

The Z8001+Z8010 pair does **not** fully support demand paging: on a violation the
Z8001 finishes the current instruction before taking the trap. For an
`ADD R0, DATA` where `DATA` faults, the instruction completes and whatever is on
the bus during T3 is added to R0 even though `SUP` was asserted — so CPU registers
can be corrupted. True virtual memory needs extra hardware to force a known value
(e.g. all-0s for a data fetch, or a NOP opcode for an IF1 fetch) onto the bus when
`SUP` is active. (The later **Z8003** VMPU adds instruction-abort; the **Z8015**
PMMU adds 2 KB paging for the Z8003.) The P8000 uses the Z8010 segmentation model,
not paging.

---

*Source: `z8010.pdf`, Chapter 9 "The Z8010 Memory Management Unit" (Zilog Z8000
architecture text). Figures/tables referenced: 9.5 pinout, 9.7 translation, 9.8
descriptor, 9.11 mode reg, 9.12 SAR, 9.13 DSC, 9.16 VTR, 9.17–9.19 status regs,
9.20 SUP/SEGT timing, Table 9.1 responses, Table 9.2 commands, 9.24 descriptor
memory layout, 9.25 dual-MMU wiring.*
