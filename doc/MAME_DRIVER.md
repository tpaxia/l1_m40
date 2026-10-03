# MAME M40/M44 driver — implementation and reverse-engineering notes

This document records the hardware knowledge, diagnostic discoveries and deliberate
emulation choices embodied in `src/mame/olivetti/m40.cpp` and the boards in
`src/devices/bus/olivetti_l1/` (branch `m40_z8010_sup_test` of `tpaxia/mame`). It complements
[`doc/HARDWARE.md`](HARDWARE.md), which is the hardware/ROM reference,
[`doc/KDC.md`](KDC.md), which owns the keyboard/video protocol, and
[`doc/DIAGNOSTICS.md`](DIAGNOSTICS.md), which owns the diagnostic-disk workflow.

Provenance tags follow the rest of this repository: **[ROM]**, **[DISK]**,
**[MAN]**, **[PHOTO]**, **[EMU]** and **[?]**. Statements explicitly labelled
**model** describe a MAME implementation choice rather than proven hardware.

## 1. Driver scope and machine composition

Current user-facing additions (2026-09-10): the default M40/M44 layout shows
the actual Console IPL Switch below the screen (ISL1 Hard Disk / ISL2 Floppy
Disk). Control it through Tab → Machine Configuration; the indicator does not
add any boot-policy logic. GO280 image order is provisionally BCOS-facing:
flop1/2/3/4 map to controller units 1/2/3/0, with all four 8dsdd connectors
populated by default. Electrical/controller selection is unchanged. This is
an **[EMU]** presentation choice, not a proven physical jumper truth table.
Start fresh rather than loading states made with the former connector topology.

The current driver models the single-MMU M40 sufficiently to pass the resident
self-test, run the M40-applicable DCOS 8.4 diagnostics, and run ESE, MDOS, BCOS II
(floppy and hard disk) and MOS (hard disk). It instantiates:

- Z8001 at 4 MHz (`32 MHz / 8`) and one Z8010 MMU;
- 16 KB REL 6.0 ROM, RAM beginning at physical `0x010000`, and the GO252 video
  window at physical `0xFF0000`;
- UC 8253, EF68B50P/6850 ACIA, MB15652 bus arbiter and UC glue latches;
- GO252 KDC with MC6845, keyboard protocol, ANK 1426 matrix and text renderer;
- GO280 FDU with µPD765, AM9517 DMA, on-board 8253 and four 8-inch connectors;
- optionally (`-slot5 go363`), the GO363 hard-disk board around MAME's µPD7261, with
  two CHD drives. Booting from it needs the patched `m40rom-6.0-hd65.bin`
  (`doc/HARDWARE.md` §10).

The M44 ROM set is kept with this driver because it belongs to the same M30/M40/M44
hardware family, not to the M20 driver. The M44 currently reuses the M40 machine
configuration as a bring-up approximation; its different UC048/two-MMU hardware is
not yet modeled. **[EMU]**

The GO363 wrapper translates the board's command protocol, recovered from DCOS
([GO363_DCOS_RECOVERY.md](GO363_DCOS_RECOVERY.md)), onto the existing µPD7261 device,
and adds the board's word-addressed DMA, VI and ID buffer. **[EMU]**

## 2. CPU, MMU and physical memory

### 2.1 Address spaces and translation

The Z8001 program, data and stack spaces are distinct and all pass through the
Z8010. The driver classifies MMU bus cycles as first instruction fetch, subsequent
instruction fetch, stack request or data request. The CPU's actual FCW bit 14 drives
the Z8010 N/S input; this is essential for the UC3003 system-only violation test.
The upper-range-select bit is masked because the M40 has the single-range wiring.
When the MMU master-enable bit is clear, translation is transparent. **[DISK]/[EMU]**

Special I/O is the Z8010 programming space. Standard I/O uses the L1 backplane
decode: address bits 15–12 select a slot, bits 7–0 select a register, and bits 11–8
are ignored. Electrical select and physical cage position are distinct. The current
M40 configuration puts the UC, RAM, GO252 and GO280 in physical positions 1–4;
their electrical selects are respectively `F`, `0`, `1` and `2`. The M40/M44 cage
has 14 physical positions. **[MAN]/[ROM]/[EMU]**

