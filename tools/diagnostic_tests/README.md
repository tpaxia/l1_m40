# M40 Diagnostic Test Inventory

Generated from the DCOS 8.4 diagnostic disk DML catalogs, with one
MAME boot-screen capture per disk. The emulator reaches the common
`SYSTEM ENVIRONMENT` / `HIT "ENTER" FOR DIAGNOSTIC MONITOR` screen on all
nine disks, and the GO252/KDC keyboard path can now inject Enter to reach
the Diagnostic Monitor menu.

## Disks

| Disk | Subsystem | Catalog special | Entries | Inventory | Monitor menu | MAP inventory |
|---|---|---|---:|---|---|---|
| A | central unit / RAM / UC | `UTILY884871127` | 22 | [disk_A.md](disk_A.md) | [monitor_menu_A.txt](monitor_menu_A.txt) | [monitor_map_A.txt](monitor_map_A.txt) |
| B | KDC video-keyboard / MUX | `UTILY884870331` | 22 | [disk_B.md](disk_B.md) | [monitor_menu_B.txt](monitor_menu_B.txt) | [monitor_map_B.txt](monitor_map_B.txt) |
| C | line controllers | `UTILY884871127` | 18 | [disk_C.md](disk_C.md) | [monitor_menu_C.txt](monitor_menu_C.txt) | [monitor_map_C.txt](monitor_map_C.txt) |
| D | FDU / MFDU / STC / MTU | `UTILY884871127` | 15 | [disk_D.md](disk_D.md) | [monitor_menu_D.txt](monitor_menu_D.txt) | [monitor_map_D.txt](monitor_map_D.txt) |
| E | HDU 18/14 MB | `UTILY884870331` | 14 | [disk_E.md](disk_E.md) | [monitor_menu_E.txt](monitor_menu_E.txt) | [monitor_map_E.txt](monitor_map_E.txt) |
| F | HDU 60/120 MB Fujitsu SMD | `UTILY884870331` | 15 | [disk_F.md](disk_F.md) | [monitor_menu_F.txt](monitor_menu_F.txt) | [monitor_map_F.txt](monitor_map_F.txt) |
| G | HDU WREN/Micropolis/ST506 | `UTILY884870331` | 12 | [disk_G.md](disk_G.md) | [monitor_menu_G.txt](monitor_menu_G.txt) | [monitor_map_G.txt](monitor_map_G.txt) |
| H | HDU 140 MB ESDI | `UTILY884871127` | 8 | [disk_H.md](disk_H.md) | [monitor_menu_H.txt](monitor_menu_H.txt) | [monitor_map_H.txt](monitor_map_H.txt) |
| R | reduced 3930 set | `UTILY884871127` | 19 | [disk_R.md](disk_R.md) | [monitor_menu_R.txt](monitor_menu_R.txt) | [monitor_map_R.txt](monitor_map_R.txt) |

## Collection Status

- MAME was run for disks A, B, C, D, E, F, G, H, and R with `--vram-trace`.
- Each run reached console sequence `01 02 44 55 21 FF` and displayed the common prompt.
- Enter is delivered as KDC byte `0x52`, which the monitor accepts as the prompt key.
- Verified post-Enter monitor-menu dumps are present as `monitor_menu_A.txt` through `monitor_menu_H.txt`, plus `monitor_menu_R.txt`.
- Disk B option `2` reaches the runtime `DCOS *L1* LIBRARY` MAP page; the first page confirms the DML-derived program codes/names/releases/dates through entries 001-021.
- The monitor/help/manual path is: `1` = LOAD by MAP code, `2` = MAP, `4` = GO; SKIP is the documented back-page/back-to-menu key.
- Generated `monitor_map_*.txt` files enumerate every known program code from the DML catalog, including entries beyond the first visible MAP page; their LOC/LEN fields are DML fields, not a byte-for-byte runtime MAP transcript.
