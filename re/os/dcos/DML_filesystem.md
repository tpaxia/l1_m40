# L1 DCOS 8.4 diagnostic disk — "DML" filesystem / test library (RE notes)

Working notes on the on-disk structure of the L1 diagnostic disks (disk A analysed;
DCOS 8.4). Coordinates are byte offsets into the *concatenated-sector
image* produced by `tools/imd.py extract` (track 0 = 26×128B, tracks 1+ = 26×256B).

## Volume layout (track 0)
Track 0 carries an IBM-diskette-style label set (128-byte records):
- `0x0200` `ERMAP` — (error map / bad-track record), rest blank.
- `0x0300` **`VOL1DML     LIBRARY ADDRESS ` `0f 17 08`** — the DML volume descriptor.
  The 3 bytes after "ADDRESS " decode cleanly as **track 0x0f, sector 0x17,
  length 0x08 sectors**. In the extracted image this is flat offset `0x31500`,
  and the 8-sector run is `0x31500..0x31cff`.
- `0x0340` `M   1   W` , `0x0380` `DDR1` — further label/data-set-header records.

So the medium is a **"DML" library**: a VOL1 descriptor + a directory of named
diagnostic files. The first 512 bytes of track 0 are the common `SYS0` bootloader
(see `../disk/boot.s`); the label set follows it.

## Test-file directory
The DML library/catalog lives at the VOL1 library pointer above:
`0x31500..0x31cff`. `0x31500` starts with a special 16-byte `UTILY884871127`
catalog/header entry. Normal catalogue records start at **`0x31510`** and are
20 bytes each:

```
offset  size  field
0       1     ext   -- high address extension byte (usually 0x00; PRT.UC has 0x02)
1       2     loc   -- DML block address, LITTLE-endian ( (b2<<8)|b1 )
3       1     len   -- length (DML units; NOT a simple block count, see below)
4       1     0x00
5       1     index -- sequential file number (0x00..)
6       14    name  -- mnemonic + catalogue number, space/NUL padded
```

`loc` rises monotonically with `index`. `index 0` = terminator (`ZZ...`, loc 0);
`index 1` = the special `UTILY...` entry/header at `0x31500`.

The Functional Checks manual's catalogue display names these fields as `TR/ST`
(`Starting Track and Sector`, four characters) and `LENGTH` (`Program length in
sectors of 256 bytes`). That makes the catalogue `loc` a displayed logical
track/sector value plus sector length, not a raw byte offset.

Important distinction: the diagnostic monitor's `LOAD` command asks for a
three-character program `CODE`. The extracted DML record `index` is not yet
proven to be that displayed `CODE`. For disk B, `KEYTE183851212` is record/index
`13`, but scripted attempts to load `013` and `13` both currently end with the
loader/library message `ac_mmulogfi: 02`. The FDU trace shows those attempts do
read the DML catalog sector `(C=0F H=00 R=17 N=01)` successfully before failing
inside the disk-resident FDU/library path. Until MAP works or the UTILY display
routine is fully decoded, treat `index` as catalog order, not as confirmed
monitor `CODE`.

### Disk-A directory (decoded)
| idx | loc | len | name | test |
|-----|------|-----|------|------|
| 2 | 0x106c | 01 | LDHSE… | loader HD→SE |
| 3 | 0x1294 | 05 | LDHMU… | loader HD→MU |
| 4 | 0x14aa | 31 | SYSINB… | system init |
| 5 | 0x18ac | 0b | HDSCT… | HD ↔ SCT |
| 6 | 0x1b64 | 1b | HDMTU… | HD ↔ MTU |
| 7 | 0x1d6c | 17 | HDFDU… | HD ↔ FDU |
| 8 | 0x1f2c | 1b | UC30038… | central-unit test |
| 9 | 0x2052 | 13 | UCG3048… | UC + GIPO |
| 10 | 0x2156 | 31 | UCV3058… | UC + video/V24 |
| 11 | 0x2378 | 1f | UCY8058… | UC … |
| 12 | 0x25f0 | 2f | FJCAC18… | **Fujitsu S3000SV cache test** (`0xFFD0-DB`) |
| 13 | 0x2a50 | 1b | WRCAC18… | cache test (other UP) |
| 14 | 0x2c4a | 03 | MEM8138… | RAM / memory test |
| 15 | 0x2d7e | 19 | CHY1018… | (?) |
| 16 | 0x2fba | 2f | TCM8018… | **S8000 TCM** |
| 17 | 0x333e | 19 | PRGEN28… | program generator |
| 18 | 0x3402 | 23 | PRT.UC8… | printer on UC |
| 19 | 0x3e26 | 1d | PRTWIN8… | printer TWIN |
| 20 | 0x3f2a | 0f | PRTELB8… | printer ELB |
| 21 | 0x4032 | 05 | PINELB8… | PIN-pad / badge (ELB) |
| 22 | 0x412c | 03 | SOVRA78… | sovrapposizione (video overlay) |
| 23 | 0x41cc | 2f | CESTE08… | (?) |

