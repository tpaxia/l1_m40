# OSLEM / BCOS hard-disk installation status (2026-10-02)

Goal: install BCOS II on the emulated WREN2 hard disk (GO363, M40) following
the Olivetti restore procedure in
`reference/Disk Images (Stefano Marinelli + others)/Ripristino_HD/Procedura di salvataggio e ripristino di un sistema Olivetti L1 M30.docx`.

## Outcome (2026-10-02)

The install is complete and the hard disk boots. Steps 1–9 ran under DCOS and
`oslem7+` (below); step 10, the boot from the hard disk, uses a patched REL 6.0
ROM, `m40rom-6.0-hd65.bin` (`tools/mkrom_hd65.py`), that adds the GO363 IPL and
the M44 service-table entries LDHSEL calls (Issue 2, "Resolution"). The keyboard
map was then changed from `KITA` to `KUSA` with `COS#`; that disk is published as
`m40-bcos-hd-kusa.chd` in `mame_disks` and boots to `/SYS`. Still open: why the
unmodified `oslem7+` needs the two debugger patches (Issue 1).

The rest of this note is the record of how it was done.

## Two independent blockers

1. **No unmodified OS drives the GO363** (disks/OSLEM, not the ROM). The ROM
   IPLs floppies normally; after IPL the OS's own driver (`1HDI`, `H65R`)
   talks to the GO363. The procedure needs a floppy-loaded OSLEM with the
   type-65 driver to run JX24/MX24/TOC£/DKC£. `oslem7+` (floppy IPL,
   system library on HD via `JLDH`) unmodified stops at
   `PUS= TIME OK== DISK`. **With two run-time debugger hacks (1E, 1F) it
   reaches OX, and steps 7–9 have been run with it: the HD now holds BCOS
   II, installed by JX24/MX24/TOC£/DKC£ (1F).** Why the unmodified release
   needs the hacks is still not established.
2. **The ROM cannot IPL from the GO363** (ROM only). REL 6.0, REL 4.1 and
   the 1981 ROM have no type `65` in their IPL lists and no `0x90`–`0x9C`
   HD read entries that LDHSEL/HDU1ST24 call. Only the M44 REL B.1 ROM has
   them, and its UC048 CPU board is not emulated. This affects only the
   final floppy-less boot (step 10), not anything under Issue 1.

Issue 1 has priority; Issue 2 is a later, independent improvement.

## Procedure steps and state

| # | Step | State |
|---|---|---|
| 1 | Standard 24 (`S24W25`, DCOS disk G) | Done |
| 2 | ERMAP format (`HDC5X3` option 1) | Done (test pattern; no factory ETF) |
| 3 | Format HD (`HDC5F5`) | **Done: `DISK CORRECTLY FORMATTED`, 0 errors** |
| 4 | Error rate (`HDC5E9`, code `1004`) | **Done** (default: read tests, cyl 0–100, heads 0–3): `RELIABLE SUBSYSTEM` |
| 5 | ERMAP update | Skipped (no defects) |
| 6 | LDHSEL (`LDHSE2`, DCOS disk A code `1002`) | **Done**: sectors 0–6 of cyl 0 head 0 written (`SYS0…`) |
| 7 | OSLEM: `EXEC JX24`, reboot, `EXEC MX24` (65 MB: MNR `0003EA00`, TK0 `0120`) | **Done** under `oslem7+` with debugger hacks (1E, 1F) |
| 8 | `TOC£`: re-enter dataset FF parameters | **Done** (1F), values from the FF backup (1D) |
| 9 | `DKC£`: copy datasets FF (`ff1`,`ff2`) and 80 (`80-1`…`80-4`) to HD | **Done** (1F); image identical to the offline restore (1D) |
| 10 | Boot from HD → BCOS II | **Done** with the patched hd65 ROM (Issue 2, Resolution) |

Disk images (all disposable copies):

- Formatted HD: `re/checkpoints/mos-install/wren2-formatted-hdc5f5.chd`
  (summary screen `hdc5f5-formatted-summary.png`)
- Error-rate summary: `runs-archive/hdc5e-errorrate-20260926/hdc5e-summary.png` ([screen](../../evidence/screenshots/hdc5e-errorrate-20260926__hdc5e-summary.png))
- Formatted + LDHSEL: `runs-archive/ldhsel-20260926/wren2-ldhsel.chd`
  (screen `ldhsel-summary.png`) — **current starting point**
- Formatted + LDHSEL + restored FF/80 + SSID `1EX` entry:
  `re/checkpoints/bcos-hd/wren2-restored.chd` (Issue 1D)
- **Baseline: BCOS II installed by JX24/MX24/TOC£/DKC£** (Issue 1F):
  `re/checkpoints/bcos-hd/wren2-bcos-installed-baseline.chd`
  (read-only). Work on copies.

MAME changes that made formatting work (committed and pushed as `f7144257e16`
on `m40_z8010_sup_test`): uPD7261 read/write/verify data-field timing,
GO363 `0x0e00` ID buffer for FORMAT/VERIFY ID, GO363 register `0x41`
extended head select. Evidence: `re/evidence/upd7261-read-data-timing-evidence.md`,
`re/evidence/go363-format-id-buffer-evidence.md`.

## Issue 1: an OS that drives the GO363

### Why the OSLEM utilities are needed

The BCOS II manual (pp. 178–180, `reference/manual-digests/BCOS_II_MANUAL_EXTRACT.md`) lists them as
"OSLEM utilities": `JX24` formats HD track 0 / writes the OS descriptor,
`MX24` defines the HD extent, `TOC£` data-set table, `DKC£` data-set copy,
disk restore, OSLEM disk generator. They are reached at `OX - COMMAND :`
(caps LOCK then Ctrl+J), e.g. `EXEC JX24`.

Media containing them: `Ripristino_HD/oslem7+.imd` (= identical copy in
`BcosII M30M40 Christian ok/`), `ff1.imd` (dataset FF backup = OSLEM + BCOS),
`BCOS_II_3.3_FD_ALL_RESIDENT.imd`, `Ese L1/probejsf.imd`.

### 1A: OSLEM7 floppy (`oslem7+.imd`, floppy IPL, HD system) — blocked, under investigation

Boot from FD1 (ISL2). OSLEM (`VEGA`, configuration `J0XP B6.0` — `JH24` is
the HD configuration name it references, not the configuration —, loader `JLDH`,
tag `MX81`, resident modules `KER0 KIO0 MOD0 JPTC 1HDI 0FMU`) loads and stops
on its status page `PUS= TIME OK== DISK`. Keyboard input is never enabled.

Traced cause (`runs-archive/oslem-jx24-20260926/` ([screen](../../evidence/screenshots/oslem-jx24-20260926.png)): `bp.txt`, `sc1a.trace`,
`ctx*.bin`, `fdc.txt`):

1. The DISK step (`22:0502`…`05B8`) reads the boot floppy's label (µPD765
   FM reads, all normal status), then calls `sc #0x1a` function `0x800a`
   for device `0xC0` (= GO280 floppy unit "1", our FD1; from the
   configuration table on the floppy at flat `0x7BDB0`).
2. The floppy driver (`03:1C20` → `03:1F06`) finds the mounted-volume list
   empty: pointer at `[00:00B0]+0x76` (`F054+0x76`) is null. A watchpoint
   shows nothing ever writes it from power-on.
3. It therefore starts the mount utility **`JMDU`** (`03:1D54`, `sc #0x0d`).
   JMDU is not resident; its directory entry (`00:C57E`) points to the boot
   library descriptor `00:CC30` = `05 05 81 83 …`, i.e. load via logical
   unit 3. *(Corrected 2026-09-30: `JMDU` is an appended sub-module of the
   resident `KIO0 MX82` (`+0x30A2`), and `0x83` may be `0x80|segment 3`;
   see 1E "Correction".)*
