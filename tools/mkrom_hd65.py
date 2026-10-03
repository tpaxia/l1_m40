#!/usr/bin/env python3
"""Build an EXPERIMENTAL M40 ROM: REL 6.0 plus GO363 (governo type 65) boot.

This ROM never existed.  It is the byte-exact REL 6.0 source (re/disassembly/m40-rom/m40rom-6.0.s)
with four changes, so that the hard-disk system installed on the WREN2 can be
IPLed.  Background: re/os/oslem/OSLEM_STATUS.md "Issue 2".

  1. ROM service table extended to 0x8C-0x9F, as on the M44 REL B.1 ROM.
     LDHSEL (HD LBA 0-6) and HDU1ST24 read the routine address from
     <<63>>0x0094 / 0x009C for governi 61/65.  REL 6.0 has code there (the VI
     dispatcher at 0x8C, entered by the `calr` that is ROM word 0), so the
     dispatcher moves to 0xA0 and its default handler (0xB4) to the free area.
  2. IPL list: type E4 (old HDU governo, first in the HDU-first list at
     0x06E6) is replaced by 65, and its handler-table entry points to a new
     stub.  E4 can no longer be IPLed from this ROM.
  3. New code in the free area (0x2996..): polled GO363/uPD7261 sector read,
     the register sequence being the one the OSLEM 7.0+ driver H65R issues
     (MAME -log of a JX24 run), minus the board VI enable.
  4. ROM checksum (last four bytes) recomputed (self-test at 0x01BE).

Geometry is fixed at 9 heads x 32 sectors (WREN2 / 65 MB): the M44 ROM asks
the board; that handshake is not reproduced here.

usage: mkrom_hd65.py re/disassembly/m40-rom/m40rom-6.0.s re/disassembly/m40-rom/m40rom-6.0-hd65.s
       mkrom_hd65.py --checksum re/disassembly/m40-rom/m40rom-6.0-hd65.bin      (patch in place)
"""
import struct, sys

DISPATCHER = r"""
! ---- 0x008c .. 0x00ce  ROM service table extension + relocated VI dispatcher ----
	.word	0x8000		! 008c: (M44: dispatcher pointer)
	.word	vi_disp
	.word	0x8000		! 0090: GO363 read by block number
	.word	hd65_rdlba
	.word	0x8000		! 0094: GO363 read by cylinder/head/sector (LDHSEL, HDU1ST24)
	.word	hd65_rdchs
	.word	0x8000		! 0098
	.word	hd65_rdlba
	.word	0x8000		! 009c
	.word	hd65_rdchs
vi_disp:			! was at 0x008c; reached by the calr in ROM word 0
	pushl @rr14,rr0
	pushl @rr14,rr2
	pushl @rr14,rr4
	ld r1,rr14(#0x10)
	bit r1,#0x0
	jr ne,vi_disp_def
	subb rh1,rh1
	add r1,r1
	.long_addr
	lda rr2,0x10001c0
	ldl rr4,rr2(r1)
	ldl rr14(#0xc),rr4
	popl rr4,@rr14
	popl rr2,@rr14
	popl rr0,@rr14
	ret t
vi_disp_def:
	ldar rr2,L_00b4
	jp t,@rr2
"""