The disk-A "BUS ARBITER / RESET / S8000 TCM / BURST / MASTER-SLAVE / ADAPTER" tests
are sub-tests inside the `UC*` and/or `TCM` files.

## UTILY catalogue/load trace
Focused disassembly of UTILY gives a stronger model for the catalogue fields. Raw
image offsets below are from `/tmp/diskA.bin`; `<<33>>` long addresses are runtime
addresses and are not always a direct linear image offset.

The floppy-DML path at image `0x33f04..0x33f3e` reads the already-loaded VOL1
buffer at runtime `<<33>>0x6714`:

```
33f06  rr8 = <<33>>0x6714
33f0c  compare word [rr8+4] with "DM"        ; observed, but no visible reject
33f14  rl2 = [rr8+0x1e]                      ; library/catalog sector count
33f18  reject if count == 0 or count >= 0x11
33f32  r6 = word [rr8+0x1c]                  ; library/catalog TR/ST
33f36  rl0 = 2
33f38  rl2 = [rr8+0x1e]
33f3c  call catalogue read wrapper
33f3e  jump to the catalogue display path
```

For disk A, VOL1 bytes `+0x1c..+0x1e` are exactly `0f 17 08`, so UTILY itself
confirms that this is the read tuple `(TR/ST=0x0f17, count=0x08)`.

The FDU->HDU append utility at image `0x3395e..0x33a40` does the same thing after
copying source/destination labels into local work areas:

```
33a0e  rr8 = saved source VOL1
33a12  r0  = word [rr8+0x1c]     ; source library TR/ST
33a16  rl2 = byte [rr8+0x1e]     ; source library length, capped at 9 here
33a26  r6  = saved source unit/label descriptor
33a2a  call read wrapper
33a32  copy 0x0480 bytes from the read buffer into a working catalogue area
```

This path is useful corroboration because it obtains the same values from VOL1,
not from our manual offset arithmetic.

The HDU path is different: around `0x33e7a..0x33efe` it reads a volume/SSID area,
checks `VOL1`, checks `SSID` at `+0x100`, scans fourteen 0x20-byte SSID entries
for an entry beginning with `T`, uses a long pointer at entry `+7` minus one, and
then reads the HDU library. Its later loop (`0x33f44..0x33f82`) normalizes packed
decimal-looking catalogue words. That is not the floppy DML directory format.

## `loc` / `TR/ST` → physical image mapping
The catalogue records store a DML/monitor logical sector address, not a byte
offset and not normalized physical CHS.

For disk A's 2-sided 26-sector layout, decode a normal record as:

```
ext = record[0]
loc = little_endian(record[1:3])
logical_sector = ext * 256 + (loc >> 8) * 52 + (loc & 0xff)
flat_image_sector = logical_sector - 13
flat_image_offset = flat_image_sector * 256
byte_length = record[3] * 256
```

The `-13` is only for our `tools/imd.py extract` image: track 0 side 0 is
26 x 128-byte sectors, so it occupies 13 256-byte units in the flat file while
the monitor's sector arithmetic counts the disk geometry as 26 sectors.

The device dispatcher around image `0x35250` confirms the lower-level model. For
removable media types (`0x60`, `0x61`, `0x65`, `0x66`) it calls the conversion
routine at `0x3531e`, which divides a logical sector number by
`sectors_per_track * heads` and then by `sectors_per_track` to produce C/H/S.

The VOL1 `LIBRARY ADDRESS 0f 17 08` is a different encoding: it is physical-ish
track/sector/count. `0x0f,0x17` means cylinder/track 15, sector 23, count 8.
Using one-based sector numbering gives logical sector `15*52 + (23-1) = 802`;
the extracted flat sector is `802 - 13 = 789`, i.e. byte offset `0x31500`.

The formula above is corroborated by title blocks appearing at the end of many
file spans:

| name | ext | loc | len | decoded flat span | title/name evidence |
|------|-----|-----|-----|-------------------|---------------------|
| LDHSE | 0x00 | 0x106c | 1 | sectors 927..927 | `LDHSE` at sector 927 |
| LDHMU | 0x00 | 0x1294 | 5 | sectors 1071..1075 | `LDHMU` at sector 1075 |
| SYSINB | 0x00 | 0x14aa | 49 | sectors 1197..1245 | `SYSINB` at sector 1245 |
| HDSCT | 0x00 | 0x18ac | 11 | sectors 1407..1417 | `HDSCT` at sector 1417 |
| HDMTU | 0x00 | 0x1b64 | 27 | sectors 1491..1517 | `HDMTU` at sector 1517 |
| UCV305 | 0x00 | 0x2156 | 49 | sectors 1789..1837 | `UCV305` at sector 1837 |
| MEM813 | 0x00 | 0x2c4a | 3 | sectors 2349..2351 | `MEM813` at sector 2351 |
| PRT.UC | 0x02 | 0x3402 | 35 | sectors 3205..3239 | `PRT.UC` at sector 3239 |
| PRTWIN | 0x00 | 0x3e26 | 29 | sectors 3249..3277 | `PRTWIN` at sector 3277 |
| PRTELB | 0x00 | 0x3f2a | 15 | sectors 3305..3319 | `PRTELB` at sector 3319 |
| SOVRA7 | 0x00 | 0x412c | 3 | sectors 3411..3413 | `SOVRA7` at sector 3413 |

The previous apparent `PRT.UC`/`PRGEN2` overlap was caused by treating byte 0 as
a flag and ignoring it in the address calculation. Interpreting it as an
extension byte adds `0x02 * 256` sectors, placing `PRT.UC` at `0xc8500..0xca7ff`
with its title block at the end, matching the surrounding file layout.

Older physical string-search anchors are still useful as sanity checks, but they
are not always file starts. For many overlays the catalogue mnemonic is in a title
block near the end of the decoded span, while other overlays contain only generic
test text or shared code strings.

| idx | loc | len | name | physical header evidence |
|-----|------|-----|------|--------------------------|
| 1 | special | -- | UTILY884871127 | `0x33300` (C16/H0/S1), name at `+0x0c` |
| 2 | 0x106c | 01 | LDHSE... | `0x39f00` (C18/H0/S5), name at `+0x0c` |
| 3 | 0x1294 | 05 | LDHMU... | `0x43300` (C20/H1/S23), name at `+0x0c` |
| 4 | 0x14aa | 31 | SYSINB... | `0x4dd00` (C24/H0/S11), name at `+0x0c` |
| 5 | 0x18ac | 0b | HDSCT... | `0x58900` (C27/H1/S1), name at `+0x0c` |
| 6 | 0x1b64 | 1b | HDMTU... | `0x5ed00` (C29/H0/S23), name at `+0x0c` |
| 8 | 0x1f2c | 1b | UC30038... | `0x6a400` (C32/H1/S24), name nearby |
| 9 | 0x2052 | 13 | UCG3048... | `0x6fa00` (C34/H1/S6), name nearby |
| 10 | 0x2156 | 31 | UCV3058... | `0x72d00` (C35/H1/S5), name at `+0x0c` |
| 11 | 0x2378 | 1f | UCY8058... | `0x7bd00` (C38/H0/S19), name nearby |
| 12 | 0x25f0 | 2f | FJCAC18... | `0x89f00` (C42/H1/S11), name nearby |
| 13 | 0x2a50 | 1b | WRCAC18... | `0x8ef00` (C44/H0/S13), name nearby |
| 14 | 0x2c4a | 03 | MEM8138... | `0x92f00` (C45/H0/S25), name at `+0x0c` |
| 16 | 0x2fba | 2f | TCM8018... | `0xa9500` (C52/H0/S19), name nearby |

## Practical extraction
Use `tools/dml_catalog.py` on the flat image produced by `tools/imd.py extract`:

```
python3 tools/imd.py "<path>/A.IMD" extract /tmp/diskA.bin
tools/dml_catalog.py list /tmp/diskA.bin
tools/dml_catalog.py extract /tmp/diskA.bin LDHMU /tmp/LDHMU.bin
```

Then disassemble extracted spans or full-image offsets with
`tools/z8kdisrom <image> <start> <end>`. Overlays run at segment **33** (`<<33>>`).

