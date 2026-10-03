# Scroll Lock reservation — 2026-09-14

User requested Scroll Lock remain free for Windows and agreed to an explicit
UI toggle setting on macOS. No global MAME defaults were changed.

- Existing interactive BCOS scripts already pass `-uimodekey SCRLOCK`.
- Added the option to all three Windows launch commands in the published
  `mame_disks/BCOS/BCOS_WINDOWS_BASIC.md` guide.
- Added `installation/M40_UI_CONTROLS.md` with both-platform instructions.
- Extended the temporary host-keymap harness to assert the effective UI toggle
  is exactly `KEYCODE_SCRLOCK`; its matrix checks reject guest Scroll Lock.
- Test run `runs-archive/host-keymap.jQp5oU`: UI assertion passed, all 202 input
  cases passed. Headless macOS, isolated configuration, no disk attached.
  The harness injects logical fields and consumes emulated keyboard I/O;
  this is not a physical Windows key-delivery test.

Native Alt-layer/LOCK changes in keyboard.cpp and keyboard.h remain pending
from the keyboard task. No additional native edits were needed for this UI
reservation. The existing interactive session was not restarted.