4. Kernel load service `0x30` (`21:0F82`) rejects unit 3 because the unit
   table entry (`00:D400`) is `0x0901` (assigned, bit 8): error `0xC205`,
   task aborted via `02:0BB0`.
5. The unit table and `CC30` descriptor are static data from the floppy
   image (no CPU writes). The only dynamic element found is the empty
   mounted-volume list.

Checks already done: not the hard disk (same with no GO363 / no CHD); the
GO363 board ID `0x65` is correct; booting from controller unit 0 (`-flop4`)
is worse (`#ERR NODK`); ejecting the floppy during load crashes the boot
(floppy busy 69–76 s, no idle window). BCOS 3.3 configurator (same kernel
family) uses the same unit check only for units ≥7 and mounts its boot
volume in its own DISK step (`LDK=E100 LIB=…1`).

Open hypothesis: the boot volume should be registered in the mounted-volume
list before the DISK step (e.g. by the floppy driver on a READY-change
notification that the emulated always-ready 8-inch drives never produce),
so that JMDU is not needed. Not yet proven.

#### Follow-up trace (2026-09-27, later)

Correction: the earlier "no CPU writes" watchpoints were on the Z8001
*program* space. Ordinary loads/stores use the *data* space (`wpdset`), and
PC-relative `ldr` stores use the program space. With the right spaces:

| Structure | Writers |
|---|---|
| Unit table `00:D3F4` (unit 3 = `D400`) | kernel init `03:0CD6` at 73.55 s: units 0–3 `0x0901`, 4–6 `0x0900`, 7+ `0x0100`; start-up task `22:0098` (free-unit allocation) and `22:01D4` (unit 3 → device block `CBF0`) at 75.71 s |
| Library descriptor `00:CC30` | `03:0AE6` (init), `21:06C4/06D2`, then `22:0392` writes byte 3 = `0x83` |
| Start-up variable `22:025E` (source of `0x83`) | `22:02D6` from kernel variable `00:016C` (= `0x83`, written by kernel `03:0050`; BCOS 3.3 has the same value) |
| Device entry for `0xC0` `00:D808` (+0x0E/+0x0F = `C0 FF`) | only kernel init `03:0C5E` |
| Mounted-volume list pointer `F054+0x76` | nothing (stays 0) |

None of these structures is present verbatim in the floppy image; the
start-up module's variables at `22:025A`–`0261` are zero on disk (module at
flat `0x5B360`). Bit 8 (`0x0100`) is a default attribute on every unit; no
code in segments 3/21/22 clears it. The load service (`21:2370`) treats
descriptor byte 3 bit 7 as "validate logical unit (byte & 0x7F)", and
service `0x30` rejects any unit with bit 0 and bit 8 set (`0xC205`).

The whole JMDU load runs in one task context (`00:00A6 = C85E`, unit table
`D3F4`); no task switch or interrupt race is involved. RAM size does not
matter (512 KB and 1 MB stop identically).

Conclusion so far: with this code and data, loading JMDU from the boot
library fails on any machine, so on working hardware this path must not be
reached (boot volume already mounted / device entry +0x0F not `0xFF` /
different DISK-step branch). What causes that difference is still unknown.

#### JMDU and the next failure (diagnostic patch only)

`JMDU` (floppy flat `0x2B4A2` in the old track-0-prefixed convention,
header `JMDUMX82`, inside `KIO0 MX82` at `+0x30A2`; code at `0x2B4C4`)
is the mount manager: it sets the mounted-volume heads `00:0102`/`0104`,
checks a `0TOC` signature and calls `DIK#` (the "support declaration"
utility whose errors `NODK`/`8305` are in the manual). So loading it is
normal, and the unit-3 check must pass on real hardware.

Units 2 and 3 are assigned explicitly by the start-up task
(`22:0084` → `22:0098`, `r0 = 2`, `r0 = 3`); the free-unit scan afterwards
hands out units from 0x21 downward. Unit 3 keeps the kernel-init default
bit 8 (`0x0901`); the init store happens inside an indirectly called module
routine (reported at `03:0CD6`).

Diagnostic experiment (guest-memory patch, **not a fix**): writing unit 3 =
`0x0801` in the data space at 75.95 s removes the `0xC205` error. The load
then proceeds (two more FM label reads, track 0 sectors 5 and 7) and enters a
retry loop in segment 0x21 (`21:0B9A`–`0BC0`): I/O request `sc #0x14`
(function word `0x0102`, device `0xC0` request block at `00:3AD2`) fails with
`0xC303` every ~50 ms, followed by `sc #0x1a` `0x9100` (operator message) and
`sc #0x1c` (wait). No floppy command is issued: the error is raised in the
driver at `03:26B8` (`calr 0x2A5E` with inline `C303`) when bit 8 of the
request word at `@rr2` (+2 of block `3AEE`) tests clear. The same site also
runs once during the unpatched DISK-step open at 75.88 s.

Status: two consecutive OSLEM-internal checks reject the boot floppy
(`C205` unit check, then `C303` request check). Neither is yet tied to a
specific emulated-hardware difference.

#### Key finding: the OSLEM7 floppy is an HD-loaded OSLEM (JLDH)

Source: *M40 – DOS Environment – Software Configuration and Generation*
(Olivetti 3988331 Y, Sep/Oct 1983; in `~/Downloads/LINEA 1-…zip`). It uses
"a general-purpose OSLEM release disk" and documents JX24, MX24, TOC£,
DIK£ and the OSLEM disk generator OSG£. Page 2-14 (`SMVO` at the end of
OSG£): `OS LOAD MNAME: JLDO` default, **`JLDH` "if loading is from HD"**;
RTS/INIT modules `HDUR/HDUI` (via CFU) or `HDIR/HDII` (integrated HDU).
Page 2-13 shows the expected layout: `SYSHDU FF` on `E400`, `OSLIB` on the
floppy (`DDK1 → 02 00 C0 E100`).

Boot descriptors found on the disks:

| Disk | Descriptor | Meaning |
|---|---|---|
| `oslem7+.imd` (flat `0x9F42`) | `H65R H65I JLDH 0440-0540-1000-3000` (+ `HE4R HE4I JLDH`) | HD system (65 MB HDU), HD loader |
| `ff1.imd` | `FUNR FUNI JLDH …`, module `JLDH MX81`, also `JLD0 A.4A` module | HD system |
| `M40MDO32.imd` | `FDUR FDUI JLD0 0440-0540-0700-1400` and `HDIR HDII JLDH` | floppy system (+ HD variant) |
| `BCOS_II_3.3_FD_ALL_RESIDENT`, `K02733` | loader module `JLD0 A.02` | floppy systems |

**Refuted 2026-10-01 (see end of 1E):** the inference below was wrong.
`oslem7+` reads its library from the floppy (`LIB= .1F5`) and stops at
`DISK` with the installed HD too.

