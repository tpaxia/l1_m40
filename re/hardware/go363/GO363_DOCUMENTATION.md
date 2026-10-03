# GO363 documentation and Standard 24 evidence boundary

## Primary Olivetti documents

1. *M34/M44 Manuale per l'assistenza*, section 4.1.10, printed page 4-16
   (PDF page 90 of `reference/Manuals (Stefano Marinelli + Olivrea)/M34-M44.pdf`).
   This is a GO363 board description with a component-placement drawing.
   It identifies one board serving two ST506 drives, a PD7261 hard disk
   controller, programmable 8253 timer, 8K×8 RAM, and a 20 MHz clock. It
   says the board identifies the attached drive type from information on
   track 0. It gives no host register map, status-bit definitions, interrupt
   acknowledgement sequence, or DMA address encoding.
2. *L1 Functional Checks Manual, Concise Version*, section 17.5, printed
   pages 17-25–17-27. The HDC505 test descriptions say test 2 checks
   interrupt request logic, test 3 the controller/FIFO path, test 4 the
   8253 and DMA transfer logic, and test 5 the controller RAM and DMA address
   logic. They establish which circuits exist, but not their port semantics.
3. The same Functional Checks manual, section 17.8, printed page 17-32,
   specifies an XU1709/WREN2 65 MB drive and G0363 controller. Option 1
   checks, certifies, and formats track 0, then writes Standard 24 to sectors
   7–15. This establishes the intended installation sequence, not the
   GO363 register protocol.

The original board photo is
`reference/Pictures (M40 + spares)/IMG-20260620-WA0110.jpg`; the component index
is `reference/Pictures (M40 + spares)/BOARD_INDEX.md`.

## What the diagnostic run adds

The disposable-image `009.S24W25` run reaches test 0 and reports
`CONTROLLER INITIALIZATION ERROR` with the current GO363 source. Debugger
and emulator traces show actual GO363 I/O during initialization. Temporary
experiments separated interrupt pending state from VI acknowledgement,
supplied unit status bits at port `0x43`, and added a DMA bridge. With these
experiments the diagnostic advanced to formatting; with the independently
documented uPD7261 DREQ fix it performed 16 sector DMA transfers. These are
software observations and emulator experiments, not GO363 hardware evidence.

| Proposed GO363 behavior | Evidence available | External MAME edit? |
| --- | --- | --- |
| Keep uPD7261 pending status after VI acknowledge | S24W25 checks pending state; HDC505 manual says interrupt logic is tested | No: no board latch/acknowledge documentation |
| Return presence, ready, and fault bits from port `0x43` | S24W25 branches on bits 0, 4, and 2 | No: bit meanings/polarity are not documented |
| Treat ports `0x42`–`0x45` as a word-addressed DMA pointer | S24W25 writes these ports; manual confirms board DMA and 8 KB RAM | No: address encoding and transfer path are not documented |

The incremental `GO363_S24W25_*.patch` files in this working directory are
experimental scratch proposals. The repository ignores patch files; they
have **not** been applied to the external MAME source. The separate
uPD7261 change is justified in `re/evidence/UPD7261_DREQ_EVIDENCE.md`.

The user has directed recovery from the original DCOS programs in the absence
of the board schematic. See `doc/GO363_DCOS_RECOVERY.md` for the instruction-level
evidence and testable inferences. The Olivetti manual still supplies the
hardware and test context; the NEC manual supplies chip behavior only.
