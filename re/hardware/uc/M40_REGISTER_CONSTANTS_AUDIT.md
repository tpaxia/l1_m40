# M40 register constants audit

2026-09-15; MAME `olivetti_m40`, base `eaa45037109`.

## Scope and constraint

Use existing chip constants only when already accessible to the caller. Do not
add chip constants, change their visibility, or duplicate private chip definitions
in board code. Board-local register addresses may have their own names.

The initially attempted changes to five existing chip devices and their M40
consumers were rejected and completely reversed before this replacement. The
current native diff touches **only GO252 and GO280**. No existing chip source or
header differs from HEAD. Nothing has been committed or pushed for this cleanup.

This is a source-level naming audit, not a new validation of the hardware model.
Evidence includes the current driver implementations, chip headers/implementations,
`doc/HARDWARE.md` sections 3–5, `doc/KDC.md` (including its correction at the top),
`re/hardware/go280/FDU_governo_3963590.md`, and the recovered `m40_8049.s` in the keyboard
firmware repository. Historical documents contain superseded interpretations;
an old statement is not enough to establish a hardware name.

## Existing chips

| Device | Existing definitions and accessibility | Action |
|---|---|---|
| Z8001 | Public `ST_IFETCH_1`, `ST_IFETCH_N`, `ST_REQ_STACK`, `ST_REQ_DATA`, address-space and interrupt-line identifiers | Already used in UC; keep them. Do not introduce a public FCW mask merely for the literal bit 14 check. |
| Z8010 | Mode, descriptor, violation and bus-cycle enums are protected; command offsets in read/write are numeric | Leave chip untouched. UC's mode-register comparison `0x00` and master-enable mask `0x80` remain numeric; do not expose `MODE_MSEN`. |
| 6850 ACIA | Status masks `SR_RDRF`…`SR_IRQ` are private; named status/data/control methods are public | Keep method calls. Do not expose masks or recast GO252's uncertain status semantics as ACIA behavior. UC's `0x05` keyboard overlay remains unchanged. |
| MC6845 | Public address/register methods, no public register-index constants | Keep indirect register `0x09` and masks numeric. Board CRTC address/data offsets are independently named below. Variant-specific register indices must not be treated as universal. |
| 8253 | Public counter/clock/read/write methods, no public register-offset enum | Keep `(offset >> 1) & 3` decoding. No new counter/control constants or changes to PIT internals. |
| AM9517A/8237A | `REGISTER_*` enum exists only in `am9517a.cpp`; mode helpers there are state-dependent macros | Do not move/expose/copy them. GO280's DMA range, mode-register address `0x56`, channel extraction and decrement bit remain unchanged. |
| uPD765 family | Protected status masks and live-state enum are available to the existing GO280 subclass | It already uses `ST0_ABRT` and `WRITE_*` states. Keep that reuse. Do not invent one register map shared by all FDC variants or expose protected internals to unrelated boards. |
| uPD7261 | HD-only consumer; excluded from base M40 branch | No changes. Any further HD naming work belongs on `olivetti_m40_hd`. |

The constant's visibility must be checked from the actual caller: protected
uPD765 names are usable by its subclass, but protected Z8010 names are not
usable by UC, which owns a device rather than inheriting from it.

## GO252: implemented names

The board masks A0 with `offset & 0xfe`. These constants therefore identify the
normalized board offsets, not the original odd port addresses and not internal
MC6845 register indices.

| Offset | Read name | Write name |
|---|---|---|
| 00 | `REG_KBD_STATUS` | `REG_KBD_CONTROL` |
| 02 | `REG_KBD_DATA` | `REG_KBD_DATA` |
| 20 | — | `REG_KBD_VECTOR` |
| 40 | — | `REG_CRTC_ADDRESS` |
| 42 | `REG_CRTC_DATA` | `REG_CRTC_DATA` |
| 6A | — | `REG_VIDEO_ENABLE` |
| 80 | `REG_VIDEO_STATUS` | — |
| FE | `REG_BOARD_ID` | — |

