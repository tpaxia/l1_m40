# Hardware, board by board

The settled descriptions are in [`../../doc/HARDWARE.md`](../../doc/HARDWARE.md)
(the whole machine), [`../../doc/KDC.md`](../../doc/KDC.md) (GO252) and
[`../../doc/GO363_DCOS_RECOVERY.md`](../../doc/GO363_DCOS_RECOVERY.md) (GO363).
The notes here are how they were found: ROM and diagnostic disassembly,
manual extracts, and tests in MAME.

## `uc/`: UC042 central unit (Z8001, Z8010, 8253, ACIA, MB15652 arbiter)

| Note | Contents | Status |
|---|---|---|
| [ROM_disassembly_findings.md](uc/ROM_disassembly_findings.md) | The ROMs REL 4.1 and 6.0: reset path, self-tests, slot scan, IPL device search; ROM 151/152 vs REL numbering | Historical (first pass); the results are in `doc/HARDWARE.md` |
| [UC3003_cpu_test.md](uc/UC3003_cpu_test.md) | The UC3003 central-unit diagnostic: TRAP, VIENO, timers, ACIA, interrupts, ROM | Current |
| [UC3003_NVI.md](uc/UC3003_NVI.md) | UC3003 test 5, the non-vectored interrupt | Current |
| [UCY805_bus_arbiter.md](uc/UCY805_bus_arbiter.md) | The bus-arbiter test and the MB15652 register model | Historical (superseded in part by `UC3003_NVI.md`) |
| [M40_REGISTER_CONSTANTS_AUDIT.md](uc/M40_REGISTER_CONSTANTS_AUDIT.md) | Audit of the register constants in the driver source (15 September) | Historical |
| [M40_bus_slot_configuration_design.md](uc/M40_bus_slot_configuration_design.md) | Proposed MAME card-cage design for other UC and board combinations | Proposal, partly implemented by the slot options |

## `go252/`: video and keyboard board

| Note | Contents | Status |
|---|---|---|
| [GO252_KDC_diagnostics.md](go252/GO252_KDC_diagnostics.md) | Board photos, ROM anchors, the disk-B video and keyboard programs | Current |
| [CRTAN5_video_test.md](go252/CRTAN5_video_test.md) | CRTAN5, the video, character and attribute test | Current |
| [GO252_BIT4_ABLATION.md](go252/GO252_BIT4_ABLATION.md) | Proof that the old control-bit-4 keyboard workaround was unnecessary (15 September) | Historical |

The keyboard itself is documented in [`../../keyboard/`](../../keyboard/README.md).

## `go280/`: floppy board (uPD765, AM9517 DMA, 8253)

| Note | Contents | Status |
|---|---|---|
| [FDU_governo_3963590.md](go280/FDU_governo_3963590.md) | Translation and summary of Olivetti manual 3963590, the floppy board's functional description | Reference |
| [GO280_FDU_diagnostics.md](go280/GO280_FDU_diagnostics.md) | The disk-D floppy diagnostics and the CPU-to-board protocol | Current |
| [FDU_drive_selection_wiring.md](go280/FDU_drive_selection_wiring.md) | What the manuals do and do not establish about drive-select wiring | Current |

## `go363/`: hard-disk board (uPD7261)

| Note | Contents | Status |
|---|---|---|
| [GO363_HDC5_diagnostics.md](go363/GO363_HDC5_diagnostics.md) | The disk-G hard-disk programs (HDC505, HDC5F5, HDC5X3, Standard 24) and the board protocol they show | Current; summarised in `doc/GO363_DCOS_RECOVERY.md` |
| [GO363_DOCUMENTATION.md](go363/GO363_DOCUMENTATION.md) | What the Olivetti documents say about the GO363 and Standard 24, and where they stop | Current |
| [upd7261_GROUND_TRUTH.md](go363/upd7261_GROUND_TRUTH.md) | MAME already has a uPD7261 device; what it does, how MG-1 wires it, and the GO363 gate-array command protocol (16 July) | Historical; the protocol is current in `doc/GO363_DCOS_RECOVERY.md` |
