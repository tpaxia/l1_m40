# M30/M40 configurable bus and card-cage design

## Purpose

This note records a proposed MAME architecture for configuring an M30/M40 with
different UC and governo boards. It is a design proposal, not an implementation.

The goals are:

- represent the UC, backplane, RAM, and governo boards as distinct hardware;
- let users add, remove, or swap governo cards with standard MAME slot options;
- preserve the real interrupt and DMA priority imposed by physical placement;
- reproduce the ROM slot scan, including no-READY faults for empty positions;
- support reproducible, tested configurations for diagnostic and system disks;
- keep uncertain or impossible layouts clearly marked as experimental.

## Evidence and important distinctions

### UC and governo identity

The photographed M40 uses a UC042. It contains the Z8001, Z8010, boot ROM,
MB15652 bus arbiter, 8253, ACIA, and bus interface. The UC is therefore the bus
owner and CPU complex, not an ordinary peripheral governo.

Diagnostics also identify other UC families:

- UC036 and UC051: older boards without the gate-array implementation targeted
  by `UC3003`;
- UC042: the photographed M40 board with MB15652, best matched by `UCY805` and
  the M40-applicable portions of `UCV305`;
- UC048: later M44-class board with different clock and memory expectations.

Changing UC type can change the CPU clock, ROM layout, UC registers, arbiter,
memory organization, and interrupt wiring. It must not be treated as merely
swapping a peripheral card.

### Electrical slot identifier versus physical position

Two independent concepts must not be conflated:

1. The electrical slot name/select used by the ROM scan and governo I/O decode.
2. The physical board position in the card cage and daisy chains.

The M30/M40 diagnostic display has entries `00` through `0F` and always reports
the UC as entry `0F`. This confirms the UC's reported/electrical identity, but it
does not by itself prove that the UC PCB is physically the sixteenth board.

The M34/M44 service manual documents the compatible mechanical layouts, and its
compatibility table identifies the backplanes shared with the older systems:

| Family | Positions | CPU | First RAM | Physical numbering |
|--------|-----------|-----|-----------|--------------------|
| M30/M34 (`IN062`) | 9 | 2 | 1 | bottom to top |
| M40/M44 (`IN074`) | 14 | 1 | 2 | right to left viewed from the front |

M30 also accepts `IN052`, and M40 accepts `IN051/IN061`; the shared `IN062` and
`IN074` entries, together with the board-upgrade path from M30/M40 to M34/M44,
establish that the chassis layout is unchanged. This is direct evidence for the
physical count and CPU/RAM positions. The M30/M40 diagnostic manual separately
states that the UC is always logical entry `0F` and that the lower-named
controller is nearer the UC. Thus the CPU's electrical select is `F` even when
its physical position is 1 or 2.

The bus model should consequently give every connector both values:

```text
physical position  electrical slot name  permitted role
```

I/O decode and the ROM configuration table use the electrical name. Interrupt,
DMA, and card-cage validation use physical position.

### Governo address format

The FDU manual gives the M30/M40 governo I/O format as:

```text
bits 15-12  slot name/select
bits 11-8   unused
bits 7-0    governo register
```

The slot object should supply the high-nibble selection. The card implements the
low register byte and returns its logical/type ID from the identification port.
Board type remains independent from placement. For example, moving a GO252 does
not change its `FE` type ID.

The card interface should carry 16-bit data and `mem_mask`, despite many boards
being byte-wide. This preserves byte-lane behavior and permits boards such as
GO363 whose diagnostics use word I/O.

### Empty slots and READY

An empty governo selection is not just an `0xFFFF` read. During the ROM scan,
an absent board fails to produce READY, causing the UC's NMI recovery path to
skip that slot. The bus must invoke that path for accesses to an empty electrical
slot.

## Proposed MAME structure

```text
m30/m40 machine or chassis configuration
  required UC configuration
  M30/M40 bus/backplane device
  fixed physical connector descriptions
  configurable governo slot devices

device_m40_card_interface
  go252_device
  go280_device
  go151_device
  go300_device
  go303_device
  go327_device
  go363_device
  other boards as their protocols become definite
```

The useful MAME analogues are:

- ISA for user-selectable slots, defaults, card-owned devices, and IRQ/DMA
  plumbing;
- Apple II and NuBus for cards that know their slot and derive an address window
  from it;
- NABU option bus for central dispatch to a selected slot;
- RC2014 for modular cards containing standard serial, timer, storage, and CPU
  devices.

The M40 needs a native bus because none of those buses implements its particular
READY fault, priority chains, address format, or UC relationship.

