# Diagnostic Disk D

- Subsystem: FDU / MFDU / STC / MTU
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/D.IMD`
- DML special/catalog loader: `UTILY884871127`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162456-diag-tests-D`
- Post-Enter monitor run: `runs-archive/20260716-164505-enter-menu-D`
- Post-Enter screen dump: [monitor_menu_D.txt](monitor_menu_D.txt)
- Generated MAP inventory: [monitor_map_D.txt](monitor_map_D.txt)

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

See [monitor_map_D.txt](monitor_map_D.txt). This is generated
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
| 3 | `7032E584870331` | `00` | `0x122c` | 5 | `0x3c700` | 1280 | FDU/MFDU error-rate test. |
| 4 | `FDUMA280840810` | `00` | `0x12f8` | 49 | `0x49300` | 12544 | FDU alignment/eccentricity test. |
| 5 | `4301T483851212` | `00` | `0x17aa` | 37 | `0x54900` | 9472 | MFDU running-test variant. |
| 6 | `4305T684870331` | `00` | `0x1aca` | 51 | `0x60500` | 13056 | MFDU running-test variant. |
| 7 | `6030T683861117` | `00` | `0x1ece` | 45 | `0x6d900` | 11520 | XU/XG6030 FDU running test; controller communication, timer, interrupt, DMA, format/read/write. |
| 8 | `SCT30381850329` | `00` | `0x22ca` | 43 | `0x7a500` | 11008 |  |
| 9 | `STC40484870331` | `00` | `0x26ac` | 37 | `0x85700` | 9472 |  |
| 10 | `SCTER781850329` | `00` | `0x2abc` | 1 | `0x93700` | 256 |  |
| 11 | `EPCOV381850329` | `00` | `0x2d82` | 33 | `0x99900` | 8448 |  |
| 12 | `CPCOV184870331` | `00` | `0x308a` | 7 | `0xa3d00` | 1792 |  |
| 13 | `STC5E283861117` | `00` | `0x3286` | 41 | `0xaa100` | 10496 |  |
| 14 | `STC5T384871127` | `00` | `0x35b2` | 19 | `0xb6900` | 4864 |  |
| 15 | `MTUER784870331` | `00` | `0x38da` | 41 | `0xc2d00` | 10496 |  |
| 16 | `MTC30481850329` | `00` | `0x3ca0` | 51 | `0xcc300` | 13056 |  |