The bus separately records every physical connector, including empty ones. It
validates the documented fixed locations (M30/M34: RAM position 1, CPU position 2;
M40/M44: CPU position 1, RAM position 2) and rejects a governo installed beyond an
empty connector in the outward priority-chain direction. Error messages use
one-based physical cage positions, not electrical select numbers. **[MAN]/[EMU]**

Governi can be moved or exchanged with ordinary MAME slot options. A trailing
board can be removed with an empty option; removing a board between populated
positions is rejected by the physical-layout check:

```sh
# Exchange the default video and floppy positions
./m40 m40 -slot3 go280 -slot4 go252

# Remove the trailing GO280
./m40 m40 -slot4 ''
```

### 2.2 Violation suppression (SUP)

The Z8010's SUP output suppresses the violating transfer and all remaining CPU
memory transfers through the end of that instruction. The model records the
violating PC, returns a harmless `NOP` word for a suppressed instruction fetch and
all ones for suppressed data reads, and drops suppressed writes. A first-word fetch
for the next instruction ends the normal suppression window. **[MAN]/[DISK]/[EMU]**

There are two important exceptions discovered with UC3003:

- reading UC register `0xFF00` disables write inhibition, so a violating write
  reaches memory; reading `0xFFA0` re-enables inhibition;
- a segment-trap or NMI acknowledge ends the violating instruction and must release
  suppression immediately. Otherwise the PSA vector read and trap-frame stack
  writes still appear at the violating PC, are suppressed, and the CPU vectors into
  garbage. This was the cause of the post-SUP trap failures. **[DISK]/[EMU]**

The Z8010 drives the Z8001 SEGT line. During the SEGT acknowledge cycle the CPU reads
the MMU identifier/status word and the MMU drops SEGT. UC3003 installs a segment-trap
handler at PSA+`0x20`, write-protects a descriptor, performs the violating write and
checks that the handler and all violation registers are correct. **[DISK]/[EMU]**

### 2.3 Physical map and READY faults

The current physical decode is:

| Physical address | Model |
|---|---|
| `0x000000–0x003FFF` | REL 6.0 ROM; writes ignored |
| `0x010000…` | contiguous configured RAM |
| `0xFF0000–0xFFFFFF` | GO252 framebuffer window |
| everything else | no `READY` → NMI |

RAM and VRAM are stored big-endian: the byte at an even address is the high byte of
the Z8001 word. A plain unpopulated access sets `0xFF41` bit 7 as the modeled NMI
cause, leaves bit 6 clear, and asserts NMI. The ROM's RAM-sizing/slot-scan handler
interprets bit 6 clear as the ordinary no-`READY` case and resumes through `rr12`.
Setting bit 6 for this fault makes the ROM follow its distinct power/BBU path and
mis-size memory. DMA to an unpopulated/ROM address is ignored rather than generating
a CPU READY fault. **[ROM]/[DISK]/[EMU]**

### 2.4 RAM-card population and command line

The manuals identify two RAM-board families; their capacities and DRAM technologies
are listed in `doc/HARDWARE.md` §1.1. MAME offers the three documented populations of
the `ME027-32` plus all five `RA57` variants:

| Slot option | Board | Installed capacity |
|---|---|---:|
| `me256k` | ME027-32 | 256 KB |
| `me384k` | ME027-32 | 384 KB |
| `me512k` | ME027-32 | 512 KB |
| `ra57d` | RA57/D | 512 KB |
| `ra57e` | RA57/E | 512 KB |
| `ra57c` | RA57/C | 1 MB |
| `ra57b` | RA57/B | 1.5 MB |
| `ra57a` | RA57/A | 2 MB |

There are two mutually exclusive configuration modes:

1. Supplying `-ram` makes MAME populate the required physical board profile(s).
2. Selecting ME/RA57 cards in slots makes installed RAM equal to the sum of those
   cards. In this mode `-ram` must not be supplied.

The default is the first mode's 512 KB ME027-32 profile. Automatic totals are split
as follows; the first board occupies the required first M40 RAM position (`slot2`),
and a second board occupies `slot5` after the default GO252 and GO280:

| `-ram` | Automatic physical population |
|---:|---|
| `256k` | ME027-32 256 KB |
| `384k` | ME027-32 384 KB |
| `512k` | ME027-32 512 KB |
| `640k` | ME027-32 384 KB + ME027-32 256 KB |
| `768k` | ME027-32 512 KB + ME027-32 256 KB |
| `896k` | ME027-32 512 KB + ME027-32 384 KB |
| `1m` | RA57/C 1 MB |
| `1536k` | RA57/B 1.5 MB |
| `2m` | RA57/A 2 MB |

Examples:

```sh
./m40 m40
./m40 m40 -ram 1m
./m40 m40 -ram 1536k
./m40 m40 -ram 2m
```

With explicit slot cards, each card owns storage of its real capacity. Multiple
cards are mapped contiguously from physical `0x010000` in increasing cage-position
order, and the first explicit RAM card must be in `slot2`. For example:

```sh
# One 512 KB RA57/E in the normal first RAM position
./m40 m40 -slot2 ra57e

# One 1 MB RA57/C
./m40 m40 -slot2 ra57c

# Two 256 KB ME027-32 populations; slots 3 and 4 contain GO252 and GO280
./m40 m40 -slot2 me256k -slot5 me256k
```

This is rejected rather than silently choosing one configuration source:

```sh
./m40 m40 -ram 640k -slot2 me384k -slot5 me256k
```

The available card choices and current defaults can be inspected with:

```sh
./m40 m40 -listslots
```

Internally, two hidden automatic devices let the RAM size option (`-ram`) configure
one or two board profiles after MAME has constructed the slot tree. They use one
contiguous backing allocation but expose the physical boundaries above. With
explicit card options they contribute no memory. **[EMU]**

Run the RAM regression with:

```sh
scripts/test-m40-ram-config.sh
```

It cold-starts each supported automatic total with independent NVRAM and requires
the resident ROM to reach console code `0x44` after its memory phase. It also checks
every explicit card type, a two-card explicit population, and the mixed/misplaced
configuration errors. **[ROM]/[EMU]**

## 3. UC glue, ACIA and shared interrupts

The UC register map is tabulated in `doc/HARDWARE.md` §4. The implementation details
that matter in addition to the table are:

- `0xFFE0` writes are printed as resident diagnostic phase/error codes;
- `0xFF60–0xFF6F` implement the three-lamp set/clear/readback latch;
- `0xFF19` sets MASTO, `0xFF11` clears it, and `0xFFB1` bit 6 reads it;
- `0xFF41` bit 4 reflects the 8253 channel-1 output sampled by UCV305; writing
  `0xFF41` clears/re-arms the NMI latch;
- `0xFF01` is the UC timer VI vector latch and write-side `0xFFA0` is the ACIA VI
  vector latch. Read-side `0xFFA0` remains configuration/jumpers plus the suppression
  re-enable side effect. **[DISK]/[EMU]**

### 3.1 ACIA/KDC multiplexing at `0xFF20/0xFF22`

The EF68B50P is a real 6850 used by UC3003, with TXD looped to RXD for the internal
diagnostic. The resident keyboard byte stream is overlaid on the same status/data
interface:

- a queued keyboard byte adds both RDRF (bit 0) and the resident handler's byte-ready
  trigger (bit 2) to the real 6850 status;
- keyboard bytes take priority on data reads; when the keyboard FIFO is empty the
  read reaches the 6850 loopback data;
- writes remain visible in the byte latch, are not fed back into the host-key FIFO,
  and are also transmitted through the 6850 loopback path. **[DISK]/[EMU]**

The 6850 IRQ joins the shared Z8001 VI line. Its interrupt enable remains off during
normal monitor use (the boot writes only the `0x03` master reset), but UC3003 enables
and tests its polling and interrupt modes. **[DISK]/[EMU]**

### 3.2 Shared VI arbitration

GO280, GO252, the UC timer and the UC ACIA share VI. Each source now enters the L1
backplane resolver with an interrupt level and physical position:

| Source | Level in the current profile | Position |
|---|---|---|
| UC ACIA | L1A | UC anchor |
| GO252 KDC | L1B | card position |
| UC timer | L2 | UC anchor |
| GO280 FDU | L2 | card position |

