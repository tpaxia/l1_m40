# GO363 / HDC5 ST506 diagnostic reverse engineering notes

This note collects the photo evidence, collaudi/manual mapping, disk-G catalogue,
and initial disassembly anchors for the GO363 hard-disk governo. The
*M34/M44 Manuale per l'assistenza*, section 4.1.10, printed page 4-16,
describes the board and shows component placement, but no host register or
DMA protocol. See `re/hardware/go363/GO363_DOCUMENTATION.md` for the documented limits of the
current Standard 24 experiments. Unlike GO280, no GO363 schematic or
register-level functional description has been found yet.

## Conclusions (October 2026)

- **Board.** GO363 answers board ID `65`; the gate array is a thin command
  translator in front of the uPD7261, with word-addressed DMA, a vectored
  interrupt and a 20 MHz 8253 (divider unknown). The register protocol recovered
  from these diagnostics is written up in `doc/GO363_DCOS_RECOVERY.md`.
- **Results on the emulated WREN2** (1024 × 9 × 32 × 256): S24W25 writes and reads
  back Standard 24; HDC5X3 writes ERMAP at cylinder 924; HDC5F5 formats the disk
  (`DISK CORRECTLY FORMATTED`); HDC5E9 reports `RELIABLE SUBSYSTEM`. BCOS II and
  MOS are installed on it and boot.
- **HDC505** passed tests 1–4 on the old HD branch; on the current build it fails
  test 2 (3 October 2026, `doc/MAME_DRIVER.md` §9).
- The MAME changes these runs led to are listed in `re/evidence/README.md`.

The rest of this note is the investigation record; sections such as "Current
implementation boundary" describe the model at the time they were written.

## Board photo

Photo index:

```text
reference/Pictures (M40 + spares)/BOARD_INDEX.md
reference/Pictures (M40 + spares)/IMG-20260620-WA0110.jpg
```

`BOARD_INDEX.md` identifies this as:

```text
GO363 - HDU hard-disk governo, physical/logical name 65
NEC D7261AD (uPD7261 ST506 controller), CXO 20.000 MHz oscillator, TI gate arrays
ROMs on board: none
```

The earlier `E4` identification was wrong: `E4` belongs to the older GO230
18 MB HDU governo.  The M34/M44 hardware table assigns `65` to GO363, and the
live HDC505 test 1 independently requires register `0xff` to return `0x65`.
Consequently ROM 6.0's `E4` IPL entry and handler at `0x1e58` must not be
described as native GO363 merely because its host protocol looks similar.

Additional markings visible in `IMG-20260620-WA0110.jpg`:

- `NEC JAPAN D7261AD` - uPD7261-family ST506 hard-disk controller.
- `CXO-042D 20.000MHz` - local HDC clock oscillator.
- `P8253-5` - AMD 8253 timer.
- `TOSHIBA TC5565CPL-15` - 8K x 8 SRAM, likely controller buffer RAM.
- `AM26LS31PC`/similar line-driver parts near the ST506 connectors.
- Many 74LS/74S glue parts and larger custom/gate-array parts.

The lack of EPROMs is important: this is not an intelligent CPU board. It is a
host-driven controller with HDC/timer/SRAM/gate-array logic.

## Relevant manual tests

The concise Functional Checks manual chapter 17 is the relevant section:

```text
17. HDU TEST PROGRAMS FOR ST506 INTERFACE
```

The hardware lists identify `G0363` as the controller for the ST506 systems:

```text
XU1707/1709 WREN1/2      G0363 (ST506)
MICROPOLIS 1325          G0363 (ST506)
OPE / XM5221             G0363 (ST506)
WREN2 downgraded         G0363 (ST506)
MICROPOLIS 1323/A        G0363 (ST506)
XU5006 14 MB             G0363 (ST506) or SASI/DTC path
```

Chapter 17 programs:

```text
17.1  HDC5F5   XU1707/1709 hard-disk formatter
17.2  HDC5E7   XU1707/1709 error-rate program
17.3  HD5ST3   XU1707/1709 and STC save/restore
17.4  HDC5V6   XU1707/1709 verify and correction
17.5  HDC505   XU1707/1709 controller and driver diagnostic
17.6  HDC5X3   ST506 HDU read/write ERMAP
17.7  S24W16   write Standard 24 on XU1707 / WREN1
17.8  S24W25   write Standard 24 on XU1709 / WREN2
17.9  S24M54   write Standard 24 on Micropolis 1325
17.10 S24X11   write Standard 24 on XM5221
17.11 S24WD0   write Standard 24 on WREN2 41 MB
17.12 S24MA1   write Standard 24 on Micropolis 1323/A
17.13 S24MA1   write Standard 24 on NEC5126H
```

The disk catalogue uses `HDC5E9` where the OCR/manual heading reads `HDC5E7`.
The OCR also reads the controller diagnostic heading as `HDC503` in one place,
but the disk catalogue and embedded program banner are `HDC505`. Treat both as
manual/OCR/catalogue naming discrepancies until proven otherwise.

The most useful test for modelling the controller is `HDC505`, especially:

```text
1) SLOT TEST-CHECK TYPE & BOARD ADDRESS
2) GENERATE INTERRUPT AND TEST VECTORS
3) PROGRAM 'NEC' & WRITE/READ 'FIFO'
4) TEST 8253 TIMER & DMA TRANSFER LOGIC
5) TEST DMA & RAM & ASS.ADDRESS COUNTER
6) TEST HOME+TIMEROT+READID+STD24:CYL.0
...
16) FORMAT-READ 'GPLX' MINIMUM CYL.
```

Tests 3-5 are the main GO363 protocol targets because they exercise the NEC HDC
FIFO path, the local 8253, DMA transfer logic, board RAM, and address counter.

The OCR text for 17.5 confirms the intent:

