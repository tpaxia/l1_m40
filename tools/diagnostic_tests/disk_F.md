# Diagnostic Disk F

- Subsystem: HDU 60/120 MB Fujitsu SMD
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/F.IMD`
- DML special/catalog loader: `UTILY884870331`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162456-diag-tests-F`
- Post-Enter monitor run: `runs-archive/20260716-164525-enter-menu-F`
- Post-Enter screen dump: [monitor_menu_F.txt](monitor_menu_F.txt)
- Generated MAP inventory: [monitor_map_F.txt](monitor_map_F.txt)

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

See [monitor_map_F.txt](monitor_map_F.txt). This is generated
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
| 3 | `SM23F682850612` | `00` | `0x122c` | 5 | `0x3c700` | 1280 |  |
| 4 | `ST24S580840810` | `00` | `0x12dc` | 49 | `0x47700` | 12544 |  |
| 5 | `2312E881850329` | `00` | `0x176c` | 9 | `0x50b00` | 2304 |  |
| 6 | `SM061184870331` | `00` | `0x19c2` | 13 | `0x5c900` | 3328 |  |
| 7 | `SM060983851212` | `00` | `0x1cfa` | 51 | `0x69d00` | 13056 |  |
| 8 | `F60TM382850612` | `00` | `0x21f8` | 41 | `0x79f00` | 10496 |  |
| 9 | `SM12V483851212` | `00` | `0x2686` | 29 | `0x83100` | 7424 |  |
| 10 | `2322F582850612` | `00` | `0x29f6` | 7 | `0x93d00` | 1792 |  |
| 11 | `120ST183851212` | `00` | `0x2de0` | 45 | `0x9f700` | 11520 |  |
| 12 | `2322E381850329` | `00` | `0x3268` | 9 | `0xa8300` | 2304 |  |
| 13 | `SM121184870331` | `00` | `0x34c2` | 9 | `0xb4500` | 2304 |  |
| 14 | `SM120983851212` | `00` | `0x37fa` | 47 | `0xc1900` | 12032 |  |
| 15 | `F12TM382850612` | `00` | `0x3cf8` | 37 | `0xd1b00` | 9472 |  |
| 16 | `SM22V283851212` | `00` | `0x4186` | 25 | `0xdad00` | 6400 |  |
