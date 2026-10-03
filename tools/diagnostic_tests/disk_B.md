# Diagnostic Disk B

- Subsystem: KDC video-keyboard / MUX
- Image: `reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD`
- DML special/catalog loader: `UTILY884870331`
- Catalog: offset `0x31500`, sectors `8`
- MAME boot run: `runs-archive/20260716-162444-diag-tests-B`
- Post-Enter monitor run: `runs-archive/20260716-164211-enter-code52-B`
- Post-Enter screen dump: [monitor_menu_B.txt](monitor_menu_B.txt)
- Generated MAP inventory: [monitor_map_B.txt](monitor_map_B.txt)

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
DIAGNOSTIC MONITOR  8.4 880222  K.04488
 1  LOAD (PGM CODE)
 2  MAP  (PGMS)
 3  HELP (MONITOR)
 4  GO
  HIT  1..4 + "ENTER":
```

## Generated MAP Inventory

See [monitor_map_B.txt](monitor_map_B.txt). This is generated
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
| 3 | `UCM80584870331` | `00` | `0x122c` | 5 | `0x3c700` | 1280 |  |
| 4 | `CACH8481850329` | `00` | `0x12c6` | 49 | `0x46100` | 12544 |  |
| 5 | `TCB80581850329` | `00` | `0x165c` | 39 | `0x4c700` | 9984 |  |
| 6 | `MEM81384871127` | `00` | `0x1842` | 27 | `0x51500` | 6912 |  |
| 7 | `MREDA383851212` | `00` | `0x197e` | 41 | `0x58500` | 10496 |  |
| 8 | `CAC60383851212` | `00` | `0x1c92` | 11 | `0x63500` | 2816 |  |
| 9 | `CAC12383851212` | `00` | `0x1f82` | 1 | `0x6c100` | 256 |  |
| 10 | `RAMVID80840810` | `00` | `0x2182` | 27 | `0x72900` | 6912 | Video RAM test for the GO252/KDC framebuffer. |
| 11 | `CRTAN581841109` | `00` | `0x2408` | 1 | `0x74b00` | 256 | Alphanumeric CRT controller test. |
| 12 | `CRTGR281841109` | `00` | `0x2410` | 9 | `0x75300` | 2304 | Black-and-white graphics CRT test. |
| 13 | `KEYTE183851212` | `00` | `0x2412` | 25 | `0x75500` | 6400 | Keyboard test; interrupt/vector, alpha/numeric/KANA/LED/buzzer paths. |
| 14 | `GRAPH381850329` | `00` | `0x2438` | 43 | `0x77b00` | 11008 | Video graphics colour / 7220-family graphics test. |
| 15 | `T3110381850329` | `00` | `0x2582` | 47 | `0x7f900` | 12032 |  |
| 16 | `TKEY0483851212` | `00` | `0x2896` | 21 | `0x8a900` | 5376 |  |
| 17 | `MULT1383860616` | `00` | `0x2b9a` | 15 | `0x94900` | 3840 |  |
| 18 | `MULT2283851212` | `00` | `0x2efe` | 13 | `0xa4900` | 3328 |  |
| 19 | `WSVID684880222` | `00` | `0x33f2` | 7 | `0xb4100` | 1792 |  |
| 20 | `WSKEY684880222` | `00` | `0x3790` | 41 | `0xbaf00` | 10496 |  |
| 21 | `WSPCR384871127` | `00` | `0x3ac6` | 29 | `0xc8100` | 7424 |  |
| 22 | `WSLIN384880222` | `00` | `0x3e9e` | 19 | `0xd2900` | 4864 |  |
| 23 | `PRMUX083860616` | `00` | `0x415c` | 21 | `0xd8300` | 5376 |  |