```text
TEST 3 PROGRAM HDC & WRITE/READ FIFO
  Checks the part of the input/output circuit associated with the FIFO memory.

TEST 4 TEST 8253 TIMER & DMA TRANSFER LOGIC
  Checks the input/output circuit associated with the 8253 timer and the DMA
  transfer logic.

TEST 5 TEST DMA & RAM & ASS.ADDRESS COUNTER
  Checks RAM addressing/storing and the DMA address logic between controller
  RAM and system RAM.
```

The HDC505 binary itself also contains the matching operator/error strings:

```text
6 DATA BYTES WRITTEN =
6 DATA BYTES READ    =
ERROR IN WRITE/READ OF 'NEC' FIFO
AT END OF TRANSFER DMA ERROR =
DMA FROM SYSTEM RAM TO BOARD RAM
DMA FROM BOARD RAM TO SYSTEM RAM
SYSTEM RAM PHYSIC.ADDRESS =
SYSTEM RAM LOGIC  ADDRESS =
TRASFER LENGTH (IN WORDS) =
BYTE=ADDR.BOARD RAM(WORD)=
BYTE=ADDR.SYS.RAM(WORD)=
```

## Disk image and catalogue

Relevant image:

```text
reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD
```

Extraction and catalogue:

```sh
python3 tools/imd.py \
  "reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD" \
  extract /tmp/diskG.bin
python3 tools/dml_catalog.py list /tmp/diskG.bin
```

Catalogue:

```text
catalog offset=0x31500 sectors=8 special=UTILY884870331
idx ext loc   len  flat_sec  flat_off  bytes  name
  2  00   106c  01       927  0x39f00    256  HDFDU784870331
  3  00   122c  05       967  0x3c700   1280  HDC5F583861117
  4  00   12fa  31      1173  0x49500  12544  HDC5E984870331
  5  01   17a2  27      1601  0x64100   9984  HDC5V683861117
  6  01   1fa4  29      2019  0x7e300  10496  HDC50584870331
  7  01   270e  2d      2285  0x8ed00  11520  HDC5X383851212
  8  00   2db0  03      2503  0x9c700    768  S24W1683851212
  9  00   30d6  17      2697  0xa8900   5888  S24W2583851212
 10  00   34d6  1d      2905  0xb5900   7424  S24M5483851212
 11  00   38d6  23      3113  0xc2900   8960  S24X1183860616
 12  00   3cd6  29      3321  0xcf900  10496  S24WD083860616
 13  00   40d6  2f      3529  0xdc900  12032  S24MA183861117
```

## Generated disassemblies

Repository-local disassemblies:

```text
re/disassembly/diagnostics/go363/diskG_HDC5F5_3c700_3cc00.dis
re/disassembly/diagnostics/go363/diskG_HDC5E9_49500_4c600.dis
re/disassembly/diagnostics/go363/diskG_HDC5V6_64100_66800.dis
re/disassembly/diagnostics/go363/diskG_HDC505_7e300_80c00.dis
re/disassembly/diagnostics/go363/diskG_HDC5X3_8ed00_91a00.dis
re/disassembly/diagnostics/go363/diskG_S24W16_9c700_9ca00.dis
re/disassembly/diagnostics/go363/diskG_S24W25_a8900_aa000.dis
re/disassembly/diagnostics/go363/diskG_S24M54_b5900_b7600.dis
re/disassembly/diagnostics/go363/diskG_S24X11_c2900_c4c00.dis
re/disassembly/diagnostics/go363/diskG_S24WD0_cf900_d2200.dis
re/disassembly/diagnostics/go363/diskG_S24MA1_dc900_df800.dis
```

The useful shared HDC5 runtime was not isolated by the catalogue entry alone. Raw
opcode scanning for GO363 register constants found dense low-level code at:

```text
re/disassembly/diagnostics/go363/diskG_common_HDC5_runtime_1a400_1ca00.dis
re/disassembly/diagnostics/go363/diskG_common_HDC5_more_1d400_1f400.dis
```

These two files are currently the best protocol source.

## Embedded HDC5 routine names

The disk-G binaries contain these HDC5 runtime signatures:

```text
HDC5_CONTRES~W
HDC5_VECTOR~WW
HDC5_PROINT~WW
HDC5_STATUSFLAG~WP
HDC5_STATUS~WP
HDC5_PROPEAK~WW
HDC5_DMACAR~WW
HDC5_TIMER~WW
HDC5_CONTRINIZ~WP*WWWWWWWWWW
HDC5_GENINT~W
HDC5_HOME~WW
HDC5_SEEK~WWP*WWWWW
HDC5_LOAD~WLW
HDC5_STORE~WLW
HDC5_CORECC~W
HDC5_TESTPLO~WWP*LWWWWWWWWWWW
HDC5_READ~WWP*LWWWWWWWWWW
HDC5_WRITE~WWP*LWWWWWWWWWW
HDC5_VERIFY~WWP*LWWWWWWWWWWW
HDC5_FORMAT~WWP*WWWWWWWWW
HDC5_READLONG~WWP*WWWWWWWWWW
HDC5_WRITELONG~WWP*WWWWWWWWWW
HDC5_VERIFYLONG~WWP*WWWWWWWWWW
HDC5_READID~WWP*LWWWWWW
HDC5_VERIFYID~WWP*WWWWWW
HDC5_TIMESEEK~WWP*WWWWW
HDC5_TIMEROT~WWP*WWWW
```

`HDC505` adds private board-test routines:

```text
HDC5P_PORES~W
HDC5P_RFIFO~W
HDC5P_WFIFO~W
HDC5P_CONTIMER~WWW
HDC5P_CONTIMEB~WWW
HDC5P_CONTMREND~W
HDC5P_LOAD8W~WLW
HDC5P_STORE8W~WLW
HDC5P_LOAD8WEND~W
HDC5P_STOR8WEND~W
HDC5P_TIMEDMAL~WL
HDC5P_TIMEDMAS~WL
```

