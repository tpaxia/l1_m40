# M30/M40 operating-system media boot survey

## 2026-09-20 cross-version retest on MAME 8920b132a11

Fresh 160-second probes used the same clean `m40_z8010_sup_test` executable as
the successful ESE retest, ROM 6.0, 2 MB RAM, verified floppy IPL (`ISL=00`),
disposable media copies, and isolated configuration/NVRAM directories.

| Family / image | Current result | Evidence |
|---|---|---|
| ESE 3.1 `ESE.IMD` | **Boots:** visible `READY` | `runs/os-ese.LHQL2l` |
| MDOS 3.0 `MDOS30.IMD` | **Boots:** visible `READY` | `runs/os-mdos.16dmel` |
| MDOS 3.1 utility `MDOSUTIL.IMD` | **Boots:** visible `READY` | `runs/os-mdosutil.CNUQ4b` |
| MDOSC 2.0 `probejsf.imd` | Loads the OS but stops at visible `ERROR 172` | `runs/os-mdos20.mbbHPT` |
| MDOSC 3.1 `m40.imd` | Loads the OS but cycles through visible `ERROR 172` | `runs/os-mdos31.PrqGFM` |
| MDOSC 3.2 `M40MDO32.imd` | Loads the OS but repeats visible `ERROR 173` | `runs/os-mdos32.Gi6GzW` |
| BCOS II 3.3 all-resident | **Boots:** reaches the BCOS mono-user banner and `REMOUNTING SYSTEM DISK ALLOWED`; stable scheduler at `02:0912..0920` | `runs/os-bcos33.04XtmY` |
| BCOS II 3.3 K02733 configurator | **Boots:** reaches the interactive `DATE YYMMDD` prompt; stable scheduler at `02:0912..0920` | `runs/os-bcos33-config.PrkwLJ` |
| BCOS II 3.3 generated LOAD/RUN | **Boots:** the recent branch regression reaches the password prompt when LOAD is explicitly ejected, the drive remains empty for two emulated seconds, and RUN is inserted | `runs/bcos-generated-boot.cOPRTL` |
| BCOS II 5.0 all-resident K02753 | **Partial boot only:** the correctly decoded 360-RPM image displays the NLS-3000 system-environment page and reaches the normal scheduler at `02:0e0c..0e1a`, but does not advance to a usable prompt | `runs/os-bcos50.eeWMvD` |
| MOS `StarterST506.IMD` | **Does not boot:** with GO363 and a fresh 40 MB CHD it remains on a blank display in the diagnostic-lamp delay at `04:65d8` | `runs/os-mos.2nWw01` |

MDOS30 is indeed an ESE-family system rather than a separate operating-system
architecture.  The reverse-engineering extracts in the P6066 repository show
that `MDOS30.IMD` and `ESE.IMD` contain byte-identical `OSLIB`, `L1ESEF`, and
EP60 3.1 interpreter allocations.  MDOS30 also contains substantial German
text (`DATUM`, `FEHLER`, `AENDERUNGEN`, and service records), so describing this
particular volume as a German ESE distribution is supported by its contents.
The complete disk images differ, which explains their different startup paths.

MOS remains blocked before hard-disk initialization.  GO363/ST506 support was
ported onto the current Z8010/Sadie-integrated M40 branch at `576ccea57ec` and
the exact-tip run attached a fresh 425/12/32/256 CHD.  `StarterST506` still
remains on a blank display in the diagnostic-lamp delay at `04:65d8`, exactly
matching the no-controller endpoint.  The starter has not yet issued a GO363
command beyond the ROM's board-identification reads, so this result does not
implicate the attached CHD or the controller command implementation.

## 2026-09-20 ESE retest on MAME 8920b132a11

