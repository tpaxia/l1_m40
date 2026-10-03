# Olivetti L1 (M30/M40) OSLEM / BCOS disk formats and debugging toolkit

Read this before reverse-engineering any L1 system floppy. Everything here
was established on real images (ALL_RESIDENT, K02743, oslem7+, probejsf,
ff1) during September 2026; items marked *observed* are consistent across
those images but not documented by Olivetti.

## 1. Tools

| Tool | Purpose |
|---|---|
| `tools/l1lib.py` | Library-level inspector (this document's formats): `info`, `boot`, `labels`, `modules [--sub]`, `dir`, `containers`, `config`, `extract NAME[/SUB]`, `find TEXT\|--hex`, `versions IMG...` |
| `tools/l1disk.py` | Sector-level IMD access: `L1Disk(path)`, `read(index, len)`, `write(index, data)`, `track0()`, `set_track0()`, `save(path)` (lossless round trip) |
| `tools/imd.py` | Raw IMD parser used by `l1disk.py` |
| `tools/z8kdisrom` | Z8000 disassembler: `z8kdisrom FILE START END` (hex offsets into FILE). Use on an extracted module or a runtime segment dump |
| `runs-archive/restore-hd-20260928/*.lua` | MAME harness scripts (section 9) |
| `runs-archive/restore-hd-20260928/build_*.py` | Examples of image surgery: `build_restore.py` (write data sets onto a WREN2 CHD), `build_allres_osg.py` (add modules + directory entries), `build_k02743_fmd.py` (redirect a directory entry) |
| `disk-analyse` (keirf Disk-Utilities, `/usr/local/bin`) | SCP flux → IMD conversion (IMD headers say "Created by https://github.com/keirf/Disk-Utilities") |

Quick start:

```sh
python3 tools/l1lib.py info IMG           # everything at a glance
python3 tools/l1lib.py dir IMG            # library directory, each entry checked
python3 tools/l1lib.py containers IMG     # driver/program containers
python3 tools/l1lib.py extract IMG HDII/E3#I -o e3i.bin
tools/z8kdisrom e3i.bin 0 186             # disassemble it
python3 tools/l1lib.py find IMG JMDU      # which module contains a string
python3 tools/l1lib.py versions A.imd B.imd --common
```

`extract` writes header + data. Code offsets in a disassembly of the
extracted file equal the offsets inside the module *and* inside its runtime
segment (modules are loaded with their header at segment offset 0).

## 2. Media layout (8" FDU, 77 cylinders, 2 heads)

- Track 0: head 0 FM 26×128, head 1 MFM 26×256 → `track0()` is 9984 bytes
  (head 0 then head 1).
- Data area: cylinders 1-76, MFM 26×256 per side. **Data index**
  `i = (cyl-1)*52 + head*26 + (sector-1)`, sectors 1-based; 3952 sectors.
  "flat" offsets in this document = `i*256`.
- Fill seen in unused areas: `E5` (formatted, blank), `@` (0x40), the text
  `-=[BAD SECTOR]=-` (real disk content on spare cylinders 75-76 of DKC£
  backup volumes, not read errors), `0xFF` on track 0 of backup volumes.
- IMD sector types 1/2 only (no CRC errors) on every image checked.

## 3. Track 0

| Offset | Content |
|---|---|
| `0x000` | `SYS0` + entry (`b9 00 00 14`/…) + name (`FDU0701`, `HDU1ST24`): IPL boot block read by the ROM |
| `0x080` | OS (IPL) descriptor, section 3.1 |
| `0x100` | descriptor copy on some disks (ALL_RESIDENT); `HDR1` label on others (K02743) |
| `0x200` | `ERMAP` |
| `0x300` | `VOL1` label (volume id, owner `OLIVETTI`, serial e.g. `WV 0750522561`) |
| `0x380…` | `HDR1` file labels (`HDR1 JJU033  00256 01001 25022 …` = name, record size, start/end cyl-head-sector), `DDR1` |
| DKC£ backup volumes | `0TOC` at `0x100` (data set id at `+0x20`, count at `+0x2C` = data sectors + 1), `SYSCO 03Cx` volume chain |

`python3 tools/l1lib.py labels IMG` lists them.

### 3.1 OS (IPL) descriptor at track-0 `0x80`

```
+00  MVO quad: four words, e.g. 0440-0540-0700-1800 (memory variable org.)
+10..+6F  up to six 16-byte module entries:
     [0:4]  entry address, segmented long form (byte0 = 0x80|segment)
     [4:8]  load address,  segmented long form
     [8:10] length (bytes)
     [10]   cylinder, [11] head, [12] sector (1-based) of the module HEADER sector
     [13:16] ff ff ff / 00
+70  tail: ff ff ff ff | u16 loader start (1-based data index) |
           '    OS**' | u16 library directory (1-based data index)
```

Slots seen: `+10` BOOT, `+20` start-up module `####` (only on the newer
releases), `+40` RTS driver container (`HDIR`/`H65R`/`HDUR`/`FUNR`), `+50`
INIT container (`HDII`/`H65I`/`HDUI`), `+60` OS loader (`JLD0` floppy,
`JLDH` hard disk). Examples: ALL_RESIDENT BOOT→39, HDIR→3B, HDII→38,
JLD0→03; tail `00a3 … 0001` (JLD0 at index 0xA2, directory at index 0);
oslem7+ tail `056e … 01f5` (directory at index 0x1F4).

The manual (3988331 Y p. 2-14, SMVO step of OSG£) names `JLD0` as the
default loader and `JLDH` "if loading is from HD". Having `JLDH` in a
floppy's descriptor does **not** make the floppy boot use the HD library:
`oslem7+` (`JLDH MX81`) booted from floppy reads its library from the
floppy (`LIB= .1F5`) even with an installed HD (OSLEM_STATUS 1E).
The load addresses here come from the disk, not the ROM: `JLD0`/`JLDH`
load at `03:0000` on ALL_RESIDENT, `oslem7+` and the HD boot set in FF
(descriptor at `HDU1ST24` `+0x100`, FF index 1, sector fields 32-bit).

## 4. Module header (first 0x20 bytes of a module)

```
+00  name (4)        '#' is the Olivetti '£' glyph (OSG# = OSG£, TOC# = TOC£)
+04  version (4)     usually text (A.02, 0E.3, MX81, 00D1); may be binary (H1SY, HA04)
+08  flag byte A     seen 00 01 02 08 0e 10 11 1e 80 81 88
+09  flag byte B
+0a  length (u16)    bytes of module data
+0c  u16             (repeats the length on 0x81 containers)
+0e  u16             preferred load segment (KER0 02, HDIR 3B, HDII 38, JLD0 03)
+14..+1f             entry/relocation words (observed): single-entry programs
                     keep the entry at +1c (OSG# 002e, SMV# 001e, TOC# 001e,
                     JX24 0024); multi-entry modules list several
                     (JERR 008e 00b8 0020 … 00b4 01fc; DIK# 01aa 01be 0022 …)
+1c                  containers: sub-module offset table (section 5)
```

A module occupies the header sector plus data sectors; tools use
`1 + ceil(length/256)` sectors, which was sufficient to copy modules
between disks (`build_allres_osg.py`). Code begins inside the header sector
(e.g. OSG# entry at +0x2e).

Module *families* by version string: A-series BCOS 3.3 / OSLEM (A.02 on
ALL_RESIDENT, A.04/A.4x on K02743), MX8x OSLEM 7 (oslem7+), 00Dx/000x
older numeric generation (probejsf ESE). Do not mix families without
checking (a grafted A.0 OSG# loaded but never ran under an A.02 kernel).

## 5. Containers

Rule (implemented in `Module.sub_offsets`): u16 table at `+0x1c`, ending
at a 0 word or where the table reaches the first sub-module (the first
table value); every entry points at a module header inside the container.
Sub-modules have the same header format.

| Kind | Examples | Sub-modules |
|---|---|---|
| Driver containers (RTS `…R`, INIT `…I`) | `HDIR/HDII` (integrated HDU), `HDUR/HDUI` (HDU via CFU), `FUNR/FUNI`, `H65R/H65I` (GO363), `HE4R/HE4I`, `H60x`, `H61x`, `GIPR/GIPI`, `INTR/INTI`, `MFDR/MFDI`, `FDUR/FDUI` | `xx#R` / `xx#I` per governo type: `FF` UC, `FE` video/keyboard, `E0` MFDU, `E1` FDU, `E3` floppy (GO280 path used here), `E4` GO230 HDU, `E6` STC, `EF` GIPO/DCU, `CF` twin RS232, `60`/`61`/`65` ST506-class HDU (65 = GO363) |
| Program containers | `DKDK` (DKC#, DKR#, COPY, MONT, LOG#, VSDK), `DKST` (SCT#, MONT, LOG#, VSDK) | named programs |
| Code with appended modules | `KIO0` (K02743: JMDU A.04, JH24 A.N4, JAPP A.03; oslem7+: JMDU, JAPP) | table ends with 0 |

Which HD governo types a system supports = the `xx#R` list of its RTS
container named in the boot descriptor (`l1lib.py containers`).

## 6. Library directory

Located by the descriptor tail word (`t0+0xFE`, 1-based data index). Entries
are 8 bytes: `name(4) start(u16) length(u16)`.

- `start` is 1-based and **relative to the directory sector**: header at
  data index `dir + start - 1` (dir = 0 on ALL_RESIDENT/K02743/probejsf,
  0x1F4 on oslem7+).
- Entry 0 is the library header: name = library id (`RE33`, `A04C`,
  `7.0+`), start field = total entry count, length field = observed last
  used sector (ALL_RESIDENT `04e6`).
- Specials at the end: `+DIR` (start `0080` = max entries, length = size),
  `+LOG`, `+ELG` (start has bit 15 set).
- Sub-modules are listed with their container's start sector (e.g. `FF#R`,
  `E3#R` → `HDIR`), so name ≠ header name for those.
- To add a module: write header + data sectors to free space, insert an
  entry before `+DIR`, increase the header count (`build_allres_osg.py`).

`l1lib.py dir` marks each entry `ok` (header of the same name at the
target) or `--` (sub-module, special, fill).

### 6.1 Hard-disk data set FF (from the `ff1`/`ff2` DKC£ backups)

Data set FF (OSLEM + BCOS on the WREN2) is laid out like a floppy data area
without track 0; index = FF volume sector − 1. Backup-volume images
(`ff1.imd`, `ff2.imd`) carry it contiguously from data index 0 (3848
sectors per volume; see `re/os/oslem/OSLEM_STATUS.md` 1D).

- Index 0: `SYS0` block `HDU1ST24` (HD boot stage; entry `0x00E0`); index 1:
  its OS descriptor (same entry format as section 3.1 but with 32-bit
  1-based sector numbers instead of C/H/S).
- Index `0x0B` and `0x13`: `0TOC` data-set table (two copies).
- Index `0x120` (= `TK0` of data set FF, the value MX24/TOC£ ask for):
  library directory `7.0+` (218 entries). `l1lib.py dir ff1.imd` finds it by
  scanning (no track-0 descriptor on backup volumes).
- HD addressing and the SSID `1EX` entry: `re/os/oslem/OSLEM_STATUS.md` 1D.

## 7. Configuration modules (`J0XP`, `J0X1`, `J0X9`, …)

Selected configuration is shown on the boot status page as `0XP=`. Layout
for versions `0E.3` / `000C` (`l1lib.py config`):

```
+20  five resident module names (4 each): KER0 KIO0 0FMD|0FMU MODR 0HDI ...
+34  8 zero bytes
+3c  mode module: MODD (ALL_RESIDENT, probejsf) / MOD0 (K02743)
+40  start program: SIM0 (BCOS /SYS), LOAD (EP60 P6060 emulator), blank
+44  u16 0001
+46  name: JH24 (HD configuration) or blank
```

`J0XP B6.0` (oslem7+) uses a different layout (resident list elsewhere;
from the runtime status page: `KER0 KIO0 MOD0 JPTC 1HDI 0FMU`).

Peripheral records in the configuration (e.g. type-65 device
`65 00 ff 00 … 2SCA 0HDI … DK`) are described in `re/os/oslem/OSLEM_STATUS.md` 1B.

### 7.1 `J0XP B6.0` peripheral-unit records and `COS#` (measured 2026-10-01)

In `J0XP B6.0` (data set FF index `0x63A`, `0xA00` bytes) the peripheral-unit
records are 32 bytes each and start at module offset `0x1B0` (keyboard first).
The layout below was measured, not inferred: every field of the keyboard
record was set to a marker value with `COS#` on a scratch disk and the saved
disk was diffed against the baseline (`install/cos-map/`). `COS#` rewrote only
those 32 bytes: the module header and the rest of the disk were unchanged, so
there is no checksum to maintain.

| Offset | Size | `COS#` field | Example (keyboard / hard disk) |
|---|---|---|---|
| `+0x00` | 2 | `PUNL` | `FE01` (governo type, unit) / `6500` |
| `+0x02` | 1 | `EMUN` | `01` |
| `+0x03` | 1 | `EMUS` | `00` (`08` on oslem7+; `FE` on the extra terminals) |
| `+0x04` | 2 | `BIT1` | `0000` (`0001` on oslem7+) |
| `+0x06` | 2 | `D1EQ` | `0000` (`234B` = `#K` on oslem7+) |
| `+0x08` | 4 | `MV0M` | blank / `65#R` |
| `+0x0C` | 4 | `DL2M` | blank / `2SCA` |
| `+0x10` | 4 | `DL0M` | `1KYB` / `1HDI` |
| `+0x14` | 4 | `VARM` | `KITA` (keymap) / blank |
| `+0x18` | 2 | `BIT2` | `0000` |
| `+0x1A` | 2 | `TBD.` | `0000` |
| `+0x1C` | 2 | `TYPE` | `KY` / `DK` (also `DY`, `PR`, `ST`) |
| `+0x1E` | 1 | `EREN` | `00` |
| `+0x1F` | 1 | `SPID` | `00` |

Running `COS#` (OSLEM "system configuration") on the HD-booted system:

1. At `/SYS`: LOCK on, Ctrl+J gives `0X - COMMAND :`.
2. Type the utility name alone, `COS#`, then keypad Enter. `EXEC COS#` does
   nothing visible; `TOC#` and `SMV#` behave the same way. Loading takes about
   30 s of emulated time.
3. `UNIT NR. 1H :` answer `1`. `PARAM. REF. 4A :` answer `J0XP`.
4. Pages: TIME SLICE INSIDE, TIME SLICE OUTSIDE, JLD0 DATA TABLE, NUM. ELEM.
   STACK, POOLS OUT SEG. 0, then one PERIPHERAL UNIT page per record (dozens:
   terminals `FE20`, `FE30`, …). `+` Enter = next page, `-` Enter = previous.
5. Edit on the current page with `FIELD value` and Enter, e.g. `VARM KUSA`,
   `EMUS 08`, `BIT1 0001`. The character after the four-letter field name is a
   separator (`VARMKUSA` stores `USA`). Hex fields take hex digits.
6. Empty Enter ends editing; Enter twice more accepts `CUR. PAR IS: J0XP` and
   `CUR. LIB IS: 0001`; `FUNCTION OK` means it was written.

Typing under the Italian map (`install/kita_keymap.txt`): `#` is the unshifted
`1 !` key (LOCK off) and is drawn as a blank; `M` is the `; +` key; `+` is the
`~ ^` key with LOCK on; `.` is the `,` key with LOCK on; `W`/`Z` are swapped.
`SMV#` is not peripheral configuration: it is "SET MV0 IPL DATA".

What the fields do, as far as tested: `VARM` on the keyboard record selects
the keymap (`KUSA` gives QWERTY; the map must be in the library: FF holds
`KITA`, `KUSA`, `KLIM`, `KBCS`). `EMUS 08` stops the driver from initialising
the keyboard, which leaves the BCOS user without a `KY` unit (`JMOP … MISS`).
`BIT1` and `D1EQ` alone changed nothing observable at boot.

## 8. Runtime (Z8001 segmented, observed)

Notation `SS:OOOO` = segment:offset; `00:xxxx` kernel data space. Program
space (code, PC-relative stores) and data space are separate for the
debugger: `wpset` = program, `wpdset` = data.

| Address | Meaning |
|---|---|
| seg 02 | kernel (`KER0`); `02:0912`-`091E` idle loop; `02:07AA` SVC entry |
| seg 03 | `JLD0` during start-up, later `KIO0` (segment reused!) |
| `00:00A4` | pointer to device/system table |
| `00:00A6` | current task control block |
| `00:00A8` | pointer; `[A8]+6` = logical-unit table base, 4 bytes/unit: flags word + device-block pointer. Init (JLD0 A.4A `03:0CB4`, A.02 `03:0BBE`): units 0-3 `0901`, 4 `0900`, rest `0100`; start-up sets bit 0 on units 2,3 |
| `00:00AC` | device list (MODD keyboard handler searches `+0x60` ids) |
| `00:00B2` | SVC dispatch table |
| `00:0102`/`0104` | system / second volume (written by JMDU) |
| `00:010E` | attention program name (`JATT`), `00:0116` error program (`JERR`), both set by JLD0 |
| `00:016C` | `0x83` = `0x80|segment 3` from JLD0's own address |

System calls (`sc #n`, observed use): `02` misc/echo, `07` wait,
`0D` load/start program by name (`rr2` = name, `r0` = function),
`10` task exit, `11` open module (`r0=3`), `12` get memory (`r3` size),
`14` I/O request (block with function word, e.g. `0102` read, device `C0`),
`15` attach device, `17`/`18` I/O wait/status, `19` error message,
`1A` driver function (e.g. `800A` mount check) / operator message,
`1C` wait.

Error codes seen: `C205` load via a unit with flags bit 0 and bit 8 set;
`C303` driver request with bit 8 clear; `C20B` unknown module
(`ERR.C20B UNKNOWN MODULE AT 26,0C2C … name`); `8305`/`NODK` (DIK£);
`/SYS ERR.152`, `ERROR 172` (EP60 start-up message, also on P6060 disks).

Mechanisms traced:

- **Attention (Ctrl+J)** → kernel calls `MODD`'s keyboard handler
  (descriptor `MODD+0x1FE`, entry `0x216` on A.02) → dispatch table
  `+0x2E6`: `'J'` → read `00:010E` (`JATT`) and start it → `0X - COMMAND :`.
  `'?'` loads `JCN?`. Works on ALL_RESIDENT; in probejsf the handler is
  never called.
- **On-demand program load** (`sc #0D`, newer releases; code in `MOD0`,
  segment 1D): `1D:1E24`, name hash `1D:20D0`, in-memory directory
  `1D:1F74`. Directory entry = `name(4) offset(u16) descriptor(u16) seg`;
  for KIO0's appended modules the offset is the sub-module offset inside
  KIO0 (`JMDU 2CD0 799C BB`, `JH24 33E0 799C`, `JAPP 370C 799C`).
  Descriptor (K02743 `00:799C` = `06 06 81 83 0001 02EB 0045 795C 794C …`):
  `+4` use count (incremented per load), byte 2 load flags, byte 3 bit 7 =
  "load through I/O" with low bits = logical unit (bit 7 clear → no disk
  load, `1D:1FDE`). With bit 7 set: service `0x30`, unit check `1D:0D26`
  (unit flags bit 0 and bit 8 → `C205`). ALL_RESIDENT instead loads by
  absolute sector from an in-memory copy of its disk directory.
- **DISK step** (JLD0 A.4A / MX81 start-up, segment 20): label read
  (`sc 14`, `0102`, device `C0`), driver `sc 1A 800A`; KIO0 `+0x1976`
  calls `JMDU` when no mounted volume matches and device entry `+0x0A` is
  `0xFF`.
- **Floppy driver `E3#R`** (RTS container, seg 3B): result bytes ST0→`rh0`,
  ST1→`rl0`, ST2→`rh1`, C, H, R, N (`0x1D5C`); for data transfers
  `ST1:ST2 = 8000` (EN only) is success (`0x1C3C`); main status handling
  `0x1B0E`. INIT `E3#I` (`HDII+0x2F2`) builds the controller block and
  does not touch the unit table.

## 9. MAME harness (`runs-archive/restore-hd-20260928/`)

`launch.sh CHD [extra MAME args]` runs `mame_latest/mame/m40` headless with
GO363 in slot 5; environment: `OUT` (run dir, required), `RUN_SECONDS`,
`SCRIPT` (Lua autoboot script, default `run.lua`), `ISL=floppy` (boot from
floppy), `DEBUG=1` (enable debugger; pass `-debugscript DIR/debug.cmd`
containing `go`). Screenshots go to `OUT/s_NNNN.png` every 5 s.

| Script | Use |
|---|---|
| `run_keys.lua` | `STEPS="t:@Key;t:^Key;t:%Key;t:=text"` — tap key (field name prefix), with CONTROL, with SHIFT, or natural-keyboard text; `@#2F` selects a key by scan code; `t:!floppydisk2=/abs/x.imd` loads an image, `t:!floppydisk2=-` ejects. Screenshot `kNN_*.png` 3 s after each step, `s_NNNN.N.png` every `SHOT_STEP` s. `;` separates steps, so keys whose names contain `;` must use `#code`. Times are absolute machine time: after a `-state` load, steps earlier than the restored time all fire at once |
| `run_oslem7_hack2.lua` | oslem7+ from power-on: from 73 s unit-3 flags `00:D400` `0901`→`0801` and the `03:2956` range-check breakpoint (v2 limit `0F08`; use v3 `7fff`, see OSLEM_STATUS 1F), then `run_keys.lua` |
| `run_savestate.lua` | `SAVE_T`, `SAVE_NAME`: save a state (to `-state_directory`/m40/NAME.sta) then `dofile(INNER)` |
| `state_run.sh EXPDIR` | resume from a saved state: env `BASE` (dir with `hd.chd` + `sta/`), `STATE`, `STEPS`, `PROBE` (`|`-separated debugger commands armed after load), `LIMIT` (range-check length, default `7fff`), `WRAP`/`INNER`/`SAVE_T`/`SAVE_NAME` to save a new state. Copies `BASE/hd.chd` into EXPDIR. Uses `run_state_probe.lua` (re-arms hack v3; breakpoints are not in a state) |
| `run_bps.lua` | `BP_T`, `BPS="seg:off,…"` logging breakpoints (pc, r0-r3) |
| `run_trace.lua` | breakpoint(s) `TRACE_AT` start a CPU trace for `TRACE_LEN` s |
| `run_ttrace.lua` | trace between `TR_FROM` and `TR_TO` seconds |
| `run_dumpseg.lua` | dump program-space segments `DUMP_SEGS` at `DUMP_T` to `segXX.bin` |
| `run_findseg.lua` | at `FIND_T`, list segment offsets holding module name `FIND` |
| `run_pcs.lua` | PC histogram between `PC_FROM` and `PC_TO` |
| `run_units.lua` | locate the unit table via `00:00A8` and log it / writes |
| `run_unitinit.lua` | watch writes to a fixed table address `UT` from `WATCH_T` |
| `run_st45.lua` | log FDC data-register reads returning ST0 `0x45` |
| `run_att*.lua`, `run_modd*.lua`, `run_handler.lua` | attention-path probes |

Saved states (`install/`): `base02/sta/m40/mount02.sta` (272 s, DKC£ FF at
`MOUNT INPUT DISK NR. 02`), `base03/sta/m40/ffdone.sta` (325 s, FF copied,
`END OF PROGRAM`; `^j` gives `0X - COMMAND :`). Loading takes ~8 s wall.

oslem7+ OX sequence (from power-on, LOCK on): `150:@LOCK;153:^j`, then
`=exec dkc;@LOCK;@#38;@Keypad ENTER;@LOCK` (`#` = key `#38` with LOCK off;
answer Y with `=z`). Active keymap: `install/oslem7_keymap.txt`.

Login/OX sequence for ALL_RESIDENT (password `ALLRES`, date `860909`):
`100:@Keypad ENTER;110:=ALLRES;117:@Keypad ENTER;125:=860909;132:@Keypad ENTER;140:@LOCK;143:^j`
then `=exec name` and `@Keypad ENTER`.

## 10. Pitfalls (each cost real time)

1. **Keyboard.** Read the active table from memory instead of guessing
   (oslem7+: segment 04, unshifted `0x255E`, shifted `0x2652`; decoded in
   `install/oslem7_keymap.txt`). LOCK selects the shifted table for every
   key regardless of Shift. oslem7+: `#` = key `#38` (`] }`), `.` = `#2D`,
   `=` = Shift+`#2E`, `+` = `#36`, all with LOCK off; `y`/`z` are swapped.
   The earlier claim that `#` cannot be typed was a misreading; aliasing
   modules (`OSG#` → `OSGX`) is unnecessary. Typing
   `EXEC OSG1`/`OSG3` by accident runs a sub-module stand-alone (runaway
   code; one run swept GO363 registers and MAME aborted with "hard sectored
   mode is not emulated").
2. **Segment reuse.** Segment 3 holds JLD0 during start-up and KIO0 later;
   a segment dump taken at the wrong time disassembles the wrong module.
   Dump at the moment of interest (`run_dumpseg.lua DUMP_T`).
3. **Stale copies.** `run_findseg.lua` finds module headers left in memory
   after the module stopped (OSG# at `2E:0000` was stale; the code running
   there was `JERR`). Confirm with a trace which code actually executes.
4. **Trace windows.** Floppy loads take seconds; a 2 s trace after `EXEC`
   misses the program. Use ≥ 15 s or time-window traces.
5. **Debugger spaces.** Data watchpoints need `wpdset`; `wpset` watches
   program space (early "no writer found" results were wrong because of
   this).
6. **Directory start fields** are relative to the directory sector, not
   absolute (oslem7+).
7. **Mid-sector modules.** A name found mid-sector is usually a
   sub-module; `l1lib.py find` reports the containing module.
8. **Free space.** Check fill before writing (`E5` blank vs `@` fill):
   ALL_RESIDENT has only cylinder 74 free.
9. **Versions.** Compare `l1lib.py versions` before grafting modules
   between disks.
10. **Auto-mode classifier outages** block tool calls ("no verdict");
    they are not judgments about the command.
11. **Do not read guest memory from Lua during ROM start-up.** Polling the
    CPU data space every frame from power-on (e.g. `ds:read_u8` in a frame
    callback) left the machine blank with no boot, most likely bus NMIs from
    unpopulated addresses. Start memory access after the OS is loaded
    (≥ 60-73 s); `run_descpatch.lua` uses `POLL_FROM`.
12. **`C303` is not always an I/O error.** In `KIO0 MX82` it is also raised
    before any FDC command when a data-area request fails the `+0x50` bit 0
    test (`03:2798`); check the FDC command log before assuming a
    device/emulation fault.
13. **Save states.** Before the 2026-10-01 `upd7261.cpp` fix (allocate
    `m_buf` before `save_pointer`) every save failed silently (popup only,
    file deleted). Watchpoint data symbol is `wpdata` (not `wdata`);
    `dumpd` needs a filename (`dumpd file,addr,len`). Z8001 stack accesses
    use a separate `stack` space; `wpdset` does not see them.
14. **A crash far from the cause.** `ERR.C003 SEGMENT TRAP` after a volume
    swap was an I/O request rejected by the range check, then the kernel
    `sc #0x1B` path that returns with `r3` = request+0x98 instead of the
    TCB (OSLEM_STATUS 1F). Log `03:2944` (range check) before chasing the
    dispatcher.

## 11. Where the findings live

- `re/os/oslem/OSLEM_STATUS.md` — installation status, experiments, traces (sections
  1A-1F, Issue 2).
- `re/hardware/go363/GO363_DOCUMENTATION.md`, `doc/HARDWARE.md`, `reference/manual-digests/BCOS_II_MANUAL_EXTRACT.md` —
  hardware and manual extracts.
- Manual *M40 DOS Environment – Software Configuration and Generation*
  (3988331 Y, in `~/Downloads/LINEA 1-…zip`): JX24, MX24, TOC£ (fields DSN,
  BOE, MNR, TK0, BSIZ), DKC£, DKR£ (disk restore; reads sectors 8 and 12
  of the input disk), SCT£, OSG£ SMVO step. Pages 2-9..2-12 are missing
  from the scan.