The resolver selects L1A before L1B before L2. Within L1A and L2, the board nearer
the UC wins; L1B traverses in the opposite direction, so the board farther from the
UC wins. The later compatible documentation describes the ACIA level as switchable
between L1A and L1B; the current UC042 profile selects L1A, pending exact UC042
jumper evidence. The timer request is edge-latched and cleared by acknowledge; the
6850 IRQ clears when its ISR services the ACIA status/data cause. **[MAN]/[DISK]/[EMU]**

## 4. GO252 KDC and keyboard protocol

Detailed keyboard tables and bindings are in `doc/KDC.md` and `keyboard/KEYMAP.md`.

### 4.1 Board interface and video self-test

GO252 reports type `0xFE`. Its status register `0x81` returns monitor type 0 in bits
0–2 and a toggling live-signal in bit 3. The resident video self-test selects one of
eight CRTC tables, programs MC6845 index/data at `0x41/0x43`, walks the segment-61
framebuffer, observes the live-signal change, writes control `0x01`, and finally
writes `0x6A` to enable normal video. **[ROM]/[EMU]**

The byte-oriented board registers are exposed on the Z8001's 16-bit I/O bus. Reads
mirror the selected byte into both halves of the returned word; writes dispatch the
high and low byte lanes to consecutive board registers. **[EMU]**

### 4.2 Status, control and VI

Read-side register `0x00/0x01` returns TX-ready bit 1 and RX-data-available bit 2.
The two bits are independent and must combine: returning RX instead of TX+RX makes a
pending key fail the resident direct-send TX-ready test with error `0x8006`.
Reading status arms the following data read when RX data exists. **[DISK]/[EMU]**

Write-side control bits are:

- bit 5: TX/completion VI enable. The modeled transmitter is always empty, so this
  is a level source until the resident driver clears the bit;
- bit 6: direct-send handshake;
- bit 7: RX VI enable. RX availability is edge-latched for acknowledge. **[DISK]**

Both causes use the vector programmed through `0x20/0x21`. The VI handler reads
status: bit 2 set selects the RX/data path; bit 2 clear selects TX/completion. A
vector write alone must never arm the interrupt, and KDC acknowledge must only win
the shared line when a KDC source is genuinely enabled and pending. **[DISK]/[EMU]**

### 4.3 Commands, identification and FIFO

The recovered, byte-exact Intel 8049 firmware now proves that these are independent
single-byte commands. KEYTE1 sends `0x06`, `0x08`, `0x0A`, `0x0C`, `0x10` to put
the five keyboard indicator outputs at their idle levels, then `0x02` to request
keyboard ID/jumpers. The keyboard replies `0xFB`, then a raw configuration sample
whose low five bits are the layout and high three bits are straps. KEYTE1's table defines layouts 0
(international) through 10 (Italy), 11 (Japan/Kana), and 17 (USA ASCII). The modeled
reply `0xF1` is layout 17 with strap value 7, the D.P./KUSA02 configuration; it is
the HLE strap choice, not a constant in the MCU ROM. KEYTE1 waits for `0xFB` before
dequeuing the configuration byte. **[KBDROM]/[DISK]/[EMU]**

At reset the real keyboard repeatedly sends `0xFC` until command `0x00`; command
`0x01` returns the ROM-check result (`0xFA` pass, `0xF9` fail), `0x03/0x04` gate
matrix scanning, ten commands control five P1 indicator pins, and `0x0D` starts a
self-timed beeper pulse. The current edited HLE dispatches `0x00`, `0x01`, and
`0x02` independently and returns `FA` or `FB F1` as appropriate. It still omits
startup `FC`, scan gating and visible indicator/beeper state. **[KBDROM]/[EMU]**

Gardini NLS3000 provides a useful independent check: unlike the diagnostics, it
does not send `0x00`. It polls GO252 status bit 0, sends `01`, reads `FA`, sends
`02`, and reads `FB F1`; it then issues `04 05 0C 0D`. The HLE retains this
pre-`00` polled mode while diagnostic/resident operation remains interrupt driven.

Command transmission completes immediately in the model. If bit 5 remains set for a
multi-byte command, the level TX VI reasserts for the next byte. Host keys enter a
small FIFO; reading either the GO252 data path or the UC ACIA overlay consumes the
next queued byte and keeps RX pending while more bytes remain. **[EMU]**