The same binary has a display/name table for these routines:

```text
CONTIMER  CONTMREND RFIFO     WFIFO     LOAD8W    STORE8W   TIMEDMA
STOR8WEND LOAD8WEND
```

These names align directly with `HDC505` tests 3-5.

## Port addressing convention

The HDC5 common runtime follows the same general governo addressing pattern as
other boards:

```asm
ldb     rh2,<<4>>0x016d    ; slot/select high byte
ldb     rl2,#REG           ; low-byte register
in/out  ...,@r2
```

So `r2` is the actual I/O port:

```text
r2 high byte = selected GO363 slot
r2 low byte  = GO363 register
```

## Definite register anchors from ROM and diagnostics

These are backed by both the ROM handler and disk-G HDC5 runtime:

```text
0x80  DMA/address counter low path
0x82  DMA/address counter high path
0x83  command/DMA start strobe
0x90  status register
0xaa  vector setup path in ROM; disk runtime also has a vector-programming path
0xb0  NEC/uPD7261 command + control latch
0xe0  drive/cylinder/head/parameter select path
0xe1  secondary drive/cylinder/head/parameter byte path
```

Additional diagnostic-only/private-test registers seen in disk G:

```text
0x00..0x03  result/status bytes read after HDC command completion
0x10        DMA/test control path
0x20..0x23  DMA/FIFO/timer setup path
0x40..0x57  HDC5P DMA/timer/FIFO private test path
0x70        control/clear path used around commands
0xc0..0xc3  8253 timer channels/control
0xd0        error/result latch written on nonzero completion
0xe3..0xe5  HDC5P private FIFO/test ports
0xe9,0xef,0xf4,0xf7,0xf8,0xfb  HDC5P private init/status/test ports
```

The diagnostic-only ports need more work before naming. They are definitely used
by `HDC505` private tests, but not all are part of the ROM boot path.

## Low-level disassembly anchors

### Controller init/status

Flat `0x1a59c..0x1a5f2` is a controller-init/status sequence:

```asm
1a59c  rl2=0xe0; out r3
1a5a0  r9=0x0b10 or 0x0310 depending on r3 bit 0
1a5ac  rl2=0xb0; out r9
1a5b0  r9=0x0810; out r9
1a5b6  rl2=0x90; read status several times
1a5c2  clear bit 11 of r9; out to 0xb0
1a5c8  out 0 to 0xb0
1a5cc  require status bit 0 clear, else error 0x14
1a5d8  read 0x90; require bit 2 set and bit 3 clear
```

This is a good candidate for `HDC5_CONTRINIZ` or a subroutine used by it.

### Command latch and strobe

Observed command/strobe patterns:

```asm
1a60e..1a642:
  write 0xe0
  write 0x0910 to 0xb0
  clear bit 11 then bit 4 in the command word, writing 0xb0 after each change

1a672..1a68a:
  write two selector bytes through 0xe0/0xe1
  write 0x0a18 to 0xb0
  write 0x0a18 to 0x83

1a696..1a6a4:
  write parameter through 0xe0
  write 0x0218 to 0xb0
  write 0x0218 to 0x83

1a784..1a79a:
  read 0x90
  if needed, write 0x0208 to 0xb0 and 0x83
  poll 0x90 bit 1
```

The ROM already suggested `0x09` = SEEK and `0x0a` = READ. The diagnostic
sequence confirms the high byte of the word written through `0xb0` is the HDC
operation code, while low bits are board-control/strobe bits.

### DMA/address counter

Flat `0x1a64c..0x1a65a`:

```asm
rl2 = 0x80
rr4 >>= 1
out r5 -> 0x80
rl2 = 0x82
out r4 -> 0x82
r7 = 0
```

This is strong evidence that the GO363 DMA/address counter is word-addressed on
the system side: the address is shifted right by one before programming the board.

### Timer/DMA setup

Flat `0x1a6d4..0x1a73e` programs a multi-register DMA/timer transfer:

```asm
0x20,0x21,0x22,0x23  setup words/bytes
0x10                 setup word
0xc3/0xc0            8253 control/channel 0 sequence
0xc3/0xc1            8253 control/channel 1 sequence
0xc3/0xc2            8253 control/channel 2 sequence
0xb0                 command word 0x0d25 or 0x0d22, then set bit 3
0x70                 control value 0x83/0x81/0x87
```

This aligns with `HDC505` test 4, "TEST 8253 TIMER & DMA TRANSFER LOGIC".

### Status decode

Flat `0x1a7f4..0x1a88c`:

```asm
read 0x90 into r1
poll helper at 0x1a892
status bit 14 -> error/result 0x20
status bit 13 -> error/result 0x21
other result bits in r3 are decoded into 0x01,0x03,0x02,0x15,0x05,0x04
read result/status bytes from 0x00,0x01,0x02,0x03
pulse/control 0x70 with 0x1f then 0
store decoded result words in caller buffer
```

### Interrupt/DMA arbiter use

Flat `0x1ade4..0x1ae30` and `0x1c45c..0x1c494` are interrupt service paths. Both
wrap controller/DMA completion handling with UC arbiter strobes:

```asm
outb #0xff84,rl0
ei vi
...
outb #0xff8c,rl0
iret
```

This matches the disk-A arbiter interpretation: `0xff84` opens/requests a DMA or
controller service window, `0xff8c` closes/releases it.

### HDC5P private tests

Flat `0x1c4ac..0x1c820` uses the diagnostic/private register group:

```asm
0xff  type/status read, compared with 0x60 in this path
0xf8  command/test selector writes 0x82/0x88/0x8c/0x84/0x8e/0x8a
0xf7  clear/write 0
0xe4/0xe5  handshake/status paths
0xe3  FIFO byte stream path via outib
0xef/0xe9/0xfb/0xf4  init/status paths
```

