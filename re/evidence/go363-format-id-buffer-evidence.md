# GO363 format ID buffer and Verify ID after Format (2026-09-26, provisional)

## Symptom

With the uPD7261 read-timing fix (`re/evidence/upd7261-read-data-timing-evidence.md`),
`1003.HDC5F5` passes the ETF read and prints `FORMAT PHASE ...`. It then
fails with `ERR.0001 *PGM HDC5F5 *TST 01 / HARDWARE FAILURE`,
`FROM CYL: 919 TO CYL: 901`. The failing command is uPD7261 VERIFY ID
(`0x80`), issued immediately after FORMAT (`0x70`) at cylinder 919, head 0.
It ends with status `0x22` (CEL + NCI), EST `00`, SCNT `0x20`, after one
4-byte ID.

## Primary documentation

NEC, *uPD7261A/B Hard-Disk Controllers*, `reference/datasheets/NEC_uPD7261B_datasheet.pdf`,
printed page 6-22 (PDF page 20):

- **Format:** for soft-sector drives, format-writing begins at the sector
  after the index pulse. For each sector, the HDC takes four bytes (LCNH,
  LCNL, LHN, LSN) by DMA from local memory and writes them into the ID
  field. SCNT counts down per sector.
- **Verify ID:** the ID bytes of the sectors are read from the disk and
  compared with data taken from local memory by DMA, starting at the first
  physical sector of the track (PHN given). Comparison continues until SCNT
  reaches zero or a mismatch/CRC error occurs.
- Page 6-16, status bit NCI: set when data from the disk does not coincide
  with the data from the system during Verify ID.

Consequence: on hardware, Verify ID compares the host's ID list against the
IDs that Format just wrote. When the same list is supplied to both, it
passes whatever the four bytes contain.

The Olivetti *L1 Functional Checks Manual* (January 1987), sections
17.1.1–17.1.2, describes HDC5F5 formatting the whole disk after reading
Standard 24 and the ETF. Section 17.6 describes HDC5X3 ERMAP option 1
formatting and certifying the ERMAP track.

## GO363 protocol recovered from DCOS

