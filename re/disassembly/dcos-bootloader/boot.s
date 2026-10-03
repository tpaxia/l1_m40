	.z8001
	.text
	.org	0

! =============================================================================
! SYS0 FIRST-STAGE BOOTLOADER  --  L1 DCOS 8.4 diagnostic disk, track 0
! -----------------------------------------------------------------------------
! Loaded by the ROM IPL: track 0 (26 x 128B) is read into the <<60>> buffer,
! the "SYS0" magic is checked, MMU descriptor 25 is aliased onto that buffer,
! and control jumps to the header entry point <<25>>0x000c (this file).
! The code + tables below (first 512 bytes) are identical on all 9 disks; the
! rest of track 0 is disk volume data and is not part of the loader.
!
! What it does: issue ONE load command (9-byte descriptor @0x0114) to read the
! Diagnostic Monitor to <<25>>0x0200 -- retrying on error -- then jp to the
! Monitor entry <<25>>0x0234.  The sector read itself is done by a ROM driver
! routine (segment 0), reached by a type -> table -> ROM-vector indirection.
! =============================================================================

! ---- 0x0000 .. 0x0004  (ascii) ----   ;; "SYS0" magic (0x53595330)
	! "SYS0"
	.byte	0x53,0x59,0x53,0x30

! ---- 0x0004 .. 0x000c  (word) ----   ;; block header: entry <<25>>0x000c (0x9900000c) + flags longword 0x00000001
	.word	0x9900
	.word	0x000c
	.word	0x0000
	.word	0x0001

! ---- 0x000c .. 0x00dc  (code) ----
	.long_addr

! ---- entry: save the boot marker, load the Monitor, jump to it ----------------
	ld r2,0x1000308                   ! 000c: 610281000308   ;; r2 = boot-success marker (<<1>>0x0308 = 0x5555, set by the ROM IPL)
	.word	0x3302		! 0012: ldr 0xfa,r2   ;; save the marker to scratch <<25>>0x00fa  (ldr, kept as .word)
	.word	0x00e4		! 0014: ldr 0xfa,r2
	ldar rr2,L_0114                   ! 0016: 340200fa   ;; rr2 = &load-descriptor  (<<25>>0x0114)
	calr L_0022                       ! 001a: dffd   ;; call the loader (retries until the FDC status is clean)
	.word	0x3502		! 001c: ldrl rr2,0x110   ;; rr2 = Monitor entry <<25>>0x0234  (longword @0x0110; ldrl kept as .word)
	.word	0x00f0		! 001e: ldrl rr2,0x110
	jp t,@rr2                         ! 0020: 1e28   ;; jump into the loaded Diagnostic Monitor
L_0022:
	.long_addr

! ---- loader dispatch (called with rr2 = &descriptor) --------------------------
! Read the config-table TYPE for the booted slot (the ROM's own enumeration, not
! a re-scan), pick the ROM device-load routine for that type, and call it.  Loop
! = retry-on-error: on a bad FDC status, run the recovery routine and try again;
! rr2 (the descriptor) never advances, so this is one load command, not a list.
	ldb rh4,0x1000302                 ! 0022: 600481000302   ;; rh4 = IPL slot  (<<1>>0x0302, from the ROM) -- no bus re-scan
	srl r4,#0xa                       ! 0028: b341fff6   ;; r4 = slot * 4  (config-table stride)
	and r4,#0x3c                      ! 002c: 0704003c
	.long_addr
	ldb rl7,0x1000230(r4)             ! 0030: 604f81000230   ;; rl7 = config-table[slot].TYPE  (<<1>>0x0230) -- the ROM's SYSTEM ENVIRONMENT table
	cpb rl7,#0x60                     ! 0036: 0a0f6060   ;; removable types 60/61/65/66 -> pre-translate LBA at 0x0078 first
	jr eq,L_0078                      ! 003a: e61e
	cpb rl7,#0x61                     ! 003c: 0a0f6161
	jr eq,L_0078                      ! 0040: e61b
	cpb rl7,#0x65                     ! 0042: 0a0f6565
	jr eq,L_0078                      ! 0046: e618
	cpb rl7,#0x66                     ! 0048: 0a0f6666
	jr eq,L_0078                      ! 004c: e615
