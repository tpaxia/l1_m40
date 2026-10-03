	.z8001
	.text
	.org	0

! ---- 0x0000 .. 0x0008  (word) ----
L_0000:
	calr vi_disp			! 0000: was dfbb (calr 0x8c)
	.word	0xc000
	.word	0x8000
	.word	0x0106

! ---- 0x0008 .. 0x0028  (ascii) ----
	! " 17 DEC. 82     REL 6.0         "
	.byte	0x20,0x31,0x37,0x20,0x44,0x45,0x43,0x2e
	.byte	0x20,0x38,0x32,0x20,0x20,0x20,0x20,0x20
	.byte	0x52,0x45,0x4c,0x20,0x36,0x2e,0x30,0x20
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
	.word	0x8000
	.word	0x1d3a
	.word	0x8000
	.word	0x1e58
	.word	0x8000
	.word	0x1eb2
	.word	0x8000
	.word	0x1642
	.word	0x8000
	.word	0x14ae
	.word	0x8000
	.word	0x0d10
	.word	0x8000
	.word	0x19fa
	.word	0x8000
	.word	0x2814
	.word	0x8000
	.word	0x0dd4
	.word	0x8000
	.word	0x1a5e
	.word	0x8000
	.word	0x17f0
	.word	0x8000
	.word	0x0a68
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

! ---- 0x00ce .. 0x00f6  (code) ----
	inc r15,#0x8                      ! 00ce: a9f7
	cp r13,#0xaa8                     ! 00d0: 0b0d0aa8
	jr eq,L_00dc                      ! 00d4: e603
	cp r13,#0xaea                     ! 00d6: 0b0d0aea
	jr ne,L_00ec                      ! 00da: ee08
L_00dc:
	inb rl6,#0xff41                   ! 00dc: 3ae4ff41
	out #0xff41,r0                    ! 00e0: 3b06ff41
	bitb rl6,#0x6                     ! 00e4: a6e6
	.long_addr
	jp ne,0xada                       ! 00e6: 5e0e80000ada
L_00ec:
	out #0xff41,r0                    ! 00ec: 3b06ff41
	jp t,@rr12                        ! 00f0: 1ec8
	inc r15,#0x8                      ! 00f2: a9f7
	jp t,@rr12                        ! 00f4: 1ec8

! ---- 0x00f6 .. 0x0106  (word) ----
L_00f6:
	.word	0x0000
	.word	0xff00
	.word	0xff00
	.word	0xff00
	.word	0xf000
	.word	0xff00
	.word	0x0000
	.word	0xff00

! ---- 0x0106 .. 0x2996  (code) ----
	ldb rl0,#0x80                     ! 0106: c880
	soutb #0x0,rl0                    ! 0108: 3a870000
	sub r0,r0                         ! 010c: 8300
	out #0xf0e0,r0                    ! 010e: 3b06f0e0
	out #0xf0e2,r0                    ! 0112: 3b06f0e2
	ldar rr10,L_0122                  ! 0116: 340a0008
	ldb rl7,#0x1                      ! 011a: cf01
	.long_addr
	jp t,0xbaa                        ! 011c: 5e0880000baa
L_0122:
	ld r0,#0x9200                     ! 0122: 21009200
	ldctl refresh,r0                  ! 0126: 7d0b
	lda rr14,0xfe                     ! 0128: 760e00fe
	.long_addr
	ldar rr2,L_0000                   ! 012c: 3402fed0
	ldctl psapseg,r2                  ! 0130: 7d2c
	ldctl psapoff,r3                  ! 0132: 7d3d
	ldb rl0,#0x34                     ! 0134: c834
	outb #0xffc7,rl0                  ! 0136: 3a86ffc7
	ldb rl0,#0x70                     ! 013a: c870
	outb #0xffc7,rl0                  ! 013c: 3a86ffc7
	ldb rl0,#0xb6                     ! 0140: c8b6
	outb #0xffc7,rl0                  ! 0142: 3a86ffc7
	inb rl0,#0xffa0                   ! 0146: 3a84ffa0
	ldb rl0,#0x3                      ! 014a: c803
	outb #0xff20,rl0                  ! 014c: 3a86ff20
	subl rr6,rr6                      ! 0150: 9266
	ldar rr12,L_01b2                  ! 0152: 340c005c
	sub r1,r1                         ! 0156: 8311
L_0158:
	or r1,#0xfff                      ! 0158: 05010fff
	inb rl0,@r1                       ! 015c: 3c18
	cpb rl0,#0xf0                     ! 015e: 0a08f0f0
	jr ne,L_016a                      ! 0162: ee03
	ldb rl1,#0x81                     ! 0164: c981
	ldb rh0,#0x7                      ! 0166: c007
	outb @r1,rh0                      ! 0168: 3e10
L_016a:
	cpb rl0,#0xfe                     ! 016a: 0a08fefe
	jr ne,L_01a0                      ! 016e: ee18
	ldb rh0,#0x3                      ! 0170: c003
	ldb rl1,#0x1                      ! 0172: c901
	outb @r1,rh0                      ! 0174: 3e10
	ldb rl1,#0x41                     ! 0176: c941
	ldk r2,#0x6                       ! 0178: bd26
	outb @r1,rl2                      ! 017a: 3e1a
	ldb rl1,#0x43                     ! 017c: c943
	outb @r1,rh2                      ! 017e: 3e12
	ldb rl1,#0x41                     ! 0180: c941
	ldb rl2,#0x1                      ! 0182: ca01
	outb @r1,rl2                      ! 0184: 3e1a
	ldb rl1,#0x43                     ! 0186: c943
	outb @r1,rh2                      ! 0188: 3e12
	ldk r2,#0x2                       ! 018a: bd22
L_018c:
	ldb rl1,#0x65                     ! 018c: c965
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
	andb rl0,#0xf1                    ! 01a0: 0608f1f1
	cpb rl0,#0xd0                     ! 01a4: 0a08d0d0
	jr ne,L_01b2                      ! 01a8: ee04
	ldb rl1,#0xb1                     ! 01aa: c9b1
	ldb rh0,#0x1                      ! 01ac: c001
	outb @r1,rh0                      ! 01ae: 3e10
	ldb rh7,#0xff                     ! 01b0: c7ff
L_01b2:
	addb rh1,#0x10                    ! 01b2: 00011010
	jr nc/uge,L_0158                  ! 01b6: efd0
	ldctl nspoff,r7                   ! 01b8: 7d7f
	or r7,r7                          ! 01ba: 8577
	jr ne,L_0242                      ! 01bc: ee42
	subl rr0,rr0                      ! 01be: 9200
	subl rr2,rr2                      ! 01c0: 9222
	subl rr4,rr4                      ! 01c2: 9244
	sub r6,r6                         ! 01c4: 8366
	ld r7,#0x1ffe                     ! 01c6: 21071ffe
L_01ca:
	ldb rl4,@rr2                      ! 01ca: 202c
	xorb rl4,rl3                      ! 01cc: 88bc
	inc r3,#0x1                       ! 01ce: a930
	ldb rl5,@rr2                      ! 01d0: 202d
	xorb rl5,rl3                      ! 01d2: 88bd
	inc r3,#0x1                       ! 01d4: a930
	add r1,r4                         ! 01d6: 8141
	adc r1,r6                         ! 01d8: b561
	add r0,r5                         ! 01da: 8150
	adc r0,r6                         ! 01dc: b560
	djnz r7,L_01ca                    ! 01de: f78b
	ldl rr4,@rr2                      ! 01e0: 1424
	exb rh4,rl5                       ! 01e2: acd4
	cpl rr0,rr4                       ! 01e4: 9040
L_01e6:
	jr ne,L_01e6                      ! 01e6: eeff
	ldk r0,#0x2                       ! 01e8: bd02
	outb #0xffc1,rl0                  ! 01ea: 3a86ffc1
	outb #0xffc1,rh0                  ! 01ee: 3a06ffc1
	ld r1,#0x3be                      ! 01f2: 210103be
	outb #0xffc3,rl1                  ! 01f6: 3a96ffc3
	outb #0xffc3,rh1                  ! 01fa: 3a16ffc3
L_01fe:
	ldb rl0,#0x40                     ! 01fe: c840
	outb #0xffc7,rl0                  ! 0200: 3a86ffc7
	incb rh0,#0x1                     ! 0204: a800
L_0206:
	jr eq,L_0206                      ! 0206: e6ff
	inb rl1,#0xffc3                   ! 0208: 3a94ffc3
	inb rh1,#0xffc3                   ! 020c: 3a14ffc3
	bit r1,#0xf                       ! 0210: a71f
	jr eq,L_01fe                      ! 0212: e6f5
	ldb rl0,#0x70                     ! 0214: c870
	outb #0xffc7,rl0                  ! 0216: 3a86ffc7
	cpb rh0,#0x28                     ! 021a: 0a002828
L_021e:
	jr lt,L_021e                      ! 021e: e1ff
	sub r0,r0                         ! 0220: 8300
	soutb #0x100,rl0                  ! 0222: 3a870100
	soutb #0x2000,rl0                 ! 0226: 3a872000
L_022a:
	soutb #0xf00,rl0                  ! 022a: 3a870f00
	dbjnz rl0,L_022a                  ! 022e: f803
	soutb #0x100,rl0                  ! 0230: 3a870100
	soutb #0x2000,rl0                 ! 0234: 3a872000
L_0238:
	sinb rh0,#0xf00                   ! 0238: 3a050f00
	cpb rh0,rl0                       ! 023c: 8a80
L_023e:
	jr ne,L_023e                      ! 023e: eeff
	dbjnz rl0,L_0238                  ! 0240: f805
L_0242:
	ld r0,#0xff                       ! 0242: 210000ff
	soutb #0x100,rh0                  ! 0246: 3a070100
	soutb #0x2000,rh0                 ! 024a: 3a072000
L_024e:
	soutb #0xf00,rl0                  ! 024e: 3a870f00
	dbjnz rh0,L_024e                  ! 0252: f003
	soutb #0x100,rh0                  ! 0254: 3a070100
	soutb #0x2000,rh0                 ! 0258: 3a072000
	.long_addr
	ldar rr2,L_00f6                   ! 025c: 3402fe96
	ld r1,#0xf00                      ! 0260: 21010f00
	ldk r0,#0x4                       ! 0264: bd04
	sotirb @r1,@rr2,r0                ! 0266: 3a230010
	ldb rl0,#0x3d                     ! 026a: c83d
	soutb #0x100,rl0                  ! 026c: 3a870100
	ldk r0,#0xc                       ! 0270: bd0c
	sotirb @r1,@rr2,r0                ! 0272: 3a230010
	ldb rl0,#0xc0                     ! 0276: c8c0
	soutb #0x0,rl0                    ! 0278: 3a870000
	ldk r7,#0x0                       ! 027c: bd70
	sub r1,r1                         ! 027e: 8311
L_0280:
	ldar rr12,L_02a0                  ! 0280: 340c001c
	or r1,#0xfff                      ! 0284: 05010fff
	inb rl0,@r1                       ! 0288: 3c18
	cpb rl0,#0xfe                     ! 028a: 0a08fefe
	jr ne,L_02a0                      ! 028e: ee08
	ldar rr10,L_029c                  ! 0290: 340a0008
	ldl rr12,rr10                     ! 0294: 94ac
	.long_addr
	jp t,0xbc6                        ! 0296: 5e0880000bc6
L_029c:
	add r7,#0x2000                    ! 029c: 01072000
L_02a0:
	addb rh1,#0x10                    ! 02a0: 00011010
	jr nc/uge,L_0280                  ! 02a4: efed
	ldar rr12,L_02f0                  ! 02a6: 340c0046
	out #0xff80,r0                    ! 02aa: 3b06ff80
	out #0xff89,r0                    ! 02ae: 3b06ff89
	out #0xff8a,r0                    ! 02b2: 3b06ff8a
	out #0xff8b,r0                    ! 02b6: 3b06ff8b
	out #0xff85,r0                    ! 02ba: 3b06ff85
	ei nvi                            ! 02be: 7c06
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
	ldar rr12,L_02f2                  ! 02e8: 340c0006
	out #0xff8b,r0                    ! 02ec: 3b06ff8b
L_02f0:
	jr t,L_02f0                       ! 02f0: e8ff
L_02f2:
	ldar rr12,L_0302                  ! 02f2: 340c000c
	out #0xff8a,r0                    ! 02f6: 3b06ff8a
	out #0xff87,r0                    ! 02fa: 3b06ff87
	ei nvi                            ! 02fe: 7c06
L_0300:
	jr t,L_0300                       ! 0300: e8ff
L_0302:
	ldar rr12,L_0312                  ! 0302: 340c000c
	out #0xff89,r0                    ! 0306: 3b06ff89
	out #0xff86,r0                    ! 030a: 3b06ff86
	ei nvi                            ! 030e: 7c06
L_0310:
	jr t,L_0310                       ! 0310: e8ff
L_0312:
	ldar rr12,L_0322                  ! 0312: 340c000c
	out #0xff88,r0                    ! 0316: 3b06ff88
	out #0xff85,r0                    ! 031a: 3b06ff85
	ei nvi                            ! 031e: 7c06
L_0320:
	jr t,L_0320                       ! 0320: e8ff
L_0322:
	out #0xff80,r0                    ! 0322: 3b06ff80
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
L_035c:
	inb rl0,#0xff41                   ! 035c: 3a84ff41
	bit r0,#0x0                       ! 0360: a700
	jr ne,L_03a4                      ! 0362: ee20
	ldar rr12,L_03a4                  ! 0364: 340c003c
	ldar rr8,L_039c                   ! 0368: 34080030
	.long_addr
	lda rr2,0x10003f8                 ! 036c: 7602810003f8
	ld r0,#0x8                        ! 0372: 21000008
	cpsirb @rr8,@rr2,r0,ne            ! 0376: ba26008e
	jr eq,L_03a4                      ! 037a: e614
	ldm r2,0x1000210,#0x4             ! 037c: 5c0102038100
	res r2,#0xf                       ! 0384: a32f
	soutb #0x100,rh2                  ! 0386: 3a270100
	soutb #0xf00,rh4                  ! 038a: 3a470f00
	soutb #0xf00,rl4                  ! 038e: 3ac70f00
	soutb #0xf00,rh5                  ! 0392: 3a570f00
	soutb #0xf00,rl5                  ! 0396: 3ad70f00
	jp t,@rr2                         ! 039a: 1e28
L_039c:
	setb @rr4,#0x2                    ! 039c: 2442
	subb rh5,0x2000004f(r5)           ! 039e: 4255204f
	.word	0x4e20		! 03a2: .word 4e20
L_03a4:
	.long_addr
	lda rr2,0x10003ff                 ! 03a4: 7602810003ff
	sub r0,r0                         ! 03aa: 8300
L_03ac:
	ldb @rr2,rl0                      ! 03ac: 2e28
	djnz r3,L_03ac                    ! 03ae: f382
	ldctl r0,nspoff                   ! 03b0: 7d07
	orb rh0,rh0                       ! 03b2: 8400
	.long_addr
	jp ne,0x4ca                       ! 03b4: 5e0e800004ca
	ldl rr6,#0x2000000                ! 03ba: 140602000000
	ld r8,#0x100                      ! 03c0: 21080100
	ldb rh0,rh4                       ! 03c4: a040
	ldb rl0,rh5                       ! 03c6: a058
	ld r9,r0                          ! 03c8: a109
	sub r0,r0                         ! 03ca: 8300
	ldctl nspoff,r0                   ! 03cc: 7d0f