**ESE now boots to a visible `READY` prompt.**  A fresh, bounded 160-second
run used ROM 6.0, the 2 MB RAM board profile, verified floppy IPL (`ISL=00`),
default cards, Normal key switches, an isolated configuration/NVRAM directory,
and a disposable copy of `ESE.IMD`.  The clean executable identifies itself as
`mame0289-987-g8920b132a11`.  The prompt was visible at 90 seconds and remained
on screen at the final 159-second capture.  The CPU continued to move
through ESE code (final sample `03:1A36`, FCW `D008`), so this is neither the ROM
prompt nor a stopped processor.  Evidence: `runs/os-ese.LHQL2l`.

All seven sampled PC/FCW pairs match the preceding cccb239075b dirty-build run
exactly, including the final endpoint.  This confirms that the direct Z8010
bus-cycle cleanup at 8920b132a11 preserves the successful ESE boot.

This supersedes the blank-display ESE result below.  Interactive ESE input and
the full `SYSTEM ENVIRONMENT` display seen on the real L1/ESE-R 3.1 machine
remain to be exercised; the existing optional key-injection path currently
crashes the Lua harness during initialization, before guest execution, when a
command is requested.  The boot harness was updated for MAME's RAM-slot API
(`-ram 2m` and the selected RAM-device tag) and SDL3's dummy headless driver;
no emulator or guest-media behavior was patched for this test.

## 2026-09-15 retest on MAME a421751bf44

Fresh runs, ROM 6.0, 2048K RAM, verified floppy IPL (ISL bits 00), default
cards, Normal key switches, disposable disk copies, isolated cfg/NVRAM.
All runs were headless and bounded to 160 emulated seconds; no native changes,
guest patches, or interactive-session manipulation.

| Disk | Current endpoint | Run |
|---|---|---|
| MDOS30.IMD | Visible READY; final PC 14:0968 | `runs/os-mdos.4Fvz6s` |
| ESE.IMD | Blank display through 159 s; sampled CPU executes OS addresses, final PC 03:1A36 | `runs/os-ese.gEmHe7` |
| M40MDO32.imd | Visible ERROR 173, repeated; final PC 14:0968 | `runs/os-mdos32.NccEEF` |
| MOS StarterST506.IMD | Blank console; PC 04:65D8 at 90/139/159 s, 04:65E8 at 119 s | `runs/os-mos.T7FP0n` |

MOS used GO363 in slot 5 and a fresh blank 425-cylinder, 12-head,
32-sector, 256-byte/sector CHD. The existing conversion helper omitted the
single zero-filled cylinder-77 record from the disposable starter copy;
all retained IMD records are copied verbatim and the original is untouched.
The endpoint reproduces the September 9 diagnostic-lamp delay path, not a
MOS console or installation prompt. This retest does not establish the
underlying failure or prove a particular missing GO363 feature is responsible.

MOS no-HD comparison on the same build and starter copy:

- `mos-nohd`: explicitly empty slot 5, no HD controller/image;
  `runs/os-mos-nohd.l3ro6K`.
- `mos-nomedia`: GO363 in slot 5, no HD image;
  `runs/os-mos-nomedia.Wbj5fW`.

Both exited normally after 160 emulated seconds, with blank guest displays.
Both sampled PC 04:65D8 at 90/139/159 seconds and 04:65E8 at 119 seconds,
FCW D040, matching the controller-plus-blank-disk test. Removing either the
disk image or the controller does not avoid this failure path. This weakens
the hypothesis that the attached blank CHD itself causes the observed stop;
it does not establish whether the starter requires an HD or why it enters
the diagnostic-lamp path. Only the boot-test script was extended.

MDOS30 input trials:

- Keypad Enter at 120/145 s: ERROR 190 (`runs/os-mdos.6AZtUg`).
- Main Enter at 120/145 s: ERROR 190 (`runs/os-mdos.BZicFX`).
- Attempted Shift-letter sequence PRINT, Space, keypad 1, keypad Enter:
  display contains `OR PRINT WRITE: NEXT USING 1`, followed by ERROR 190
  (`runs/os-mdos.Kt39nZ`). Keys are reaching the guest, but the host-letter
  sequence is not producing literal PRINT under this keyboard interpretation.
  This is not a successful BASIC execution test; keyword entry/mode needs
  investigation before claiming the command interpreter is usable.