So `oslem7+.imd` is an OSLEM generated to load from the hard disk (likely a
copy of an installed machine's FF data-set). It IPLs from floppy, but its
system library is the HD data-set (unit 3 = `SYSHDU FF`); with a blank HD
the mount chain fails, consistent with the `C205`/`C303` traces. This is
probably not an emulator fault.

#### Newly recovered OSLEM 5/6/7 captures (2026-09-27)

The four new SCP captures in `Ripristino_HD/` were converted to IMD and their
track-0 IPL descriptors, module headers, and configuration records inspected.
All have `JX24` and `MX24` in the library, but every IPL descriptor selects
`JLDH` (the HD loader), with MVO `0440-0540-1000-3000` and resident `1HDI`.

| Image | IPL RTS / INIT / loader | Type-65 GO363 entries | Assessment |
|---|---|---|---|
| `oslem5.imd` | `HE4R B300` / `HE4I B300` / `JLDH 1100` | None | HD-loaded, different HD device configuration |
| `oslem6.imd` | `HE4R B300` / `HE4I B300` / `JLDH 2605` | One | HD-loaded; type 65 is present in the device table but not selected for IPL |
| `oslem6st506.imd` | Same IPL modules as `oslem6` | Two | Most promising device table, but still HD-loaded |
| `oslem7.imd` | `H65R AGRE` / `H65I AGRE` / `JLDH MX81` | Two | Sector data is byte-for-byte identical to `oslem7+.imd` |

Evidence locations in the flattened sector streams: track-0 descriptors at
`0x80` (all disks); `oslem5` boot descriptor text at `0x4C52E`, `oslem6` and
`oslem6st506` at `0x62D2E`, and `oslem7` at `0x9F2E` (also `0x4772E`).
The type-65 device records are at `0x821F0` (`oslem6`), `0x821F0` and
`0x82210` (`oslem6st506`), and `0x7BE10` / `0x7BE30` (`oslem7`). The
standalone `JLD0` strings in some images do not change the IPL selection.

An independent bounded MAME boot of `oslem6st506.imd` with a disposable copy
of the formatted, LDHSEL-initialized WREN2 CHD reached `PUS= TIME OK== DISK`
at 110 and 119 emulated seconds, then showed `SYS= 0 / J0XP` by 139 seconds;
it never reached `OX - COMMAND :`. Captures are in
`/tmp/oslem6st506-probe/`. This runtime result supports the descriptor
reading: the best-matched new disk does not solve the blank-HD OSLEM boot
problem. A floppy-loaded OSLEM release with `JLD0` selected by its IPL
descriptor is still needed, or an equivalent BCOS system must be generated.

With the populated HD (`wren2-restored.chd`, Issue 1D) the result is
unchanged: `runs-archive/restore-hd-20260928/fd1/` ([screen](../../evidence/screenshots/restore-hd-20260928__fd1.png)) stops at the same
`PUS= TIME OK== DISK` page with only 3 GO363 board-ID reads and no HD I/O.
The blank HD was therefore not the cause of this stop.

### 1B: `BCOS_II_3.3_FD_ALL_RESIDENT.imd` — works, but no HD driver

Password **`ALLRES`** (found in the configuration record on the disk, same
layout as the generated system's password). Date `860909`. At `/SYS`:
caps LOCK + Ctrl+J → `OX - COMMAND :`; type in lowercase with LOCK on
(`exec jx24`). **JX24 runs** (`CREATE O UPDATE DESCRI.`), but its volume
table is empty: this generation's modules are `KER0 KIO0 FMD MODR MODD`,
floppy only, no HD driver. Harness: `runs-archive/bcos33res-utils-20260927/` ([screen](../../evidence/screenshots/bcos33res-utils-20260927.png)).

#### 1B follow-up: what ALL_RESIDENT has and lacks (2026-09-27)

Track-0 OS descriptor (flat `0x80`, copy at `0x100`) lists the IPL
segments by length: ALL_RESIDENT loads `BOOT` (`0x0B18`), RTS **`HDIR`**
(`0x2FF2`), INIT **`HDII`** (`0x0692`) and loader **`JLD0`** (`0x1A58`), MVO
`0440-0540-0700-1800`. OSLEM7 loads `H65R` (`0x3200`), `H65I` (`0x0576`),
`JLDH` (`0x2CF2`), MVO `0440-0540-1000-3000`. So ALL_RESIDENT is already an
"HDU integrated, floppy-loaded" system, but:

- `HDIR`/`HDII` contain device types `FF FE E3 E4 E6` only; the GO363/WREN
  type `65` (`65#R`/`65#I`) exists only in OSLEM7's `H65R`/`H65I`.
- Its resident modules (config record at flat `0xAE20`: `KER0 KIO0 0FMD
  MODR` + `MODD`, start program `SIM0`) do not include the HD driver
  `0HDI` (present in its library, version `03.0`).
- Module generations differ: ALL_RESIDENT `A.02` (BCOS 3.3), OSLEM7
  `MX81/MX82`; mixing modules across them is untested.

The ALL_RESIDENT library also holds `JH24`, `JLDH`, `JX24`, `MX24`,
`TOC#`, `DKC#`, `DIK#`, `JMDU` (module directory at flat `0x2780`,
entries name/start/length). The manual confirms a separate
"general-purpose OSLEM release disk" (floppy-loaded) exists; we do not have
one.

#### 1B experiments: patched ALL_RESIDENT (2026-09-27)

Tooling: `tools/l1disk.py` (sector-level IMD read/write, lossless round
trip). Builder: `runs-archive/allres-hd-20260927/build.py` (flags `--no-rts`,
`--no-drv`, `--mvo`); original images untouched.

Formats established:

- Data sector index `i` = flat `0x2700 + i*256` in the extracted image;
  `i = (cyl-1)*52 + head*26 + (sector-1)`; sectors are 1-based.
- Track-0 OS descriptor entries (16 bytes): segment, load offset, segment,
  0, length, cyl, head, sector (1-based) of the module **header sector**;
  module data follows. ALL_RESIDENT's library directory is disk-absolute;
  OSLEM7's is relative to its library base `0x1F4` (`LIB= .1F5`).
- Header sector: name + version, flags, length, then (for containers) a
  sub-module table (`FF#R 0700`, `FE#R 0500`, …).
- Only cylinders 74–76 are blank on ALL_RESIDENT.

Results (disposable HD `wren2-ldhsel.chd`):

| Variant | Change | Result |
|---|---|---|
| first try | module data at sector 0 of cyl 74/75 (wrong) | IPL blink `4 2 1` = media-read error, GO280 unit 1 |
| full | OSLEM7 `H65R`/`H65I` as RTS/INIT + `0HDI` resident + HD device record | boots, `MOD=… 0HDI …`, stalls at KEYB |
| V1 | only RTS/INIT swap | stalls at KEYB → OSLEM7 (`MX8x`) RTS/INIT incompatible with BCOS 3.3 kernel |
| V2 | only `0HDI` resident + device record `65 00 ff 00 … 2SCA 0HDI … DK` | boots normally, `OX COMMAND`, JX24 runs; volume table still empty; GO363 never accessed |

Conclusion: ALL_RESIDENT accepts the resident driver and device record,
but its `HDIR`/`HDII` containers have no type-65 sub-modules, so the HDU is
never initialized. Next possible step: merge OSLEM7's `65#R`/`65#I`
sub-modules into ALL_RESIDENT's containers (needs the container table
format and cross-generation compatibility) — uncertain.

#### Local floppy search and GO363 merge check (2026-09-27)

The available IMD images and remaining `K027xx` SCP captures were checked for
the conjunction of an IPL-selected `JLD0`, OSLEM utility modules `JX24` and
`MX24`, and type-65 GO363 runtime support. No captured disk has all three:

| Image | IPL loader | OSLEM utilities | Type-65 support / boot result |
|---|---|---|---|
| `Ese L1/probejsf.imd` | `JLD0 00D1` | Both | `HDUR`/`HDUI` include `FF#R`/`FF#I`, not `65#R`/`65#I`; no type-65 device record |
| `K02738` configurator multi disk 1 | `JLD0 000E` | Both | `HDIR`/`HDII` lack type 65; bounded FD1 boot did not reach BCOS prompt |
| `K02743` J0XI33 | `JLD0 A.4A` | Both | Resident `0HDI`, but `HDIR`/`HDII` lack type 65; bounded FD1 boot stopped at `PUS= TIME OK== DISK` |
| `BCOS_II_3.3_FD_ALL_RESIDENT.imd` | `JLD0 A.02` | Both | Boots and runs `JX24`, but its original `HDIR`/`HDII` lack type 65 |
| `K02736`, `K02742`, `K02753` | `JLDH` | Both | HD-loaded; no type-65 modules |

Other `K027xx` captures surveyed either lack the OSLEM utilities or lack an
IPL-selected `JLD0`; none contains the `65#R`/`65#I` pair. The manufacturer
configuration manual's separate floppy-loaded OSLEM release is still not in
the local disk collection.

The existing `runs-archive/allres-hd-20260927/build_merge.py` was run on disposable
copies. It appends OSLEM7 `65#R`/`65#I` to the ALL_RESIDENT `HDIR`/`HDII`, adds
resident `0HDI` and a type-65 device record, and optionally adds a driver
binding record. Both variants boot, accept `EXEC JX24`, and show an **empty**
`CURRENT VOLUME` table at 160–200 emulated seconds. Neither is a working
GO363 OSLEM release. The test artifacts and screenshots are in
`/tmp/allres-merge-probe/` and `/tmp/allres-merge-drvrec-probe/`; source SCPs,
original IMDs, and the prepared CHD were not modified.

An independent I/O tap on slot 5's CPU window (`0x3000`–`0x3fff`) during the
driver-binding variant recorded only three GO363 board-ID reads (`0x3ffe` at
0.000 and 0.160 s; `0x30fe` at 69.173 s), all returning `0x65`. There were
no GO363 writes or HD data operations through `JX24`. The appended
sub-modules alone do not make the hard disk available to OSLEM. An earlier
tap on `0x0500`–`0x05ff` was on the wrong window and is disregarded.

### 1C: BCOS system generation — floppy-only

The configurator `K02733` SYS generator was scripted end to end
(`runs-archive/bcos-gen-hd-20260927/` ([screen](../../evidence/screenshots/bcos-gen-hd-20260927.png)), sequence in `steps.sh`). Output:
`gen-PASS-load.imd` / `gen-PASS-run.imd` (password `PASS`, M40, FDU,
KEYB-CRT, PR 1350/1470, BASIC+OCL, USA-ASCII). Its hardware section offers
only the standard configuration (FDU, no HDU).

Generator notes: every page needs Enter to clear its MESSAGE first; the
configurator knows only FD1/FD2 (`ERR.516` otherwise); blank formatted
images are rejected ("INCOMPATIBLE DISK"), copies of the earlier
`BCOS_LOAD`/`BCOS_RUN` work as targets; after "Dismount …" press main Enter
twice; Shift+M gives `?` (Italian table), so avoid M in passwords.

`CONF2` (in `UTS233` on `K02737`) runs from the configurator
(`runs-archive/bcos-conf2-20260927-B/` ([screen](../../evidence/screenshots/bcos-conf2-20260927-B.png))) but only sets an HDU data-set number.
The device configuration program with "HARD DISK UNITS" screens is `DECONF`
in `BCS533` on `K02737`; the configurator cannot launch it (`ERR.153`).
Grafting DECONF + HD drivers into the generated system with `PRDKDK` is a
possible fallback, not attempted.

### 1D: HD populated offline from the FF/80 backups (2026-09-28)

#### The backup disks

The six other images in `Ripristino_HD/` are the original machine's `DKC£`
data-set backups, not boot disks:

| Image | Content |
|---|---|
| `ff1`, `ff2` | Data set **FF** (OSLEM + BCOS), 2 volumes |
| `80-1` … `80-4` | Data set **80** (user data, e.g. `HDR1 BOLLA`), 4 volumes |

Track 0 of each holds only backup-volume records: `0TOC` at `0x100` (data
set `FF`/`80`, count at `+0x2C`), `ERMAP`, `VOL1 … WV 0750522561`, and
`SYSCO 03C3` (FF) / `SYSCO 03C5` (80) with the volume chain (80-1 → 80-2 →
80-3 → 80-4). No IPL descriptor. Every sector is readable (IMD types 1/2
only). Cylinders 75–76 contain the literal text `-=[BAD SECTOR]=-` (disk
content, not read errors), so each volume carries 3848 data sectors
(cyl 1–74) and the track-0 count is data sectors + 1:

- FF: `0x0F09` + `0x7C` → 3848 + 123 = 3971 = `0xF83`
- 80: 3 × `0x0F09` + `0x0A16` → 3 × 3848 + 2581 = 14125 = `0x372D`

Both match the TOC below exactly.

#### Original data-set table (step 8 values)

The HD `0TOC` is inside data set FF at backup index `0x13` (flat `0x3A00`
in the extracted `ff1`; identical copy at index `0x0B`, flat `0x3200`).
Entries are 32 bytes (id, start, length, attribute words):

| Data set | Start | Length | Attr |
|---|---|---|---|
| FF | `0x00001` | `0x0F83` | `0120 0100` |
| 80 | `0x00F84` | `0x372D` | `0030 0100` |
| 81 | `0x046B1` | `0x5000` | `0063 0100` |
| 82 | `0x096B1` | `0x8000` | `0063 0100` |
| 83 | `0x116B1` | `0x6000` | `0063 0100` |
| 84 | `0x176B1` | `0x6000` | `0063 0100` |
| 85 | `0x1D6B1` | `0x6000` | `0063 0100` |
| 86 | `0x236B1` | `0x8000` | `0063 0100` |
| 87 | `0x2B6B1` | `0x6000` | `0063 0100` |

The table ends at `0x316B1`, inside MX24's `MNR 0003EA00`. Only FF and 80
were backed up. FF's attribute `0x0120` equals the procedure's `TK0` for
65 MB; the meaning of the attribute fields is otherwise not decoded.

#### HD layout, from the code on the disks

- **LDHSEL** (HD LBA 0–6, entry `<<32>>0x0008`) reads the VOL1/SSID
  sectors into `0x0700`. With no key, it scans SSID entries at `+0x40`
  (6 × 32 bytes) for a name starting with `1` (`0x0382`), then loads
  `word[+0x1E]` sectors from 1-based LBA `long[+0x18]` (`0x04C2`: `-1`).
  It picks the ROM read routine by governo type: `60` → `<<63>>0x9C`,
  `61`/`65` → `<<63>>0x94`, otherwise `<<63>>0x64` (`0x03E0`–`0x040E`). It
  jumps to the loaded `SYS0` entry with `rr2` → SSID entry, `rr8` = `LCZx`.
- **JX24** (`JX24MX81`, ff1 flat `0x2DF00`) reads 3 sectors from 1-based
  sector 8 (VOL1, SSID, SSID cont.), writes them back to 8 and 11 (the
  SSID copy). It allocates from the SSID free area (header `+8` first free
  sector, `+0x0C` free count) and writes the entry (`0x02BA`–`0x0310`):
  `"1EX0000 "`, start, size, start, size, start, `00000002`.
- **JH24** (`JH240140`, ff1 flat `0x29400`) reads SSID (1-based sector 9),
  matches `1EX?`, takes volume start `+0x08` and size `+0x0C`, then reads
  8 sectors from volume sector 12 and checks `0TOC`, i.e. FF index `0x0B`.
- **HDU1ST24** (FF index 0, `SYS0`, entry `0x00E0`) stores `long[rr2+8]`
  as the base and loads modules from physical LBA = sector + base − 2
  (`0x0092`–`0x00A0`). Its descriptor at `+0x100` points to `BOOT` at
  `0x1AE`, `JLDH` at `0x272`. The module headers are at FF indices
  `0x1AD` and `0x271`, so FF index *i* is at LBA base − 1 + *i*.

With the WREN2 SSID from Standard 24 (first free sector 17, 1-based;
`0x3FD70` free), JX24 would create `1EX` with start 17. FF index 0 then
sits at LBA 16 and TOC volume sector *n* at LBA 15 + *n*.

#### Trial restore

`scripts/harness/build_restore.py` writes a copy of
`wren2-ldhsel.chd` (`chdman extracthd`, rebuilt with `-chs 1024,9,32 -ss 256`):

- SSID (LBA 8, copy LBA 11): entry `1EX0000 ` with start `0x11`, size
  `0x3EA00` (assumed from MNR), boot count 2; header becomes first free
  `0x3EA11`, free `0x1370`.
- FF → LBA 16–3986; 80 → LBA 3987–18111. Data sets 81–87 are left blank.

Output: `re/checkpoints/bcos-hd/wren2-restored.chd`. Harness:
`launch.sh` + `run.lua` (`OUT=dir`, `ISL=floppy` for FD boot, 5-second
screenshots).

The layout is consistent with four independent code paths on the disks,
but it is **unverified at runtime**: no boot path reads it yet (see 1A and
Issue 2). The SSID size field (`0x3EA00`) and the blank 81–87 extents are
assumptions.

### 1E: OSG£ attempts and the K02743 boot (2026-09-29)

All runs are disposable copies in `runs-archive/restore-hd-20260928/` (with the
restored CHD attached); harness scripts (now in `scripts/harness/`) `run_keys.lua` (key steps),
`run_bps.lua`, `run_trace.lua`, `run_ttrace.lua`, `run_st45.lua`,
`run_units.lua`, `run_dumpseg.lua`, `run_findseg.lua`, `run_pcs.lua`.

**Floppy-loaded systems and their HD drivers.** HD sub-drivers found in the
driver containers: `ALL_RESIDENT` `HDIR/HDII` E3 E4 E6; `K02738` E1 E4;
`K02743` `HDIR/HDII` E3 E4, `HDUR/HDUI` E3 EF; `probejsf` E1 EF;
`oslem7+` 65 60 61 E4 (plus FF/FE on all). Only `oslem7+` has type 65, and
it is HD-loaded. `oslem7+`, `K02743` and `probejsf` contain OSG£
(`OSG#`, `OSG1`-`3`).

**probejsf.** ESE system (OSLEM + `EP60` P6060 emulator), `JLD0`, carries
`OSG#`, `JX24`, `MX24`, `TOC#`, `DKC#`, `DIK#`. Its `J0XP` starts `LOAD` →
EP60 → `ERROR 172` (a normal P6060 start-up message, same as the P6066
project's system disks); EP60 then owns the keyboard (HALT PGM/EXIT/S keys
type BASIC keywords). LOCK + Ctrl+J never reaches OX. Mechanism (traced in
ALL_RESIDENT, `allres-att`, `allres-modd`): Ctrl+J makes the kernel call
`MODD`'s keyboard handler (descriptor `MODD+0x1FE`, entry `0x0216`), which
dispatches `'J'` → `0x0336`: reads the attention name `JATT` from `00:010E`
and starts it → `0X - COMMAND :`. In probejsf the same `MODD` code exists
(`1E:0212`, `'J'` → `0x032C`) but the handler is never called, with or
without EP60 (blank start program: idle, label `0D1B`; start program
`JAPP`: blank screen). Not pursued further.

**OSG£ grafted onto ALL_RESIDENT** (`build_allres_osg.py`, images
`allres-osg*`): copies `OSG#` A.0, `OSG1`-`3`, `SMV#` A.0, `SMV0` B.00,
`PMV0`/`PMV1` 0E.1 and `DIRE` A.04 from K02743 onto blank cylinder 74
(cylinders 75-76 hold `@` fill) and adds directory entries (header `RE33`,
count at +4). `OSG#` opens `DIRE`, `SMV0`, `PMV0`, `PMV1` by name and exits
silently without `DIRE`. `£` (0x23) could not be typed (every attempt gave
`1` or `3`; `EXEC OSG1`/`OSG3` then ran those sub-modules alone, one run
swept GO363 registers from runaway code), so the entry is aliased `OSGX`.
`EXEC OSGX`: `JERR` re-initialises, the OX processor and a stub issue
`sc #0x0D` (`20:0078`), `OSG#` is loaded but never executes (15 s trace),
no message. Larger MVO (`--mvo`) does not help. Version check: ALL_RESIDENT
core is A.02 (`KER0`, `KIO0`, `JLD0`, `MODD`, `JERR`); the grafted modules
come from K02743's A.04/A.4x release (`DIRE` A.04 = K02743 `KER0` A.04),
so this is a cross-release graft; utilities common to both (`JATT`, `JX24`,
`MX24`, `TOC#` A.4A, `DIK#`) are identical builds.

**K02743 boot** (`k02743-*`). Stops at `PUS= TIME OK== DISK` like
`oslem7+` (`IPL= E100 JLD0 A.4A`, `MOD= KER0 KIO0 0FMU 0HDI MOD0`).
ALL_RESIDENT's older `JLD0` A.02 has no DISK mount step, which is why it
boots. Experiments with no effect: `0FMU` → `0FMD PATC` (directory entry
redirected; `ES2` changed so it loaded), `####` removed from the boot
descriptor, only drive 1 present, all four drives loaded. Traced
(`k02743-trace`, `-st45`, `-units`):

- Same mechanism as `oslem7+`: DISK step (segment 20) reads the label via
  `sc #0x14` (fn `0x0102`, device `C0`), calls driver fn `0x800A`
  (`sc #0x1A`); with no mounted volume the driver prepares `JMDU`
  (`03:1990`) and the load service rejects logical unit 3 at `1D:0D64`
  with `C205` (unit entry bits 0 and 8 set).
- Unit table (base = word at `[00:00A8]+6`, 4 bytes/unit): kernel init
  0-3 = `0901`, 4 = `0900`, 5-7 = `0100`. The start-up task only sets bit 0
  on units 2 and 3 (`20:009C`) and stores their device blocks. Nothing
  clears bit 8 (no writer found; no bit-clear instruction in any segment).
  So on working hardware the boot volume must already be mounted before the
  DISK step; nothing we emulate registers it.
- Floppy driver `E3#R` (in the `HDIR` container, segment 3B): read results
  are taken from the main status register; for ST0 errors it builds
  `ST1:ST2` and treats `0x8000` (EN only) as success, so the
  `ST0=45 ST1=80` end-of-track reads seen in the logs are not the cause.
- Emulation difference noted, link unproven: after each controller reset
  MAME reports all four 8" drives ready (`C0`-`C3`, NR clear), including
  empty ones (GO280 model keeps the spindles running); real empty drives
  would report not-ready.

**Library-load path (2026-09-30, `k02743-units*`, `allres-units`,
`allres-jmdu`).**

- Unit-table initial values are constants in `JLD0` A.4A (`03:0CB4`-`0D2C`,
  fill routine `0x0D2C`): units 0-3 `0901` (fixed count 4), unit 4 `0900`,
  rest `0100`. Independent of drives present (same with one drive).
- `00:016C` = `0x83` is the high byte of `JLD0`'s own segmented address
  (`03:0044` `ldar rr4`; `03:0048` `ldb 0x016C,rh4`), i.e. `0x80|segment 3`.
- `KIO0` A.4C holds every `JMDU` call (`+0x692` fn 1, `+0x812` fn 3,
  `+0x870` fn 2, `+0x1858` fn 1, `+0x1990` fn 0). The DISK-step call
  (`+0x1990`) happens when the mounted-volume search (`0x1B62/0x1B68`)
  finds nothing and the device entry byte `+0x0A` is `0xFF`.
- `sc #0x0D` → program-load service `1D:1E24`: name hash (`1D:20D0`),
  in-memory directory lookup (`1D:1F74`), then the library descriptor.
  The descriptor used for `JMDU` is at `00:799C`:
  `06 06 81 83 0001 02EB 0045 795C 794C …` (`794C` = the device block the
  start-up task attached to unit 3; `0001 02EB 0045` undecoded). The load
  fails `C205` at the unit check.
  **Correction (2026-09-30, from the container format in
  `tools/L1_DISK_FORMATS.md`):** this is not a general system-library
  descriptor. `JMDU`, `JH24` and `JAPP` are sub-modules appended to the
  resident `KIO0` (`KIO0 A.4C+0x2CD0/0x33E0/0x370C`; oslem7+ `KIO0 MX82`
  holds `JMDU` and `JAPP`). Their in-memory directory entries are
  `name, offset-in-KIO0, 799C, BB` (`00:7710`, `00:7544`, `00:76CA`). So
  `0x83` may mean `0x80|segment 3` (the resident `KIO0` segment) rather
  than "logical unit 3", and `JAPP` (OX processor) uses the same descriptor.
  The earlier "boot volume must be mounted first" reasoning is unproven.
  **Load-service branch** (`MOD0 A.4A` in segment 1D, `1D:1FB8`-`2008`):
  directory entry `+6` → descriptor; `inc descriptor+4` (use count);
  byte 3 bit 7 tested and cleared, low bits stored as the unit in task
  `+0x68`. Bit 7 **clear** → `jr 0x204A`, no disk load. Bit 7 **set** →
  byte 2 (`0x81`) taken as load flags (task `+0x5C`, bit 12 set; bit 4 would
  clear the unit), then service `0x30` → unit check `1D:0D26` → `C205`.
  So the loader does read `0x83` as "load via I/O from logical unit 3"; the
  segment-3 reading applies only to where the value comes from (`JLD0`'s
  own segment byte, `00:016C`, copied by the start-up task into the
  descriptor, `22:0392` on oslem7+). The target modules are already in
  memory inside the resident `KIO0`, where a bit-7-clear descriptor would
  skip the load. Open: whether bit 7 should have been clear (in-memory
  sub-modules) or unit 3 usable at this point.
  **Descriptor lifecycle** (`k02743-desc`, data watch on `00:799C`):
  `JLD0 03:0CAE` skeleton → start-up `20:01DE`-`01F2` reads a Z8010 segment
  descriptor via special I/O (size/task fields only) → `MOD0` service
  `0x14` (`1D:0540`-`05B0`) fills `02EB 0045 795C 794C`, byte 2 = task
  `+0x5C` (cleared by start-up at `20:0218`) `|0x80` → start-up
  `20:0228`-`023C` byte 3 = `[00:016C]` = `0x83`, byte 2 bit 0 → `0x81`,
  task `+0x68` = `0x83` → service `0x2C` (`1D:0BC2`) uses byte 3 as the
  segmented address `03:0000`, parses `KIO0`'s header and registers its
  appended sub-modules. Load service: byte 2 bit 4 set would clear the unit
  (`1D:1FEA`) and service `0x30` would skip the unit check (`1D:0D32`); on
  this path byte 2 is always `0x81`, so the unit-3 check (and `C205`) is
  always reached. No emulated-hardware input reaches these flag bytes.

**Diagnostic patch results (2026-09-30; guest-memory patches on disposable
runs, not fixes).** Scripts: `run_patch.lua` (breakpoint + debugger
expression), `run_descpatch.lua` (Lua poll of the descriptor; polling must
start after ~73 s — reading guest memory during ROM start-up raises bus
NMIs and the machine never boots), `run_descpatch_*.lua` (probes).

| Run | Patch | Result |
|---|---|---|
| `k02743-patchV1` | descriptor `00:799C` byte 2 bit 4 (`0x81`→`0x91`) at `20:0244` | Boot completes (`DYSP OK== PRTR OK==`, `END= LOAD GOON`, label `A04C`); LOCK+Ctrl+J → `0X - COMMAND :`; `EXEC JX24` runs (empty volume table, no GO363 driver on K02743) |
| `k02743-patchV2` | unit 3 `0901`→`0801` | same completed boot |
| `oslem7-patch` | descriptor `00:CC30` byte 2 bit 4 at 75.797 s | `C205` avoided (load path `21:238A/23A6/23AA`, `21:0FD0` not hit); then retry loop `21:0B9A`: `sc #0x14` returns `4000`, then `C303` every ~50 ms |

`oslem7+` after the patch: floppy device block `00:13E6` (`+0xD8` = `0x0080`,
`+0xD6` = `0x1A`; K02743 has the same values and works). Requests: first
`C0000002` (track-0 label, `0x80` bytes) accepted; then `000001F5`
(library directory sector, `LIB= .1F5`) `0x100` bytes, request `+0x50` =
`0x100A`, rejected by `KIO0 MX82` at `03:2798` (`bit +0x50,#0` clear →
`03:26B8` → `C303`). The FDC log shows only track-0 FM reads (sectors 5,
7, 2, normal status); the data-sector read is never issued. The same test
in `KIO0 A.4C` (`03:2476`) takes `03:24E6` → `jp 03:0C64` (normal path),
and K02743's data reads (sectors 1-5, request `+0x50` = buffer offsets such
as `6C7E`) proceed. The `+0x4E` long of the request is set to a buffer
address by the retry loop (`21:0B70`); the meaning of `+0x50` bit 0 for
`KIO0 MX82` is not established.