L_03ce:
	ldar rr12,L_0430                  ! 03ce: 340c005e
	ldl rr2,rr6                       ! 03d2: 9462
	ldar rr10,L_03de                  ! 03d4: 340a0006
	ld r1,#0x5555                     ! 03d8: 21015555
	jr t,L_03f2                       ! 03dc: e80a
L_03de:
	ldar rr10,L_03e8                  ! 03de: 340a0006
	ld r1,#0x3131                     ! 03e2: 21013131
	jr t,L_0418                       ! 03e6: e818
L_03e8:
	ldar rr10,L_0494                  ! 03e8: 340a00a8
	ld r1,#0xffff                     ! 03ec: 2101ffff
	jr t,L_0418                       ! 03f0: e813
L_03f2:
	cpl rr2,rr4                       ! 03f2: 9042
	jr eq,L_0400                      ! 03f4: e605
	ld @rr2,r1                        ! 03f6: 2f21
	inc r3,#0x2                       ! 03f8: a931
	jr ne,L_03f2                      ! 03fa: eefb
	incb rh2,#0x1                     ! 03fc: a820
	jr t,L_03f2                       ! 03fe: e8f9
L_0400:
	ldl rr2,rr6                       ! 0400: 9462
	ld r0,r1                          ! 0402: a110
	com r0                            ! 0404: 8d00
L_0406:
	cpl rr2,rr4                       ! 0406: 9042
	jp eq,@rr10                       ! 0408: 1ea6
	cp r1,@rr2                        ! 040a: 0b21
	jr ne,L_0430                      ! 040c: ee11
	ld @rr2,r0                        ! 040e: 2f20
	inc r3,#0x2                       ! 0410: a931
	jr ne,L_0406                      ! 0412: eef9
	incb rh2,#0x1                     ! 0414: a820
	jr t,L_0406                       ! 0416: e8f7
L_0418:
	ldl rr2,rr6                       ! 0418: 9462
L_041a:
	cpl rr2,rr4                       ! 041a: 9042
	.long_addr
	jp eq,0x400                       ! 041c: 5e0680000400
	cp r0,@rr2                        ! 0422: 0b20
	jr ne,L_0430                      ! 0424: ee05
	ld @rr2,r1                        ! 0426: 2f21
	inc r3,#0x2                       ! 0428: a931
	jr ne,L_041a                      ! 042a: eef7
	incb rh2,#0x1                     ! 042c: a820
	jr t,L_041a                       ! 042e: e8f5
L_0430:
	.long_addr
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
	ldb rl6,rh7                       ! 04ca: a07e
	inc r6,#0x4                       ! 04cc: a963
	.long_addr
	ld 0x1000226,r6                   ! 04ce: 6f0681000226
	dec r6,#0x4                       ! 04d4: ab63
	.long_addr
	ld 0x100022a,r6                   ! 04d6: 6f068100022a
	ld r1,#0x200                      ! 04dc: 21010200
	ldar rr10,L_04e6                  ! 04e0: 340a0002
	jr t,L_053a                       ! 04e4: e82a
L_04e6:
	.long_addr
	ld 0x1000224,r0                   ! 04e6: 6f0081000224
	.long_addr
	ld 0x1000228,r0                   ! 04ec: 6f0081000228
	.long_addr
	lda rr10,0x4fe                    ! 04f2: 760a800004fe
	.long_addr
	jp t,0xa94                        ! 04f8: 5e0880000a94
	ldb rl4,rh5                       ! 04fe: a05c
	ldb rl6,rh7                       ! 0500: a07e
	.long_addr
	ld 0x1000220,r4                   ! 0502: 6f0481000220
	.long_addr
	ld 0x1000222,r6                   ! 0508: 6f0681000222
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
L_053a:
	soutb #0x100,rh1                  ! 053a: 3a170100
	ldb rl0,#0x0                      ! 053e: c800
	soutb #0x2000,rl0                 ! 0540: 3a872000
	sinb rh0,#0xf00                   ! 0544: 3a050f00
	sinb rl0,#0xf00                   ! 0548: 3a850f00
	ldb rh1,#0x0                      ! 054c: c100
	add r0,r1                         ! 054e: 8110
	jp t,@rr10                        ! 0550: 1ea8
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
	ldk r7,#0x0                       ! 0590: bd70
	ldb rh1,#0x0                      ! 0592: c100
L_0594:
	ldar rr12,L_05c6                  ! 0594: 340c002e
	ld r2,r1                          ! 0598: a112
	srl r2,#0xa                       ! 059a: b321fff6
	and r2,#0x3c                      ! 059e: 0702003c
	ldb rl1,#0xff                     ! 05a2: c9ff
	inb rl0,@r1                       ! 05a4: 3c18
	cpb rh1,#0xe0                     ! 05a6: 0a01e0e0
	jr ne,L_05ae                      ! 05aa: ee01
	ldk r0,#0x0                       ! 05ac: bd00
L_05ae:
	.long_addr
	ldb 0x1000230(r2),rl0             ! 05ae: 6e2881000230
	cpb rl0,#0xfe                     ! 05b4: 0a08fefe
	ldk r0,#0x0                       ! 05b8: bd00
	jr ne,L_05be                      ! 05ba: ee01
	calr L_0996                       ! 05bc: de14
L_05be:
	.long_addr
	ld 0x1000232(r2),r0               ! 05be: 6f2081000232
	jr t,L_05d8                       ! 05c4: e809
L_05c6:
	.long_addr
	ld 0x1000230(r2),#0xffff          ! 05c6: 4d2581000230
	inc r2,#0x2                       ! 05ce: a921
	.long_addr
	ld 0x1000230(r2),#0xffff          ! 05d0: 4d2581000230
L_05d8:
	addb rh1,#0x10                    ! 05d8: 00011010
	jr nc/uge,L_0594                  ! 05dc: efdb
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
L_065c:
	ldar rr8,L_06e6                   ! 065c: 34080086
	inb rl0,#0xff41                   ! 0660: 3a84ff41
	bitb rl0,#0x1                     ! 0664: a681
	jr ne,L_066c                      ! 0666: ee02
	ldar rr8,L_06e8                   ! 0668: 3408007c
L_066c:
	sub r1,r1                         ! 066c: 8311
L_066e:
	.long_addr
	ldb rl0,0x1000230(r1)             ! 066e: 601881000230
	cpb rl0,@rr8                      ! 0674: 0a88
	jr ne,L_06c4                      ! 0676: ee26
	pushl @rr14,rr8                   ! 0678: 91e8
	push @rr14,r1                     ! 067a: 93e1
	sll r1,#0x2                       ! 067c: b3110002
	.long_addr
	ldb 0x1000302,rl1                 ! 0680: 6e0981000302
	ldar rr2,L_06e6                   ! 0686: 3402005c
	ld r2,r9                          ! 068a: a192
	sub r2,r3                         ! 068c: 8332
	sll r2,#0x2                       ! 068e: b3210002
	ldar rr4,L_06ee                   ! 0692: 34040058
	ldl rr6,rr4(r2)                   ! 0696: 75460200
	test r7                           ! 069a: 8d74
	jr eq,L_06b8                      ! 069c: e60d
	inc r7,#0x1                       ! 069e: a970
	jr eq,L_06b8                      ! 06a0: e60b
	add r5,r6                         ! 06a2: 8165
	.long_addr
	tsetb 0x10002fd                   ! 06a4: 4c06810002fd
L_06aa:
	jr mi,L_06b6                      ! 06aa: e505
	ld r7,#0x5555                     ! 06ac: 21075555
	.long_addr
	call 0xd10                        ! 06b0: 5f0080000d10
L_06b6:
	call @rr4                         ! 06b6: 1f40
L_06b8:
	.long_addr
	testb 0x10002fc                   ! 06b8: 4c04810002fc
L_06be:
	jr mi,L_06be                      ! 06be: e5ff
	pop r1,@rr14                      ! 06c0: 97e1
	popl rr8,@rr14                    ! 06c2: 95e8
L_06c4:
	inc r1,#0x4                       ! 06c4: a913
L_06c6:
	bit r1,#0x6                       ! 06c6: a716
	jr eq,L_066e                      ! 06c8: e6d2
L_06ca:
	inc r9,#0x1                       ! 06ca: a990
	cp r9,#0x6ec                      ! 06cc: 0b0906ec
	jr ne,L_066c                      ! 06d0: eecd
	.long_addr
	cp 0x1000308,#0x5555              ! 06d2: 4d0181000308
	jr ne,L_065c                      ! 06da: eec0
	ldk r7,#0x8                       ! 06dc: bd78
	.long_addr
	call 0xd10                        ! 06de: 5f0080000d10
	jr t,L_065c                       ! 06e4: e8bb
L_06e6:
	.word	0x65ef		! 06e6: was e4ef (E4 -> 65)
L_06e8:
	jr lt,L_06aa                      ! 06e8: e1e0
	jr eq,L_06ca                      ! 06ea: e6ef
	.word	0x0000		! 06ec: addb rh0,#0x2e
L_06ee:
	.word	hd65_stub-L_06ee	! 06ee: was 002e (E4 stub at 0x071c)
	.word	0x1e58		! 06f0: jp t,@rr5
	addb rh4,@rr4                     ! 06f2: 0044
	.word	0x1a5e		! 06f4: divl rq14,@rr5
	.word	0x0170		! 06f6: add r0,@rr7
	ext0e #0xae                       ! 06f8: 0eae
	.word	0x0170		! 06fa: add r0,@rr7
	ext0e #0xae                       ! 06fc: 0eae
	.word	0x00be		! 06fe: addb rl6,@rr11
	.word	0x2814		! 0700: incb @rr1,#0x5
	addb rl2,@rr4                     ! 0702: 004a
	.word	0x1a5e		! 0704: divl rq14,@rr5
L_0706:
	or r4,#0x302                      ! 0706: 05040302
	addb rh1,#0x0                     ! 070a: 00010000
	.word	0x0000		! 070e: addb rh0,#0x0
L_0710:
	.word	0xbc00		! 0710: addb rh0,#0x0
	.word	0x0000		! 0712: addb rh0,#0x0
	.word	0x1000		! 0714: addb rh0,#0x0
	addb rh0,#0x0                     ! 0716: 00000000
	incb rh0,#0x1                     ! 071a: a800
	.long_addr
	ldar rr8,L_0706                   ! 071c: 3408ffe6
	ldar rr4,L_0a60                   ! 0720: 3404033c
	.long_addr
	lda rr10,0x1e58                   ! 0724: 760a80001e58
	.long_addr
	lda rr12,0x21d4                   ! 072a: 760c800021d4
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
	call 0x2722                       ! 07c2: 5f0080002722
	or r7,r7                          ! 07c8: 8577
	.long_addr
	jp ne,0xdc6                       ! 07ca: 5e0e80000dc6
	calr L_098c                       ! 07d0: df23
	.long_addr
	decb 0x10002fc,#0x2               ! 07d2: 6a01810002fc
	ldar rr2,L_0852                   ! 07d8: 34020076
	.long_addr
	call 0x2814                       ! 07dc: 5f0080002814
	or r7,r7                          ! 07e2: 8577
	.long_addr
	jp ne,0xdc6                       ! 07e4: 5e0e80000dc6
	ldb rh0,#0xe4                     ! 07ea: c0e4
	calr L_082c                       ! 07ec: dfe1
	jr ne,L_0802                      ! 07ee: ee09
	.long_addr
	lda rr4,0x1e58                    ! 07f0: 760480001e58
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
	lda rr4,0x14ae                    ! 085e: 7604800014ae
	cp r4,r5                          ! 0864: 8b54
	ret eq                            ! 0866: 9e06
	calr L_09de                       ! 0868: df46
	or r7,r7                          ! 086a: 8577
	jr eq,L_0880                      ! 086c: e609
L_086e:
	.long_addr
	ldb rh1,0x1000302                 ! 086e: 600181000302
	.long_addr
	call 0xeae                        ! 0874: 5f0080000eae
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
	lda rr2,0x3c000000                ! 089e: 76023c00
	.long_addr
	ldb rl0,0x1000303                 ! 08a2: 600881000303
	.long_addr
	call 0x14ae                       ! 08a8: 5f00800014ae
	.long_addr
	ldb rh1,0x1000302                 ! 08ae: 600181000302
	ldb rl1,#0xed                     ! 08b4: c9ed
	inb rl0,@r1                       ! 08b6: 3c18
	bitb rl0,#0x3                     ! 08b8: a683
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
L_08fe:
	lda rr2,0x3c000000                ! 08fe: 76023c00
	clr r4                            ! 0902: 8d48
L_0904:
	cpb rl3,@rr2                      ! 0904: 0a2b
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
	ldl rr0,@rr2                      ! 0918: 1420
	cpl rr0,#0x53595330               ! 091a: 100053595330
	jr eq,L_0926                      ! 0920: e602
	ldk r7,#0x8                       ! 0922: bd78
	ret t                             ! 0924: 9e08