ESE stayed blank with keypad Enter (`runs/os-ese.Xz7W6R`) and main Enter
(`runs/os-ese.xuxJju`). Blank output alone does not establish a CPU hang or
prove the historical graphics-console hypothesis. Errors 173/190 have not
been assigned meanings from a matching manual.

The local ESE PDF, `reference/Manuals/PARTE 1/M30ST M40ST - Software di Base - ESE.pdf`,
is a two-page feature sheet, not an operating/error manual. OCR confirms that
it describes an extended BASIC and immediate calculator mode, but supplies
no boot-key sequence or error-code definitions.

Harness changes only: added `ese` and `mdos32` media choices to
`scripts/test-m40-os.sh`; added SPACE field lookup to the existing optional
input observer `scripts/lua/mame_bcos_state.lua`. No changes to MAME itself.
The older survey below remains historical, not the current boot result.

## 2026-09-09 retest on MAME commit 871bc96bf69

These results supersede the older MDOS30 blank-console result below. Both runs
used ROM 6.0, 2048K RAM, background/null video, disposable media, fresh NVRAM and
160 emulated seconds. No MAME source changes or status overrides were used.

- **MDOS30: reaches visible READY.** `runs/os-mdos.KBcxRE/159-screen.png`.
  CPU at 14:0968, FCW 9810. This run used default ISL1 (the initial observer's
  attempt to change a configuration switch with `set_value` was ineffective).
  No commands were entered, so application/input behavior remains untested.
- **MOS StarterST506: does not reach a console.** `runs/os-mos.dZq9Z9/` used
  GO363 in slot 5, blank CHD 425/12/32/256, and verified ISL2 (switch bits 00).
  At 139/159 s the PC samples are 04:65D8 in a delay loop within the diagnostic
  lamp display routine (writes FF64–FF6F). The screen is blank. This is a
  more specific current failure than the historical lost-control-flow result.
  The cause of the lamp/error path is not yet established.

The original MOS IMD cannot mount in the configured 77-cylinder drive: it has
one extra cylinder-77 record containing one zero-filled sector. The disposable
copy omits only that verified zero record; all retained records are copied
byte-for-byte by `tools/imd_trim_empty_tail.py`. Original media is untouched.
`runs/os-mos.B4spbo` is the rejected-original-image attempt, not an OS execution;
`runs/os-mos.0MCg9Z` is the intermediate default-ISL1 run, not the final ISL2 test.

Reproducer: `sh scripts/test-m40-os.sh mdos` or `sh scripts/test-m40-os.sh mos`.
The current observer uses `field.user_value` and verifies ISL2 after input update.
It captures screens, CPU registers and saved RAM/MMU data; it does not patch code.
All test processes exited normally except the explicitly noted image rejection.

## Historical survey

Survey performed with the current `olivetti_m40` driver and M40 ROM 6.0. Each viable
image was run for 90 emulated seconds. CPU state and screen snapshots were sampled at
25, 40, 60, and 90 seconds. Diagnostic disks are intentionally excluded: they are
already known to boot and are not candidate user operating systems.

## Recommendation

Use **`BCOS_II_3.3_FD_ALL_RESIDENT`** as the first interactive target. It already
drives the GO252 display and accepts GO252 keyboard interrupts. Its remaining
`PUS=DISK` state is a configuration/runtime-volume problem, but it is a smaller and
better-grounded target than inventing the graphics console expected by the ESE media.

`MDOS30.IMD` remains valuable as a scheduler and floppy regression test: with ROM 6.0
it loads completely and remains stable at `02:0912..0920`. However, all inspected ESE
images embed `VIDEO DISPLAY: GRAPHIC`, while the implemented GO252 is the alphanumeric
console. The earlier slot-E line-card conclusion was caused by the old driver's bogus
`FF-0000` result for an absent slot and has been withdrawn.

## Results

