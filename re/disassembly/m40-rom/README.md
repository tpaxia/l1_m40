# M30/M40 ROM — round-trippable disassembly

Reassemblable Z8001 source for the resident ROMs. Each `.s` assembles+links back
to a **byte-identical** copy of the original dump in `../../../reference/roms`, so we can
annotate freely and always re-verify against the silicon.

## Files
- `m40rom-4.1.s` — `REL 4.1`, 8 KB (banner *17 DEC 82*).
- `m40rom-6.0.s` — `REL 6.0`, 16 KB (banner *17 DEC 82*).

> `REL x.x` is the loader-release number. The service manual's "ROM 151 / 152"
> is a *separate* board-generation label (UC boards before / from Nov 1982); it is
> not tied to the REL number, so these dumps being "ROM 152" is only inferred from
> their date, not confirmed.
- `Makefile` — `make verify` rebuilds both and `cmp`s against the originals.

## Toolchain
Uses the **patched** `z8k-coff` binutils (a binutils 2.46.0 build with the `.long_addr` patch) (same as
the M20 BIOS project). The patch adds the **`.long_addr`** directive, which forces
long-form for the *next* segmented-address instruction — essential for round-trip,
because stock `as` picks short form whenever the offset fits in 8 bits.

Segmented address syntax is a 32-bit constant `(segment<<24)|offset`; segment lives
in bits 30–24, offset in bits 15–0. `.long_addr` sets bit 15 of the emitted segment
word. PC-relative ops (`jr`/`calr`/`djnz`/`dbjnz`/`ldar`) **must** use labels — a bare
number is taken as a raw displacement — so the build **links** (`-Ttext 0`) to resolve
those relocations.

## Build / verify
```sh
make verify      # assemble+link+cmp both ROMs -> "IDENTICAL"
make clean
make regen       # regenerate .s from the ROMs (OVERWRITES hand edits!)
```

## How the source was generated
`../tools/mkasm.py` drives GNU `objdump` (same binutils, so its disassembly
reassembles), then:
- labels every PC-relative target,
- forces `.long_addr` where the raw bytes show a long-form seg address,
- emits data ranges as `.word`/`.byte`,
- iteratively falls back any instruction the assembler rejects or re-encodes
  differently to a raw `.word` (guaranteed identical) — these are mostly data
  tables objdump mis-decoded as code, to be reclaimed as we annotate.

Each instruction line carries a `! addr: rawbytes` trailing comment.

## Annotation workflow
Annotations live in the **`../tools/annotate_*.py`** passes, not in hand edits — so
they survive a regen. Each pass keys on the stable `! addr: rawbytes` markers and
only rewrites comments / inserts `!` lines, so the bytes never change. To add
commentary: edit (or add) an `annotate_*.py` pass, then run:

```sh
sh ../tools/rebuild.sh     # mkasm regen -> all annotate passes -> make verify
```

`rebuild.sh` regenerates both `.s` from the ROMs, re-applies every pass in order,
and confirms byte-identity. Data-region boundaries (e.g. embedded tables, the
`$BBU ON ` marker) are carved in `MAPS` inside `mkasm.py`. `make verify` alone still
checks the current `.s` without regenerating.

## Segment map (both ROMs)
| Range | Kind | Notes |
|---|---|---|
| `0x0000`–`0x0007` | data | reset vector (FCW/PC) |
| `0x0008`–`0x0027` | ascii | `" 17 DEC. 82  REL x.x "` banner in unused trap slots |
| `0x0028`–`0x00cd` | data | PSA vectors (NMI→`0xce`, NVI→`0xf2`) |
| `0x00ce`–`0x00f5` | code | NMI + NVI handlers |
| `0x00f6`–`0x0105` | data | gap before reset entry |
| `0x0106`–code end | code | main firmware (reset entry `0x0106`) |
| code end–EOF | data | `0xFF` padding + trailing checksum word |

The code/data split lives in `MAPS` in `mkasm.py`; refine it there as we identify
embedded data tables (each is currently a `.word` block inside the code range).