More specific anchors:

```asm
1c4ac:
  read 0xff, require 0x60
  write 0xf8 selectors 0x82/0x88/0x8c/0x84/0x8e/0x8a
  clear/control through 0xf7, 0xe4, 0xef, 0xe9
  read 0xfb and 0xe1 status

1c53a:
  write byte to FIFO/data port 0xe3
  pulse/control 0xe4 with 0xf5, 0xf3, 0xf8
  poll 0xe5 bit 4, timeout -> error 0x43

1c572:
  poll 0xe5 bit 5, timeout -> error 0x44

1c588:
  wait for 0xe5 status mask 0xd8 == 0x50
  stream bytes with outib to 0xe3

1c5ca:
  wait for 0xe5 status mask 0xd8 == 0x10
  stream bytes with outib to 0xe3

1c5ea:
  wait for 0xe5 status mask 0xd8 == 0x90
  stream bytes with inib from 0xe3

1c636:
  load address from caller buffer
  shift right by one
  write bytes through 0xf1, 0xf2, 0xf4

1c64c..1c716:
  select transfer/test modes with 0xf7 values 0x81/0x88/0x89/0x8a
  prepare six-byte command/FIFO records
  perform FIFO write/read handshakes and timer/status reads

1c7a8:
  select 0xf7 = 0x8c
  send command byte 0xc2, six-byte FIFO phase, then ten-byte phase
```

The `1c636` address setup is independent evidence that the private HDC5P DMA
path is also word-addressed. These routines are still best kept out of the
minimal ROM boot model until the `HDC505` caller mapping is complete, but the
FIFO/status/control behaviour is now fairly concrete.

## Current GO363 model

Defensible model so far:

1. GO363 is a host-driven ST506 HDC board, not an intelligent controller.
2. The board contains a uPD7261-compatible HDC, local 8253, local 8K SRAM buffer,
   20 MHz clock, gate-array/glue logic, and line drivers.
3. Host I/O is slot-windowed: slot/select in the high byte, register in the low
   byte.
4. ROM boot uses a small subset: DMA/address counter `0x80/0x82`, start `0x83`,
   status `0x90`, command/control `0xb0`, drive/CHS `0xe0/0xe1`, vector setup
   `0xaa`, and UC arbiter gating.
5. Disk-G `HDC505` exposes the broader board-test interface, including NEC FIFO,
   local 8253, board RAM, DMA timing, and address-counter tests.
6. DMA/system addresses are word-addressed (`addr >> 1`) when programmed into the
   controller; this is visible in both the common HDC5 path (`0x1a64c`) and the
   private HDC5P path (`0x1c636`).
7. The word written to `0xb0` is structured as high-byte HDC operation code plus
   low-byte board control/strobe bits; many commands are also written to `0x83`
   to launch the operation.

## Drive geometries

GO363 does not imply one disk geometry.  The concise Functional Checks manual
lists WREN1/XU1707 (27 MB), WREN2/XU1709 (65 MB), Micropolis 1325 (65 MB),
XM5221 (20 MB), WREN2 downgraded (40/41 MB), Micropolis 1323/A (40 MB), and
NEC5126H as supported ST506 units.

The S24 programs on diagnostic disk G contain `UNITDESC` tables.  Their first
two words establish the last physical cylinder and last head (both zero based):

```text
drive             last cyl  last head  physical geometry
WREN1/XU1707       0x02aa    0x0004     683 x 5
WREN2/XU1709       0x038b    0x0008     908 x 9
Micropolis 1325    0x03ee    0x0007     1007 x 8
XM5221             0x025f    0x0003     608 x 4
WREN2 41 MB        0x0346    0x0005     839 x 6
Micropolis 1323/A  0x03ee    0x0004     1007 x 5
```

These are physical diagnostic/format geometries, not necessarily the logical
geometry placed in CHD metadata.

The MOS `StarterST506.IMD` identifies its target in `$INFO` as an M44 two-WS,
two-system-partition **40 MB** configuration.  ROM release 6.0 selects the
40 MB logical geometry as **425 cylinders, 12 heads, 32 sectors per track,
256 bytes per sector**.  This is 163,200 sectors / 41,779,200 bytes.  The MOS
installation manual's usable first-volume value is 41,234,944 bytes; the
difference is reserved disk space and does not change the CHD geometry.

Create a suitable empty CHD with:

```sh
./chdman createhd -o m40-40mb-empty.chd -chs 425,12,32 -ss 256
```

The WREN2-41M physical table (839 x 6 x 32) describes the same capacity class
before the controller/driver's logical remapping.

## Next work

1. Build a call map from the HDC5 signature names to the flat addresses in
   `diskG_common_HDC5_runtime_1a400_1ca00.dis`.
2. Map `HDC505` menu tests 1-5 to exact call sequences, especially which
   `1c4ac..1c820` routines correspond to `PORES`, `RFIFO`, `WFIFO`, `LOAD8W`,
   `STORE8W`, and `TIMEDMA`.
3. Decode `0x90` status bits by collecting every test/error-message branch.
4. Decode low byte of `0xb0` command/control words (`0x10`, `0x18`, `0x08`,
   `0x25`, `0x22`) against observed strobes and completion status.
5. Compare ROM handler `0x1e58` with the disk-G common runtime to separate the
   minimal boot path from diagnostic-only test paths.

## Archive manual record

The local file `reference/ArchiviOlivetti/M30-M40_HDC.pdf` is not a scan of the
controller manual.  It is a four-page PDF printout of an Olivetti archive
catalogue page.  The catalogue nevertheless identifies the missing primary
source precisely:

```text
M30-M40 Hard Disk Controller. Theory of Operation
date:                  10/1982
archive item:          71680
numero definitivo:    806
original publication: M.005.48
location:              V-C-I-3-6
language:              English
```