Further `oslem7+` diagnostics (`oslem7-patch2`, `oslem7-patch3`):

- Forcing the `+0x50` test to accept (clear Z at `03:279C`) reaches
  `03:280E`, but `sc #0x14` still returns `C303` with no FDC command. Both
  `C303` sites (`03:26B8`, `03:283C`) are `calr 0x2932` + `calr 0x2A5E`
  with inline `C303`; `0x2932` is a **range check**: requested sector
  (`rr8+0x0A`) vs limit `[req+0x62] + [req+0x66]` (extent start/length).
  Request `00:3AD2`: start `1`, length `0x0F08` (3848 sectors), but flag
  word `+0x0A` = `0x8383`; with bit 15 set the length is skipped
  (`03:295C`/`2960`), the limit becomes 1, and sector `0x1F5` fails. `0x8383`
  is the `0x83` byte from `00:016C` again.
- Forcing both bit-15 tests (`03:2960`, `03:2972`) to "clear" as well:
  **DISK step completes** — status line `PUS= TIME OK== DISK OK== KEYB`;
  the boot then stops at the `KEYB` step (keys ineffective). Same step at
  which the earlier ALL_RESIDENT + OSLEM7 RTS experiment (1B) stalled.

**Working hack (2026-09-30): oslem7+ reaches OX with the GO363 volume.**
`scripts/harness/run_oslem7_hack.lua` (run `oslem7-hack`):