NEWCODE = r"""
! ---- GO363 (type 65) support: EXPERIMENTAL, not part of REL 6.0 ----
L_00b4:				! default VI handler, moved from 0x00b4
	ldb rl7,#0x3
	ldb rl0,#0x70
	outb #0xffc3,rl0
	ldk r2,#0xf
hd65_d1:
	djnz r3,hd65_d1
	djnz r2,hd65_d1
	ldar rr10,hd65_d2
	.long_addr
	jp t,0xb7e
hd65_d2:
	jr t,hd65_d2

hd65_list:			! unit "types" matched against <<1>>0x0270..
	.byte	0x01,0x00

! IPL stub, called from the device search (0x06b6) for type 65
hd65_stub:
	ldar rr8,hd65_list
	ldar rr4,hd65_init
	ldar rr10,hd65_rdlba
	ldar rr12,hd65_geom
	.long_addr
	jp t,0x74c

! geometry for the common loader: r4 -> <<1>>030c, rl5 -> 030e (heads),
! rl6 -> 0306 (sectors per track)
hd65_geom:
	ld r4,#1024
	ld r5,#9
	ld r6,#32
	sub r7,r7
	ret t

! ---- port helpers: r1 = (slot << 8) | register, r0 = data ----
hd65_port:			! rh1 = board port high byte
	.long_addr
	ldb rh1,0x1000302
	andb rh1,#0xf0
	ret t

! wait for completion: poll 0x4a/0x4b for 0x28; returns Z and rl0 = HDC
! status, or NZ with r7 = 2 on timeout
hd65_wait:
	push @rr14,r2
	push @rr14,r3
	ld r2,#0x40
	sub r3,r3
hd65_w1:
	ldb rl1,#0x4a
	in r0,@r1
	andb rl0,#0x28
	cpb rl0,#0x28
	jr eq,hd65_w2
	djnz r3,hd65_w1
	djnz r2,hd65_w1
	pop r3,@rr14
	pop r2,@rr14
	ldk r7,#0x2
	or r7,r7
	ret t
hd65_w2:
	ldb rl1,#0x68
	ldb rl0,#0x2
	outb @r1,rl0
	ldb rl1,#0x11
	inb rl0,@r1
	pop r3,@rr14
	pop r2,@rr14
	cp r0,r0
	ret t

! end-of-command housekeeping; r0 = closing board command word
hd65_clean:
	push @rr14,r0
	ldb rl1,#0x10
	ld r0,#0x0800
	out @r1,r0
	ld r0,#0x0200
	out @r1,r0
	ldb rl1,#0x48
	ld r0,#0x000c
	out @r1,r0
	ld r0,#0x0018
	out @r1,r0
	ldb rl0,#0x3
	outb @r1,rl0
	pop r0,@rr14
	ldb rl1,#0x4c
	out @r1,r0
	ret t

! board + controller initialisation (IPL): r7 = 0 if a unit answers
hd65_init:
	pushl @rr14,rr0
	pushl @rr14,rr2
	pushl @rr14,rr4
	calr hd65_port
	ldb rl1,#0x4a
	in r0,@r1
	ldb rl1,#0x10
	ld r0,#0x0100
	out @r1,r0
	ldb rl1,#0x4c
	out @r1,r0
	ldb rl1,#0x4a
	in r0,@r1
	ldb rl0,#0x0a
	outb @r1,rl0
	ldb rl1,#0x4c
	ld r0,#0x0300
	out @r1,r0
	ldb rl1,#0x4a
	in r0,@r1
	ldb rl1,#0x10
	in r0,@r1
	! SPECIFY
	ldb rl1,#0x48
	ld r0,#0x0020
	out @r1,r0
	ldar rr2,hd65_spec
	ldb rl1,#0x01
	ldk r0,#0x8
hd65_i1:
	ldb rl7,@rr2
	outb @r1,rl7
	inc r3,#0x1
	djnz r0,hd65_i1
	ldb rl1,#0x48
	ld r0,#0x000d
	out @r1,r0
	ldb rl1,#0x11
	ldb rl0,#0x20
	outb @r1,rl0
	calr hd65_wait
	jr ne,hd65_i9
	ld r0,#0x1d00
	calr hd65_clean
	ld r0,#0x0a00
	out @r1,r0
	! seek to cylinder 0 (also checks that unit 0 is there)
	sub r4,r4
	calr hd65_seek
	jr ne,hd65_i9
	! unit table for the common loader: unit 0 present
	.long_addr
	lda rr2,0x1000270
	ldb rl0,#0x1
	ldb @rr2,rl0
	ldk r0,#0x7
	clrb rl7
hd65_i2:
	inc r3,#0x1
	ldb @rr2,rl7
	djnz r0,hd65_i2
	sub r7,r7
hd65_i9:
	popl rr4,@rr14
	popl rr2,@rr14
	popl rr0,@rr14
	or r7,r7
	ret t
hd65_spec:			! mode, dtlh, dtll, etn, esn, gpl2, rwch, rwcl
	.byte	0x58,0xb1,0x00,0x08,0x1f,0x0d,0x00,0x20

! seek: r4 = cylinder.  NZ / r7 on error.  rh1 must be set.
hd65_seek:
	ldb rl1,#0x4a
	in r0,@r1
	ldb rl1,#0x10
	in r0,@r1
	ldb rl1,#0x40
	ld r0,#0x0600
	out @r1,r0
	ldb rl1,#0x48
	ld r0,#0x000d
	out @r1,r0
	ldb rl1,#0x42
	in r0,@r1
	andb rl0,#0x15
	cpb rl0,#0x15
	jr eq,hd65_s1
	ldk r7,#0x4
	or r7,r7
	ret t
hd65_s1:
	ldb rl1,#0x48
	ld r0,#0x060c
	out @r1,r0
	ld r0,#0x0020
	out @r1,r0
	ldb rl1,#0x01
	outb @r1,rh4
	outb @r1,rl4
	ldb rl1,#0x48
	ld r0,#0x000d
	out @r1,r0
	ldb rl1,#0x11
	ldb rl0,#0x68
	outb @r1,rl0
	calr hd65_wait
	ret ne
	bitb rl0,#0x6
	jr ne,hd65_s2
	ldk r7,#0x5
	or r7,r7
	ret t
hd65_s2:
	ldb rl1,#0x01
	inb rl0,@r1
	ld r0,#0x2000
	calr hd65_clean
	sub r7,r7
	ret t

! read one sector: r4 = cylinder, rh5 = head, rl5 = sector,
! rr2 = physical byte address.  NZ / r7 on error.  rh1 must be set.
hd65_rd1:
	ldb rl1,#0x4a
	in r0,@r1
	ldb rl1,#0x10
	in r0,@r1
	ldb rl1,#0x40
	ldb rh0,#0x4
	ldb rl0,rh5
	out @r1,r0
	ldb rl1,#0x48
	ld r0,#0x000d
	out @r1,r0
	ldb rl1,#0x42
	in r0,@r1
	ldb rl1,#0x48
	ld r0,#0x040c
	out @r1,r0
	ldb rl1,#0x57
	ldb rl0,#0xb0
	outb @r1,rl0
	ldb rl1,#0x56
	ldb rl0,#0x0f
	outb @r1,rl0
	clrb rl0
	outb @r1,rl0
	! DMA address in words: physical byte address >> 1
	srl r2,#0x1
	rrc r3,#0x1
	ldb rl1,#0x42
	out @r1,r3
	ldb rl1,#0x44
	out @r1,r2
	ldb rl1,#0x57
	ldb rl0,#0x70
	outb @r1,rl0
	ldb rl1,#0x47
	ldb rl0,#0xff
	outb @r1,rl0
	clrb rl0
	outb @r1,rl0
	ldb rl1,#0x48
	ldb rl0,#0xaa
	outb @r1,rl0
	ldb rl0,#0x19
	outb @r1,rl0
	! READ DATA parameters: phn, lcnh, lcnl, lhn, lsn, scnt
	ldb rl1,#0x01
	clrb rl0
	outb @r1,rl0
	ldb rl0,rh4
	orb rl0,#0x10
	outb @r1,rl0
	outb @r1,rl4
	outb @r1,rh5
	outb @r1,rl5
	ldb rl0,#0x1
	outb @r1,rl0
	ldb rl1,#0x48
	ld r0,#0x000d
	out @r1,r0
	ldb rl1,#0x11
	ldb rl0,#0xb0
	outb @r1,rl0
	ldb rl1,#0x4c
	ld r0,#0x1100
	out @r1,r0
	ld r0,#0x0d00
	out @r1,r0
	calr hd65_wait
	ret ne
	ldb rh0,rl0
	ldb rl1,#0x01
	ldk r2,#0x7
hd65_r1:
	inb rl0,@r1
	djnz r2,hd65_r1
	push @rr14,r0
	ld r0,#0x2400
	calr hd65_clean
	pop r0,@rr14
	cpb rh0,#0x40
	jr eq,hd65_r2
	ldk r7,#0x6
	or r7,r7
	ret t
hd65_r2:
	sub r7,r7
	ret t

! ---- services: rr2 -> block {+0 buffer (long, logical), +4 byte count,
!      +6 block number (long)  or  +6 cylinder, +8 head, +9 sector} ----
! return r7 = 0 if good; all other registers preserved
hd65_rdlba:
	dec r15,#0x8
	ldl @rr14,rr0		! keep rr0
	ldl rr0,rr2(#0x6)	! block number
	jr t,hd65_rd
hd65_rdchs:
	dec r15,#0x8
	ldl @rr14,rr0
	ld r1,rr2(#0x6)		! cylinder
	sub r0,r0
	mult rr0,#9
	ldb rl7,rr2(#0x8)	! head
	subb rh7,rh7
	add r1,r7
	slll rr0,#0x5
	ldb rl7,rr2(#0x9)	! sector
	subb rh7,rh7
	add r1,r7
hd65_rd:			! rr0 = block number, rr2 -> block
	ldl rr14(#0x4),rr2
	pushl @rr14,rr4
	pushl @rr14,rr8
	pushl @rr14,rr10
	pushl @rr14,rr12
	ldl rr10,rr0		! rr10 = block number
	ldl rr8,@rr2		! rr8 = logical buffer address
	ld r12,rr2(#0x4)	! byte count -> sectors
	add r12,#0xff
	srl r12,#0x8
	jr ne,hd65_rd0
	ldk r12,#0x1
hd65_rd0:
	calr hd65_port
	ld r13,#0xffff		! cylinder the heads are on
hd65_rd1l:
	ldl rr4,rr10
	div rr4,#288		! r5 = cylinder, r4 = remainder
	ld r3,r4
	ld r4,r5
	sub r2,r2
	div rr2,#32		! r3 = head, r2 = sector
	ldb rh5,rl3
	ldb rl5,rl2
	cp r4,r13
	jr eq,hd65_rd2
	ld r13,r4
	calr hd65_seek
	jr ne,hd65_rd9
hd65_rd2:
	ldl rr2,rr8		! logical -> physical through the ROM helper
	push @rr14,r12
	push @rr14,r13
hd65_rd3:
	ldar rr12,hd65_rd3
	ld r13,#0xa70
	call @rr12
	pop r13,@rr14
	pop r12,@rr14
	calr hd65_rd1
	jr ne,hd65_rd9
	add r9,#0x100
	addl rr10,#0x1
	djnz r12,hd65_rd1l
	sub r7,r7
hd65_rd9:
	popl rr12,@rr14
	popl rr10,@rr14
	popl rr8,@rr14
	popl rr4,@rr14
	ldl rr0,@rr14
	ldl rr2,rr14(#0x4)
	inc r15,#0x8
	or r7,r7
	ret t
	.even
"""