The video-enable name describes the ROM-observed strobe; the source explicitly
notes that it remains unimplemented. No extra decoding or side effect was added.
Status values 02/01/04/83, control bits, queue behavior and firmware command
handling are unchanged. Existing `ATTR_*` bit-position constants are already
appropriate for `BIT`; do not replace them with bit masks without changing usage.

## GO280: implemented names

| Offset | Read name | Write name |
|---|---|---|
| 00 | `REG_BOOT_HANDSHAKE` | — |
| 1D | `REG_FDC_STATUS` | — |
| 1F | `REG_FDC_DATA` | `REG_FDC_DATA` |
| E7 | `REG_DMA_PRESET` | `REG_CONTR` |
| ED | `REG_RDGNN` | — |
| EF | — | `REG_VETTN` |
| F6 | — | `REG_ADRLN` |
| F7 | `REG_RD1NT` | — |
| FF | `REG_RD1DN` | `REG_E01NT` |

Manual signal names are retained for documented board registers. Offset 00 is
explicitly an observed ROM handshake, not a documented chip register. The E7
read-side DMA preset association is explicitly marked as inferred from the
resident driver; the manual's VERFN signal listing alone does not establish that
read address. Read/write names must remain distinct at E7 and FF.

DMA window 40–5E and PIT windows 99–9D/9F already dispatch through named chip
methods with explicit address decoding. No change to those windows, byte lanes,
CONTR/RD1NT/RDGNN bits, board ID E1, fixed status bits or DMA timing is included.

## Other M40 code reviewed

- **UC map:** F020–23 keyboard/ACIA overlay; F041 NMI status/acknowledge;
  F011/F019 MASTO clear/set; F0B1 MASTO read; F060–6F lamps; F080–8F arbiter;
  F000 suppression disable; F001 timer vector; F0A0 config read/ACIA-vector
  write; F0C0–C7 PIT; F0E0–E1 console writes. Explicit map addresses paired
  with named handlers already communicate these mappings. Keep them numeric
  rather than replacing the address map with a second table of constants.
- **UC arbiter:** offset groups acknowledge/request/release and VIENO strobes
  are not chip registers. Preserve odd-word I/O handling and all boundaries.
  Historical descriptions of request versus grant readback differ; a naming
  cleanup must not silently settle that behavioral question.
- **L1 bus/RAM:** slot extraction, lane masks, address widths, capacities and
  all-ones open-bus responses are structural values, not register identities.
  Existing interrupt-level enum remains appropriate. No benefit in naming every
  `0xff`, `0xffff` or RAM size.
- **Keyboard:** matrix and Alt-layer tables contain positional scancodes, not
  hardware register offsets. Leave them as tables. Firmware protocol constants
  could be a separate keyboard-owned cleanup, but are not existing chip constants:
  commands 00–10, FA/FB/FC/FD replies, and 6E/76, 6F/77, 70/78 modifier pairs
  must not be conflated with board control bits or host function-key labels.
- **Driver/layout:** BIOS indices, slot positions and UI fields are not register
  constants. No changes. Physical FLOPPY/HD selection stays independent of the
  experimental HD controller branch.

## Verification

Build passed. Automated source comparison expanded each new board constant back
to its numeric value and removed the new declarations: both entire files match
HEAD after whitespace normalization (9 GO252 and 11 GO280 constants). This
checks that only naming changed, including all 23 affected case labels.
`git diff --check` passed, and the existing chip directories have no diff.
Runtime: all 210 keyboard/UI tests passed (`runs-archive/host-keymap.QsidgM/result.log`).
BCOS LOAD-to-RUN reached the password prompt on disposable disks
(`runs-archive/bcos-generated-boot.SegswC/159.png`). Both headless processes exited
successfully. No BASIC or full RAM-suite rerun was performed for this naming-only
change; the prior regression results remain separate.
