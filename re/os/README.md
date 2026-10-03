# Operating systems

How each M40 operating system boots and what it needed from the emulator.
For running them, see the published guide in
[mame_disks/m40](https://github.com/tpaxia/mame_disks/tree/main/m40).

| Note | Contents | Status |
|---|---|---|
| [OS_boot_media_survey.md](OS_boot_media_survey.md) | Boot test of every OS image from floppy (20 September): ESE, MDOS, MDOSC, BCOS II 3.3 and 5.0, MOS | Historical table; its opening summarises the current state |

## `bcos/`: BCOS II

| Note | Contents | Status |
|---|---|---|
| [BCOS_BOOT.md](bcos/BCOS_BOOT.md) | The working BCOS II 3.3 sequence from the K02733 configurator: date, `/SYS`, the SYS generator | Current |
| [BCOS_boot_reverse_engineering.md](bcos/BCOS_boot_reverse_engineering.md) | How BCOS boots: loader, scheduler, keyboard and floppy paths | Current up to 10 September |
| [K02733_BCOS_headless_boot.md](bcos/K02733_BCOS_headless_boot.md) | A reproducible unattended K02733 boot on macOS | Historical |
| [BCOS_DEBUG_LEDGER.md](bcos/BCOS_DEBUG_LEDGER.md) | Log of every BCOS debugging step and instrument, July to September | Historical |

## `oslem/`: OSLEM and the BCOS hard-disk install

| Note | Contents | Status |
|---|---|---|
| [OSLEM_STATUS.md](oslem/OSLEM_STATUS.md) | Installing BCOS II on the GO363 hard disk with the Olivetti restore procedure: the OSLEM 7+ boot, JX24, MX24, TOC£, DKC£, and why REL 6.0 cannot IPL the hard disk (Issue 2) | Current: opens with the outcome; the rest is the install record |

The disk and library formats found on the way are in
[`../../tools/L1_DISK_FORMATS.md`](../../tools/L1_DISK_FORMATS.md).

## `mdos/`: MDOS

| Note | Contents | Status |
|---|---|---|
| [MDOS30_E0xx_line_driver.md](mdos/MDOS30_E0xx_line_driver.md) | MDOS 3.0: the J0XP loader, the `OVF#SG2#` stop (a GO280 bug), and the E0xx line-controller wait | Current to 22 July; MDOS 3.0 now boots to `READY` |

## `mos/`: MOS

| Note | Contents | Status |
|---|---|---|
| [MOS_DECOMPILATION_STRATEGY.md](mos/MOS_DECOMPILATION_STRATEGY.md) | Plan for decompiling MOS 5.2 with the original Olivetti Pascal+ tools (ZPC, ZPDIS, ZSTUB) | Plan, not started |

The MOS install is scripted in [`../../scripts/mos-install/`](../../scripts/README.md);
the arbiter finding it led to is in
[`../evidence/uc-arbiter-nvi-latency-evidence.md`](../evidence/uc-arbiter-nvi-latency-evidence.md).

## `dcos/`: DCOS diagnostic disks

| Note | Contents | Status |
|---|---|---|
| [DML_filesystem.md](dcos/DML_filesystem.md) | The DML file system and test library of the DCOS 8.4 disks | Current |

The disks' boot flow and test inventory are in
[`../../doc/DIAGNOSTICS.md`](../../doc/DIAGNOSTICS.md) and
[`../../tools/diagnostic_tests/`](../../tools/diagnostic_tests/README.md).

## `l1wse/`: L1WSE on the Olivetti M24

| Note | Contents | Status |
|---|---|---|
| [L1WSE.md](l1wse/L1WSE.md) | `L1WSE.EXE`, the M24 program that emulates an L1 workstation; source of the official PC-keyboard mapping | Living document |