Host input is handled by a dedicated HLE ANK keyboard device using MAME's standard
matrix-keyboard interface. Matrix make transitions produce the decoded positional
scancodes; SHIFT and CONTROL break transitions produce their corresponding break
codes. Firmware confirms that ordinary keys use raw matrix positions `0x01–0x68`
(the MAME table has 101 unique entries; `32`, `33`, `45` are absent) and that the
auxiliary group uses make `0x6A–0x70`, break `0x72–0x78`. A callback
delivers each byte to the GO252/KDC FIFO above. The scanner runs
120 complete matrix passes per second to preserve the original driver behavior;
this is an input-sampling choice, not a measured M40 keyboard timing. The real
firmware also emits a held-key repeat token `0x80`, which the HLE does not yet
produce. **[KBDROM]/[EMU]/[?]**

Host commands05/06,07/08,09/0A,0B/0C,0F/10 now drive five saved MAME
keyboard LED outputs (READY,L1,L2,SHIFT,unidentified LED5). The layout
displays their actual values, not inferred switch or key state. BCOS
CONTROL+RUN is verified as left Ctrl+F8: it sets/clears its TEST bit and
sends09/0A for L2; BASIC reaches EDIT when TEST is enabled. See
`keyboard/BCOS_TEST_mode_and_keyboard_LEDs.md`. Scan modes and beeper timing
remain outside this addition. **[KBDROM]/[DISK]/[EMU]**

## 5. GO280 FDU

The authoritative register map and manual evidence are in `doc/HARDWARE.md` §6.3 and
`re/hardware/go280/FDU_governo_3963590.md`. This section records the exact implemented behavior.

### 5.1 Controller, rate and READY

GO280 reports type `0xE1` (FDU; NOM10=1). The µPD765/P8272 appears at `0x1D`
(main status) and `0x1F` (FIFO). The four connectors use 8-inch double-sided,
double-density drives. The governo runs at a fixed 500 kbit/s; the command's MF bit
selects FM versus MFM. Leaving MAME's default 250 kbit/s rate halves the cell clock
and prevents address-mark detection. **[MAN]/[EMU]**

In the configured FDU mode the FDC sees the drive READY signal. The former
unconditional CONTR bit 4 override fabricated READY transitions on absent drives,
causing spurious interrupts; it was removed after controlled diagnostic and BCOS
tests on 2026-09-09. The manual's separate DIAG0 diagnostic path is not yet
modelled. (MFDU instead has a documented pulled-up ready input.)
The governo control register also controls FDC reset and
interrupt enable.  FDU spindle motors run continuously; MOTO1/MOTO2 are for MFDU
configurations. **[MAN]/[EMU]**

### 5.2 Anomalous two-channel DMA

FDC `DMARO` drives AM9517 channel 2. Channel 2 transfers the FDC bytes, but channel 1
plus the `0xF6` high-address counters hold the memory word address. Channel 2 is a
local FDC↔buffer byte transfer and does not itself perform the system-memory cycle.
After each pair of channel-2 byte cycles, the board requests one channel-1 cycle;
the gate array turns its address into the actual 16-bit OLIBUS memory transaction.
That cycle advances the AM9517 channel-1 current address to the next memory word.
For reads, only the initial channel-1 cycle is suppressed; the per-word cycles still
occur. Firmware forms the initial address by shifting the physical byte address
right by one (`0x0F96`: `srll rr2,#1`). The running physical byte address is therefore:

```text
((0xF6 << 16) | channel_1_address) << 1 | byte_offset
```

The channel-2 AM9517 address, observed as `0xFFFF`, is not the system-memory
destination; its count controls the transfer. Register `0x58` clears only the
AM9517 first/second-byte flip-flop. A complete two-byte channel-1 address load resets
the board transfer cursor. DMA bypasses the Z8010 and writes the big-endian RAM
backing directly. **[MAN]/[ROM]/[EMU]**

