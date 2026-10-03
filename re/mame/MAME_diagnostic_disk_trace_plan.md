# MAME-driven diagnostic disk trace plan

This is a plan for using a bootable MAME model as a repeatable experiment
harness to pin down two things definitively:

1. The physical and logical disk format used by the DCOS 8.4 diagnostic disks.
2. The DML Monitor's test-load and overlay model.

No diagnostic code should be patched for this phase. The strategy is to drive the
machine exactly as an operator would, but through scripted input and debugger
logpoints so every run is reproducible.

Current concrete scripts, environment variables, driver assumptions, and known
limitations are documented in `re/mame/MAME_diagnostic_trace_harness.md`.

## Questions to answer

### Disk format

Definitive answers needed:

- Which tracks use 128-byte sectors and which use 256-byte sectors?
- Do all tracks use 26 sectors?
- Are sectors numbered 1..26 on every track?
- Is track 0 single-density/FM and later tracks double-density/MFM?
- Does any disk or track use mixed sector sizes?
- What exact CHRN values does the ROM use for the first-stage boot read?
- What exact CHRN values does the Monitor use after `SYS0` takes over?
- How does the DML logical sector number map to physical C/H/R/N?

Current working model:

```text
track 0:   26 x 128-byte sectors
tracks 1+: 26 x 256-byte sectors
DML logical sector size: 256 bytes
track-0 compensation in flat extracted images: 13 logical 256-byte sectors
```

The MAME trace should either confirm this completely or expose exceptions.

### Overlay model

Definitive answers needed:

- Is a catalogue entry a contiguous file, an overlay descriptor, or a first
  segment of a larger load plan?
- Where does the Monitor load each test?
- Does it relocate or patch pointers after loading?
- Which code/data remains resident between tests?
- Which ranges are shared by multiple tests?
- Why do some `KEYTE1` strings and routines appear in the flat region listed as
  `GRAPH3` by the catalogue?
- What is the entry PC for each selected test?
- Does a selected test perform secondary overlay reads after entering?

## High-level method

Use three independent observations for every load:

1. **FDC trace**: every physical disk command and result.
2. **Monitor trace**: the logical read request and catalogue entry being loaded.
3. **Memory trace**: bytes changed in RAM before/after the load.

The output should be a run transcript that can be aligned back to the IMD image
and to `tools/dml_catalog.py` output.

## Run structure

Use one test per emulator run.

Recommended flow:

```text
reset MAME
boot selected diagnostic disk
wait until Monitor menu is ready
select one test
stop at test entry
dump memory and logs
reset and repeat for the next test
```

Avoid long interactive sessions. Short deterministic runs make memory diffs and
disk-read attribution much cleaner.

## Scripted operator

The operator should be automated with MAME facilities rather than manual typing.
Useful approaches, in order of preference:

1. MAME debugger script or Lua input script that waits for stable conditions and
   injects key events.
2. Autoboot command/input if sufficient for the current driver.
3. Keyboard FIFO injection at the GO252/KDC level once the keyboard path is
   modelled well enough.

The script should not rely only on wall-clock delays. It should synchronize on
stable machine state, such as:

- PC reaches a known Monitor input loop.
- Monitor reads from the keyboard FIFO.
- A known screen/menu string appears in video RAM.
- A known idle loop is reached after boot.

## Trace points

### ROM boot read

Trace from reset through the first-stage `SYS0` jump.

Record:

```text
ROM PC/caller
FDC command bytes
C/H/R/N/EOT/GPL/DTL
DMA destination
DMA byte count
FDC result bytes
first-stage entry address
```

Expected result:

```text
track 0, head 0, sectors 1..26, N=0, 128-byte sectors, 0x0d00 bytes
destination segment 60
SYS0 header present at destination
```

### First-stage and Monitor load

After `SYS0` starts, log every disk read until the Monitor is idle.

Record:

```text
caller PC
logical sector/block requested by loader, if visible
computed C/H/R/N
sector count or byte count
DMA/copy destination
completion status
```

Expected outcome:

- Confirm the first-stage loader switches to 256-byte sectors for later tracks.
- Identify the Monitor load range.
- Identify resident Monitor code/data ranges before any test is selected.

### Catalogue lookup

When a test is selected, break around the DML catalogue lookup/load path.

Record:

```text
selected menu/test number
catalogue record offset
catalogue name
ext byte
loc word
len byte
computed logical sector
computed physical C/H/R/N
requested byte count
```

Cross-check against:

```text
re/os/dcos/DML_filesystem.md
tools/dml_catalog.py list <flat image>
```

### Disk read command issue

For every FDC command during test load, record:

```text
caller PC
FDC command bytes
FDC command phase direction
C/H/R/N/EOT/GPL/DTL
DMA address/count
actual bytes transferred
FDC result bytes
```

This is the authoritative record for physical disk format.

### Memory writes and overlays

Dump memory at these points:

```text
after ROM SYS0 load, before SYS0 jump
after Monitor load, before Monitor menu
before selected test load
after selected test load, before test entry
after test entry, before any secondary overlay if possible
after every later disk read performed by the test
```

For each dump pair, compute:

```text
changed address ranges
source disk byte ranges matching changed ranges
zeroed ranges
small patched ranges that do not directly match disk bytes
entry point after load
```

