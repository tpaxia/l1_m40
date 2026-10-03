	.z8001
	.text
	.org	0

! ---- 0x0000 .. 0x0008  (word) ----
L_0000:
	.word	0xdfbb
	.word	0xc000
	.word	0x8000
	.word	0x0106

! ---- 0x0008 .. 0x0028  (ascii) ----
	! " 17 DEC. 82     REL 4.1         "
	.byte	0x20,0x31,0x37,0x20,0x44,0x45,0x43,0x2e
	.byte	0x20,0x38,0x32,0x20,0x20,0x20,0x20,0x20
	.byte	0x52,0x45,0x4c,0x20,0x34,0x2e,0x31,0x20
	.byte	0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20

! ---- 0x0028 .. 0x00ce  (word) ----
	.word	0x0000
	.word	0xc000
	.word	0x8000
	.word	0x00ce
	.word	0x0000
	.word	0xc000
	.word	0x8000
	.word	0x00f2
	.word	0x0000
	.word	0xc000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8100
	.word	0x0000
	.word	0x8000
	.word	0x03a4
	.word	0x8100
	.word	0x0000
	.word	0x8000
	.word	0x0552
	.word	0x8000
	.word	0x0a60
	.word	0xff00
	.word	0xffff
	.word	0xff00
	.word	0xffff
	.word	0xff00
	.word	0xffff
	.word	0x8000
	.word	0x1642
	.word	0x8000
	.word	0x14ae
	.word	0x8000
	.word	0x0d10
	.word	0x8000
	.word	0x19fa
	.word	0x8000
	.word	0x1e2c
	.word	0x8000
	.word	0x0dd4
	.word	0x8000
	.word	0x1a5e
	.word	0x8000
	.word	0x17f0
	.word	0x8000
	.word	0x0a68
	.word	0x91e0
	.word	0x91e2
	.word	0x91e4
	.word	0x31e1
	.word	0x0010
	.word	0xa710
	.word	0xee0d
	.word	0x8211
	.word	0x8111
	.word	0x7602
	.word	0x8100
	.word	0x01c0
	.word	0x7524
	.word	0x0100
	.word	0x37e4
	.word	0x000c
	.word	0x95e4
	.word	0x95e2
	.word	0x95e0
	.word	0x9e08
L_00b4:
	.word	0xcf03
	.word	0xc870
	.word	0x3a86
	.word	0xffc3
	.word	0xbd2f
	.word	0xf381
	.word	0xf282
	.word	0x340a
	.word	0x0006
	.word	0x5e08
	.word	0x8000
	.word	0x0b7e
	.word	0xe8ff

! ---- 0x00ce .. 0x00f6  (code) ----
!------------------------------------------------------------------------------
! NMI HANDLER = RAM-probe fault handler.  A memory read with no READY raises an
! NMI; here rr12 already points at the RAM-sizing loop's resume point, and r13
! (its low half) is that checkpoint's offset.  The handler pops the NMI frame,
! confirms we are in the probe loop (r13 = 0xaa8/0xaea), clears the source at
! 0xFF41, and either records the location (0x0ada) or skips the window (rr12).
!------------------------------------------------------------------------------
	inc r15,#0x8                      ! 00ce: a9f7   pop the 8-byte NMI frame (resume, don't iret)
	cp r13,#0xaa8                     ! 00d0: 0b0d0aa8   in the RAM-sizing probe loop? (rr12 low = checkpoint 0xaa8)
	jr eq,L_00dc                      ! 00d4: e603
	cp r13,#0xaea                     ! 00d6: 0b0d0aea   ...or the 'record end' checkpoint (0xaea)?
	jr ne,L_00ec                      ! 00da: ee08   neither -> generic NMI: just clear source and resume
L_00dc:
	inb rl6,#0xff41                   ! 00dc: 3ae4ff41   read NMI source (0xFF41)
	out #0xff41,r0                    ! 00e0: 3b06ff41   clear it
	bitb rl6,#0x6                     ! 00e4: a6e6   NMI-source bit 6 set?
	.long_addr
	jp ne,0xada                       ! 00e6: 5e0e80000ada   set -> location responded: record it (0x0ada)
L_00ec:
	out #0xff41,r0                    ! 00ec: 3b06ff41   clear NMI source
	jp t,@rr12                        ! 00f0: 1ec8   resume the probe at rr12 (= skip this window)
	inc r15,#0x8                      ! 00f2: a9f7   NVI handler: pop frame and resume at rr12
	jp t,@rr12                        ! 00f4: 1ec8

! ---- 0x00f6 .. 0x0106  (word) ----
! MMU descriptor init table (base_hi, base_lo, limit, attr) x4, loaded at 0x25c:
!   desc 0  : 00 00 ff 00  seg0  -> phys 0x000000, limit 0xff (64 KB)  = ROM
!   desc 61 : ff 00 ff 00  seg61 -> phys 0xff0000, 64 KB              = video
!   desc 62 : f0 00 ff 00  seg62 -> phys 0xf00000, 64 KB              = video
!   desc 63 : 00 00 ff 00  seg63 -> phys 0x000000
L_00f6:
	.word	0x0000
	.word	0xff00
	.word	0xff00
	.word	0xff00
	.word	0xf000
	.word	0xff00
	.word	0x0000
	.word	0xff00

! ---- 0x0106 .. 0x039c  (code) ----
	ldb rl0,#0x80                     ! 0106: c880
	soutb #0x0,rl0                    ! 0108: 3a870000
	sub r0,r0                         ! 010c: 8300
	out #0xf0e0,r0                    ! 010e: 3b06f0e0
	out #0xf0e2,r0                    ! 0112: 3b06f0e2
	ldar rr10,L_0122                  ! 0116: 340a0008
	ldb rl7,#0x1                      ! 011a: cf01
	.long_addr
	jp t,0xbaa                        ! 011c: 5e0880000baa
!==============================================================================
! POST-RESET INIT: DRAM refresh, stack, PSAP, 8253 timers, config port.
!==============================================================================
L_0122:
	ld r0,#0x9200                     ! 0122: 21009200
	ldctl refresh,r0                  ! 0126: 7d0b   DRAM refresh control = 0x9200 (enable + rate)
	lda rr14,0xfe                     ! 0128: 760e00fe   SP (rr14) = <<0>>0x00fe
	.long_addr
	ldar rr2,L_0000                   ! 012c: 3402fed0
	ldctl psapseg,r2                  ! 0130: 7d2c   PSAP -> <<0>>0x0000 (PSA at ROM start)
	ldctl psapoff,r3                  ! 0132: 7d3d
	ldb rl0,#0x34                     ! 0134: c834
	outb #0xffc7,rl0                  ! 0136: 3a86ffc7   8253 ctrl: counter0 = mode2 (rate gen)
	ldb rl0,#0x70                     ! 013a: c870
	outb #0xffc7,rl0                  ! 013c: 3a86ffc7   8253 ctrl: counter1 = mode0
	ldb rl0,#0xb6                     ! 0140: c8b6
	outb #0xffc7,rl0                  ! 0142: 3a86ffc7   8253 ctrl: counter2 = mode3 (square wave)
	inb rl0,#0xffa0                   ! 0146: 3a84ffa0   read config/jumpers (port 0xFFA0)
	ldb rl0,#0x3                      ! 014a: c803
	outb #0xff20,rl0                  ! 014c: 3a86ff20   UC control latch 0xFF20 = 0x03

!------------------------------------------------------------------------------
! Preliminary board scan: step the device-select high byte (rh1 += 0x10),
! read each board's ID at port 0x?FFF, and inline-init a video (ID 0xFE) or
! line (ID 0xD?) board so diagnostics have an output device early.
!------------------------------------------------------------------------------
	subl rr6,rr6                      ! 0150: 9266   rr6 = 0
	ldar rr12,L_01b2                  ! 0152: 340c005c   rr12 = &next-slot  <- NMI resume target if this slot is empty
	sub r1,r1                         ! 0156: 8311   r1 = 0  -> device-select high byte starts at 0x00
L_0158:
	or r1,#0xfff                      ! 0158: 05010fff   r1 = (slot<<8) | 0x0FFF  -> the board's ID port
	inb rl0,@r1                       ! 015c: 3c18   read board ID  (empty slot: no READY -> NMI -> rr12 = next slot)
	cpb rl0,#0xf0                     ! 015e: 0a08f0f0   ID == 0xF0 ?
	jr ne,L_016a                      ! 0162: ee03
	ldb rl1,#0x81                     ! 0164: c981   reg-select 0x81
	ldb rh0,#0x7                      ! 0166: c007
	outb @r1,rh0                      ! 0168: 3e10   write 0x07 to reg 0x81
L_016a:
	cpb rl0,#0xfe                     ! 016a: 0a08fefe   ID == 0xFE (video) ?
	jr ne,L_01a0                      ! 016e: ee18   not video -> try line board
	ldb rh0,#0x3                      ! 0170: c003   -- video: blank it for now --
	ldb rl1,#0x1                      ! 0172: c901   reg-select 0x01
	outb @r1,rh0                      ! 0174: 3e10   reg 0x01 = 0x03
	ldb rl1,#0x41                     ! 0176: c941   reg-select 0x41 (CRTC address)
	ldk r2,#0x6                       ! 0178: bd26   select CRTC R6 (rows displayed)
	outb @r1,rl2                      ! 017a: 3e1a
	ldb rl1,#0x43                     ! 017c: c943   reg-select 0x43 (CRTC data)
	outb @r1,rh2                      ! 017e: 3e12   R6 = 0 -> blank
	ldb rl1,#0x41                     ! 0180: c941   reg-select 0x41
	ldb rl2,#0x1                      ! 0182: ca01   select CRTC R1 (cols displayed)
	outb @r1,rl2                      ! 0184: 3e1a
	ldb rl1,#0x43                     ! 0186: c943   reg-select 0x43
	outb @r1,rh2                      ! 0188: 3e12   R1 = 0 -> blank
	ldk r2,#0x2                       ! 018a: bd22   clear indicator regs 0x65..0x67 (r6=0)
L_018c:
	ldb rl1,#0x65                     ! 018c: c965   reg 0x65 + i
	addb rl1,rl2                      ! 018e: 80a9
	bit r6,r2                         ! 0190: 27020600
	jr eq,L_0198                      ! 0194: e601
	set r1,#0x3                       ! 0196: a513
L_0198:
	outb @r1,rl1                      ! 0198: 3e19
	dec r2,#0x1                       ! 019a: ab20
	jr pl,L_018c                      ! 019c: edf7
	inc r6,#0x1                       ! 019e: a960
L_01a0:
	andb rl0,#0xf1                    ! 01a0: 0608f1f1   mask ID with 0xF1
	cpb rl0,#0xd0                     ! 01a4: 0a08d0d0   == 0xD0 (line-board family) ?
	jr ne,L_01b2                      ! 01a8: ee04
	ldb rl1,#0xb1                     ! 01aa: c9b1   reg-select 0xB1
	ldb rh0,#0x1                      ! 01ac: c001
	outb @r1,rh0                      ! 01ae: 3e10   write 0x01 to reg 0xB1
	ldb rh7,#0xff                     ! 01b0: c7ff   rh7 = 0xFF  <- flag: line board present (later skips the ROM checksum)
L_01b2:
	addb rh1,#0x10                    ! 01b2: 00011010   next slot: high byte += 0x10
	jr nc/uge,L_0158                  ! 01b6: efd0   loop until it carries past 0xF0  (16 slots scanned)
	ldctl nspoff,r7                   ! 01b8: 7d7f   NSP = r7
	or r7,r7                          ! 01ba: 8577
	jr ne,L_0242                      ! 01bc: ee42   skip checksum if r7 flag set

!==============================================================================
! ROM CHECKSUM  ("Test ROM", Manuale dei Collaudi 1-2)
! Two interleaved 16-bit sums-with-end-around-carry over the whole ROM (even
! bytes -> sum1, odd bytes -> sum0), each byte first XORed with its offset low
! byte. Compared against the 4-byte value stored at the very top (0x1ffc).
! Verified: reproduces the stored word for both 4.1 (d977 e802) and 6.0.
! On mismatch the CPU hangs at 0x1e6 (no console output possible yet).
!==============================================================================
	subl rr0,rr0                      ! 01be: 9200   sum0:sum1 (rr0) = 0  <- running checksum
	subl rr2,rr2                      ! 01c0: 9222   rr2 = <<0>>0x0000  <- pointer (r2=seg, r3=offset)
	subl rr4,rr4                      ! 01c2: 9244   rr4 = 0 (byte scratch; rh4/rh5 stay 0)
	sub r6,r6                         ! 01c4: 8366   r6 = 0 (carry addend)
	ld r7,#0xffe                      ! 01c6: 21070ffe   count = 0x0ffe pairs = 8188 bytes (all but the 4-byte checksum)
L_01ca:
	ldb rl4,@rr2                      ! 01ca: 202c   b1 = ROM[offset]
	xorb rl4,rl3                      ! 01cc: 88bc   b1 ^= offset & 0xff
	inc r3,#0x1                       ! 01ce: a930   offset++  (r3 is the low half of rr2)
	ldb rl5,@rr2                      ! 01d0: 202d   b2 = ROM[offset]
	xorb rl5,rl3                      ! 01d2: 88bd   b2 ^= offset & 0xff
	inc r3,#0x1                       ! 01d4: a930   offset++
	add r1,r4                         ! 01d6: 8141   sum1 += b1
	adc r1,r6                         ! 01d8: b561     + end-around carry
	add r0,r5                         ! 01da: 8150   sum0 += b2
	adc r0,r6                         ! 01dc: b560     + end-around carry
	djnz r7,L_01ca                    ! 01de: f78b   next pair
	ldl rr4,@rr2                      ! 01e0: 1424   rr4 = stored checksum (4 bytes @ 0x1ffc)
	exb rh4,rl5                       ! 01e2: acd4   byte-swap to accumulator layout (rh4<->rl5)
	cpl rr0,rr4                       ! 01e4: 9040   computed (rr0) == stored (rr4) ?
L_01e6:
	jr ne,L_01e6                      ! 01e6: eeff   MISMATCH -> hang here forever (ROM fault)

!------------------------------------------------------------------------------
! 8253 TIMER test (Collaudi 1-3).  counter0 (mode2) prescales the clock for
! counter1 (mode0), preloaded 0x03be.  Poll-latch counter1 until it counts
! through 0 (bit15 set); the CPU poll-count must land in [0x28,0x100) --
! too fast -> hang @0x21e, stuck/too slow -> hang @0x206.
!------------------------------------------------------------------------------
	ldk r0,#0x2                       ! 01e8: bd02   counter0 reload = 2 (prescaler feeding counter1)
	outb #0xffc1,rl0                  ! 01ea: 3a86ffc1
	outb #0xffc1,rh0                  ! 01ee: 3a06ffc1   counter0 = 0x0002
	ld r1,#0x3be                      ! 01f2: 210103be   counter1 reload = 0x03be
	outb #0xffc3,rl1                  ! 01f6: 3a96ffc3
	outb #0xffc3,rh1                  ! 01fa: 3a16ffc3   counter1 = 0x03be, counting down (mode0)
L_01fe:
	ldb rl0,#0x40                     ! 01fe: c840
	outb #0xffc7,rl0                  ! 0200: 3a86ffc7   latch counter1 for reading (ctrl 0x40)
	incb rh0,#0x1                     ! 0204: a800   poll counter (rh0)++
L_0206:
	jr eq,L_0206                      ! 0206: e6ff   256 polls w/o terminal count -> hang (stuck/slow)
	inb rl1,#0xffc3                   ! 0208: 3a94ffc3   read counter1 LSB
	inb rh1,#0xffc3                   ! 020c: 3a14ffc3   read counter1 MSB
	bit r1,#0xf                       ! 0210: a71f   counter1 wrapped through 0 (bit15 set)?
	jr eq,L_01fe                      ! 0212: e6f5   not yet -> keep polling
	ldb rl0,#0x70                     ! 0214: c870
	outb #0xffc7,rl0                  ! 0216: 3a86ffc7   reprogram counter1 (mode0)
	cpb rh0,#0x28                     ! 021a: 0a002828   polls taken >= 0x28 ?
L_021e:
	jr lt,L_021e                      ! 021e: e1ff   < 0x28 -> timer too fast -> hang

!==============================================================================
! Z8010 MMU DESCRIPTOR TEST  ("Test Z8010", Collaudi 1-2)
! Write 0x00 to all 256 descriptor bytes (64 segs x 4) via SAR+auto-inc, read
! back and compare; mismatch -> hang. Then fill them all with 0xFF to mark
! every segment invalid before the real descriptors are loaded.
!==============================================================================
	sub r0,r0                         ! 0220: 8300   r0 = 0 (test pattern + SAR/DSC)
	soutb #0x100,rl0                  ! 0222: 3a870100   MMU SAR = 0 (descriptor 0)
	soutb #0x2000,rl0                 ! 0226: 3a872000   MMU DSC = 0 (byte 0)
L_022a:
	soutb #0xf00,rl0                  ! 022a: 3a870f00   write 0x00 to descriptor byte, auto-inc SAR
	dbjnz rl0,L_022a                  ! 022e: f803   ...256 bytes = all 64 descriptors x 4
	soutb #0x100,rl0                  ! 0230: 3a870100   SAR = 0
	soutb #0x2000,rl0                 ! 0234: 3a872000   DSC = 0
L_0238:
	sinb rh0,#0xf00                   ! 0238: 3a050f00   read descriptor byte back
	cpb rh0,rl0                       ! 023c: 8a80   == 0x00 ?
L_023e:
	jr ne,L_023e                      ! 023e: eeff   MISMATCH -> hang (MMU fault)
	dbjnz rl0,L_0238                  ! 0240: f805   ...256 bytes
L_0242:
	ld r0,#0xff                       ! 0242: 210000ff   pattern = 0xff (rl0=0xff, rh0=0)
	soutb #0x100,rh0                  ! 0246: 3a070100   SAR = 0
	soutb #0x2000,rh0                 ! 024a: 3a072000   DSC = 0
L_024e:
	soutb #0xf00,rl0                  ! 024e: 3a870f00   fill every descriptor byte with 0xff (mark all segs invalid)
	dbjnz rh0,L_024e                  ! 0252: f003   ...256 bytes
	soutb #0x100,rh0                  ! 0254: 3a070100   SAR = 0
	soutb #0x2000,rh0                 ! 0258: 3a072000   DSC = 0
	.long_addr

!------------------------------------------------------------------------------
! Load the live MMU map from the table at 0x00f6 and switch the MMU into
! translate mode: segment 0 -> ROM (phys 0x000000), segments 61..63 -> video
! windows (phys 0xff0000 / 0xf00000, 64 KB each).  After this, <<61>> reaches
! video RAM.  Ref: Collaudi 1-2 ("segment 0 = ROM, segment 61 = video RAM").
!------------------------------------------------------------------------------
	ldar rr2,L_00f6                   ! 025c: 3402fe96   rr2 = &descriptor init table (0x00f6)
	ld r1,#0xf00                      ! 0260: 21010f00   MMU port = R/W descriptor + auto-inc SAR
	ldk r0,#0x4                       ! 0264: bd04   4 bytes = 1 descriptor
	sotirb @r1,@rr2,r0                ! 0266: 3a230010   load descriptor 0 = segment 0 (ROM) [SAR=0]
	ldb rl0,#0x3d                     ! 026a: c83d
	soutb #0x100,rl0                  ! 026c: 3a870100   SAR = 0x3d = 61
	ldk r0,#0xc                       ! 0270: bd0c   12 bytes = 3 descriptors
	sotirb @r1,@rr2,r0                ! 0272: 3a230010   load descriptors 61,62,63 = video windows
	ldb rl0,#0xc0                     ! 0276: c8c0
	soutb #0x0,rl0                    ! 0278: 3a870000   MMU mode = 0xC0 (MSEN|TRNS) -> ENABLE TRANSLATION

!==============================================================================
! BACKPLANE SLOT SCAN — video pass
! Walk all 16 device-select slots (high byte 0x00,0x10,...,0xF0). Each board
! answers its logical-name ID byte at I/O port (slot<<8)|0x0FFF. An EMPTY slot
! has no READY, so the read faults and the NMI handler (0x00ce) resumes at
! rr12 = the next slot. Every video board (ID 0xFE) is initialised and
! self-tested (0x0bc6) and handed the next 0x2000-byte framebuffer window (r7).
!==============================================================================
	ldk r7,#0x0                       ! 027c: bd70   r7 = 0  <- video framebuffer window offset
	sub r1,r1                         ! 027e: 8311   r1 = 0  -> device-select high byte starts at 0x00
L_0280:
	ldar rr12,L_02a0                  ! 0280: 340c001c   rr12 = &next-slot  <- NMI resume target if this slot is empty
	or r1,#0xfff                      ! 0284: 05010fff   r1 = (slot<<8) | 0x0FFF  -> board ID port
	inb rl0,@r1                       ! 0288: 3c18   read board ID  (empty slot -> NMI -> rr12 = next slot)
	cpb rl0,#0xfe                     ! 028a: 0a08fefe   ID == 0xFE (video) ?
	jr ne,L_02a0                      ! 028e: ee08   no -> next slot
	ldar rr10,L_029c                  ! 0290: 340a0008   rr10 = return (0x29c)
	ldl rr12,rr10                     ! 0294: 94ac   rr12 = return too (so an NMI mid-init also unwinds cleanly)
	.long_addr
	jp t,0xbc6                        ! 0296: 5e0880000bc6   init + self-test this video controller  (r1=port, r7=window)
L_029c:
	add r7,#0x2000                    ! 029c: 01072000   advance framebuffer window +0x2000 for the next video board
L_02a0:
	addb rh1,#0x10                    ! 02a0: 00011010   next slot: high byte += 0x10
	jr nc/uge,L_0280                  ! 02a4: efed   loop until it carries past 0xF0  (all 16 slots)