L_0926:
	sub r7,r7                         ! 0926: 8377
	.long_addr
	call 0xd10                        ! 0928: 5f0080000d10
	ldctl r6,psapseg                  ! 092e: 7d64
	ldctl r7,psapoff                  ! 0930: 7d75
	.long_addr
	lda rr8,0x10001c0                 ! 0932: 7608810001c0
	ldb rl7,#0x3c                     ! 0938: cf3c
	ld r0,#0x20                       ! 093a: 21000020
	ldir @rr6,@rr8,r0                 ! 093e: bb810060
	ldl rr2,rr2(#0x4)                 ! 0942: 35220004
	ldl rr4,rr2                       ! 0946: 9424
	ld r0,#0x3c                       ! 0948: 2100003c
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
	lda rr14,0x10001c0                ! 0984: 760e810001c0
	jp t,@rr4                         ! 098a: 1e48
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
	jp t,0x1d3a                       ! 0a62: 5e0880001d3a
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
	lda rr14,0xfe                     ! 0a94: 760e00fe
	ld r1,#0x100                      ! 0a98: 21010100
L_0a9c:
	ldar rr12,L_0aa8                  ! 0a9c: 340c0008
	.long_addr
	lda rr2,0x3c00c000                ! 0aa0: 7602bc00c000
	ldb rh0,#0x0                      ! 0aa6: c000
L_0aa8:
	add r3,#0x4000                    ! 0aa8: 01034000
	jr nc/uge,L_0ad8                  ! 0aac: ef15
	incb rh1,#0x1                     ! 0aae: a810
	cpb rh1,#0xf0                     ! 0ab0: 0a01f0f0
	jr ne,L_0abc                      ! 0ab4: ee03
	orb rh0,rh0                       ! 0ab6: 8400
	jr ne,L_0aea                      ! 0ab8: ee18
	jr t,L_0b0a                       ! 0aba: e827
L_0abc:
	ldb rl0,#0x3c                     ! 0abc: c83c
	soutb #0x100,rl0                  ! 0abe: 3a870100
	soutb #0x2000,rl1                 ! 0ac2: 3a972000
	soutb #0xf00,rh1                  ! 0ac6: 3a170f00
	soutb #0xf00,rl1                  ! 0aca: 3a970f00
	ldb rl0,#0xff                     ! 0ace: c8ff
	soutb #0xf00,rl0                  ! 0ad0: 3a870f00
	soutb #0xf00,rl1                  ! 0ad4: 3a970f00
L_0ad8:
	ld r6,@rr2                        ! 0ad8: 2126
	orb rh0,rh0                       ! 0ada: 8400
	jr ne,L_0aa8                      ! 0adc: eee5
	incb rh0,#0x1                     ! 0ade: a800
	ld r4,r1                          ! 0ae0: a114
	ld r5,r3                          ! 0ae2: a135
	ldar rr12,L_0aea                  ! 0ae4: 340c0002
	jr t,L_0aa8                       ! 0ae8: e8df
L_0aea:
	ld r6,r1                          ! 0aea: a116
	ld r7,r3                          ! 0aec: a137
	ldl rr2,rr6                       ! 0aee: 9462
	ldl rr12,rr4                      ! 0af0: 944c
	srl r2,#0x8                       ! 0af2: b321fff8
	srl r12,#0x8                      ! 0af6: b3c1fff8
	subl rr2,rr12                     ! 0afa: 92c2
	subl rr2,#0x4000                  ! 0afc: 120200004000
	jp nc/uge,@rr10                   ! 0b02: 1eaf
	cpb rh1,#0xf0                     ! 0b04: 0a01f0f0
	jr ne,L_0a9c                      ! 0b08: eec9
L_0b0a:
	setflg c                          ! 0b0a: 8d81
	jp t,@rr10                        ! 0b0c: 1ea8
	ldk r1,#0x2                       ! 0b0e: bd12
	soutb #0x100,rl1                  ! 0b10: 3a970100
	soutb #0x2000,rh1                 ! 0b14: 3a172000
L_0b18:
	soutb #0xf00,rh4                  ! 0b18: 3a470f00
	soutb #0xf00,rh5                  ! 0b1c: 3a570f00
	ldb rl0,#0x0                      ! 0b20: c800
L_0b22:
	add r5,#0x100                     ! 0b22: 01050100
	jr nc/uge,L_0b2a                  ! 0b26: ef01
	incb rh4,#0x1                     ! 0b28: a840
L_0b2a:
	cpl rr6,rr4                       ! 0b2a: 9046
	jr eq,L_0b40                      ! 0b2c: e609
	incb rl0,#0x1                     ! 0b2e: a880
	jr ne,L_0b22                      ! 0b30: eef8
	decb rl0,#0x1                     ! 0b32: aa80
	soutb #0xf00,rl0                  ! 0b34: 3a870f00
	soutb #0xf00,rh1                  ! 0b38: 3a170f00
	incb rl1,#0x1                     ! 0b3c: a890
	jr t,L_0b18                       ! 0b3e: e8ec
L_0b40:
	soutb #0xf00,rl0                  ! 0b40: 3a870f00
	soutb #0xf00,rh1                  ! 0b44: 3a170f00
	ldb rh4,rl1                       ! 0b48: a094
	ldb rh5,rl0                       ! 0b4a: a085
	incb rh5,#0x1                     ! 0b4c: a850
	jr ne,L_0b52                      ! 0b4e: ee01
	incb rh4,#0x1                     ! 0b50: a840
L_0b52:
	ldk r0,#0x1                       ! 0b52: bd01
	soutb #0x100,rl0                  ! 0b54: 3a870100
	soutb #0x2000,rh0                 ! 0b58: 3a072000
	sub r7,#0x400                     ! 0b5c: 03070400
	jr nc/uge,L_0b64                  ! 0b60: ef01
	decb rh6,#0x1                     ! 0b62: aa60
L_0b64:
	soutb #0xf00,rh6                  ! 0b64: 3a670f00
	soutb #0xf00,rh7                  ! 0b68: 3a770f00
	ldk r0,#0x3                       ! 0b6c: bd03
	soutb #0xf00,rl0                  ! 0b6e: 3a870f00
	soutb #0xf00,rh0                  ! 0b72: 3a070f00
	.long_addr
	lda rr14,0x10001c0                ! 0b76: 760e810001c0
	jp t,@rr10                        ! 0b7c: 1ea8
	ldk r1,#0x0                       ! 0b7e: bd10
	ldar rr12,L_0baa                  ! 0b80: 340c0026
	ld r0,r7                          ! 0b84: a170
	addb rl0,#0x30                    ! 0b86: 00083030
	cpb rl0,#0x3a                     ! 0b8a: 0a083a3a
	jr c/ult,L_0b92                   ! 0b8e: e701
	incb rl0,#0x7                     ! 0b90: a886
L_0b92:
	ldb 0x3d000001(r1),rl0            ! 0b92: 6e183d01
	ldb 0x3d000005(r1),#0x20          ! 0b96: 4c153d052020
	ldb 0x3d000009(r1),#0x20          ! 0b9c: 4c153d092020
	add r1,#0x2000                    ! 0ba2: 01012000
	jr ne,L_0b92                      ! 0ba6: eef5
	jr t,L_0baa                       ! 0ba8: e800
L_0baa:
	outb #0xffe0,rl7                  ! 0baa: 3af6ffe0
	ldk r0,#0x3                       ! 0bae: bd03
L_0bb0:
	ld r1,#0xff64                     ! 0bb0: 2101ff64
	add r1,r0                         ! 0bb4: 8101
	bit r7,r0                         ! 0bb6: 27000700
	jr eq,L_0bbe                      ! 0bba: e601
	set r1,#0x3                       ! 0bbc: a513
L_0bbe:
	outb @r1,rl1                      ! 0bbe: 3e19
	dec r0,#0x1                       ! 0bc0: ab00
	jr pl,L_0bb0                      ! 0bc2: edf6
	jp t,@rr10                        ! 0bc4: 1ea8
	ldb rl1,#0x81                     ! 0bc6: c981
	inb rl2,@r1                       ! 0bc8: 3c1a
	and r2,#0x7                       ! 0bca: 07020007
	add r2,r2                         ! 0bce: 8122
	ldar rr4,L_0c44                   ! 0bd0: 34040070
	ld r0,rr4(r2)                     ! 0bd4: 71400200
	add r5,r0                         ! 0bd8: 8105
	test @rr4                         ! 0bda: 0d44
	jr eq,L_0c34                      ! 0bdc: e62b
	ldb rl1,@rr4                      ! 0bde: 2049
	outb @r1,rl1                      ! 0be0: 3e19
	inc r5,#0x1                       ! 0be2: a950
	ldb rl1,@rr4                      ! 0be4: 2049
	outb @r1,rl1                      ! 0be6: 3e19
	inc r5,#0x1                       ! 0be8: a950
	ldb rh0,#0x10                     ! 0bea: c010
	sub r2,r2                         ! 0bec: 8322
L_0bee:
	ldb rl1,#0x41                     ! 0bee: c941
	outb @r1,rl2                      ! 0bf0: 3e1a
	ldb rl0,rr4(r2)                   ! 0bf2: 70480200
	ldb rl1,#0x43                     ! 0bf6: c943
	outb @r1,rl0                      ! 0bf8: 3e18
	inc r2,#0x1                       ! 0bfa: a920
	dbjnz rh0,L_0bee                  ! 0bfc: f008
	lda rr2,0x3d000000                ! 0bfe: 76023d00
	ld r3,r7                          ! 0c02: a173
	ld r5,#0x800                      ! 0c04: 21050800
	ld r0,#0x20                       ! 0c08: 21000020
L_0c0c:
	ld @rr2,r0                        ! 0c0c: 2f20
	cp r0,@rr2                        ! 0c0e: 0b20
	jr ne,L_0c16                      ! 0c10: ee02
	inc r3,#0x2                       ! 0c12: a931
	djnz r5,L_0c0c                    ! 0c14: f585
L_0c16:
	and r3,#0x7ff                     ! 0c16: 070307ff
	jr ne,L_0c34                      ! 0c1a: ee0c
	ldb rl1,#0x1                      ! 0c1c: c901
	ldb rl0,#0x3                      ! 0c1e: c803
	outb @r1,rl0                      ! 0c20: 3e18
	ldb rl1,#0x81                     ! 0c22: c981
	ldb rl2,#0x8                      ! 0c24: ca08
	inb rl0,@r1                       ! 0c26: 3c18
	andb rl0,rl2                      ! 0c28: 86a8
L_0c2a:
	inb rh0,@r1                       ! 0c2a: 3c10
	andb rh0,rl2                      ! 0c2c: 86a0
	xorb rh0,rl0                      ! 0c2e: 8880
	jr ne,L_0c3c                      ! 0c30: ee05
	djnz r3,L_0c2a                    ! 0c32: f385
L_0c34:
	resflg z                          ! 0c34: 8d43
	ld r0,#0xffff                     ! 0c36: 2100ffff
	jp t,@rr10                        ! 0c3a: 1ea8
L_0c3c:
	ldb rl1,#0x6a                     ! 0c3c: c96a
	outb @r1,rl1                      ! 0c3e: 3e19
	sub r0,r0                         ! 0c40: 8300
	jp t,@rr10                        ! 0c42: 1ea8
L_0c44:
	.word	0x0010		! 0c44: addb rh0,@rr1
	addb rh2,@rr2                     ! 0c46: 0022
	.word	0x0034		! 0c48: addb rh4,@rr3
	addb rh6,@rr4                     ! 0c4a: 0046
	.word	0x0058		! 0c4c: addb rl0,@rr5
	addb rl6,@rr8                     ! 0c4e: 008e
	addb rl2,@rr6                     ! 0c50: 006a
	.word	0x007c		! 0c52: addb rl4,@rr7
	exb rh0,0x69000050(r6)            ! 0c54: 6c606950
	.word	0x530a		! 0c58: .word 530a
	mult rr0,#0x1919                  ! 0c5a: 19001919
	.word	0x0010		! 0c5e: addb rh0,@rr1
	cp r11,0x0                        ! 0c60: 4b0b0000
	out @r15,r15                      ! 0c64: 3fff
	setb 0x69000050(r6),#0x0          ! 0c66: 64606950
	.word	0x530a		! 0c6a: .word 530a
	.word	0x1905		! 0c6c: mult rr5,#0x1919
	.word	0x1919		! 0c6e: mult rr5,#0x1919
	.word	0x000b		! 0c70: addb rl3,#0xb
	.word	0x4b0b		! 0c72: addb rl3,#0xb
	.word	0x0000		! 0c74: addb rh0,#0xff
	.word	0x3fff		! 0c76: addb rh0,#0xff
	exb rl0,0x34000028(r6)            ! 0c78: 6c683428
	.word	0x2a07		! 0c7c: .word 2a07
	.word	0x0d01		! 0c7e: .word 0d01
	.word	0x0d0d		! 0c80: .word 0d0d
	.word	0x000f		! 0c82: addb rl7,#0xb
	.word	0x6b0b		! 0c84: addb rl7,#0xb
	.word	0x0000		! 0c86: addb rh0,#0xff
	.word	0x3fff		! 0c88: addb rh0,#0xff
	setb 0x68000050(r6),#0x0          ! 0c8a: 64606850
	.word	0x530a		! 0c8e: .word 530a
	.word	0x1905		! 0c90: mult rr5,#0x1919
	.word	0x1919		! 0c92: mult rr5,#0x1919
	.word	0x000b		! 0c94: addb rl3,#0xb
	.word	0x4b0b		! 0c96: addb rl3,#0xb
	.word	0x0000		! 0c98: addb rh0,#0xff
	.word	0x3fff		! 0c9a: addb rh0,#0xff
	exb rh0,0x67000050(r6)            ! 0c9c: 6c606750
	addl rr10,0x19000009              ! 0ca0: 560a1909
	.word	0x1919		! 0ca4: mult rr9,@rr1
	.word	0x000f		! 0ca6: addb rl7,#0xb
	.word	0x4b0b		! 0ca8: addb rl7,#0xb
	.word	0x0000		! 0caa: addb rh0,#0xff
	.word	0x3fff		! 0cac: addb rh0,#0xff
	exb rl0,0x34000028(r6)            ! 0cae: 6c683428
	.word	0x2a06		! 0cb2: .word 2a06
	ext0e #0x0                        ! 0cb4: 0e00
	.word	0x0d0d		! 0cb6: .word 0d0d
	.word	0x000f		! 0cb8: addb rl7,#0xb
	.word	0x6b0b		! 0cba: addb rl7,#0xb
	.word	0x0000		! 0cbc: addb rh0,#0xff
	.word	0x3fff		! 0cbe: addb rh0,#0xff
	setb 0x6b000050(r6),#0x0          ! 0cc0: 64606b50
	mult rr10,0x1a000011              ! 0cc4: 590a1a11
	.word	0x1919		! 0cc8: mult rr9,@rr1
	.word	0x000b		! 0cca: addb rl3,#0xb
	.word	0x4b0b		! 0ccc: addb rl3,#0xb
	.word	0x0000		! 0cce: addb rh0,#0xff
	.word	0x3fff		! 0cd0: addb rh0,#0xff
	.word	0x0000		! 0cd2: addb rh0,#0xe4
L_0cd4:
	.word	0x91e4		! 0cd4: addb rh0,#0xe4
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
L_0eae:
	push @rr14,r0                     ! 0eae: 93e0
	.long_addr
	clrb 0x1000354                    ! 0eb0: 4c0881000354
	calr L_12ca                       ! 0eb6: ddf7
	ldb rl0,#0x32                     ! 0eb8: c832
L_0eba:
	dbjnz rl0,L_0eba                  ! 0eba: f801
	pop r0,@rr14                      ! 0ebc: 97e0
	ret t                             ! 0ebe: 9e08
L_0ec0:
	pushl @rr14,rr0                   ! 0ec0: 91e0
	pushl @rr14,rr2                   ! 0ec2: 91e2
	pushl @rr14,rr8                   ! 0ec4: 91e8
	ldctl r2,fcw                      ! 0ec6: 7d22
	di vi                             ! 0ec8: 7c01
	.long_addr
	ldb rh1,0x1000302                 ! 0eca: 600181000302
	calr L_0eae                       ! 0ed0: d012
	.long_addr
	clrb 0x100034d                    ! 0ed2: 4c088100034d
	.long_addr
	clrb 0x100034e                    ! 0ed8: 4c088100034e
	ldb rl1,#0x9f                     ! 0ede: c99f
	ldb rl0,#0x50                     ! 0ee0: c850
	outb @r1,rl0                      ! 0ee2: 3e18
	ldb rl1,#0xe7                     ! 0ee4: c9e7
	inb rl0,@r1                       ! 0ee6: 3c18
	.long_addr
	ldb 0x1000354,#0x13               ! 0ee8: 4c0581000354
	calr L_12ca                       ! 0ef0: de14
	ldb rl1,#0x1d                     ! 0ef2: c91d
	inb rl0,@r1                       ! 0ef4: 3c18
	ldb rl0,#0x20                     ! 0ef6: c820
	ldb rl1,#0x50                     ! 0ef8: c950
	outb @r1,rl0                      ! 0efa: 3e18
	calr L_12da                       ! 0efc: de12
	ldar rr8,L_0f2a                   ! 0efe: 34080028
	jr ne,L_0f10                      ! 0f02: ee06
	calr L_0f2e                       ! 0f04: dfec
	ldar rr8,L_0f26                   ! 0f06: 3408001c
	jr ne,L_0f10                      ! 0f0a: ee02
	ldar rr8,L_0f22                   ! 0f0c: 34080012
L_0f10:
	calr L_1172                       ! 0f10: ded0
	ldctl fcw,r2                      ! 0f12: 7d2a
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
	ldb rh1,0x1000302                 ! 0f30: 600181000302
	ldb rl1,#0xff                     ! 0f36: c9ff
	inb rl0,@r1                       ! 0f38: 3c18
	bitb rl0,#0x0                     ! 0f3a: a680
	jr ne,L_0f44                      ! 0f3c: ee03
	ldb rl1,#0xed                     ! 0f3e: c9ed
	inb rl0,@r1                       ! 0f40: 3c18
	bitb rl0,#0x0                     ! 0f42: a680
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
	lda rr8,0x1000334                 ! 111a: 760881000334
	ld @rr8,#0x207                    ! 1120: 0d850207
	.long_addr
	ldb rl0,0x1000303                 ! 1124: 600881000303
	andb rl0,#0x3                     ! 112a: 06080303
	ldb rr8(#0x2),rl0                 ! 112e: 32880002
	calr L_1172                       ! 1132: dfe1
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
L_1154:
	push @rr14,r2                     ! 1154: 93e2
	ld r2,#0x0                        ! 1156: 21020000
L_115a:
	ldb rl0,#0x14                     ! 115a: c814
L_115c:
	dbjnz rl0,L_115c                  ! 115c: f801
	dec r2,#0x1                       ! 115e: ab20
	jr eq,L_116e                      ! 1160: e606
	ldb rl1,#0x1d                     ! 1162: c91d
	inb rl0,@r1                       ! 1164: 3c18
	ldb rl1,rl0                       ! 1166: a089
	rlb rl0,#0x1                      ! 1168: b280
	jr nc/uge,L_115a                  ! 116a: eff7
	rlb rl0,#0x1                      ! 116c: b280
L_116e:
	pop r2,@rr14                      ! 116e: 97e2
	ret t                             ! 1170: 9e08
L_1172:
	pushl @rr14,rr0                   ! 1172: 91e0
	pushl @rr14,rr2                   ! 1174: 91e2
	pushl @rr14,rr4                   ! 1176: 91e4
	pushl @rr14,rr6                   ! 1178: 91e6
	pushl @rr14,rr8                   ! 117a: 91e8
	.long_addr
	ldb rh1,0x1000302                 ! 117c: 600181000302
	ldb rl1,#0x1d                     ! 1182: c91d
	inb rh6,@r1                       ! 1184: 3c16
	andb rh6,#0x1f                    ! 1186: 06061f1f
	jr ne,L_124c                      ! 118a: ee60
	ldb rl1,#0x9f                     ! 118c: c99f
	ldb rl0,rr8(#0x1)                 ! 118e: 30880001
	andb rl0,#0xf                     ! 1192: 06080f0f
	cpb rl0,#0xd                      ! 1196: 0a080d0d
	ldb rl0,#0x98                     ! 119a: c898
	jr eq,L_11a6                      ! 119c: e604
	ldb rl0,#0x90                     ! 119e: c890
	outb @r1,rl0                      ! 11a0: 3e18
	ldb rl1,#0x9d                     ! 11a2: c99d
	ldb rl0,#0x2                      ! 11a4: c802
L_11a6:
	outb @r1,rl0                      ! 11a6: 3e18
	clr r2                            ! 11a8: 8d28
	ldb rl0,#0x8                      ! 11aa: c808
L_11ac:
	.long_addr
	clr 0x100033a(r2)                 ! 11ac: 4d288100033a
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
	out #0xff84,r0                    ! 1216: 3b06ff84
	.long_addr
	ldb rl2,0x1000354                 ! 121a: 600a81000354
	set r2,r3                         ! 1220: 25030200
	.long_addr
	ldb 0x1000354,rl2                 ! 1224: 6e0a81000354
	calr L_12ca                       ! 122a: dfb1
	out #0xff8c,r0                    ! 122c: 3b06ff8c
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
	calr L_1150                       ! 1260: d089
	jr c/ult,L_129e                   ! 1262: e71d
	out #0xff84,r0                    ! 1264: 3b06ff84
	outib @r1,@rr8,r4                 ! 1268: 3a820418
	jr nov/po,L_1260                  ! 126c: ecf9
	out #0xff8c,r0                    ! 126e: 3b06ff8c
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
	out #0xff8c,r0                    ! 129e: 3b06ff8c
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
	pushl @rr14,rr0                   ! 12ca: 91e0
	ldb rl1,#0xe7                     ! 12cc: c9e7
	.long_addr
	ldb rl0,0x1000354                 ! 12ce: 600881000354
	outb @r1,rl0                      ! 12d4: 3e18
	popl rr0,@rr14                    ! 12d6: 95e0
	ret t                             ! 12d8: 9e08
L_12da:
	pushl @rr14,rr0                   ! 12da: 91e0
	.long_addr
	ldb rh1,0x1000302                 ! 12dc: 600181000302
	ldb rl1,#0xff                     ! 12e2: c9ff
	inb rl0,@r1                       ! 12e4: 3c18
	bitb rl0,#0x0                     ! 12e6: a680
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
	ldb rl1,#0x9f                     ! 146e: c99f
	ldb rl0,#0x50                     ! 1470: c850
	outb @r1,rl0                      ! 1472: 3e18
	ld r0,#0x13c2                     ! 1474: 210013c2
	.long_addr
	ld 0x1000352,r0                   ! 1478: 6f0081000352
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
	pushl @rr14,rr0                   ! 14ae: 91e0
	pushl @rr14,rr6                   ! 14b0: 91e6
	pushl @rr14,rr8                   ! 14b2: 91e8
	.long_addr
	clr 0x100034a                     ! 14b4: 4d088100034a
	.long_addr
	ldb 0x1000303,rl0                 ! 14ba: 6e0881000303
	calr L_1116                       ! 14c0: d1d6
	ldar rr8,L_1614                   ! 14c2: 3408014e
	.long_addr
	test 0x100034a                    ! 14c6: 4d048100034a
	jp ne,@rr8                        ! 14cc: 1e8e
	calr L_12da                       ! 14ce: d0fb
	ld r0,#0x800                      ! 14d0: 21000800
	ldar rr6,L_17dc                   ! 14d4: 34060304
	jr eq,L_14e2                      ! 14d8: e604
	ld r0,#0xd00                      ! 14da: 21000d00
	ldar rr6,L_17e6                   ! 14de: 34060304
L_14e2:
	.long_addr
	lda rr8,0x1000320                 ! 14e2: 760881000320
	ld r1,#0xa                        ! 14e8: 2101000a
	ldirb @rr8,@rr6,r1                ! 14ec: ba610180
	.long_addr
	lda rr8,0x1000320                 ! 14f0: 760881000320
	.long_addr
	ldb rl1,0x1000303                 ! 14f6: 600981000303
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
L_17dc:
	xor r6,#0x0                       ! 17dc: 09060000
	.word	0x0001		! 17e0: addb rh1,#0x10
	.word	0x0010		! 17e2: addb rh1,#0x10
	.word	0x10ff		! 17e4: cpl rr15,@rr15
L_17e6:
	xor r6,#0x0                       ! 17e6: 09060000
	.word	0x0001		! 17ea: addb rh1,#0x1a
	.word	0x001a		! 17ec: addb rh1,#0x1a
	.word	0x07ff		! 17ee: and r15,@rr15
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
	.long_addr
	lda rr4,0x10001c0                 ! 1d48: 7604810001c0
	ld r1,r7                          ! 1d4e: a171
	add r1,r1                         ! 1d50: 8111
	add r5,r1                         ! 1d52: 8115
	ldar rr2,L_22ca                   ! 1d54: 34020572
	ldl @rr4,rr2                      ! 1d58: 1d42
	.long_addr
	ldb rh2,0x1000302                 ! 1d5a: 600281000302
	ld r3,r7                          ! 1d60: a173
	calr L_237a                       ! 1d62: dcf5
	ldar rr12,L_24be                  ! 1d64: 340c0756
	ldar rr8,L_25c2                   ! 1d68: 34080856
	calr L_2266                       ! 1d6c: dd84
	jr eq,L_1e44                      ! 1d6e: e66a
	ldb rl0,#0x1e                     ! 1d70: c81e
	.long_addr
	call 0xe76                        ! 1d72: 5f0080000e76
	.long_addr
	call 0xde4                        ! 1d78: 5f0080000de4
L_1d7e:
	.long_addr
	testb 0x100030f                   ! 1d7e: 4c048100030f
	jr ne,L_1d7e                      ! 1d84: eefc
	.long_addr
	lda rr4,0x1000270                 ! 1d86: 760481000270
	ldb rl2,#0x7                      ! 1d8c: ca07
L_1d8e:
	clrb @rr4                         ! 1d8e: 0c48
	inc r5,#0x1                       ! 1d90: a950
	dbjnz rl2,L_1d8e                  ! 1d92: fa03
	.long_addr
	clr 0x1000334                     ! 1d94: 4d0881000334
L_1d9a:
	.long_addr
	ld r3,0x1000334                   ! 1d9a: 610381000334
	inc r3,#0x1                       ! 1da0: a930
	cp r3,#0x5                        ! 1da2: 0b030005
	clr r7                            ! 1da6: 8d78
	jr eq,L_1e48                      ! 1da8: e64f
	.long_addr
	ld 0x1000334,r3                   ! 1daa: 6f0381000334
	.long_addr
	lda rr4,0x1000270                 ! 1db0: 760481000270
	dec r3,#0x1                       ! 1db6: ab30
	add r5,r3                         ! 1db8: 8135
	testb @rr4                        ! 1dba: 0c44
	jr ne,L_1d9a                      ! 1dbc: eeee
	.long_addr
	ldb rh2,0x1000302                 ! 1dbe: 600281000302
	inc r3,#0x1                       ! 1dc4: a930
	calr L_22d2                       ! 1dc6: dd7b
	cp r7,#0x14                       ! 1dc8: 0b070014
	jr eq,L_1d9a                      ! 1dcc: e6e6
	test r7                           ! 1dce: 8d74
	jr ne,L_1e3e                      ! 1dd0: ee36
	ldar rr12,L_2514                  ! 1dd2: 340c073e
	ldar rr8,L_263c                   ! 1dd6: 34080862
	calr L_2266                       ! 1dda: ddbb
	jr eq,L_1e44                      ! 1ddc: e633
	inc r5,#0x1                       ! 1dde: a950
	.long_addr
	ldl rr2,0x1000318                 ! 1de0: 540281000318
	inc r3,#0x2                       ! 1de6: a931
	ldl rr4,#0x81000270               ! 1de8: 140481000270
	.long_addr
	ld r2,0x1000334                   ! 1dee: 610281000334
	dec r2,#0x1                       ! 1df4: ab20
	add r5,r2                         ! 1df6: 8125
	ldb @rr4,rl3                      ! 1df8: 2e4b
	ld r3,#0x1                        ! 1dfa: 21030001
L_1dfe:
	push @rr14,r3                     ! 1dfe: 93e3
	ldar rr12,L_251e                  ! 1e00: 340c071a
	ldar rr8,L_2640                   ! 1e04: 34080838
	calr L_2266                       ! 1e08: ddd2
	pop r3,@rr14                      ! 1e0a: 97e3
	jr eq,L_1e44                      ! 1e0c: e61b
	.long_addr
	lda rr4,0x1000318                 ! 1e0e: 760481000318
	ld r2,@rr4                        ! 1e14: 2142
	cpb rl3,rl2                       ! 1e16: 8aab
	jr ne,L_1e44                      ! 1e18: ee15
	cpb rl3,#0xff                     ! 1e1a: 0a0bffff
	jr eq,L_1e2e                      ! 1e1e: e607
	com r3                            ! 1e20: 8d30
	cpb rh3,#0x0                      ! 1e22: 0a030000
	jr ne,L_1e2c                      ! 1e26: ee02
	sllb rl3,#0x1                     ! 1e28: b2b10001
L_1e2c:
	jr t,L_1dfe                       ! 1e2c: e8e8
L_1e2e:
	.long_addr
	ld r3,0x1000334                   ! 1e2e: 610381000334
	cp r3,#0x4                        ! 1e34: 0b030004
	jr ne,L_1d9a                      ! 1e38: eeb0
	clr r7                            ! 1e3a: 8d78
	jr t,L_1e48                       ! 1e3c: e805
L_1e3e:
	ld r7,#0x2                        ! 1e3e: 21070002
	jr t,L_1e48                       ! 1e42: e802
L_1e44:
	ld r7,#0x1                        ! 1e44: 21070001
L_1e48:
	popl rr12,@rr14                   ! 1e48: 95ec
	popl rr10,@rr14                   ! 1e4a: 95ea
	popl rr8,@rr14                    ! 1e4c: 95e8
	pop r6,@rr14                      ! 1e4e: 97e6
	popl rr4,@rr14                    ! 1e50: 95e4
	popl rr2,@rr14                    ! 1e52: 95e2
	popl rr0,@rr14                    ! 1e54: 95e0
	ret t                             ! 1e56: 9e08
	pushl @rr14,rr0                   ! 1e58: 91e0
	pushl @rr14,rr2                   ! 1e5a: 91e2
	pushl @rr14,rr4                   ! 1e5c: 91e4
	push @rr14,r6                     ! 1e5e: 93e6
	pushl @rr14,rr8                   ! 1e60: 91e8
	pushl @rr14,rr10                  ! 1e62: 91ea
	.long_addr
	lda rr8,0x1000354                 ! 1e64: 760881000354
	ld r1,#0xb                        ! 1e6a: 2101000b
	pushl @rr14,rr2                   ! 1e6e: 91e2
	pushl @rr14,rr8                   ! 1e70: 91e8
	ldirb @rr8,@rr2,r1                ! 1e72: ba210180
	popl rr8,@rr14                    ! 1e76: 95e8
	popl rr2,@rr14                    ! 1e78: 95e2
	calr L_21d4                       ! 1e7a: de54
	ld r7,#0x1                        ! 1e7c: 21070001
	jr c/ult,L_1ea4                   ! 1e80: e711
	ldl rr0,#0x0                      ! 1e82: 140000000000
	ldl rr2,rr8(#0x6)                 ! 1e88: 35820006
	clr r10                           ! 1e8c: 8da8
	ld r11,r6                         ! 1e8e: a16b
	mult rr10,r5                      ! 1e90: 995a
	divl rq0,rr10                     ! 1e92: 9aa0
	ld rr8(#0x6),r3                   ! 1e94: 33830006
	div rr0,r6                        ! 1e98: 9b60
	ldb rr8(#0x8),rl1                 ! 1e9a: 32890008
	ldb rr8(#0x9),rl0                 ! 1e9e: 32880009
	calr L_1ed0                       ! 1ea2: dfea
L_1ea4:
	popl rr10,@rr14                   ! 1ea4: 95ea
	popl rr8,@rr14                    ! 1ea6: 95e8
	pop r6,@rr14                      ! 1ea8: 97e6
	popl rr4,@rr14                    ! 1eaa: 95e4
	popl rr2,@rr14                    ! 1eac: 95e2
	popl rr0,@rr14                    ! 1eae: 95e0
	ret t                             ! 1eb0: 9e08
	push @rr14,r1                     ! 1eb2: 93e1
	pushl @rr14,rr2                   ! 1eb4: 91e2
	pushl @rr14,rr8                   ! 1eb6: 91e8
	.long_addr
	lda rr8,0x1000354                 ! 1eb8: 760881000354
	ld r1,#0xb                        ! 1ebe: 2101000b
	ldirb @rr8,@rr2,r1                ! 1ec2: ba210180
	calr L_1ed0                       ! 1ec6: dffc
	popl rr8,@rr14                    ! 1ec8: 95e8
	popl rr2,@rr14                    ! 1eca: 95e2
	pop r1,@rr14                      ! 1ecc: 97e1
	ret t                             ! 1ece: 9e08
L_1ed0:
	pushl @rr14,rr0                   ! 1ed0: 91e0
	pushl @rr14,rr2                   ! 1ed2: 91e2
	pushl @rr14,rr4                   ! 1ed4: 91e4
	push @rr14,r6                     ! 1ed6: 93e6
	pushl @rr14,rr8                   ! 1ed8: 91e8
	pushl @rr14,rr10                  ! 1eda: 91ea
	pushl @rr14,rr12                  ! 1edc: 91ec
	.long_addr
	ldb rh2,0x1000302                 ! 1ede: 600281000302
	.long_addr
	ldb rl3,0x1000303                 ! 1ee4: 600b81000303
	calr L_22d2                       ! 1eea: de0d
	test r7                           ! 1eec: 8d74
	ldar rr12,L_21c4                  ! 1eee: 340c02d2
	ldk r7,#0x2                       ! 1ef2: bd72
	jp ne,@rr12                       ! 1ef4: 1ece
	.long_addr
	lda rr8,0x1000354                 ! 1ef6: 760881000354
	.long_addr
	lda rr2,0x100036c                 ! 1efc: 76028100036c
	ld r1,#0xb                        ! 1f02: 2101000b
	ldirb @rr2,@rr8,r1                ! 1f06: ba810120
L_1f0a:
	.long_addr
	lda rr8,0x1000354                 ! 1f0a: 760881000354
	.long_addr
	lda rr2,0x100036c                 ! 1f10: 76028100036c
	ld r1,#0xb                        ! 1f16: 2101000b
	ldirb @rr8,@rr2,r1                ! 1f1a: ba210180
	.long_addr
	lda rr8,0x1000354                 ! 1f1e: 760881000354
	ldl rr2,@rr8                      ! 1f24: 1482
L_1f26:
	.long_addr
	ldar rr10,L_1f26                  ! 1f26: 340afffc
	ld r11,#0xa70                     ! 1f2a: 210b0a70
	call @rr10                        ! 1f2e: 1fa0
	ldl @rr8,rr2                      ! 1f30: 1d82
	.long_addr
	ldl 0x1000310,rr2                 ! 1f32: 5d0281000310
	ldl rr4,rr2                       ! 1f38: 9424
	.long_addr
	ldb rh2,0x1000302                 ! 1f3a: 600281000302
	calr L_24ae                       ! 1f40: dd4a
	.long_addr
	lda rr8,0x1000354                 ! 1f42: 760881000354
	ld r2,rr8(#0x4)                   ! 1f48: 31820004
	cpb rl2,#0x0                      ! 1f4c: 0a0a0000
	jr eq,L_1f54                      ! 1f50: e601
	incb rh2,#0x1                     ! 1f52: a820
L_1f54:
	ldb rl2,rh2                       ! 1f54: a02a
	clrb rh2                          ! 1f56: 8c28
	ld rr8(#0x4),r2                   ! 1f58: 33820004
L_1f5c:
	ldb rl3,#0x3                      ! 1f5c: cb03
	.long_addr
	ldb 0x1000315,rl3                 ! 1f5e: 6e0b81000315
	.long_addr
	lda rr8,0x1000354                 ! 1f64: 760881000354
	ld r3,rr8(#0x6)                   ! 1f6a: 31830006
	ldar rr12,L_24ce                  ! 1f6e: 340c055c
	ldar rr8,L_25c8                   ! 1f72: 34080652
	calr L_2266                       ! 1f76: de89
	test r7                           ! 1f78: 8d74
	ldar rr12,L_21a8                  ! 1f7a: 340c022a
	jp ne,@rr12                       ! 1f7e: 1ece
	.long_addr
	ldb rh2,0x1000302                 ! 1f80: 600281000302
	.long_addr
	lda rr8,0x1000354                 ! 1f86: 760881000354
	clr r3                            ! 1f8c: 8d38
	clrb rh4                          ! 1f8e: 8c48
	ldb rl4,rr8(#0x8)                 ! 1f90: 308c0008
	calr L_2344                       ! 1f94: de29
	test r7                           ! 1f96: 8d74
	ldar rr12,L_21c4                  ! 1f98: 340c0228
	ldk r7,#0x2                       ! 1f9c: bd72
	jp ne,@rr12                       ! 1f9e: 1ece
	.long_addr
	lda rr8,0x1000354                 ! 1fa0: 760881000354
	calr L_21d4                       ! 1fa6: deea
	ldar rr12,L_21a8                  ! 1fa8: 340c01fc
	jp c/ult,@rr12                    ! 1fac: 1ec7
	clrb rh2                          ! 1fae: 8c28
	ldb rl2,rr8(#0x9)                 ! 1fb0: 308a0009
	sub r6,r2                         ! 1fb4: 8326
	ld r3,rr8(#0x4)                   ! 1fb6: 31830004
	cp r3,r6                          ! 1fba: 8b63
	ld r7,r6                          ! 1fbc: a167
	jr pl,L_1fc2                      ! 1fbe: ed01
	ld r7,r3                          ! 1fc0: a137
L_1fc2:
	sub r3,r7                         ! 1fc2: 8373
	ld rr8(#0x4),r3                   ! 1fc4: 33830004
	.long_addr
	lda rr8,0x1000354                 ! 1fc8: 760881000354
	ld r0,r5                          ! 1fce: a150
	ld r3,#0x1                        ! 1fd0: 21030001
	ld r4,rr8(#0x6)                   ! 1fd4: 31840006
	clrb rh5                          ! 1fd8: 8c58
	ldb rl5,rr8(#0x8)                 ! 1fda: 308d0008
	clrb rh6                          ! 1fde: 8c68
	ldb rl6,rr8(#0x9)                 ! 1fe0: 308e0009
	clrb rh2                          ! 1fe4: 8c28
	ldb rl2,rr8(#0x8)                 ! 1fe6: 308a0008
	incb rl2,#0x1                     ! 1fea: a8a0
	cp r0,r2                          ! 1fec: 8b20
	ldb rr8(#0x8),rl2                 ! 1fee: 328a0008
	clrb rl2                          ! 1ff2: 8ca8
	ldb rr8(#0x9),rl2                 ! 1ff4: 328a0009
	jr ne,L_200a                      ! 1ff8: ee08
	ld r2,rr8(#0x6)                   ! 1ffa: 31820006
	inc r2,#0x1                       ! 1ffe: a920
	ld rr8(#0x6),r2                   ! 2000: 33820006
	clr r2                            ! 2004: 8d28
	ld rr8(#0x8),r2                   ! 2006: 33820008
L_200a:
	.long_addr
	lda rr10,0x1000320                ! 200a: 760a81000320
	ldm @rr10,r3,#0x5                 ! 2010: 1ca90304
L_2014:
	.long_addr
	lda rr8,0x1000354                 ! 2014: 760881000354
	ldb rl2,rr8(#0xa)                 ! 201a: 308a000a
	andb rl2,#0xf                     ! 201e: 060a0f0f
	cpb rl2,#0x8                      ! 2022: 0a0a0808
	jr eq,L_2040                      ! 2026: e60c
	cpb rl2,#0x2                      ! 2028: 0a0a0202
	jr eq,L_2052                      ! 202c: e612
	ldar rr12,L_25a2                  ! 202e: 340c0570
	ldar rr8,L_2712                   ! 2032: 340806dc
	calr L_2266                       ! 2036: dee9
	ldar rr12,L_2156                  ! 2038: 340c011a
	jp ne,@rr12                       ! 203c: 1ece
	jr t,L_2064                       ! 203e: e812
L_2040:
	ldar rr12,L_2526                  ! 2040: 340c04e2
	ldar rr8,L_264e                   ! 2044: 34080606
	calr L_2266                       ! 2048: def2
	ldar rr12,L_2156                  ! 204a: 340c0108
	jp ne,@rr12                       ! 204e: 1ece
	jr t,L_2064                       ! 2050: e809
L_2052:
	ldar rr12,L_25b2                  ! 2052: 340c055c
	ldar rr8,L_271a                   ! 2056: 340806c0
	calr L_2266                       ! 205a: defb
	ldar rr12,L_2156                  ! 205c: 340c00f6
	jp ne,@rr12                       ! 2060: 1ece
	jr t,L_2064                       ! 2062: e800
L_2064:
	cp r7,#0x1                        ! 2064: 0b070001
	jr ne,L_2092                      ! 2068: ee14
	.long_addr
	lda rr4,0x1000318                 ! 206a: 760481000318
	ld r2,@rr4                        ! 2070: 2142
	andb rl2,#0xf                     ! 2072: 060a0f0f
	cpb rl2,#0xe                      ! 2076: 0a0a0e0e
	jr eq,L_207e                      ! 207a: e601
	jr t,L_2092                       ! 207c: e80a
L_207e:
	ldm r3,@rr4,#0x4                  ! 207e: 1c410303
	ld r3,#0xd                        ! 2082: 2103000d
	.long_addr
	lda rr8,0x1000320                 ! 2086: 760881000320
	ld r7,rr8(#0x8)                   ! 208c: 31870008
	jr t,L_2014                       ! 2090: e8c1
L_2092:
	.long_addr
	ldb rl3,0x1000315                 ! 2092: 600b81000315
	testb rl3                         ! 2098: 8cb4
	jr eq,L_20ec                      ! 209a: e628
	decb rl3,#0x1                     ! 209c: aab0
	.long_addr
	ldb 0x1000315,rl3                 ! 209e: 6e0b81000315
	.long_addr
	ldb rh2,0x1000302                 ! 20a4: 600281000302
	.long_addr
	ldl rr4,0x1000310                 ! 20aa: 540481000310
	calr L_24ae                       ! 20b0: de02
	ldar rr12,L_24ee                  ! 20b2: 340c0438
	ldar rr8,L_25cc                   ! 20b6: 34080512
	calr L_2266                       ! 20ba: df2b
	ldar rr12,L_21a8                  ! 20bc: 340c00e8
	jp eq,@rr12                       ! 20c0: 1ec6
	.long_addr
	lda rr8,0x1000320                 ! 20c2: 760881000320
	ld r3,rr8(#0x2)                   ! 20c8: 31830002
	ldar rr12,L_24ce                  ! 20cc: 340c03fe
	ldar rr8,L_25c8                   ! 20d0: 340804f4
	calr L_2266                       ! 20d4: df38
	ldar rr12,L_21a8                  ! 20d6: 340c00ce
	jp eq,@rr12                       ! 20da: 1ec6
	.long_addr
	lda rr8,0x1000320                 ! 20dc: 760881000320
	ldm r3,@rr8,#0x5                  ! 20e2: 1c810304
	.long_addr
	ldar rr12,L_2014                  ! 20e6: 340cff2a
	jp t,@rr12                        ! 20ea: 1ec8
L_20ec:
	cp r7,#0x2                        ! 20ec: 0b070002
	jr ne,L_2184                      ! 20f0: ee49
	.long_addr
	lda rr4,0x1000318                 ! 20f2: 760481000318
	ldm r3,@rr4,#0x5                  ! 20f8: 1c410304
	.long_addr
	lda rr10,0x1000320                ! 20fc: 760a81000320
	ld r7,rr10(#0x8)                  ! 2102: 31a70008
	inc r6,#0x1                       ! 2106: a960
	sub r7,r6                         ! 2108: 8367
	ldm @rr10,r5,#0x5                 ! 210a: 1ca90504
	.long_addr
	lda rr4,0x1000318                 ! 210e: 760481000318
	ldl rr2,rr4(#0x6)                 ! 2114: 35420006
	sll r3,#0x8                       ! 2118: b3310008
	.long_addr
	ldl rr4,0x1000310                 ! 211c: 540481000310
	addl rr4,rr2                      ! 2122: 9624
	.long_addr
	ldb rh2,0x1000302                 ! 2124: 600281000302
	.long_addr
	lda rr6,0x1000318                 ! 212a: 760681000318
	calr L_2382                       ! 2130: ded8
	.long_addr
	lda rr4,0x1000318                 ! 2132: 760481000318
	ld r7,@rr4                        ! 2138: 2147
	cp r7,#0x1                        ! 213a: 0b070001
	ldk r7,#0x2                       ! 213e: bd72
	jr eq,L_2184                      ! 2140: e621
	.long_addr
	lda rr8,0x1000320                 ! 2142: 760881000320
	ldm r3,@rr8,#0x5                  ! 2148: 1c810304
	test r7                           ! 214c: 8d74
	jr eq,L_2156                      ! 214e: e603
	.long_addr
	ldar rr12,L_2014                  ! 2150: 340cfec0
	jp t,@rr12                        ! 2154: 1ec8
L_2156:
	.long_addr
	lda rr8,0x1000354                 ! 2156: 760881000354
	.long_addr
	lda rr2,0x1000320                 ! 215c: 760281000320
	subl rr4,rr4                      ! 2162: 9244
	ldb rh5,rr2(#0x9)                 ! 2164: 30250009
	.long_addr
	ldl rr2,0x1000310                 ! 2168: 540281000310
	addl rr2,rr4                      ! 216e: 9642
	.long_addr
	ldl 0x1000310,rr2                 ! 2170: 5d0281000310
	ld r2,rr8(#0x4)                   ! 2176: 31820004
	cp r2,#0x0                        ! 217a: 0b020000
	.long_addr
	ldar rr12,L_1f5c                  ! 217e: 340cfdda
	jp ne,@rr12                       ! 2182: 1ece
L_2184:
	.long_addr
	lda rr8,0x1000354                 ! 2184: 760881000354
	ldb rl2,rr8(#0xa)                 ! 218a: 308a000a
	andb rl2,#0xf                     ! 218e: 060a0f0f
	cpb rl2,#0x7                      ! 2192: 0a0a0707
	ldb rl2,#0x2                      ! 2196: ca02
	.long_addr
	lda rr10,0x100036c                ! 2198: 760a8100036c
	ldb rr10(#0xa),rl2                ! 219e: 32aa000a
	.long_addr
	ldar rr12,L_1f0a                  ! 21a2: 340cfd64
	jp eq,@rr12                       ! 21a6: 1ec6
L_21a8:
	ldb rl2,rl7                       ! 21a8: a0fa
	cpb rl2,#0x0                      ! 21aa: 0a0a0000
	clr r7                            ! 21ae: 8d78
	jr eq,L_21c4                      ! 21b0: e609
	cpb rl2,#0xff                     ! 21b2: 0a0affff
	ldk r7,#0x1                       ! 21b6: bd71
	jr eq,L_21c4                      ! 21b8: e605
	andb rl2,#0xf0                    ! 21ba: 060af0f0
	ldk r7,#0x2                       ! 21be: bd72
	jr ne,L_21c4                      ! 21c0: ee01
	ldk r7,#0x4                       ! 21c2: bd74
L_21c4:
	popl rr12,@rr14                   ! 21c4: 95ec
	popl rr10,@rr14                   ! 21c6: 95ea
	popl rr8,@rr14                    ! 21c8: 95e8
	pop r6,@rr14                      ! 21ca: 97e6
	popl rr4,@rr14                    ! 21cc: 95e4
	popl rr2,@rr14                    ! 21ce: 95e2
	popl rr0,@rr14                    ! 21d0: 95e0
	ret t                             ! 21d2: 9e08
L_21d4:
	pushl @rr14,rr0                   ! 21d4: 91e0
	pushl @rr14,rr2                   ! 21d6: 91e2
	pushl @rr14,rr8                   ! 21d8: 91e8
	pushl @rr14,rr10                  ! 21da: 91ea
	pushl @rr14,rr12                  ! 21dc: 91ec
	.long_addr
	ldb rh2,0x1000302                 ! 21de: 600281000302
	.long_addr
	ldb rl3,0x1000303                 ! 21e4: 600b81000303
	calr L_22d2                       ! 21ea: df8d
	test r7                           ! 21ec: 8d74
	jr ne,L_2234                      ! 21ee: ee22
	ldar rr12,L_250a                  ! 21f0: 340c0316
	ldar rr8,L_2618                   ! 21f4: 34080420
	calr L_2266                       ! 21f8: dfca
	.long_addr
	ld r4,0x1000318                   ! 21fa: 610481000318
	.long_addr
	ld 0x100034c,r4                   ! 2200: 6f048100034c
	test r7                           ! 2206: 8d74
	jr ne,L_2234                      ! 2208: ee15
	ldar rr12,L_2514                  ! 220a: 340c0306
	ldar rr8,L_263c                   ! 220e: 3408042a
	calr L_2266                       ! 2212: dfd7
	test r7                           ! 2214: 8d74
	jr ne,L_2234                      ! 2216: ee0e
	.long_addr
	ldl rr2,0x1000318                 ! 2218: 540281000318
	cp r3,#0x2                        ! 221e: 0b030002
	ld r4,#0x26d                      ! 2222: 2104026d
	ld r6,#0x3a                       ! 2226: 2106003a
	jr eq,L_2234                      ! 222a: e604
	ld r4,#0x1a9                      ! 222c: 210401a9
	ld r6,#0x20                       ! 2230: 21060020
L_2234:
	ldb rl2,rl7                       ! 2234: a0fa
	cpb rl2,#0x0                      ! 2236: 0a0a0000
	clr r7                            ! 223a: 8d78
	resflg c                          ! 223c: 8d83
	jr eq,L_2254                      ! 223e: e60a
	cpb rl2,#0xff                     ! 2240: 0a0affff
	ldk r7,#0x1                       ! 2244: bd71
	jr eq,L_2252                      ! 2246: e605
	andb rl2,#0xf0                    ! 2248: 060af0f0
	ldk r7,#0x2                       ! 224c: bd72
	jr ne,L_2252                      ! 224e: ee01
	ldk r7,#0x4                       ! 2250: bd74
L_2252:
	setflg c                          ! 2252: 8d81
L_2254:
	.long_addr
	ld r5,0x100034c                   ! 2254: 61058100034c
	popl rr12,@rr14                   ! 225a: 95ec
	popl rr10,@rr14                   ! 225c: 95ea
	popl rr8,@rr14                    ! 225e: 95e8
	popl rr2,@rr14                    ! 2260: 95e2
	popl rr0,@rr14                    ! 2262: 95e0
	ret t                             ! 2264: 9e08
L_2266:
	pushl @rr14,rr0                   ! 2266: 91e0
	push @rr14,r2                     ! 2268: 93e2
	pushl @rr14,rr10                  ! 226a: 91ea
	.long_addr
	tsetb 0x1000316                   ! 226c: 4c0681000316
	ld r0,#0xa                        ! 2272: 2100000a
L_2276:
	.long_addr
	ldar rr10,L_2276                  ! 2276: 340afffc
	ld r11,#0xde4                     ! 227a: 210b0de4
	call @rr10                        ! 227e: 1fa0
	.long_addr
	ldb rh2,0x1000302                 ! 2280: 600281000302
	pushl @rr14,rr8                   ! 2286: 91e8
	call @rr12                        ! 2288: 1fc0
	popl rr8,@rr14                    ! 228a: 95e8
	test r7                           ! 228c: 8d74
	jr eq,L_2292                      ! 228e: e601
	jr t,L_22c0                       ! 2290: e817
L_2292:
	.long_addr
	testb 0x1000316                   ! 2292: 4c0481000316
	clr r7                            ! 2298: 8d78
	jr eq,L_22aa                      ! 229a: e607
	.long_addr
	testb 0x100030f                   ! 229c: 4c048100030f
	ld r7,#0xffff                     ! 22a2: 2107ffff
	jr eq,L_22c0                      ! 22a6: e60c
	jr t,L_2292                       ! 22a8: e8f4
L_22aa:
	.long_addr
	ldb rh2,0x1000302                 ! 22aa: 600281000302
	.long_addr
	lda rr4,0x1000318                 ! 22b0: 760481000318
	call @rr8                         ! 22b6: 1f80
	test r7                           ! 22b8: 8d74
	jr ne,L_22c0                      ! 22ba: ee02
	resflg z                          ! 22bc: 8d43
	jr t,L_22c2                       ! 22be: e801
L_22c0:
	setflg z                          ! 22c0: 8d41
L_22c2:
	popl rr10,@rr14                   ! 22c2: 95ea
	pop r2,@rr14                      ! 22c4: 97e2
	popl rr0,@rr14                    ! 22c6: 95e0
	ret t                             ! 22c8: 9e08
L_22ca:
	.long_addr
	clrb 0x1000316                    ! 22ca: 4c0881000316
	iret                              ! 22d0: 7b00
L_22d2:
	ldb rl2,#0xe0                     ! 22d2: cae0
	out @r2,r3                        ! 22d4: 3f23
	ld r9,#0xb10                      ! 22d6: 21090b10
	bit r3,#0x0                       ! 22da: a730
	jr eq,L_22e2                      ! 22dc: e602
	ld r9,#0x310                      ! 22de: 21090310
L_22e2:
	ldb rl2,#0xb0                     ! 22e2: cab0
	out @r2,r9                        ! 22e4: 3f29
	ld r9,#0x810                      ! 22e6: 21090810
	out @r2,r9                        ! 22ea: 3f29
	ldb rl2,#0x90                     ! 22ec: ca90
	ld r8,#0xa                        ! 22ee: 2108000a
L_22f2:
	in r6,@r2                         ! 22f2: 3d26
	dec r8,#0x1                       ! 22f4: ab80
	jr ne,L_22f2                      ! 22f6: eefd
	res r9,#0xb                       ! 22f8: a39b
	ldb rl2,#0xb0                     ! 22fa: cab0
	out @r2,r9                        ! 22fc: 3f29
	clr r9                            ! 22fe: 8d98
	out @r2,r9                        ! 2300: 3f29
	bit r6,#0x0                       ! 2302: a760
	ld r7,#0x14                       ! 2304: 21070014
	ret ne                            ! 2308: 9e0e
	calr L_230e                       ! 230a: dfff
	ret t                             ! 230c: 9e08
L_230e:
	ldb rl2,#0x90                     ! 230e: ca90
	in r8,@r2                         ! 2310: 3d28
	bit r8,#0x2                       ! 2312: a782
	ld r7,#0x10                       ! 2314: 21070010
	jr eq,L_2326                      ! 2318: e606
	bit r8,#0x3                       ! 231a: a783
	ld r7,#0x11                       ! 231c: 21070011
	jr ne,L_2326                      ! 2320: ee02
	clr r7                            ! 2322: 8d78
	ret t                             ! 2324: 9e08
L_2326:
	popl rr8,@rr14                    ! 2326: 95e8
	ret t                             ! 2328: 9e08
L_232a:
	ldb rl2,#0xb0                     ! 232a: cab0
	ld r8,#0x500                      ! 232c: 21080500
	out @r2,r8                        ! 2330: 3f28
	ldb rl2,#0x70                     ! 2332: ca70
	clr r8                            ! 2334: 8d88
	out @r2,r8                        ! 2336: 3f28
	cp r7,#0x0                        ! 2338: 0b070000
	jr eq,L_2342                      ! 233c: e602
	ldb rl2,#0xd0                     ! 233e: cad0
	out @r2,r7                        ! 2340: 3f27
L_2342:
	ret t                             ! 2342: 9e08
L_2344:
	calr L_230e                       ! 2344: d01c
	ld r5,r4                          ! 2346: a145
	or r5,r3                          ! 2348: 8535
	ldb rl2,#0xe0                     ! 234a: cae0
	out @r2,r5                        ! 234c: 3f25
	ldb rl2,#0xb0                     ! 234e: cab0
	ld r9,#0x910                      ! 2350: 21090910
	out @r2,r9                        ! 2354: 3f29
	ld r6,#0x5                        ! 2356: 21060005
L_235a:
	in r8,@r2                         ! 235a: 3d28
	djnz r6,L_235a                    ! 235c: f682
	res r9,#0xb                       ! 235e: a39b
	out @r2,r9                        ! 2360: 3f29
	in r8,@r2                         ! 2362: 3d28
	in r8,@r2                         ! 2364: 3d28
	res r9,#0x4                       ! 2366: a394
	out @r2,r9                        ! 2368: 3f29
	andb rl3,#0x30                    ! 236a: 060b3030
	jr eq,L_2378                      ! 236e: e604
	ld r6,#0x3e8                      ! 2370: 210603e8
L_2374:
	in r8,@r2                         ! 2374: 3d28
	djnz r6,L_2374                    ! 2376: f682
L_2378:
	ret t                             ! 2378: 9e08
L_237a:
	ldb rl2,#0x81                     ! 237a: ca81
	out @r2,r3                        ! 237c: 3f23
	clr r7                            ! 237e: 8d78
	ret t                             ! 2380: 9e08
L_2382:
	pushl @rr14,rr4                   ! 2382: 91e4
	pushl @rr14,rr6                   ! 2384: 91e6
	ldl rr0,#0xa7eb                   ! 2386: 14000000a7eb
	ldl rr6,rr0                       ! 238c: 9406
	subl rr4,rr4                      ! 238e: 9244
	ldb rl2,#0x20                     ! 2390: ca20
	in r3,@r2                         ! 2392: 3d23
	bit r3,#0xf                       ! 2394: a73f
	jr eq,L_239a                      ! 2396: e601
	inc r5,#0x1                       ! 2398: a950
L_239a:
	dec r1,#0x1                       ! 239a: ab10
	ldb rl2,#0x70                     ! 239c: ca70
	ld r3,#0x41                       ! 239e: 21030041
	out @r2,r3                        ! 23a2: 3f23
	ldb rl2,#0x10                     ! 23a4: ca10
L_23a6:
	in r3,@r2                         ! 23a6: 3d23
	bit r3,#0x5                       ! 23a8: a735
	jr ne,L_23c6                      ! 23aa: ee0d
	bit r3,#0x4                       ! 23ac: a734
	jr eq,L_23b2                      ! 23ae: e601
	inc r5,#0x1                       ! 23b0: a950
L_23b2:
	djnz r1,L_23a6                    ! 23b2: f187
L_23b4:
	popl rr6,@rr14                    ! 23b4: 95e6
	popl rr4,@rr14                    ! 23b6: 95e4
	ld @rr6,#0x1                      ! 23b8: 0d650001
	inc r7,#0x2                       ! 23bc: a971
	ld @rr6,#0xffff                   ! 23be: 0d65ffff
	clr r7                            ! 23c2: 8d78
	ret t                             ! 23c4: 9e08
L_23c6:
	subl rr6,rr0                      ! 23c6: 9206
	subl rr6,rr4                      ! 23c8: 9246
	slll rr6,#0x3                     ! 23ca: b3650003
	addl rr6,rr4                      ! 23ce: 9646
	ldl rr0,#0xa7eb                   ! 23d0: 14000000a7eb
	subl rr0,rr6                      ! 23d6: 9260
	jr pl,L_23e2                      ! 23d8: ed04
L_23da:
	addl rr0,#0xa7eb                  ! 23da: 16000000a7eb
	jr mi,L_23da                      ! 23e0: e5fc
L_23e2:
	ld r9,#0x7                        ! 23e2: 21090007
	and r9,r1                         ! 23e6: 8719
	ldl rr6,#0x20                     ! 23e8: 140600000020
	subl rr0,rr6                      ! 23ee: 9260
	jr mi,L_23f4                      ! 23f0: e501
	jr ne,L_2406                      ! 23f2: ee09
L_23f4:
	popl rr6,@rr14                    ! 23f4: 95e6
	popl rr4,@rr14                    ! 23f6: 95e4
	ld @rr6,#0x2                      ! 23f8: 0d650002
	inc r7,#0x2                       ! 23fc: a971
	ld @rr6,#0x0                      ! 23fe: 0d650000
	clr r7                            ! 2402: 8d78
	ret t                             ! 2404: 9e08
L_2406:
	subl rr6,rr0                      ! 2406: 9206
	jr mi,L_2414                      ! 2408: e505
	jr eq,L_2414                      ! 240a: e604
	ldl rr0,#0x4                      ! 240c: 140000000004
	jr t,L_243a                       ! 2412: e813
L_2414:
	srll rr0,#0x3                     ! 2414: b305fffd
	cp r1,#0x100                      ! 2418: 0b010100
	jr ule,L_2428                     ! 241c: e305
	jr t,L_23b4                       ! 241e: e8ca
	nop                               ! 2420: 8d07
	nop                               ! 2422: 8d07
	nop                               ! 2424: 8d07
	nop                               ! 2426: 8d07
L_2428:
	cp r9,#0x0                        ! 2428: 0b090000
	jr eq,L_243c                      ! 242c: e607
	addl rr0,#0x1                     ! 242e: 160000000001
	ld r7,#0x8                        ! 2434: 21070008
	sub r7,r9                         ! 2438: 8397
L_243a:
	ld r9,r7                          ! 243a: a179
L_243c:
	ldb rl2,#0x70                     ! 243c: ca70
	ld r8,#0x61                       ! 243e: 21080061
	out @r2,r8                        ! 2442: 3f28
	ldb rl2,#0x20                     ! 2444: ca20
	in r6,@r2                         ! 2446: 3d26
	clr r7                            ! 2448: 8d78
	ldb rl2,#0x70                     ! 244a: ca70
	out @r2,r7                        ! 244c: 3f27
	and r3,#0xf                       ! 244e: 0703000f
	sll r3,#0x4                       ! 2452: b3310004
	ldb rh6,rl3                       ! 2456: a0b6
	exb rh6,rl6                       ! 2458: ace6
	ld r3,r6                          ! 245a: a163
	srl r3,#0x4                       ! 245c: b331fffc
	ld r5,#0xc                        ! 2460: 2105000c
L_2464:
	srl r3,#0x1                       ! 2464: b331ffff
	jr c/ult,L_246e                   ! 2468: e702
	dec r5,#0x1                       ! 246a: ab50
	jr t,L_2464                       ! 246c: e8fb
L_246e:
	cp r9,#0x0                        ! 246e: 0b090000
	jr eq,L_247c                      ! 2472: e604
	srll rr6,#0x1                     ! 2474: b365ffff
	dec r9,#0x1                       ! 2478: ab90
	jr t,L_246e                       ! 247a: e8f9
L_247c:
	ldl rr8,#0x100                    ! 247c: 140800000100
	subl rr8,rr0                      ! 2482: 9208
	ldl rr0,rr6                       ! 2484: 9460
	popl rr6,@rr14                    ! 2486: 95e6
	ld rr6(#0x2),r5                   ! 2488: 33650002
	popl rr4,@rr14                    ! 248c: 95e4
	addl rr4,rr8                      ! 248e: 9684
	xorb rh0,@rr4                     ! 2490: 0840
	ldb @rr4,rh0                      ! 2492: 2e40
	inc r5,#0x1                       ! 2494: a950
	xorb rl0,@rr4                     ! 2496: 0848
	ldb @rr4,rl0                      ! 2498: 2e48
	inc r5,#0x1                       ! 249a: a950
	xorb rh1,@rr4                     ! 249c: 0841
	ldb @rr4,rh1                      ! 249e: 2e41
	inc r5,#0x1                       ! 24a0: a950
	xorb rl1,@rr4                     ! 24a2: 0849
	ldb @rr4,rl1                      ! 24a4: 2e49
	ld @rr6,#0x0                      ! 24a6: 0d650000
	clr r7                            ! 24aa: 8d78
	ret t                             ! 24ac: 9e08
L_24ae:
	ldb rl2,#0x80                     ! 24ae: ca80
	srll rr4,#0x1                     ! 24b0: b345ffff
	out @r2,r5                        ! 24b4: 3f25
	ldb rl2,#0x82                     ! 24b6: ca82
	out @r2,r4                        ! 24b8: 3f24
	clr r7                            ! 24ba: 8d78
	ret t                             ! 24bc: 9e08
L_24be:
	ld r5,#0x708                      ! 24be: 21050708
	ldb rl2,#0xb0                     ! 24c2: cab0
	out @r2,r5                        ! 24c4: 3f25
	set r5,#0x7                       ! 24c6: a557
	out @r2,r5                        ! 24c8: 3f25
	clr r7                            ! 24ca: 8d78
	ret t                             ! 24cc: 9e08
L_24ce:
	calr L_230e                       ! 24ce: d0e1
	calr L_24d4                       ! 24d0: dfff
	ret t                             ! 24d2: 9e08
L_24d4:
	ldb rl2,#0xe0                     ! 24d4: cae0
	exb rh3,rl3                       ! 24d6: acb3
	out @r2,r3                        ! 24d8: 3f23
	exb rh3,rl3                       ! 24da: acb3
	ldb rl2,#0xe1                     ! 24dc: cae1
	out @r2,r3                        ! 24de: 3f23
	ldb rl2,#0xb0                     ! 24e0: cab0
	ld r6,#0xa18                      ! 24e2: 21060a18
	out @r2,r6                        ! 24e6: 3f26
	ldb rl2,#0x83                     ! 24e8: ca83
	out @r2,r6                        ! 24ea: 3f26
	ret t                             ! 24ec: 9e08
L_24ee:
	calr L_230e                       ! 24ee: d0f1
	ld r3,#0x18                       ! 24f0: 21030018
	calr L_24f8                       ! 24f4: dfff
	ret t                             ! 24f6: 9e08
L_24f8:
	ldb rl2,#0xe0                     ! 24f8: cae0
	out @r2,r3                        ! 24fa: 3f23
	ldb rl2,#0xb0                     ! 24fc: cab0
	ld r3,#0x218                      ! 24fe: 21030218
	out @r2,r3                        ! 2502: 3f23
	ldb rl2,#0x83                     ! 2504: ca83
	out @r2,r3                        ! 2506: 3f23
	ret t                             ! 2508: 9e08
L_250a:
	calr L_230e                       ! 250a: d0ff
	ld r3,#0x68                       ! 250c: 21030068
	calr L_24f8                       ! 2510: d00d
	ret t                             ! 2512: 9e08
L_2514:
	calr L_230e                       ! 2514: d104
	ld r3,#0x88                       ! 2516: 21030088
	calr L_24f8                       ! 251a: d012
	ret t                             ! 251c: 9e08
L_251e:
	calr L_230e                       ! 251e: d109
	ldb rh3,#0x50                     ! 2520: c350
	calr L_24d4                       ! 2522: d028
	ret t                             ! 2524: 9e08
L_2526:
	ld r0,r7                          ! 2526: a170
	calr L_230e                       ! 2528: d10e
	ld r9,#0xd25                      ! 252a: 21090d25
	ld r7,#0x83                       ! 252e: 21070083
	calr L_2536                       ! 2532: dfff
	ret t                             ! 2534: 9e08
L_2536:
	bitb rl3,#0x4                     ! 2536: a6b4
	jr eq,L_253e                      ! 2538: e602
	xor r7,#0x1                       ! 253a: 09070001
L_253e:
	ldb rl2,#0x20                     ! 253e: ca20
	out @r2,r5                        ! 2540: 3f25
	ldb rl2,#0x21                     ! 2542: ca21
	out @r2,r3                        ! 2544: 3f23
	ldb rl2,#0x23                     ! 2546: ca23
	out @r2,r4                        ! 2548: 3f24
	ldb rl2,#0x22                     ! 254a: ca22
	exb rh4,rl4                       ! 254c: acc4
	out @r2,r4                        ! 254e: 3f24
	ldb rl2,#0x10                     ! 2550: ca10
	out @r2,r6                        ! 2552: 3f26
	ldb rl2,#0xc3                     ! 2554: cac3
	ld r8,#0x30                       ! 2556: 21080030
	out @r2,r8                        ! 255a: 3f28
	ldb rl2,#0xc0                     ! 255c: cac0
	ld r8,#0x1                        ! 255e: 21080001
	out @r2,r8                        ! 2562: 3f28
	clr r8                            ! 2564: 8d88
	out @r2,r8                        ! 2566: 3f28
	ldb rl2,#0xc3                     ! 2568: cac3
	ld r8,#0x70                       ! 256a: 21080070
	out @r2,r8                        ! 256e: 3f28
	ldb rl2,#0xc1                     ! 2570: cac1
	exb rh0,rl0                       ! 2572: ac80
	dec r0,#0x1                       ! 2574: ab00
	out @r2,r0                        ! 2576: 3f20
	exb rh0,rl0                       ! 2578: ac80
	out @r2,r0                        ! 257a: 3f20
	ldb rl2,#0xc3                     ! 257c: cac3
	ld r8,#0xb0                       ! 257e: 210800b0
	out @r2,r8                        ! 2582: 3f28
	ldb rl2,#0xc2                     ! 2584: cac2
	exb rh0,rl0                       ! 2586: ac80
	srl r0,#0x1                       ! 2588: b301ffff
	out @r2,r0                        ! 258c: 3f20
	exb rh0,rl0                       ! 258e: ac80
	out @r2,r0                        ! 2590: 3f20
	ldb rl2,#0xb0                     ! 2592: cab0
	out @r2,r9                        ! 2594: 3f29
	set r9,#0x3                       ! 2596: a593
	out @r2,r9                        ! 2598: 3f29
	ldb rl2,#0x70                     ! 259a: ca70
	out @r2,r7                        ! 259c: 3f27
	clr r7                            ! 259e: 8d78
	ret t                             ! 25a0: 9e08
L_25a2:
	ld r0,r7                          ! 25a2: a170
	calr L_230e                       ! 25a4: d14c
	ld r9,#0xd22                      ! 25a6: 21090d22
	ld r7,#0x81                       ! 25aa: 21070081
	calr L_2536                       ! 25ae: d03d
	ret t                             ! 25b0: 9e08
L_25b2:
	ld r0,r7                          ! 25b2: a170
	calr L_230e                       ! 25b4: d154
	ld r9,#0xd22                      ! 25b6: 21090d22
	ld r7,#0x87                       ! 25ba: 21070087
	calr L_2536                       ! 25be: d045
	ret t                             ! 25c0: 9e08
L_25c2:
	clr r7                            ! 25c2: 8d78
	calr L_232a                       ! 25c4: d14e
	ret t                             ! 25c6: 9e08
L_25c8:
	calr L_25d0                       ! 25c8: dffd
	ret t                             ! 25ca: 9e08
L_25cc:
	calr L_25d0                       ! 25cc: dfff
	ret t                             ! 25ce: 9e08
L_25d0:
	calr L_25e6                       ! 25d0: dff6
	clr r7                            ! 25d2: 8d78
	andb rl3,#0xd                     ! 25d4: 060b0d0d
	jr eq,L_25e2                      ! 25d8: e604
	ldb rl7,#0x12                     ! 25da: cf12
	bitb rl3,#0x2                     ! 25dc: a6b2
	jr ne,L_25e2                      ! 25de: ee01
	incb rl7,#0x1                     ! 25e0: a8f0
L_25e2:
	calr L_232a                       ! 25e2: d15d
	ret t                             ! 25e4: 9e08
L_25e6:
	ldb rl2,#0x90                     ! 25e6: ca90
	in r7,@r2                         ! 25e8: 3d27
	bit r7,#0xb                       ! 25ea: a77b
	jr ne,L_2604                      ! 25ec: ee0b
	ldb rl2,#0xb0                     ! 25ee: cab0
	ld r3,#0x208                      ! 25f0: 21030208
	out @r2,r3                        ! 25f4: 3f23
	ldb rl2,#0x83                     ! 25f6: ca83
	out @r2,r3                        ! 25f8: 3f23
	ldb rl2,#0x90                     ! 25fa: ca90
L_25fc:
	in r7,@r2                         ! 25fc: 3d27
	bit r7,#0x1                       ! 25fe: a771
	jr ne,L_260e                      ! 2600: ee06
	djnz r3,L_25fc                    ! 2602: f384
L_2604:
	ld r7,#0xffff                     ! 2604: 2107ffff
	calr L_232a                       ! 2608: d170
	popl rr8,@rr14                    ! 260a: 95e8
	ret t                             ! 260c: 9e08
L_260e:
	ldb rl2,#0x80                     ! 260e: ca80
	in r3,@r2                         ! 2610: 3d23
	and r3,#0xff                      ! 2612: 070300ff
	ret t                             ! 2616: 9e08
L_2618:
	calr L_261c                       ! 2618: dfff
	ret t                             ! 261a: 9e08
L_261c:
	calr L_25e6                       ! 261c: d01c
	xorb rl3,#0xff                    ! 261e: 080bffff
	ldb rl7,rl3                       ! 2622: a0bf
	and r3,#0xf                       ! 2624: 0703000f
	ld rr4(#0x2),r3                   ! 2628: 33430002
	and r7,#0xf0                      ! 262c: 070700f0
	.word	0xb2f1		! 2630: srlb rl7,#0x4
	.word	0xfffc		! 2632: srlb rl7,#0x4
	ld @rr4,r7                        ! 2634: 2f47
	clr r7                            ! 2636: 8d78
	calr L_232a                       ! 2638: d188
	ret t                             ! 263a: 9e08
L_263c:
	calr L_261c                       ! 263c: d011
	ret t                             ! 263e: 9e08
L_2640:
	calr L_25e6                       ! 2640: d02e
	xorb rl3,#0xff                    ! 2642: 080bffff
	ld @rr4,r3                        ! 2646: 2f43
	clr r7                            ! 2648: 8d78
	calr L_232a                       ! 264a: d191
	ret t                             ! 264c: 9e08
L_264e:
	ld r6,#0x1d00                     ! 264e: 21061d00
	calr L_2656                       ! 2652: dfff
	ret t                             ! 2654: 9e08
L_2656:
	ldb rl2,#0x90                     ! 2656: ca90
	in r1,@r2                         ! 2658: 3d21
	calr L_26f4                       ! 265a: dfb4
	ld r7,#0x20                       ! 265c: 21070020
	bit r1,#0xe                       ! 2660: a71e
	jr ne,L_26a4                      ! 2662: ee20
	inc r7,#0x1                       ! 2664: a970
	bit r1,#0xd                       ! 2666: a71d
	jr ne,L_26a4                      ! 2668: ee1d
	clr r7                            ! 266a: 8d78
	and r3,r6                         ! 266c: 8763
	jr eq,L_2690                      ! 266e: e610
	ldb rl7,#0x1                      ! 2670: cf01
	bit r3,#0x8                       ! 2672: a738
	jr ne,L_2690                      ! 2674: ee0d
	ldb rl7,#0x3                      ! 2676: cf03
	bit r3,#0xb                       ! 2678: a73b
	jr ne,L_2690                      ! 267a: ee0a
	ldb rl7,#0x2                      ! 267c: cf02
	bit r3,#0xa                       ! 267e: a73a
	jr ne,L_2690                      ! 2680: ee07
	ldb rl7,#0x15                     ! 2682: cf15
	bit r3,#0xe                       ! 2684: a73e
	jr ne,L_2690                      ! 2686: ee04
	ldb rl7,#0x5                      ! 2688: cf05
	bit r3,#0x9                       ! 268a: a739
	jr ne,L_2690                      ! 268c: ee01
	ldb rl7,#0x4                      ! 268e: cf04
L_2690:
	cp r7,#0x0                        ! 2690: 0b070000
	jr ne,L_26a4                      ! 2694: ee07
	and r1,#0x300                     ! 2696: 07010300
	cp r1,#0x300                      ! 269a: 0b010300
	jr eq,L_26a4                      ! 269e: e602
	ld r7,#0xffff                     ! 26a0: 2107ffff
L_26a4:
	calr L_232a                       ! 26a4: d1be
	clrb rl2                          ! 26a6: 8ca8
	in r3,@r2                         ! 26a8: 3d23
	clrb rh3                          ! 26aa: 8c38
	ld rr4(#0x4),r3                   ! 26ac: 33430004
	ldb rl2,#0x2                      ! 26b0: ca02
	in r0,@r2                         ! 26b2: 3d20
	clrb rh0                          ! 26b4: 8c08
	exb rh0,rl0                       ! 26b6: ac80
	incb rl2,#0x1                     ! 26b8: a8a0
	in r3,@r2                         ! 26ba: 3d23
	clrb rh3                          ! 26bc: 8c38
	or r3,r0                          ! 26be: 8503
	ld rr4(#0x2),r3                   ! 26c0: 33430002
	ldb rl2,#0x1                      ! 26c4: ca01
	in r3,@r2                         ! 26c6: 3d23
	clrb rh3                          ! 26c8: 8c38
	ld @rr4,r3                        ! 26ca: 2f43
	ldb rl2,#0x70                     ! 26cc: ca70
	ld r8,#0x1f                       ! 26ce: 2108001f
	out @r2,r8                        ! 26d2: 3f28
	ldb rl2,#0x20                     ! 26d4: ca20
	in r3,@r2                         ! 26d6: 3d23
	clrb rh3                          ! 26d8: 8c38
	ldb rl2,#0x70                     ! 26da: ca70
	clr r8                            ! 26dc: 8d88
	out @r2,r8                        ! 26de: 3f28
	cp r7,#0x4                        ! 26e0: 0b070004
	jr eq,L_26ee                      ! 26e4: e604
	cp r7,#0x1                        ! 26e6: 0b070001
	jr eq,L_26ee                      ! 26ea: e601
	decb rl3,#0x1                     ! 26ec: aab0
L_26ee:
	ld rr4(#0x6),r3                   ! 26ee: 33430006
	ret t                             ! 26f2: 9e08
L_26f4:
	ld r8,#0x8000                     ! 26f4: 21088000
	ldb rl2,#0x20                     ! 26f8: ca20
L_26fa:
	in r3,@r2                         ! 26fa: 3d23
	bit r3,#0xd                       ! 26fc: a73d
	jr eq,L_270c                      ! 26fe: e606
	djnz r8,L_26fa                    ! 2700: f884
L_2702:
	ld r7,#0xffff                     ! 2702: 2107ffff
	calr L_232a                       ! 2706: d1ef
	popl rr8,@rr14                    ! 2708: 95e8
	ret t                             ! 270a: 9e08
L_270c:
	bit r1,#0xb                       ! 270c: a71b
	jr ne,L_2702                      ! 270e: eef9
	ret t                             ! 2710: 9e08
L_2712:
	ld r6,#0x5100                     ! 2712: 21065100
	calr L_2656                       ! 2716: d061
	ret t                             ! 2718: 9e08
L_271a:
	ld r6,#0x1f00                     ! 271a: 21061f00
	calr L_2656                       ! 271e: d065
	ret t                             ! 2720: 9e08
	pushl @rr14,rr0                   ! 2722: 91e0
	pushl @rr14,rr2                   ! 2724: 91e2
	pushl @rr14,rr4                   ! 2726: 91e4
	push @rr14,r6                     ! 2728: 93e6
	pushl @rr14,rr8                   ! 272a: 91e8
	pushl @rr14,rr10                  ! 272c: 91ea
	pushl @rr14,rr12                  ! 272e: 91ec
	ldb rl5,rl7                       ! 2730: a0fd
	.long_addr
	ldb rh2,0x1000304                 ! 2732: 600281000304
	in r7,@r2                         ! 2738: 3d27
	cpb rh7,#0x2                      ! 273a: 0a070202
	jr eq,L_2768                      ! 273e: e614
	cpb rh7,#0x4                      ! 2740: 0a070404
	jr eq,L_2786                      ! 2744: e620
L_2746:
	ldb rl1,#0xc                      ! 2746: c90c
	calr L_290a                       ! 2748: df20
	ldk r0,#0x1                       ! 274a: bd01
	.long_addr
	call 0xde4                        ! 274c: 5f0080000de4
L_2752:
	.long_addr
	testb 0x100030f                   ! 2752: 4c048100030f
	jr ne,L_2752                      ! 2758: eefc
	in r7,@r2                         ! 275a: 3d27
	cpb rh7,#0xe                      ! 275c: 0a070e0e
	jr eq,L_2746                      ! 2760: e6f2
	cpb rh7,#0x2                      ! 2762: 0a070202
	jr ne,L_2802                      ! 2766: ee4d
L_2768:
	ldb rl1,#0x55                     ! 2768: c955
	calr L_290a                       ! 276a: df31
	cpb rh7,#0x2                      ! 276c: 0a070202
	jr ne,L_2802                      ! 2770: ee48
	ldb rl1,rl5                       ! 2772: a0d9
	calr L_290a                       ! 2774: df36
	cpb rh7,#0x2                      ! 2776: 0a070202
	jr ne,L_2802                      ! 277a: ee43
	ldb rl1,#0xaa                     ! 277c: c9aa
	calr L_290a                       ! 277e: df3b
	cpb rh7,#0x6                      ! 2780: 0a070606
	jr ne,L_2802                      ! 2784: ee3e
L_2786:
	.long_addr
	lda rr2,0x10001c0                 ! 2786: 7602810001c0
	clrb rh1                          ! 278c: 8c18
	ldb rl1,rl5                       ! 278e: a0d9
	sllb rl1,#0x1                     ! 2790: b2910001
	add r3,r1                         ! 2794: 8113
	.long_addr
	lda rr6,0x298e                    ! 2796: 76068000298e
	ldl @rr2,rr6                      ! 279c: 1d26
	ldb rl1,#0x8                      ! 279e: c908
	calr L_293e                       ! 27a0: df32
	jr eq,L_2802                      ! 27a2: e62f
	.long_addr
	lda rr2,0x1000338                 ! 27a4: 760281000338
	.long_addr
	call 0xa70                        ! 27aa: 5f0080000a70
	ldb rl1,#0xa                      ! 27b0: c90a
	calr L_290a                       ! 27b2: df55
	cpb rh7,#0x6                      ! 27b4: 0a070606
	jr ne,L_2802                      ! 27b8: ee24
	ldb rl1,rl2                       ! 27ba: a0a9
	calr L_290a                       ! 27bc: df5a
	cpb rh7,#0x6                      ! 27be: 0a070606
	jr ne,L_2802                      ! 27c2: ee1f
	ldb rl1,rh3                       ! 27c4: a039
	calr L_290a                       ! 27c6: df5f
	cpb rh7,#0x6                      ! 27c8: 0a070606
	jr ne,L_2802                      ! 27cc: ee1a
	ldb rl1,rl3                       ! 27ce: a0b9
	calr L_290a                       ! 27d0: df64
	cpb rh7,#0xf8                     ! 27d2: 0a07f8f8
	jr ne,L_2802                      ! 27d6: ee15
L_27d8:
	ldb rl1,#0x6                      ! 27d8: c906
	calr L_293e                       ! 27da: df4f
	jr eq,L_2802                      ! 27dc: e612
	ldb rl0,#0x32                     ! 27de: c832
	.long_addr
	call 0xe96                        ! 27e0: 5f0080000e96
	cpb rh7,#0xe                      ! 27e6: 0a070e0e
	.long_addr
	lda rr2,0x1000338                 ! 27ea: 760281000338
	ld r4,rr2(#0xa)                   ! 27f0: 3124000a
	bit r4,#0x7                       ! 27f4: a747
	jr ne,L_27d8                      ! 27f6: eef0
	bit r4,#0x9                       ! 27f8: a749
	ldk r7,#0x8                       ! 27fa: bd78
	jr eq,L_2804                      ! 27fc: e603
	ldk r7,#0x0                       ! 27fe: bd70
	jr t,L_2804                       ! 2800: e801
L_2802:
	ldk r7,#0x1                       ! 2802: bd71
L_2804:
	popl rr12,@rr14                   ! 2804: 95ec
	popl rr10,@rr14                   ! 2806: 95ea
	popl rr8,@rr14                    ! 2808: 95e8
	pop r6,@rr14                      ! 280a: 97e6
	popl rr4,@rr14                    ! 280c: 95e4
	popl rr2,@rr14                    ! 280e: 95e2
	popl rr0,@rr14                    ! 2810: 95e0
	ret t                             ! 2812: 9e08
	pushl @rr14,rr0                   ! 2814: 91e0
	pushl @rr14,rr2                   ! 2816: 91e2
	push @rr14,r4                     ! 2818: 93e4
	pushl @rr14,rr8                   ! 281a: 91e8
	pushl @rr14,rr10                  ! 281c: 91ea
	pushl @rr14,rr12                  ! 281e: 91ec
	ldl rr4,#0x81000338               ! 2820: 140481000338
	ldl rr6,rr2                       ! 2826: 9426
	ldl rr2,@rr6                      ! 2828: 1462
L_282a:
	.long_addr
	ldar rr10,L_282a                  ! 282a: 340afffc
	ld r11,#0xa70                     ! 282e: 210b0a70
	call @rr10                        ! 2832: 1fa0
	ldl rr4(#0x4),rr2                 ! 2834: 37420004
	ld r1,rr6(#0x4)                   ! 2838: 31610004
	ldb rl0,rh1                       ! 283c: a018
	.word	0xb281		! 283e: srlb rl0,#0x1
	.word	0xffff		! 2840: srlb rl0,#0x1
	testb rl1                         ! 2842: 8c94
	jr eq,L_2848                      ! 2844: e601
	incb rl0,#0x1                     ! 2846: a880
L_2848:
	clrb rh0                          ! 2848: 8c08
	ld rr4(#0x8),r0                   ! 284a: 33400008
	ldb rl2,rr6(#0x7)                 ! 284e: 306a0007
	ldb rh2,rr6(#0xa)                 ! 2852: 3062000a
	ld @rr4,r2                        ! 2856: 2f42
	ld r2,rr6(#0x8)                   ! 2858: 31620008
	ld rr4(#0x2),r2                   ! 285c: 33420002
	ldb rl1,rr6(#0xb)                 ! 2860: 3069000b
L_2864:
	calr L_293e                       ! 2864: df94
	jr eq,L_28f8                      ! 2866: e648
	ld r5,r7                          ! 2868: a175
	cpb rh5,#0xe                      ! 286a: 0a050e0e
	jr ne,L_2884                      ! 286e: ee0a
	.long_addr
	lda rr2,0x1000338                 ! 2870: 760281000338
	ld r4,rr2(#0xa)                   ! 2876: 3124000a
	bit r4,#0x7                       ! 287a: a747
	jr ne,L_2864                      ! 287c: eef3
	bit r4,#0x9                       ! 287e: a749
	ldk r7,#0x8                       ! 2880: bd78
	jr eq,L_28f8                      ! 2882: e63a
L_2884:
	bitb rl1,#0x4                     ! 2884: a694
	jr eq,L_28aa                      ! 2886: e611
	ldb rl1,#0x2                      ! 2888: c902
L_288a:
	calr L_293e                       ! 288a: dfa7
	jr eq,L_28f8                      ! 288c: e635
	ld r5,r7                          ! 288e: a175
	cpb rh5,#0xe                      ! 2890: 0a050e0e
	jr ne,L_28aa                      ! 2894: ee0a
	.long_addr
	lda rr2,0x1000338                 ! 2896: 760281000338
	ld r4,rr2(#0xa)                   ! 289c: 3124000a
	bit r4,#0x7                       ! 28a0: a747
	jr ne,L_288a                      ! 28a2: eef3
	bit r4,#0x9                       ! 28a4: a749
	ldk r7,#0x8                       ! 28a6: bd78
	jr eq,L_28f8                      ! 28a8: e627
L_28aa:
	andb rh5,#0xf0                    ! 28aa: 0605f0f0
	cpb rh5,#0x80                     ! 28ae: 0a058080
	jr ne,L_28f2                      ! 28b2: ee1f
	.long_addr
	lda rr4,0x1000338                 ! 28b4: 760481000338
	ld r3,rr4(#0xc)                   ! 28ba: 3143000c
	and r3,#0xc                       ! 28be: 0703000c
	ld r6,rr4(#0xe)                   ! 28c2: 3146000e
	ldk r7,#0x4                       ! 28c6: bd74
	jr ne,L_28f8                      ! 28c8: ee17
	ld r3,rr4(#0xc)                   ! 28ca: 3143000c
	bit r3,#0x0                       ! 28ce: a730
	ld r7,#0x40                       ! 28d0: 21070040
	jr ne,L_28f8                      ! 28d4: ee11
	bit r3,#0x1                       ! 28d6: a731
	ld r7,#0x10                       ! 28d8: 21070010
	jr ne,L_28f8                      ! 28dc: ee0d
	bit r3,#0x4                       ! 28de: a734
	ld r7,#0x10                       ! 28e0: 21070010
	jr ne,L_28f8                      ! 28e4: ee09
	ld r3,rr4(#0xa)                   ! 28e6: 3143000a
	bit r3,#0x8                       ! 28ea: a738
	ld r7,#0x20                       ! 28ec: 21070020
	jr eq,L_28f8                      ! 28f0: e603
L_28f2:
	ld r6,#0xffff                     ! 28f2: 2106ffff
	clr r7                            ! 28f6: 8d78
L_28f8:
	ld r5,rr4(#0xe)                   ! 28f8: 3145000e
	popl rr12,@rr14                   ! 28fc: 95ec
	popl rr10,@rr14                   ! 28fe: 95ea
	popl rr8,@rr14                    ! 2900: 95e8
	pop r4,@rr14                      ! 2902: 97e4
	popl rr2,@rr14                    ! 2904: 95e2
	popl rr0,@rr14                    ! 2906: 95e0
	ret t                             ! 2908: 9e08
L_290a:
	push @rr14,r12                    ! 290a: 93ec
	push @rr14,r5                     ! 290c: 93e5
	push @rr14,r2                     ! 290e: 93e2
	ld r12,#0x2800                    ! 2910: 210c2800
	.long_addr
	ldb rh2,0x1000304                 ! 2914: 600281000304
L_291a:
	in r7,@r2                         ! 291a: 3d27
	bitb rh7,#0x0                     ! 291c: a670
	jr eq,L_292a                      ! 291e: e605
	djnz r12,L_291a                   ! 2920: fc84
	setflg z                          ! 2922: 8d41
	ld r7,#0x1                        ! 2924: 21070001
	jr t,L_2936                       ! 2928: e806
L_292a:
	outb @r2,rl1                      ! 292a: 3e29
	ld r12,#0x100                     ! 292c: 210c0100
L_2930:
	djnz r12,L_2930                   ! 2930: fc81
	in r7,@r2                         ! 2932: 3d27
	resflg z                          ! 2934: 8d43
L_2936:
	pop r2,@rr14                      ! 2936: 97e2
	pop r5,@rr14                      ! 2938: 97e5
	pop r12,@rr14                     ! 293a: 97ec
	ret t                             ! 293c: 9e08
L_293e:
	pushl @rr14,rr0                   ! 293e: 91e0
	pushl @rr14,rr2                   ! 2940: 91e2
	pushl @rr14,rr4                   ! 2942: 91e4
	push @rr14,r6                     ! 2944: 93e6
	pushl @rr14,rr8                   ! 2946: 91e8
	.long_addr
	tsetb 0x1000314                   ! 2948: 4c0681000314
	ldb rl0,#0xf0                     ! 294e: c8f0
L_2950:
	.long_addr
	ldar rr10,L_2950                  ! 2950: 340afffc
	ld r11,#0xde4                     ! 2954: 210b0de4
	call @rr10                        ! 2958: 1fa0
	calr L_290a                       ! 295a: d029
	ld r7,#0x1                        ! 295c: 21070001
	jr eq,L_2982                      ! 2960: e610
L_2962:
	.long_addr
	testb 0x1000314                   ! 2962: 4c0481000314
	jr eq,L_2978                      ! 2968: e607
	.long_addr
	testb 0x100030f                   ! 296a: 4c048100030f
	ld r7,#0x1                        ! 2970: 21070001
	jr eq,L_2982                      ! 2974: e606
	jr t,L_2962                       ! 2976: e8f5
L_2978:
	.long_addr
	ldb rh2,0x1000304                 ! 2978: 600281000304
	in r7,@r2                         ! 297e: 3d27
	resflg z                          ! 2980: 8d43
L_2982:
	popl rr8,@rr14                    ! 2982: 95e8
	pop r6,@rr14                      ! 2984: 97e6
	popl rr4,@rr14                    ! 2986: 95e4
	popl rr2,@rr14                    ! 2988: 95e2
	popl rr0,@rr14                    ! 298a: 95e0
	ret t                             ! 298c: 9e08
	.long_addr
	clrb 0x1000314                    ! 298e: 4c0881000314
	iret                              ! 2994: 7b00

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
	.org	0x3ffc,0xff
	.word	0x0000		! checksum, patched after linking
	.word	0x0000