1. descriptor `00:CC30` byte 2 bit 4 set once the start-up task has built it
   (Lua poll from 73 s, `run_descpatch.lua`);
2. `KIO0 MX82` range check: breakpoint at `03:2956` with condition
   `r3==0 && (r0&8000)==0` (request `+0x84` length zero, normal address) →
   `r3 = 0x0F08`, clear Z. Register-only; special `0xC000…` track-0
   addresses keep their own path.

Result: boot completes (`DYSP OK== PRTR OK==`, library `7.0+`); LOCK + Ctrl+J
→ `0X - COMMAND :`; `EXEC JX24` lists `CURRENT VOLUME: 01 FF FF - 6500 1..1
1HDI 2SCA` (GO363 type 65 unit 00) and prompts `NUMBER CURRENT UP 2D:`;
~450 GO363 accesses. Superseded attempts: forcing `03:279C` (`+0x50`
test) sends requests down the deblocking path and, with the bit-15 bypass,
led to `1KYB` code at `1C:0860` being overwritten by library-directory data
(`KEYB` hang); writing `+0x84` into the request block made the special
label reads fail (`#ERR NODK` loop). In `KIO0 MX82` the range check
(`03:2932`) uses `[req+0x84]` as the length whenever request `+0x0A` bit 15
is set — and `+0x0A` is copied from the driver entry's segmented pointer
(`8383 0D66` = `03:0D66`), so bit 15 is always set; `+0x84` is never filled
on this path. `KIO0 A.4C` (K02743) has no such range check.