L_004e:
! Find the type in the device-type table, then fetch its loader from the pointer
! table.  cpirb counts the counter DOWN, so a hit at device index i leaves
! r6 = 9-i: the pointer table is therefore indexed in REVERSE (offset 2*(9-i)).
! The pointer word is a segment-0 (ROM) address whose contents is the routine
! entry -- i.e. the loader lives in the boot ROM (FDU/MFDU E0/E1 -> <<0>>0x1642).
	ldar rr4,L_00dc                   ! 004e: 3404008a   ;; rr4 = device-type table (0x00dc)
	ldk r6,#0xa                       ! 0052: bd6a   ;; 10 entries
	cpirb rl7,@rr4,r6,eq              ! 0054: ba4406f6   ;; scan for the booted TYPE; counter counts down (see header)
L_0058:
	jr ne,L_0058                      ! 0058: eeff   ;; TYPE not in table -> hang (unsupported boot device)
	add r6,r6                         ! 005a: 8166   ;; r6 = 2*(9-index): reversed word index into the pointer table
	ldar rr4,L_00e6                   ! 005c: 34040086   ;; rr4 = loader-pointer table (0x00e6)
	ld r5,rr4(r6)                     ! 0060: 71450600   ;; r5 = pointer word = a segment-0 (ROM) vector offset
	ld r4,#0x0                        ! 0064: 21040000   ;; segment 0 = the boot ROM
	ld r5,@rr4                        ! 0068: 2145   ;; r5 = ROM[ptr] = device-load routine entry (FDU/MFDU E0/E1 = 0x1642)
	call @rr4                         ! 006a: 1f40   ;; call the ROM loader (rr2 = descriptor); status returned in r7
	or r7,r7                          ! 006c: 8577   ;; r7 = FDC result status (<<1>>0x034a)
	ret eq                            ! 006e: 9e06   ;; clean -> return, then jp Monitor
	ld r5,0x72                        ! 0070: 61050072   ;; else r5 = ROM[0x0072] = recovery routine (0x0d10)
	call @rr4                         ! 0074: 1f40   ;; reset/recalibrate the governo
	jr t,L_0022                       ! 0076: e8d5   ;; retry the whole load
L_0078:

! ---- removable devices (types 60/61/65/66): pre-translate the start LBA -------
! Before the common dispatch, convert the descriptor's logical start block to a
! cylinder/head/sector using the drive geometry passed by the ROM, then rejoin
! the dispatch at 0x004e.
	push @rr14,r7                     ! 0078: 93e7   ;; save the type
	.long_addr
	ld r6,0x100030c                   ! 007a: 61068100030c   ;; r6 = geometry: sectors/track (<<1>>0x030c)
	.long_addr
	ldb rh7,0x100030e                 ! 0080: 60078100030e   ;; rh7 = heads (<<1>>0x030e)
	.long_addr
	ldb rl7,0x1000306                 ! 0086: 600f81000306   ;; rl7 = ? (<<1>>0x0306)
	ldb rl0,rr2(#0xa)                 ! 008c: 3028000a   ;; descriptor[10] (start-block hi)
	cpb rl0,#0xa8                     ! 0090: 0a08a8a8   ;; marker 0xa8 -> already translated?
	jr ne,L_00a6                      ! 0094: ee08
	ldb rl0,#0x88                     ! 0096: c888
	ldb rr2(#0xa),rl0                 ! 0098: 3228000a
	ldl rr4,rr2(#0x6)                 ! 009c: 35240006   ;; rr4 = descriptor start-block longword
	calr L_00aa                       ! 00a0: dffc   ;; translate LBA -> CHS
	ldl rr2(#0x6),rr4                 ! 00a2: 37240006   ;; write the CHS back into the descriptor
L_00a6:
	pop r7,@rr14                      ! 00a6: 97e7
	jr t,L_004e                       ! 00a8: e8d2   ;; rejoin the common dispatch
L_00aa:

! ---- LBA -> CHS ---------------------------------------------------------------
! rr4 = logical block; divide by sectors-per-track (rl7 hi) for the track, then
! by heads (rl7 lo) for cylinder/head; leaves sector in rl5, cyl/head packed.
	pushl @rr14,rr0                   ! 00aa: 91e0
	pushl @rr14,rr2                   ! 00ac: 91e2
	subl rr0,rr0                      ! 00ae: 9200
	subl rr2,rr2                      ! 00b0: 9222
	ldb rl1,rh7                       ! 00b2: a079
	ldb rl3,rl7                       ! 00b4: a0fb
	mult rr0,r3                       ! 00b6: 9930
L_00b8:
	inc r2,#0x1                       ! 00b8: a920
	subl rr4,rr0                      ! 00ba: 9204
	jr nc/uge,L_00b8                  ! 00bc: effd
	dec r2,#0x1                       ! 00be: ab20
	addl rr4,rr0                      ! 00c0: 9604
	clr r1                            ! 00c2: 8d18
	ldb rl1,rl7                       ! 00c4: a0f9
	clr r4                            ! 00c6: 8d48
L_00c8:
	inc r4,#0x1                       ! 00c8: a940
	sub r5,r1                         ! 00ca: 8315
	jr nc/uge,L_00c8                  ! 00cc: effd
	dec r4,#0x1                       ! 00ce: ab40
	add r5,r1                         ! 00d0: 8115
	ldb rh5,rl4                       ! 00d2: a0c5
	ld r4,r2                          ! 00d4: a124
	popl rr2,@rr14                    ! 00d6: 95e2
	popl rr0,@rr14                    ! 00d8: 95e0
	ret t                             ! 00da: 9e08

! ---- 0x00dc .. 0x00e6  (word) ----   ;; DEVICE-TYPE TABLE (10 bytes) -- E4 E0 66 E6 E7 E1 60 61 62 65
! device index:  0:E4  1:E0  2:66  3:E6  4:E7  5:E1  6:60  7:61  8:62  9:65
L_00dc:
	.word	0xe4e0
	.word	0x66e6
	.word	0xe7e1
	.word	0x6061
	.word	0x6265

! ---- 0x00e6 .. 0x00fa  (word) ----   ;; LOADER-POINTER TABLE (10 words) -- ROM seg-0 vector offsets, REVERSED index
! reversed: pointer for device index i is the word at offset 2*(9-i).  Values
! are segment-0 offsets; ROM[value] holds the routine entry.  In ROM 4.1:
!   E0/E1 (FDU/MFDU) -> 0x6a -> 0x1642     E6/E7 (STC)  -> 0x7a -> 0x1e2c
!   62 (MTU)         -> 0xa2 -> 0x01c0     E4/66/60/61/65 (HDU) unsupported (16K 6.0)
L_00e6:
	.word	0x0096
	.word	0x00a2
	.word	0x0096
	.word	0x009e
	.word	0x006a
	.word	0x007a
	.word	0x007a
	.word	0x0096
	.word	0x006a
	.word	0x0062

! ---- 0x00fa .. 0x0110  (word) ----   ;; scratch: saved boot marker (0xcccc placeholder) + fill
	.word	0xcccc
	.word	0x0000
	.word	0x0000
	.word	0x0440
	.word	0x0540
	.word	0x0700
	.word	0x1e00
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000

! ---- 0x0110 .. 0x0114  (word) ----   ;; MONITOR ENTRY <<25>>0x0234 (0x99000234) -- jp target after the load
	.word	0x9900
	.word	0x0234

! ---- 0x0114 .. 0x0200  (word) ----   ;; LOAD DESCRIPTOR (9 bytes) -- 99 00 02 00 / 0e 00 / 01 00 01
! 99 00 02 00 = dest <<25>>0x0200   0e 00 = length 0x0e00 (3584 B = 14x256B sec)
! 01 00 01    = start C/H/S params.  Copied (9 bytes) to <<1>>0x0366 by the ROM
! loader, which reads the run into <<25>>0x0200.  Monitor entry <<25>>0x0234 lies
! inside this image.  (Bytes past 0x011c here are a table used by the Monitor,
! not by this first stage.)
L_0114:
	.word	0x9900
	.word	0x0200
	.word	0x0e00
	.word	0x0100
	.word	0x0100
	.word	0x0000
	.word	0x9d00
	.word	0x0000
	.word	0x9d00
	.word	0x0000
	.word	0x13fe
	.word	0x0100
	.word	0x0f00
	.word	0x0000
	.word	0x9c00
	.word	0x0000
	.word	0x9c00
	.word	0x0000
	.word	0x0bfe
	.word	0x0101
	.word	0x0900
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8200
	.word	0x0000
	.word	0xfe00
	.word	0x0101
	.word	0x1500
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8300
	.word	0x0000
	.word	0xb000
	.word	0x0601
	.word	0x0f00
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8400
	.word	0x0000
	.word	0xb000
	.word	0x0a00
	.word	0x0900
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8500
	.word	0x0000
	.word	0x4400
	.word	0x0d01
	.word	0x0300
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x8700
	.word	0x0000
	.word	0x1200
	.word	0x0e01
	.word	0x1300
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x1a00
	.word	0x0000
	.word	0x0bfe
	.word	0x0f00
	.word	0x0b00
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000
	.word	0x0000