The catalogue record did not advertise an attached scan.  Attempts on
2026-08-13 to retrieve the former item URL returned HTTP 404, and web searches
found the record metadata but no corresponding backend-media PDF.  Do not
mistake the four-page local PDF for the theory manual in future work.

## ROM 6.0 discovery result format

The ROM 6.0 code at `0x21d4`, `0x250a`, `0x2514`, `0x25e6`, `0x261c`, and
`0x2640` establishes that GO363 query results are one active-low byte in the
low byte of the word read at port `0x80`:

```text
command 02, parameter 68:
    result is complemented
    decoded high nibble is saved as the logical head count
    decoded low nibble is saved separately

command 02, parameter 88:
    result is complemented and saved as a word
    decoded value 2 selects ROM constants 621 and 58
    every other value selects ROM constants 425 and 32
```

The confirmed 40 MB logical geometry is 425 cylinders, 12 heads, 32 sectors.
Consequently, a 12-head 40 MB unit must initially answer:

```text
02/0068 -> 3f   ; complement c0: high nibble 12, low nibble 0
02/0088 -> fe   ; complement 01: 40 MB geometry class
```

The previous experimental `ffef` result for parameter `0088` was not supported
by the ROM and has been removed from the emulator.

### Command 0a / selector 50xx

The `0a/50xx` unit probe is now decoded from ROM `0x1dfe..0x1e2c` and confirmed
by an emulator trace.  The ROM preserves each requested byte on the stack,
complements the returned byte, and requires the decoded result to equal the
request.  It alternates each one-bit value with its complement, shifts the bit,
then finishes with `00` and `ff`:

```text
01 fe 02 fd 04 fb 08 f7 10 ef 20 df 40 bf 80 7f 00 ff
```

Therefore, for the word written as `50xx` by the CPU, GO363 returns the active-
low byte `~xx`.  Due to the two word writes and byte exchange in ROM `0x24d4`,
the card's assembled parameter appears as `xx50`, so the implementation uses
the high byte of its parameter latch.  The complete sequence reached `50ff`
without the old discovery error and the ROM then probed units 2, 3, and 4.

### Bus byte placement

The L1 bus turns a word access at an even I/O address into byte callbacks for
that address and the following address.  Thus a word read at board port `0x80`
calls GO363 registers `0x80` (high byte) and `0x81` (low byte).  ROM `0x2610`
masks the returned word with `0x00ff`, proving that the query result belongs at
register `0x81`; register `0x80` is the other byte of the word.

## 2026-08-13 emulator traces

### Console IPL switch

The UC board's physical IPL selector is now a persistent MAME configuration
option: **Machine Configuration -> Console IPL Switch**.  It defaults to
**ISL1 - Hard Disk**; choose **ISL2 - Floppy Disk** when booting the MOS starter
disk to initialize or install a GO363 hard disk.  The selected value supplies
bit 1 of the UC NMI/status register, which is where the REL 6.0 ROM reads it.

### MOS `StarterST506` rerun after the GO280 diagnostic fixes

The normalized 77-cylinder `StarterST506.IMD` was rerun with ROM 6.0, ISL2
(floppy IPL), GO363 in slot 5, and a disposable empty CHD using the confirmed
425/12/32/256 geometry.  The result is unchanged: the ROM reads GO363 ID `65`
three times, but neither the ROM nor the disk-loaded code issues any other
GO363 register access.  The CHD remains byte-identical and video remains blank.

A passive CPU-state sample shows that floppy loading does reach disk-resident
code (for example segment `3c`, PC `3c0ce0`) at about 33 emulated seconds.  At
about 37 seconds execution loses its valid control flow and repeatedly enters
segment-0 ROM/trap addresses (`00d0..00f0`) and uninitialized segment-0 RAM near
`a61c/a718`, while the stack offset runs through the address space.  Therefore
the current blocker precedes MOS hard-disk initialization: it is a control-flow,
MMU, or loaded-runtime failure, not a rejected GO363 command or wrong CHD
geometry.

### HDC505 loading attempt

The diagnostic was run without displacing the floppy controller:

```sh
M40_KEYS='\n1\n006\n' \
M40_KEY_DELAY=80 \
M40_INTER_KEY_DELAY=1 \
M40_SCREEN_INTERVAL=2 \
M40_TRACE_LOG=/tmp/m40-hdc505-run.log \
./m40 m40 \
  -slot5 go363 \
  -flop1 /tmp/G.IMD \
  -autoboot_script /tmp/mame_m40_diag_trace.lua \
  -window -nomaximize -sound none -seconds_to_run 130
```

The monitor accepted the keystrokes and attempted a disk load, reaching PCs in
the `0x0002bxxx`/`0x0002cxxx` floppy-loading path, but it did not enter HDC505.
The selected screen segment was blank.  This repeats the earlier loader issue
rather than exercising GO363, so the static HDC505 extraction remains the
current diagnostic source.

### HDC505 loading resolved

The failed `006` load was not an invalid program code.  Disk G's library MAP
confirms `006.HDC505`; the monitor requests the library through logical floppy
unit 4.  With GO280 drives 3 and 4 populated and the same disk G mounted in
drive 4, HDC505 loads and executes.  Its defaults are GO363 slot `3`, physical
unit `0`, and no sector-buffer display.

Live HDC505 test 1 established that GO363 register `0xff` must return `0x65`.
After correcting the old `0xe4` value, test 1 advances into test 2.  Test 2's
observed diagnostic interrupt sequence uses registers `0x10`, `0x42/43`,
`0x48/49`, `0x4a/4b`, `0x4c/4d`, and `0x6f`; command word `0x0b00` is the
interrupt-generation command.  `PRIN0` is reported clear when this command
does not set the diagnostic interrupt-pending indication.

