# µPD7261 in MAME — Ground Truth (supersedes the implementation plan)

**Bottom line:** the µPD7261 is **already fully emulated in the current MAME tree**. Do **not**
write a new device. `re/hardware/go363/upd7261_implementation_plan.md` and `re/hardware/go363/upd7261ad_mame.md` ("Status: Not
Emulated in MAME") are based on an out-of-date premise — verified false against the tree on
2026-07-16.

## The existing device

- **Files:** `src/devices/machine/upd7261.cpp` (733 lines) + `upd7261.h` (104 lines)
- **Author:** Patrick Mackinlay, BSD-3-Clause
- **Device type:** `DECLARE_DEVICE_TYPE(UPD7261, upd7261_device)` — one type (A/B variance handled
  by the SPECIFY mode bits, not separate classes)
- **Drive backend:** `optional_device_array<harddisk_image_device, 8>` — CHD/LBA level (Phase 4
  stage-1 in the plan; already done)

### Host interface (`upd7261.h`)

| Member | Direction | Purpose |
|---|---|---|
| `UPD7261(config, tag, clock)` | — | instantiate |
| `map(address_map &)` | — | 2 registers: **offset 0 = DATA** (r/w), **offset 1 = STATUS (r) / COMMAND (w)** |
| `out_dreq()` | out line | DMA request (level) |
| `out_int()` | out line | interrupt request |
| `tc_w(int)` | in line | DMA terminal count |
| `head_w(u8)` | in method | extended/physical head number (host supplies via a control reg) |

Internal state (all `save_item`'d): `m_status`, `m_est` (error status), `m_ist` (interrupt
status), `m_ua` (unit addr), `m_pcn[4]` (per-unit cylinder), the `m_specify` packet
(mode/dtlh/dtll/etn/esn/gpl2/rwch/rwcl), the `m_transfer` packet
(phn/lcnh/lcnl/lhn/lsn/scnt), a 1-sector `m_buf`, and the dreq/int/tc line states.

### Command set (opcode = `BIT(command, 4, 4)`; unit = low 2–3 bits)

| Op | Command | State |
|----|---------|-------|
| 0x1 | sense interrupt status | done |
| 0x2 | specify (8 param bytes) | done |
| 0x3 | sense unit status | done |
| 0x4 | detect error | **stub** ("not emulated") |
| 0x5 | recalibrate | done (normal + buffered, polled/unpolled) |
| 0x6 | seek | done (normal + buffered, polled/unpolled) |
| 0x7 | format | **stub** |
| 0x8 | verify id | **stub** |
| (read/write data) | data transfer | done (PIO + DMA via dreq/dack, multi-sector) |

Status bits: `S_RRQ`=0x08 (reset request), `S_SRQ`=0x10 (SIS request).
Interrupt status (`m_ist`): `IST_NR`=0x08, `IST_EQC`=0x10, `IST_SER`=0x20 (seek err),
`IST_RC`=0x40 (ready change), `IST_SEN`=0x80 (seek end).
Unit status (`UST_*`) and error status (`EST_NR`/`EST_EQC`) also defined.

## Wiring reference — `src/mame/mg1/mg1.cpp` (the ONE live consumer)

```cpp
required_device<upd7261_device> m_hdc;

// address map (16-bit host, low byte lane):
map(0x309600, 0x309603).mirror(0xcf6000).m(m_hdc, FUNC(upd7261_device::map)).umask16(0x00ff);

// extended head bit driven from a control register write:
m_hdc->head_w(BIT(data, 4) ? 0x08 : 0x00);

// device config:
UPD7261(config, m_hdc, 10_MHz_XTAL);
m_hdc->out_dreq().set(m_dma[1], FUNC(am9516_device::dreq_w<0>)).invert();  // -> DMA
m_hdc->out_int().set(m_icu, FUNC(ns32202_device::ir_w<3>));               // -> interrupt ctrl
HARDDISK(config, "hdc:0");
HARDDISK(config, "hdc:1");
```

Note: `src/mame/att/att3b2.cpp` references it too but it is **commented out** and uses the old
`read`/`write` names (pre-`map`); ignore it. `mg1` is authoritative.

## What the GO363 HDU (NEC D7261AD) integration still needs (the real open work)

The chip is done; only the **board glue** is unknown and must come from the ROM/disk RE
(`re/hardware/go363/GO363_HDC5_diagnostics.md`):

1. **Slot register offsets** — where DATA and STATUS/COMMAND sit in the GO363 slot window
   (like the FDU's `0x1D`/`0x1F`). Map those two to `upd7261_device::map`.
2. **DMA** — GO363 almost certainly uses the same UC arbiter + AM9517-style DMA as the FDU:
   `out_dreq()` → the DMA request; `tc_w()` from the DMA terminal count; data flows through the
   same 24-bit word-address path already built for the FDU.
3. **Interrupt** — `out_int()` → the governo **VI** (same INTP1/VETTN latch path as the FDU).
4. **head_w** — the extended head from a GO363 control-register bit (find in the RE).
5. **Drives** — `HARDDISK(config, "hdc:0")` with a CHD whose geometry matches what the GO363
   firmware SPECIFYs (log mismatches — the "boots but corrupts" trap).

## Cross-check vs `re/hardware/go363/GO363_HDC5_diagnostics.md` — the GO363 does NOT expose the raw chip

The µPD7261 chip has **two** host registers: DATA (offset 0) and STATUS(r)/COMMAND(w) (offset 1).
Commands are a byte whose **opcode is the high nibble** `BIT(cmd,4,4)`; parameter and result bytes
stream through the DATA register (`data_w`/`data_r` into `m_buf`). Full opcode table:

| op | µPD7261 command | | op | µPD7261 command |
|----|-----------------|-|----|-----------------|
| 0x1 | sense interrupt status | | 0x9 | read id |
| 0x2 | specify                | | 0xa | read diagnostic |
| 0x3 | sense unit status      | | 0xb | **read data** |
| 0x4 | detect error (stub)    | | 0xc | check |
| 0x5 | recalibrate            | | 0xd | scan |
| 0x6 | **seek**               | | 0xe | verify data |
| 0x7 | format (stub)          | | 0xf | **write data** |
| 0x8 | verify id (stub)       | |     | |

**But the GO363 host registers are a gate-array wrapper, not these two chip registers.** The RE
found: `0x80/0x82` DMA address counter, `0x83` start strobe, `0x90` status, `0xb0` command+control
**word**, `0xe0/0xe1` drive/CHS/parameter bytes, `0x00-0x03` result bytes — plus a local 8253, an
8K SRAM FIFO buffer, and the board's own DMA/address counter. So the host talks to the TI gate
array; the gate array drives the µPD7261 and buffers the data phase in SRAM. This is the **same
shape as the FDU** (governo wraps µPD765) but heavier (SRAM FIFO + board DMA + result latches).

**Opcode encodings do NOT map 1:1 — this is the key open item.** The GO363 writes an opcode in the
**high byte** of the `0xb0` word (observed `0x09`, `0x0a`, `0x0d`, `0x02`). The RE's ROM-guess
"`0x09`=seek, `0x0a`=read" **disagrees** with the actual chip (`0x09`=read-id, `0x0a`=read-diag,
seek=`0x6`, read-data=`0xb`). So either the guesses are wrong or (more likely) the gate array
**translates** its opcodes into µPD7261 command bytes. That translation, and how `0xe0/0xe1`
parameters and `0x00-0x03` results map onto the chip's DATA-register packet, must be decoded from
`re/disassembly/diagnostics/go363/diskG_common_HDC5_runtime_1a400_1ca00.dis` before any wiring.

### Revised integration verdict
- **Reuse** the `upd7261_device` as the disk-I/O core (seek/read/write to CHD, status, ISR) — it is
  correct and complete for the happy path.
- **A GO363 gate-array wrapper is still required** — you cannot `.m(hdc, upd7261::map)` at the slot
  the way `mg1` does, because the GO363 doesn't present the chip's 2 registers. The wrapper must:
  translate `0xb0`/`0xe0`/`0xe1` → a µPD7261 command byte + parameter stream via `data_w`; expose
  `0x90` from `status_r` (bit re-map likely); return the result phase at `0x00-0x03`; run the board
  DMA (word-addressed like the FDU, `0x80/0x82` = `addr>>1`) between the µPD7261 `out_dreq`/`tc_w`
  and system RAM; and raise the governo VI from `out_int`.
- **Blocking RE:** the `0xb0` opcode→µPD7261 map and the parameter/result byte order. Until those
  are decoded, the wrapper can't be written correctly.

## GO363 gate-array command protocol — DECODED (from `diskG_common_HDC5_runtime_1a400_1ca00.dis`)

All GO363 port accesses are **16-bit `out`/`in`** (word), port = `(slot<<8)|reg`. A command is
issued as:

```
1. out 0xe0, <param word>        ; drive/CHS/parameter selector (0xe1 = 2nd param word)
2. out 0xb0, <command word>      ; command word (see below)
3. out 0x83, <command word>      ; start strobe (data-transfer commands repeat the word here)
```

**Command word layout** (`0x0900`..`0x0f__` observed): bits **11-8 = the µPD7261 opcode nibble**,
low byte = board control/strobe (bit 4 = command strobe, pulsed via `res r9,#4`/write-back; bit 3
≈ DMA/data-phase enable; bit 11 also pulsed via `res r9,#11` in the handshake). Verified command
words and their meaning **against the chip's opcode table** (correcting the RE's ROM guesses):

| `0xb0` word (obs.) | opcode nibble | µPD7261 command | RE doc had said |
|---|---|---|---|
| `0x02xx` (`0218`,`0208`) | 2 | **specify** | specify ✓ |
| `0x03xx` (`0310`) | 3 | sense unit status | — |
| `0x08xx` (`0810`) | 8 | verify id | — |
| `0x09xx` (`0910`) | 9 | **read id** | ~~seek~~ (wrong) |
| `0x0axx` (`0a18`) | a | **read diagnostic** | ~~read~~ (wrong) |
| `0x0bxx` (`0b10`) | b | **read data** | — |
| `0x0dxx` (`0d25`) | d | scan (used by the DMA/timer test) | — |

So the gate array forms the µPD7261 command byte as `(opcode_nibble<<4)|unit` — the host-visible
opcode value **is** the chip's opcode nibble. seek would be `0x06xx`, recalibrate `0x05xx`,
write-data `0x0fxx` (not yet spotted in this range — look in the S24* format/write tests).

**DMA address = word-addressed, identical to the FDU** (`0x1a64c`): `srll rr4,#1` then `out 0x80,
<low>` / `out 0x82,<high>` — i.e. `board_addr = system_byte_addr >> 1`. The FDU's word-address DMA
model (already built) applies directly.

**Result/status:** status polled at `0x90`; after completion the gate array exposes result bytes at
`0x00-0x03` (the RE's status-decode anchor `0x1a7f4` reads `0x90` then `0x00..0x03`). Mapping those
onto the chip's ST/EST/IST result bytes is the remaining fine-grained decode.

### Net: the gate array is a thin command translator, not an intelligent controller
Host writes {opcode-nibble word to `0xb0`, params to `0xe0/e1`, DMA addr to `0x80/82`, strobe `0x83`}
→ gate array drives the µPD7261 (`(nibble<<4)|unit` command, params via the chip DATA register) and
runs the SRAM-buffered word-addressed DMA. A GO363 wrapper device that does exactly this translation,
sitting in front of the existing `upd7261_device`, is the correct model — and every hard part (DMA
word-addressing, governo VI latch) is already implemented for the FDU.

## Corrections to fold back into the other notes
- `re/hardware/go363/upd7261ad_mame.md` §"Status: Not Emulated" → **wrong**; it is emulated.
- `re/hardware/go363/upd7261_implementation_plan.md` Phases 1–4 (write skeleton → FSM → data path → drive
  backend) → **already implemented** by Mackinlay's device; skip to the equivalent of Phase 5
  (host/board integration) using `mg1` as the pattern.
- `re/hardware/go363/upd7261_mame_analogues.md` (derive from xt_hdc/pdc/wd2010) → moot; the direct analogue **is
  the µPD7261 device itself**.