!------------------------------------------------------------------------------
! Initialise the UC DMA/interrupt controller (0xFF80..0xFF8F, in the MB15652
! gate array).  Writes ALL 16 registers (the data = leftover r0, a don't-care)
! and hand-shakes on the NVI the device raises: `ei nvi`, spin (`jr self`), and
! the NVI handler (0x00f2) resumes at the next rr12 target.  This is the device
! the FDU transfer later strobes via 0xFF84/0xFF8C; it does NOT load an address.
!------------------------------------------------------------------------------
	ldar rr12,L_02f0                  ! 02a6: 340c0046   rr12 = NVI resume target (next group)
	out #0xff80,r0                    ! 02aa: 3b06ff80   write all 16 controller regs 0xFF80..0xFF8F (data = don't-care r0)
	out #0xff89,r0                    ! 02ae: 3b06ff89
	out #0xff8a,r0                    ! 02b2: 3b06ff8a
	out #0xff8b,r0                    ! 02b6: 3b06ff8b
	out #0xff85,r0                    ! 02ba: 3b06ff85
	ei nvi                            ! 02be: 7c06   enable NVI...
	nop                               ! 02c0: 8d07
	out #0xff81,r0                    ! 02c2: 3b06ff81
	out #0xff86,r0                    ! 02c6: 3b06ff86
	out #0xff8d,r0                    ! 02ca: 3b06ff8d
	nop                               ! 02ce: 8d07
	out #0xff82,r0                    ! 02d0: 3b06ff82
	out #0xff87,r0                    ! 02d4: 3b06ff87
	out #0xff8e,r0                    ! 02d8: 3b06ff8e
	nop                               ! 02dc: 8d07
	out #0xff83,r0                    ! 02de: 3b06ff83
	out #0xff8f,r0                    ! 02e2: 3b06ff8f
	nop                               ! 02e6: 8d07
	ldar rr12,L_02f2                  ! 02e8: 340c0006   rr12 = next group
	out #0xff8b,r0                    ! 02ec: 3b06ff8b
L_02f0:
	jr t,L_02f0                       ! 02f0: e8ff   spin until the device raises NVI -> next group
L_02f2:
	ldar rr12,L_0302                  ! 02f2: 340c000c
	out #0xff8a,r0                    ! 02f6: 3b06ff8a
	out #0xff87,r0                    ! 02fa: 3b06ff87
	ei nvi                            ! 02fe: 7c06
L_0300:
	jr t,L_0300                       ! 0300: e8ff   spin for NVI
L_0302:
	ldar rr12,L_0312                  ! 0302: 340c000c
	out #0xff89,r0                    ! 0306: 3b06ff89
	out #0xff86,r0                    ! 030a: 3b06ff86
	ei nvi                            ! 030e: 7c06
L_0310:
	jr t,L_0310                       ! 0310: e8ff   spin for NVI
L_0312:
	ldar rr12,L_0322                  ! 0312: 340c000c
	out #0xff88,r0                    ! 0316: 3b06ff88
	out #0xff85,r0                    ! 031a: 3b06ff85
	ei nvi                            ! 031e: 7c06
L_0320:
	jr t,L_0320                       ! 0320: e8ff   spin for NVI
L_0322:
	out #0xff80,r0                    ! 0322: 3b06ff80   final re-write of 0xFF80..0xFF83
	out #0xff81,r0                    ! 0326: 3b06ff81
	out #0xff82,r0                    ! 032a: 3b06ff82
	out #0xff83,r0                    ! 032e: 3b06ff83
	ldar rr10,L_033e                  ! 0332: 340a0008
	ldb rl7,#0x2                      ! 0336: cf02
	.long_addr
	jp t,0xbaa                        ! 0338: 5e0880000baa
L_033e:
	ldar rr10,L_0348                  ! 033e: 340a0006
	.long_addr
	jp t,0xa94                        ! 0342: 5e0880000a94
L_0348:
	jr nc/uge,L_0352                  ! 0348: ef04
	ldk r7,#0x2                       ! 034a: bd72
	.long_addr
	jp t,0xb6                         ! 034c: 5e08800000b6
L_0352:
	ldar rr10,L_035c                  ! 0352: 340a0006
	.long_addr
	jp t,0xb0e                        ! 0356: 5e0880000b0e

!==============================================================================
! BBU (Battery Backup Unit) WARM-START CHECK
! If ff41 bit 0 says the BBU kept RAM alive and the marker "$BBU ON " is present
! at <<1>>0x03f8, restore the saved MMU descriptor from <<1>>0x0210 and resume at
! the saved entry point -- a warm boot.  Otherwise fall through to cold start.
!==============================================================================
L_035c:
	inb rl0,#0xff41                   ! 035c: 3a84ff41   read ff41 (BBU / NMI status)
	bit r0,#0x0                       ! 0360: a700   BBU-held-RAM bit 0 set?
	jr ne,L_03a4                      ! 0362: ee20   no -> cold start
	ldar rr12,L_03a4                  ! 0364: 340c003c   rr12 = &cold-start (if the compare below faults)
	ldar rr8,L_039c                   ! 0368: 34080030   rr8 = &"$BBU ON " marker
	.long_addr
	lda rr2,0x10003f8                 ! 036c: 7602810003f8   rr2 = <<1>>0x03f8 (marker in battery-backed RAM)
	ld r0,#0x8                        ! 0372: 21000008   8 bytes
	cpsirb @rr8,@rr2,r0,ne            ! 0376: ba26008e   RAM marker == "$BBU ON " ?
	jr eq,L_03a4                      ! 037a: e614   no -> cold start
	ldm r2,0x1000210,#0x4             ! 037c: 5c0102038100   warm start: load saved descriptor from <<1>>0x0210
	res r2,#0xf                       ! 0384: a32f
	soutb #0x100,rh2                  ! 0386: 3a270100   reprogram the MMU descriptor from saved state
	soutb #0xf00,rh4                  ! 038a: 3a470f00
	soutb #0xf00,rl4                  ! 038e: 3ac70f00
	soutb #0xf00,rh5                  ! 0392: 3a570f00
	soutb #0xf00,rl5                  ! 0396: 3ad70f00
	jp t,@rr2                         ! 039a: 1e28   resume at the saved entry point (warm boot)

! ---- 0x039c .. 0x03a4  (ascii) ----
	! "$BBU ON "
L_039c:
	.byte	0x24,0x42,0x42,0x55,0x20,0x4f,0x4e,0x20

! ---- 0x03a4 .. 0x06e6  (code) ----
L_03a4:
	.long_addr
!------------------------------------------------------------------------------
! Cold start: zero low RAM, then branch by the line-board flag (NSP).
!------------------------------------------------------------------------------
	lda rr2,0x10003ff                 ! 03a4: 7602810003ff   rr2 = <<1>>0x03ff
	sub r0,r0                         ! 03aa: 8300   clear value 0
L_03ac:
	ldb @rr2,rl0                      ! 03ac: 2e28   clear r3 bytes of low RAM
	djnz r3,L_03ac                    ! 03ae: f382
	ldctl r0,nspoff                   ! 03b0: 7d07   r0 = NSP (line-board flag set during the scan)
	orb rh0,rh0                       ! 03b2: 8400   line board present?
	.long_addr
	jp ne,0x4ca                       ! 03b4: 5e0e800004ca   yes -> 0x4ca (skip the RAM pattern test)

!==============================================================================
! MEMORY PATTERN TEST  ("test piastra di memoria")
! Marching test over all mapped RAM (rr6 = start .. rr4 = end): write 0x5555,
! verify + write its complement, then 0x3131, then 0xFFFF.  Any miscompare jumps
! to the fault handler (0x0430).  Loops: 0x3f2 fill, 0x418 verify-old/write-new,
! 0x400 verify/write-complement.
!==============================================================================
	ldl rr6,#0x2000000                ! 03ba: 140602000000   rr6 = <<2>>0x0000 : start of mapped RAM
	ld r8,#0x100                      ! 03c0: 21080100
	ldb rh0,rh4                       ! 03c4: a040
	ldb rl0,rh5                       ! 03c6: a058
	ld r9,r0                          ! 03c8: a109   r9 = end-bank marker
	sub r0,r0                         ! 03ca: 8300
	ldctl nspoff,r0                   ! 03cc: 7d0f   NSP = 0
L_03ce:
	ldar rr12,L_0430                  ! 03ce: 340c005e   rr12 = &fault handler (0x0430)
	ldl rr2,rr6                       ! 03d2: 9462   rr2 = start
	ldar rr10,L_03de                  ! 03d4: 340a0006   after fill -> next pattern (0x3de)
	ld r1,#0x5555                     ! 03d8: 21015555   pattern 1 = 0x5555
	jr t,L_03f2                       ! 03dc: e80a   -> fill loop
L_03de:
	ldar rr10,L_03e8                  ! 03de: 340a0006   after -> 0x3e8
	ld r1,#0x3131                     ! 03e2: 21013131   pattern 2 = 0x3131
	jr t,L_0418                       ! 03e6: e818   -> verify-old / write-new
L_03e8:
	ldar rr10,L_0494                  ! 03e8: 340a00a8   after -> 0x0494 (done)
	ld r1,#0xffff                     ! 03ec: 2101ffff   pattern 3 = 0xFFFF
	jr t,L_0418                       ! 03f0: e813   -> verify-old / write-new
L_03f2:
	cpl rr2,rr4                       ! 03f2: 9042   [fill] reached end (rr4)?
	jr eq,L_0400                      ! 03f4: e605   yes -> verify pass
	ld @rr2,r1                        ! 03f6: 2f21   write pattern
	inc r3,#0x2                       ! 03f8: a931   next word
	jr ne,L_03f2                      ! 03fa: eefb
	incb rh2,#0x1                     ! 03fc: a820   next segment
	jr t,L_03f2                       ! 03fe: e8f9
L_0400:
	ldl rr2,rr6                       ! 0400: 9462   [verify + write complement] rr2 = start
	ld r0,r1                          ! 0402: a110   r0 = pattern
	com r0                            ! 0404: 8d00   r0 = ~pattern
L_0406:
	cpl rr2,rr4                       ! 0406: 9042   reached end?
	jp eq,@rr10                       ! 0408: 1ea6   yes -> return (rr10 = next stage)
	cp r1,@rr2                        ! 040a: 0b21   read == pattern?
	jr ne,L_0430                      ! 040c: ee11   no -> memory fault (0x0430)
	ld @rr2,r0                        ! 040e: 2f20   write the complement
	inc r3,#0x2                       ! 0410: a931
	jr ne,L_0406                      ! 0412: eef9
	incb rh2,#0x1                     ! 0414: a820
	jr t,L_0406                       ! 0416: e8f7
L_0418:
	ldl rr2,rr6                       ! 0418: 9462   [verify old, write new] rr2 = start
L_041a:
	cpl rr2,rr4                       ! 041a: 9042   reached end?
	.long_addr
	jp eq,0x400                       ! 041c: 5e0680000400   yes -> verify this pattern (0x0400)
	cp r0,@rr2                        ! 0422: 0b20   read == expected previous value (r0)?
	jr ne,L_0430                      ! 0424: ee05   no -> memory fault (0x0430)
	ld @rr2,r1                        ! 0426: 2f21   write new pattern
	inc r3,#0x2                       ! 0428: a931
	jr ne,L_041a                      ! 042a: eef7
	incb rh2,#0x1                     ! 042c: a820
	jr t,L_041a                       ! 042e: e8f5
L_0430:
	.long_addr
!------------------------------------------------------------------------------
! Memory-test fault handler: computes the faulting address from the RAM bounds
! and (comparing against NSP / r11) decides the outcome. (details TBD)
!------------------------------------------------------------------------------
	ldar rr12,L_03ce                  ! 0430: 340cff9a
L_0434:
	ldb rl3,#0x0                      ! 0434: cb00
	ldl rr10,rr2                      ! 0436: 942a
	srl r10,#0x8                      ! 0438: b3a1fff8
	exb rh6,rl6                       ! 043c: ace6
	subl rr10,rr6                     ! 043e: 926a
	exb rh6,rl6                       ! 0440: ace6
	ldl rr0,rr4                       ! 0442: 9440
	srl r0,#0x8                       ! 0444: b301fff8
	exb rh2,rl2                       ! 0448: aca2
	subl rr0,rr2                      ! 044a: 9220
	exb rl2,rh2                       ! 044c: ac2a
	cpl rr10,rr0                      ! 044e: 900a
	ldctl r0,nspoff                   ! 0450: 7d07
	jr nc/uge,L_047a                  ! 0452: ef13
	srll rr10,#0x8                    ! 0454: b3a5fff8
	cp r0,r11                         ! 0458: 8bb0
	jr nc/uge,L_046a                  ! 045a: ef07
	ldctl nspoff,r11                  ! 045c: 7dbf
	ldb rh0,rh6                       ! 045e: a060
	ldb rl0,rh7                       ! 0460: a078
	ld r8,r0                          ! 0462: a108
	ldb rh0,rh2                       ! 0464: a020
	ldb rl0,rh3                       ! 0466: a038
	ld r9,r0                          ! 0468: a109
L_046a:
	and r3,#0xc000                    ! 046a: 0703c000
	add r3,#0x4000                    ! 046e: 01034000
	jr ne,L_0476                      ! 0472: ee01
	incb rh2,#0x1                     ! 0474: a820
L_0476:
	ldl rr6,rr2                       ! 0476: 9426
	jp t,@rr12                        ! 0478: 1ec8
L_047a:
	srll rr10,#0x8                    ! 047a: b3a5fff8
	cp r0,r11                         ! 047e: 8bb0
	jr nc/uge,L_0490                  ! 0480: ef07
	ldctl nspoff,r11                  ! 0482: 7dbf
	ldb rh0,rh6                       ! 0484: a060
	ldb rl0,rh7                       ! 0486: a078
	ld r8,r0                          ! 0488: a108
	ldb rh0,rh2                       ! 048a: a020
	ldb rl0,rh3                       ! 048c: a038
	ld r9,r0                          ! 048e: a109
L_0490:
	ldl rr4,rr2                       ! 0490: 9424
	jp t,@rr12                        ! 0492: 1ec8
L_0494:
	ldar rr12,L_049a                  ! 0494: 340c0002
	jr t,L_0434                       ! 0498: e8cd
L_049a:
	ld r1,r8                          ! 049a: a181
	ldar rr10,L_04a2                  ! 049c: 340a0002
	jr t,L_053a                       ! 04a0: e84c
L_04a2:
	ldb rh4,rh0                       ! 04a2: a004
	ldb rh5,rl0                       ! 04a4: a085
	ld r1,r9                          ! 04a6: a191
	sub r1,r8                         ! 04a8: 8381
	cp r1,#0x40                       ! 04aa: 0b010040
	ldk r7,#0x2                       ! 04ae: bd72
	.long_addr
	jp c/ult,0xb6                     ! 04b0: 5e07800000b6
	ldl rr6,rr4                       ! 04b6: 9446
	addb rh7,rl1                      ! 04b8: 8097
	adcb rh6,rh1                      ! 04ba: b416
	ldar rr10,L_04c6                  ! 04bc: 340a0006
	.long_addr
	jp t,0xb0e                        ! 04c0: 5e0880000b0e
L_04c6:
	sub r0,r0                         ! 04c6: 8300
	ldctl nspoff,r0                   ! 04c8: 7d0f

!------------------------------------------------------------------------------
! Publish the memory map: store the discovered RAM start/end into the system
! area in seg 1 (<<1>>0x0220..0x022a) for the OS/monitor to read.
!------------------------------------------------------------------------------
	ldb rl6,rh7                       ! 04ca: a07e   store RAM bounds into the system area (<<1>>0x0220..)
	inc r6,#0x4                       ! 04cc: a963
	.long_addr
	ld 0x1000226,r6                   ! 04ce: 6f0681000226   <<1>>0x0226 = RAM end + 4
	dec r6,#0x4                       ! 04d4: ab63
	.long_addr
	ld 0x100022a,r6                   ! 04d6: 6f068100022a   <<1>>0x022a = RAM end
	ld r1,#0x200                      ! 04dc: 21010200
	ldar rr10,L_04e6                  ! 04e0: 340a0002
	jr t,L_053a                       ! 04e4: e82a   read descriptor base (helper 0x53a)
L_04e6:
	.long_addr
	ld 0x1000224,r0                   ! 04e6: 6f0081000224   <<1>>0x0224 = base
	.long_addr
	ld 0x1000228,r0                   ! 04ec: 6f0081000228
	.long_addr
	lda rr10,0x4fe                    ! 04f2: 760a800004fe
	.long_addr
	jp t,0xa94                        ! 04f8: 5e0880000a94   re-run RAM sizing for fresh bounds
	ldb rl4,rh5                       ! 04fe: a05c
	ldb rl6,rh7                       ! 0500: a07e
	.long_addr
	ld 0x1000220,r4                   ! 0502: 6f0481000220   <<1>>0x0220 = RAM start
	.long_addr
	ld 0x1000222,r6                   ! 0508: 6f0681000222   <<1>>0x0222 = start base
	ldctl r0,nspoff                   ! 050e: 7d07
	.long_addr
	ldb 0x1000300,rl0                 ! 0510: 6e0881000300
	.long_addr
	lda rr4,0x10001c0                 ! 0516: 7604810001c0
	.long_addr
	ldar rr2,L_00b4                   ! 051c: 3402fb94
	ld r1,#0x10                       ! 0520: 21010010
L_0524:
	ldl @rr4,rr2                      ! 0524: 1d42
	inc r5,#0x4                       ! 0526: a953
	djnz r1,L_0524                    ! 0528: f183
	.long_addr
	lda rr14,0x10001c0                ! 052a: 760e810001c0
	ldctl nspseg,r14                  ! 0530: 7dee
	ldctl nspoff,r15                  ! 0532: 7dff
	.long_addr
	jp t,0x552                        ! 0534: 5e0880000552

!------------------------------------------------------------------------------
! Helper: read back MMU descriptor rh1's base bytes (SAR=rh1, DSC=0) and return
! their sum in r0 (a segment's physical base).
!------------------------------------------------------------------------------
L_053a:
	soutb #0x100,rh1                  ! 053a: 3a170100   MMU SAR = rh1 (segment)
	ldb rl0,#0x0                      ! 053e: c800
	soutb #0x2000,rl0                 ! 0540: 3a872000   MMU DSC = 0
	sinb rh0,#0xf00                   ! 0544: 3a050f00   read descriptor base-high
	sinb rl0,#0xf00                   ! 0548: 3a850f00   read descriptor base-low
	ldb rh1,#0x0                      ! 054c: c100
	add r0,r1                         ! 054e: 8110   r0 = base-high + base-low
	jp t,@rr10                        ! 0550: 1ea8   return
	.long_addr
	ldl rr2,0x1000224                 ! 0552: 540281000224
	sub r3,r2                         ! 0558: 8323
	srl r3,#0x8                       ! 055a: b331fff8
	ld r2,r3                          ! 055e: a132
	add r2,r3                         ! 0560: 8132
	add r2,r3                         ! 0562: 8132
	cp r2,#0xff                       ! 0564: 0b0200ff
	jr c/ult,L_056c                   ! 0568: e701
	ldb rl2,#0xff                     ! 056a: caff
L_056c:
	.long_addr
	ldb 0x10002fb,rl2                 ! 056c: 6e0a810002fb
	ldk r1,#0x2                       ! 0572: bd12
	outb #0xff01,rl1                  ! 0574: 3a96ff01
	add r1,r1                         ! 0578: 8111
	.long_addr
	lda rr2,0xe2e                     ! 057a: 760280000e2e
	.long_addr
	ldl 0x10001c0(r1),rr2             ! 0580: 5d12810001c0
	ld r7,#0x4444                     ! 0586: 21074444
	.long_addr
	call 0xd10                        ! 058a: 5f0080000d10

!==============================================================================
! BUILD CONFIG TABLE  ("ricerca governo di caricamento" — enumerate the bus)
! Scan all 16 slots; read each board's type-ID (nome logico) at register 0xFF;
! store the type (XX) at <<1>>0x0230 + slot*4 and its diagnostic response (YYYY)
! at +2.  An empty slot faults (NMI) -> 0xFFFF/0xFFFF.  This is the data behind
! the "NLS 30000 SYSTEM ENVIRONMENT" screen (Collaudi 1-10).
!==============================================================================
	ldk r7,#0x0                       ! 0590: bd70   r7 = 0
	ldb rh1,#0x0                      ! 0592: c100   rh1 = 0 -> slot high nibble 0
L_0594:
	ldar rr12,L_05c6                  ! 0594: 340c002e   rr12 = &absent-handler (NMI if slot empty)
	ld r2,r1                          ! 0598: a112   r2 = slot
	srl r2,#0xa                       ! 059a: b321fff6
	and r2,#0x3c                      ! 059e: 0702003c   table index = slot * 4
	ldb rl1,#0xff                     ! 05a2: c9ff   rl1 = 0xFF -> the slot's type-ID register
	inb rl0,@r1                       ! 05a4: 3c18   read board type-ID (absent -> NMI -> 0x5c6)
	cpb rh1,#0xe0                     ! 05a6: 0a01e0e0   slot 0xE0 (FDU/MFDU) special-case?
	jr ne,L_05ae                      ! 05aa: ee01
	ldk r0,#0x0                       ! 05ac: bd00   response = 0
L_05ae:
	.long_addr
	ldb 0x1000230(r2),rl0             ! 05ae: 6e2881000230   store type (XX) at <<1>>0x0230 + slot*4
	cpb rl0,#0xfe                     ! 05b4: 0a08fefe   video board?
	ldk r0,#0x0                       ! 05b8: bd00
	jr ne,L_05be                      ! 05ba: ee01
	calr L_0996                       ! 05bc: de14   yes -> fetch its diag response (0x0996)
L_05be:
	.long_addr
	ld 0x1000232(r2),r0               ! 05be: 6f2081000232   store response (YYYY) at +2
	jr t,L_05d8                       ! 05c4: e809
L_05c6:
	.long_addr
	ld 0x1000230(r2),#0xffff          ! 05c6: 4d2581000230   [absent slot] type = 0xFFFF
	inc r2,#0x2                       ! 05ce: a921
	.long_addr
	ld 0x1000230(r2),#0xffff          ! 05d0: 4d2581000230   response = 0xFFFF
L_05d8:
	addb rh1,#0x10                    ! 05d8: 00011010   next slot (high nibble += 1)
	jr nc/uge,L_0594                  ! 05dc: efdb   loop over all 16 slots
	lda rr2,0x1000000                 ! 05de: 76020100
	ldctl r4,psapseg                  ! 05e2: 7d44
	ldctl r5,psapoff                  ! 05e4: 7d55
	ldctl psapseg,r2                  ! 05e6: 7d2c
	ldctl psapoff,r3                  ! 05e8: 7d3d
	ld r0,#0x1e                       ! 05ea: 2100001e
	ldir @rr2,@rr4,r0                 ! 05ee: bb410020
	ldb rl3,#0xa                      ! 05f2: cb0a
	ldk r4,#0x7                       ! 05f4: bd47
L_05f6:
	ld @rr2,#0xc000                   ! 05f6: 0d25c000
	inc r3,#0x8                       ! 05fa: a937
	djnz r4,L_05f6                    ! 05fc: f484
	ldar rr12,L_0622                  ! 05fe: 340c0020
	ldl rr2,0x3e000004                ! 0602: 54023e04
	res r2,#0xf                       ! 0606: a32f
	soutb #0x100,rh2                  ! 0608: 3a270100
	ld r0,#0xf0ff                     ! 060c: 2100f0ff
	soutb #0xf00,rh0                  ! 0610: 3a070f00
	soutb #0xf00,rl2                  ! 0614: 3aa70f00
	soutb #0xf00,rl0                  ! 0618: 3a870f00
	soutb #0xf00,rl2                  ! 061c: 3aa70f00
	call @rr2                         ! 0620: 1f20
L_0622:
	.long_addr
	ld r2,0x100022a                   ! 0622: 61028100022a
	dec r2,#0x10                      ! 0628: ab2f
	.long_addr
	ld 0x100022a,r2                   ! 062a: 6f028100022a
	ld r0,#0x3c                       ! 0630: 2100003c
	soutb #0x100,rl0                  ! 0634: 3a870100
	soutb #0x2000,rh0                 ! 0638: 3a072000
	soutb #0xf00,rh2                  ! 063c: 3a270f00
	soutb #0xf00,rl2                  ! 0640: 3aa70f00
	ldb rl0,#0xf                      ! 0644: c80f
	soutb #0xf00,rl0                  ! 0646: 3a870f00
	soutb #0xf00,rh0                  ! 064a: 3a070f00
	ei vi,nvi                         ! 064e: 7c04
	outb #0xff8c,rl0                  ! 0650: 3a86ff8c
	.long_addr
	ldb 0x10002fc,#0x7                ! 0654: 4c05810002fc

!==============================================================================
! IPL DEVICE SEARCH & LOAD  (ricerca + test governo di caricamento, Collaudi 1-9)
! Pick a boot-device priority list by the ISL switch (0xFF41 bit 1): set -> HDU
! first (0x6e6), clear -> FDU first (0x6e8).  For each device type in the list,
! scan the config table (<<1>>0x0230) for a matching board; when found, call its
! handler (table 0x6ee) to load the boot program.  Retry until <<1>>0x0308=0x5555.
!==============================================================================
L_065c:
	ldar rr8,L_06e6                   ! 065c: 34080086   rr8 = &priority list (HDU-first, 0x6e6)
	inb rl0,#0xff41                   ! 0660: 3a84ff41   read ff41 (ISL switch)
	bitb rl0,#0x1                     ! 0664: a681   ISL bit 1 set (HDU first)?
	jr ne,L_066c                      ! 0666: ee02
	ldar rr8,L_06e8                   ! 0668: 3408007c   clear -> FDU-first list (0x6e8)
L_066c:
	sub r1,r1                         ! 066c: 8311   slot index = 0
L_066e:
	.long_addr
	ldb rl0,0x1000230(r1)             ! 066e: 601881000230   read config-table[slot] type
	cpb rl0,@rr8                      ! 0674: 0a88   == the wanted device type (@rr8)?
	jr ne,L_06c4                      ! 0676: ee26   no -> next slot
	pushl @rr14,rr8                   ! 0678: 91e8   found this device: save state
	push @rr14,r1                     ! 067a: 93e1
	sll r1,#0x2                       ! 067c: b3110002
	.long_addr
	ldb 0x1000302,rl1                 ! 0680: 6e0981000302   record found slot
	ldar rr2,L_06e6                   ! 0686: 3402005c
	ld r2,r9                          ! 068a: a192
	sub r2,r3                         ! 068c: 8332
	sll r2,#0x2                       ! 068e: b3210002   device index in the list
	ldar rr4,L_06ee                   ! 0692: 34040058   rr4 = &handler table (0x6ee)
	ldl rr6,rr4(r2)                   ! 0696: 75460200   rr6 = {param, handler} for this device type
	test r7                           ! 069a: 8d74
	jr eq,L_06b8                      ! 069c: e60d
	inc r7,#0x1                       ! 069e: a970
	jr eq,L_06b8                      ! 06a0: e60b
	add r5,r6                         ! 06a2: 8165
	.long_addr
	tsetb 0x10002fd                   ! 06a4: 4c06810002fd
	jr mi,L_06b6                      ! 06aa: e505
	ld r7,#0x5555                     ! 06ac: 21075555
	.long_addr
	call 0xd10                        ! 06b0: 5f0080000d10
L_06b6:
	call @rr4                         ! 06b6: 1f40   call the device's boot handler
L_06b8:
	.long_addr
	testb 0x10002fc                   ! 06b8: 4c04810002fc   wait for the load result (<<1>>0x02fc)
L_06be:
	jr mi,L_06be                      ! 06be: e5ff
	pop r1,@rr14                      ! 06c0: 97e1
	popl rr8,@rr14                    ! 06c2: 95e8
L_06c4:
	inc r1,#0x4                       ! 06c4: a913   next slot (+4)
	bit r1,#0x6                       ! 06c6: a716   all 16 slots done?
	jr eq,L_066e                      ! 06c8: e6d2
	inc r9,#0x1                       ! 06ca: a990   next device type in the priority list
	cp r9,#0x6ec                      ! 06cc: 0b0906ec   end of list?
	jr ne,L_066c                      ! 06d0: eecd
	.long_addr
	cp 0x1000308,#0x5555              ! 06d2: 4d0181000308   boot succeeded? (<<1>>0x0308 == 0x5555)
	jr ne,L_065c                      ! 06da: eec0   no -> retry the whole search
	ldk r7,#0x8                       ! 06dc: bd78   show 'waiting for IPL'
	.long_addr
	call 0xd10                        ! 06de: 5f0080000d10
	jr t,L_065c                       ! 06e4: e8bb   retry

! ---- 0x06e6 .. 0x071c  (word) ----
! IPL device-type priority lists (nome logico bytes).  The ISL switch (ff41
! bit 1) picks the start: set -> 0x6e6 (E4=HDU first), clear -> 0x6e8 (E1=FDU
! first).  E4=HDU  EF=GIPO/IEEE-488 (DCU)  E1=FDU  E0=MFDU  E6=STC.  00 = end.
L_06e6:
	.word	0xe4ef
L_06e8:
	.word	0xe1e0
	.word	0xe6ef
	.word	0x0000
! Per-device handler table: {param, handler-offset} x N, indexed by list
! position.  handler 0x0eae = FDU/MFDU (floppy) loader; 0x1a5e = GIPO/HDU;
! 0x1e2c = STC; 0xffff = HDU-direct (no handler -> via GIPO).
L_06ee:
	.word	0x002e
	.word	0xffff
	.word	0x0044
	.word	0x1a5e
	.word	0x0170
	.word	0x0eae
	.word	0x0170
	.word	0x0eae
	.word	0x00be
	.word	0x1e2c
	.word	0x004a
	.word	0x1a5e
L_0706:
	.word	0x0504
	.word	0x0302
	.word	0x0001
	.word	0x0000
	.word	0x0000
L_0710:
	.word	0xbc00
	.word	0x0000
	.word	0x1000
	.word	0x0000
	.word	0x0000
	.word	0xa800

! ---- 0x071c .. 0x0c44  (code) ----
	.long_addr
	ldar rr8,L_0706                   ! 071c: 3408ffe6
	ldar rr4,L_0a60                   ! 0720: 3404033c
	.long_addr
	lda rr10,0x7f00ffff               ! 0724: 760aff00ffff
	.long_addr
	lda rr12,0x7f00ffff               ! 072a: 760cff00ffff
	jr t,L_074c                       ! 0730: e80d
	.long_addr
	ldar rr8,L_0706                   ! 0732: 3408ffd0
	jr t,L_073c                       ! 0736: e802
	.word	0x3408		! 0738: ldar rr8,0x70b
	.word	0xffcf		! 073a: ldar rr8,0x70b
L_073c:
	ldar rr4,L_0a68                   ! 073c: 34040328
	.long_addr
	lda rr10,0x1a5e                   ! 0740: 760a80001a5e
	.long_addr
	lda rr12,0x1bfa                   ! 0746: 760c80001bfa
L_074c:
	call @rr4                         ! 074c: 1f40
	or r7,r7                          ! 074e: 8577
	.long_addr
	jp ne,0xdc6                       ! 0750: 5e0e80000dc6
L_0756:
	sub r1,r1                         ! 0756: 8311
L_0758:
	.long_addr
	ldb rl0,0x1000270(r1)             ! 0758: 601881000270
	cpb rl0,@rr8                      ! 075e: 0a88
	jr ne,L_079e                      ! 0760: ee1e
	pushl @rr14,rr8                   ! 0762: 91e8
	push @rr14,r1                     ! 0764: 93e1
	inc r1,#0x1                       ! 0766: a910
	.long_addr
	ldb 0x1000303,rl1                 ! 0768: 6e0981000303
	calr L_098c                       ! 076e: def2
	.long_addr
	ldar rr2,L_0710                   ! 0770: 3402ff9c
	call @rr10                        ! 0774: 1fa0
	or r7,r7                          ! 0776: 8577
	jr ne,L_0794                      ! 0778: ee0d
	call @rr12                        ! 077a: 1fc0
	or r7,r7                          ! 077c: 8577
	jr ne,L_0794                      ! 077e: ee0a
	.long_addr
	ld 0x100030c,r4                   ! 0780: 6f048100030c
	.long_addr
	ldb 0x100030e,rl5                 ! 0786: 6e0d8100030e
	.long_addr
	ldb 0x1000306,rl6                 ! 078c: 6e0e81000306
	calr L_08fe                       ! 0792: df4b
L_0794:
	.long_addr
	call 0xdc6                        ! 0794: 5f0080000dc6
	pop r1,@rr14                      ! 079a: 97e1
	popl rr8,@rr14                    ! 079c: 95e8
L_079e:
	inc r1,#0x1                       ! 079e: a910
	bit r1,#0x3                       ! 07a0: a713
	jr eq,L_0758                      ! 07a2: e6da
	inc r9,#0x1                       ! 07a4: a990
	testb @rr8                        ! 07a6: 0c84
	jr ne,L_0756                      ! 07a8: eed6
	ret t                             ! 07aa: 9e08
	.long_addr
	ldb rl0,0x1000302                 ! 07ac: 600881000302
	.long_addr
	ldb 0x1000304,rl0                 ! 07b2: 6e0881000304
	.long_addr
	ldb 0x1000303,#0x1                ! 07b8: 4c0581000303
	ldk r7,#0x6                       ! 07c0: bd76
	.long_addr
	call 0x1d3a                       ! 07c2: 5f0080001d3a
	or r7,r7                          ! 07c8: 8577
	.long_addr
	jp ne,0xdc6                       ! 07ca: 5e0e80000dc6
	calr L_098c                       ! 07d0: df23
	.long_addr
	decb 0x10002fc,#0x2               ! 07d2: 6a01810002fc
	ldar rr2,L_0852                   ! 07d8: 34020076
	.long_addr
	call 0x1e2c                       ! 07dc: 5f0080001e2c
	or r7,r7                          ! 07e2: 8577
	.long_addr
	jp ne,0xdc6                       ! 07e4: 5e0e80000dc6
	ldb rh0,#0xe4                     ! 07ea: c0e4
	calr L_082c                       ! 07ec: dfe1
	jr ne,L_0802                      ! 07ee: ee09
	.long_addr
	lda rr4,0x7f00ffff                ! 07f0: 7604ff00ffff
	test r5                           ! 07f6: 8d54
	jr eq,L_0802                      ! 07f8: e604
	inc r5,#0x1                       ! 07fa: a950
	jr eq,L_0802                      ! 07fc: e602
	calr L_0a60                       ! 07fe: ded0
	jr t,L_0818                       ! 0800: e80b
L_0802:
	ldb rh0,#0xef                     ! 0802: c0ef
	calr L_082c                       ! 0804: dfed
	jr ne,L_0818                      ! 0806: ee08
	.long_addr
	lda rr4,0x1a5e                    ! 0808: 760480001a5e
	test r5                           ! 080e: 8d54
	jr eq,L_0818                      ! 0810: e603
	inc r5,#0x1                       ! 0812: a950
	jr eq,L_0818                      ! 0814: e601
	calr L_0a68                       ! 0816: ded8
L_0818:
	calr L_08fe                       ! 0818: df8e
	.long_addr
	ldb rl0,0x1000304                 ! 081a: 600881000304
	.long_addr
	ldb 0x1000302,rl0                 ! 0820: 6e0881000302
	.long_addr
	jp t,0xdc6                        ! 0826: 5e0880000dc6
L_082c:
	sub r1,r1                         ! 082c: 8311
L_082e:
	.long_addr
	ldb rl0,0x1000230(r1)             ! 082e: 601881000230
	cpb rl0,rh0                       ! 0834: 8a08
	jr ne,L_084a                      ! 0836: ee09
	sll r1,#0x2                       ! 0838: b3110002
	orb rl1,#0xf                      ! 083c: 04090f0f
	.long_addr
	ldb 0x1000302,rl1                 ! 0840: 6e0981000302
	sub r0,r0                         ! 0846: 8300
	ret t                             ! 0848: 9e08
L_084a:
	inc r1,#0x4                       ! 084a: a913
	bit r1,#0x6                       ! 084c: a716
	jr eq,L_082e                      ! 084e: e6ef
	ret t                             ! 0850: 9e08
L_0852:
	rrdb rh0,rh0                      ! 0852: bc00
	.word	0x0000		! 0854: addb rh0,#0x0
	.word	0x1000		! 0856: addb rh0,#0x0
	.word	0x0000		! 0858: addb rh0,#0x1
	.word	0x0001		! 085a: addb rh0,#0x1
	.word	0x0111		! 085c: add r1,@rr1
	.long_addr

!==============================================================================
! FDU IPL HANDLER  (entry = handler-table base 0x6ee + param 0x170)
! Reads the boot track to segment 60, validates the "SYS0" magic, then jumps to
! the entry point stored in the block header (longword at <<60>>0x0004).
!==============================================================================
	lda rr4,0x14ae                    ! 085e: 7604800014ae   FDU IPL handler entry (dispatched from the boot search)
	cp r4,r5                          ! 0864: 8b54
	ret eq                            ! 0866: 9e06
	calr L_09de                       ! 0868: df46   probe/select the drive (0x09de)
	or r7,r7                          ! 086a: 8577
	jr eq,L_0880                      ! 086c: e609
L_086e:
	.long_addr
	ldb rh1,0x1000302                 ! 086e: 600181000302   rh1 = FDU slot
	.long_addr
	call 0xeae                        ! 0874: 5f0080000eae   reset the governo (0x0eae)
	.long_addr
	jp t,0xdc6                        ! 087a: 5e0880000dc6
L_0880:
	sub r1,r1                         ! 0880: 8311
L_0882:
	inc r1,#0x1                       ! 0882: a910
	and r1,#0x3                       ! 0884: 07010003
	.long_addr
	ldb rl0,0x100034d                 ! 0888: 60088100034d
	bit r0,r1                         ! 088e: 27010000
	jr eq,L_08f8                      ! 0892: e632
	push @rr14,r1                     ! 0894: 93e1
	.long_addr
	ldb 0x1000303,rl1                 ! 0896: 6e0981000303
	calr L_098c                       ! 089c: df89
L_089e:
	lda rr2,0x3c000000                ! 089e: 76023c00   read target = <<60>>0x0000 (segment 60 = boot buffer)
	.long_addr
	ldb rl0,0x1000303                 ! 08a2: 600881000303
	.long_addr
	call 0x14ae                       ! 08a8: 5f00800014ae   read the boot track into <<60>> (0x14ae)
	.long_addr
	ldb rh1,0x1000302                 ! 08ae: 600181000302
	ldb rl1,#0xed                     ! 08b4: c9ed   reg 0xed = status
	inb rl0,@r1                       ! 08b6: 3c18   read
	bitb rl0,#0x3                     ! 08b8: a683   complete/error?
	jr ne,L_08cc                      ! 08ba: ee08
	ld r0,r7                          ! 08bc: a170
	and r0,#0x2bb                     ! 08be: 070002bb
	jr ne,L_08cc                      ! 08c2: ee04
	.long_addr
	call 0xd10                        ! 08c4: 5f0080000d10
	jr t,L_089e                       ! 08ca: e8e9
L_08cc:
	sub r0,r0                         ! 08cc: 8300
	set r0,#0x9                       ! 08ce: a509
	cp r0,r7                          ! 08d0: 8b70
	jr eq,L_08f6                      ! 08d2: e611
	.long_addr
	decb 0x10002fc,#0x1               ! 08d4: 6a00810002fc
	res r7,#0x6                       ! 08da: a376
	or r7,r7                          ! 08dc: 8577
	jr ne,L_08e2                      ! 08de: ee01
	calr L_08fe                       ! 08e0: dff2
L_08e2:
	bit r7,#0x8                       ! 08e2: a778
	jr eq,L_08ea                      ! 08e4: e602
	res r7,#0x8                       ! 08e6: a378
	set r7,#0x3                       ! 08e8: a573
L_08ea:
	res r7,#0x9                       ! 08ea: a379
	or r7,r7                          ! 08ec: 8577
	jr eq,L_08f6                      ! 08ee: e603
	.long_addr
	call 0xdc6                        ! 08f0: 5f0080000dc6
L_08f6:
	pop r1,@rr14                      ! 08f6: 97e1
L_08f8:
	or r1,r1                          ! 08f8: 8511
	jr ne,L_0882                      ! 08fa: eec3
	jr t,L_086e                       ! 08fc: e8b8

!------------------------------------------------------------------------------
! Validate + launch the loaded block: require magic "SYS0" at <<60>>0x0000, take
! the entry point from <<60>>0x0004, set up the MMU/PSA, and jp to it.
!------------------------------------------------------------------------------
L_08fe:
	lda rr2,0x3c000000                ! 08fe: 76023c00   [validate the loaded block]
	clr r4                            ! 0902: 8d48
L_0904:
	cpb rl3,@rr2                      ! 0904: 0a2b   scan segment 60
	jr ne,L_090a                      ! 0906: ee01
	inc r4,#0x1                       ! 0908: a940
L_090a:
	dbjnz rl3,L_0904                  ! 090a: fb04
	cp r4,#0x78                       ! 090c: 0b040078
	jr c/ult,L_0916                   ! 0910: e702
	ldk r7,#0x1                       ! 0912: bd71
	ret t                             ! 0914: 9e08
L_0916:
	clr r3                            ! 0916: 8d38
	ldl rr0,@rr2                      ! 0918: 1420   rr0 = first 4 bytes of the block
	cpl rr0,#0x53595330               ! 091a: 100053595330   magic == "SYS0" (0x53595330) ?
	jr eq,L_0926                      ! 0920: e602
	ldk r7,#0x8                       ! 0922: bd78   no -> not bootable (r7=8)
	ret t                             ! 0924: 9e08
L_0926:
	sub r7,r7                         ! 0926: 8377
	.long_addr
	call 0xd10                        ! 0928: 5f0080000d10
	ldctl r6,psapseg                  ! 092e: 7d64   save old PSAP
	ldctl r7,psapoff                  ! 0930: 7d75
	.long_addr
	lda rr8,0x10001c0                 ! 0932: 7608810001c0
	ldb rl7,#0x3c                     ! 0938: cf3c
	ld r0,#0x20                       ! 093a: 21000020
	ldir @rr6,@rr8,r0                 ! 093e: bb810060   copy the PSA vectors into place
	ldl rr2,rr2(#0x4)                 ! 0942: 35220004   ENTRY POINT = longword at <<60>>0x0004 (block header)
	ldl rr4,rr2                       ! 0946: 9424   rr4 = entry point
	ld r0,#0x3c                       ! 0948: 2100003c   reprogram MMU descriptor 60 -> the loaded block
	soutb #0x100,rl0                  ! 094c: 3a870100
	soutb #0x2000,rh0                 ! 0950: 3a072000
	ldb rl0,#0xff                     ! 0954: c8ff
	soutb #0xf00,rl0                  ! 0956: 3a870f00
	soutb #0xf00,rl0                  ! 095a: 3a870f00
	soutb #0xf00,rl0                  ! 095e: 3a870f00
	soutb #0xf00,rl0                  ! 0962: 3a870f00
	res r2,#0xf                       ! 0966: a32f
	soutb #0x100,rh2                  ! 0968: 3a270100
	ldk r0,#0xf                       ! 096c: bd0f
	.long_addr
	ld r1,0x100022a                   ! 096e: 61018100022a
	soutb #0xf00,rh1                  ! 0974: 3a170f00
	soutb #0xf00,rl1                  ! 0978: 3a970f00
	soutb #0xf00,rl0                  ! 097c: 3a870f00
	soutb #0xf00,rh0                  ! 0980: 3a070f00
	.long_addr
	lda rr14,0x10001c0                ! 0984: 760e810001c0   stack = <<1>>0x01c0
	jp t,@rr4                         ! 098a: 1e48   JUMP to the loaded boot program (rr4 = its entry point)
L_098c:
	lda rr2,0x3c000000                ! 098c: 76023c00
L_0990:
	ldb @rr2,rl3                      ! 0990: 2e2b
	dbjnz rl3,L_0990                  ! 0992: fb02
	ret t                             ! 0994: 9e08
L_0996:
	pushl @rr14,rr2                   ! 0996: 91e2
	pushl @rr14,rr4                   ! 0998: 91e4
	pushl @rr14,rr10                  ! 099a: 91ea
	pushl @rr14,rr12                  ! 099c: 91ec
	ldar rr12,L_09cc                  ! 099e: 340c002a
	ldar rr10,L_09ac                  ! 09a2: 340a0006
	.long_addr
	jp t,0xbc6                        ! 09a6: 5e0880000bc6
L_09ac:
	jr ne,L_09cc                      ! 09ac: ee0f
	.long_addr
	testb 0x1000357                   ! 09ae: 4c0481000357
	jr ne,L_09c8                      ! 09b4: ee09
	.long_addr
	ldb 0x1000355,rh1                 ! 09b6: 6e0181000355
	.long_addr
	ldb 0x1000357,rl0                 ! 09bc: 6e0881000357
	.long_addr
	ld 0x100035a,r7                   ! 09c2: 6f078100035a
L_09c8:
	sub r0,r0                         ! 09c8: 8300
	jr t,L_09d0                       ! 09ca: e802
L_09cc:
	tset r0                           ! 09cc: 8d06
	resflg z                          ! 09ce: 8d43
L_09d0:
	add r7,#0x2000                    ! 09d0: 01072000
	popl rr12,@rr14                   ! 09d4: 95ec
	popl rr10,@rr14                   ! 09d6: 95ea
	popl rr4,@rr14                    ! 09d8: 95e4
	popl rr2,@rr14                    ! 09da: 95e2
	ret t                             ! 09dc: 9e08
L_09de:
	.long_addr
	clr 0x100034a                     ! 09de: 4d088100034a
	.long_addr
	ldb rh1,0x1000302                 ! 09e4: 600181000302
	.long_addr
	call 0xeae                        ! 09ea: 5f0080000eae
	ldk r2,#0x4                       ! 09f0: bd24
	ldb rl1,#0xef                     ! 09f2: c9ef
	outb @r1,rl2                      ! 09f4: 3e1a
	.long_addr
	lda rr4,0x12ec                    ! 09f6: 7604800012ec
	add r2,r2                         ! 09fc: 8122
	.long_addr
	ldl 0x10001c0(r2),rr4             ! 09fe: 5d24810001c0
	ldb rl1,#0x9f                     ! 0a04: c99f
	ldb rl0,#0x3e                     ! 0a06: c83e
	outb @r1,rl0                      ! 0a08: 3e18
	ldb rl0,#0x50                     ! 0a0a: c850
	outb @r1,rl0                      ! 0a0c: 3e18
	ldb rl0,#0x90                     ! 0a0e: c890
	outb @r1,rl0                      ! 0a10: 3e18
	ldb rl1,#0x99                     ! 0a12: c999
	ldb rl0,#0x10                     ! 0a14: c810
	outb @r1,rl0                      ! 0a16: 3e18
	ldb rl0,#0x27                     ! 0a18: c827
	outb @r1,rl0                      ! 0a1a: 3e18
	ldb rl1,#0xff                     ! 0a1c: c9ff
	outb @r1,rl1                      ! 0a1e: 3e19
	.long_addr
	lda rr8,0x13c2                    ! 0a20: 7608800013c2
	.long_addr
	ld 0x1000350,r9                   ! 0a26: 6f0981000350
	.long_addr
	ld 0x1000352,r9                   ! 0a2c: 6f0981000352
	.long_addr
	ldb 0x1000354,#0x1                ! 0a32: 4c0581000354
	.long_addr
	call 0x12ca                       ! 0a3a: 5f00800012ca
	.long_addr
	ld r7,0x100034a                   ! 0a40: 61078100034a
	or r7,r7                          ! 0a46: 8577
	ret ne                            ! 0a48: 9e0e
	.long_addr
	lda rr8,0x12fe                    ! 0a4a: 7608800012fe
	.long_addr
	ld 0x1000350,r9                   ! 0a50: 6f0981000350
	.long_addr
	call 0xec0                        ! 0a56: 5f0080000ec0
	sub r7,r7                         ! 0a5c: 8377
	ret t                             ! 0a5e: 9e08
L_0a60:
	ldk r7,#0x8                       ! 0a60: bd78
	.long_addr
	jp t,0x7f00ffff                   ! 0a62: 5e08ff00ffff
L_0a68:
	ldk r7,#0x8                       ! 0a68: bd78
	.long_addr
	jp t,0x17f0                       ! 0a6a: 5e08800017f0
	push @rr14,r0                     ! 0a70: 93e0
	res r2,#0xf                       ! 0a72: a32f
	soutb #0x100,rh2                  ! 0a74: 3a270100
	sub r2,r2                         ! 0a78: 8322
	soutb #0x2000,rl2                 ! 0a7a: 3aa72000
	sinb rh0,#0x800                   ! 0a7e: 3a050800
	sinb rl0,#0x800                   ! 0a82: 3a850800
	ldb rl2,rh3                       ! 0a86: a03a
	add r2,r0                         ! 0a88: 8102
	ldb rh3,rl2                       ! 0a8a: a0a3
	srl r2,#0x8                       ! 0a8c: b321fff8
	pop r0,@rr14                      ! 0a90: 97e0
	ret t                             ! 0a92: 9e08

!==============================================================================
! RAM SIZING  ("ricerca allocazione fisica RAM", Collaudi 1-2)
! out: carry clear + contiguous-RAM extent, or carry set = fault (code 2).
! Walks physical memory in 16 KB steps by repeatedly remapping MMU descriptor
! 60 (segment 60 = scratch "probe window") to each 64 KB bank and reading it.
! Absent RAM has no READY -> NMI -> the NMI handler (0x00ce) resumes here at
! rr12 (checkpoints 0xaa8 = keep scanning, 0xaea = record end).  Records the
! contiguous start (r4:r5) and end (r6:r7); requires extent >= 16 KB.
!==============================================================================
	lda rr14,0xfe                     ! 0a94: 760e00fe   reset SP
	ld r1,#0x100                      ! 0a98: 21010100   r1 = 0x0100 -> rh1 = physical bank #1 (descriptor base-high)
L_0a9c:
	ldar rr12,L_0aa8                  ! 0a9c: 340c0008   rr12 = &0xaa8  <- NMI resume = 'skip this window' checkpoint
	.long_addr
	lda rr2,0x3c00c000                ! 0aa0: 7602bc00c000   rr2 = <<60>>0xc000 : segment 60 is the RAM-probe scratch window
	ldb rh0,#0x0                      ! 0aa6: c000   rh0 = 0  -> 'RAM start not found yet'
L_0aa8:
	add r3,#0x4000                    ! 0aa8: 01034000   [probe loop] offset += 0x4000 (16 KB step)
	jr nc/uge,L_0ad8                  ! 0aac: ef15   no wrap -> probe within the current bank
	incb rh1,#0x1                     ! 0aae: a810   bank exhausted: rh1++ (next 64 KB physical bank)
	cpb rh1,#0xf0                     ! 0ab0: 0a01f0f0   reached bank 0xF0 (top of scanned space)?
	jr ne,L_0abc                      ! 0ab4: ee03   no -> remap descriptor 60 to this bank
	orb rh0,rh0                       ! 0ab6: 8400   any RAM found so far?
	jr ne,L_0aea                      ! 0ab8: ee18   yes -> go record the end
	jr t,L_0b0a                       ! 0aba: e827   no RAM at all -> error
L_0abc:
	ldb rl0,#0x3c                     ! 0abc: c83c   SAR = 0x3C = descriptor 60
	soutb #0x100,rl0                  ! 0abe: 3a870100   MMU SAR = 60
	soutb #0x2000,rl1                 ! 0ac2: 3a972000   MMU DSC = 0 (start at base-high byte)
	soutb #0xf00,rh1                  ! 0ac6: 3a170f00   descriptor base-high = rh1 (physical bank)
	soutb #0xf00,rl1                  ! 0aca: 3a970f00   descriptor base-low = 0
	ldb rl0,#0xff                     ! 0ace: c8ff
	soutb #0xf00,rl0                  ! 0ad0: 3a870f00   descriptor limit = 0xFF (64 KB)
	soutb #0xf00,rl1                  ! 0ad4: 3a970f00   descriptor attr = 0  -> descriptor 60 now maps bank rh1 into <<60>>
L_0ad8:
	ld r6,@rr2                        ! 0ad8: 2126   [probe] read the window (absent RAM: no READY -> NMI -> rr12)
	orb rh0,rh0                       ! 0ada: 8400   already scanning for the end?
	jr ne,L_0aa8                      ! 0adc: eee5   yes -> keep scanning
	incb rh0,#0x1                     ! 0ade: a800   rh0 = 1 -> 'RAM start found'
	ld r4,r1                          ! 0ae0: a114   record start bank  (r4)
	ld r5,r3                          ! 0ae2: a135   record start offset (r5)
	ldar rr12,L_0aea                  ! 0ae4: 340c0002   rr12 = &0xaea  <- NMI resume now = 'record end' checkpoint
	jr t,L_0aa8                       ! 0ae8: e8df   keep scanning
L_0aea:
	ld r6,r1                          ! 0aea: a116   [end] record end bank  (r6)
	ld r7,r3                          ! 0aec: a137   record end offset (r7)
	ldl rr2,rr6                       ! 0aee: 9462   rr2 = end (bank:offset)
	ldl rr12,rr4                      ! 0af0: 944c   rr12 = start (bank:offset)
	srl r2,#0x8                       ! 0af2: b321fff8   end -> physical address
	srl r12,#0x8                      ! 0af6: b3c1fff8   start -> physical address
	subl rr2,rr12                     ! 0afa: 92c2   extent = end - start
	subl rr2,#0x4000                  ! 0afc: 120200004000   - 16 KB
	jp nc/uge,@rr10                   ! 0b02: 1eaf   extent >= 16 KB -> return OK (carry clear, via rr10)
	cpb rh1,#0xf0                     ! 0b04: 0a01f0f0   at the top bank?
	jr ne,L_0a9c                      ! 0b08: eec9   no -> retry the scan (0x0a9c)
L_0b0a:
	setflg c                          ! 0b0a: 8d81   [error] set carry = RAM absent or < 16 KB
	jp t,@rr10                        ! 0b0c: 1ea8   return; caller shows code 2 (system-RAM fault)

!==============================================================================
! MAP RAM INTO SEGMENTS  (in: rr4 = RAM start, rr6 = RAM end)
! Programs MMU descriptors from #2 upward to cover the contiguous physical RAM
! in 64 KB chunks (base, limit 0xFF, attr 0), the last sized to the remainder.
! Then sets descriptor 1 = a small system/stack segment near the RAM top and
! moves the stack into it (<<1>>0x01c0).
!==============================================================================
	ldk r1,#0x2                       ! 0b0e: bd12   SAR = descriptor 2 (first bulk-RAM segment)
	soutb #0x100,rl1                  ! 0b10: 3a970100   MMU SAR = 2
	soutb #0x2000,rh1                 ! 0b14: 3a172000   MMU DSC = 0
L_0b18:
	soutb #0xf00,rh4                  ! 0b18: 3a470f00   descriptor base-high = rh4
	soutb #0xf00,rh5                  ! 0b1c: 3a570f00   descriptor base-low  = rh5
	ldb rl0,#0x0                      ! 0b20: c800   block counter = 0
L_0b22:
	add r5,#0x100                     ! 0b22: 01050100   advance base by 256 bytes
	jr nc/uge,L_0b2a                  ! 0b26: ef01
	incb rh4,#0x1                     ! 0b28: a840   carry -> base-high++
L_0b2a:
	cpl rr6,rr4                       ! 0b2a: 9046   reached end of RAM (rr6)?
	jr eq,L_0b40                      ! 0b2c: e609   yes -> write the final (partial) descriptor
	incb rl0,#0x1                     ! 0b2e: a880   block++
	jr ne,L_0b22                      ! 0b30: eef8   < 256 blocks (64 KB)? keep filling this descriptor
	decb rl0,#0x1                     ! 0b32: aa80   256 blocks done
	soutb #0xf00,rl0                  ! 0b34: 3a870f00   descriptor limit = 0xFF (64 KB)
	soutb #0xf00,rh1                  ! 0b38: 3a170f00   descriptor attr = 0
	incb rl1,#0x1                     ! 0b3c: a890   next descriptor (SAR++)
	jr t,L_0b18                       ! 0b3e: e8ec   loop
L_0b40:
	soutb #0xf00,rl0                  ! 0b40: 3a870f00   final descriptor limit = remaining blocks
	soutb #0xf00,rh1                  ! 0b44: 3a170f00   attr = 0
	ldb rh4,rl1                       ! 0b48: a094
	ldb rh5,rl0                       ! 0b4a: a085
	incb rh5,#0x1                     ! 0b4c: a850
	jr ne,L_0b52                      ! 0b4e: ee01
	incb rh4,#0x1                     ! 0b50: a840
L_0b52:
	ldk r0,#0x1                       ! 0b52: bd01   SAR = descriptor 1 (small system/stack segment)
	soutb #0x100,rl0                  ! 0b54: 3a870100
	soutb #0x2000,rh0                 ! 0b58: 3a072000
	sub r7,#0x400                     ! 0b5c: 03070400   base = 0x400 below RAM top
	jr nc/uge,L_0b64                  ! 0b60: ef01
	decb rh6,#0x1                     ! 0b62: aa60
L_0b64:
	soutb #0xf00,rh6                  ! 0b64: 3a670f00   descriptor 1 base-high = rh6
	soutb #0xf00,rh7                  ! 0b68: 3a770f00   base-low = rh7
	ldk r0,#0x3                       ! 0b6c: bd03
	soutb #0xf00,rl0                  ! 0b6e: 3a870f00   limit = 3 (~1 KB)
	soutb #0xf00,rh0                  ! 0b72: 3a070f00   attr = 0
	.long_addr
	lda rr14,0x10001c0                ! 0b76: 760e810001c0   move the stack into RAM (<<1>>0x01c0)
	jp t,@rr10                        ! 0b7c: 1ea8   return
!==============================================================================
! DIAGNOSTIC CODE DISPLAY  (video + console)
! Shows the 1-hex-digit power-on step / error code (in r7) on every attached
! video screen, then on the UC diagnostic console panel. Ref: Manuale dei
! Collaudi 1-9..1-10 ("messaggi dell'autodiagnostica").
!------------------------------------------------------------------------------
! show code on VIDEO: write its ASCII hex digit into each seg-61 window
!==============================================================================
	ldk r1,#0x0                       ! 0b7e: bd10   r1=0 (video window index)
	ldar rr12,L_0baa                  ! 0b80: 340c0026   rr12 = &console-display (fall-through chain)
	ld r0,r7                          ! 0b84: a170   r0 = error/step code (r7)
	addb rl0,#0x30                    ! 0b86: 00083030   += '0'  -> ASCII
	cpb rl0,#0x3a                     ! 0b8a: 0a083a3a   > '9' ?
	jr c/ult,L_0b92                   ! 0b8e: e701   if <= '9', skip
	incb rl0,#0x7                     ! 0b90: a886   += 7  -> 'A'..'F' (hex)
L_0b92:
	ldb 0x3d000001(r1),rl0            ! 0b92: 6e183d01   video[seg61 : 0x0001 + r1] = digit
	ldb 0x3d000005(r1),#0x20          ! 0b96: 4c153d052020   video[0x0005 + r1] = ' '
	ldb 0x3d000009(r1),#0x20          ! 0b9c: 4c153d092020   video[0x0009 + r1] = ' '
	add r1,#0x2000                    ! 0ba2: 01012000   next video controller window (+0x2000)
	jr ne,L_0b92                      ! 0ba6: eef5   loop until r1 wraps to 0 (all windows)
	jr t,L_0baa                       ! 0ba8: e800   fall into the console display
!------------------------------------------------------------------------------
! show code on the CONSOLE: 0xFFE0 = numeric latch; 0xFF64..0xFF6F = 4 lamps,
! one per code bit (0xFF64+i clears lamp i, 0xFF6C+i sets it).  in: r7=code.
!------------------------------------------------------------------------------
L_0baa:
	outb #0xffe0,rl7                  ! 0baa: 3af6ffe0   console code latch (0xFFE0) = step/error code
	ldk r0,#0x3                       ! 0bae: bd03   i = 3 (4 bits, 3..0)
L_0bb0:
	ld r1,#0xff64                     ! 0bb0: 2101ff64   port = 0xFF64 + i  ("lamp i = 0" latch)
	add r1,r0                         ! 0bb4: 8101
	bit r7,r0                         ! 0bb6: 27000700   bit i of the code set?
	jr eq,L_0bbe                      ! 0bba: e601   clear -> use 0xFF64+i
	set r1,#0x3                       ! 0bbc: a513   set  -> port |= 8 -> 0xFF6C+i ("lamp i = 1")
L_0bbe:
	outb @r1,rl1                      ! 0bbe: 3e19   strobe the lamp latch (data = port low byte)
	dec r0,#0x1                       ! 0bc0: ab00
	jr pl,L_0bb0                      ! 0bc2: edf6   next bit while i >= 0
	jp t,@rr10                        ! 0bc4: 1ea8   return (rr10)

!==============================================================================
! VIDEO CONTROLLER DETECT / INIT / SELF-TEST        in: r1=ctrl I/O port,
!                                                       rr10=return
! The low byte of r1 (rl1) is the controller register-select; the high byte is
! the board select found by the slot scan.  Reads the controller type (reg
! 0x81, low 3 bits), programs its CRTC registers (0x41/0x43) from the per-type
! command table at 0x0c44, then tests video RAM and the live-signal logic.
! out: r0 = 0x0000 (video OK) or 0xFFFF (fail) -> config-table response word.
! Ref: Manuale dei Collaudi 1-10/1-11 (video controllers as diag output).
!==============================================================================
	ldb rl1,#0x81                     ! 0bc6: c981   rl1 = r1 low byte = reg-select 0x81 (status)
	inb rl2,@r1                       ! 0bc8: 3c1a   read status/type from ctrl reg 0x81
	and r2,#0x7                       ! 0bca: 07020007   type = low 3 bits
	add r2,r2                         ! 0bce: 8122   *2 -> word index
	ldar rr4,L_0c44                   ! 0bd0: 34040070   rr4 = &video-command table (0x0c44)
	ld r0,rr4(r2)                     ! 0bd4: 71400200   r0 = table[type] = offset of this type's cmd block
	add r5,r0                         ! 0bd8: 8105
	test @rr4                         ! 0bda: 0d44   empty command block?
	jr eq,L_0c34                      ! 0bdc: e62b   yes -> treat as failure
	ldb rl1,@rr4                      ! 0bde: 2049
	outb @r1,rl1                      ! 0be0: 3e19   strobe reg (byte = its own select)
	inc r5,#0x1                       ! 0be2: a950
	ldb rl1,@rr4                      ! 0be4: 2049
	outb @r1,rl1                      ! 0be6: 3e19
	inc r5,#0x1                       ! 0be8: a950
	ldb rh0,#0x10                     ! 0bea: c010   16 register writes
	sub r2,r2                         ! 0bec: 8322   index = 0
L_0bee:
	ldb rl1,#0x41                     ! 0bee: c941   reg-select 0x41 (CRTC addr latch)
	outb @r1,rl2                      ! 0bf0: 3e1a   write rl2 to ctrl reg 0x41
	ldb rl0,rr4(r2)                   ! 0bf2: 70480200   rl0 = next command byte from table
	ldb rl1,#0x43                     ! 0bf6: c943   reg-select 0x43 (CRTC data)
	outb @r1,rl0                      ! 0bf8: 3e18   write command byte to ctrl reg 0x43
	inc r2,#0x1                       ! 0bfa: a920
	dbjnz rh0,L_0bee                  ! 0bfc: f008   next of 16
	lda rr2,0x3d000000                ! 0bfe: 76023d00   rr2 = video RAM base (seg 61)
	ld r3,r7                          ! 0c02: a173   r3 = video offset = 0 (r7=0); rr2 = seg61:offset
	ld r5,#0x800                      ! 0c04: 21050800   2048 read-back passes
	ld r0,#0x20                       ! 0c08: 21000020   pattern = 0x20 (' ')
L_0c0c:
	ld @rr2,r0                        ! 0c0c: 2f20   video[seg61 : offset] = pattern (word)
	cp r0,@rr2                        ! 0c0e: 0b20   read back, compare
	jr ne,L_0c16                      ! 0c10: ee02   mismatch -> stop (fail)
	inc r3,#0x2                       ! 0c12: a931   offset += 2   <- WALKS video RAM (2048 words = 4 KB)
	djnz r5,L_0c0c                    ! 0c14: f585
L_0c16:
	and r3,#0x7ff                     ! 0c16: 070307ff   did the walk finish? (offset reached 0x1000)
	jr ne,L_0c34                      ! 0c1a: ee0c   nonzero -> FAIL
	ldb rl1,#0x1                      ! 0c1c: c901   reg-select 0x01
	ldb rl0,#0x3                      ! 0c1e: c803
	outb @r1,rl0                      ! 0c20: 3e18   write 3 to ctrl reg 0x01 (arm)
	ldb rl1,#0x81                     ! 0c22: c981   reg-select 0x81 (status)
	ldb rl2,#0x8                      ! 0c24: ca08   mask = bit 3 (VSYNC/refresh)
	inb rl0,@r1                       ! 0c26: 3c18   sample status
	andb rl0,rl2                      ! 0c28: 86a8   isolate bit 3
L_0c2a:
	inb rh0,@r1                       ! 0c2a: 3c10   sample status again
	andb rh0,rl2                      ! 0c2c: 86a0   isolate bit 3
	xorb rh0,rl0                      ! 0c2e: 8880   changed?
	jr ne,L_0c3c                      ! 0c30: ee05   toggled -> video OK
	djnz r3,L_0c2a                    ! 0c32: f385   retry
L_0c34:
	resflg z                          ! 0c34: 8d43   --- FAIL: response word = 0xFFFF ---
	ld r0,#0xffff                     ! 0c36: 2100ffff   r0 = 0xFFFF (video KO in config table)
	jp t,@rr10                        ! 0c3a: 1ea8   return (rr10)
L_0c3c:
	ldb rl1,#0x6a                     ! 0c3c: c96a   --- OK: reg-select 0x6a ---
	outb @r1,rl1                      ! 0c3e: 3e19   write 0x6a (enable normal video)
	sub r0,r0                         ! 0c40: 8300   r0 = 0x0000 (video OK in config table)
	jp t,@rr10                        ! 0c42: 1ea8   return (rr10)

! ---- 0x0c44 .. 0x0cd4  (word) ----
! Video-controller command table.  8 entries (one per type 0..7) each holding
! the offset (from 0x0c44) of that controller's CRTC init byte-string; the
! strings follow, terminated by 0x3fff.  Indexed via (status reg 0x81 & 7).
L_0c44:
	.word	0x0010
	.word	0x0022
	.word	0x0034
	.word	0x0046
	.word	0x0058
	.word	0x008e
	.word	0x006a
	.word	0x007c
	.word	0x6c60
	.word	0x6950
	.word	0x530a
	.word	0x1900
	.word	0x1919
	.word	0x0010
	.word	0x4b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6460
	.word	0x6950
	.word	0x530a
	.word	0x1905
	.word	0x1919
	.word	0x000b
	.word	0x4b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6c68
	.word	0x3428
	.word	0x2a07
	.word	0x0d01
	.word	0x0d0d
	.word	0x000f
	.word	0x6b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6460
	.word	0x6850
	.word	0x530a
	.word	0x1905
	.word	0x1919
	.word	0x000b
	.word	0x4b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6c60
	.word	0x6750
	.word	0x560a
	.word	0x1909
	.word	0x1919
	.word	0x000f
	.word	0x4b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6c68
	.word	0x3428
	.word	0x2a06
	.word	0x0e00
	.word	0x0d0d
	.word	0x000f
	.word	0x6b0b
	.word	0x0000
	.word	0x3fff
	.word	0x6460
	.word	0x6b50
	.word	0x590a
	.word	0x1a11
	.word	0x1919
	.word	0x000b
	.word	0x4b0b
	.word	0x0000
	.word	0x3fff
	.word	0x0000

! ---- 0x0cd4 .. 0x17dc  (code) ----
L_0cd4:
	pushl @rr14,rr4                   ! 0cd4: 91e4
	pushl @rr14,rr6                   ! 0cd6: 91e6
	lda rr6,0x3d000000                ! 0cd8: 76063d00
	subl rr4,rr4                      ! 0cdc: 9244
L_0cde:
	.long_addr
	ldb rl5,0x1000230(r4)             ! 0cde: 604d81000230
	cpb rl5,#0xfe                     ! 0ce4: 0a0dfefe
	jr ne,L_0d04                      ! 0ce8: ee0d
	pushl @rr14,rr6                   ! 0cea: 91e6
	pushl @rr14,rr2                   ! 0cec: 91e2
	push @rr14,r1                     ! 0cee: 93e1
L_0cf0:
	ldb rl5,@rr2                      ! 0cf0: 202d
	ld @rr6,r5                        ! 0cf2: 2f65
	inc r3,#0x1                       ! 0cf4: a930
	inc r7,#0x2                       ! 0cf6: a971
	djnz r1,L_0cf0                    ! 0cf8: f185
	pop r1,@rr14                      ! 0cfa: 97e1
	popl rr2,@rr14                    ! 0cfc: 95e2
	popl rr6,@rr14                    ! 0cfe: 95e6
	add r7,#0x2000                    ! 0d00: 01072000
L_0d04:
	inc r4,#0x4                       ! 0d04: a943
	bit r4,#0x6                       ! 0d06: a746
	jr eq,L_0cde                      ! 0d08: e6ea
	popl rr6,@rr14                    ! 0d0a: 95e6
	popl rr4,@rr14                    ! 0d0c: 95e4
	ret t                             ! 0d0e: 9e08
L_0d10:
	pushl @rr14,rr0                   ! 0d10: 91e0
	pushl @rr14,rr2                   ! 0d12: 91e2
	pushl @rr14,rr4                   ! 0d14: 91e4
	pushl @rr14,rr6                   ! 0d16: 91e6
	pushl @rr14,rr8                   ! 0d18: 91e8
	pushl @rr14,rr10                  ! 0d1a: 91ea
	or r7,r7                          ! 0d1c: 8577
	ld r0,#0xffff                     ! 0d1e: 2100ffff
	jr eq,L_0d4a                      ! 0d22: e613
	ld r0,r7                          ! 0d24: a170
	cpb rh7,rl7                       ! 0d26: 8af7
	jr eq,L_0d4a                      ! 0d28: e610
	ldb rh1,#0xf0                     ! 0d2a: c1f0
	ldb rl1,rl7                       ! 0d2c: a0f9
	andb rl1,#0xf                     ! 0d2e: 06090f0f
	.long_addr
	ldb rl0,0x1000302                 ! 0d32: 600881000302
	.long_addr
	ldb rh0,0x1000303                 ! 0d38: 600081000303
	and r0,#0xff0                     ! 0d3e: 07000ff0
	orb rh0,rh0                       ! 0d42: 8400
	jr ne,L_0d48                      ! 0d44: ee01
	setb rh0,#0x2                     ! 0d46: a402
L_0d48:
	or r0,r1                          ! 0d48: 8510
L_0d4a:
	.long_addr
	ld 0x1000308,r0                   ! 0d4a: 6f0081000308
	.long_addr
	lda rr2,0x10002d4                 ! 0d50: 7602810002d4
	ldb rl4,#0x20                     ! 0d56: cc20
	ld r1,#0x17                       ! 0d58: 21010017
L_0d5c:
	ldb rr2(r1),rl4                   ! 0d5c: 722c0100
	djnz r1,L_0d5c                    ! 0d60: f183
	ldb @rr2,#0x20                    ! 0d62: 0c252020
	ldl rr4,rr2                       ! 0d66: 9424
	ldk r6,#0x1                       ! 0d68: bd61
	or r7,r7                          ! 0d6a: 8577
	jr eq,L_0da0                      ! 0d6c: e619
	cpb rh7,rl7                       ! 0d6e: 8af7
	jr eq,L_0d74                      ! 0d70: e601
	ldk r6,#0x3                       ! 0d72: bd63
L_0d74:
	push @rr14,r0                     ! 0d74: 93e0
	and r0,#0xf                       ! 0d76: 0700000f
	orb rl0,#0x30                     ! 0d7a: 04083030
	cpb rl0,#0x3a                     ! 0d7e: 0a083a3a
	jr c/ult,L_0d86                   ! 0d82: e701
	incb rl0,#0x7                     ! 0d84: a886
L_0d86:
	ldb @rr4,rl0                      ! 0d86: 2e48
	pop r0,@rr14                      ! 0d88: 97e0
	rr r0,#0x2                        ! 0d8a: b306
	rr r0,#0x2                        ! 0d8c: b306
	inc r5,#0x2                       ! 0d8e: a951
	djnz r6,L_0d74                    ! 0d90: f68f
L_0d92:
	.long_addr
	ldar rr8,L_0d92                   ! 0d92: 3408fffc
	ld r9,#0x14                       ! 0d96: 21090014
	ldk r0,#0x8                       ! 0d9a: bd08
	ldir @rr4,@rr8,r0                 ! 0d9c: bb810040
L_0da0:
	ld r1,#0x18                       ! 0da0: 21010018
	calr L_0cd4                       ! 0da4: d069
	.long_addr
	ld r7,0x1000308                   ! 0da6: 610781000308
	cpb rh7,rl7                       ! 0dac: 8af7
	jr ne,L_0db4                      ! 0dae: ee02
	calr L_0e60                       ! 0db0: dfa9
	jr t,L_0db8                       ! 0db2: e802
L_0db4:
	ldk r0,#0x1                       ! 0db4: bd01
	calr L_0de4                       ! 0db6: dfea
L_0db8:
	popl rr10,@rr14                   ! 0db8: 95ea
	popl rr8,@rr14                    ! 0dba: 95e8
	popl rr6,@rr14                    ! 0dbc: 95e6
	popl rr4,@rr14                    ! 0dbe: 95e4
	popl rr2,@rr14                    ! 0dc0: 95e2
	popl rr0,@rr14                    ! 0dc2: 95e0
	ret t                             ! 0dc4: 9e08
	push @rr14,r0                     ! 0dc6: 93e0
	ld r0,r7                          ! 0dc8: a170
	and r0,#0x7                       ! 0dca: 07000007
	pop r0,@rr14                      ! 0dce: 97e0
	ret eq                            ! 0dd0: 9e06
	jr t,L_0d10                       ! 0dd2: e89e
	push @rr14,r0                     ! 0dd4: 93e0
	.long_addr
	ld 0x1000308,r7                   ! 0dd6: 6f0781000308
	ldk r0,#0x1                       ! 0ddc: bd01
	calr L_0de4                       ! 0dde: dffe
	pop r0,@rr14                      ! 0de0: 97e0
	ret t                             ! 0de2: 9e08
L_0de4:
	pushl @rr14,rr0                   ! 0de4: 91e0
	pushl @rr14,rr6                   ! 0de6: 91e6
	pushl @rr14,rr8                   ! 0de8: 91e8
	pushl @rr14,rr10                  ! 0dea: 91ea
	.long_addr
	ldb 0x100030f,rl0                 ! 0dec: 6e088100030f
	.long_addr
	tsetb 0x10002fa                   ! 0df2: 4c06810002fa
	jr mi,L_0e24                      ! 0df8: e515
	calr L_0e60                       ! 0dfa: dfce
	.long_addr
	ld r7,0x1000308                   ! 0dfc: 610781000308
	rr r7,#0x2                        ! 0e02: b376
	rr r7,#0x2                        ! 0e04: b376
	.long_addr
	ld 0x1000308,r7                   ! 0e06: 6f0781000308
	ld r1,#0x3013                     ! 0e0c: 21013013
	outb #0xffc1,rl1                  ! 0e10: 3a96ffc1
	outb #0xffc1,rh1                  ! 0e14: 3a16ffc1
	ld r0,#0x64                       ! 0e18: 21000064
	outb #0xffc3,rl0                  ! 0e1c: 3a86ffc3
	outb #0xffc3,rh0                  ! 0e20: 3a06ffc3
L_0e24:
	popl rr10,@rr14                   ! 0e24: 95ea
	popl rr8,@rr14                    ! 0e26: 95e8
	popl rr6,@rr14                    ! 0e28: 95e6
	popl rr0,@rr14                    ! 0e2a: 95e0
	ret t                             ! 0e2c: 9e08
	pushl @rr14,rr0                   ! 0e2e: 91e0
	ldb rl0,#0x70                     ! 0e30: c870
	outb #0xffc7,rl0                  ! 0e32: 3a86ffc7
	.long_addr
	clrb 0x10002fa                    ! 0e36: 4c08810002fa
	.long_addr
	ldb rl0,0x100030f                 ! 0e3c: 60088100030f
	cpb rl0,#0x1                      ! 0e42: 0a080101
	jr ne,L_0e54                      ! 0e46: ee06
	.long_addr
	ld r0,0x1000308                   ! 0e48: 610081000308
	cpb rh0,rl0                       ! 0e4e: 8a80
	jr eq,L_0e56                      ! 0e50: e602
	ldk r0,#0x1                       ! 0e52: bd01
L_0e54:
	calr L_0de4                       ! 0e54: d039
L_0e56:
	.long_addr
	decb 0x100030f,#0x1               ! 0e56: 6a008100030f
	popl rr0,@rr14                    ! 0e5c: 95e0
	iret                              ! 0e5e: 7b00
L_0e60:
	.long_addr
	ldar rr8,L_0e60                   ! 0e60: 3408fffc
	ld r9,#0xbaa                      ! 0e64: 21090baa
	ldar rr10,L_0e74                  ! 0e68: 340a0008
	.long_addr
	ld r7,0x1000308                   ! 0e6c: 610781000308
	jp t,@rr8                         ! 0e72: 1e88
L_0e74:
	ret t                             ! 0e74: 9e08
	push @rr14,r2                     ! 0e76: 93e2
	ldb rl2,rl0                       ! 0e78: a08a
	.long_addr
	ldb rh2,0x10002fb                 ! 0e7a: 6002810002fb
	subb rl2,rh2                      ! 0e80: 822a
	jr ule,L_0e90                     ! 0e82: e306
	.long_addr
	ldb 0x10002fb,rl0                 ! 0e84: 6e08810002fb
	ldb rl0,rl2                       ! 0e8a: a0a8
	pop r2,@rr14                      ! 0e8c: 97e2
	ret t                             ! 0e8e: 9e08
L_0e90:
	ldb rl0,#0x1                      ! 0e90: c801
	pop r2,@rr14                      ! 0e92: 97e2
	ret t                             ! 0e94: 9e08
	push @rr14,r2                     ! 0e96: 93e2
	.long_addr
	ldb rl2,0x10002fb                 ! 0e98: 600a810002fb
	addb rl0,rl2                      ! 0e9e: 80a8
	jr nc/uge,L_0ea4                  ! 0ea0: ef01
	ldb rl0,#0xff                     ! 0ea2: c8ff
L_0ea4:
	.long_addr
	ldb 0x10002fb,rl0                 ! 0ea4: 6e08810002fb
	pop r2,@rr14                      ! 0eaa: 97e2
	ret t                             ! 0eac: 9e08

!==============================================================================
! FDU FLOPPY BOOT LOADER (IPL handler for E1/E0) -- GO280: uPD765 + AM9517 DMAC
! + 8253.  Governo at the FDU slot (high byte = <<1>>0x0302); low byte = register
! (per manual 3963590): 0x1D=FDC status, 0x1F=FDC data, 0x40-5E=DMAC, 0x9x=8253
! timer, 0xE7=control (CONTR), 0xF6=DMA addr-high, 0xF7=int status, 0xFF=ID(E0/E1).
! Boot read = uPD765 READ DATA (templates 0x17dc/0x17e6: C=0 H=0 R=1), DMA'd via
! DMAC ch2 (+0xF6 high byte) to segment 60.
!==============================================================================
L_0eae:
	push @rr14,r0                     ! 0eae: 93e0   reset the governo control latch (0x0354=0) + strobe (0xe7)
	.long_addr
	clrb 0x1000354                    ! 0eb0: 4c0881000354   control shadow <<1>>0x0354 = 0
	calr L_12ca                       ! 0eb6: ddf7   push control latch to reg 0xe7 (helper 0x12ca)
	ldb rl0,#0x32                     ! 0eb8: c832
L_0eba:
	dbjnz rl0,L_0eba                  ! 0eba: f801   settle delay
	pop r0,@rr14                      ! 0ebc: 97e0
	ret t                             ! 0ebe: 9e08
L_0ec0:
	pushl @rr14,rr0                   ! 0ec0: 91e0
	pushl @rr14,rr2                   ! 0ec2: 91e2
	pushl @rr14,rr8                   ! 0ec4: 91e8
	ldctl r2,fcw                      ! 0ec6: 7d22   save FCW
	di vi                             ! 0ec8: 7c01   di vi
	.long_addr
	ldb rh1,0x1000302                 ! 0eca: 600181000302   rh1 = FDU slot device-select (<<1>>0x0302)
	calr L_0eae                       ! 0ed0: d012   reset the governo
	.long_addr
	clrb 0x100034d                    ! 0ed2: 4c088100034d
	.long_addr
	clrb 0x100034e                    ! 0ed8: 4c088100034e
	ldb rl1,#0x9f                     ! 0ede: c99f   8253 timer: control = 0x50 (reg 0x9f)
	ldb rl0,#0x50                     ! 0ee0: c850
	outb @r1,rl0                      ! 0ee2: 3e18
	ldb rl1,#0xe7                     ! 0ee4: c9e7   read reg 0xe7
	inb rl0,@r1                       ! 0ee6: 3c18
	.long_addr
	ldb 0x1000354,#0x13               ! 0ee8: 4c0581000354   control shadow = 0x13 (motor/select on)
	calr L_12ca                       ! 0ef0: de14   push to reg 0xe7
	ldb rl1,#0x1d                     ! 0ef2: c91d   read reg 0x1d (uPD765 main status)
	inb rl0,@r1                       ! 0ef4: 3c18
	ldb rl0,#0x20                     ! 0ef6: c820   reg 0x50 = 0x20
	ldb rl1,#0x50                     ! 0ef8: c950
	outb @r1,rl0                      ! 0efa: 3e18   write
	calr L_12da                       ! 0efc: de12   poll status (0x12da)
	ldar rr8,L_0f2a                   ! 0efe: 34080028
	jr ne,L_0f10                      ! 0f02: ee06
	calr L_0f2e                       ! 0f04: dfec
	ldar rr8,L_0f26                   ! 0f06: 3408001c
	jr ne,L_0f10                      ! 0f0a: ee02
	ldar rr8,L_0f22                   ! 0f0c: 34080012
L_0f10:
	calr L_1172                       ! 0f10: ded0   issue the read (0x1172)
	ldctl fcw,r2                      ! 0f12: 7d2a   restore FCW
	ld r0,#0xfa0                      ! 0f14: 21000fa0
L_0f18:
	djnz r0,L_0f18                    ! 0f18: f081
	popl rr8,@rr14                    ! 0f1a: 95e8
	popl rr2,@rr14                    ! 0f1c: 95e2
	popl rr0,@rr14                    ! 0f1e: 95e0
	ret t                             ! 0f20: 9e08
L_0f22:
	sub r3,#0xed0e                    ! 0f22: 0303ed0e
L_0f26:
	sub r3,#0x3f1c                    ! 0f26: 03033f1c
L_0f2a:
	sub r3,#0xdf26                    ! 0f2a: 0303df26
L_0f2e:
	pushl @rr14,rr0                   ! 0f2e: 91e0
	.long_addr
	ldb rh1,0x1000302                 ! 0f30: 600181000302   rh1 = FDU slot
	ldb rl1,#0xff                     ! 0f36: c9ff   reg 0xff
	inb rl0,@r1                       ! 0f38: 3c18   read status
	bitb rl0,#0x0                     ! 0f3a: a680   bit 0 (ready/complete)?
	jr ne,L_0f44                      ! 0f3c: ee03
	ldb rl1,#0xed                     ! 0f3e: c9ed   reg 0xed
	inb rl0,@r1                       ! 0f40: 3c18   read
	bitb rl0,#0x0                     ! 0f42: a680   bit 0?
L_0f44:
	popl rr0,@rr14                    ! 0f44: 95e0
	ret t                             ! 0f46: 9e08
L_0f48:
	pushl @rr14,rr4                   ! 0f48: 91e4
	pushl @rr14,rr2                   ! 0f4a: 91e2
	push @rr14,r1                     ! 0f4c: 93e1
	push @rr14,r0                     ! 0f4e: 93e0
	.long_addr
	ldb rh1,0x1000302                 ! 0f50: 600181000302
	ldctl r4,fcw                      ! 0f56: 7d42
	di vi                             ! 0f58: 7c01
	ldb rl1,#0x5e                     ! 0f5a: c95e
	ldb rl0,#0xff                     ! 0f5c: c8ff
	outb @r1,rl0                      ! 0f5e: 3e18
	ldb rl0,rr8(#0x1)                 ! 0f60: 30880001
	andb rl0,#0x13                    ! 0f64: 06081313
	cpb rl0,#0x1                      ! 0f68: 0a080101
	ldb rl0,#0x4a                     ! 0f6c: c84a
	.long_addr
	setb 0x1000354,#0x6               ! 0f6e: 640681000354
	jr eq,L_0f7e                      ! 0f74: e604
	ldb rl0,#0x46                     ! 0f76: c846
	.long_addr
	resb 0x1000354,#0x6               ! 0f78: 620681000354
L_0f7e:
	calr L_12ca                       ! 0f7e: de5b
	ldb rl1,#0x56                     ! 0f80: c956
	outb @r1,rl0                      ! 0f82: 3e18
	ldb rl0,#0x41                     ! 0f84: c841
	outb @r1,rl0                      ! 0f86: 3e18
	pushl @rr14,rr4                   ! 0f88: 91e4
L_0f8a:
	.long_addr
	ldar rr4,L_0f8a                   ! 0f8a: 3404fffc
	ld r5,#0xa70                      ! 0f8e: 21050a70
	call @rr4                         ! 0f92: 1f40
	popl rr4,@rr14                    ! 0f94: 95e4
	srll rr2,#0x1                     ! 0f96: b325ffff
	ldb rl1,#0xf6                     ! 0f9a: c9f6
	outb @r1,rl2                      ! 0f9c: 3e1a
	ldb rl1,#0x58                     ! 0f9e: c958
	outb @r1,rl1                      ! 0fa0: 3e19
	ldb rl1,#0x44                     ! 0fa2: c944
	outb @r1,rl3                      ! 0fa4: 3e1b
	outb @r1,rh3                      ! 0fa6: 3e13
	ldb rl1,#0x48                     ! 0fa8: c948
	ldb rl2,#0xff                     ! 0faa: caff
	outb @r1,rl2                      ! 0fac: 3e1a
	outb @r1,rl2                      ! 0fae: 3e1a
	ldb rl1,#0x46                     ! 0fb0: c946
	outb @r1,rl2                      ! 0fb2: 3e1a
	outb @r1,rl2                      ! 0fb4: 3e1a
	ldb rl1,#0x4a                     ! 0fb6: c94a
	pop r0,@rr14                      ! 0fb8: 97e0
	dec r0,#0x1                       ! 0fba: ab00
	outb @r1,rl0                      ! 0fbc: 3e18
	outb @r1,rh0                      ! 0fbe: 3e10
	inc r0,#0x1                       ! 0fc0: a900
	ldctl fcw,r4                      ! 0fc2: 7d4a
	ldb rl1,#0xe7                     ! 0fc4: c9e7
	inb rl2,@r1                       ! 0fc6: 3c1a
	ldb rl1,#0x5e                     ! 0fc8: c95e
	ldb rl2,#0xf9                     ! 0fca: caf9
	outb @r1,rl2                      ! 0fcc: 3e1a
	pop r1,@rr14                      ! 0fce: 97e1
	popl rr2,@rr14                    ! 0fd0: 95e2
	popl rr4,@rr14                    ! 0fd2: 95e4
	ret t                             ! 0fd4: 9e08
L_0fd6:
	pushl @rr14,rr0                   ! 0fd6: 91e0
	pushl @rr14,rr2                   ! 0fd8: 91e2
	pushl @rr14,rr4                   ! 0fda: 91e4
	pushl @rr14,rr8                   ! 0fdc: 91e8
	andb rl0,rl0                      ! 0fde: 8688
	jr eq,L_100a                      ! 0fe0: e614
	.long_addr
	cpb 0x1000338,#0x0                ! 0fe2: 4c0181000338
	jr eq,L_100a                      ! 0fea: e60f
	.long_addr
	cpb rl0,0x1000338                 ! 0fec: 4a0881000338
	jr lt,L_0ff6                      ! 0ff2: e101
	incb rl0,#0x1                     ! 0ff4: a880
L_0ff6:
	.long_addr
	cpb 0x1000339,#0x0                ! 0ff6: 4c0181000339
	jr eq,L_100a                      ! 0ffe: e605
	.long_addr
	cpb rl0,0x1000339                 ! 1000: 4a0881000339
	jr lt,L_100a                      ! 1006: e101
	incb rl0,#0x1                     ! 1008: a880
L_100a:
	jr t,L_1014                       ! 100a: e804
	pushl @rr14,rr0                   ! 100c: 91e0
	pushl @rr14,rr2                   ! 100e: 91e2
	pushl @rr14,rr4                   ! 1010: 91e4
	pushl @rr14,rr8                   ! 1012: 91e8
L_1014:
	.long_addr
	ldb rh1,0x1000302                 ! 1014: 600181000302
	calr L_12da                       ! 101a: dea1
	ldb rl2,#0x4d                     ! 101c: ca4d
	jr ne,L_1028                      ! 101e: ee04
	calr L_0f2e                       ! 1020: d07a
	ldb rl2,#0x28                     ! 1022: ca28
	jr ne,L_1028                      ! 1024: ee01
	ldb rl2,#0x50                     ! 1026: ca50
L_1028:
	cpb rl0,rl2                       ! 1028: 8aa8
	jr pl,L_106e                      ! 102a: ed21
	calr L_0f2e                       ! 102c: d080
	jr ne,L_103c                      ! 102e: ee06
	.long_addr
	cpb 0x1000307,#0x4e               ! 1030: 4c0181000307
	jr eq,L_103c                      ! 1038: e601
	addb rl0,rl0                      ! 103a: 8088
L_103c:
	sub r4,r4                         ! 103c: 8344
L_103e:
	.long_addr
	lda rr8,0x1000330                 ! 103e: 760881000330
	ld @rr8,#0x30f                    ! 1044: 0d85030f
	ld rr8(#0x2),r0                   ! 1048: 33800002
	calr L_1172                       ! 104c: df6e
	.long_addr
	ld r3,0x100034a                   ! 104e: 61038100034a
	or r3,r3                          ! 1054: 8533
	resflg c                          ! 1056: 8d83
	jr eq,L_1076                      ! 1058: e60e
	res r3,#0x7                       ! 105a: a337
	or r3,r3                          ! 105c: 8533
	jr ne,L_1074                      ! 105e: ee0a
	djnz r4,L_103e                    ! 1060: f492
	calr L_0ec0                       ! 1062: d0d2
L_1064:
	.long_addr
	testb 0x100034e                   ! 1064: 4c048100034e
	jr ne,L_1064                      ! 106a: eefc
	jr eq,L_103e                      ! 106c: e6e8
L_106e:
	.long_addr
	set 0x100034a,#0x4                ! 106e: 65048100034a
L_1074:
	setflg c                          ! 1074: 8d81
L_1076:
	popl rr8,@rr14                    ! 1076: 95e8
	popl rr4,@rr14                    ! 1078: 95e4
	popl rr2,@rr14                    ! 107a: 95e2
	popl rr0,@rr14                    ! 107c: 95e0
	ret t                             ! 107e: 9e08
L_1080:
	.long_addr
	clrb 0x100035d                    ! 1080: 4c088100035d
	pushl @rr14,rr4                   ! 1086: 91e4
	ldb rl4,rr8(#0x2)                 ! 1088: 308c0002
	and r4,#0x3                       ! 108c: 07040003
	.long_addr
	ldb rl5,0x100034d                 ! 1090: 600d8100034d
	bit r5,r4                         ! 1096: 27040500
	jr ne,L_10b6                      ! 109a: ee0d
	.long_addr
	set 0x100034a,#0x1                ! 109c: 65018100034a
L_10a2:
	.long_addr
	bit 0x100034a,#0x3                ! 10a2: 67038100034a
	setflg c                          ! 10a8: 8d81
	jr eq,L_10b2                      ! 10aa: e603
	calr L_0ec0                       ! 10ac: d0f7
	jr t,L_10b2                       ! 10ae: e801
L_10b0:
	resflg c                          ! 10b0: 8d83
L_10b2:
	popl rr4,@rr14                    ! 10b2: 95e4
	ret t                             ! 10b4: 9e08
L_10b6:
	.long_addr
	clr 0x100034a                     ! 10b6: 4d088100034a
	push @rr14,r0                     ! 10bc: 93e0
	ldb rl0,rr8(#0x3)                 ! 10be: 30880003
	ldb rh0,rl4                       ! 10c2: a0c0
	calr L_0fd6                       ! 10c4: d078
	pop r0,@rr14                      ! 10c6: 97e0
	jr c/ult,L_10a2                   ! 10c8: e7ec
	popl rr4,@rr14                    ! 10ca: 95e4
	jr t,L_10d4                       ! 10cc: e803
L_10ce:
	.long_addr
	clrb 0x100035d                    ! 10ce: 4c088100035d
L_10d4:
	pushl @rr14,rr4                   ! 10d4: 91e4
	ldb rl5,#0x5                      ! 10d6: cd05
L_10d8:
	.long_addr
	clr 0x100034a                     ! 10d8: 4d088100034a
	calr L_0f48                       ! 10de: d0cc
	calr L_1172                       ! 10e0: dfb8
	.long_addr
	ld r4,0x100034a                   ! 10e2: 61048100034a
	or r4,r4                          ! 10e8: 8544
	jr eq,L_10b0                      ! 10ea: e6e2
	res r4,#0x7                       ! 10ec: a347
	or r4,r4                          ! 10ee: 8544
	jr eq,L_10d8                      ! 10f0: e6f3
	res r4,#0x6                       ! 10f2: a346
	or r4,r4                          ! 10f4: 8544
	jr eq,L_10b0                      ! 10f6: e6dc
	res r4,#0x2                       ! 10f8: a342
	or r4,r4                          ! 10fa: 8544
	jr ne,L_1102                      ! 10fc: ee02
	dbjnz rl5,L_10d8                  ! 10fe: fd14
	jr t,L_10a2                       ! 1100: e8d0
L_1102:
	res r4,#0x2                       ! 1102: a342
	res r4,#0x2                       ! 1104: a342
	or r4,r4                          ! 1106: 8544
	jr ne,L_10a2                      ! 1108: eecc
	.long_addr
	tsetb 0x100035d                   ! 110a: 4c068100035d
	jr mi,L_10a2                      ! 1110: e5c8
	calr L_1116                       ! 1112: dfff
	jr t,L_10b6                       ! 1114: e8d0
L_1116:
	pushl @rr14,rr0                   ! 1116: 91e0
	pushl @rr14,rr8                   ! 1118: 91e8
	.long_addr
	lda rr8,0x1000334                 ! 111a: 760881000334   cmd block at <<1>>0x0334
	ld @rr8,#0x207                    ! 1120: 0d850207   @block = 0x0207 (seek/specify)
	.long_addr
	ldb rl0,0x1000303                 ! 1124: 600881000303   drive # from <<1>>0x0303
	andb rl0,#0x3                     ! 112a: 06080303
	ldb rr8(#0x2),rl0                 ! 112e: 32880002   patch drive into block
	calr L_1172                       ! 1132: dfe1   issue (0x1172)
	popl rr8,@rr14                    ! 1134: 95e8
	popl rr0,@rr14                    ! 1136: 95e0
	ret t                             ! 1138: 9e08
L_113a:
	calr L_1154                       ! 113a: dff4
	comflg c                          ! 113c: 8d85
L_113e:
	jr eq,L_1142                      ! 113e: e601
	jr nc/uge,L_114a                  ! 1140: ef04
L_1142:
	.long_addr
	set 0x100034a,#0x0                ! 1142: 65008100034a
	setflg c                          ! 1148: 8d81
L_114a:
	ldb rl0,rl1                       ! 114a: a098
	ldb rl1,#0x1f                     ! 114c: c91f
	ret t                             ! 114e: 9e08
L_1150:
	calr L_1154                       ! 1150: dfff
	jr t,L_113e                       ! 1152: e8f5

!------------------------------------------------------------------------------
! Poll the uPD765 main status register (governo reg 0x1d) for RQM, with timeout.
!------------------------------------------------------------------------------
L_1154:
	push @rr14,r2                     ! 1154: 93e2   [poll RQM] retry counter
	ld r2,#0x0                        ! 1156: 21020000
L_115a:
	ldb rl0,#0x14                     ! 115a: c814
L_115c:
	dbjnz rl0,L_115c                  ! 115c: f801   short delay
	dec r2,#0x1                       ! 115e: ab20   timeout--
	jr eq,L_116e                      ! 1160: e606
	ldb rl1,#0x1d                     ! 1162: c91d   reg 0x1d = uPD765 main status
	inb rl0,@r1                       ! 1164: 3c18   read it
	ldb rl1,rl0                       ! 1166: a089
	rlb rl0,#0x1                      ! 1168: b280   rotate: RQM (bit7) into carry
	jr nc/uge,L_115a                  ! 116a: eff7   not ready -> keep polling
	rlb rl0,#0x1                      ! 116c: b280
L_116e:
	pop r2,@rr14                      ! 116e: 97e2
	ret t                             ! 1170: 9e08

!------------------------------------------------------------------------------
! Issue a governo/uPD765 operation (command bytes + DMA read of the sector).
! rr8 -> device/command descriptor; op code in rr8[1].
!------------------------------------------------------------------------------
L_1172:
	pushl @rr14,rr0                   ! 1172: 91e0   [read routine]
	pushl @rr14,rr2                   ! 1174: 91e2
	pushl @rr14,rr4                   ! 1176: 91e4
	pushl @rr14,rr6                   ! 1178: 91e6
	pushl @rr14,rr8                   ! 117a: 91e8
	.long_addr
	ldb rh1,0x1000302                 ! 117c: 600181000302   rh1 = FDU slot
	ldb rl1,#0x1d                     ! 1182: c91d   reg 0x1d = main status
	inb rh6,@r1                       ! 1184: 3c16
	andb rh6,#0x1f                    ! 1186: 06061f1f   mask ready bits
	jr ne,L_124c                      ! 118a: ee60   not ready -> error (0x124c)
	ldb rl1,#0x9f                     ! 118c: c99f   8253/DMAC setup (reg 0x9f)
	ldb rl0,rr8(#0x1)                 ! 118e: 30880001   op code from descriptor rr8[1]
	andb rl0,#0xf                     ! 1192: 06080f0f
	cpb rl0,#0xd                      ! 1196: 0a080d0d   read op (0x0d)?
	ldb rl0,#0x98                     ! 119a: c898
	jr eq,L_11a6                      ! 119c: e604
	ldb rl0,#0x90                     ! 119e: c890
	outb @r1,rl0                      ! 11a0: 3e18   8253 counter setup (0x90/0x98 -> reg 0x9f)
	ldb rl1,#0x9d                     ! 11a2: c99d   8253 counter (reg 0x9d) = 0x02
	ldb rl0,#0x2                      ! 11a4: c802
L_11a6:
	outb @r1,rl0                      ! 11a6: 3e18
	clr r2                            ! 11a8: 8d28
	ldb rl0,#0x8                      ! 11aa: c808
L_11ac:
	.long_addr
	clr 0x100033a(r2)                 ! 11ac: 4d288100033a   clear the 8-byte result buffer <<1>>0x033a
	inc r2,#0x2                       ! 11b2: a921
	dbjnz rl0,L_11ac                  ! 11b4: f805
	ldb rl0,rr8(#0x1)                 ! 11b6: 30880001
	cpb rl0,#0x3                      ! 11ba: 0a080303
	jr eq,L_125a                      ! 11be: e64d
	cpb rl0,#0x4                      ! 11c0: 0a080404
	jr eq,L_125a                      ! 11c4: e64a
	resb rl0,#0x3                     ! 11c6: a283
	cpb rl0,#0x7                      ! 11c8: 0a080707
	jr ne,L_11e8                      ! 11cc: ee0d
	ldb rl0,rr8(#0x2)                 ! 11ce: 30880002
	and r0,#0x3                       ! 11d2: 07000003
	.long_addr
	ldb rl4,0x100034e                 ! 11d6: 600c8100034e
	setb rl4,r0                       ! 11dc: 24000c00
	.long_addr
	ldb 0x100034e,rl4                 ! 11e0: 6e0c8100034e
	jr t,L_125a                       ! 11e6: e839
L_11e8:
	calr L_146e                       ! 11e8: debe
	.long_addr
	ldb rl2,0x100034e                 ! 11ea: 600a8100034e
	.long_addr
	ldb rl4,0x1000303                 ! 11f0: 600c81000303
	and r4,#0x1                       ! 11f6: 07040001
	inc r4,#0x5                       ! 11fa: a944
	bit r2,r4                         ! 11fc: 27040200
	jr ne,L_1254                      ! 1200: ee29
	ldar rr2,L_133e                   ! 1202: 34020138
	ld r0,#0x64                       ! 1206: 21000064
	calr L_12ae                       ! 120a: dfaf
	cp r4,#0x5                        ! 120c: 0b040005
	ldk r3,#0x7                       ! 1210: bd37
	jr eq,L_1216                      ! 1212: e601
	ldk r3,#0x3                       ! 1214: bd33
L_1216:
	out #0xff84,r0                    ! 1216: 3b06ff84   0xFF84 = backplane-DMA gate
	.long_addr
	ldb rl2,0x1000354                 ! 121a: 600a81000354
	set r2,r3                         ! 1220: 25030200
	.long_addr
	ldb 0x1000354,rl2                 ! 1224: 6e0a81000354
	calr L_12ca                       ! 122a: dfb1
	out #0xff8c,r0                    ! 122c: 3b06ff8c   0xFF8C = DMA control
	subl rr2,rr2                      ! 1230: 9222
	ldb rl3,#0x14                     ! 1232: cb14
L_1234:
	.long_addr
	ldb rl5,0x100034e                 ! 1234: 600d8100034e
	bit r5,r4                         ! 123a: 27040500
	jr ne,L_1254                      ! 123e: ee0a
	djnz r2,L_1234                    ! 1240: f287
	dbjnz rl3,L_1234                  ! 1242: fb08
	.long_addr
	set 0x100034a,#0x0                ! 1244: 65008100034a
	jr t,L_129e                       ! 124a: e829
L_124c:
	.long_addr
	set 0x100034a,#0x7                ! 124c: 65078100034a
	jr t,L_129e                       ! 1252: e825
L_1254:
	.long_addr
	setb 0x100034e,#0x4               ! 1254: 64048100034e
L_125a:
	ldb rl4,@rr8                      ! 125a: 208c
	clrb rh4                          ! 125c: 8c48
	inc r9,#0x1                       ! 125e: a990
L_1260:
	calr L_1150                       ! 1260: d089   [send command byte] poll RQM (0x1150)
	jr c/ult,L_129e                   ! 1262: e71d
	out #0xff84,r0                    ! 1264: 3b06ff84   open the backplane-DMA gate (UC gate array 0xFF84)
	outib @r1,@rr8,r4                 ! 1268: 3a820418   PIO one command byte to the governo (outib @r1,@rr8)
	jr nov/po,L_1260                  ! 126c: ecf9   more command bytes -> loop
	out #0xff8c,r0                    ! 126e: 3b06ff8c   close the DMA gate (0xFF8C) -- sector data itself DMAs to system RAM
	.long_addr
	ldb rl0,0x100034e                 ! 1272: 60088100034e
	andb rl0,#0x1f                    ! 1278: 06081f1f
	jr eq,L_129e                      ! 127c: e610
	ldar rr2,L_135c                   ! 127e: 340200da
	ld r0,#0x258                      ! 1282: 21000258
	calr L_12ae                       ! 1286: dfed
L_1288:
	.long_addr
	ldb rl0,0x100034e                 ! 1288: 60088100034e
	andb rl0,#0x1f                    ! 128e: 06081f1f
	jr ne,L_1288                      ! 1292: eefa
	ldar rr2,L_1322                   ! 1294: 3402008a
	ld r0,#0x3e8                      ! 1298: 210003e8
	calr L_12ae                       ! 129c: dff8
L_129e:
	out #0xff8c,r0                    ! 129e: 3b06ff8c   0xFF8C = DMA control
	popl rr8,@rr14                    ! 12a2: 95e8
	popl rr6,@rr14                    ! 12a4: 95e6
	popl rr4,@rr14                    ! 12a6: 95e4
	popl rr2,@rr14                    ! 12a8: 95e2
	popl rr0,@rr14                    ! 12aa: 95e0
	ret t                             ! 12ac: 9e08
L_12ae:
	push @rr14,r1                     ! 12ae: 93e1
	push @rr14,r0                     ! 12b0: 93e0
	.long_addr
	ld 0x1000352,r3                   ! 12b2: 6f0381000352
	ldb rl1,#0x9f                     ! 12b8: c99f
	ldb rh0,#0x70                     ! 12ba: c070
	outb @r1,rh0                      ! 12bc: 3e10
	ldb rl1,#0x9b                     ! 12be: c99b
	pop r0,@rr14                      ! 12c0: 97e0
	outb @r1,rl0                      ! 12c2: 3e18
	outb @r1,rh0                      ! 12c4: 3e10
	pop r1,@rr14                      ! 12c6: 97e1
	ret t                             ! 12c8: 9e08
L_12ca:
	pushl @rr14,rr0                   ! 12ca: 91e0   [helper] write control shadow (<<1>>0x0354) to reg 0xe7
	ldb rl1,#0xe7                     ! 12cc: c9e7   reg 0xe7
	.long_addr
	ldb rl0,0x1000354                 ! 12ce: 600881000354
	outb @r1,rl0                      ! 12d4: 3e18
	popl rr0,@rr14                    ! 12d6: 95e0
	ret t                             ! 12d8: 9e08
L_12da:
	pushl @rr14,rr0                   ! 12da: 91e0   [helper] read reg 0xff bit 0 (status)
	.long_addr
	ldb rh1,0x1000302                 ! 12dc: 600181000302
	ldb rl1,#0xff                     ! 12e2: c9ff   reg 0xff
	inb rl0,@r1                       ! 12e4: 3c18   read
	bitb rl0,#0x0                     ! 12e6: a680   bit 0
	popl rr0,@rr14                    ! 12e8: 95e0
	ret t                             ! 12ea: 9e08
L_12ec:
	pushl @rr14,rr0                   ! 12ec: 91e0
	pushl @rr14,rr2                   ! 12ee: 91e2
	pushl @rr14,rr8                   ! 12f0: 91e8
	.long_addr
	ldar rr2,L_12ec                   ! 12f2: 3402fff6
	.long_addr
	ld r3,0x1000350                   ! 12f6: 610381000350
	jp t,@rr2                         ! 12fc: 1e28
	.long_addr
	ldb rh1,0x1000302                 ! 12fe: 600181000302
	.long_addr
	resb 0x1000354,#0x0               ! 1304: 620081000354
	calr L_12ca                       ! 130a: d021
	ldb rl1,#0xf7                     ! 130c: c9f7
	inb rh0,@r1                       ! 130e: 3c10
	ldb rl1,#0xff                     ! 1310: c9ff
	outb @r1,rl1                      ! 1312: 3e19
	ei vi                             ! 1314: 7c05
	bitb rh0,#0x1                     ! 1316: a601
	jr ne,L_137c                      ! 1318: ee31
	.long_addr
	ld r3,0x1000352                   ! 131a: 610381000352
	jp t,@rr2                         ! 1320: 1e28
L_1322:
	.long_addr
	resb 0x1000354,#0x3               ! 1322: 620381000354
	.long_addr
	resb 0x1000354,#0x7               ! 1328: 620781000354
	calr L_12ca                       ! 132e: d033
	.long_addr
	resb 0x100034e,#0x5               ! 1330: 62058100034e
	.long_addr
	resb 0x100034e,#0x6               ! 1336: 62068100034e
	jr t,L_1362                       ! 133c: e812
L_133e:
	.long_addr
	ldb rl2,0x100034e                 ! 133e: 600a8100034e
	.long_addr
	ldb rl3,0x1000303                 ! 1344: 600b81000303
	and r3,#0x1                       ! 134a: 07030001
	inc r3,#0x5                       ! 134e: a934
	set r2,r3                         ! 1350: 25030200
	.long_addr
	ldb 0x100034e,rl2                 ! 1354: 6e0a8100034e
	jr t,L_1362                       ! 135a: e803
L_135c:
	.long_addr
	set 0x100034a,#0x3                ! 135c: 65038100034a
L_1362:
	calr L_146e                       ! 1362: df7b
L_1364:
	di vi                             ! 1364: 7c01
	.long_addr
	resb 0x100034e,#0x4               ! 1366: 62048100034e
	.long_addr
	setb 0x1000354,#0x0               ! 136c: 640081000354
	calr L_12ca                       ! 1372: d055
L_1374:
	popl rr8,@rr14                    ! 1374: 95e8
	popl rr2,@rr14                    ! 1376: 95e2
	popl rr0,@rr14                    ! 1378: 95e0
	iret                              ! 137a: 7b00
L_137c:
	bitb rh0,#0x2                     ! 137c: a602
	jr eq,L_1386                      ! 137e: e603
	.long_addr
	set 0x100034a,#0x0                ! 1380: 65008100034a
L_1386:
	bitb rh0,#0x3                     ! 1386: a603
	jr eq,L_1390                      ! 1388: e603
	.long_addr
	set 0x100034a,#0x0                ! 138a: 65008100034a
L_1390:
	ldb rl1,#0x1d                     ! 1390: c91d
	inb rl0,@r1                       ! 1392: 3c18
	bitb rl0,#0x5                     ! 1394: a685
	jr ne,L_13c2                      ! 1396: ee15
	bitb rl0,#0x4                     ! 1398: a684
	jr ne,L_13ee                      ! 139a: ee29
L_139c:
	calr L_1150                       ! 139c: d127
	jr c/ult,L_1322                   ! 139e: e7c1
	ldb rl0,#0x8                      ! 13a0: c808
	outb @r1,rl0                      ! 13a2: 3e18
	calr L_1442                       ! 13a4: dfb2
	jr c/ult,L_1322                   ! 13a6: e7bd
	.long_addr
	ldb rl0,0x100033a                 ! 13a8: 60088100033a
	bitb rl0,#0x7                     ! 13ae: a687
	jr eq,L_13ca                      ! 13b0: e60c
	bitb rl0,#0x6                     ! 13b2: a686
	jr eq,L_1364                      ! 13b4: e6d7
	bitb rl0,#0x3                     ! 13b6: a683
	jr eq,L_13be                      ! 13b8: e602
L_13ba:
	calr L_149a                       ! 13ba: df91
	jr t,L_139c                       ! 13bc: e8ef
L_13be:
	calr L_1480                       ! 13be: dfa0
	jr t,L_139c                       ! 13c0: e8ed
L_13c2:
	.long_addr
	set 0x100034a,#0x0                ! 13c2: 65008100034a
	jr t,L_1374                       ! 13c8: e8d5
L_13ca:
	push @rr14,r0                     ! 13ca: 93e0
	and r0,#0x3                       ! 13cc: 07000003
	.long_addr
	ldb rl2,0x100034e                 ! 13d0: 600a8100034e
	resb rl2,r0                       ! 13d6: 22000a00
	.long_addr
	ldb 0x100034e,rl2                 ! 13da: 6e0a8100034e
	pop r0,@rr14                      ! 13e0: 97e0
	bitb rl0,#0x6                     ! 13e2: a686
	jr eq,L_13be                      ! 13e4: e6ec
	.long_addr
	set 0x100034a,#0x9                ! 13e6: 65098100034a
	jr t,L_13ba                       ! 13ec: e8e6
L_13ee:
	calr L_1442                       ! 13ee: dfd7
	.long_addr
	ld r0,0x100034a                   ! 13f0: 61008100034a
	.long_addr
	ldb rl2,0x100033a                 ! 13f6: 600a8100033a
	bitb rl2,#0x3                     ! 13fc: a6a3
	jr eq,L_1402                      ! 13fe: e601
	set r0,#0x1                       ! 1400: a501
L_1402:
	.long_addr
	ldb rl2,0x100033b                 ! 1402: 600a8100033b
	bitb rl2,#0x5                     ! 1408: a6a5
	jr eq,L_140e                      ! 140a: e601
	set r0,#0x2                       ! 140c: a502
L_140e:
	bitb rl2,#0x4                     ! 140e: a6a4
	jr eq,L_1414                      ! 1410: e601
	set r0,#0x0                       ! 1412: a500
L_1414:
	bitb rl2,#0x2                     ! 1414: a6a2
	jr eq,L_141a                      ! 1416: e601
	set r0,#0x2                       ! 1418: a502
L_141a:
	bitb rl2,#0x1                     ! 141a: a6a1
	jr eq,L_1420                      ! 141c: e601
	set r0,#0x5                       ! 141e: a505
L_1420:
	bitb rl2,#0x0                     ! 1420: a6a0
	jr eq,L_1426                      ! 1422: e601
	set r0,#0x2                       ! 1424: a502
L_1426:
	.long_addr
	ldb rl2,0x100033c                 ! 1426: 600a8100033c
	bit r2,#0x6                       ! 142c: a726
	jr eq,L_1432                      ! 142e: e601
	set r0,#0x6                       ! 1430: a506
L_1432:
	and r2,#0x12                      ! 1432: 07020012
	jr eq,L_143a                      ! 1436: e601
	set r0,#0x2                       ! 1438: a502
L_143a:
	.long_addr
	ld 0x100034a,r0                   ! 143a: 6f008100034a
	jr t,L_1362                       ! 1440: e890
L_1442:
	.long_addr
	lda rr2,0x100033a                 ! 1442: 76028100033a
	ld r8,#0x8                        ! 1448: 21080008
L_144c:
	ldb rl1,#0x20                     ! 144c: c920
L_144e:
	dbjnz rl1,L_144e                  ! 144e: f901
	ldb rl1,#0x1d                     ! 1450: c91d
	inb rl0,@r1                       ! 1452: 3c18
	bitb rl0,#0x4                     ! 1454: a684
	resflg c                          ! 1456: 8d83
	ret eq                            ! 1458: 9e06
	calr L_113a                       ! 145a: d191
	ret c/ult                         ! 145c: 9e07
	inib @rr2,@r1,r8                  ! 145e: 3a100828
	jr nov/po,L_144c                  ! 1462: ecf4
	setflg c                          ! 1464: 8d81
	.long_addr
	set 0x100034a,#0x0                ! 1466: 65008100034a
	ret t                             ! 146c: 9e08
L_146e:
	ldb rl1,#0x9f                     ! 146e: c99f   reg 0x9f = 0x50
	ldb rl0,#0x50                     ! 1470: c850
	outb @r1,rl0                      ! 1472: 3e18
	ld r0,#0x13c2                     ! 1474: 210013c2
	.long_addr
	ld 0x1000352,r0                   ! 1478: 6f0081000352   retry vector <<1>>0x0352 = 0x13c2
	ret t                             ! 147e: 9e08
L_1480:
	calr L_14a2                       ! 1480: dff0
	or r0,r0                          ! 1482: 8500
	jr ne,L_148e                      ! 1484: ee04
	ldb rl1,#0xed                     ! 1486: c9ed
	inb rh2,@r1                       ! 1488: 3c12
	bitb rh2,#0x0                     ! 148a: a620
	ret ne                            ! 148c: 9e0e
L_148e:
	set r2,r0                         ! 148e: 25000200
L_1492:
	.long_addr
	ldb 0x100034d,rl2                 ! 1492: 6e0a8100034d
	ret t                             ! 1498: 9e08
L_149a:
	calr L_14a2                       ! 149a: dffd
	res r2,r0                         ! 149c: 23000200
	jr t,L_1492                       ! 14a0: e8f8
L_14a2:
	.long_addr
	ldb rl2,0x100034d                 ! 14a2: 600a8100034d
	and r0,#0x3                       ! 14a8: 07000003
	ret t                             ! 14ac: 9e08

!------------------------------------------------------------------------------
! Build a uPD765 READ DATA command block at <<1>>0x0320 from a 10-byte template
! (0x17dc = format A, 0x17e6 = format B), patched with the drive number.
!------------------------------------------------------------------------------
	pushl @rr14,rr0                   ! 14ae: 91e0   [build read command]
	pushl @rr14,rr6                   ! 14b0: 91e6
	pushl @rr14,rr8                   ! 14b2: 91e8
	.long_addr
	clr 0x100034a                     ! 14b4: 4d088100034a
	.long_addr
	ldb 0x1000303,rl0                 ! 14ba: 6e0881000303
	calr L_1116                       ! 14c0: d1d6   init the FDC (0x1116)
	ldar rr8,L_1614                   ! 14c2: 3408014e
	.long_addr
	test 0x100034a                    ! 14c6: 4d048100034a
	jp ne,@rr8                        ! 14cc: 1e8e
	calr L_12da                       ! 14ce: d0fb
	ld r0,#0x800                      ! 14d0: 21000800   format A: count 0x0800, template 0x17dc
	ldar rr6,L_17dc                   ! 14d4: 34060304
	jr eq,L_14e2                      ! 14d8: e604
	ld r0,#0xd00                      ! 14da: 21000d00   format B: count 0x0d00, template 0x17e6
	ldar rr6,L_17e6                   ! 14de: 34060304
L_14e2:
	.long_addr
	lda rr8,0x1000320                 ! 14e2: 760881000320   cmd buffer at <<1>>0x0320
	ld r1,#0xa                        ! 14e8: 2101000a
	ldirb @rr8,@rr6,r1                ! 14ec: ba610180   copy the 10-byte uPD765 READ template
	.long_addr
	lda rr8,0x1000320                 ! 14f0: 760881000320
	.long_addr
	ldb rl1,0x1000303                 ! 14f6: 600981000303   patch drive #
	ldb rr8(#0x2),rl1                 ! 14fc: 32890002
	.long_addr
	clrb 0x1000338                    ! 1500: 4c0881000338
	.long_addr
	clrb 0x1000339                    ! 1506: 4c0881000339
	calr L_10ce                       ! 150c: d220
	.long_addr
	jp c/ult,0x1614                   ! 150e: 5e0780001614
	ldb rl0,rr2(#0x347)               ! 1514: 30280347
	cpb rl0,#0x20                     ! 1518: 0a082020
	ldb rh0,#0x0                      ! 151c: c000
	jr eq,L_153a                      ! 151e: e60d
	cpb rl0,#0x31                     ! 1520: 0a083131
	jr eq,L_153a                      ! 1524: e60a
	cpb rl0,#0x33                     ! 1526: 0a083333
	jr eq,L_1532                      ! 152a: e603
	cpb rl0,#0x4d                     ! 152c: 0a084d4d
	jr ne,L_160e                      ! 1530: ee6e
L_1532:
	.long_addr
	setb 0x1000321,#0x6               ! 1532: 640681000321
	ldb rh0,#0x40                     ! 1538: c040
L_153a:
	.long_addr
	ldb 0x1000304,rh0                 ! 153a: 6e0081000304
	ldb rl0,rr2(#0x34b)               ! 1540: 3028034b
	ldb rh0,#0x0                      ! 1544: c000
	cpb rl0,#0x20                     ! 1546: 0a082020
	jr eq,L_155a                      ! 154a: e607
	cpb rl0,#0x30                     ! 154c: 0a083030
	jr eq,L_155a                      ! 1550: e604
	ldb rh0,#0x1                      ! 1552: c001
	cpb rl0,#0x31                     ! 1554: 0a083131
	jr ne,L_160e                      ! 1558: ee5a
L_155a:
	.long_addr
	ldb 0x1000305,rh0                 ! 155a: 6e0081000305
	.long_addr
	ldb 0x1000326,rh0                 ! 1560: 6e0081000326
	calr L_12da                       ! 1566: d147
	jr ne,L_1588                      ! 1568: ee0f
	ldb rl0,rr2(#0x347)               ! 156a: 30280347
	cpb rl0,#0x33                     ! 156e: 0a083333
	ldb rl1,#0x4e                     ! 1572: c94e
	jr eq,L_1578                      ! 1574: e601
	ldb rl1,#0x26                     ! 1576: c926
L_1578:
	.long_addr
	bitb 0x1000304,#0x6               ! 1578: 660681000304
	ldb rl0,#0x20                     ! 157e: c820
	ldb rh0,#0x10                     ! 1580: c010
	jr ne,L_15a4                      ! 1582: ee10
	ldb rl0,#0x9                      ! 1584: c809
	jr t,L_15a4                       ! 1586: e80e
L_1588:
	ldb rl1,#0x4b                     ! 1588: c94b
	ldb rl0,#0x34                     ! 158a: c834
	ldb rh0,#0xe                      ! 158c: c00e
	.long_addr
	bitb 0x1000304,#0x6               ! 158e: 660681000304
	jr ne,L_15a4                      ! 1594: ee07
	ldb rl0,#0xf                      ! 1596: c80f
	.long_addr
	bitb 0x1000305,#0x0               ! 1598: 660081000305
	jr ne,L_15a4                      ! 159e: ee02
	ldb rl0,#0x1a                     ! 15a0: c81a
	ldb rh0,#0x7                      ! 15a2: c007
L_15a4:
	.long_addr
	ldb 0x1000307,rl1                 ! 15a4: 6e0981000307
	.long_addr
	ldb 0x1000306,rl0                 ! 15aa: 6e0881000306
	.long_addr
	ldb 0x1000328,rh0                 ! 15b0: 6e0081000328
	cpb rl0,#0x1c                     ! 15b6: 0a081c1c
	jr c/ult,L_15c0                   ! 15ba: e702
	.word	0xb281		! 15bc: srlb rl0,#0x1
	.word	0xffff		! 15be: srlb rl0,#0x1
L_15c0:
	.long_addr
	ldb 0x1000327,rl0                 ! 15c0: 6e0881000327
	ldb rl0,rr2(#0x208)               ! 15c6: 30280208
	cpb rl0,#0x20                     ! 15ca: 0a082020
	jr eq,L_15fe                      ! 15ce: e617
	ldb rh0,rr2(#0x206)               ! 15d0: 30200206
	ldb rl0,rr2(#0x207)               ! 15d4: 30280207
	calr L_1618                       ! 15d8: dfe1
	jr c/ult,L_160e                   ! 15da: e719
	.long_addr
	ldb 0x1000338,rl0                 ! 15dc: 6e0881000338
	ldb rl0,rr2(#0x20c)               ! 15e2: 3028020c
	cpb rl0,#0x20                     ! 15e6: 0a082020
	jr eq,L_15fe                      ! 15ea: e609
	ldb rh0,rr2(#0x20a)               ! 15ec: 3020020a
	ldb rl0,rr2(#0x20b)               ! 15f0: 3028020b
	calr L_1618                       ! 15f4: dfef
	jr c/ult,L_160e                   ! 15f6: e70b
	.long_addr
	ldb 0x1000339,rl0                 ! 15f8: 6e0881000339
L_15fe:
	resflg c                          ! 15fe: 8d83
L_1600:
	popl rr8,@rr14                    ! 1600: 95e8
	popl rr6,@rr14                    ! 1602: 95e6
	popl rr0,@rr14                    ! 1604: 95e0
	.long_addr
	ld r7,0x100034a                   ! 1606: 61078100034a
	ret t                             ! 160c: 9e08
L_160e:
	.long_addr
	set 0x100034a,#0x8                ! 160e: 65088100034a
L_1614:
	setflg c                          ! 1614: 8d81
	jr t,L_1600                       ! 1616: e8f4
L_1618:
	calr L_1634                       ! 1618: dff3
	ret c/ult                         ! 161a: 9e07
	exb rh0,rl0                       ! 161c: ac80
	calr L_1634                       ! 161e: dff6
	ret c/ult                         ! 1620: 9e07
	exb rh0,rl0                       ! 1622: ac80
	and r0,#0xf0f                     ! 1624: 07000f0f
L_1628:
	orb rh0,rh0                       ! 1628: 8400
	ret eq                            ! 162a: 9e06
	addb rl0,#0xa                     ! 162c: 00080a0a
	decb rh0,#0x1                     ! 1630: aa00
	jr t,L_1628                       ! 1632: e8fa
L_1634:
	cpb rl0,#0x30                     ! 1634: 0a083030
	ret c/ult                         ! 1638: 9e07
	cpb rl0,#0x3a                     ! 163a: 0a083a3a
	comflg c                          ! 163e: 8d85
	ret t                             ! 1640: 9e08
	pushl @rr14,rr0                   ! 1642: 91e0
	pushl @rr14,rr2                   ! 1644: 91e2
	pushl @rr14,rr4                   ! 1646: 91e4
	pushl @rr14,rr6                   ! 1648: 91e6
	pushl @rr14,rr8                   ! 164a: 91e8
	pushl @rr14,rr10                  ! 164c: 91ea
	pushl @rr14,rr12                  ! 164e: 91ec
	.long_addr
	lda rr4,0x1000366                 ! 1650: 760481000366
	ld r0,#0x9                        ! 1656: 21000009
	ldirb @rr4,@rr2,r0                ! 165a: ba210040
	calr L_16ac                       ! 165e: dfda
	popl rr12,@rr14                   ! 1660: 95ec
	popl rr10,@rr14                   ! 1662: 95ea
	popl rr8,@rr14                    ! 1664: 95e8
	popl rr6,@rr14                    ! 1666: 95e6
	popl rr4,@rr14                    ! 1668: 95e4
	popl rr2,@rr14                    ! 166a: 95e2
	popl rr0,@rr14                    ! 166c: 95e0
	.long_addr
	ld r7,0x100034a                   ! 166e: 61078100034a
	setflg c                          ! 1674: 8d81
	or r7,r7                          ! 1676: 8577
	ret ne                            ! 1678: 9e0e
	resflg c                          ! 167a: 8d83
	ret t                             ! 167c: 9e08
L_167e:
	.long_addr
	cpb 0x1000306,#0x1c               ! 167e: 4c0181000306
	jr nc/uge,L_1690                  ! 1686: ef04
L_1688:
	ld r0,r1                          ! 1688: a110
	calr L_1774                       ! 168a: df8c
	jr nc/uge,L_16ac                  ! 168c: ef0f
	ret t                             ! 168e: 9e08
L_1690:
	.long_addr
	cpb 0x100036d,#0x0                ! 1690: 4c018100036d
	jr ne,L_1688                      ! 1698: eef7
	.long_addr
	setb 0x1000321,#0x7               ! 169a: 640781000321
	add r1,r4                         ! 16a0: 8141
	cp r0,r1                          ! 16a2: 8b10
	jr ugt,L_1688                     ! 16a4: ebf1
	or r0,r0                          ! 16a6: 8500
	jr eq,L_1688                      ! 16a8: e6ef
	jr t,L_1774                       ! 16aa: e864
L_16ac:
	.long_addr
	lda rr8,0x1000320                 ! 16ac: 760881000320
	ldb rl0,rr8(#0x1)                 ! 16b2: 30880001
	.long_addr
	ldb 0x100036f,rl0                 ! 16b6: 6e088100036f
	.long_addr
	cpb 0x100036c,#0x0                ! 16bc: 4c018100036c
	jr ne,L_1734                      ! 16c4: ee37
	.long_addr
	cpb 0x100036d,#0x0                ! 16c6: 4c018100036d
	jr ne,L_1734                      ! 16ce: ee32
	ldar rr2,L_17dc                   ! 16d0: 34020108
	calr L_12da                       ! 16d4: d1fe
	jr eq,L_16dc                      ! 16d6: e602
	ldar rr2,L_17e6                   ! 16d8: 3402010a
L_16dc:
	sub r1,r1                         ! 16dc: 8311
	ldb rl1,rr2(#0x7)                 ! 16de: 30290007
	.long_addr
	ldb rl0,0x100036e                 ! 16e2: 60088100036e
	decb rl0,#0x1                     ! 16e8: aa80
	subb rl1,rl0                      ! 16ea: 8289
	sll r1,#0x7                       ! 16ec: b3110007
	.long_addr
	ld r0,0x100036a                   ! 16f0: 61008100036a
	or r0,r0                          ! 16f6: 8500
	jr eq,L_1712                      ! 16f8: e60c
	cp r0,r1                          ! 16fa: 8b10
	jr ugt,L_1712                     ! 16fc: eb0a
	ldl rr8,rr2                       ! 16fe: 9428
	.long_addr
	ldb rl1,0x100036f                 ! 1700: 60098100036f
	andb rl1,#0x1f                    ! 1706: 06091f1f
	ldb rr8(#0x1),rl1                 ! 170a: 32890001
	calr L_1774                       ! 170e: dfce
	ret t                             ! 1710: 9e08
L_1712:
	ld r0,r1                          ! 1712: a110
	ldl rr8,rr2                       ! 1714: 9428
	calr L_1774                       ! 1716: dfd2
	ret c/ult                         ! 1718: 9e07
	.long_addr
	cpb 0x1000304,#0x0                ! 171a: 4c0181000304
	jr eq,L_16ac                      ! 1722: e6c4
	.long_addr
	decb 0x100036c,#0x1               ! 1724: 6a008100036c
	.long_addr
	ldb 0x100036d,#0x1                ! 172a: 4c058100036d
	jr t,L_16ac                       ! 1732: e8bc
L_1734:
	sub r4,r4                         ! 1734: 8344
	ldb rl4,rr8(#0x7)                 ! 1736: 308c0007
	ld r1,r4                          ! 173a: a141
	.long_addr
	ldb rl0,0x100036e                 ! 173c: 60088100036e
	decb rl0,#0x1                     ! 1742: aa80
	subb rl1,rl0                      ! 1744: 8289
	sll r1,#0x7                       ! 1746: b3110007
	sll r4,#0x7                       ! 174a: b3410007
	.long_addr
	cpb 0x1000326,#0x0                ! 174e: 4c0181000326
	jr eq,L_1760                      ! 1756: e604
	sll r1,#0x1                       ! 1758: b3110001
	sll r4,#0x1                       ! 175c: b3410001
L_1760:
	.long_addr
	resb 0x1000321,#0x7               ! 1760: 620781000321
	.long_addr
	ld r0,0x100036a                   ! 1766: 61008100036a
	or r0,r0                          ! 176c: 8500
	jr eq,L_167e                      ! 176e: e687
	cp r0,r1                          ! 1770: 8b10
	jr ugt,L_167e                     ! 1772: eb85
L_1774:
	.long_addr
	ldb rl1,0x1000303                 ! 1774: 600981000303
	.long_addr
	ldb rh1,0x100036d                 ! 177a: 60018100036d
	ldb rr8(#0x4),rh1                 ! 1780: 32810004
	sllb rh1,#0x2                     ! 1784: b2110002
	orb rl1,rh1                       ! 1788: 8419
	ldb rr8(#0x2),rl1                 ! 178a: 32890002
	.long_addr
	ldb rl1,0x100036e                 ! 178e: 60098100036e
	ldb rr8(#0x5),rl1                 ! 1794: 32890005
	.long_addr
	ldb rl1,0x100036c                 ! 1798: 60098100036c
	ldb rr8(#0x3),rl1                 ! 179e: 32890003
	.long_addr
	incb 0x100036c,#0x1               ! 17a2: 68008100036c
	.long_addr
	clrb 0x100036d                    ! 17a8: 4c088100036d
	.long_addr
	ldb 0x100036e,#0x1                ! 17ae: 4c058100036e
	.long_addr
	ld r1,0x100036a                   ! 17b6: 61018100036a
	sub r1,r0                         ! 17bc: 8301
	.long_addr
	ld 0x100036a,r1                   ! 17be: 6f018100036a
	.long_addr
	ldl rr2,0x1000366                 ! 17c4: 540281000366
	ldl rr4,rr2                       ! 17ca: 9424
	add r5,r0                         ! 17cc: 8105
	jr nc/uge,L_17d2                  ! 17ce: ef01
	incb rh4,#0x1                     ! 17d0: a840
L_17d2:
	.long_addr
	ldl 0x1000366,rr4                 ! 17d2: 5d0481000366
	calr L_1080                       ! 17d8: d3ad
	ret t                             ! 17da: 9e08

! ---- 0x17dc .. 0x17f0  (word) ----
! uPD765 READ DATA command templates (10 bytes): count, 06=READ, HDUS, C, H,
! R=1, N, EOT, GPL, DTL.  Two disk formats: 0x17dc EOT=0x10/GPL=0x10,
! 0x17e6 EOT=0x1a/GPL=0x07.  Read starts at cylinder 0, head 0, sector 1.
L_17dc:
	.word	0x0906
	.word	0x0000
	.word	0x0001
	.word	0x0010
	.word	0x10ff
L_17e6:
	.word	0x0906
	.word	0x0000
	.word	0x0001
	.word	0x001a
	.word	0x07ff

! ---- 0x17f0 .. 0x1fae  (code) ----
	pushl @rr14,rr0                   ! 17f0: 91e0
	pushl @rr14,rr2                   ! 17f2: 91e2
	pushl @rr14,rr4                   ! 17f4: 91e4
	push @rr14,r6                     ! 17f6: 93e6
	pushl @rr14,rr8                   ! 17f8: 91e8
	pushl @rr14,rr10                  ! 17fa: 91ea
	pushl @rr14,rr12                  ! 17fc: 91ec
	.long_addr
	ldb 0x1000316,rl7                 ! 17fe: 6e0f81000316
	.long_addr
	ldb rh2,0x1000302                 ! 1804: 600281000302
	ldb rl3,#0x10                     ! 180a: cb10
L_180c:
	ldk r0,#0x5                       ! 180c: bd05
	.long_addr
	call 0xde4                        ! 180e: 5f0080000de4
L_1814:
	in r1,@r2                         ! 1814: 3d21
	bitb rh1,#0x0                     ! 1816: a610
	jr eq,L_1828                      ! 1818: e607
	.long_addr
	testb 0x100030f                   ! 181a: 4c048100030f
	jr ne,L_1814                      ! 1820: eef9
	.long_addr
	jp t,0x19e8                       ! 1822: 5e08800019e8
L_1828:
	ldb rl1,#0xc0                     ! 1828: c9c0
	outb @r2,rl1                      ! 182a: 3e29
	ldb rl0,#0x50                     ! 182c: c850
L_182e:
	decb rl0,#0x1                     ! 182e: aa80
	jr ne,L_182e                      ! 1830: eefe
	in r1,@r2                         ! 1832: 3d21
	andb rh1,#0xf                     ! 1834: 06010f0f
	cpb rh1,#0x1                      ! 1838: 0a010101
	jr eq,L_1846                      ! 183c: e604
	dbjnz rl3,L_180c                  ! 183e: fb1a
	.long_addr
	jp t,0x19e8                       ! 1840: 5e08800019e8
L_1846:
	ldk r0,#0x5                       ! 1846: bd05
	.long_addr
	call 0xde4                        ! 1848: 5f0080000de4
L_184e:
	in r1,@r2                         ! 184e: 3d21
	andb rh1,#0xf                     ! 1850: 06010f0f
	cpb rh1,#0x2                      ! 1854: 0a010202
	jr eq,L_1868                      ! 1858: e607
	.long_addr
	testb 0x100030f                   ! 185a: 4c048100030f
	jr ne,L_184e                      ! 1860: eef6
	.long_addr
	jp t,0x19e8                       ! 1862: 5e08800019e8
L_1868:
	ldb rl1,#0x55                     ! 1868: c955
	ldb rh1,#0x6                      ! 186a: c106
	calr L_1bc0                       ! 186c: de57
	.long_addr
	jp eq,0x19e8                      ! 186e: 5e06800019e8
	.long_addr
	ldb rl1,0x1000316                 ! 1874: 600981000316
	ldb rh1,#0x6                      ! 187a: c106
	calr L_1bc0                       ! 187c: de5f
	.long_addr
	jp eq,0x19e8                      ! 187e: 5e06800019e8
	ldb rl1,#0xaa                     ! 1884: c9aa
	ldb rh1,#0x4                      ! 1886: c104
	calr L_1bc0                       ! 1888: de65
	.long_addr
	jp eq,0x19e8                      ! 188a: 5e06800019e8
	.long_addr
	lda rr4,0x10001c0                 ! 1890: 7604810001c0
	clrb rh1                          ! 1896: 8c18
	.long_addr
	ldb rl1,0x1000316                 ! 1898: 600981000316
	add r1,r1                         ! 189e: 8111
	add r5,r1                         ! 18a0: 8115
	ldb rh2,#0x8                      ! 18a2: c208
	ldar rr6,L_1cf8                   ! 18a4: 34060450
L_18a8:
	ldl @rr4,rr6                      ! 18a8: 1d46
	inc r5,#0x4                       ! 18aa: a953
	dbjnz rh2,L_18a8                  ! 18ac: f203
	ldb rl1,#0x80                     ! 18ae: c980
	ldb rh1,#0x6                      ! 18b0: c106
	calr L_1bc0                       ! 18b2: de7a
	.long_addr
	jp eq,0x19e8                      ! 18b4: 5e06800019e8
	.long_addr
	ldb rl1,0x1000316                 ! 18ba: 600981000316
	ldb rh1,#0x6                      ! 18c0: c106
	calr L_1bc0                       ! 18c2: de82
	.long_addr
	jp eq,0x19e8                      ! 18c4: 5e06800019e8
	.long_addr
	ldb rl3,0x1000316                 ! 18ca: 600b81000316
	ldb rh3,#0xaa                     ! 18d0: c3aa
	ldb rl1,#0xaa                     ! 18d2: c9aa
	ldb rh1,#0x4                      ! 18d4: c104
	calr L_1bc0                       ! 18d6: de8c
	.long_addr
	jp eq,0x19e8                      ! 18d8: 5e06800019e8
	cp r3,r4                          ! 18de: 8b43
	.long_addr
	jp ne,0x19e8                      ! 18e0: 5e0e800019e8
	ldb rl0,#0x8                      ! 18e6: c808
	ldl rr6,#0x81000318               ! 18e8: 140681000318
	ldl rr2,#0x81000338               ! 18ee: 140281000338
	.long_addr
	call 0xa70                        ! 18f4: 5f0080000a70
L_18fa:
	ldl @rr6,rr2                      ! 18fa: 1d62
	add r3,#0x18                      ! 18fc: 01030018
	inc r7,#0x4                       ! 1900: a973
	dbjnz rl0,L_18fa                  ! 1902: f805
	ldl rr6,#0x81000338               ! 1904: 140681000338
	ldb rl3,#0x60                     ! 190a: cb60
L_190c:
	tset @rr6                         ! 190c: 0d66
	inc r7,#0x2                       ! 190e: a971
	dbjnz rl3,L_190c                  ! 1910: fb03
	ldb rl1,#0xa0                     ! 1912: c9a0
	ldb rh1,#0x6                      ! 1914: c106
	calr L_1bc0                       ! 1916: deac
	jr eq,L_19e8                      ! 1918: e667
	ldl rr2,#0x81000318               ! 191a: 140281000318
	.long_addr
	call 0xa70                        ! 1920: 5f0080000a70
	ldb rl1,rl2                       ! 1926: a0a9
	ldb rh1,#0x6                      ! 1928: c106
	calr L_1bc0                       ! 192a: deb6
	jr eq,L_19e8                      ! 192c: e65d
	ldb rl1,rh3                       ! 192e: a039
	ldb rh1,#0x6                      ! 1930: c106
	calr L_1bc0                       ! 1932: deba
	jr eq,L_19e8                      ! 1934: e659
	ldb rl1,rl3                       ! 1936: a0b9
	ldb rh1,#0x6                      ! 1938: c106
	calr L_1bc0                       ! 193a: debe
	jr eq,L_19e8                      ! 193c: e655
	ldb rl1,#0x8                      ! 193e: c908
	ldb rh1,#0x8                      ! 1940: c108
	calr L_1bc0                       ! 1942: dec2
	jr eq,L_19e8                      ! 1944: e651
	ldl rr4,#0x81000270               ! 1946: 140481000270
	ldb rl2,#0x7                      ! 194c: ca07
L_194e:
	clrb @rr4                         ! 194e: 0c48
	inc r5,#0x1                       ! 1950: a950
	dbjnz rl2,L_194e                  ! 1952: fa03
	ldb rl0,#0x1e                     ! 1954: c81e
	.long_addr
	call 0xe76                        ! 1956: 5f0080000e76
	incb rl0,#0x4                     ! 195c: a883
	.long_addr
	call 0xde4                        ! 195e: 5f0080000de4
L_1964:
	.long_addr
	testb 0x100030f                   ! 1964: 4c048100030f
	jr ne,L_1964                      ! 196a: eefc
	ldl rr6,#0x81000338               ! 196c: 140681000338
	add r7,#0x18                      ! 1972: 01070018
	.long_addr
	ldl 0x1000310,rr6                 ! 1976: 5d0681000310
	ldl rr4,#0x81000270               ! 197c: 140481000270
	ldb rl2,#0x7                      ! 1982: ca07
L_1984:
	testb @rr4                        ! 1984: 0c44
	jr ne,L_19dc                      ! 1986: ee2a
	bit @rr6,#0x8                     ! 1988: 2768
	jr eq,L_19dc                      ! 198a: e628
	ld r3,#0x500                      ! 198c: 21030500
	ld rr6(#0x8),r3                   ! 1990: 33630008
	ldk r1,#0x8                       ! 1994: bd18
	subb rl1,rl2                      ! 1996: 82a9
	or r1,#0x10                       ! 1998: 05010010
	calr L_1c8c                       ! 199c: de89
	calr L_1c8c                       ! 199e: de8a
	jr eq,L_19e8                      ! 19a0: e623
	.long_addr
	ldl rr6,0x1000310                 ! 19a2: 540681000310
	ldb rh0,rr6(#0x2)                 ! 19a8: 30600002
	bitb rh0,#0x4                     ! 19ac: a604
	jr eq,L_19ba                      ! 19ae: e605
	.long_addr
	ldl rr4,0x1000310                 ! 19b0: 540481000310
	calr L_1d02                       ! 19b6: de5b
	jr t,L_19ea                       ! 19b8: e818
L_19ba:
	ld r3,rr6(#0x16)                  ! 19ba: 31630016
	bitb rl3,#0x4                     ! 19be: a6b4
	jr ne,L_19cc                      ! 19c0: ee05
	ldb rl3,rh3                       ! 19c2: a03b
	andb rl3,#0xf                     ! 19c4: 060b0f0f
	incb rl3,#0x2                     ! 19c8: a8b1
	jr t,L_19da                       ! 19ca: e807
L_19cc:
	ldb @rr4,#0x1                     ! 19cc: 0c450101
	add r7,#0x18                      ! 19d0: 01070018
	inc r5,#0x1                       ! 19d4: a950
	decb rl2,#0x1                     ! 19d6: aaa0
	ldb rl3,#0x2                      ! 19d8: cb02
L_19da:
	ldb @rr4,rl3                      ! 19da: 2e4b
L_19dc:
	add r7,#0x18                      ! 19dc: 01070018
	inc r5,#0x1                       ! 19e0: a950
	dbjnz rl2,L_1984                  ! 19e2: fa30
	clr r7                            ! 19e4: 8d78
	jr t,L_19ea                       ! 19e6: e801
L_19e8:
	ldk r7,#0x1                       ! 19e8: bd71
L_19ea:
	popl rr12,@rr14                   ! 19ea: 95ec
	popl rr10,@rr14                   ! 19ec: 95ea
	popl rr8,@rr14                    ! 19ee: 95e8
	pop r6,@rr14                      ! 19f0: 97e6
	popl rr4,@rr14                    ! 19f2: 95e4
	popl rr2,@rr14                    ! 19f4: 95e2
	popl rr0,@rr14                    ! 19f6: 95e0
	ret t                             ! 19f8: 9e08
	pushl @rr14,rr0                   ! 19fa: 91e0
	pushl @rr14,rr4                   ! 19fc: 91e4
	push @rr14,r6                     ! 19fe: 93e6
	.long_addr
	lda rr4,0x1000338                 ! 1a00: 760481000338
	clrb rh1                          ! 1a06: 8c18
	.long_addr
	ldb rl1,0x1000303                 ! 1a08: 600981000303
	mult rr0,#0x18                    ! 1a0e: 19000018
	add r5,r1                         ! 1a12: 8115
	.long_addr
	ldl 0x1000310,rr4                 ! 1a14: 5d0481000310
	calr L_1bfa                       ! 1a1a: df11
	ldk r7,#0x1                       ! 1a1c: bd71
	jr c/ult,L_1a56                   ! 1a1e: e71b
	clr r0                            ! 1a20: 8d08
	ld r1,rr2(#0x6)                   ! 1a22: 31210006
	mult rr0,r5                       ! 1a26: 9950
	clrb rh7                          ! 1a28: 8c78
	ldb rl7,rr2(#0x8)                 ! 1a2a: 302f0008
	add r1,r7                         ! 1a2e: 8171
	mult rr0,r6                       ! 1a30: 9960
	clr r6                            ! 1a32: 8d68
	clrb rh7                          ! 1a34: 8c78
	ldb rl7,rr2(#0x9)                 ! 1a36: 302f0009
	addl rr0,rr6                      ! 1a3a: 9660
	.long_addr
	ldl rr4,0x1000310                 ! 1a3c: 540481000310
	ldb rr4(#0xa),rl0                 ! 1a42: 3248000a
	ldb rr4(#0xb),rh1                 ! 1a46: 3241000b
	ldb rr4(#0xc),rl1                 ! 1a4a: 3249000c
	clrb rh0                          ! 1a4e: 8c08
	ldb rr4(#0xd),rh0                 ! 1a50: 3240000d
	calr L_1a9e                       ! 1a54: dfdc
L_1a56:
	pop r6,@rr14                      ! 1a56: 97e6
	popl rr4,@rr14                    ! 1a58: 95e4
	popl rr0,@rr14                    ! 1a5a: 95e0
	ret t                             ! 1a5c: 9e08
	pushl @rr14,rr0                   ! 1a5e: 91e0
	pushl @rr14,rr2                   ! 1a60: 91e2
	pushl @rr14,rr4                   ! 1a62: 91e4
	.long_addr
	lda rr4,0x1000338                 ! 1a64: 760481000338
	clrb rh1                          ! 1a6a: 8c18
	.long_addr
	ldb rl1,0x1000303                 ! 1a6c: 600981000303
	mult rr0,#0x18                    ! 1a72: 19000018
	add r5,r1                         ! 1a76: 8115
	.long_addr
	ldl 0x1000310,rr4                 ! 1a78: 5d0481000310
	ldb rh0,rr2(#0x7)                 ! 1a7e: 30200007
	ldb rl0,rr2(#0x8)                 ! 1a82: 30280008
	ld rr4(#0xa),r0                   ! 1a86: 3340000a
	ldb rh0,rr2(#0x9)                 ! 1a8a: 30200009
	clrb rl0                          ! 1a8e: 8c88
	ld rr4(#0xc),r0                   ! 1a90: 3340000c
	calr L_1a9e                       ! 1a94: dffc
	popl rr4,@rr14                    ! 1a96: 95e4
	popl rr2,@rr14                    ! 1a98: 95e2
	popl rr0,@rr14                    ! 1a9a: 95e0
	ret t                             ! 1a9c: 9e08
L_1a9e:
	pushl @rr14,rr0                   ! 1a9e: 91e0
	pushl @rr14,rr2                   ! 1aa0: 91e2
	pushl @rr14,rr4                   ! 1aa2: 91e4
L_1aa4:
	.long_addr
	ldl 0x1000310,rr4                 ! 1aa4: 5d0481000310
	ldl rr6,@rr2                      ! 1aaa: 1426
	pushl @rr14,rr2                   ! 1aac: 91e2
	pushl @rr14,rr4                   ! 1aae: 91e4
L_1ab0:
	.long_addr
	ldar rr4,L_1ab0                   ! 1ab0: 3404fffc
	ld r5,#0xa70                      ! 1ab4: 21050a70
	ldl rr2,rr6                       ! 1ab8: 9462
	call @rr4                         ! 1aba: 1f40
	popl rr4,@rr14                    ! 1abc: 95e4
	ldl rr4(#0x4),rr2                 ! 1abe: 37420004
	popl rr2,@rr14                    ! 1ac2: 95e2
	ld r0,rr2(#0x4)                   ! 1ac4: 31200004
	testb rl0                         ! 1ac8: 8c84
	jr eq,L_1ad0                      ! 1aca: e602
	clrb rl0                          ! 1acc: 8c88
	incb rh0,#0x1                     ! 1ace: a800
L_1ad0:
	ld rr4(#0xe),r0                   ! 1ad0: 3340000e
	ldb rh0,rr2(#0xa)                 ! 1ad4: 3020000a
	orb rh0,#0x20                     ! 1ad8: 04002020
	clrb rl0                          ! 1adc: 8c88
	ld rr4(#0x8),r0                   ! 1ade: 33400008
	.long_addr
	clrb 0x1000317                    ! 1ae2: 4c0881000317
	.long_addr
	clrb 0x1000315                    ! 1ae8: 4c0881000315
L_1aee:
	.long_addr
	ldb rl1,0x1000303                 ! 1aee: 600981000303
	or r1,#0x10                       ! 1af4: 05010010
	calr L_1c8c                       ! 1af8: df37
	jr eq,L_1bb4                      ! 1afa: e65c
	ldb rh0,rr4(#0x2)                 ! 1afc: 30400002
	bitb rh0,#0x5                     ! 1b00: a605
	jr ne,L_1b16                      ! 1b02: ee09
	bitb rh0,#0x4                     ! 1b04: a604
	jr eq,L_1b30                      ! 1b06: e614
	ldb rl0,rr4(#0x11)                ! 1b08: 30480011
	cpb rl0,#0x3                      ! 1b0c: 0a080303
	jr eq,L_1aee                      ! 1b10: e6ee
	calr L_1d02                       ! 1b12: df09
	jr t,L_1bb8                       ! 1b14: e851
L_1b16:
	ld r0,rr4(#0x10)                  ! 1b16: 31400010
	bit r0,#0xe                       ! 1b1a: a70e
	jr ne,L_1b30                      ! 1b1c: ee09
	bit r0,#0x8                       ! 1b1e: a708
	jr eq,L_1b7a                      ! 1b20: e62c
	bit r0,#0x0                       ! 1b22: a700
	jr ne,L_1b3c                      ! 1b24: ee0b
	.long_addr
	tsetb 0x1000317                   ! 1b26: 4c0681000317
	jr mi,L_1b9c                      ! 1b2c: e537
	jr t,L_1aee                       ! 1b2e: e8df
L_1b30:
	.long_addr
	tsetb 0x1000315                   ! 1b30: 4c0681000315
	jr mi,L_1aa4                      ! 1b36: e5b6
	clr r7                            ! 1b38: 8d78
	jr t,L_1bb8                       ! 1b3a: e83e
L_1b3c:
	ldb rl0,rr4(#0x16)                ! 1b3c: 30480016
	cpb rl0,#0xff                     ! 1b40: 0a08ffff
	jr eq,L_1aee                      ! 1b44: e6d4
	ldb rl1,rr4(#0x17)                ! 1b46: 30490017
	clr r0                            ! 1b4a: 8d08
	clrb rh1                          ! 1b4c: 8c18
	ldl rr2,rr4(#0xa)                 ! 1b4e: 3542000a
	srll rr2,#0x8                     ! 1b52: b325fff8
	addl rr2,rr0                      ! 1b56: 9602
	slll rr2,#0x8                     ! 1b58: b3250008
	ldl rr4(#0xa),rr2                 ! 1b5c: 3742000a
	sll r1,#0x8                       ! 1b60: b3110008
	ld r2,rr4(#0xe)                   ! 1b64: 3142000e
	sub r2,r1                         ! 1b68: 8312
	ld rr4(#0xe),r2                   ! 1b6a: 3342000e
	ldl rr2,rr4(#0x4)                 ! 1b6e: 35420004
	subl rr2,rr0                      ! 1b72: 9202
	ldl rr4(#0x4),rr2                 ! 1b74: 37420004
	jr t,L_1aee                       ! 1b78: e8ba
L_1b7a:
	.long_addr
	testb 0x1000315                   ! 1b7a: 4c0481000315
	ld r7,#0x4                        ! 1b80: 21070004
	jr ne,L_1bb8                      ! 1b84: ee19
	ld r6,#0x200                      ! 1b86: 21060200
	ld rr4(#0x8),r6                   ! 1b8a: 33460008
	ldk r6,#0x0                       ! 1b8e: bd60
	ld rr4(#0xe),r6                   ! 1b90: 3346000e
	.long_addr
	tsetb 0x1000315                   ! 1b94: 4c0681000315
	jr t,L_1aee                       ! 1b9a: e8a9
L_1b9c:
	ld r6,rr4(#0xc)                   ! 1b9c: 3146000c
	ld r2,rr4(#0x12)                  ! 1ba0: 31420012
	and r2,#0xf100                    ! 1ba4: 0702f100
	ld r7,#0x2                        ! 1ba8: 21070002
	jr ne,L_1bb8                      ! 1bac: ee05
	ld r7,#0x4                        ! 1bae: 21070004
	jr t,L_1bb8                       ! 1bb2: e802
L_1bb4:
	ld r7,#0x1                        ! 1bb4: 21070001
L_1bb8:
	popl rr4,@rr14                    ! 1bb8: 95e4
	popl rr2,@rr14                    ! 1bba: 95e2
	popl rr0,@rr14                    ! 1bbc: 95e0
	ret t                             ! 1bbe: 9e08
L_1bc0:
	push @rr14,r12                    ! 1bc0: 93ec
	push @rr14,r2                     ! 1bc2: 93e2
	.long_addr
	ldb rh2,0x1000302                 ! 1bc4: 600281000302
	ld r12,#0x2800                    ! 1bca: 210c2800
L_1bce:
	in r7,@r2                         ! 1bce: 3d27
	bitb rh7,#0x0                     ! 1bd0: a670
	jr eq,L_1bda                      ! 1bd2: e603
	djnz r12,L_1bce                   ! 1bd4: fc84
	setflg z                          ! 1bd6: 8d41
	jr t,L_1bf4                       ! 1bd8: e80d
L_1bda:
	outb @r2,rl1                      ! 1bda: 3e29
	ld r12,#0x100                     ! 1bdc: 210c0100
L_1be0:
	djnz r12,L_1be0                   ! 1be0: fc81
	ld r12,#0x2800                    ! 1be2: 210c2800
L_1be6:
	in r7,@r2                         ! 1be6: 3d27
	andb rh7,#0xf                     ! 1be8: 06070f0f
	cpb rh1,rh7                       ! 1bec: 8a71
	comflg z                          ! 1bee: 8d45
	jr ne,L_1bf4                      ! 1bf0: ee01
	djnz r12,L_1be6                   ! 1bf2: fc87
L_1bf4:
	pop r2,@rr14                      ! 1bf4: 97e2
	pop r12,@rr14                     ! 1bf6: 97ec
	ret t                             ! 1bf8: 9e08
L_1bfa:
	pushl @rr14,rr2                   ! 1bfa: 91e2
	.long_addr
	lda rr6,0x1000338                 ! 1bfc: 760681000338
	clrb rh1                          ! 1c02: 8c18
	.long_addr
	ldb rl1,0x1000303                 ! 1c04: 600981000303
	mult rr0,#0x18                    ! 1c0a: 19000018
	add r7,r1                         ! 1c0e: 8117
	.long_addr
	ldl 0x1000310,rr6                 ! 1c10: 5d0681000310
	ld r2,#0x500                      ! 1c16: 21020500
	ld rr6(#0x8),r2                   ! 1c1a: 33620008
	.long_addr
	ldb rl1,0x1000303                 ! 1c1e: 600981000303
	or r1,#0x10                       ! 1c24: 05010010
	calr L_1c8c                       ! 1c28: dfcf
	ldk r7,#0x1                       ! 1c2a: bd71
	jr eq,L_1c88                      ! 1c2c: e62d
	.long_addr
	ldl rr6,0x1000310                 ! 1c2e: 540681000310
	ldb rh0,rr6(#0x2)                 ! 1c34: 30600002
	bitb rh0,#0x4                     ! 1c38: a604
	jr eq,L_1c42                      ! 1c3a: e603
	calr L_1d02                       ! 1c3c: df9e
	setflg c                          ! 1c3e: 8d81
	jr eq,L_1c88                      ! 1c40: e623
L_1c42:
	ld r5,rr6(#0x16)                  ! 1c42: 31650016
	bitb rl5,#0x4                     ! 1c46: a6d4
	and r5,#0xf0f                     ! 1c48: 07050f0f
	jr ne,L_1c5c                      ! 1c4c: ee07
	addb rl5,rl5                      ! 1c4e: 80dd
	decb rl5,#0x1                     ! 1c50: aad0
	ld r4,#0x328                      ! 1c52: 21040328
	ld r6,#0x3c                       ! 1c56: 2106003c
	jr t,L_1c82                       ! 1c5a: e813
L_1c5c:
	cpb rh5,#0x3                      ! 1c5c: 0a050303
	ld r4,#0x1a9                      ! 1c60: 210401a9
	ld r6,#0x20                       ! 1c64: 21060020
	jr eq,L_1c80                      ! 1c68: e60b
	cpb rh5,#0x2                      ! 1c6a: 0a050202
	ld r4,#0x26d                      ! 1c6e: 2104026d
	ld r6,#0x3a                       ! 1c72: 2106003a
	jr eq,L_1c80                      ! 1c76: e604
	ld r4,#0x1bc                      ! 1c78: 210401bc
	ld r6,#0x2c                       ! 1c7c: 2106002c
L_1c80:
	clrb rh3                          ! 1c80: 8c38
L_1c82:
	resflg c                          ! 1c82: 8d83
	clrb rh5                          ! 1c84: 8c58
	clr r7                            ! 1c86: 8d78
L_1c88:
	popl rr2,@rr14                    ! 1c88: 95e2
	ret t                             ! 1c8a: 9e08
L_1c8c:
	pushl @rr14,rr0                   ! 1c8c: 91e0
	pushl @rr14,rr2                   ! 1c8e: 91e2
	pushl @rr14,rr4                   ! 1c90: 91e4
	pushl @rr14,rr8                   ! 1c92: 91e8
	pushl @rr14,rr10                  ! 1c94: 91ea
	.long_addr
	ldl rr6,0x1000310                 ! 1c96: 540681000310
	inc r7,#0x2                       ! 1c9c: a971
	ld @rr6,#0x3                      ! 1c9e: 0d650003
	ld r10,#0x28                      ! 1ca2: 210a0028
L_1ca6:
	.long_addr
	ldb rh2,0x1000302                 ! 1ca6: 600281000302
	in r3,@r2                         ! 1cac: 3d23
	andb rh3,#0xf                     ! 1cae: 06030f0f
	cpb rh3,#0x8                      ! 1cb2: 0a030808
	jr eq,L_1cbc                      ! 1cb6: e602
	djnz r10,L_1ca6                   ! 1cb8: fa8a
	jr t,L_1cec                       ! 1cba: e818
L_1cbc:
	.long_addr
	tsetb 0x1000316                   ! 1cbc: 4c0681000316
	ld r0,#0x14                       ! 1cc2: 21000014
L_1cc6:
	.long_addr
	ldar rr10,L_1cc6                  ! 1cc6: 340afffc
	ld r11,#0xde4                     ! 1cca: 210b0de4
	call @rr10                        ! 1cce: 1fa0
	ldb rh1,#0x8                      ! 1cd0: c108
	calr L_1bc0                       ! 1cd2: d08a
	jr eq,L_1cec                      ! 1cd4: e60b
L_1cd6:
	.long_addr
	testb 0x1000316                   ! 1cd6: 4c0481000316
	jr eq,L_1ce8                      ! 1cdc: e605
	.long_addr
	testb 0x100030f                   ! 1cde: 4c048100030f
	jr eq,L_1cec                      ! 1ce4: e603
	jr t,L_1cd6                       ! 1ce6: e8f7
L_1ce8:
	in r7,@r2                         ! 1ce8: 3d27
	resflg z                          ! 1cea: 8d43
L_1cec:
	popl rr10,@rr14                   ! 1cec: 95ea
	popl rr8,@rr14                    ! 1cee: 95e8
	popl rr4,@rr14                    ! 1cf0: 95e4
	popl rr2,@rr14                    ! 1cf2: 95e2
	popl rr0,@rr14                    ! 1cf4: 95e0
	ret t                             ! 1cf6: 9e08
L_1cf8:
	.long_addr
	clrb 0x1000316                    ! 1cf8: 4c0881000316
	ld r4,@rr14                       ! 1cfe: 21e4
	iret                              ! 1d00: 7b00
L_1d02:
	pushl @rr14,rr0                   ! 1d02: 91e0
	ldb rl0,rr4(#0x11)                ! 1d04: 30480011
	cpb rl0,#0x1                      ! 1d08: 0a080101
	ld r7,#0x10                       ! 1d0c: 21070010
	jr eq,L_1d28                      ! 1d10: e60b
	cpb rl0,#0xa                      ! 1d12: 0a080a0a
	ld r7,#0x1                        ! 1d16: 21070001
	jr eq,L_1d28                      ! 1d1a: e606
	cpb rl0,#0xb                      ! 1d1c: 0a080b0b
	jr eq,L_1d28                      ! 1d20: e603
	ld r7,#0x2                        ! 1d22: 21070002
	push @rr14,r7                     ! 1d26: 93e7
L_1d28:
	.long_addr
	ldb rl1,0x1000303                 ! 1d28: 600981000303
	or r1,#0x30                       ! 1d2e: 05010030
	calr L_1c8c                       ! 1d32: d054
	pop r7,@rr14                      ! 1d34: 97e7
	popl rr0,@rr14                    ! 1d36: 95e0
	ret t                             ! 1d38: 9e08
	pushl @rr14,rr0                   ! 1d3a: 91e0
	pushl @rr14,rr2                   ! 1d3c: 91e2
	pushl @rr14,rr4                   ! 1d3e: 91e4
	push @rr14,r6                     ! 1d40: 93e6
	pushl @rr14,rr8                   ! 1d42: 91e8
	pushl @rr14,rr10                  ! 1d44: 91ea
	pushl @rr14,rr12                  ! 1d46: 91ec
	ldb rl5,rl7                       ! 1d48: a0fd
	.long_addr
	ldb rh2,0x1000304                 ! 1d4a: 600281000304
	in r7,@r2                         ! 1d50: 3d27
	cpb rh7,#0x2                      ! 1d52: 0a070202
	jr eq,L_1d80                      ! 1d56: e614
	cpb rh7,#0x4                      ! 1d58: 0a070404
	jr eq,L_1d9e                      ! 1d5c: e620
L_1d5e:
	ldb rl1,#0xc                      ! 1d5e: c90c
	calr L_1f22                       ! 1d60: df20
	ldk r0,#0x1                       ! 1d62: bd01
	.long_addr
	call 0xde4                        ! 1d64: 5f0080000de4
L_1d6a:
	.long_addr
	testb 0x100030f                   ! 1d6a: 4c048100030f
	jr ne,L_1d6a                      ! 1d70: eefc
	in r7,@r2                         ! 1d72: 3d27
	cpb rh7,#0xe                      ! 1d74: 0a070e0e
	jr eq,L_1d5e                      ! 1d78: e6f2
	cpb rh7,#0x2                      ! 1d7a: 0a070202
	jr ne,L_1e1a                      ! 1d7e: ee4d
L_1d80:
	ldb rl1,#0x55                     ! 1d80: c955
	calr L_1f22                       ! 1d82: df31
	cpb rh7,#0x2                      ! 1d84: 0a070202
	jr ne,L_1e1a                      ! 1d88: ee48
	ldb rl1,rl5                       ! 1d8a: a0d9
	calr L_1f22                       ! 1d8c: df36
	cpb rh7,#0x2                      ! 1d8e: 0a070202
	jr ne,L_1e1a                      ! 1d92: ee43
	ldb rl1,#0xaa                     ! 1d94: c9aa
	calr L_1f22                       ! 1d96: df3b
	cpb rh7,#0x6                      ! 1d98: 0a070606
	jr ne,L_1e1a                      ! 1d9c: ee3e
L_1d9e:
	.long_addr
	lda rr2,0x10001c0                 ! 1d9e: 7602810001c0
	clrb rh1                          ! 1da4: 8c18
	ldb rl1,rl5                       ! 1da6: a0d9
	sllb rl1,#0x1                     ! 1da8: b2910001
	add r3,r1                         ! 1dac: 8113
	.long_addr
	lda rr6,0x1fa6                    ! 1dae: 760680001fa6
	ldl @rr2,rr6                      ! 1db4: 1d26
	ldb rl1,#0x8                      ! 1db6: c908
	calr L_1f56                       ! 1db8: df32
	jr eq,L_1e1a                      ! 1dba: e62f
	.long_addr
	lda rr2,0x1000338                 ! 1dbc: 760281000338
	.long_addr
	call 0xa70                        ! 1dc2: 5f0080000a70
	ldb rl1,#0xa                      ! 1dc8: c90a
	calr L_1f22                       ! 1dca: df55
	cpb rh7,#0x6                      ! 1dcc: 0a070606
	jr ne,L_1e1a                      ! 1dd0: ee24
	ldb rl1,rl2                       ! 1dd2: a0a9
	calr L_1f22                       ! 1dd4: df5a
	cpb rh7,#0x6                      ! 1dd6: 0a070606
	jr ne,L_1e1a                      ! 1dda: ee1f
	ldb rl1,rh3                       ! 1ddc: a039
	calr L_1f22                       ! 1dde: df5f
	cpb rh7,#0x6                      ! 1de0: 0a070606
	jr ne,L_1e1a                      ! 1de4: ee1a
	ldb rl1,rl3                       ! 1de6: a0b9
	calr L_1f22                       ! 1de8: df64
	cpb rh7,#0xf8                     ! 1dea: 0a07f8f8
	jr ne,L_1e1a                      ! 1dee: ee15
L_1df0:
	ldb rl1,#0x6                      ! 1df0: c906
	calr L_1f56                       ! 1df2: df4f
	jr eq,L_1e1a                      ! 1df4: e612
	ldb rl0,#0x32                     ! 1df6: c832
	.long_addr
	call 0xe96                        ! 1df8: 5f0080000e96
	cpb rh7,#0xe                      ! 1dfe: 0a070e0e
	.long_addr
	lda rr2,0x1000338                 ! 1e02: 760281000338
	ld r4,rr2(#0xa)                   ! 1e08: 3124000a
	bit r4,#0x7                       ! 1e0c: a747
	jr ne,L_1df0                      ! 1e0e: eef0
	bit r4,#0x9                       ! 1e10: a749
	ldk r7,#0x8                       ! 1e12: bd78
	jr eq,L_1e1c                      ! 1e14: e603
	ldk r7,#0x0                       ! 1e16: bd70
	jr t,L_1e1c                       ! 1e18: e801
L_1e1a:
	ldk r7,#0x1                       ! 1e1a: bd71
L_1e1c:
	popl rr12,@rr14                   ! 1e1c: 95ec
	popl rr10,@rr14                   ! 1e1e: 95ea
	popl rr8,@rr14                    ! 1e20: 95e8
	pop r6,@rr14                      ! 1e22: 97e6
	popl rr4,@rr14                    ! 1e24: 95e4
	popl rr2,@rr14                    ! 1e26: 95e2
	popl rr0,@rr14                    ! 1e28: 95e0
	ret t                             ! 1e2a: 9e08
	pushl @rr14,rr0                   ! 1e2c: 91e0
	pushl @rr14,rr2                   ! 1e2e: 91e2
	push @rr14,r4                     ! 1e30: 93e4
	pushl @rr14,rr8                   ! 1e32: 91e8
	pushl @rr14,rr10                  ! 1e34: 91ea
	pushl @rr14,rr12                  ! 1e36: 91ec
	ldl rr4,#0x81000338               ! 1e38: 140481000338
	ldl rr6,rr2                       ! 1e3e: 9426
	ldl rr2,@rr6                      ! 1e40: 1462
L_1e42:
	.long_addr
	ldar rr10,L_1e42                  ! 1e42: 340afffc
	ld r11,#0xa70                     ! 1e46: 210b0a70
	call @rr10                        ! 1e4a: 1fa0
	ldl rr4(#0x4),rr2                 ! 1e4c: 37420004
	ld r1,rr6(#0x4)                   ! 1e50: 31610004
	ldb rl0,rh1                       ! 1e54: a018
	.word	0xb281		! 1e56: srlb rl0,#0x1
	.word	0xffff		! 1e58: srlb rl0,#0x1
	testb rl1                         ! 1e5a: 8c94
	jr eq,L_1e60                      ! 1e5c: e601
	incb rl0,#0x1                     ! 1e5e: a880
L_1e60:
	clrb rh0                          ! 1e60: 8c08
	ld rr4(#0x8),r0                   ! 1e62: 33400008
	ldb rl2,rr6(#0x7)                 ! 1e66: 306a0007
	ldb rh2,rr6(#0xa)                 ! 1e6a: 3062000a
	ld @rr4,r2                        ! 1e6e: 2f42
	ld r2,rr6(#0x8)                   ! 1e70: 31620008
	ld rr4(#0x2),r2                   ! 1e74: 33420002
	ldb rl1,rr6(#0xb)                 ! 1e78: 3069000b
L_1e7c:
	calr L_1f56                       ! 1e7c: df94
	jr eq,L_1f10                      ! 1e7e: e648
	ld r5,r7                          ! 1e80: a175
	cpb rh5,#0xe                      ! 1e82: 0a050e0e
	jr ne,L_1e9c                      ! 1e86: ee0a
	.long_addr
	lda rr2,0x1000338                 ! 1e88: 760281000338
	ld r4,rr2(#0xa)                   ! 1e8e: 3124000a
	bit r4,#0x7                       ! 1e92: a747
	jr ne,L_1e7c                      ! 1e94: eef3
	bit r4,#0x9                       ! 1e96: a749
	ldk r7,#0x8                       ! 1e98: bd78
	jr eq,L_1f10                      ! 1e9a: e63a
L_1e9c:
	bitb rl1,#0x4                     ! 1e9c: a694
	jr eq,L_1ec2                      ! 1e9e: e611
	ldb rl1,#0x2                      ! 1ea0: c902
L_1ea2:
	calr L_1f56                       ! 1ea2: dfa7
	jr eq,L_1f10                      ! 1ea4: e635
	ld r5,r7                          ! 1ea6: a175
	cpb rh5,#0xe                      ! 1ea8: 0a050e0e
	jr ne,L_1ec2                      ! 1eac: ee0a
	.long_addr
	lda rr2,0x1000338                 ! 1eae: 760281000338
	ld r4,rr2(#0xa)                   ! 1eb4: 3124000a
	bit r4,#0x7                       ! 1eb8: a747
	jr ne,L_1ea2                      ! 1eba: eef3
	bit r4,#0x9                       ! 1ebc: a749
	ldk r7,#0x8                       ! 1ebe: bd78
	jr eq,L_1f10                      ! 1ec0: e627
L_1ec2:
	andb rh5,#0xf0                    ! 1ec2: 0605f0f0
	cpb rh5,#0x80                     ! 1ec6: 0a058080
	jr ne,L_1f0a                      ! 1eca: ee1f
	.long_addr
	lda rr4,0x1000338                 ! 1ecc: 760481000338
	ld r3,rr4(#0xc)                   ! 1ed2: 3143000c
	and r3,#0xc                       ! 1ed6: 0703000c
	ld r6,rr4(#0xe)                   ! 1eda: 3146000e
	ldk r7,#0x4                       ! 1ede: bd74
	jr ne,L_1f10                      ! 1ee0: ee17
	ld r3,rr4(#0xc)                   ! 1ee2: 3143000c
	bit r3,#0x0                       ! 1ee6: a730
	ld r7,#0x40                       ! 1ee8: 21070040
	jr ne,L_1f10                      ! 1eec: ee11
	bit r3,#0x1                       ! 1eee: a731
	ld r7,#0x10                       ! 1ef0: 21070010
	jr ne,L_1f10                      ! 1ef4: ee0d
	bit r3,#0x4                       ! 1ef6: a734
	ld r7,#0x10                       ! 1ef8: 21070010
	jr ne,L_1f10                      ! 1efc: ee09
	ld r3,rr4(#0xa)                   ! 1efe: 3143000a
	bit r3,#0x8                       ! 1f02: a738
	ld r7,#0x20                       ! 1f04: 21070020
	jr eq,L_1f10                      ! 1f08: e603
L_1f0a:
	ld r6,#0xffff                     ! 1f0a: 2106ffff
	clr r7                            ! 1f0e: 8d78
L_1f10:
	ld r5,rr4(#0xe)                   ! 1f10: 3145000e
	popl rr12,@rr14                   ! 1f14: 95ec
	popl rr10,@rr14                   ! 1f16: 95ea
	popl rr8,@rr14                    ! 1f18: 95e8
	pop r4,@rr14                      ! 1f1a: 97e4
	popl rr2,@rr14                    ! 1f1c: 95e2
	popl rr0,@rr14                    ! 1f1e: 95e0
	ret t                             ! 1f20: 9e08
L_1f22:
	push @rr14,r12                    ! 1f22: 93ec
	push @rr14,r5                     ! 1f24: 93e5
	push @rr14,r2                     ! 1f26: 93e2
	ld r12,#0x2800                    ! 1f28: 210c2800
	.long_addr
	ldb rh2,0x1000304                 ! 1f2c: 600281000304
L_1f32:
	in r7,@r2                         ! 1f32: 3d27
	bitb rh7,#0x0                     ! 1f34: a670
	jr eq,L_1f42                      ! 1f36: e605
	djnz r12,L_1f32                   ! 1f38: fc84
	setflg z                          ! 1f3a: 8d41
	ld r7,#0x1                        ! 1f3c: 21070001
	jr t,L_1f4e                       ! 1f40: e806
L_1f42:
	outb @r2,rl1                      ! 1f42: 3e29
	ld r12,#0x100                     ! 1f44: 210c0100
L_1f48:
	djnz r12,L_1f48                   ! 1f48: fc81
	in r7,@r2                         ! 1f4a: 3d27
	resflg z                          ! 1f4c: 8d43
L_1f4e:
	pop r2,@rr14                      ! 1f4e: 97e2
	pop r5,@rr14                      ! 1f50: 97e5
	pop r12,@rr14                     ! 1f52: 97ec
	ret t                             ! 1f54: 9e08
L_1f56:
	pushl @rr14,rr0                   ! 1f56: 91e0
	pushl @rr14,rr2                   ! 1f58: 91e2
	pushl @rr14,rr4                   ! 1f5a: 91e4
	push @rr14,r6                     ! 1f5c: 93e6
	pushl @rr14,rr8                   ! 1f5e: 91e8
	.long_addr
	tsetb 0x1000314                   ! 1f60: 4c0681000314
	ldb rl0,#0xf0                     ! 1f66: c8f0
L_1f68:
	.long_addr
	ldar rr10,L_1f68                  ! 1f68: 340afffc
	ld r11,#0xde4                     ! 1f6c: 210b0de4
	call @rr10                        ! 1f70: 1fa0
	calr L_1f22                       ! 1f72: d029
	ld r7,#0x1                        ! 1f74: 21070001
	jr eq,L_1f9a                      ! 1f78: e610
L_1f7a:
	.long_addr
	testb 0x1000314                   ! 1f7a: 4c0481000314
	jr eq,L_1f90                      ! 1f80: e607
	.long_addr
	testb 0x100030f                   ! 1f82: 4c048100030f
	ld r7,#0x1                        ! 1f88: 21070001
	jr eq,L_1f9a                      ! 1f8c: e606
	jr t,L_1f7a                       ! 1f8e: e8f5
L_1f90:
	.long_addr
	ldb rh2,0x1000304                 ! 1f90: 600281000304
	in r7,@r2                         ! 1f96: 3d27
	resflg z                          ! 1f98: 8d43
L_1f9a:
	popl rr8,@rr14                    ! 1f9a: 95e8
	pop r6,@rr14                      ! 1f9c: 97e6
	popl rr4,@rr14                    ! 1f9e: 95e4
	popl rr2,@rr14                    ! 1fa0: 95e2
	popl rr0,@rr14                    ! 1fa2: 95e0
	ret t                             ! 1fa4: 9e08
	.long_addr
	clrb 0x1000314                    ! 1fa6: 4c0881000314
	iret                              ! 1fac: 7b00

! ---- 0x1fae .. 0x2000  (word) ----
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0xffff
	.word	0x0277
	.word	0xe8d9

