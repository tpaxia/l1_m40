# M40 8049 keyboard firmware correlation

This note correlates the recovered M40 keyboard-controller ROM with the GO252
diagnostic reverse engineering and audits the current MAME HLE model.  The source
material lives in the M20 tree at `PCOS/src/KeyBoard/M40/`:

```text
80491402.MCU     2048-byte Intel 8049 mask-ROM image
m40_8049.s       annotated English source, byte-identical on reassembly
m40_8049.ita.s   statement-for-statement Italian source, also byte-identical
```

SHA-256 of the image is
`dd6f7e626fefc4d3316bd9d5dc4d8f1075d072d09b3b0cb382f4729c4e12e405`.
Both sources pass `make verify-m40`/`verify-m40-ita`; the tracer finds 1,097 reachable
code bytes (730 instructions), 62 dispatch-table bytes, 11 other data bytes, and 878
bytes of zero fill.  This makes the behavioral conclusions below substantially
stronger than inference from diagnostic execution alone.

## What the ROM proves

- The normal scanner covers 13 rows by 8 columns.  Its make code is the raw 1-based
  scan position, `0x01` through `0x68`; there is no ROM translation table and no
  normal-key break report.  MAME contains 101 unique populated codes in this range,
  with no duplicates; raw positions `0x32`, `0x33`, and `0x45` are not exposed by its
  diagnostic-derived input map.
- A separate eight-input group is scanned after the matrix.  Position `0x69/0x71` is
  explicitly suppressed; the remaining stable edges produce make `0x6A`–`0x70` and
  break `0x72`–`0x78`.  KEYTE1/manual assignments `SH=6E/76`, `LK=6F/77`, and
  `CN=70/78` agree exactly with this `make + 8 = break` mechanism.
- Debouncing uses four 2-bit states per switch: up, first down sample, confirmed down,
  first up sample.  A second transition during one scan causes the `0xFE` rollover/
  limit report path.
- A held normal key repeats after a 70-scan initial counter.  The repeat machinery
  sends the held key code on one path and later the special `0x80` token, with a
  10-scan repeat counter.  More host-side work is needed to name the exact two phases.
- Serial frames are start + 8 LSB-first data bits + stop.  TX and RX advance from the
  timer ISR and each has only one byte of storage.  No keyboard-side FIFO exists.
- Reset checks ROM, stores `0xFA` on success or `0xF9` on failure, and repeatedly sends
  `0xFC` until host command `0x00` completes the startup handshake.

## Complete MCU command map

The receiver rejects bytes above `0x10`; every accepted byte dispatches independently.
This is important: the byte strings seen in KEYTE1 are sequences of ordinary commands,
not multi-byte keyboard opcodes.

| Command | Firmware action | Diagnostic interpretation |
|---|---|---|
| `00` | set startup/ready bit 2 | finish the `FC` handshake |
| `01` | transmit saved `FA`/`F9` | ROM self-test result |
| `02` | set request bit 1 | later send `FB`, then configuration |
| `03` / `04` | clear / set bit 0 | disable / enable normal scan passes |
| `05` / `06` | clear / set P1.4 | indicator output |
| `07` / `08` | clear / set P1.3 | indicator output |
| `09` / `0A` | clear / set P1.2 | indicator output |
| `0B` / `0C` | set / clear P1.1 | indicator output (opposite command polarity) |
| `0D` | set P1.5; foreground later clears it | timed beeper pulse |
| `0E` | no operation | nominal beeper-off needs no action |
| `0F` / `10` | set / clear P1.0 | indicator output |

Command `02` reaches the path previously named `REPORT_SCAN_FAULT` in the fresh
disassembly.  Diagnostic correlation shows that name is too narrow: it transmits the
`0xFB` identification marker, clears the request bit, and schedules `SEND_CONFIG`.
That routine returns RAM `0x0C`, the raw P2 sample captured at reset while BUS is
`0xFF`.  Thus `FB F1` is correct for an emulated KUSA02 whose straps read `F1`, but
`F1` is not a firmware constant.

The KEYTE1 stream `06 08 0A 0C 10 02` first puts all five P1 indicator outputs in
their initial idle levels and then requests identification/configuration.  The
earlier MAME interpretation of this whole stream as an identification signature was
therefore accidental.

## MAME audit

Checked against `src/devices/bus/olivetti_l1/{keyboard,go252}.{cpp,h}` in the active
MAME tree:

| Area | Result |
|---|---|
| normal key codes `01–68` | correct for all 101 mapped keys; no duplicates; raw positions `32`, `33`, `45` unmapped |
| `6E/76`, `70/78` edge pairs | correct HLE behavior for mapped SHIFT/CONTROL |
| `6A–6D`, `6F/77` | not exposed by the current ANK1426 input map |
| debounce / rollover `FE` | omitted by HLE |
| repeat token `80` | omitted by HLE |
| command `02` → `FB`, config | externally correct result, but currently recognized through ad-hoc sequence state |
| commands `00`, `01`, `03–10` | MCU effects omitted (apart from their accidental role in sequence recognition) |
| startup `FC` and checksum `FA/F9` | omitted |
| serial bit timing | intentionally abstracted by byte-level GO252 HLE |
| keyboard buffering | MAME uses a 16-byte convenience FIFO; real MCU has one TX byte |

The byte-level abstraction is reasonable for GO252 bring-up, but command dispatch,
repeat, and outputs can now be modeled from ROM facts instead of signatures.  The
GO252 board-side TX-ready/RX-ready and VI behavior remains a separate hardware layer;
the MCU ROM does not by itself prove the board control-register bit assignments.

### Live diagnostic check (2026-09-02)

The apparent `ERROR ON UNIT 4` was a media-connector mismatch. The current M40
configuration fits drives at both `fdc:0` and `fdc:1`; the surviving software uses
unit 1, exposed by MAME as `-flop2`. Mounting disk B as `-flop1` made the monitor
issue HD/US byte `04` while requesting ID head 0, hence the missing-address-mark
result. With `-flop2`, `KEYTE1` loads and reaches its keyboard-jumper screen:
layout 17, U.S.A. ASCII, KUSA02.1, configuration `F1`. The captured run is
`runs-archive/20260902-221939-20260902-keyte1-fw-commands/`.

Gardini NLS3000 independently confirms command dispatch and polling. Its trace is
`01 -> FA`, `02 -> FB F1`, followed by commands `04 05 0C 0D`; an injected PC `H`
arrives as M40 code `1B`. The SCP-derived IMD boots through normal FDU reads to the
NLS-3000 utility menu and identifies slots `1-FE`, `2-E1`. Evidence is in
`runs-archive/20260902-gardini-native-trace/` and
`runs-archive/20260902-gardini-help-key/`.

## Remaining cross-checks

1. Trace host handling of `0x80` to name the first-repeat versus subsequent-repeat
   phases precisely.
2. Continuity-test the auxiliary selector inputs.  The ROM proves seven reportable
   edge-coded inputs, while photos show six microswitches beside the three rotary
   controls and KEYTE1 names three modifier pairs.  Their physical sharing/routing is
   not established by code alone.
3. Map P1.0–P1.4 to POWER-ON/READY/L1/L2 and the fifth red indicator.  Firmware gives
   exact command-to-pin behavior but not the PCB net names.
4. Measure the keyboard crystal/serial line or derive it from GO252 timing before
   assigning an exact baud rate or matrix scans per second.
