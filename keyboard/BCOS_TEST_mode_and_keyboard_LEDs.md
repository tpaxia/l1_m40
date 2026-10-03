# BCOS TEST mode and keyboard LEDs

Verified 2026-09-14 with generated LOAD/RUN, native M40, all three rotary
key switches Normal. No guest RAM or LED overrides.

## Exact US keyboard sequence

Current host mapping (user-requested swap): PC F12 -> ANK F8/5A,
PC F8 -> ANK `(`/41. Earlier runs below used the old PC F8 mapping.
No duplicate binding or synthetic TEST shortcut was introduced.

At `/SYS`, hold **left Ctrl**, press and release **F12**, then release Ctrl.
This is BCOS's CONTROL + RUN command. **L2 lights**. Type `basic`, followed
by **keypad Enter**: BASIC reaches `EDIT`.

CONTROL + F12 again at `/SYS` clears TEST and extinguishes L2. BASIC then
returns ERR.163. The ANK1426 BASIC-keyword key labelled RUN is a different
key: scancode64, mapped to right Windows. CONTROL + that key did not set
TEST. Do not confuse the fixed physical legend with BCOS's function-key
assignment. No alias or synthetic TEST input was added.

The three rotary contacts are separate inputs. They stayed Normal in all
these tests; changing them is not needed to enable TEST.

## Manual and traced software path

`/Users/paxia/Downloads/000-040-corrected.pdf`:
- PDF35: ERR.163 means `"TEST" presetting not active`.
- PDF40, printed185: CONTROL + RUN activates TEST, LED L2 on.

Native input sends CONTROL make70, F8 positional code5A, CONTROL break78.
BCOS sets low-byte bit02 in logical00:1760 (per-console context00:1736+2A).
The observed write-tap PC is36:01C4 when setting and36:01F6 when clearing.
It sends host keyboard command09 on set, 0A on clear, through port1F02
(observed write PC3B:06C6). The previously traced BASIC check at35:1708
reads this word through13:11D0 and requires mask0002.

Thus the bit and LED are **set by BCOS in response to keys**, not a rotary
switch, a hardware TEST input, or an LED feeding back into the CPU.

## Indicator emulation

The old GO252 HLE ignored indicator commands. `keyboard::command_w` now
receives host commands from GO252 and exposes five real MAME outputs.
The layout shows those outputs; clicking the labels does not set a mode.
Display revision: the visible labels are READY, L1, L2 and SHIFT. The
unverified fifth output is retained internally but hidden. The boot
selector is labelled simply FLOPPY or HD. These changes require a new
MAME process; an already running process retains its compiled layout.
Original physical left Ctrl+F8 did nothing. DYomHu's provider log shows
F8 alone reaches MAME but no F8 event while Ctrl is held. macOS reserves
Ctrl+F8 for status-menu focus (Apple keyboard-shortcut reference102650).
The user chose PC F12 instead; physical delivery with this new binding
still needs their test. Interactive launchers explicitly use Scroll Lock
as UI-toggle key, overriding a conflicting F12 setting in an external INI.
The firmware INIT writes P1=DC, corresponding to all indicators off.

| Output | Firmware pin | On command | Off command | Evidence |
|---|---|---|---|---|
| READY | P1.4, low on | 05 | 06 | KEYTE1 sequence / DCOS prompt behavior |
| L1 | P1.3, low on | 07 | 08 | KEYTE1 sequence |
| L2 | P1.2, low on | 09 | 0A | KEYTE1 sequence and BCOS TEST trace |
| SHIFT | P1.1, high on | 0B | 0C | KEYTE1 sequence and modifier handling |
| LED5, name unverified | P1.0, high on | 0F | 10 | Firmware and diagnostic fifth command pair |

Firmware: M20/PCOS/src/KeyBoard/M40/m40_8049.s, command stubs04C0-04D6,
handlers0500-052C. KEYTE1 seg21:0B24 loops over table3344:
`05 07 09 0B 0F 06 08 0A 0C 10 FF`; helper1184 sends all off commands.
Concise Functional Checks Manual6.4.1 describes READY/L1/L2/SHIFT order
and CONTROL70/78. It does not supply a verified name for the fifth output.

These are host-controlled indicators: SHIFT is not simply wired to the
current host Shift key, and L2 is called TEST here only in the BCOS context.
MAME's output manager saves/restores output values. New outputs change
the saved-state registration; use a fresh boot/state with this build.

## Verified runs

- LkTjzZ (old binary): CONTROL+physical64, then BASIC -> ERR.163, no TEST write.
- DxJlIP (old binary): CONTROL+F8, then BASIC -> EDIT, bit02 set, command09.
- HpSmLA: fresh cold LOAD-to-RUN boot with LED-enabled binary -> `/SYS`.
- wY4bZG: new-state CONTROL+F8 then BASIC -> EDIT, visible L2 on.
- wfNCMz: CONTROL+F8 twice then BASIC -> bit02 set then cleared, commands09/0A,
  visible L2 off and ERR.163.

All are under `runs-archive/`, with `bcos-run-error.` or `bcos-generated-boot.`
prefixes. Disks are disposable copies; user GUI session was not modified.
The temporary chord input is in `re/os/bcos/leftovers/mame_bcos_run_error.lua`, controlled
by BCOS_TEST_RUN_KEY and optional BCOS_TEST_TOGGLE_OFF.

This validates the TEST/LED path, not every aspect of the keyboard HLE.
Scan-mode commands, beeper timing and other firmware behavior remain
outside this LED change. Do not call the entire keyboard firmware fully
emulated on the strength of these results.

## Live KEYTE1 coverage and limitations

`scripts/test-m40-keyte1-leds.sh` runs diagnostic B code013 from a cold boot.
The2048K boot completes about77 seconds, so inputs start at90 seconds.
After the jumper report, a key advances to layout selection; select3 for
ANK1426. KEYTE1 starts TEST1 automatically, not a test-number menu.
Runs0nDyal/aTwrBq/HtqZ4X/6xQxr1 reached the layout/alpha phases. The
observer checks every frame that the actual output values match all LED
commands issued: initialization06,08,0A,0C,10 and prompt05/06 passed.
The full TEST3 animation and complete special-key sequence have NOT passed
in these runs. End/3D did not advance the active alpha test; the44,39,3F
sequence returned to a TEST1 summary, not to the LED test. Do not count
these attempts as a full KEYTE1 pass.
