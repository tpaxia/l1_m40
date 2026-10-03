# uPD7261 VERIFY ID during DCOS ERMAP formatting

## Primary documentation

NEC *uPD7261A/B Hard Disk Controller*,
`reference/datasheets/NEC_uPD7261B_datasheet.pdf`, printed pages 6-19, 6-20, 6-22,
and 6-16:

- Figure 3 identifies opcode nibble `8` as VERIFY ID.
- VERIFY ID takes PHN and SCNT on a soft-sector drive and compares each
  four-byte ID field against bytes supplied from local memory through DMA.
  It returns EST and the remaining SCNT.
- The status-register description says DREQ requests host-to-controller
  data during VERIFY ID, and NCI is set if disk ID bytes do not match the
  supplied bytes. A new disk command clears NCI.

The current external MAME `upd7261.cpp` only logs VERIFY ID and never
enters a result or DMA phase. The existing READ ID implementation synthesizes
four-byte soft-sector IDs from the current physical cylinder, head, and
sector. VERIFY ID should compare incoming four-byte DMA records against
the same ID sequence, update SCNT, and return EST/SCNT. This is an
approximation because the CHD model has no retained physical ID marks.

## DCOS evidence and independent check

The original DCOS 8.4 Disk G image is
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`.
In program `007.HDC5X3`, the shared HDC command issue at linear `0x215382`
(`outb @r2,rl1`, with `r2=0x0011`) receives `r1=0x0080` after `0x68`
SEEK and `0x70` FORMAT in ERMAP option 1. This executing instruction is
at extracted Disk G offset `0x96f82`; its next instruction at linear
`0x215384` is at file `0x96f84`. The bytes `ca11 3e29 ca4c` at extracted
offset `0x96f80` identify this copy of the shared runtime.
The exact dynamic sequence is preserved in
`runs-archive/ermap-breakpoints-20260925/buffered-seek-before-verify-id.breakpoints.log`,
lines 242–304. The option-1 program is described in Olivetti's contemporary
*M30 M40 Manuale dei collaudi*, section 17.6. The VERIFY ID request block
still needs to be mapped precisely; therefore any GO363 board DMA routing
inferred solely from this path is provisional until independently checked.

An independent check is the ERMAP option-2 READ ID path: its `0x90`
controller DMA uses the same synthetic physical ID sequence, allowing the
four-byte IDs and addressing to be compared with option-1 VERIFY ID.
HDC505's Verify ID diagnostic is a further check of the transfer direction,
length, result, and interrupt path. The buffered-seek option-1 replay must
advance past `0x80` and leave the `0x0312be` completion wait before any
whole-disk formatting is attempted. Use disposable CHD copies only.