## UC representation

The UC should be a fixed bus participant and priority-chain anchor. Initially it
is safer to choose it through machine configurations, for example:

```text
m30 with a supported M30 UC
m40 with UC042
m44 with UC048
```

A dedicated `-uc` slot is technically possible, but only compatible choices
should be offered. Arbitrary combinations such as UC048 in an M40 chassis should
be rejected unless later documentation proves them valid.

Longer term, a UC device can own:

- Z8001 and Z8010;
- ROM selection;
- UC 8253 and ACIA;
- MB15652 or the appropriate earlier arbiter implementation;
- RAM/READY handling;
- local interrupt sources and acknowledge logic;
- the governo bus and physical-layout description.

This would move UC-specific behavior out of `m40_state`, but it should be done
after the governo bus works without behavioral regressions.

## Slots and command-line overrides

The standard machine would supply defaults, such as GO252 and GO280 in their
documented connectors. Standard MAME slot options would override them:

```sh
mame m40 -slot1 go252 -slot2 go280 -slot3 go327
```

Swapping cards would be expressed by changing the options:

```sh
mame m40 -slot1 go280 -slot2 go252
```

A card can be removed explicitly:

```sh
mame m40 -slot3 none
```

Physical slot option names should follow the documented one-based cage positions.
The bus keeps physical position separate from the electrical select: the CPU is
select `F`, while the current M30/M40 defaults retain the ROM-proven controller
selects (`1` for GO252 and `2` for GO280). `-listslots` should enumerate compatible
cards and show descriptions that include the connector's physical position.

Cards can expose subordinate options. A serial governo could contain standard
MAME SIO/DART, 8253, and RS232 devices, allowing commands conceptually like:

```sh
mame m40 -slote go327 -slote:rs232a terminal -slote:rs232b null_modem
```

Real PCB switches should be configuration inputs when they alter one board's
mode. Distinct boards or incompatible register protocols should remain distinct
slot options rather than being hidden behind a generic serial-card model.

## Physical card-cage validation

Documentation for the compatible chassis says that installed boards cannot have
vacant positions between them. Validation must inspect physical cage order, not
electrical slot-name order.

Valid layouts:

```text
UC | board | board | board | empty | empty
UC | board | board | empty | empty | empty
```

Invalid layout:

```text
UC | board | empty | board | empty | empty
```

At startup, the backplane should walk outward from the UC through each applicable
contiguous region. After it sees an empty position, a populated later position is
an error. Removing a middle board therefore requires physically moving subsequent
boards toward the UC, which also changes their priority.

An error should identify both positions:

```text
Invalid M40 card-cage layout: physical position 4 is populated after empty
position 3. Boards must be contiguous from the UC.
```

There may be chassis-specific exceptions, such as a memory-only connector outside
the governo chains. These must be represented in the physical-layout table rather
than handled by a universal no-gap rule.

For reverse-engineering experiments, validation may offer `Strict` and `Warn`
modes. Validated configurations must use `Strict`. `Warn` must still report the
electrically impossible or uncertain arrangement.

## Interrupt and DMA priority

The compatible hardware documentation describes three interrupt chains with
different traversal rules:

```text
L1A  highest system level; nearer the UC has higher priority
L1B  middle system level; farther from the UC has higher priority
L2   lowest system level; nearer the UC has higher priority
```

DMA priority decreases with distance from the UC. The exact applicability and
wiring on M30/M40 must be checked against its original backplane diagrams, but
the bus API should support these rules rather than hard-coding one ascending slot
scan.

Every interrupt source should provide:

```text
interrupt level
physical position
pending state
vector
acknowledge callback
```

The UC also supplies sources. Later compatible documentation identifies its ACIA
as switchable between L1A and L1B and its timer as L2. These sources should enter
the same resolver at the UC anchor, not be checked in an unrelated hard-coded
order.

On acknowledge, the resolver should:

1. choose L1A before L1B before L2;
2. traverse that level in its documented physical direction;
3. select the first pending source;
4. invoke that card or UC source's acknowledge operation;
5. return its programmed vector.

DMA-capable cards should request the bus through the backplane. The arbiter then
uses physical priority and supplies grant plus physical-memory read/write access.

## IPL priority is separate

The UC ROM's IPL-controller search order is not the interrupt priority chain. It
is selected by the ISL switch. The documented default search order is:

```text
HDU 5010
HDU 6813
DCU 9448 fixed
FDU
MFDU
STC
DCU 9448 removable
```