At the AM9517 interface channel 1 is effectively a verify/address cycle: it does not
exchange a peripheral byte, although the surrounding board performs the OLIBUS word
read or write. The current-address advancement is visible to software when it reads
the AM9517 channel-1 address registers. BCOS JLD uses that value as the destination of the next
track-sized extent. Before the per-word channel-1 cycles were modeled, every extent
started at the original address: the second KER extent overwrote its header and first
code extent, and JLD subsequently interpreted opcode `0xed06` at offset `+0x0c` as an
allocation size, producing the blinking `OVF#SG2#` stop. This was a GO280 sequencing
error, not a Z8010 translation error or a damaged disk. **[MAN]/[DISK]/[EMU]**

The AM9517 `HRQ` is looped back to `HACK`, as on the board. System-bus arbitration
is requested separately by the gate-array `REQ00/BAXXN` path only for the channel-1
OLIBUS word transaction; channel-2 FDC/buffer cycles remain local. If multiple cards
request simultaneously, the populated card physically nearest the UC wins. Releasing
the bus after the word transaction, rather than after the complete internal DACK1
interval, is essential at terminal count. AM9517 terminal count drives µPD765 TC and
terminates the FDC transfer. **[MAN]/[EMU]**

### 5.3 Interrupt and timer latches

µPD765 `INTRQ` (`INTOO`) is rising-edge latched into board pending latch `INTP1`.
8253 channel-1 end-of-count (`INTMO`) reaches the same latch. `EN100` gates the
pending request onto VI; the VI acknowledge gates the programmed vector onto the bus
and clears `INTP1`. Writing `E01NT` at register `0xFF` acknowledges/resets the pending
interrupt and the source latches. `RD1NT` at `0xF7` reports the timer and FDC causes.
**[MAN]/[DISK]/[EMU]**

The on-board 8253 uses channel 0 as an approximately 10 ms time base cascaded into
channel 1. Channel 1 provides the 500 ms motor spin-up, 2 s motor-off and 800 ms
read/write timeout. Channel 2 is clocked by physical index while the FDC head-load
output is active. Its output is externally ANDed with index so the first two index
pulses of a data command are hidden from the FDC. MAME supplies the gated channel-2
clock, but does not yet put its output in the FDC index path: doing that directly
loses the gate-array phase and breaks IPL. **[MAN]/[EMU]**

The manual describes DIAG0 as a diagnostic READY source; equating this to an
unconditional CONTR.DIAGN override in normal FDU mode was not justified.
`IDXC0` is associated with the separate G10 `1101` diagnostic-test jumper setting.
`SCANO` is explicitly unused on GO280 (called 60280 in that paragraph), so it must
not be treated as a synthetic index output. **[MAN]**

The ROM boot masks VI and polls completion, while loaded diagnostic/runtime code can
use the programmed FDU vector. Tests 1/2/3/5 of 6030T6 verify controller
communication, timer, interrupt and compatibility. **[ROM]/[DISK]/[EMU]**

## 6. GO252 text rendering

Each framebuffer cell is two bytes: even address = attribute, odd address =
character. Pen 0 is beam off, pen 1 normal intensity and pen 2 high light. The
provisional attribute mapping, derived from CRTAN5 order and monitor writes, is:

| Mask | Effect |
|---|---|
| `0x01` | high/top line |
| `0x02` | low/bottom line |
| `0x04` | left line |
| `0x08` | right line |
| `0x10` | blink |
| `0x20` | high light |
| `0x40` | reverse video |

Blink is a field/frame-derived board function (approximately 1.5 Hz), not an MC6845
feature. Reverse swaps foreground/background. Edge attributes force pixels on the
cell boundary; the bottom line uses the actual MC6845 R9 maximum raster value rather
than a hard-coded scanline, otherwise boxed corners do not meet on the 17-line mode.
The monitor's observed `0x50` attribute is therefore reverse video plus blink.
**[DISK]/[EMU]**

The real character generator is the undumped `GI 9428DS-2067`. The model derives an
8×16 readable font from the M20/L1 5×7 house font: each row is shifted left one and
the ten-row form is centered on scanlines 3–12. Photos show matching shapes and a
slashed zero, but glyph-exact identity and codes above ASCII `0x7E` remain open.
**[PHOTO]/[EMU]/[?]**

The ROM programs 80×25 mode with 17-line cells. The current eight-dot character
width, approximately 57 Hz refresh, 2.67 MHz character clock and 2.5 ms vblank are
modeling approximations pending the GO252 dot-clock/schematic evidence. **[EMU]/[?]**

