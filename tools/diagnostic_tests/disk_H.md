# Diagnostic Disk H

- Subsystem: HDU 140 MB ESDI
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/H.IMD`
- DML special/catalog loader: `UTILY884871127`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162508-diag-tests-H`
- Post-Enter monitor run: `runs-archive/20260716-164525-enter-menu-H`
- Post-Enter screen dump: [monitor_menu_H.txt](monitor_menu_H.txt)
- Generated MAP inventory: [monitor_map_H.txt](monitor_map_H.txt)

## Captured Boot Screen

```text
(NOV 27 1987)    SYSTEM ENVIRONMENT         RAM SIZE  0448 KB
  0 FF-0000           1 FE-0000           2 E1-0000           3 FF-0000
  4 FF-0000           5 FF-0000           6 FF-0000           7 FF-0000
  8 FF-0000           9 FF-0000          10 FF-0000          11 FF-0000
 12 FF-0000          13 FF-0000          14 00-0000          15 FF-0000
   HIT "ENTER" FOR DIAGNOSTIC MONITOR
```

## Captured Monitor Menu

```text
DIAGNOSTIC MONITOR  8.4 870331  K.04356
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_H.txt](monitor_map_H.txt). This is generated
from the DML catalog records, not from manually paging the monitor UI.
The runtime MAP screen shows TR/ST and its own LENGHT unit; the generated
file records DML loc and sector/byte length instead.


## Available Catalog Entries

These are the DML catalog payloads present on the disk. The emulator can
inject Enter, select monitor options, and disk B has been verified reaching
the runtime MAP catalogue screen. The table is the machine-derived full
inventory of available tests/support overlays.

| Idx | Name | Ext | Loc | Len sectors | Flat offset | Bytes | Notes |
|---:|---|---:|---:|---:|---:|---:|---|
| 2 | `HDFDU784870331` | `00` | `0x106c` | 1 | `0x39f00` | 256 |  |
| 3 | `ESDIF384871127` | `00` | `0x122c` | 5 | `0x3c700` | 1280 | ESDI hard-disk diagnostic family. |
| 4 | `ESDIE183861117` | `01` | `0x12c4` | 49 | `0x55f00` | 12544 | ESDI hard-disk diagnostic family. |
| 5 | `ESDIV284871127` | `01` | `0x1be2` | 33 | `0x75100` | 8448 | ESDI hard-disk diagnostic family. |
| 6 | `EIM3S084871127` | `01` | `0x2486` | 47 | `0x8c900` | 12032 |  |
| 7 | `ESDIT183861117` | `01` | `0x2c78` | 21 | `0xa5b00` | 5376 | ESDI hard-disk diagnostic family. |
| 8 | `EIW3S383861117` | `01` | `0x3300` | 33 | `0xb4f00` | 8448 |  |
| 9 | `EIM5S383861117` | `01` | `0x3878` | 29 | `0xccb00` | 7424 |  |