Original image:
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`.

### Path 1 — HDC5F5 (`1003`), shared runtime loaded at `0x218000`

Loaded address → flat Disk G offset: `flat = loaded − 0x1d3200`. Verified
byte-identical against the runtime dump
`runs-archive/formatter-wren2-20260926/hdc5f5-runtime-218000.bin`.

| Loaded | Flat | Role |
|---|---|---|
| `0x21ac66` | `0x47a66` | Converts the logical ID-table pointer (`call <<4>>0x457e`) and calls `0x21956c` with `r6=1` |
| `0x218932` | `0x45732` | Board command `0x0e00`: `r6<<1`, then `0x21923a`; board data `0xNNab`, `0x0099`, `0x000d` |
| `0x21923a` | `0x4603a` | System DMA: counter 2 (`0x57=0xb0`, `0x56`) = `r6·16−1`, address `0x42/0x44` = physical/2 |
| `0x218baa` | `0x459aa` | FORMAT (`0x1400`): `r6 = SCNT·4`, `0x21922a` sets local counter 1 (`0x57=0x70`, `0x47`) = `r6−1`; board data `0x002b`; NEC params PHN, SCNT, DPAT, GPL1, GPL3 |
| `0x218d08` | `0x45b08` | VERIFY ID (`0x1900`): same `r6 = SCNT·4`, `0x21922a`, board data `0x002b`; NEC params PHN, SCNT |

The counter-2 unit is 16 bytes. The same helper programs `0x000f` for a
256-byte READ DATA (`0x21923a` with `r6=1`), so `0x001f` means 512 bytes.

Captured run (`runs-archive/hdc5f5-timeout-20260926/breakpoints.log`, device log
`error.log`): `0x0e00` system DMA from physical `0x0773fa`, 512 bytes; board
data `0x5fab`, `0x0099`, `0x000d`. The buffer, identical at `0x0e00`, FORMAT
and VERIFY ID issue, is:

```text
+000: F397 0000 F397 0001 F397 0002 … F397 001F   (32 IDs, 128 bytes)
+128 … +511: FFFF
```

The IDs are LCNH `0xF3`, LCNL `0x97` (cylinder 919 = `0x397`), LHN 0, and
LSN 0–31 ascending. FORMAT/VERIFY ID local counter `0x007f` (128 bytes =
32 × 4). The emulator's VERIFY ID compares the first ID `F3 97 00 00`
against its synthesized `03 97 00 00` and sets NCI.

### Path 2 (independent) — HDC5X3 (`007`) ERMAP option 1

This is a separate program with its own copy of the shared runtime, loaded
at `0x214xxx`/`0x215xxx`. Device log:
`runs-archive/readtiming-regression-20260926/opt1log/error.log`, lines ~620–750.
It issues the same sequence:

- `0x57=0xb0`, `0x56=0x001f` (512 bytes), `0x42/43=0x0779`,
  `0x44/45=0x0003` (physical `0x060ef2`); board data `0x0eab`, `0x0099`,
  `0x000d`; board command `0x0e00` (`0x215388`).
- `0x57=0x70`, `0x47=0x007f`; board data `0x002b` (`0x214cea`); NEC
  params `00 20 00 10 0f`; FORMAT `0x70` (`0x215384`); board `0x1400`.
- board data `0x002b` (`0x214e52`); VERIFY ID `0x80`; 32 four-byte DMAs
  from `0x060ef2` onward, all matching. This implies ERMAP's list is the
  plain `03 9C 00 nn`, the same as the model's synthetic IDs, which is why
  ERMAP option 1 already passes.

### Inferred GO363 behavior (provisional)

1. Board command `0x0e00` copies a block (counter-2 units × 16 bytes) from
   system memory at the programmed system DMA address into a board buffer.
2. With board data `0x002b` selected, the uPD7261's DMA for FORMAT and
   VERIFY ID transfers ID bytes from/to that board buffer (4 × SCNT bytes,
   local counter 1), not from system memory.

Two independent DCOS programs use exactly this sequence for FORMAT +
VERIFY ID. The GO363 board description does not document it. Both points
remain provisional until corroborated by another path (e.g. S24W25's track-0
format or HDC505).

## Model change (external MAME, GO363 only; uPD7261 untouched)

The CHD cannot hold per-sector ID fields, and the uPD7261 model synthesizes
IDs as (PCN high, PCN low, head, sector). To keep VERIFY ID meaningful
without changing the controller:

- `0x0e00` loads the board ID buffer from system memory as in (1).
- GO363 tracks the uPD7261 parameters it forwards: Specify ETN/ESN, Seek
  PCN, Recalibrate (PCN 0), and the PHN/SCNT of FORMAT and VERIFY ID.
- On FORMAT, GO363 remembers the ID list for that unit/cylinder/head
  (4 × SCNT bytes from the board buffer). Only the last formatted track is
  kept, because HDC5F5 and ERMAP verify immediately after formatting.
- On VERIFY ID with board data `0x002b`, IDs are fed from the board buffer.
  If the verified track is the last formatted track, each ID is compared
  with the remembered list. On a match, GO363 feeds the uPD7261 the
  synthetic ID it expects, so it passes. On a mismatch, it feeds a value that
  differs from it, so NCI is reported as on hardware. Otherwise the ID bytes
  are passed through unchanged (existing behavior).

This preserves the datasheet semantics "Verify ID succeeds iff the supplied
IDs equal the IDs written by Format". It keeps the translation in the board
model, where the ID DMA path lives.

Limits: after another track is formatted, a Read ID of an earlier track
still returns synthetic IDs (`03 97 …`, not `F3 97 …`). Formatting does not
fill data fields with DPAT. Neither is changed here.

## Checks

1. HDC5F5 on a disposable synthetic-ETF CHD must pass the first VERIFY ID
   at cylinder 919 and continue formatting.
2. ERMAP option 1 must still complete, and its CHD must stay byte-identical
   to `wren2-service-finalcheck.chd`.
3. Standard 24 must still reproduce its preserved CHD.

## Result of the ID-buffer change (2026-09-26)

HDC5F5 on a disposable synthetic-ETF CHD: the first VERIFY ID at cylinder
919 passes. FORMAT and VERIFY IDENTIFIER then complete for all tracks
(8,279 FORMAT commands, each followed by its VERIFY ID). The remembered
first IDs vary with cylinder: `F3 97 00 00` at 919, `11 D4 03 00` at 468,
`10 00 08 00` at 0. So the high nibble of LCNH is not a constant, and
remembering the actual list (rather than a fixed rule) is required. ERMAP
option 1 and Standard 24 still reproduce their preserved CHDs byte for byte.

The next phase, WRITE & VERIFY DATA FIELD, then exposed two further model
gaps (below and in `re/evidence/upd7261-read-data-timing-evidence.md`).

# GO363 extended head select (register 0x41), provisional

## Evidence

- NEC datasheet, printed page 6-4 (PDF page 2), "Pin Identification —
  ST506-Type Interface": pins 24–26 are HS2–HS0, head select outputs 2–0.
  The uPD7261 can therefore address only heads 0–7 itself.
- The WREN2 has 9 heads. The DCOS `UNITDESCWREN2` descriptor (Disk G flat
  `0xb5f30`) gives last head `0x0008`, and HDC5F5 writes heads 0–8.
- HDC5F5 WRITE DATA for cylinder 907 (`0x38b`), head 8 sends parameters
  PHN `00`, LCNH `13`, LCNL `8b`, LHN `08`, LSN `00`, SCNT `20`. PHN is the
  head modulo 8, so the ninth head must be selected outside the chip.
- Before every NEC command, the shared runtime routine at loaded `0x2191dc`
  (Disk G flat `0x45fdc`, bytes `a0b8 b284 8510 ca40 3f20`, verified) ORs
  the head number into `r0` and writes it to GO363 `0x40`/`0x41`. In the
  HDC5F5 run, register `0x41` takes only the values `0x00`–`0x08`, with an
  equal count for each head 1–8. HDC5X3 uses the same routine in its own
  runtime copy (loaded `0x2152fc`).

## Model change

GO363 forwards `0x41 & 0x0f` to the existing uPD7261 `head_w()` input (the
"extended head" MAME already uses for MG-1). Without it the uPD7261 model
reported EST `0x04` (ND) for every head-8 transfer, and HDC5F5 stopped on
the first head-8 WRITE DATA.

The register's other bits (`0x40` high byte `0x07`) are not interpreted.
This is provisional: two programs share one routine, not two independent
paths.

## Final result

With the read/write/verify data-field timing and both GO363 changes, HDC5F5
on `runs-archive/hdc5f5-timeout-20260926/wren2.chd` (a copy of
`wren2-synthetic-etf.chd`) reports **`DISK CORRECTLY FORMATTED`**, with
0 errors. It passed Standard 24 read, ETF read, Format, Verify identifier,
Write & verify data field (13,789 WRITE DATA + 13,789 VERIFY DATA), and
certify/format/write of the diagnostic areas. The formatted image is saved
as `runs-archive/hdc5f5-timeout-20260926/wren2-formatted-hdc5f5.chd` (393,216
bytes, SHA-256
`7789c8aa8dce4a8498a94b79170be461c2e680b9916930539742e405dd0e2858`), and
the summary screen as `hdc5f5-formatted-summary.png`. Regressions: ERMAP
option 1 and Standard 24 CHDs are byte-identical to their preserved
results.