## 7. MB15652 bus/DMA arbiter

**2026-09-09 correction:** UC3003 now advances through tests 5 and 6 after fixing
NV2–NV4 re-masking and word-I/O strobe decoding. It stops at test 7 with a ROM
bank/size fault; this is not a complete UC diagnostic pass. Exact diagnostic
addresses and evidence are in [UC3003_NVI.md](../re/hardware/uc/UC3003_NVI.md).

The behavioral decode comes from the resident self-test, UC3003 VIENO test and
UCY805/UCO.71 bus-arbiter test:

- `0xFF80–0xFF83`: acknowledge/clear channels 0–3;
- `0xFF85–0xFF87`: mask NV2–NV4; `0xFF88–0xFF8B`: request NV1–NV4;
- `0xFF8D–0xFF8F`: enable NV2–NV4;
- read `0xFF81`: pending requests in bits 7–4 (`ch0` through `ch3`), VIENO/active in bit 3,
  and an idle marker in bits 2–0. **[DISK]/[EMU]**

VIENO is set by writes to `0xFF8C–0xFF8F` and cleared by writes to
`0xFF84–0xFF87`. A grant also makes bit 3 visible. Bits 2–0 read as `111` while
idle and clear while requests are pending. UC3003 expects `0x0F` with no requests
and `0xF8` with all requests pending and NV2–NV4 masked. **[DISK]/[EMU]**

NV1 is unmasked; NV2–NV4 have separate enable latches. Masked requests remain
pending and enabling them schedules delivery. The diagnostic releases preceding
channels as well, so arbitrary mask/priority combinations are not established by
this test alone. The existing 50 us arbitration delay remains an approximation.
With no enabled pending request, the delayed assertion is cancelled and NVI is
cleared. **[DISK]/[EMU]/[?]**

NVI acknowledge clears only the CPU line. Requests remain readable at `0xFF81`
until software writes the corresponding channel acknowledge. An enable strobe
may deliver an existing request, but cannot fabricate one. **[ROM]/[DISK]/[EMU]**

Each byte or word output produces one addressed strobe. The CPU exposes its
original I/O address before the memory interface aligns word accesses; the UC
uses that address bit for word writes and the byte lane for byte writes. Splitting
word `OUT FF87` into FF86 and FF87 incorrectly masks NV3 during the ROM's NV3
test and stalls at 00:0300. All these registers retain F0xx–FFxx aliases.

## 8. Debugging and regression tests

Later on 2026-09-09, explicitly authorized opt-in native `BCOS_HISTORY` probes
were added for the BCOS investigation. Their scope and removal instructions
are tracked in [BCOS_DEBUG_LEDGER.md](../re/os/bcos/BCOS_DEBUG_LEDGER.md). The subsequent
keyboard latency experiment was removed after it failed to improve startup.
UC register aliases now cover F0xx–FFxx (bits 11–8 ignored); VIENO gates all
level-2 vectored sources, without discarding pending requests or masking
level 1a/1b. Focused alias and interrupt-gate tests are in
`scripts/test-m40-uc.sh aliases`. These fixes do not imply a complete UC3003
pass or an interactive BCOS boot.

The temporary native instrumentation was removed on 2026-09-09: CPU/stack/MMU
probes, PC-specific triggers, RAM dumps, VRAM/FDU log files, board trace callbacks,
and trace-only DMA counters. `M40_CPU_TRACE*`, `M40_CPU_DUMP*`, `M40_VRAM_TRACE`
and `M40_FDU_TRACE` no longer affect the driver. The unimplemented console output
port no longer prints to the host terminal. **[EMU]**

Hardware diagnostic lamps, status registers, and interrupt cause latches remain
part of the emulation. The RAM regression script uses an explicitly loaded Lua
observer for ROM progress; normal launches install no such observer. Historical
trace decoders and captured evidence remain in `re/`, but their native tracing
instructions describe the pre-cleanup build. **[EMU]**

## 9. Known approximations

- GO252 monitor type/config registers other than the implemented status paths return
  all ones; this is why CRTAN5's automatic video-type check remains open.
