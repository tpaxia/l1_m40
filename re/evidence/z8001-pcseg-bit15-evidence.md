# Z8001: bit 15 of the PC segment word (evidence for a MAME CPU change)

Recorded 2026-10-01, before editing `src/devices/cpu/z8000/` in the external
MAME tree (AGENTS.md).

## Behaviour being changed

MAME's Z8001 always writes the PC segment back out with bit 15 set
(`make_segmented_addr()`: `| 0x80000000`), in `LDAR` (`addr_to_reg()`) and in
the return address pushed by `CALL`, `CALR` and traps. The proposed change
makes the core keep bit 15 of the segment word the PC was last loaded from
and emit that bit instead.

## Documentation

- Zilog *Z8000 CPU Technical Manual*, January 1983
  (`reference/datasheets/Z8000_CPU_Technical_Manual_Jan83.pdf`), LDAR, printed
  page 6-73 (PDF page 132): "In segmented mode, the address loaded into the
  destination has all 'reserved' bits (bits 16-23 and bit 31) cleared to
  zero."
- Same manual, LDA, printed page 6-71 (PDF page 130): "the address loaded
  into the destination has an undefined value in all reserved bits (bits
  16-23 and bit 31)."

So the manual does not support a constant 1 in bit 31 for LDAR. It says 0.

## Measurement on the physical part

The manual's "cleared to zero" is not what the part does either. Captures on
the physical Z8001 rig (`~/Projects/Z8000_FPGA/z8000_test`, branch
`pcseg-bit15-tests`, goldens in `golden/z8001-seg/`, tests 38-48 in
`tests/gen_segmented.py`):

| Test | PC loaded from | Read back | Result |
|---|---|---|---|
| `seg_ldar_pc_ir_b15clr_seg0` | `JP @RR2`, `0x0000:0210` | `LDAR RR4` | `0x0000` |
| `seg_ldar_pc_ir_b15set_seg0` | `JP @RR2`, `0x8000:0210` | `LDAR RR4` | `0x8000` |
| `seg_ldar_pc_ir_b15clr_seg1` | `JP @RR2`, `0x0100:0200` | `LDAR RR4` | `0x0100` |
| `seg_ldar_pc_ir_b15set_seg1` | `JP @RR2`, `0x8100:0200` | `LDAR RR4` | `0x8100` |
| `seg_ldar_pc_da_short_seg1` | short-offset `JP`, word `0x0120` | `LDAR RR4` | `0x0100` |
| `seg_ldar_pc_ret_b15clr_seg1` | `RET`, pushed `0x0100:0200` | `LDAR RR4` | `0x0100` |
| `seg_ldar_pc_iret_b15clr_seg1` | `IRET`, frame PCSEG `0x0100` | `LDAR RR4` | `0x0100` |
| `seg_ldar_pc_ldps_b15clr_seg1` | `LDPS @RR6`, block PCSEG `0x0100` | `LDAR RR4` | `0x0100` |
| `seg_ldar_pc_trap_b15clr_seg1` | SC vector, PSA PCSEG `0x0100` | `LDAR RR4` | `0x0100` |
| `seg_push_pcseg_ir_b15clr_seg1` | `JP @RR2`, `0x0100:0200` | SC push | `0x0100` |
| `seg_calr_push_ir_b15clr_seg1` | `JP @RR2`, `0x0100:0200` | CALR push | `0x0100` |

Earlier captures (`seg_mame_ldar_ra_hiword_poison` → `0x8000`,
`seg_push_pcseg_from_seg1` → `0x8100`) all entered their code through a
bit-15-set word (bootstrap `jp test_code` = `5e08 8000 0200`, long-form JP,
PSA entries `0x8000`), which is why they showed the bit set and why MAME
commit `ab41620cf2d` forced it. The low byte of the LDAR result is zero in
every capture (destination poisoned with `0xA5AA`).

Conclusion: the PC segment register keeps bit 15 of the word it was loaded
from; LDAR and PC pushes emit it unchanged.

## Why the M40 needs it

OSLEM 7.0+ (`oslem7+.imd`), `KIO0 MX82` initialisation, entered from the
start-up task (trace `runs-archive/restore-hd-20260928/install/ldar4/` ([screen](screenshots/restore-hd-20260928__install__ldar4.png))):

```
22:01D4  xor  r0,r0
22:01D6  ldb  rh0,rl1          ; r8 = 0x0300, bit 15 clear
22:0206  ld   r9,r8(#0x14)     ; entry offset 0x0044
22:0252  jp   @rr8
03:0046  ldar rr4,0x00b4
03:004A  ldb  <<0>>0x016c,rh4  ; must be 0x03; MAME stores 0x83
03:0056  ldar rr6,0x00ca
03:005A  ldb  rl6,rh6          ; must be 0x0303; MAME gives 0x8383
03:0068  ldar rr6,0x00ca
03:007C  ld   r12,r6
03:007E  set  r12,#15          ; the code sets bit 15 itself where it wants it
```

`00:016C` is later used as a library-descriptor byte whose bit 7 means "load
via logical unit" (→ `C205` at the DISK step), and the `0x8383` word as a
request flag whose bit 15 changes the driver's range check. Both are the two
"hacks" documented in re/os/oslem/OSLEM_STATUS.md 1E/1F.

Corroboration (not by itself the justification): with register-only
breakpoints clearing bit 15 after those three LDARs and no other change,
`oslem7+` boots to `DYSP OK== PRTR OK==` (`install/ldar2/`) and a full DKC£
copy of data set FF matches the reference image (`install/ldar3/`).

## Proposed change

`z8000.h`, `z8000.cpp`, `z8000ops.hxx`: add `m_pc_b15`; load it in JP/CALL
`@Rd`, JP/CALL `addr` and `addr(Rd)` (bit 15 of the address word: long-offset
form 1, short-offset form 0), RET, IRET, LDPS, trap/interrupt vectors and
reset; leave it alone for JR, CALR, DJNZ and non-segmented transfers; emit it
from LDAR and from pushed return addresses. The same change is in
`z8000_emu` branch `pcseg-bit15` (commit `7a0c925`), which then matches all
`golden/z8001-seg` captures (10 differing before, 1 after, the pre-existing
MSET case).

Systems to re-test: M40 (`oslem7+` without hacks), ZEUS on the S8000, M20.