| Image | Result | Suitability |
|---|---|---|
| `MDOS30.IMD` | With ROM 6.0, loads completely and idles normally at `02:0912..0920`; GO280 runtime activity continues. Its embedded environment specifies a graphic display, not the implemented alphanumeric GO252. | Strong regression test; console hardware/configuration is unresolved |
| `ESE.IMD` | Same L1/ESE 3.1 system files and same stable scheduler behavior as MDOS30. | Equivalent, but MDOS30 already has much more trace work |
| `MDOSUTIL.IMD` | Same stable L1/ESE scheduler; utility payload rather than the preferred working disk. | Useful companion after MDOS30 boots |
| `probejsf.imd` | Older MDOSC 2.0 image; reaches its stable scheduler at `02:0668` but has no local console output. | Possible, but older and less studied |
| `m40.imd` | MDOSC 3.1 image explicitly labeled for M40 and containing `READY TO RUN`; enters a persistent `02:43xx` display/terminal path with a blank screen. Its embedded environment describes the video as `GRAPHIC`. | More configuration and execution uncertainty than MDOS30 |
| `M40MDO32.imd` | MDOSC 3.2; behavior is identical to `m40.imd` in the current configuration. | Second choice only after MDOS30 |
| `BCOS_II_3.3_FD_ALL_RESIDENT` | Boots, displays the `SYS`/`PUS=DISK` environment page, accepts GO252 interrupts, and idles normally. The disk is generation `BCS431`; no matching generated runtime volume has been found. | **Best interactive target** |
| `K02733_BCOS_II_3.3_CONFIGURATOR` | Boots stably as a load-time system from FDU unit 1 (`-flop2`) after correcting GO280 ENSOO pending-latch behavior. It reaches `PUS=DISK OK`, `LDK=E100`, `TIMEOK==KEYB` and the normal scheduler. Traces have not shown a read from the other drive, so earlier companion-volume conclusions are withdrawn. It has not entered the on-line generator UI. | Proven bootable configurator media; generator transition still unresolved |
| `K02753_BCOS_II_5.0_ALL_RESIDENT` | Displays a partial `NLS-3000` environment and waits in a fixed synchronization loop at `03:03de..03e0`. | Worse than BCOS 3.3 |
| `oslem7+.imd` | Its M38/M48 environment page is a false positive: after `iret`, a segment-0 access raises `SEGTRAP`, whose uninitialized PSA entry is `20:2020`; the CPU then walks padding and happens to execute display modules while passing through them. | Wrong machine/MMU configuration; not a patch candidate |
| Christian `801.imd`–`804.imd` | All four enter the same REL 6.0 ROM IPL wait at `00:06be`, with byte-identical final screens and CPU state. They are volumes from one BCOS set, not four alternative IPL systems. | Not standalone boot disks |
| `ff1.imd` | Shows only a fragmentary REL 6.0 display and stalls in the loader. | Not a standalone candidate |
| `StarterST506.IMD` | The image is valid 80-track 5.25-inch media. With a temporary 5.25-inch drive option it loads and stops at `3A:0190`, before a console; it expects the GO363/ST506 path. | Blocked by incomplete hard-disk emulation |
| `DPC51.IMD` | Valid MOS distribution media but not a standalone IPL system disk. | Runtime component only |

The remaining MOS `DPC52`–`DPC77` images are distribution/runtime components. Their
contents include MOS 5.2 utilities, login, compilers, and applications, but the set's
starter path still depends on the ST506 system disk and GO363 behavior.

## Why the slot-E line-card approach was rejected

The old monolithic driver returned `FF-0000` when ROM probing touched an absent slot.
The hardware diagnostics and the current backplane correctly return `FF-FFFF`. The
malformed old configuration entry selected segment `3E` and its `E0xx` line path;
that path disappears when absent-slot READY/NMI behavior is modeled correctly.

No provisional line card remains in the driver. Normal ROM-6.0 execution of
`MDOS30.IMD` reaches the scheduler without entering segment `3E` or accessing window
E. The next ESE task is to identify the configured graphics device or patch the media
configuration to the alphanumeric GO252. BCOS 3.3 is preferable for immediate
interactive work because its GO252 display path is already proven.
