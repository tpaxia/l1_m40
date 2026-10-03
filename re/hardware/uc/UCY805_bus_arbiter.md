# UCY805 / UCO.71 bus arbiter test

2026-09-09 update: the shared UC3003 sequence now passes its NVI test after
implementing mask latches and single-address word strobes. The notes below are
the original reverse-engineering record; see [re/hardware/uc/UC3003_NVI.md](UC3003_NVI.md) for
the resolved word-I/O interaction and current validation. High-nibble readback
must include masked requests, not just enabled grants.

Working notes for disk-A reverse engineering. The useful manual reference is the
Functional Checks manual section 3.4, "UCY807: Central Unit Board UCO 71 Test
Program"; the disk-A menu string is `UCY805 UCO.71 MULTIPROCESSOR UC TEST 10.87`.

## Which test to use

The most useful arbiter test is **test 13, BUS ARBITER TEST**. The manual says this
test runs code on all CUs, attempts simultaneous bus accesses, and checks handling
of the shared resource, with cache both enabled and disabled.

Test 3, **MASTER AND VIENO SIGNALS TEST**, is useful for the multiprocessor signal
latches (`0xff50`, `0xff51`, `0xff54`, `0xff55`, etc.), but it only checks that
those signals set and reset correctly. It is secondary for the `0xff80..0xff8f`
arbiter itself.

The older Italian `Manuale dei collaudi` OCRs as the earlier `CPUTST` flow and does
not describe this UCO.71 arbiter sequence. It is background material; the concise
Functional Checks manual is the better procedure reference for UCO.71.

## Disk offsets

- `0x7b8e7..0x7bdba`: UCO.71 / UCY805 menu and test-name strings, including
  `13) BUS ARBITER TEST`.
- `0x6cd94..0x6ce1a`: arbiter NVI handler.
- `0x6ce1c..0x6cfde`: bus arbiter test body.
- `0x6cfe0..0x6cffc`: arbiter cleanup helper.

The code body is in the `UCG304` catalog extent (`0x6c500` region), while the
UCO.71/UCY805 strings name it from the multiprocessor UC menu. Treat this as shared
UC diagnostic code rather than assuming the string block and executable body are in
the same catalog span.

## NVI handler at image 0x6cd94

The test installs this routine into the PSA at `PSAP+0x34`, then enables NVI while
provoking arbiter grants.

```
0x6cd94  save r0..r13 to <<33>>0x4572
0x6cd9c  inb rl2,#0xff81
0x6cda0  andb rl2,#0xf0

0x6cda4  if rl2 == 0x90: set <<33>>0x4592, ack 0xff80,81,82,83
0x6cdc4  if rl2 == 0x80: set <<33>>0x458e, ack 0xff80
0x6cdd8  if rl2 == 0x40: set <<33>>0x458f, ack 0xff81
0x6cdec  if rl2 == 0x20: set <<33>>0x4590, ack 0xff82
0x6ce00  if rl2 == 0x10: set <<33>>0x4591, ack 0xff83

0x6ce12  restore r0..r13
0x6ce1a  iret
```

This is the cleanest channel map:

| Grant bit from `0xff81` | Seen flag | Ack strobe |
|---|---|---|
| `0x80` | `<<33>>0x458e` | `0xff80` |
| `0x40` | `<<33>>0x458f` | `0xff81` |
| `0x20` | `<<33>>0x4590` | `0xff82` |
| `0x10` | `<<33>>0x4591` | `0xff83` |
| `0x90` | `<<33>>0x4592` | `0xff80..83` |

## Test body at image 0x6ce1c

Initial setup:

```
0x6ce1c  clear error/status <<33>>0x3242
0x6ce22  clear grant flags <<33>>0x458e..0x4592
0x6ce40  install handler 0xcd94 at PSAP+0x34
0x6ce4e  di nvi
0x6ce50  outb #0xff8d,rl2
0x6ce54  outb #0xff8e,rl2
0x6ce58  outb #0xff8f,rl2
0x6ce5c  outb #0xff80,rl2
0x6ce60  outb #0xff81,rl2
0x6ce64  outb #0xff82,rl2
0x6ce68  outb #0xff83,rl2
0x6ce6c  inb rl2,#0xff81; expect 0x0f, else error 0x002c
0x6ce76  outb #0xff88,rl2
0x6ce7a  outb #0xff89,rl2
0x6ce7e  outb #0xff8a,rl2
0x6ce82  outb #0xff8b,rl2
0x6ce86  outb #0xff85,rl2
0x6ce8a  outb #0xff86,rl2
0x6ce8e  outb #0xff87,rl2
0x6ce92  inb rl2,#0xff81; expect 0xf8, else error 0x002c
0x6ceaa  ack 0xff80..83
0x6ceba  ei nvi
```