### HDC505 tests 1 and 2: board ID and diagnostic interrupts

The live diagnostic and an instruction trace of the loaded segment establish
the following details without relying on guessed register names:

```text
register ff read        board physical/logical name, must be 65
register 4a write       interrupt vector
register 4a/4b read     board status word
register 48/49 write    diagnostic data/FIFO word
register 4c/4d write    HDC5 command word
command 03              VECTOR
command 04              PROINT
command 0b              GENINT
command 39              diagnostic reset/clear
```

Before a command, status register `4b` bit 3 must be clear.  This is a separate
condition from `PRIN0`; treating bit 3 as the pending indication makes the
common HDC5 pre-command check fail.  After `GENINT`, HDC505 polls `4b` bit 5
(`0x20`) for `PRIN0`, then requires `(status & 0x2f) == 0x28`.  Thus the observed
post-command status is `0x28`: bit 5 is the pending request and bit 3 is the
command-complete/status qualifier.

Test 2 deliberately exercises both interrupt-output states:

1. `GENINT` sets `PRIN0`, but VI must remain disabled.
2. `PROINT` command `0400`, with diagnostic data word `0003`, enables the
   interrupt output.
3. A second `GENINT` sets `PRIN0` and asserts the L1 vectored-interrupt line.
4. The interrupt handler acknowledges the request by writing low byte `02` to
   register `49`.  Its high byte is scratch data and was observed as `42`, so
   the acknowledge must be decoded as `xx02`, not only `0002`.

This explains both diagnostic failures used during bring-up:

```text
WITH ENIRO=0 INTERRUPT ENABLED   VI was asserted before PROINT
WITH ENIRO=1 INTERRUPT DISABLED  PROINT had run but GENINT did not assert VI
```

The MAME model now keeps the board-pending state (`PRIN0`) separate from both
the PROINT enable and the asserted VI line.  The handler's `xx02` acknowledge
deasserts VI but leaves PRIN0 visible for the diagnostic's post-handler poll.
A full sequence run confirms that tests 1 and 2 pass.  Test 3 has now established
the direct uPD7261 register path as well.  The common `HDC5_CONTRINIZ` routine:

```text
reads NEC status through byte port 11 (the odd-address word precheck spans 10/11)
writes the eight SPECIFY bytes through FIFO/data port 01
writes NEC command 20 (SPECIFY) to byte port 11
writes board command 0a00 through 4c/4d
waits for board status 28, then reads NEC status 40 from port 11
```

The observed SPECIFY record is:

```text
58 b0 00 03 1f 0d 00 80
```

The uPD7261 completion request must set the same board-visible `28` status used
by the diagnostic request, while its VI output remains gated by PROINT.  Exposing
the raw controller interrupt directly caused a segment trap; exposing only bit 3
left the diagnostic polling indefinitely.  With the controller request mapped to
`28`, `HDC5.CONTRINIZ` completes.  The remainder of test 3 establishes this
private FIFO exercise:

```text
NEC auxiliary 08/02 through odd word port 11 clears completion and FIFO state
six bytes are written through data port 01
board command 4500 (HDC5.WFIFO) exposes those bytes for readback
six bytes are read through data port 01
board command 4400 terminates HDC5.RFIFO
```

The cleanup sequence proves that word writes at odd port `11` place NEC
auxiliary-command bytes on both decoded byte positions `10/11`; both positions
therefore need to reach the uPD7261 command register.  Modelling auxiliary clear
and the six-byte diagnostic FIFO readback makes HDC505 tests 1 through 3 pass.
The original test-4 boundary was:

```text
4) TEST 8253 TIMER & DMA TRANSFER LOGIC
COMMAND NOT CORRECT= HDC5.CONTIMER
DIAG.COD(EX-VALUE) CMD START=41 END=41
NOT GENERATING INTERRUPT ( PRINO = 0 )
COMMAND NOT CORRECT= HDC5.TIMEREND
DIAG.COD(EX-VALUE) CMD START=41 END=1C
```

Subsequent live-code tracing resolves much more of this path.

### Test 4: the two distinct 8253 timers

The private HDC505 routines loaded at logical segment `21` show that test 4
uses both the GO363-local 8253 and the UC042 8253. They must not be conflated.

`HDC5P_CONTIMER` command `4100` loads the GO363 timer through private ports:

```text
57 <- 36        counter 0, LSB/MSB, mode 3
46 <- count 0   little-endian bytes
57 <- 70        counter 1, LSB/MSB, mode 0
47 <- count 1   little-endian bytes
48/49 <- 0002, 00c0, 000d
4c/4d <- 4100
```

The first two observed cases are `0004 × 0001` and `0004 × 0002`. Completion
is polled through `PRIN0` (`4b.5`) and both cases pass in the current model.

Command `4000` uses a long GO363 load, `fffe × 000f`, and then installs and
starts a separate UC timer interrupt. The relevant live routines are:

```text
2115f6  install UC timer vector handler 211630 and write vector to FF01
211688  UC PIT: 34/0010 to FFC7/FFC1, 70/ffff to FFC7/FFC3;
        EI VI; write FF8C to enable VI
211630  UC timer ISR: write 70 to FFC7, restore vector, TSET A200:0b30, IRET
2116bc  latch/read UC counters and restore the former vector
```

The caller at `210f3c` polls both GO363 `PRIN0` and `A200:0b30`.  The normal
GO363 VI handler at `211972` acknowledges the board with data `0002` and stores
the delivered vector in `A200:0b30`.  If `PRIN0` is seen first, execution jumps
straight to cleanup and preserves that vector.  If the UC watchdog changes the
word while `PRIN0` is still clear, the foreground writes the failure sentinel
`0f0f` there.  The caller at `21848e` explicitly rejects that sentinel.