Pattern so far: every obstacle on these releases traces to the value `0x83`
(`JLD0`'s own segment byte, stored in `00:016C`) being used as a
logical-unit / flag byte (descriptor byte 3, request `+0x0A`). Whether a
real machine produces a different value there (e.g. a different `JLD0`
load segment or code path) is the open question.

**Answered (2026-10-01): the value is the same on a real HD boot, so it is
not ROM-dependent.** The load segment comes from the disk's OS descriptor,
read by the disk's `BOOT` module; the ROM only reads `SYS0`. All three
descriptors load the OS loader at `03:0000`:

| Descriptor | Loader | Load |
|---|---|---|
| `oslem7+` track 0 `+0x80` | `JLDH MX81` (len `0x2CF2`) | `03:0000` |
| ALL_RESIDENT track 0 `+0x80` (boots unpatched) | `JLD0 A.02` | `03:0000` |
| FF index 1 (`HDU1ST24` `+0x100`, real HD boot) | `JLDH` (len `0x2CF2`) | `03:0000` |

A GO363-capable ROM would therefore produce the same `0x83` at `00:016C`.
Still open, and untested: whether booting an HD-generated system
(`JLDH`, `H65R`/`H65I`) from the floppy (`IPL= E100`, `LIB= .1F5`) leaves
the library unit 3 in a state a real HD boot would not; the two hacks
bypass exactly the unit-3 checks. The FF boot set is a different build from
`oslem7+`'s: `BOOT` `0x0BEC` vs `0x0BF6`, `####` `0x0E82` vs `0x05FC`,
`H65R` `0x38D6` vs `0x3200`, `H65I` `0x08EE` vs `0x0576` (same `JLDH`
length).

**Unpatched `oslem7+` against the installed HD (`install/nohack1/`,
2026-10-01):** stops at `PUS= TIME OK== DISK` as with a blank HD, with 3
GO363 accesses in 300 s. The HD contents are not what the `DISK` step is
waiting for. With the hacks, `EXEC JSE#` (FF's `J0XP` start program, the
BCOS entry) gives `ERR.C20B UNKNOWN MODULE`: `oslem7+` loads modules from
its floppy library only.

**How unit 3 is filled (2026-10-01, `install/unit3/`: unpatched boot,
segments 00/03/22 dumped at 77 s; `JLDH MX81` extracted from `oslem7.imd`,
loaded at `03:0000`, so file offset = segment offset).** Nothing reads the
boot device:

- Flag word: constant in `JLDH MX81`. `03:0AEE` takes the unit-table base
  from `[00:00A8]+2` (`00:D3F4`); `03:0B04` `ldk r1,#4`, `03:0B06`
  `ld r11,#0x0901`, `calr 0x0CD4` (store `r11` into `r1` consecutive
  entries): units 0-3 = `0901`. Then `0900` and `0100` for the remaining
  units, sized from the configuration bytes at `03:41AA` and the byte at
  `00:00C0` (`0x01`, tested at `03:0B26`, after units 0-3 are written).
- Device-block pointer: start-up code `22:0098` sets bit 0 on units 2 and
  3; `22:01AC`-`01D0` stores `[task+6] + [task+0x0C]` (task = `[00:00A6]`)
  into unit `+2`. Units 2 and 3 get `CBF0`; `00:CBF0` =
  `0100 D102 0000 0338 002C CC30 CBE0`, i.e. it points to the boot-library
  descriptor `00:CC30` (`05 05 81 83`), whose `0x83` is `[00:016C]` (same
  for floppy and HD boot, see above).
- Unit-table dump at 77 s: `D3F4: 0901 0000 0901 0000 0901 CBF0 0901 CBF0
  0900 0000 0900 0000 0900 0000 0100 …`.

So unit 3 reads `0901` → `CBF0` → `CC30` whatever the ROM or boot device,
and the load service's unit check (`C205`, bits 0 and 8) would reject it on
any machine. The unit-3 hack is not explained by floppy-vs-HD IPL. On
working hardware the DISK step must not need `JMDU` via unit 3: the call
(`KIO0` `+0x1990`) happens only when the mounted-volume search
(`0x1B62`/`0x1B68`) finds nothing and the device entry `+0x0A` is `0xFF`.
Remaining lead: why no volume is mounted at the DISK step (unproven
emulation difference: MAME reports all four 8" drives ready after a
controller reset, including empty ones). Not traced: where the start-up
task's `+6`/`+0x0C` table that yields `CBF0` is built.
- ALL_RESIDENT (A.02) has the same unit table (`03:0BBE`, units 0-3
  `0901`; start-up `29:00A0` sets bit 0 on units 2/3) but keeps its disk
  directory in memory and loads by absolute sector (`JMDU` entry at
  `00:3C8E` → sector `0xF8`). `EXEC JMDU` from its OX prompt does not reach
  its `C205` check (`26:1046`/`104E`); no output appears.
- No code clears bit 8 on a unit entry: no writer after the start-up task,
  and the only bit-clear byte patterns in memory are data (jump tables;
  kernel variables `00:01B4`-`01C4` holding `C205` and `JMDU`).
- Floppy device init `E3#I` (in `HDII`, container offset `0x2F2`, `0x186`
  bytes) allocates the controller block, installs vectors, marks four drive
  slots, calls `E3#R+0x58` (board ID port `0xFF`, port `0xED` bit 0) and sets
  rate/mode bytes. It does not touch the unit table.
- Earlier `oslem7+` patch (§1A): clearing unit-3 bit 8 lets the load
  proceed, then the driver rejects the I/O with `C303` because bit 8 of the
  request word is clear. Bit 8 is therefore required on the request but
  forbidden on the unit at load time; the state sequence that satisfies both
  on real hardware is not identified.

Keyboard note for these runs: `run_keys.lua` accepts `@#2F` to select a key
by scan code; with the Italian table `M` is key `#2F` (`; +`), `#` (0x23)
could not be produced. (Superseded: see 1F, `#` is key `#38` with LOCK off.)

### 1F: Steps 7–9 run under `oslem7+` (2026-09-30 / 2026-10-01) — done

With the oslem7+ hack (1E), JX24, MX24, TOC£ and DKC£ were run in MAME
from the OX prompt. The resulting WREN2 image is **sector-for-sector identical
to the offline restore** (1D, `hd-restored.raw`): 0 differing 256-byte
sectors over the whole 75 MB disk.

Results, all under `runs-archive/restore-hd-20260928/install/`:

| Step | Run dir | Result |
|---|---|---|
| `EXEC JX24` | `jx24/` | SSID entry `1EX0000`, start `0x11`, default size `0x2000` |
| `EXEC MX24` | `mx24/` | size `0x3EA00`; SSID identical to the offline restore (`hd-after-mx24.chd`) |
| `TOC£` | `toc1/` | FF start 1 len `0F83`, 80 start `0F84` len `372D` (attributes as the original TOC); on disk at LBA `0x1B`/`0x23` (`hd-after-toc.chd`) |
| `DKC£` FF (`ff1`, `ff2`) | `base02/`, `base03/` | LBAs 16–3986 = `ff1`+`ff2` data (`hd-after-ff.chd`) |
| `DKC£` 80 (`80-1`…`80-4`) | `d80b/` | LBAs 3987–18111; whole disk = offline restore (`hd-after-dkc.chd`, copied to `hd.chd`) |

DKC£ dialogue: `exec dkc` (`#` = key `#38` with LOCK off), input volume `2`,
output `3` (FF) or `4` (80), `COPY FROM C1 TO FF/80 ? Y`, `CONTINUE ? Y`
(type `z` for Y, the active table swaps Y/Z). Per volume:
`MONT - DISMOUNT INPUT DISK` → eject, keypad Enter → `MOUNT INPUT DISK NR. nn`
→ insert next image, keypad Enter. FF volume 1 reports `COPY=03C3`, 80
volume 1 `COPY=03C5`; each 3848-sector floppy takes about 40 s emulated.

**Hack v3 (replaces v2's limit).** v2 forced the `KIO0 MX82` range-check
length at `03:2956` to `0x0F08`, which is the size of `ff1` only. The range
check compares request end (`[blk+0x0A]` + count − 1) with
`r3 + [UCB+0x62]`; at `03:296C` end < limit is in range, otherwise
`03:2972` → `03:29A6` returns the error. With `0x0F08` the first `ff2`
write (FF sector `0x0F09`, UCB `00:4072`, request `00:1646`) was rejected.
v3 sets `r3 = 0x7FFF` (env `LIMIT` in `run_state_probe.lua`), enough for FF
(`0x0F83`) and 80 (`0x372D`). Breakpoint unchanged otherwise:
`bpset 0x032956,{r3==0 && (r0&8000)==0},{r3=7fff; fcw=fcw&ffbf; g}`.

**The `ERR.C003 SEGMENT TRAP AT 1C,0004` after mounting `ff2`** was a
consequence of that rejection, through a kernel path that loses the task
pointer:

- Task TCB `00:81C2` (code segment `0x28`) starts the HD write with
  `sc #0x14` and waits with `sc #0x1B`. The `sc #0x1B` service at
  `03:0BF8` loads `rr8 = 0:TCB`, `rr6 = [TCB+0x0C]` (UCB), `r5 = [UCB+4]`
  (request), then `lda rr2,rr4(#0x98)` and `test @rr2`.
- If `[request+0x98]` is zero (request not queued, here because the range
  check rejected it), `03:0C0E` jumps to the dispatcher return `00:0062` →
  `02:0A34` with `r3` still `request+0x98` (`0x16DE`) instead of the TCB.
  The dispatcher resumes "TCB" `0x16DE`, whose saved frame is
  `1716:6500`; execution runs through zero memory to the segment trap.
- Normal waits take `03:0C12` (`sc #0x06` on the UCB event), which never
  arrives at this path. With hack v3 the request is queued and the path is
  not taken (0 hits in `d80b`). Diagnostic workaround, unused in the final
  runs: `bpset 0x030c0e,{dw@r3==0},{r3=r9; g}`.

**Save states.** MAME could not write any save state for this machine:
`upd7261_device::device_start()` registered `m_buf` with `save_pointer`
before allocating it, so zlib received a null input
(`STATERR_WRITE_ERROR`, file deleted, message only in a popup). The fix
allocates `m_buf` before registering it in
`mame_latest/mame/src/devices/machine/upd7261.cpp` (uncommitted; user
approved 2026-10-01). This is MAME's save-state bookkeeping and changes no
emulated behaviour, so no hardware documentation applies. With it,
`state_run.sh` resumes from `base02/sta/m40/mount02.sta` (272 s, at the
`MOUNT INPUT DISK NR. 02` prompt after `ff1`) or `base03/sta/m40/ffdone.sta`
(325 s, FF copy complete, OX `END OF PROGRAM`) in seconds instead of a
5-minute boot. Debugger breakpoints are not part of a state;
`run_state_probe.lua` re-arms hack v3 after loading. The unit-3 flag patch
(`00:D400` = `0x0801`) is in memory and therefore restored with the state.

## Issue 2: IPL from the GO363 (UC ROM)

Runs use the Issue 1D restored CHD unless noted; harness as in 1D.

| Run (`runs-archive/restore-hd-20260928/…`) | Result |
|---|---|
| `boot1/`: HD IPL, restored CHD | IPL stops at `8 2 4  REL 6.0` after ~70 s; GO363 sees only 3 board-ID reads |
| `base/`: HD IPL, untouched `wren2-ldhsel.chd` | Identical `8 2 4`, identical 3 ID reads |
| `m44/`: `m44` driver, M44 ROM `REL B.1` (`reference/roms/m44.zip`) | Blank screen, no GO363 access (UC048 not emulated) |
| `rom81/`, `rom81pc/`: `-bios m40-81` (`15 DIC. 81`), restored CHD | Halts before IPL: after the `0x00BC` delay loop (~3 s) the CPU sits in `0x00CA: jr 0x00CA` with `8` on screen. The code-8 path is the handler at `0x0078`, which accepts only interrupt identifiers `FF04`/`FF00`/`FF02`. `rom81nohd/` (no GO363, no CHD) halts identically, so this is not disk-related. The ROM also has no type 65 and no `0x90`–`0x9C` entries |

### Why the HD does not boot: REL 6.0 has no GO363 IPL

- The REL 6.0 IPL priority lists at `0x06E6`/`0x06E8` contain only
  `E4 EF E1 E0 E6`; type `65` is absent, so the ROM never issues a GO363
  command.
- The REL 6.0 vector table ends at `0x8C` (`0x60` → `0x1E58`, `0x64` →
  `0x1EB2`). LDHSEL's and HDU1ST24's `<<63>>0x94`/`0x9C` calls for types
  60/61/65 land inside ROM code.
- The M44 `REL B.1` ROM has these entries (`0x90`/`0x98` → `0x1296`,
  `0x94`/`0x9C` → `0x120A`). The HD boot blocks were therefore written for
  a later UC ROM than the emulated REL 6.0.

### ROMs available

Every UC ROM dump found locally has been tried: M40 `15 DIC. 81`, `17 DEC.
82`/REL 4.1 (same image), REL 6.0 (`reference/roms/`, `reference/roms/m40.zip`) and
M44 REL B.1 (`reference/roms/m44.zip`). The two large archives in `reference/zips`
contain no ROM files.

### Which machine the disks target

The backups come from a machine labelled M40: FF/80 carry VOL1 serial
`WV 0750522561`, and `oslem5.imd` has the same serial with
`VOL1-CONVERTED FROM BCS FORMAT- OLIVETTI M 40` and
`SYSTEMKONFIGURATION M40BC`. The GO363 itself is documented in the M34/M44
service manual (re/hardware/go363/GO363_DOCUMENTATION.md), the only ROM with GO363 IPL is the
M44's, and OSLEM7 contains a 1986 `LINEA INTERNA PER M44/M48` module. The
M34/M44 manual says M30/M40 can be upgraded with the newer boards, so the
original "M40" most likely had a later UC board or ROM. The OSLEM/BCOS
software itself is not model-specific (FF has `GCM30` and `GCM44`
configuration entries).

### Options

- Obtain a later M40 UC ROM dump (then only a new BIOS entry is needed).
- Emulate the M44 UC048 (M44 ROM plus the M34–M44 schematics in
  `~/Projects/P6066/reference/…/L1/`).
- Add GO363 IPL support to MAME, modelled on the M44 ROM's
  `0x120A`/`0x1880` code; AGENTS.md requires hardware documentation first
  (`reference/ArchiviOlivetti/M30-M40_HDC.pdf` is the unread candidate).
- Patch the REL 6.0 ROM image itself, outside MAME.

### Resolution: a patched REL 6.0 ROM

The last option was taken. `tools/mkrom_hd65.py` edits the round-trippable
REL 6.0 source (`re/disassembly/m40-rom/`) and rebuilds it as
`reference/roms/m40rom-6.0-hd65.bin`:

1. the service table is extended to `0x8C`–`0x9F` as on the M44 REL B.1 ROM,
   so LDHSEL's and HDU1ST24's `<<63>>0x94`/`0x9C` calls reach a routine (the VI
   dispatcher that occupied `0x8C` moves to `0xA0`);
2. type `E4` in the HDU-first IPL list is replaced by `65`, with a new handler;
3. a polled GO363/uPD7261 sector read is added in free space, using the
   register sequence the OSLEM 7+ driver `H65R` issues;
4. the ROM checksum is recomputed.

Geometry is fixed at 9 heads × 32 sectors (WREN2). This ROM never existed; it
is an emulation aid, and MAME needs no change for it (it is loaded with
`-rompath`). With it the installed disk IPLs, LDHSEL loads, and BCOS II runs
to `/SYS`; MOS boots from its own disk the same way.

## Keyboard notes (current MAME mapping)

Alt+C clears `E`/`KE`; F8 acknowledges `*ERROR*`; keypad Enter submits;
main Enter for `Press S bar` / `AFTER ANY KEY`; Shift+letter for capitals
(physical key presses, not MAME natural-keyboard capitals); keypad digits
for drive numbers (`FD2` = Shift+F, Shift+D, keypad 2).

## Next

1. ~~Step 10 / Issue 2~~: done with the patched hd65 ROM (Issue 2, Resolution).
2. **Issue 1 (understanding, not blocking):** why `oslem7+` needs the
   unit-3 flag patch and the `03:2956` range-check override. The hacks only
   bypass checks; the root cause (the `0x83` value, 1E) is still open.
