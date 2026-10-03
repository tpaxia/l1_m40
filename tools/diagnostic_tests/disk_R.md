# Diagnostic Disk R

- Subsystem: reduced 3930 set
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/R.IMD`
- DML special/catalog loader: `UTILY884871127`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162508-diag-tests-R`
- Post-Enter monitor run: `runs-archive/20260716-164525-enter-menu-R`
- Post-Enter screen dump: [monitor_menu_R.txt](monitor_menu_R.txt)
- Generated MAP inventory: [monitor_map_R.txt](monitor_map_R.txt)

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
DIAGNOSTIC MONITOR  8.4 870331  K.ZIMMI
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_R.txt](monitor_map_R.txt). This is generated
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
| 6 | `HDFDU784870331` | `00` | `0x1b64` | 27 | `0x5d300` | 6912 |  |
| 7 | `UCG30483851212` | `00` | `0x1d2c` | 23 | `0x60300` | 5888 |  |
| 8 | `UCV30584870331` | `00` | `0x1e56` | 15 | `0x66100` | 3840 |  |
| 9 | `UCY80584880222` | `00` | `0x1f78` | 49 | `0x6b700` | 12544 | UCO.71 multiprocessor UC test; includes bus arbiter and master/slave coverage. |
| 10 | `UCM80584870331` | `00` | `0x22f0` | 13 | `0x7cb00` | 3328 |  |
| 11 | `MEM81384871127` | `00` | `0x26c6` | 45 | `0x87100` | 11520 |  |
| 12 | `PRGEN284880222` | `00` | `0x2a7e` | 35 | `0x8f900` | 8960 |  |
| 13 | `SCT30381850329` | `02` | `0x2d02` | 5 | `0xb1900` | 1280 |  |
| 14 | `STC40484870331` | `00` | `0x36ac` | 51 | `0xb9700` | 13056 |  |
| 15 | `SCTER781850329` | `00` | `0x3abc` | 15 | `0xc7700` | 3840 |  |
| 16 | `STC5E283861117` | `00` | `0x3d82` | 47 | `0xcd900` | 12032 |  |
| 17 | `STC5T384871127` | `00` | `0x40b2` | 21 | `0xda500` | 5376 |  |
| 18 | `CRTAN581841109` | `00` | `0x43da` | 43 | `0xe6900` | 11008 | Alphanumeric CRT controller test. |
| 19 | `KEYTE183851212` | `00` | `0x4810` | 1 | `0xea300` | 256 | Keyboard test; interrupt/vector, alpha/numeric/KANA/LED/buzzer paths. |
| 20 | `WSLIN384880222` | `00` | `0x4838` | 17 | `0xecb00` | 4352 |  |