The output byte is usually just the current `rl2`; for these arbiter ports the
diagnostic looks like it is using address writes as strobes. Model the write address
first, and only treat the data byte as meaningful if another trace proves it.

## Byte vs word I/O access

This block has a remaining hardware-level uncertainty: the diagnostic proves the
arbiter is byte-addressable, but the ROM also uses word `out` instructions against
the same addresses.

Evidence for byte access from disk A:

```
0x6cd9c  inb  rl2,#0xff81        ; grant/status byte
0x6cdb2  outb #0xff80,rl2        ; ack ch0
0x6cdd2  outb #0xff80,rl2        ; ack ch0
0x6cde6  outb #0xff81,rl2        ; ack ch1
0x6cdfa  outb #0xff82,rl2        ; ack ch2
0x6ce0e  outb #0xff83,rl2        ; ack ch3
0x6ce76  outb #0xff88,rl2        ; request/strobe group
0x6cf00  outb #0xff8d,rl2        ; control/release group
```

Evidence for word access from the boot ROM:

```
0x02aa  out #0xff80,r0
0x02ae  out #0xff89,r0
0x02ba  out #0xff85,r0
0x02ca  out #0xff8d,r0
0x1216  out #0xff84,r0
0x122c  out #0xff8c,r0
```

Do **not** treat a 16-bit word write as a proven packed command word. The software
evidence does not show stable bit fields in the 16-bit data. In the disk diagnostic,
`rl2` often contains a previous status value or incidental value when it is written
back to the arbiter ports, and behavior correlates with the addressed port rather
than with the byte value.

Current safest emulator rule:

- Byte writes perform the exact byte-port strobe.
- Word writes perform the strobe for the addressed port and ignore the 16-bit data
  value unless another trace proves otherwise.
- Do not automatically strobe the adjacent byte register on a word write unless the
  Z8001 I/O bus model or schematics prove that this gate array decodes both byte
  lanes as separate register selects for a word cycle.

If later hardware evidence shows that word I/O is split by byte lanes, the likely
mapping would be the normal big-endian bus mapping: high byte on address `N`, low
byte on address `N+1`. That remains a hypothesis, not a fact derived from the ROM.

Grant/priority sequence:

| Step | Stimulus | Expected result | Error on failure |
|---|---|---|---|
| 1 | write `0xff88` | NVI handler sets ch0 flag `0x458e` | `0x002d` |
| 2 | write `0xff89` | ch1 must **not** grant immediately | `0x002e` if it does |
| 3 | write `0xff8d` | ch1 flag `0x458f` must appear | `0x002f` |
| 4 | write `0xff8a` | ch2 must **not** grant immediately | `0x0030` if it does |
| 5 | write `0xff8d`, `0xff8e` | ch2 flag `0x4590` must appear | `0x0031` |
| 6 | write `0xff8b` | ch3 must **not** grant immediately | `0x0032` if it does |
| 7 | write `0xff8d`, `0xff8e`, `0xff8f` | ch3 flag `0x4591` must appear | `0x0033` |

The pattern is the useful behavioral model: `0xff88..0xff8b` assert per-channel
test requests, but lower-priority requests are not granted until the corresponding
control/release strobes in `0xff8d..0xff8f` are issued. `0xff80..0xff83` are the
per-channel ack/clear strobes, and `0xff81` read exposes the grant bitmap.

Cleanup at `0x6cfe0` strobes `0xff80..0xff83` and `0xff8d..0xff8f`.

## Emulator model implied by the test

For a first implementation:

- Reads of `0xff81` return a status byte with high-nibble grant bits and low-nibble
  idle/control state. The test expects `0x0f` after reset/ack and `0xf8` after the
  initial request setup.
- Writes to `0xff80..0xff83` clear/ack grants for channels 0..3.
- Writes to `0xff88..0xff8b` request channels 0..3 for this diagnostic path.
- Writes to `0xff8d..0xff8f` release or enable the next lower-priority grant stages.
- A grant raises NVI; the handler reads `0xff81`, sets a software flag, and acks the
  granted channel.

Remaining uncertainty: the exact hardware distinction between `0xff84..0xff87` and
`0xff88..0xff8b`. The ROM uses `0xff84`/`0xff8c` for the boot DMA gate/control, while
this diagnostic sequence uses `0xff88..0xff8b` plus `0xff85..0xff87` during setup.
The safe current naming is "request/gate groups" until another overlay pins down the
individual signal names.