def checksum(d):
    """REL 6.0 self-test at 0x01BE: two end-around-carry sums over 0..0x3FFB."""
    even = odd = 0
    for i in range(0, 0x3ffc, 2):
        even += d[i] ^ (i & 0xff)
        even = (even & 0xffff) + (even >> 16)
        odd += d[i + 1] ^ ((i + 1) & 0xff)
        odd = (odd & 0xffff) + (odd >> 16)
    # the ROM compares rr0 (r0 = odd sum, r1 = even sum) with the last long
    # after `exb rh4,rl5`
    r0, r1 = odd, even
    b = [r0 >> 8, r0 & 0xff, r1 >> 8, r1 & 0xff]
    b[0], b[3] = b[3], b[0]
    return bytes(b)


def patch_checksum(path):
    d = bytearray(open(path, 'rb').read())
    assert len(d) == 0x4000, len(d)
    d[0x3ffc:] = checksum(d)
    open(path, 'wb').write(d)
    print('checksum', d[0x3ffc:].hex())


def main():
    if sys.argv[1] == '--checksum':
        return patch_checksum(sys.argv[2])
    if sys.argv[1] == '--verify':          # the scheme reproduces the original
        d = open(sys.argv[2], 'rb').read()
        assert checksum(d) == d[0x3ffc:], (checksum(d).hex(), d[0x3ffc:].hex())
        return print('checksum scheme verified on', sys.argv[2])
    src, dst = sys.argv[1], sys.argv[2]
    lines = open(src).read().split('\n')
    out = []
    i = 0
    state = 'head'
    while i < len(lines):
        ln = lines[i]
        if state == 'head' and ln.strip() == '.word\t0xdfbb':
            out.append('\tcalr vi_disp\t\t\t! 0000: was dfbb (calr 0x8c)')
            state = 'table'
        elif state == 'table' and ln.strip() == '.word\t0x0a68':
            out.append(ln)
            out.append(DISPATCHER.strip('\n'))
            # drop the old 0x8c..0xcd words (0x21 words) and the L_00b4 label
            n = 0
            i += 1
            while n < 0x21:
                if lines[i].strip().startswith('.word'):
                    n += 1
                i += 1
            assert lines[i].strip() == '' or lines[i].startswith('!'), lines[i]
            state = 'ipl'
            continue
        elif state == 'ipl' and '! 06e6: e4ef' in ln:
            out.append('\t.word\t0x65ef\t\t! 06e6: was e4ef (E4 -> 65)')
            state = 'ipltab'
        elif state == 'ipltab' and ln.strip().startswith('.word\t0x002e'):
            out.append('\t.word\thd65_stub-L_06ee\t! 06ee: was 002e (E4 stub at 0x071c)')
            state = 'tail'
        elif state == 'tail' and ln.startswith('! ---- 0x2996 .. 0x4000'):
            out.append(NEWCODE.strip('\n'))
            out.append('\t.org\t0x3ffc,0xff')
            out.append('\t.word\t0x0000\t\t! checksum, patched after linking')
            out.append('\t.word\t0x0000')
            state = 'done'
            break
        else:
            out.append(ln)
        i += 1
    assert state == 'done', state
    open(dst, 'w').write('\n'.join(out) + '\n')
    print('wrote', dst)


if __name__ == '__main__':
    main()
