# Diagnostic Disk E

- Subsystem: HDU 18/14 MB
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/E.IMD`
- DML special/catalog loader: `UTILY884870331`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162456-diag-tests-E`
- Post-Enter monitor run: `runs-archive/20260716-164505-enter-menu-E`
- Post-Enter screen dump: [monitor_menu_E.txt](monitor_menu_E.txt)
- Generated MAP inventory: [monitor_map_E.txt](monitor_map_E.txt)

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
DIAGNOSTIC MONITOR  84  E14/18  K.03970
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_E.txt](monitor_map_E.txt). This is generated
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
| 3 | `TS501681841109` | `00` | `0x122c` | 5 | `0x3c700` | 1280 |  |
| 4 | `S24I5180840810` | `01` | `0x1202` | 49 | `0x49d00` | 12544 | 24-sector hard-disk media/seek/format/verify support test. |
| 5 | `DI501180840810` | `00` | `0x1798` | 47 | `0x53700` | 12032 |  |
| 6 | `ER50I380840810` | `00` | `0x1a98` | 43 | `0x5d300` | 11008 |  |
| 7 | `VC50I280840810` | `00` | `0x1d84` | 39 | `0x65b00` | 9984 |  |
| 8 | `50ITM181850329` | `00` | `0x20a8` | 15 | `0x71b00` | 3840 |  |
| 9 | `SASIT583851212` | `00` | `0x2374` | 27 | `0x78300` | 6912 |  |
| 10 | `C5006280840810` | `00` | `0x25a4` | 39 | `0x81b00` | 9984 |  |
| 11 | `5006F381841109` | `00` | `0x28b6` | 47 | `0x8c900` | 12032 |  |
| 12 | `ES356484870331` | `00` | `0x2cbe` | 21 | `0x9a100` | 5376 |  |
| 13 | `SAS24380840810` | `00` | `0x309c` | 3 | `0xa4f00` | 768 |  |
| 14 | `5006V181850329` | `00` | `0x337e` | 3 | `0xacd00` | 768 |  |
| 15 | `S24X6283851212` | `00` | `0x35d8` | 25 | `0xb8f00` | 6400 | 24-sector hard-disk media/seek/format/verify support test. |
