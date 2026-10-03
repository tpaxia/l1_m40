# Diagnostic Disk G

- Subsystem: HDU WREN/Micropolis/ST506
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`
- DML special/catalog loader: `UTILY884870331`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162508-diag-tests-G`
- Post-Enter monitor run: `runs-archive/20260716-164525-enter-menu-G`
- Post-Enter screen dump: [monitor_menu_G.txt](monitor_menu_G.txt)
- Generated MAP inventory: [monitor_map_G.txt](monitor_map_G.txt)

## Captured Boot Screen

```text
(MAR 31 1987)    SYSTEM ENVIRONMENT         RAM SIZE  0448 KB
  0 FF-0000           1 FE-0000           2 E1-0000           3 FF-0000
  4 FF-0000           5 FF-0000           6 FF-0000           7 FF-0000
  8 FF-0000           9 FF-0000          10 FF-0000          11 FF-0000
 12 FF-0000          13 FF-0000          14 00-0000          15 FF-0000
   HIT "ENTER" FOR DIAGNOSTIC MONITOR
```

## Captured Monitor Menu

```text
DIAGNOSTIC MONITOR  8.4 870331  K.03970
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_G.txt](monitor_map_G.txt). This is generated
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
| 3 | `HDC5F583861117` | `00` | `0x122c` | 5 | `0x3c700` | 1280 | GO363/HDC5 ST506 hard-disk controller diagnostic family. |
| 4 | `HDC5E984870331` | `00` | `0x12fa` | 49 | `0x49500` | 12544 | GO363/HDC5 ST506 hard-disk controller diagnostic family. |
| 5 | `HDC5V683861117` | `01` | `0x17a2` | 39 | `0x64100` | 9984 | GO363/HDC5 ST506 hard-disk controller diagnostic family. |
| 6 | `HDC50584870331` | `01` | `0x1fa4` | 41 | `0x7e300` | 10496 | GO363/HDC5 ST506 hard-disk controller diagnostic family. |
| 7 | `HDC5X383851212` | `01` | `0x270e` | 45 | `0x8ed00` | 11520 | GO363/HDC5 ST506 hard-disk controller diagnostic family. |
| 8 | `S24W1683851212` | `00` | `0x2db0` | 3 | `0x9c700` | 768 | 24-sector hard-disk media/seek/format/verify support test. |
| 9 | `S24W2583851212` | `00` | `0x30d6` | 23 | `0xa8900` | 5888 | 24-sector hard-disk media/seek/format/verify support test. |
| 10 | `S24M5483851212` | `00` | `0x34d6` | 29 | `0xb5900` | 7424 | 24-sector hard-disk media/seek/format/verify support test. |
| 11 | `S24X1183860616` | `00` | `0x38d6` | 35 | `0xc2900` | 8960 | 24-sector hard-disk media/seek/format/verify support test. |
| 12 | `S24WD083860616` | `00` | `0x3cd6` | 41 | `0xcf900` | 10496 | 24-sector hard-disk media/seek/format/verify support test. |
| 13 | `S24MA183861117` | `00` | `0x40d6` | 47 | `0xdc900` | 12032 | 24-sector hard-disk media/seek/format/verify support test. |
