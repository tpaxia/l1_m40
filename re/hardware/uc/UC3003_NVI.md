# UC3003 non-vectored interrupt test

Evidence: `disasm/runtime/seg21_uc3003_loaded.dis`, loaded segment 21.
Manual: *Concise Functional Checks*, 4102230 T(0), section 3.1.1,
printed page 3-2, test 5. The manual explicitly includes interrupt cause,
mask readback, and generation of NV1 through NV4.

## Annotated execution sequence

| Address (21:) | Operation | Required observation |
|---|---|---|
| 4650–4668 | FF8D/E/F, then FF80/81/82/83 | Enable NV2–NV4, clear all requests |
| 466C–4674 | Read FF81, compare 0F | Empty request nibble, low nibble F |
| 4676–468E | Request all four, then FF85/86/87 | Requests retained while NV2–NV4 masked |
| 4692–469A | Read FF81, compare F8 | All requests visible despite masking |
| 46AA–46BA | Clear requests; enable CPU NVI | Start individual delivery checks |
| 46BE–46DC | Request NV1 at FF88 | Handler flag 458E must become nonzero |
| 46E0–46FC | Request NV2 at FF89 | Flag 458F must remain zero; otherwise error 002E |
| 4700–471A | Release NV2 at FF8D | Pending request must now set flag 458F |
| 471E–475C | Request NV3, then FF8D/E | Same masked-then-released check, flag 4590 |
| 4760–479C | Request NV4, then FF8D/E/F | Same check, flag 4591 |

Handler 4594–461A decodes source bits 7–4 and clears the corresponding
request using FF80–FF83. Source flags are bytes in segment 21.

## Emulation implication

The previous monotonically increasing `m_arb_rel` cannot represent re-masking.
After the initial enable sequence it leaves NV2 deliverable at 46E0, producing
the observed **NV2 INTERRUPT MASK FAULT**. Treating masked requests as absent
from FF81 also contradicts the explicit F8 comparison.

The rejected candidate used separate NV2–NV4 enable latches and retained
request readback independently of delivery. This sequence does not by itself
prove arbitrary combinations of priority and mask settings: NV3 and NV4 are
released with all preceding releases too. Exact arbitration latency remains
unverified; the existing 50 microsecond approximation is unchanged.

Initial validation rejected this candidate: ROM startup stopped at PC 000300 before
disk loading (`runs/bcos-boot.JYaQ31`). All candidate changes were reverted.
In particular, replacing the low-bit idle marker with enable-latch readback
changed reset readback from 07 to 00; this was a possible concern, not the
established cause of the ROM stall.

## Resolved ROM interaction and retained correction

The Z8000 word-I/O memory interface aligns the port and swaps data for odd
addresses. The old 8-bit UC handlers consequently strobed both adjacent ports.
ROM 02F6 requests NV3 with word OUT FF8A; 02FA writes FF87 to mask NV4, then
waits for NV3 at 0300. Splitting that second write also strobed FF86 and masked
NV3. This explains why adding working masks exposed a ROM startup failure.

The retained correction exposes the original CPU I/O address and uses a 16-bit
UC handler to issue exactly one addressed strobe. Byte strobes use the active
lane. NV2–NV4 enable latches and pending readback are separate; the old idle
low-bit readback is preserved. No CPU-PC or disk-specific conditions are used.

Validation `runs/uc-validation.5Gyur8/screen.png`: ROM startup completes and
UC3003 advances through tests 1–6, including the previously failing NV2 check.
Test 7 reports `BANK FAULT(OR ROM SIZE WRONG)`; not an all-tests pass.
BCOS `runs/bcos-boot.rE0oFn/` reaches its scheduler with R2=0/R3=12F8 at 119 s
and consumes Ctrl+J, but still has no configurator prompt.

See `re/os/bcos/BCOS_DEBUG_LEDGER.md` for validation status and temporary instrumentation.