## Disk-tool feasibility

We have enough information to build a useful disk tool for **M30/M40 DCOS 8.4
diagnostic DML IMD files**. The tool should be scoped honestly as a diagnostic
library browser/extractor, not as a general M30/M40 filesystem implementation.

The supported path is:

```text
IMD image
  -> parse ImageDisk tracks/sectors
  -> preserve logical sector ordering
  -> expose the mixed media layout:
       track 0: 26 sectors x 128 bytes
       tracks 1+: 26 sectors x 256 bytes
  -> read VOL1 at flat offset 0x300
  -> read VOL1 library pointer at +0x1c..+0x1e
  -> parse the DML catalogue
  -> list and extract named catalogue entries
```

The current prototype pieces already exist:

```text
tools/imd.py          parses IMD and creates the flat concatenated-sector image
tools/dml_catalog.py  lists and extracts DML catalogue entries from that flat image
```

A cleaner tool can combine those into one command so an intermediate flat image
is optional:

```text
m40disk tracks <disk.imd>
m40disk info <disk.imd>
m40disk list <disk.imd>
m40disk extract <disk.imd> <name-or-code> <out.bin>
m40disk extract-all <disk.imd> <out-dir>
```

For the diagnostic DML disks, the catalogue model is solid enough:

```text
VOL1 location:      flat offset 0x300
catalog pointer:   VOL1 + 0x1c..0x1e = track, sector, sector-count
normal record size 20 bytes

record +0x00  ext
record +0x01  loc low byte
record +0x02  loc high byte
record +0x03  length in 256-byte sectors
record +0x04  zero / reserved
record +0x05  catalogue index
record +0x06  14-byte ASCII name
```

Normal file span decoding for the known two-sided 26-sector diagnostic floppies:

```text
loc = little_endian(record[1:3])
logical_sector = ext * 256 + (loc >> 8) * 52 + (loc & 0xff)
flat_sector    = logical_sector - 13
flat_offset    = flat_sector * 256
byte_length    = len * 256
```

The `-13` is not an on-disk DML field. It is only the correction needed for our
flat extracted view because track 0 side 0 physically occupies `26 * 128` bytes,
which is thirteen 256-byte logical sectors, while the monitor's DML arithmetic
counts the geometry in 256-byte logical sectors.

This has been cross-checked across the DCOS 8.4 diagnostic disks A, B, C, D, E,
F, G, H, and R. The generated inventories in `tools/diagnostic_tests/` are based
on the same decoder and match the monitor MAP/catalogue contents well enough for
test selection and extraction work.

### What such a tool can claim

- List the VOL1 label and DML library pointer.
- List the diagnostic catalogue entries with index, name, extension, loc, length,
  decoded logical sector, flat offset, and byte count.
- Extract a named diagnostic/support span as raw bytes.
- Extract all catalogue entries from a diagnostic disk.
- Show the IMD track table and sector sizes.
- Detect and report unexpected geometry instead of silently applying the DCOS
  8.4 formula.

### What it should not claim yet

- It is not a general M30/M40 OS filesystem tool.
- It is not an HDU DML-library decoder; the UTILY HDU path uses a different
  VOL1/SSID/catalogue flow.
- It does not reconstruct free-space allocation, deleted entries, or a writable
  filesystem.
- It does not resolve runtime overlay semantics. A catalogue entry is a stored
  byte span; a diagnostic may still load shared support code or secondary
  overlays after entry.
- It should not assume the catalogue index is always the monitor LOAD code unless
  corroborated by the MAP display for that disk. In practice the diagnostic
  disks observed so far use the same three-digit ordering convention for running
  tests, but the catalogue field itself is still best described as the DML entry
  index.

### Recommended implementation shape

Keep the low-level IMD parser sector-addressed instead of flattening too early.
The flattened image is convenient for current scripts, but a real tool should
retain `(cylinder, head, sector, sector-size, sector-type)` metadata so it can:

- explain the mixed 128/256-byte layout,
- verify the expected geometry before applying DML arithmetic,
- extract directly from IMD without a temporary flat file,
- emit both DML logical-sector addresses and physical CHS spans for debugging.

The existing `tools/imd.py` and `tools/dml_catalog.py` are therefore enough as a
working reference, but the production tool should merge them and make the format
assumptions explicit in its output.
The disassembler is linear, so segmented long-address display is approximate, but
I/O ports and local control flow are still useful.
