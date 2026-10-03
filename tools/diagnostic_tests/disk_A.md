# Diagnostic Disk A

- Subsystem: central unit / RAM / UC
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/A.IMD`
- DML special/catalog loader: `UTILY884871127`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162444-diag-tests-A`
- Post-Enter monitor run: `runs-archive/20260716-164234-enter-code52-A`
- Post-Enter screen dump: [monitor_menu_A.txt](monitor_menu_A.txt)
- Generated MAP inventory: [monitor_map_A.txt](monitor_map_A.txt)

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

See [monitor_map_A.txt](monitor_map_A.txt). This is generated
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
| 2 | `LDHSE282850612` | `00` | `0x106c` | 1 | `0x39f00` | 256 |  |
| 3 | `LDHMU784871127` | `00` | `0x1294` | 5 | `0x42f00` | 1280 |  |
| 4 | `SYSINB84870331` | `00` | `0x14aa` | 49 | `0x4ad00` | 12544 |  |
| 5 | `HDSCT984870331` | `00` | `0x18ac` | 11 | `0x57f00` | 2816 |  |
| 6 | `HDMTU784870331` | `00` | `0x1b64` | 27 | `0x5d300` | 6912 |  |
| 7 | `HDFDU784870331` | `00` | `0x1d6c` | 23 | `0x64300` | 5888 |  |
| 8 | `UC300383851212` | `00` | `0x1f2c` | 27 | `0x66b00` | 6912 |  |
| 9 | `UCG30483851212` | `00` | `0x2052` | 19 | `0x6c500` | 4864 |  |
| 10 | `UCV30584870331` | `00` | `0x2156` | 49 | `0x6fd00` | 12544 |  |
| 11 | `UCY80584880222` | `00` | `0x2378` | 31 | `0x78700` | 7936 | UCO.71 multiprocessor UC test; includes bus arbiter and master/slave coverage. |
| 12 | `FJCAC183860616` | `00` | `0x25f0` | 47 | `0x86700` | 12032 |  |
| 13 | `WRCAC183860616` | `00` | `0x2a50` | 27 | `0x8cb00` | 6912 |  |
| 14 | `MEM81384871127` | `00` | `0x2c4a` | 3 | `0x92d00` | 768 |  |
| 15 | `CHY10184871127` | `00` | `0x2d7e` | 25 | `0x99500` | 6400 |  |
| 16 | `TCM80184871127` | `00` | `0x2fba` | 47 | `0xa3900` | 12032 |  |
| 17 | `PRGEN284880222` | `00` | `0x333e` | 25 | `0xa8d00` | 6400 |  |
| 18 | `PRT.UC80840810` | `02` | `0x3402` | 35 | `0xc8500` | 8960 |  |
| 19 | `PRTWIN80840810` | `00` | `0x3e26` | 29 | `0xcb100` | 7424 |  |
| 20 | `PRTELB80840810` | `00` | `0x3f2a` | 15 | `0xce900` | 3840 |  |
| 21 | `PINELB80840810` | `00` | `0x4032` | 5 | `0xd2500` | 1280 |  |
| 22 | `SOVRA781850329` | `00` | `0x412c` | 3 | `0xd5300` | 768 |  |
| 23 | `CESTE083861117` | `00` | `0x41cc` | 47 | `0xdf300` | 12032 |  |
