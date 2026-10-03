# Diagnostic Disk C

- Subsystem: line controllers
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/C.IMD`
- DML special/catalog loader: `UTILY884871127`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162445-diag-tests-C`
- Post-Enter monitor run: `runs-archive/20260716-164505-enter-menu-C`
- Post-Enter screen dump: [monitor_menu_C.txt](monitor_menu_C.txt)
- Generated MAP inventory: [monitor_map_C.txt](monitor_map_C.txt)

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
DIAGNOSTIC MONITOR  8.4 870331  K.04355
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_C.txt](monitor_map_C.txt). This is generated
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
| 3 | `GLAV2883851212` | `00` | `0x122c` | 5 | `0x3c700` | 1280 |  |
| 4 | `LCUX2681850329` | `00` | `0x12bc` | 49 | `0x45700` | 12544 |  |
| 5 | `TWIN0581850329` | `00` | `0x16da` | 29 | `0x54500` | 7424 |  |
| 6 | `W24D0883861117` | `00` | `0x1af6` | 39 | `0x63100` | 9984 |  |
| 7 | `LIONV481850329` | `00` | `0x1f9a` | 25 | `0x6d900` | 6400 |  |
| 8 | `96ERM684870331` | `00` | `0x22c8` | 23 | `0x7a300` | 5888 |  |
| 9 | `96ERS684870331` | `00` | `0x26e6` | 15 | `0x89100` | 3840 |  |
| 10 | `STARL084870331` | `00` | `0x2a92` | 37 | `0x90d00` | 9472 |  |
| 11 | `SLANC484871127` | `00` | `0x2da8` | 27 | `0x9bf00` | 6912 |  |
| 12 | `ER200581850329` | `00` | `0x3078` | 39 | `0xa2b00` | 9984 |  |
| 13 | `ERS20484870331` | `00` | `0x336c` | 3 | `0xabb00` | 768 |  |
| 14 | `L2V24883861117` | `00` | `0x3568` | 7 | `0xb1f00` | 1792 |  |
| 15 | `V24L2783861117` | `00` | `0x37bc` | 7 | `0xbdb00` | 1792 |  |
| 16 | `W24S0783861117` | `00` | `0x3abc` | 39 | `0xc7700` | 9984 |  |
| 17 | `L9V24483861117` | `00` | `0x3e9c` | 19 | `0xd2700` | 4864 |  |
| 18 | `ETHER284870331` | `00` | `0x41bc` | 19 | `0xde300` | 4864 |  |
| 19 | `ETCOL484871127` | `00` | `0x44a8` | 51 | `0xe6b00` | 13056 |  |