The emulator should not replace this ROM policy. It should accurately expose the
configured cards, type IDs, slot responses, and ISL switch so the ROM performs
the search itself.

## Default and validated configurations

Two layers are useful.

### MAME hardware defaults

The MAME driver can define normal hardware defaults for real machine families:

```text
m30
m40
m44
```

Users remain free to override governo slots on the command line. Separate MAME
system variants should be created only for historically meaningful hardware or
UC/chassis combinations, not for every disk image encountered during research.

### Harness profiles

The Python harness can maintain reproducible profiles for disks and experiments:

```text
m40_diag_uc042
m40_ese31
m40_mdos30
m40_mdos32
```

A profile should record:

```text
chassis and UC type
ROM selection and hash
RAM size and refresh behavior
each board's type, electrical slot, and physical position
board switches and interrupt level
drive and serial attachments
disk image and SHA-256
MAME source commit
expected ROM configuration table
expected screen or execution milestone
diagnostics known to pass
```

Explicit command-line or harness slot options should override profile defaults
for one run without modifying the stored profile.

Profiles need an explicit validation status:

```text
documented             derived from manuals or a real-machine inventory
boots                  reaches a defined boot milestone reproducibly
diagnostics-validated  selected applicable diagnostics pass
experimental           incomplete, uncertain, or blocked
```

The current UC042/GO252/GO280 diagnostic setup is the first candidate for a
diagnostics-validated profile after the slot refactor reproduces the present test
results. The real ESE 3.1 setup is evidence-backed but should not be called
validated until its configuration display and prompt are reproduced. MDOS30 is
currently experimental because it reaches the E0xx wait but does not complete a
known successful boot.

## Current implementation status

The MAME `olivetti_l1` bus now implements the structural portion of this design:

- separate one-based physical cage position and four-bit electrical select;
- fourteen-position M40/M44 and nine-position M30/M34 chassis descriptions;
- fixed model-dependent CPU and first-RAM positions;
- strict rejection of a populated governo beyond an empty outward-chain position;
- card-owned I/O, memory, interrupt and DMA behavior;
- automatic `-ramsize` decomposition into one or two documented board-capacity
  profiles, or additive explicit ME027-32/RA57 slot cards; the two modes are
  mutually exclusive;
- L1A/L1B/L2 interrupt resolution with the documented per-level chain directions,
  including UC ACIA and timer sources at the CPU anchor;
- DMA grant priority by physical distance from the UC.

The M40 default is UC042 in position 1, an automatic 512 KB ME027-32 profile in
position 2, GO252 in position 3 and GO280 in position 4. Two-board automatic
populations place their second profile in position 5. The resident ROM memory test
has completed for every supported automatic total (256, 384, 512, 640, 768, 896,
1024, 1536 and 2048 KB), and an explicit two-board population; see
`scripts/test-m40-ram-config.sh`. The M30/M34 chassis rules are encoded, but an
M30 machine configuration and its correct CPU-board type are not yet instantiated.
The ACIA is currently assigned to L1A; exposing its documented L1A/L1B selection
awaits exact UC042 switch/jumper evidence.

## Suggested implementation sequence

1. Confirm the M30 and M40 physical connector order, UC position, electrical
   slot-name straps, and priority-chain direction from primary documentation.
2. Add a passive M30/M40 bus and configurable empty slots without moving board
   behavior yet.
3. Route empty-slot accesses through the READY/NMI path and verify the ROM scan.
4. Move GO280 into a card device and repeat all FDU boot/diagnostic checks.
5. Move GO252 into a card device and repeat video/keyboard diagnostics.
6. Replace ad hoc VI acknowledge ordering with the level/physical-position
   resolver, including UC timer and ACIA sources.
7. Add strict physical-layout validation.
8. Add the first serial governo only when diagnostics and manuals establish its
   register and interrupt behavior.
9. Add harness profiles, hashes, expected screens, and regression checks.
10. Promote only reproduced historical configurations to MAME defaults or named
    machine variants.

## Open questions requiring primary evidence

- Exact physical UC position in each M30 and M40 chassis.
- Mapping from physical connectors to electrical slot names `0..F`.
- Whether every apparent empty connector participates in the same no-gap rule.
- Exact L1A/L1B/L2 routing and acknowledge direction on M30/M40, as distinct
  from the later compatible M34/M44 implementation.
- Which UC boards and ROM releases are valid in each chassis.
- Historically correct board order for the photographed M40 and real ESE system.
- Which serial governo, if any, the currently studied MDOS images expect.
