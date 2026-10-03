# M40 keyboard

Everything specific to the Olivetti L1 M40 ANK keyboard: how it works, how
MAME maps a PC keyboard onto it, the generated key maps, and photographs.

## Start here

| Document | What it covers |
|---|---|
| [maps/README.md](maps/README.md) | The user-facing key maps: US PC keyboard to M40 ANK, and the ESE overlay |
| [KEYMAP.md](KEYMAP.md) | The official L1 MOS PC-keyboard mapping (from the L1WSE emulator manual) and how the MAME bindings follow it |
| [ANK1402_KEYMAP.md](ANK1402_KEYMAP.md) | ANK1402 scancodes correlated with photographs, and the US PC bindings |

## How the keyboard works

| Document | What it covers |
|---|---|
| [M40_8049_KEYBOARD.md](M40_8049_KEYBOARD.md) | The keyboard's 8049 firmware: commands, replies, scanning, LEDs. The ROM image is `../reference/roms/80491402.MCU`; its annotated source is `PCOS/src/KeyBoard/M40/` in the separate M20 project |
| [GO252_keyboard_reverse_engineering.md](GO252_keyboard_reverse_engineering.md) | The keyboard port on the GO252 video/keyboard board, from the ROM and diagnostics |
| [GO252_keyboard_scancodes.md](GO252_keyboard_scancodes.md) | The full scancode map |
| [ANK_key_switch_protocol.md](ANK_key_switch_protocol.md) | The three key-operated switches: firmware behaviour and the KEYTE1 diagnostic |
| [BCOS_TEST_mode_and_keyboard_LEDs.md](BCOS_TEST_mode_and_keyboard_LEDs.md) | BCOS TEST mode and the keyboard LEDs |
| [M40_KEYMAP_20260914.md](M40_KEYMAP_20260914.md) | Host keyboard verification run of 14 September 2026 |

The GO252 board as a whole (video and keyboard port) is described in
`../doc/KDC.md`; the keyboard-port reset fix in MAME is recorded in
`../re/evidence/go252-kdc-master-reset-evidence.md`.

## Other material

- `L1WSE_KEYS.pdf`: scan of the L1WSE manual's keyboard pages (7-14 to 7-16),
  the source of the official mapping in `KEYMAP.md`.
- `maps/`: the SVG and PNG key maps and `generate-m40-ank-maps.py`, which
  regenerates them from `keyboard-101-template.svg`.
- `photos/`: the ANK1402, ANK1426 and ANK1427 keyboards, and the KEYTE1
  scancode grids (`SCANCODES_ALPHA.png`, `SCANCODES_NUMERIC.png`).

## Tests

`../scripts/test-m40-host-keymap.sh` checks the PC-to-M40 key mapping (218
cases); `../scripts/test-m40-keyte1-leds.sh` runs the KEYTE1 diagnostic. See
`../scripts/README.md`.