This establishes the required ordering: loading the GO363 8253 starts it, as on
a real 8253.  Its terminal count must set `PRIN0` and raise VI while VI is still
enabled.  The later private command `4000`/`4100` reports or finishes the test;
it does not start the counter.  Starting the emulated timer on that later command
made it expire only after cleanup at `2116bc` had executed `DI VI`, so status
became `28` but no handler could run.  That single sequencing error accounts for
the formerly puzzling combination of a working `PRIN0` and the final
`NO INTERR. AFTER 8253 STARTS COUNTING` failure.

The per-run interrupt selector is carried in the high byte of the `xx02` write
to `48/49`: the two short polling cases write `0002`, while the long interrupt
case writes `ff02` (followed by `ffc0` and `ff0d`).  Latching timer interrupt
enable from `ff02` is essential.  Treating every terminal count as interrupting
causes an unwanted vector during the first `0004 × 0001` load; waiting for the
future `4000` command misses the interrupt because terminal count precedes that
command.  `0040` clears both the timer-pending and timer-interrupt-enable latches.

The separate UC delay/watchdog path was also verified: UC OUT1 rises, vector
`30` is acknowledged, handler `211630` runs, and the polling loop exits. This
exposed a UC emulation bug: changing the arbiter's VIENO latch did not recompute
the CPU VI input. Calling `update_vi()` after `FF80..FF8F` writes fixes that path.

The GO363 model now routes private timer ports `46/47/56/57` and aliases
`c0..c3`, records the two cascaded counts, and provisionally schedules terminal
count from the board's photographed 20 MHz oscillator as a single event; the
exact PIT divider still needs schematic or timing evidence. A single event
is intentional: driving MAME's PIT cascade edge by edge with the diagnostic's
very small divider creates millions of unobservable scheduler callbacks.

The model now schedules the cascaded terminal count when counter 1's complete
LSB/MSB value is loaded.  The callback always sets the timer-status latch and
asserts the normal board interrupt latch when enabled by `ff02`; VI acknowledge
clears the latter through the same path as ordinary GO363 command completion.
The photographed 20 MHz oscillator remains the provisional clock source; its
exact divider awaits schematic or timing evidence.

This was confirmed with HDC505 test 4.  The two `4100` polling cases complete
without a VI.  The `fffe × 000f` case reaches terminal count, acknowledges GO363
vector `30` at foreground PC `210f76`, and leaves `A200:0b30 = ffff` rather than
the rejected `0f0f` sentinel.  The diagnostic no longer stops at test 4 step 3
and advances into the following test.

### ROM discovery with an attached empty CHD

After changing the `02/68` and `02/88` responses to `3f` and `fe`, ROM 6.0 was
run with:

```sh
./m40 m40 \
  -slot5 go363 \
  -hard1 /tmp/m40-40mb-empty.chd \
  -autoboot_script /tmp/m40_go363_state.lua \
  -window -nomaximize -sound none -seconds_to_run 35
```

This run advanced beyond the former repeated controller/unit discovery failure.
At the state snapshot:

```text
PC       00001292
RAM 0270 03 00 00 00 ...
RAM 0334 02 07
RAM 034c 00 03
```

`0x0270 = 03` and `0x034c = 0003` are materially different from the earlier
failed discovery state and show that the corrected packed result is being
consumed.  The ROM subsequently emitted repeating console values
`31 43 f4 1f`, which are not yet decoded.  This is progress through discovery,
not proof that sector I/O or booting works.

After implementing the active-low echo for `0a/50xx`, the trace showed the full
probe sequence listed above, followed by controller initialization attempts for
units 2, 3, and 4.  Those absent units were skipped using status bit 0.  ROM then
returned to unit 1 and advanced to the boot path; the console error pattern
changed to `31 13 f1 1f`.  This locates the next failure after unit discovery,
where sector transfer is still unimplemented.

### Unit field in E0/E1

The selected unit is the low byte of the assembled E0/E1 parameter, not the
whole word.  Initial discovery uses `0001` through `0004`, but the later unit-1
initialization writes `0701`; `07` contains flags.  Treating only whole-word
values 1 through 4 as unit numbers left absent unit 4 selected and caused a
false status-bit-0 error.  Selecting from the low byte allowed ROM to continue
to the `02/68` geometry query and transfer setup.

### First boot transfer

With unit selection corrected, the first boot attempt produced this sequence:

```text
02/0068 configuration query
DMA word address: 00047600 (physical byte address 08ec00)
0a/0000 positioning command
09/0000 seek sequence

port 20 <- 0000   head 0
port 21 <- 0001   sector count 1
port 23 <- 0000   cylinder 0
port 22 <- 0000   cylinder with exchanged bytes
port 10 <- 0000   sector 0

8253 setup through c0..c3
B0 <- 0d25
B0 <- 0d2d        bit 3 set
70 <- 0083        starts read/DMA transfer
```

The field names are also established by ROM `0x1fce..0x1fe2`, which loads the
request as cylinder word, head byte, sector byte, and count before calling
`0x2536`.  The disk LBA calculation for the logical CHD is therefore:

```text
LBA = ((cylinder * CHD_heads) + head) * CHD_sectors + sector
```

The system DMA address programmed at `80/82` is a word address and is multiplied
by two before L1 physical RAM access.

There is an important Z8001/L1 alias at logical ports `82` and `83`: a word
write to odd command-strobe port `83` reaches the same two byte callbacks as an
even word write to DMA-high port `82`, but with exchanged bytes.  The wrapper
must assemble the word first.  If it equals the command latch it is a command
strobe and must not alter DMA; otherwise it is the DMA high word.  Before this
was fixed, auxiliary `0208` and positioning `0a18` commands silently corrupted
the address counter.  The internal post-fix trace confirmed:

```text
read C=0 H=0 S=0 count=1 LBA=0 DMA=08ec00
```