- The attribute low-four-bit ordering remains provisional. The character generator
  is the dumped GI 9428DS-2067, but the dump's origin is undocumented.
- MB15652 arbitration has no delay: NVI follows the grant immediately, which the MOS
  kernel needs; there is no timing data (`re/evidence/uc-arbiter-nvi-latency-evidence.md`).
- The GO363 8253 is clocked from the photographed 20 MHz oscillator; the divider is
  unknown.
- **Regression:** on the current build (3 October 2026) the DCOS GO363 board test
  HDC505 fails test 2, "generate interrupt and test vectors": `'STATUS' ERROR AFTER
  RUN-COMMAND`, `UNSE0`, `SKEN0` and `UPR00` stuck at 1, with a blank or a formatted
  disk ([screen](../re/evidence/screenshots/hdc505-20261003-test2-failure.png)).
  On 20 September (`576ccea57ec`) tests 1–3 passed and test 4 stopped at step 3,
  with the same disk G, blank disk image and keystrokes. The saved binaries from
  1 October (`m40.pre-pcseg`, before any October change) and 2 October
  (`m40.pre-arb`) fail test 2 identically, and so does the current build with the
  IPL switch on floppy. Cause: `2eef3161383` (26 September) made register `43`
  report the unit-0 status bits whenever a disk is attached, which S24W25 needs,
  but HDC505 reads them without the auxiliary code `0D` that enables them
  ([evidence](../re/evidence/go363-unit-status-gate-evidence.md)). A fix in the
  MAME working tree (uncommitted) gates the bits on that code; with it tests 1–3
  pass and test 4 stops at step 1 (board timer interrupt), earlier than on
  20 September, a second regression not yet investigated. HDC5F5, Standard 24 and
  the BCOS and MOS hard-disk systems work.
- GO280 collapses the FUMEO no-READY timeout to an immediate missing-responder fault;
  RAM parity/PERRO and the exact DAW02 diagnostic waveform are not modeled. The
  external MASKO/IDXC0 index mux is also pending; channel 2 receives its documented
  head-load-gated clock, but physical index currently reaches the FDC directly.
- M44 currently shares the M40 configuration and is not a faithful M44 model.

## 10. Building, and the branch history

Build on macOS (Homebrew SDL3):

```sh
make SUBTARGET=m40 SOURCES=src/mame/olivetti/m40.cpp \
  OSD=sdl3 USE_LIBSDL=1 SDL_INSTALL_ROOT=/opt/homebrew REGENIE=1 -j8
```

How the branch got to its present form:

- **14 September 2026.** The MAME UI toggle was standardised on Scroll Lock
  (MAME's Windows default, set explicitly with `-uimodekey SCRLOCK` on macOS) and
  the host-keymap test was extended to check it. It was later replaced by F12 and
  the `m40-ui` controller profile, which the published commands now use
  ([installation/M40_UI_CONTROLS.md](../installation/M40_UI_CONTROLS.md)).
- **15 September.** The branch (`olivetti_m40`) was rebased onto mamedev master;
  all 51 commits replayed unchanged. Upstream had turned the RAM device into a
  slot, so `-ramsize 2048K` became `-ram 2m` (§2). The experimental GO363 was split
  into its own branch, `olivetti_m40_hd`. Three `invalidate_caches()` calls on MMU
  mode writes were removed: MAME's memory-access cache holds handler lookups, not
  Z8010 translations, and the M40 handlers translate on every access. After the
  rebase the keyboard map, the RAM configurations and a BCOS boot were retested,
  and after the cache change UC3003 and two BCOS boots; the HD split was only
  build-checked.
- **20 September.** GO363 was ported onto `m40_z8010_sup_test`, the branch with the
  current Z8010 bus-cycle model, as an ordinary L1 slot card (`-slot5 go363`).
  ESE and BCOS II regressions were unchanged. On this build HDC505 stopped at
  test 4 step 3 (board timer), the same as the old HD branch, so the earlier
  "test 4 passes" result was not reproduced.
- **25 September – 2 October.** uPD7261 and GO363 work for DCOS formatting and
  the hard-disk installs, then the arbiter, GO280 DMA, Z8001 and GO252 fixes; each
  has an evidence note in `re/evidence/` (indexed in its README).
