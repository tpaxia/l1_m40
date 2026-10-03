# Checkpoints

Saved machine states and hard-disk images from the GO363 work, kept so a
long procedure can be resumed at any stage instead of rerun (about 390 MB;
the largest file is 8 MB). The runs these came from are in the local run
archive, backed up on `/Volumes/Backups/Projects/M40_re_backups/`.

Save states depend on the MAME build that made them: a build whose devices
save different fields may refuse to load them. The disk images do not have
this limit.

## `bcos-hd/`: BCOS II and OSLEM on the WREN2

Used by `scripts/harness/` (`bcos_run.sh`, `state_run.sh`, `cos_try.sh`);
background in `re/os/oslem/OSLEM_STATUS.md` and `tools/L1_DISK_FORMATS.md`
section 9.

| File | What it is |
|---|---|
| `wren2-restored.chd` | Trial restore written by `build_restore.py` (OSLEM_STATUS Issue 1D) |
| `wren2-bcos-installed-baseline.chd` | The disk after the BCOS II install |
| `hd-after-dkc.chd`, `hd-after-ff.chd`, `hd-after-mx24.chd`, `hd-after-toc.chd` | Intermediate disks after each install step |
| `hd-bcos-kusa.chd`, `hd.chd` | The installed disk (`hd.chd` is the one in OSLEM_STATUS step 10 / Issue 2) |
| `oslem7.imd`, `ff1.imd`, `ff2.imd`, `80-1.imd` … `80-4.imd` | Working copies of the OSLEM 7+ boot floppy and the data-set floppies used by the install |
| `oslem7_keymap.txt`, `kita_keymap.txt` | The active OSLEM 7+ and Italian keymaps |
| `bcos-base/` | `hd.chd` + states `bcos-sys` (BCOS II at `/SYS`, 300 s), `bcos-cos-ky` (the `COS#` utility on its keyboard record page, used by `cos_try.sh`) and `bcos-cos` (undocumented; by its name, `COS#` before that page) |
| `base02/` | `hd.chd`, `ff1.imd` + state `mount02` (272 s, DKC£ FF at `MOUNT INPUT DISK NR. 02`) |
| `base03/` | `hd.chd` + state `ffdone` (325 s, FF copied, `END OF PROGRAM`) |

States are in `<dir>/sta/m40/<name>.sta`; pass `BASE=<dir>` and
`STATE=<name>` to the harness scripts.

## `mos-install/`: MOS from the starter disk

Used by `scripts/mos-install/step.sh` and `hdrun.sh`; each new stage adds its
state and disk snapshot here.

| Path | What it is |
|---|---|
| `wren2-formatted-hdc5f5.chd` | The WREN2 formatted by HDC5F5: the cold-start disk |
| `starter.imd` | Working copy of the MOS ST506 starter |
| `sta/m40/s0-date.sta` … `s9-down.sta` | One state per install stage: date, time, install menu, SYS_INSTALL, the DPC_ALLES prompt and each of its seven volumes, USR_INSTALL, CHM_INSTALL, shutdown |
| `snap/<stage>/` | The disks (`hd.chd`, `starter.imd`, `dpc71.imd` … `dpc77.imd`) at each stage |
| `mos-hd-installed.chd`, `mos-hd-bootable.chd` | The installed disk, and the same with the LDHSEL loader added (the image published in `mame_disks` as `m40-mos-hd.chd`) |
| `hd/sta/m40/*.sta`, `hd/<name>/hd.chd` | States and disks from booting the installed system: `h0-login` (login prompt), `h1a`–`h2-root` (user name), `h3-shell` (date and time), `h4-in` (root menu), `h5-mcl` (MCL), `h6-down` (logout and shutdown); `t1`–`t6` are MCL sessions (`ls /ipl`, `ls /ipl/dpc`, `pry`, `shdate`, `who`, `mkdir`, `copy`) used to list the installed software |
