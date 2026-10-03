# Three key-operated switches: firmware and KEYTE1

## Confirmed protocol

The ANK1402 8049 firmware reports these controls separately from auxiliary
make/break codes 6A–70 / 72–78. The earlier suggestion that the six rotary
contacts belonged to that auxiliary group was incorrect.

Firmware source: `PCOS/src/KeyBoard/M40/m40_8049.s` in the separate M20 project (annotated 8049 disassembly).

- 0363–0371 selects BUS=00, samples P2, forces bits 7–6 high, and saves
  the result in RAM 13 (SAVED1).
- 0218–022A compares it with RAM 12 (SAVED0). On change it updates RAM 12,
  queues FD, and sets the pending saved-byte flag.
- 0254–0260 sends RAM 12 next. Thus the report is `FD status`, where
  `status = P2 | C0`. This is distinct from BUS=11 auxiliary scanning.

This establishes six sampled contact bits, consistent with the photographed
three key-operated controls and two switches per control.

## Diagnostic decoder

Primary binary: `runs-archive/keyte1-watch-dump/m40_seg_21.bin`.
Offsets below are within logical segment 21.

At 13AE–13B8 (also 1484–148E), FD invokes 14FC. That routine consumes the
next byte, then decodes three two-bit fields, low pair first, at 1522–154C.
Strings at 1E66 are eight-byte entries: ERROR, RIGHT, LEFT, NORMAL.
The first field has a special inversion at 152C–153A: values other than
3 are XORed with 3. Do not assume all three controls have identical wiring.

| Raw pair | Field 1, bits 1–0 | Field 2, bits 3–2 | Field 3, bits 5–4 |
|---|---|---|---|
| 00 | NORMAL | ERROR | ERROR |
| 01 | LEFT | RIGHT | RIGHT |
| 10 | RIGHT | LEFT | LEFT |
| 11 | NORMAL | NORMAL | NORMAL |

These are **display-field numbers**, not yet a verified left-to-right physical
assignment or functional names of the three locks.

Example full status bytes, with the other fields at 11:

| Report | Diagnostic interpretation |
|---|---|
| FD FF | NORMAL / NORMAL / NORMAL |
| FD FE | RIGHT / NORMAL / NORMAL |
| FD FD | LEFT / NORMAL / NORMAL |
| FD F7 | NORMAL / RIGHT / NORMAL |
| FD FB | NORMAL / LEFT / NORMAL |
| FD DF | NORMAL / NORMAL / RIGHT |
| FD EF | NORMAL / NORMAL / LEFT |

These examples are statically decoded, not new live diagnostic test results.

## Manual and test selection

Concise Functional Checks Manual, 4102230 T (0), section 6.4.1, printed
pages 6-6–6-7: KEYTE1 Test 1 explicitly tests key switches by turning right
and checking RIGHT, then returning to the original position and checking NORMAL.
The special-key test for LK/SH/CN is separate.

The binary's layout menu offers option 0 `AN + F + 3KS`, and other +3KS
variants. Option 3 ANK1426 lacks these switches; use an appropriate +3KS
layout when testing their display. The renderer is gated by byte 05FE.

## MAME and BCOS implications

Implemented in MAME on 2026-09-11: three Configuration inputs, Key switch
1/2/3, each Normal/Left/Right, default Normal. No invalid/Error position.
The status strip shows K1/K2/K3 beside IPL. Numbers follow diagnostic fields,
not physical labels. Use MAME UI -> Machine Configuration to change them;
the strip displays their state, it is not itself a position selector.

The native keyboard sends FD/status on position changes. At command 00 it
reports non-default positions; all-Normal sends nothing at startup, matching
firmware initialization of SAVED0 to FF. No host-key aliases were added.

Headless saved-state C replays on copied relabelled RUN media:

| Position (others Normal) | Report | Run | Result |
|---|---|---|---|
| K1 Right | FD FE | ELlxVg | ERR.163 |
| K2 Right | FD F7 | DOUfpP | ERR.163 |
| K3 Right | FD DF | uYcoJz | ERR.163 in trace |
| K1 Left | FD FD | nLVZng | ERR.163 |
| K2 Left | FD FB | ExTbyj | ERR.163 in trace |
| K3 Left | FD EF | ivXkSO | ERR.163 in trace |

Run directories have prefix `runs-archive/bcos-run-error.`. Some captured screens
are blank; the CPU trace still shows internal error 0026 being formatted as
163 at 13:7C2E. Blank output is NOT a successful interpreter launch.
The extended K3 Right replay WI3bGN likewise did not establish BASIC startup.

BCOS receives the actual bytes through GO252 1F02. Its handler at 25:01B2
recognizes FD and sets a pending flag; 25:01A8 stores the following status
byte at `[r5 + D4]` (r5=0A0E in these replays). This is direct evidence
that BCOS processes the switch protocol. However, the TR00 check still reads
zero from 00:1760, and fails mask 0002 in every individual-position test.
No position combination or earlier-boot switch timing has yet been tested.
Do not equate this raw switch byte with the interpreter-enable flag.