The exploratory implementation currently reads `count` sectors from the CHD
and writes their bytes sequentially to L1 physical RAM.  It only implements the
observed read path (`0d25`/control `83`) and is a host-level board model; the
GO363-to-uPD7261 FIFO translation still needs to replace or validate it.

One traced run crashed in `lua_gettop` from MAME's Lua read-tap callback after
DMA completion.  The macOS crash report showed the Lua tap stack, not GO363 or
hard-disk code.  The identical transfer without Lua taps ran to completion, so
this was trace-hook reentrancy/lifetime trouble and must not be recorded as an
emulated-machine crash.

## Current implementation boundary

The GO363 emulator model currently has the physical devices (uPD7261, 8253,
two hard-disk image slots), L1 identification, basic command/status/result
latches, the HDC505 diagnostic pending/PROINT/VI path, vector/VI completion,
the experimental ROM-protocol responses above, and an
initial CHS-to-CHD read/DMA path.  In particular:

- GO363 gate-array to uPD7261 FIFO/status translation is not connected;
- local 8 KiB SRAM is not modelled;
- read DMA currently uses direct L1 physical writes rather than timed bus
  request/grant cycles;
- write, verify, and remaining transfer modes are not implemented;
- the 8253 private register aliases, cascaded terminal-count timing and
  `ff02`-controlled timer interrupt latch are modelled; the exact oscillator
  divider remains provisional;
- HDC505 tests 1–4 pass; test 5 is the next implementation/debugging boundary.
- **3 October 2026:** on the current build HDC505 fails test 2 (`UNSE0`, `SKEN0`,
  `UPR00` stuck at 1 after the run command); see `doc/MAME_DRIVER.md` §9.

The next useful step is to trace the first boot read after the successful unit
enumeration, then implement the uPD7261 data path and board SRAM/DMA rather than
adding further fabricated query values.

## Findings from the HDC5X3/ERMAP and Standard 24 runs (September 2026)

Kept from the working notes of those runs, which have been deleted. The
Standard 24 results themselves are in `doc/GO363_DCOS_RECOVERY.md`; the MAME
changes that let HDC5F5 format the disk are in
`re/evidence/upd7261-read-data-timing-evidence.md` and
`re/evidence/go363-format-id-buffer-evidence.md`.

**Disk size.** HDC5X3 writes the ERMAP service track at physical cylinder
924. The WREN2 image must therefore have at least 1024 cylinders; a
908-cylinder image (the `S24W25` `UNITDESC` geometry) has no cylinder 924
and ERMAP cannot complete on it. The project's WREN2 images are 1024 × 9 ×
32 × 256.

**Read ID.** Before Read ID, DCOS sends `SPECIFY` bytes
`18 b1 00 08 1f 0d 00 01`, then `PHN=00` and `SCNT=20`, then command `90`.
Mode `0x18` is soft-sector. The NEC manual says soft-sector Read ID returns
four ID bytes (`LCNH`, `LCNL`, `LHN`, `LSN`) per sector by DMA until SCNT is
exhausted; DCOS asks for 32 IDs. The model synthesises the IDs from the CHD
geometry, because a CHD keeps no physical ID marks.

**Known limits of the model.** Read ID on a formatted track returns
synthetic IDs, not the IDs DCOS wrote (DCOS writes IDs such as
`F3 97 00 nn`). Only the last formatted track's ID list is remembered for
VERIFY ID.

**Rejected change.** NEC printed page 6-20 (PDF page 18) gives
`INT = CEH + CEL + SRQ * !SRQM` and says a disk command clears CEH and CEL.
Recomputing INT on command acceptance was tested as the ERMAP fix and
rejected: the replay was identical (same dispatch, same wait-loop count, same
disk contents). Details: `re/evidence/upd7261-command-int-reset.experiment.md`.

**What fixed ERMAP option 1.** The uPD7261 buffered Seek/Recalibrate timing
(`re/evidence/upd7261-zero-distance-seek-timing.experiment.md`): with it, HDC5X3
option 1 certified the service track through all 200 write/verify cycles on
a 1024-cylinder image.

**DCOS HDC event sources.** The shared HDC runtime keeps an event selector
at `<<22>>9A59` and dispatches through a table at `<<21>>A660`:

```text
217FDE  ldb   rl1,<22>9A59
217FE8  ld    r1,<21>A660(r1)
217FEE  jp    <21>5B1E(r1)
```

Observed: source 1 → `0x217ff4`, source 2 → `0x218120` (the normal
controller-result path: board status, controller status, results), source 4
→ `0x218288`, source 5 → `0x2184e6` (scheduler/locking only). DCOS sets
source 5 deliberately before a SEEK (`216EB2`, `21654E`); it is the intended
first phase of a SEEK request, not a timeout classification.

**Disk G address map.** In those runs the shared HDC runtime was relocated so
that linear address = Disk G file offset + `0x17e400` (Disk G extracted with
`tools/imd.py … extract`). Checked against the image: the `ldb <22>9A59,#n`
source assignments are at file `0x99430` (1), `0x99468` (2), `0x99c8a` (2),
`0x99d72` (4) and `0x9a19c` (5), linear `0x217830`, `0x217868`, `0x21808a`,
`0x218172`, `0x21859c`. The catalogued `007.HDC5X3` entry at file `0x8ED00`
is not the code that executes. The ERMAP program body was noted at linear
`0x30000` = file `0x15300` (dispatcher and completion `0x15A00`–`0x16900`,
wait loop `0x165BE`/`0x165C6`, menu and error strings `0x9B3B0`–`0x9BD00`);
that mapping was not re-checked. Disassembly listings: `re/disassembly/diagnostics/go363/`,
in particular `diskG_common_HDC5_runtime_1a400_1ca00.dis` and
`diskG_common_HDC5_more_1d400_1f400.dis`.
