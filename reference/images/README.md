# Disk images

Every floppy image from the two `Disk Images` folders, in one place and in
ImageDisk (IMD) format. These are copies: the originals in `../Disk Images/`
and `../Disk Images (Stefano Marinelli + others)/` stay where they are and
are unchanged. The images are local only (git-ignored); only this README is
tracked.

## Where each folder comes from

| Folder | Source |
|---|---|
| `bcos/` | `Disk Images/`: the Olivetti BCOS II 3.3 and 5.0 distribution set (K02733–K02757) and DEE 2.1 (K02767) |
| `restore-hd/` | `Ripristino_HD/`: the OSLEM 5, 6, 6 ST506, 7 and 7+ boot disks and the FF / 80 data-set disks used to restore the BCOS hard disk |
| `bcos-christian/` | `BcosII M30M40 Christian ok/`: a second copy of the OSLEM 7+ and FF / 80 data-set disks |
| `diagnostics/` | `diagnostici l1 dcos 8.4/`: the DCOS 8.4 diagnostic disks A–H and R |
| `ese-mdos/` | `Ese L1/`: ESE, MDOS 2.0 (`probejsf.imd`), 3.0, 3.1 (`m40.imd`), 3.2 and MDOS utilities. The copy of `M40MDO32.imd` in `LM40 da rep ceca/` is identical to this one |
| `gardini/` | `Gardini/`: the Gardini utility disk (`gardini.TD0` is the same disk in Teledisk format) |
| `mos/` | `Mos/`: the MOS ST506 starter and the DPC_ALLES volumes DPC51–55 and DPC71–77 |

## Images converted from flux

Fifteen BCOS disks existed only as SuperCard Pro flux captures (`.scp`):
K02734–K02736, K02738–K02743 and K02752–K02757. Their IMDs here were made
with keirf's Disk-Utilities:

```sh
disk-analyse -q -r 360 'Disk Images/<name>.scp' images/bcos/<name>.imd
```

`-r 360` sets the 360 rpm of the 8-inch drives. Every conversion reports
"6 tracks are damaged or unidentified". The images used in the emulation
work were made the same way; fresh conversions of K02741, K02743 and K02753
hold the same sector data as the copies that were run (only the IMD header
timestamp differs), as does K02733 against its IMD in `Disk Images/`.

The other images (`K02733`, `K02737`, `K02767`, `BCOS_II_3.3_FD_ALL_RESIDENT`
and everything outside `bcos/`) were already IMD files in the source
folders and are copied unchanged.