The changed ranges are the most direct way to distinguish:

- resident Monitor code,
- test overlay code,
- test data/string tables,
- scratch/BSS,
- relocated pointers,
- reused shared regions.

## Minimum useful breakpoint/logpoint set

Start with broad chokepoints and refine only if needed.

### Device-level logpoints

Instrument or log:

```text
uPD765 command byte writes
uPD765 result byte reads
DMA address/count programming
DMA terminal count
FDC interrupt/status changes
```

This can be done in MAME device logging or debugger watchpoints.

### ROM-level breakpoints

Break/log:

```text
ROM FDU boot handler entry
ROM FDC command submit
ROM FDC result/status read
ROM recovery/error display routine 0x0d10
ROM first-stage jump through the SYS0 header
```

For `0x0d10`, log:

```text
r7
<<1>>0x0302 boot slot
<<1>>0x0303 unit
<<1>>0x0308 displayed/recovery word
```

This explains blinking codes such as `4 2 1` and `4 2 3`.

### Monitor-level breakpoints

Once identified, break/log:

```text
Monitor keyboard input loop
catalogue search routine
logical-sector-to-CHS routine
bulk disk read routine
test overlay copy/relocation routine
test entry jump/call
```

Current static notes in `re/os/dcos/DML_filesystem.md` identify promising DML catalogue
code around flat image `0x33f04..0x33f3e`, but the live runtime addresses must be
confirmed from memory after Monitor load.

## Run matrix

Start with a small, high-signal matrix.

### Disk A

Use central-unit tests because their DML entries and disassemblies are already
partly understood:

```text
UCY805 / BUS ARBITER TEST
MEM813
UCV305
```

Questions:

- Are all loaded from one catalogue span?
- Do they share resident support code?
- Do any perform secondary reads after entry?

### Disk B

Use GO252/KDC tests because they already show suspected overlap:

```text
RAMVID
CRTAN5
CRTGR2
KEYTE1
GRAPH3
TKEY04
WSKEY6
```

Questions:

- Why does `KEYTE1` code/string material appear in the flat region named
  `GRAPH3`?
- Which regions are loaded for a standard GO252 keyboard test?
- Does the Monitor load a common KDC support overlay before individual tests?

### Disk D

Use FDU tests for controller-register confirmation:

```text
6030T6
FDUMA2
7032E5
4305T6
```

Questions:

- Do diagnostic reads use the same physical disk mapping as Monitor loads?
- Do FDU tests perform secondary overlay loads?
- Do command/read/write tests use direct controller routines or Monitor services?

## Trace transcript format

Use a line-oriented format so logs can be diffed and parsed later.

Recommended fields:

```text
run_id
disk_id
phase
pc
caller
selected_test
catalog_name
catalog_ext
catalog_loc
catalog_len
logical_sector
cylinder
head
sector
N
EOT
byte_count
dma_addr
mem_dest
result_status
entry_pc
notes
```

For memory snapshots, use a manifest:

```text
run_id
snapshot_name
time/phase
pc
segment map summary
dump file path
```

## Expected products

The trace campaign should produce these durable artifacts:

1. A verified physical format table per disk:

   ```text
   disk, track, head, sector count, sector size, mode, sector numbers
   ```

2. A verified logical-to-physical formula:

   ```text
   DML logical sector -> C/H/R/N
   catalogue loc/ext/len -> logical sector/count -> flat image offset
   ```

3. A per-test load map:

   ```text
   disk/test/catalogue entry
   disk source ranges
   RAM destination ranges
   entry PC
   secondary overlays
   resident dependencies
   ```

4. A correction list for static notes:

   ```text
   re/os/dcos/DML_filesystem.md assumptions confirmed/rejected
   re/hardware/go252/GO252_KDC_diagnostics.md overlay interpretation updates
   GO280/GO363 diagnostic load maps
   ```

## How to decide the overlay model

Use the following evidence hierarchy:

1. **Observed disk reads in MAME** are authoritative for physical access.
2. **Observed RAM writes/diffs** are authoritative for loaded layout.
3. **Catalogue fields** explain intent, but are not enough by themselves.
4. **Flat extracted offsets** are a convenience view and must be derived from the
   observed physical/logical mapping.
5. **Static linear disassembly** is useful only after the loaded runtime address
   and copied byte ranges are known.

If static catalogue spans disagree with live loads, prefer live loads and update
the DML interpretation.

## First milestone

The first milestone is a complete transcript for one disk-B run selecting
`KEYTE1`:

```text
boot disk B
load Monitor
select KEYTE1
stop at first KEYTE1 entry point
dump memory
record all disk reads
map loaded bytes back to disk-B offsets
```

That single run should answer whether `KEYTE1` is loaded as:

- one contiguous catalogue entry,
- a shared KDC support overlay plus a small test entry,
- an overlay chain with secondary reads,
- or a Monitor-resident table/routine set misidentified by flat disassembly.

## Second milestone

Repeat for `RAMVID`, `CRTGR2`, and `GRAPH3`, then compare the memory maps.

The comparison should identify:

```text
common KDC resident ranges
test-specific ranges
shared string/table ranges
entry points
secondary overlay behavior
```

Once those are known, the GO252 notes can be rewritten from live load evidence
rather than inferred catalogue spans.
