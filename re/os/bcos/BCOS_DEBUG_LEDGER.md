# BCOS debug instrumentation ledger

> 2026-10-02: the save-state replay scripts named below (`trace-m40-bcos-*.sh`,
> `test-m40-bcos-drive-names.sh`, `run-m40-bcos-test-interactive.sh`,
> `m40-test-interactive-start.lua`) were removed; their states no longer load
> in the current build. The findings are recorded here and in `re/os/bcos/BCOS_BOOT.md`.

User permits temporary debug code provided it is tracked (2026-09-09).

## UC native trace removal (2026-09-15)

The temporary `BCOS_HISTORY` instrumentation in MAME's
`src/devices/bus/olivetti_l1/uc.cpp` and `uc.h` was added to investigate a
corrupted BCOS scheduler queue pointer and the interrupt save/restore of R2.
The initial 256-entry trace (`re/os/bcos/leftovers/bcos-scheduler-history.log` (removed; in tag `re-leftovers-archive`)) showed the bad
R2 restoration at 3B:0F10 and its propagation through 02:101E. Expanding the
ring to 4096 entries was intended to capture the earlier save or overwrite,
not to implement hardware behavior or assume an FDC cause.

It worked as follows:

- `device_start` read an optional output filename from `BCOS_HISTORY`.
- After emulated second 68, `mem_r` recorded instruction-start (IFETCH1)
  snapshots of time, PC, FCW and R0-R15 in a 4096-entry string ring.
- At PC 02:0912 with R2 nonzero, it opened that filename in overwrite mode,
  dumped the ring in chronological order, and stopped recording. It stopped
  even if opening the file failed.
- `physical_word_w` also printed `BCOS_SAVE` records for writes to physical
  02262C and 0227E4, the two saved-R2 locations, from second 68 until the dump.
- It did not perform extra emulated memory transfers or change guest
  registers. It did add host allocation, formatting and file I/O overhead.
  Without the environment variable, tracing was inactive but the ring object
  still existed. Its fields were not saved or reset with emulated state;
  investigations therefore required cold starts.

Tracking originally consisted of `TEMP` comments at the two hooks and a
header comment pointing to this ledger. The older entry below recorded the
trigger, evidence and explicit removal instructions. Nevertheless, the code
remained in the branch: tracking it did not ensure its removal. The September
14 statement below about having no native test loggers was too broad and is
superseded by this audit.

Removal scope: both UC tracing blocks, all four `m_bcos_history*` fields,
the environment lookup and the now-unused `<cstdio>`/`<cstdlib>` includes.
No replacement trace is being installed. The history remains documented here
and recoverable from MAME git history. External research scripts and captured
logs remain outside the MAME driver; ordinary device logging and emulated
diagnostic hardware are not temporary BCOS instrumentation and are retained.

Validation: incremental SDL3 M40 build compiled UC and the M40 driver and
linked successfully. `git diff --check` passed. A source scan of the L1 bus
devices and M40 driver found no remaining `BCOS_HISTORY`, `BCOS_SAVE`,
`m_bcos_history`, `TEMP`, `getenv` or `fopen` matches. The UC diff is solely
37 deleted lines; the earlier GO252 bit-4 removal remains a separate pending
change. No runtime boot test was repeated for this trace-only removal.
Neither change was committed or pushed as part of this cleanup.

## Active

### Windows guide and BASIC program-entry smoke tests (2026-09-14)

MAME branch olivetti_m40 committed/pushed as 0cf819193f12db100ec37c58a1a7d43617b31d8c;
native changes contain no Lua observers, guest RAM probes or test loggers.
Layout regeneration and incremental native build passed; remote HEAD verified.

TEMP additions to re/os/bcos/leftovers/mame_bcos_run_error.lua (removed; in tag `re-leftovers-archive`): support physical keypad digits,
Space and timed Shift for uppercase letters in BCOS_RUN_COMMAND. No guest RAM
or disk content override enabled. Disposable runs FaO6Yn (lowercase) and vIoP54
(uppercase) restore HpSmLA/swap.sta, enable TEST via CONTROL+5A, launch BASIC,
then try 10 PRINT 123 / 20 END / RUN with keypad Enter. Both stop on the first
line at EDIT-ERR.206; no successful program execution. Do not equate the MOS
BASIC manual's OK prompt with this BCOS EDIT environment. User's interactive
MAME was not stopped or manipulated by these tests.

BCOS_WINDOWS_BASIC.md documents the verified endpoint and open program-entry
step. tools/package_bcos_disks.py (since removed) copied archive originals/conversions,
generated LOAD/RUN and blank images with SHA-256 verification and provenance;
different existing destination contents are not overwritten. New blank IMDs
remain sector-formatted only, not BCOS-initialized or generator-verified.

### User-selected F12 host binding (2026-09-14)

Native keyboard.cpp swaps PC F8/F12 assignments: F12 -> ANK F8/5A,
F8 -> ANK `(`/41. No alias, changed guest scancode, or BCOS TEST hack.
Reason: DYomHu raw provider log saw F8 alone, but only Ctrl70/78 during
the requested chord; macOS's documented Ctrl+F8 status-menu shortcut is
the likely interceptor. User explicitly chose F12. Both interactive
launchers specify -uimodekey SCRLOCK to keep F12 free of an external INI's
UI-toggle binding. The read-only logger now labels the matrix bit ANK_F8
and startup instructions say Ctrl+F12. Old runs/logs retain historical names.
Built release64; running session has not been restarted for this change.

### Interactive physical Ctrl/F8 observation (2026-09-14)

scripts/run-m40-bcos-test-interactive.sh now explicitly passes -noui_active
and exports its disposable run directory. scripts/m40-test-interactive-start.lua
logs the CTRL/F8 matrix input bits, guest receive codes70/78/5A/64 and
L2 commands09/0A in test-keys.log. Read-only observation; no key injection,
RAM changes or synthetic LEDs. User reports the physical chord did nothing
in the first session; do not equate the successful field-injection test
with validated host delivery. New session Qc1CgU uses the simplified
FLOPPY/HD and READY/L1/L2/SHIFT layout; previous process had already exited.

### BCOS TEST resolved; native LED outputs added (2026-09-14)

See `keyboard/BCOS_TEST_mode_and_keyboard_LEDs.md` for firmware, manual, command
mapping, exact US host keys and reproducible evidence. Left CONTROL+F8
(70,5A,78) toggles BCOS bit02 at00:1760 and emits09/0A for L2. BASIC
reaches EDIT with TEST on, returns163 with TEST off. No rotary changes.
New build tests wY4bZG (on) and wfNCMz (on/off), fresh boot HpSmLA.

Native edits this turn only: keyboard.cpp/.h expose five host-commanded
LED outputs; go252.cpp forwards commands; m40.lay adds the status-strip
LED row. Prior unrelated native changes preserved, no commit/push.
Built using generated SDL3 mamem40 release64 project; regenerated layout
with scripts/build/complay.py. No CPU or BCOS behavior patch needed.

TEMP replay additions: BCOS_TEST_RUN_KEY sends physical CONTROL+selected
key before command input; BCOS_TEST_TOGGLE_OFF repeats chord. Existing
WATCH1760 verifies guest writes. No output or RAM overrides.
TEMP KEYTE1 harness: scripts/test-m40-keyte1-leds.sh and
scripts/lua/mame_keyte1_leds.lua, copied diagnostic B disk, real timed keys,
host-command/read logs, frame-by-frame assertions of commanded LED values,
screens and saved state every10 seconds after120. Stop time is bounded.
Aa4MAI was invalid due to shell default-string brace parsing (fixed).
LGjbNO sent initial menu keys before the2048K diagnostic boot completed
at77s (fixed by starting keys at90s). 0nDyal reaches layout menu;
aTwrBq reaches TEST1. These are not completed keyboard diagnostic passes.
HtqZ4X tested End/3D in TEST1 (did not advance);6xQxr1 used the physical
44,39,3F sequence and reached a TEST1 summary, not TEST3. Optional
M40_KEYTE_ADVANCE enables these two timed triplets in the temporary Lua.
Live LED assertions passed for all initialization-off commands and READY
on/off. Full TEST3 animation/special-key completion remains unverified.

### PRGDIR external-library launch and copy preparation (2026-09-14)

Disposable headless tests from clean NvcHsT/swap.sta, ISL2, RUN on FD1,
K02737_BCOS_II_3.3.imd copy on FD2; no RAM patches or native changes:
- MpHN9a: `pro\nprgdir\nuts233\n`, 180-frame line gaps, 1800 frames:
  PRO displays PRGDIR / UTS233, then ERR.004 UTS233.
- TPoL3j: direct `prgdir\n`, 900 frames: ERR.153 PRGDIR, verified ASCII
  at after-m_pointer.bin offset 2D29E (screen glyph can resemble 157).
- Tgdegq: PRO/PRGDIR/UTS233 again, but insert utility at frame10 AFTER
  restoration: ERR.630 FD1 (confirmed with strings in after RAM).
  Thus premounted-state tests do not settle external library access.
  Meaning of630 is not yet established; no successful PRGDIR launch.

TEMP harness additions: BCOS_REPLAY_FLOP2 copies an explicitly supplied
utility image to the run directory, mounting only that copy. Optional
BCOS_REPLAY_FLOP2_INSERT inserts it at frame10 after state restoration,
instead of pre-mounting, to distinguish media-state effects. Existing
tests without these options are unchanged. Originals/live session untouched.

Read bcosII.pdf (reverse-scanned Utilities User Guide): printed2.4 says
launch utilities by their library name at /SYS; it does not establish
external-library qualification. PRGDIR printed2.75-2.77 (PDF69-67):
choice1 system / choice2 application library, drive, volume confirmation,
library name (asterisk means first library), confirm, display-on-video Y.
PRDKDK printed2.67-2.71 (PDF81-77) appends selected star-version modules
from an input library to an output library; selectors include extension
and language. UTS233 directory has PRGDIR.Y *BO at36hex and PRGDIR P *OO
at90hex: executable BASIC plus OCL parameter-dialog module. Copying only
the BASIC entry is not the documented complete interactive utility.
No modules have been copied to RUN; external-library launch remains unsolved.

New scanned error reference /Users/paxia/Downloads/000-040-corrected.pdf,
PDF35: ERR.163 = '"TEST" presetting not active', action TEST + RUN.
This supplies the documented meaning missing from earlier BASIC notes;
the physical control/sequence that sets it has not yet been verified.

### BASIC through PRO on clean original-label RUN (2026-09-14)

Three disposable headless replays from NvcHsT/swap.sta, ISL2, no RAM
overrides, original-label RUN. Inputs use physical keypad Enter with180
frames between lines, stop at1800 frames. PRO accepts/display-normalizes
module BASIC, then asks LIBRARY NAME:
- rq2gCh: `pro\nbasic\nbc1a33\n` -> SYS ERR.004 BC1A33.
- RHsmZp: `pro\nbasic\n\n` -> SYS ERR.004.
- 7o3lt4: `pro\nbasic\nbco1\n` -> SYS ERR.004 BCO1.
No trial launches BASIC. BCO1 was only a candidate from configuration;
inspection shows BCO10001 is a resident module header, so calling it a
confirmed logical library name in commentary was incorrect. No correct
PRO library-field syntax/default has been established. These outcomes do
not establish whether PRO bypasses the separate direct-BASIC ERR.163 gate.
All three processes exited normally; live user session and originals
untouched. No new instrumentation or native code changes.

### BASIC after clean delayed-swap boot (2026-09-11)

`bcos-run-error.repLQj`: NvcHsT/swap.sta, original-label RUN copy, ISL2,
`basic` + keypad Enter, 900 frames. Returns `/SYS ERR.163`; BASIC does not
launch. Trace executes35:1708 then35:033A (push0026);13:7C64 has R2=3633,
confirming ASCII163 rather than relying on the screenshot. Physical RAM
13D60 (logical00:1760) remains0000. Same previously identified mask0002
gate as on the relabelled workaround path, now reproduced on a clean
successful boot without any media-label or RAM override. No live-session
changes. Separate headless test exited normally; no new instrumentation.

### PRO executes from original-label RUN (2026-09-11)

PASS `bcos-run-error.7qXbZ0`: copy of clean delayed-swap boot state
NvcHsT/swap.sta, original-label BCOS_RUN.imd copy on FD1, ISL2. Physical
`pro` + keypad Enter launches `BCOS_PRO SUBSYSTEM`, displaying
`MODULE NAME :` and awaiting input. No RAM patch, relabeling, or companion
disk. Bounded900-frame headless replay exited normally; live user session
untouched. This verifies program execution beyond SYS, not execution of a
subsequently selected module. No new instrumentation was added.

### CONF2 after successful separated-swap boot (2026-09-11)

CORRECTION from instruction trace and RAM: the displayed error was misread
as157. It is153. The output message at RAM2D29E is ASCII `.153 CONF2`.
At13:7C2A internal001D is read; shifting left2 produces0074; table entries
12:2C92..2C94 are ASCII31/35/33. Trace13:7C64 has R2=3533. Do not propagate
the previous screenshot-based157 diagnosis.

Cause: TR00 program/library search exhausts its candidates. At35:2336 the
returned status is0010; at35:2376..2384 the current index equals the limit
(both3), setting the exhaustion flag. Index increments to4;35:23AA exits
the loop;35:23C4 pushes001D and35:23CE calls the error reporter35:15CA.
This path does not use the keyboard-control-word check responsible for163.
Generated BC1A33 has21 directory entries (PRO/NPR, print/log/copy/roll,
OCL/LIMO/BASIC/IBASIC and overlays), with no CONF2; generated JJR133 also
has no CONF2 string. Read-only disk scan finds the actual `CONF2 .Y` entry
on K02737 atC21/H0/S2+12hex, within UTS233. Extracted for examination with
m40disk.py to /private/tmp/conf2-UTS233.bin. No executable copied to RUN.
March generation manual printed2.15/2.17, PDF39/41 (June replacementPDF7/9),
says CONF2 updates MODC on the user's LOAD disk; it does not establish that
the CONF2 program itself is on LOAD. Correct next investigation is access
to UTS233's CONF2, not another disk/controller/keyboard patch. Launch from
that library has NOT yet been tested. No new emulator instrumentation or
native changes needed this turn; existing53qqPf trace contained the evidence.

Test `bcos-run-error.53qqPf`: restore a copy of the clean `/SYS` state
`bcos-generated-boot.NvcHsT/swap.sta`, mount an original-label BCOS_RUN.imd
copy, explicitly select ISL2, type `conf2` + physical keypad Enter. Observe
900 frames: final message is `/SYS ERR.153 CONF2`, NOT CONF2 startup.
No CLEAR/F8, RAM patches, or relabelled media used. This is different from
the initially misread157 report above; it agrees with the older ERR153 result.
Initial repeat p0245K was also misread as157, but its fresh config defaulted to
ISL1; 53qqPf confirms the result with the correct ISL2 configuration.
Both headless processes exited normally; user session untouched.

TEMP harness options added: BCOS_REPLAY_STATE_PATH permits a named saved
state outside sta/m40; BCOS_REPLAY_ISL2 sets the real configuration field,
which MAME's saved-state restore does not restore. Reproduce:
`BCOS_REPLAY_STATE_PATH=runs-archive/bcos-generated-boot.NvcHsT/swap.sta BCOS_REPLAY_ISL2=1 BCOS_RUN_COMMAND=$'conf2\n' BCOS_RUN_FRAMES=900 sh scripts/trace-m40-bcos-run.sh`.

### Fresh-boot LOAD/RUN cause isolated (2026-09-11)

PASS `bcos-generated-boot.UnOu1f`: fresh LOAD on flop1, ISL2 selected through
field.user_value=0, eject at 90.010652 s, RUN insert at 92.013576 s, main
Return at 95 s, physical Shift+SPAM/keypad Enter at 100 s, keypad date
860909/Enter at 110 s. `/SYS` at 119 s with original-label RUN mounted.
No guest-memory patches, native changes, prior saved states, or relabeling.

FAIL matched direct-image-replacement control `bcos-generated-boot.0chSYw`:
identical inputs, but no eject at 90 s; drive:load(RUN) directly replaces
LOAD at 92 s. `/SYS ERR.006 fd001` at 119 s, reproducing the original issue.

Data provenance: generic device-status copy at12:0FB8 (LDIR, trace PC0FBC)
uses source00:0BC2. Failing control copies LOAD to1D:0848 at113.48668425;
driver updates00:0BC2 toRUN at113.55845725 (write PC28:049A), copiesRUN to
1D:08E8 at113.56018725. Successful run refreshes the record at95.058416,
and copies RUN to1D:0848 at113.48603625. The request-local expected name is
not a static generated configuration string. Note that1D:0848 is reused
after the successful operation; the final RAM dump need not retain RUN.

Source cause: floppy_8_dsdd has m_motor_always_on=true. Direct replacement
can unload/reload at one emulated instant; mon_w(0) immediately asserts
READY for these drives. upd765_family_device polls READY every1024us only
in command phase with no partial command. Thus a direct replacement can
hide the not-ready interval. The higher-level stale association persists
until a disk operation refreshes it, too late for the current request.
This supersedes the earlier implication that insertion always waits two
index pulses: the always-on motor path can assert READY immediately.
No native fix implemented; explicit separated eject/insert is tested.

Repeated with FDC FIFO I/O tracing during89..96s:
- `bcos-generated-boot.NvcHsT` separated swap: guest reads C9 at90.01187525,
  C1 at92.3476215 (both at3B:1BE4 after command08); reaches `/SYS`.
- `bcos-generated-boot.1Aif5J` direct replacement: no C9/C1 statuses in
  the swap window, first FIFO operation at95.44384325 is a read-data
  command06, not a READY-change acknowledgement; reproduces006.
Thus the missing notification at the original swap is observed, not just
inferred from the later volume comparison. The earlier saved-state-C
eject/reinsert test could deliver notifications but was too late to rebuild
the request-local expected-name snapshot. Both repeated processes exited
normally; no test session left running.

TEMP expanded scripts/test-m40-generated-boot.sh and
scripts/lua/mame_bcos_generated_boot.lua: corrected fresh boot uses default autoboot
delay, bounded120/180s, actual ISL user_value configuration, optional
BCOS_GENERATED_SWAP and BCOS_GENERATED_DIRECT_SWAP, all-memory-space
LOAD/RUN-prefix write taps, snapshots and FDC FIFO trace89..96s. Copies
original disks only. BCOS_FOLLOWUP supplies actual Shift for uppercase;
BCOS_TYPE/BCOS_COMMAND paths do not synthesize Shift for uppercase text.
Initial trials6gqJtj/Yq3fZR stopped at PASSWORD because those paths typed
lowercase; they are not successful login tests. rgRzbm stayed blank with
ISL1; zVBWoF reached the real swap prompt with ISL2 at90/119s. Earlier
69/70s generated-boot probes were too short for this fresh initialization.

### Explicit media-change recovery test (2026-09-11)

Run `runs-archive/bcos-run-error.bac21z`, state C, unmodified-label RUN copy.
Command: `BCOS_MEDIA_SWAP=1 BCOS_RUN_FRAMES=600 BCOS_RUN_KEY='Keypad top-left (49)' BCOS_RUN_RETRY=1 sh scripts/trace-m40-bcos-run.sh`.
Headless, separate process, original images/state and live session untouched.
At frame 10 insert disposable LOAD; frame 70 eject; remain empty for 120
frames (2.108 emulated seconds); frame 190 insert disposable RUN; frame 330
CLEAR, frame 390 F8. No guest RAM patches or native source changes.

Observed actual guest I/O, not just sampled controller flags:
- Eject at 343.468322836; guest issues Sense Interrupt Status (08) and
  reads ST0=C9 at 343.469287, PC=3B:1BE4 (unit 1, READY-change/not-ready).
- RUN insertion at 345.576663363; READY asserted at about 345.91048 after
  two index pulses. Guest issues 08 and reads ST0=C1 at 345.9105975,
  PC=3B:1BE4 (unit 1, READY-change/ready). Board interrupt is observed and
  pending controller status is consumed.
- Expected label at RAM 2D348 remains `LOAD  ` throughout frame sampling
  and in final dump. Final screenshot still shows `/SYS ERR.006 fd001`.

Conclusion: explicit media removal/insertion notifications reach the guest
in this replay, but do not clear this outstanding LOAD-label requirement.
This tests recovery from saved state C, AFTER the original failed handoff;
it does not prove the original swap was notified or identify the origin of
the expected label. Next trace must follow the upper-layer handling / the
creation of the expected-volume request during initialization.

TEMP opt-in instrumentation: `re/os/bcos/leftovers/mame_bcos_media_swap.lua` (removed; in tag `re-leftovers-archive`), called by the
existing replay Lua only with BCOS_MEDIA_SWAP; launcher copies LOAD as well
as RUN. Reads saved controller/drive state each frame and watches the label
without modifying it. CLEAR/F8 delayed 300 frames only in this mode; use
BCOS_RUN_FRAMES=600. An initial sandbox attempt glo19F failed SDL startup;
successful replay required normal macOS SDL access outside the sandbox.

Disk-only workaround runlwW50S uses BCOS_RUN_LABEL_LOAD_TEST.imd from
tools/bcos_volume_test_copy.py (since removed). Only VOL1 name atC0/H0/S7 differs from RUN;
all other decoded bytes verified identical. No RAM probe enabled. StateC,
CLEAR49,F8/5A reaches /SYS; subsequent bare BASIC returns SYSERR163. This is
not an interpreter success or root-cause fix. Native sources/original media
unchanged. Workaround image intentionally preserves RUN modules under LOAD
volume label; do not confuse it with the actual resident LOAD disk.
TEMP scripts/test-m40-generated-boot.sh and scripts/lua/mame_bcos_generated_boot.lua
test fresh cold boot with copies, save screenshots/RAM/MMU/state at69s.
84w5Ju (ISL2) and UBMtyd (defaultISL1) both blank at69s, tiny saved states;
do not claim cold boot fixed. They use no RAM patches. Original session
was started from K02733 then user swapped/reset to generated LOAD.

StateD TR00/C20B diagnosis, runuLImB2: physical saved-state RAM shows pending
module name TR00. Loader code26:0C18 explicitly loads C20B after exhausting
its eight-byte module-directory entry scan;26:0C28 calls the system error
entry00:00C4. This is a deliberate lookup-error report, not proof of a CPU
trap. Extracted JJL133 directory on LOAD (50 header-count) has no TR00 entry;
JJR133 on RUN (25 header-count) has TR00 at entry8 (0030/2600).
March1983 generation manual PDF33–34 / printed2.9–2.10 says LOAD resident
modules are loaded during initialization and RUN stays online for transient
modules. Swapping back to LOAD clears the expected-volume mismatch but is
not a usable runtime solution. The earlier advice to execute CONF2 with LOAD
still mounted was wrong.
Replay0fZNxl: C + diagnostic expected-volume override + RUN + normal
CLEAR49,F8/5A, then conf2/keypadEnter yields SYSERR153 CONF2, not TR00 C20B.
Thus CONF2 availability is not verified and must not be recommended as a
tested next command. Launcher now optionally selects BCOS_REPLAY_STATE and
BCOS_REPLAY_DISK; BCOS_RUN_COMMAND optional ordinary typed keys,600frame
limit when set. No native, original-state or original-media patches.

PASS diagnostic isolationd7rpKo: BCOS_RUN_VOLUME_PROBE=1 changes only six
expected-volume bytes LOAD->RUN in disposable RAM; CLEAR49,F8/5A retry
reaches `/SYS` by frame180. No original disk, saved state, live process or
native emulation changes. This establishes volume mismatch as the immediate
error006 cause, not why startup retained/selected LOAD. Observer and probe
remain TEMP and opt-in; do not treat the RAM override as a fix.

RUN retry confirmed in55HQZQ and focused trace4zGNxZ. CLEAR49 followed by
F8/5A repeats error006. FDC successfully reads C0/H0 sectors5–8 on unit1;
ST0=01/ST1=00/ST2=00. At13:4338 CPSIR compares expected volume LOAD at
1D:0848 (RAM2D348) with returned RUN at1D:08E8 (RAM2D3E8). First word
mismatches; branch13:4346 sets internal condition12, mapped through error
table13:9B46 to displayed006. Investigating origin of expected LOAD; no
claim yet of configuration fault versus stale runtime association.
BCOS_RUN_VOLUME_PROBE is an explicit diagnostic-only RAM override LOAD->RUN
with guard on exact old6bytes, only in disposable replay. Native code and
original disks/states remain untouched. Trace now filters scheduler/ROM/FDU
instruction fetches, covers retryframes90–178, max180000records.

TEMP generated RUN error006 investigation: scripts/trace-m40-bcos-run.sh
copies state C and BCOS_RUN.imd, mounts copy in flop1 and invokes
re/os/bcos/leftovers/mame_bcos_run_error.lua (removed; in tag `re-leftovers-archive`). Read-only RAM/MMU snapshots, KDC/FDC I/O taps,
at most90000 instruction fetch records, exits at180frames. Optional
BCOS_RUN_KEY supplies a normal physical key; default no input. No live
session or guest-memory changes.

User output-disk progression (2026-09-10 22:55 capture): generator displays
first output disk LOAD-TIME DISK, DRIVE NAME FD2, VOLUME CODE LOAD, OWNER TP.
Documented the difference between destination drive, BCOS volume/owner and
host filename in re/os/bcos/BCOS_BOOT.md. No claim yet that LOAD label writes completed.
Unformatted u8dsdd MFI produced reported SYSERR510 fd002; supplied a separate
byte-identical K02741 copy, flop/BCOS_WORK_COPY_K02741.imd, as requested.
Original media unchanged. Exact510 decoding and generation completion remain
unverified; the copy initially contains K02741 files, not an empty filesystem.

Space-prompt results: urGNq2 reproduces physical12 →3120 → DRL1 R5=0 at
12:1AA0 →1A2E keyboard error. HPzRky tests CLEAR49 then mainRETURN35;
35 translates608E, accepted by control mask007F0000, and advances to
"Dismount firmware files diskette". No native fixes or guest-memory patches.
The test key is selectable through BCOS_TEST_KEY; default remains SPACE12.
Initial f7Lxe1 exited before input because seconds_to_run compared against
saved emulated time (~491s); removed that option, retaining frame180 exit.

TEMP space-prompt investigation: scripts/trace-m40-bcos-space.sh copies new
state B and both PPK session media (actual folder bcos-interactive.PPkCmJ),
then runs re/os/bcos/leftovers/mame_bcos_space.lua (removed; in tag `re-leftovers-archive`) headlessly. Captures RAM/MMU/screens, sends
physical CLEAR49 then SPACE12, logs KDC I/O and at most60000 instruction
fetches over150ms. No guest memory patches or interactive-session changes.

2026-09-10 presentation changes: native GO280 connector declaration order is
1,2,3,0, all four default-populated, yielding flop1=FD1 through flop4=FD4.
Controller command decoding is untouched. Boot/interactive/OS/FDU launchers
and harness default updated; old saved-A replay guarded against accidental use
with the new topology. Native m40.cpp also installs m40.lay, a bottom IPL
indicator bound directly to :cpu:uc042:ISL bit02. No new native debug code.
Patch artifacts: re/os/bcos/leftovers/m40-bcos-drive-order.patch (removed; in tag `re-leftovers-archive`) and re/os/bcos/leftovers/m40-ipl-panel.patch (removed; in tag `re-leftovers-archive`).
Read-only alias assertions in re/os/bcos/leftovers/mame_verify_bcos_drive_order.lua (removed; in tag `re-leftovers-archive`) pass for all
four images; fresh run bcos-single-fd1.kO9Evf reaches SYS generator at219s.
Initial assertion failure was a test API error (generic device rather than
image interface), not failed numbering. IPL test re/os/bcos/leftovers/mame_verify_ipl_panel.lua (removed; in tag `re-leftovers-archive`)
temporarily changes only its disposable configuration switch and restores it;
no media or RAM patches. Initial IPL test used an unsupported numeric item
lookup; ipairs also uses that unsupported lookup, so the final test uses
view.items:at(3). Run ipl-panel.IaBFqA passes both state assertions, captures
ipl-floppy.png and ipl-hd.png, restores the switch and exits. Build and shell
syntax checks passed. Historical entries below predate these
native changes and retain their original alias descriptions.

Unpatched six-name BCOS matrix completed: uOPEDh FD0 ERROR/noFIFO;
kMa6yt FD1 unit1/K02733/incompatible; Vb2ZWP FD2 missinglabel/noFIFO;
DkY0sk FD3 unit3/notreadyST0=6B; oS1tux FD4 unit0/SYSERR516;
kSgTB9 FD5 ERROR/noFIFO. All600-frame runs exited normally.
scripts/test-m40-bcos-drive-names.sh unsets status-probe, CPU-trace and
all-I/O options before the six independent copied-state/copied-media runs.
Observer accepts digits0–5; keyboard positions0/5 added for invalid-input
controls. BCOS FD4 uses selector00, diagnostic PU4 uses04: same US bits,
different HD bit, so not the same full command or established failure cause.
Full table in re/os/bcos/BCOS_BOOT.md. No native MAME changes.

Manual wiring audit recorded in re/hardware/go280/FDU_drive_selection_wiring.md. Verified
GO280 J131 SEL0F/1F/2F/3F pins26/28/30/32 and native drive S1–S4 selection.
AM001 section is specifically an FDU999-controller adapter selecting two
drives together; no evidence it belongs in the GO280 path. Missing full
decoder/cable schematics prevent an authoritative hardware truth table.
No native changes or drive renumbering made.

Diagnostic numbering audit: see re/hardware/go280/GO280_FDU_diagnostics.md four-unit table.
PU1/2/3 separately pass compatibility with selectors01/02/03. PU4 sends04
(unit0/head1) and fails an FM read with ST0/ST1/ST2=44/01/00. The observed
wraparound is independently reproduced, but fourth-drive correctness is
NOT settled. No native changes or UI renumbering. All four230s headless
runs exited normally. First instrumentation run i9Ujoi failed due relative
dofile path, corrected to absolute path before these four runs.

FD4 control rAOJUG establishes that flop1 IS accessible as BCOS FD4. No RAM
status probe: normal replay sends RECALIBRATE07 00, gets ST0=20/PCN=00,
then READ DATA26 00 00 00 05 00 1A 0B FF (FM C0/H0/S5,128-byte size).
The controller returns normal status on that read, but the replay later
stops with SYS ERR.516 *disk*. Therefore the earlier assertion that a third
drive is required was premature: default units0/1 correspond to FD4/FD1.
FD2 unit2 remains correct, but not the only possible keyboard source.
This is a separate unresolved disk-access problem after selecting the
correct drive. No change to the live session or native emulation.

FD mapping established from saved A (2026-09-10): snapshot contains KE and
an unwanted leading character; replay keypad * then Left, FDn, keypad Enter.
FD2 replay 4V4C2L reproduces MISSING VOLUME LABEL; FD1 control jYizoW reads
K02733 and then reports INCOMPATIBLE DISK (expected: no JJKEYB on that disk).
FD1 control sends FDC RECALIBRATE bytes 07 01. Unmodified FD2 sends no FDC
commands: status at 0:0B15 (RAM dump offset13115) is08; FDUR 3B:074A/074C
branches to 3B:07BE and returns8800 at07C8 for the subsequent read request.
JCDN returns8305 and the application reports missing label.
Diagnostic-only BCOS_FD_STATUS_PROBE sets that saved RAM byte08->04 after
state load, exclusively in a disposable replay. Run0QngSo then sends
RECALIBRATE 07 02, SENSE INTERRUPT08, receives ST0=6A, PCN=00: physical
unit2 is not ready (and is unpopulated in this configuration). This proves
FD2 selects unit2/flop3, not unit0/flop1. The probe is NOT a fix and remains
opt-in; the live session and disk originals were untouched. Earlier probe
hWloR8 failed its assertion before mutation because state load was pending;
moving it to first frame resolved this timing issue.
CPU trace BBy7Wp covers the failure window; uKrqJX/XwLRIr earlier wider
service traces. Temporary scripts: scripts/trace-m40-bcos-label.sh and
re/os/bcos/leftovers/mame_bcos_fd_label.lua (removed; in tag `re-leftovers-archive`), each successful replay exits after600 frames.
Correct next launch needs -slot4:go280:fdc:2 8dsdd and keyboard on-flop3;
JJKEYB loading with that topology not yet verified. No native MAME fix
is justified by this failure. IPL panel patch remains unapplied.

FD2 label investigation: user confirms FD1 displays K02733, FD0/FD6 reject
as invalid choices, FD2 reports missing volume label. Prepared temporary
re/os/bcos/leftovers/mame_bcos_fd_label.lua (removed; in tag `re-leftovers-archive`): read-only FDC I/O taps, RAM/MMU snapshots, and
physical FDn/keypad-Enter replay, bounded to 600 frames. Not yet executed;
requires a saved state at the drive-name prompt and disposable disk copies.
Live PID44046 has no debugger/console attachment interface. Asked user for
Shift+F7/A save; no restart or modification of the live session performed.

2026-09-10: corrected conflation of physical unit 0/flop1 with BCOS FD0.
Configurator source explicitly validates I"FD1""FD4". User reports FD2
reaches a label error; physical mapping/read path still needs verification.
Read-only lsof confirms PID42428 has K02741 IMD open. Fresh conversion with
disk-analyse -r 360 to /tmp/bcos-keyboard-verify.cl8Ng0/fresh.imd matches all
4,004 decoded sectors (including mode, size and error/deleted status) of
the mounted IMD. No unavailable/error sectors; VOL1 K02741 appears twice,
HDR1 JJKEYB present. Six unidentified tail tracks are cylinders77–79,
outside the 154 decoded tracks. No changes to live mounts or emulation.
Historical FD0/FD1 test names below denote physical units, not BCOS names.

Single-disk results: FD1 pTYMDm passes date and SYS generator launch. FD0 Q841Zk
fails at /HALT MOF; explicit ISL2 FD0 sE2kCv confirms bits00 and same failure.
Both failing cases have PC02:0920 at 219s: BCOS code loaded, not a proved ROM
inability to read FD0. All three bounded tests exited normally, no user mount
changes. K02737 is unnecessary for the verified FD1 boot/SYS launch path.

Single-medium probes use scripts/test-m40-bcos-single.sh: only disposable
K02733, either -flop1 (FD0) or -flop2 (FD1), 2048 KB, fresh cfg/NVRAM,
220-second headless limit, normal physical date and SYS input. No companion
image, no edits to native emulation, no changes to the user's running mounts.

PASS `UddofU`: c+Enter, CLEAR (creates KE at application wait), CLEAR (ack KE),
F8 (5A), Shift+C, keypad Enter reaches OCS SYSTEM ENVIRONMENT CHOICE at 199/219.
Confirms separate KE reset (49/9E) and application error acknowledgement
(5A/98). No native changes. All bounded tests exited; visible PID31867 untouched.

`ucmGG9` read-only instruction trace at late key 13 (lowercase c submission)
shows the application error starts a zero-length DRL1 input (R5=0), not a
retry of the editable field. Saved keyboard request 0:1736 +46 contains
00800000: only function bit 23. Corrected table indexing: entry 98 at
12:23B0 contains 1B34 8717 (bit23); entry 97 at 23AC is disabled 0000 000F.
KITA maps physical 5A to 6198, native host F8. The initially tested Scroll Lock
(54 -> 6097) was an off-by-one table interpretation and failed in 4RtrqU.
This separates application acknowledgement from the CLEAR/9E KE reset loop.
Observer supports BCOS_ERROR_KEY to select trace trigger, `<` for Left 4A,
and `@` for LIST 54, `#` for F8 5A; these are test tokens, not host aliases.

Generator lowercase-choice investigation: `WHthWi` c+Enter,CLEAR,C+Enter
fails; `hlNdBr`/longer `uqwpJB` with two CLEARs also fails (159-second blank
capture was not progress: 219 shows original c and KE/ERROR). `q7F0wv` adds
Left after one CLEAR and still fails. Withdraw the interim claim that two
CLEARs alone clear the field. `bpMVG5` clean physical Shift+C + keypad Enter
does reach OCS SYSTEM ENVIRONMENT CHOICE at 219 seconds. No native changes.

ERR.152 recovery comparison: `0pkW5W` ignored SYS after submitting an empty
command; `zOSsDM` first sent physical 49, then SYS + 61, and loaded the generator.
Main Enter 35 had successfully completed the date in both runs. No native
changes, aliases, RAM writes or interference with the user's visible session.

`wZKNQe` reproduces user report on alias-free build: keypad date, main Enter
(35) reaches SYS; keypad Enter (61) on the empty command line yields ERR.152.
Observer BCOS_TYPE tab escape now explicitly selects physical main Return;
it is a test token, not a host remapping. Visible user session left untouched.

User-requested alias removal: interactive startup script no longer changes any
input sequences. Native keyboard.cpp no longer conditionally redirects Ctrl+Enter
to keypad 61: main Return is always 35, keypad Enter always 61. No MCU scan-code
changes. Rebuild required; native change is uncommitted. Prior interactive
PID 31644 was terminated to replace its in-memory remapped inputs with a fresh
session/config directory; its disposable disks remain available in ehaYCn.

PASS `dZFDJG`: restored native KUSA mapping, date accepted, SYS command loads
generator, physical Shift+E (6E,08,76) and keypad Enter (61) exits back to SYS.
The 159-second capture shows the command prompt. Bounded run exited normally.
MAME source worktree is clean; only external test-script/document changes remain.

External observer now supports BCOS_COMMAND at second 130 and BCOS_FOLLOWUP
at second 145. Follow-up uses explicit modifier-down/key-down/key-up/modifier-up
phases for uppercase letters. Physical matrix inputs only, no CPU memory writes.
`taWhMS` is invalid as a submitted-date test: selected inactive conditional
keypad Enter field. Corrected selection back to exact `Keypad ENTER (61)`.
`8GLYpT`: Ctrl+J then SYS produces ERR.153 JSYS; `2xKETx` without Ctrl+J
loads the generator. `tIQA8Z`: lowercase e rejected by generator menu.

2026-09-10 mapping correction: withdrew only the uncommitted photo-derived
keyboard.cpp replacement, restoring committed KUSA inputs. Rebuilding before
further BCOS tests. Keycaps are not authoritative software-function assignments.
Physical 49 recovery succeeded in EeDOUV; error loop awaits translated 9E.
BCOS_TYPE `!` means physical 49, not an exclamation character. Letter support
added to the external observer for command-prompt tests; no emulated RAM writes.

- `scripts/m40-uc-alias-test.lua`, launched with `scripts/test-m40-uc.sh aliases`:
  isolated test writes each VIENO alias and verifies all read aliases plus the
  actual gate latch. Restores original gate state, then exits. Not loaded by BCOS.
  Also uses isolated pending-source fixtures to check CPU VI pin gating: masked
  FDU requests survive, re-enabling delivers them, and GO252 level 1b is unmasked.
  Fixture state and CPU pending-request state are restored before exit.
- `scripts/test-m40-uc.sh`: bounded UC3003 run on a disposable disk-A copy with
  timed keys and a screenshot, no native tracing.

- `scripts/lua/mame_bcos_state.lua`: opt-in, read-only RAM/MMU/device saved-item snapshots
  at 70, 74 and 90 seconds, with CPU registers and screenshots. No emulated memory
  accesses, memory taps, or MAME source changes. Remove the `-autoboot_script`
  argument to disable it. Normal `scripts/boot-m40-bcos.sh` does not load it.
  Initial run: `runs-archive/bcos-state.Zezct8/`, bounded to 92 emulated seconds,
  fresh NVRAM, disposable K02733/K02737 images, 2048 KB, background-only SDL.
  Limitation: GO252 `device.items` is empty in this build; do not interpret that
  as an empty keyboard FIFO. RAM, MMU, UC and GO280 captures are present.
  Extended captures at 110/119 seconds; optional `BCOS_CTRL_J_AT` sends only a
  physical matrix chord (no emulated I/O writes). `BCOS_BOOT_SCRIPT` selects this
  script in the normal launcher; without that option it remains inactive.
  Optional `BCOS_KBD_TRACE=1` installs observation-only GO252 I/O taps, capped
  at 512 startup and 128 late events, no recursive emulated memory reads.
  Uses frame scheduling rather than coroutine waits. Output: keyboard.log.

## Native MAME changes in this investigation

TEMP external `BCOS_ERROR_TRACE=1` plus keyboard trace records program reads
matching current PC for 25 ms after the third late keyboard read, at most 20,000
register records. Output date-error-trace.log; no emulated reads/writes from
callbacks. Intended sequence 86 + keypad ENTER. Remove block and trigger state
after locating the date-error recovery defect. No native source changes yet.

2026-09-10 date-error regression (no native changes): physical-key observer now
supports BS (31) as BCOS_TYPE backspace. `zUTTxh`: 86 + BS leaves DATE 86MMDD;
`5XcPxf`: 86 + keypad ENTER leaves no SYS prompt. Follow-ups `tblIOI`
(86, BS, 0909, ENTER) and `H95X33` (86, ENTER, 860909, ENTER) fail to update
the date/advance, despite the I/O trace consuming all subsequent key bytes.
Thus successful clean date entry did not establish editing/error-path correctness.
TEMP external `BCOS_KBD_EVENTS=1` installs a read-only program-space tap at
selected 1KYB entry/error/return addresses, after 99 seconds, capped at 256
register records. It performs no emulated reads/writes in the callback. Output
keyboard-events.log. Remove the optional block once the event-path fault is found.
The user's visible MAME session is left running and untouched by these repros.
`jYMy1D` event trace further confirms 1KYB is still executing after the failure:
subsequent 8/6/0/9/0/9/ENTER become 2438/2436/2530/2439/2530/2439/6088 at
25:022C, and the queued read path 25:004C runs after each. This narrows the
failure beyond interrupt delivery and scancode translation, toward the date
consumer/error-recovery path. No native fix made on this evidence. All bounded
reproduction processes exited; interactive PID 2532 was not stopped.

REMOVED external experiment in `mame_bcos_state.lua`: `BCOS_KBD_RDRF=1`, together
with `BCOS_KBD_TRACE=1`, changes GO252 status bit 2 to bit 0 when control bit 7
is enabled. No native changes. Default remains read-only. IKYB at segment 01
0098 tests status bit 2 and jumps to restart; 1KYB callback 25:0362 only clears
TX-ready bit 1. Model status 06 thus propagates 04 instead of a normal received
byte indication. Test causal effect without claiming hardware semantics yet.
Keyboard logs now include R0 at I/O to expose the status delivered to callbacks.
Experiment `bcos-boot.u6UnMZ` reaches the BCOS banner and DATE YYMMDD prompt
at 119 seconds. Trace shows 01/FA -> 02/FB/F1 -> 0C/10 -> 04/0D, not retries.
Native GO252 correction now reports RDRF bit 0 for RX-interrupt mode (control
bit 7), preserving the old bit-4-only path pending broader validation. No new
native debug code. Verify without BCOS_KBD_RDRF before claiming native success.
Optional BCOS_TYPE and BCOS_TYPE_AT inject physical top-row digits and alpha
RETURN for prompt testing; only use disposable media. Additional captures at
139/159 seconds support bounded 160-second runs.
Native `bcos-boot.YBNr8r` reaches DATE without override, but digits/RETURN cause
0D responses and no acceptance. REMOVED BCOS_KBD_IRQ_STATUS added status bit 7 on
RDRF reads in receive-interrupt mode. 1KYB 25:017A compares RH0=01 as completion;
status 03 reduced by callback to 01 collides with that event. Normal receive
with IRQ flag (83 -> 81) bypasses it, then the 70 mask removes non-data flags.
Validate causally before retaining IRQ-status behavior.
`bcos-boot.U8Zfwg`: IRQ-status experiment with keypad 860909 and keypad ENTER
accepts the date and reaches SYS prompt at 119 seconds. Both external override
branches and environment switches have now been removed. Native GO252 returns
83 (IRQ + TX ready + RDRF) for pending input with control bit 7; other modes
remain unchanged. Native-only confirmation follows. Earlier top-row/alpha
RETURN attempts used the wrong keys for this disk's KITA table.
CONFIRMED native-only `bcos-boot.rcwPJZ`: DATE at 90 s, keypad date accepted,
SYS prompt at 119/159 s. No overrides remain; no Ctrl+J or emulated I/O writes
from the observer. MAME exits normally at 160 s. Final-build FDU regression
`fdu-validation.BbcTuR` reaches speed test 6 without displayed errors. UC run
`uc-validation.fKZKhW` (RDRF fix before addition of IRQ status) advances through
tests 1–6 and retains the known test-7 ROM fault. Only native change since pushed
commit d45e8448447 is the GO252 receive status fix; not committed or pushed yet.

- REMOVED `go252.cpp/go252.h` latency experiment (`BCOS_KBD_REPLY_US`).
  Run `runs-archive/bcos-boot.CnGP8m/` delayed command 01's FA reply by 1000 us.
  Replies were consumed about 1030 us after the command, but initialization
  retries, received Ctrl+J bytes and the blank/MOF screen at 119 seconds were
  unchanged. This does not establish the correct serial timing; it gives no
  reason to retain this particular workaround. Callback, timer, environment
  branch and extra include removed; original synchronous reply restored.

- REMOVED 2026-09-15: `uc.cpp` / `uc.h` TEMP-marked `BCOS_HISTORY` probe
  (historical description follows). An opt-in 4096-entry
  instruction/register ring starts at emulated second 68 and dumps once when
  PC=02:0912 with R2 != 0. Output path comes from `BCOS_HISTORY`; unset means
  disabled. No emulated bus reads or writes. Remove the TEMP block in `mem_r`,
  its four `m_bcos_history*` fields, getenv initialization and extra C includes
  after locating the corruption. Not included in save states; use cold starts.
  Also logs CPU writes to physical 02262C and 0227E4 (the two saved R2 words)
  after second 68 via a TEMP block in `physical_word_w`; remove that block too.
  Initial 256-entry trace: `re/os/bcos/leftovers/bcos-scheduler-history.log` (removed; in tag `re-leftovers-archive`) identifies bad R2
  restoration at 3B:0F10, propagated through 02:101E. Extended ring is to capture
  the earlier save/overwrite, not to assume another nested FDC cause.
  Write logging now stops when the corruption snapshot is captured.

## Functional correction under test

2026-09-09 second NV-mask candidate: UC arbiter uses a 16-bit handler to decode
one strobe per I/O cycle. Z8000 exposes the original I/O address before word
alignment; UC uses bit 0 for word strobes, lane mask for byte strobes. This
addresses the previous candidate's ROM stall at 0300: word OUT FF87 had called
both FF86 and FF87, masking NV3 as well as NV4. ROM 02F6 requests NV3 and
02FA masks NV4, expecting the NV3 interrupt. NV2-NV4 enable latches and pending
request readback are separate; the previous idle-status behavior is preserved.
Source changes: z8000.cpp/h and uc.cpp/h. No PC-specific or disk-specific logic.
Retained after validation: `uc-validation.5Gyur8` advances through UC3003 tests
1–6, stopping at test 7 ROM bank/size fault. `bcos-boot.rE0oFn` completes ROM
startup and reaches BCOS with R2=0/R3=12F8 at 119 seconds; Ctrl+J bytes consumed,
no configurator prompt. Focused aliases test now also passes NV2–NV4 re-masking,
pending readback, cancellation of delayed IRQ, unmask delivery and acknowledge.
This is functional code, not a new native debug probe.
Final-build FDU regression `fdu-validation.zvvPkY`: communication, timer,
interrupt, DMA and compatibility tests advance to speed test 6 with no reported
fault; measured 166.65–166.66 ms. Tests 7–13 were not covered. Build and both
worktree whitespace checks pass; all bounded test processes exited.

REVERTED NV2-NV4 mask candidate: `uc.cpp/uc.h` replaced monotonic release
level with three enable latches. F085-F087 clear them, F08D-F08F set them;
NV1 remains unmasked. Readback distinguishes requests from enabled requests.
No-pending arbitration cancels the delayed NVI assertion and clears its line.
Evidence: UC3003 loaded segment 21, 4650-469A checks 0F with all enabled/no
requests, then F8 with all requested/NV2-NV4 masked. 46E0-471A requires NV2
to remain pending without delivery until FF8D; subsequent blocks repeat for
NV3/NV4. Independent-latch interpretation remains subject to regression and
does not establish all priority combinations or exact MB15652 timing.
Candidate regressed ROM startup: `bcos-boot.JYaQ31` remains at PC 000300,
with no BCOS keyboard initialization, and `uc-validation.Jy7VVY` does not load
the diagnostic. Reverted the entire candidate (including readback and timer
cancellation), preserving the previously validated alias/VIENO changes.
Reconcile ROM reset/status expectations before retrying; see `re/hardware/uc/UC3003_NVI.md`.
After reversion, rebuild and both focused alias/level-2 gate tests pass.
Restored-baseline BCOS run: `runs-archive/bcos-boot.oT9AsS/`, 120 seconds, no
latency environment variable, observer and Ctrl+J at 95 seconds. Process exits
normally; retain this capture separately from the rejected candidate run.

Additional level-2 gate correction: `l1.cpp/l1.h`, `uc.h`. The CPU exposes
`vi_enabled(level)`; the bus filters both pending and acknowledge by that gate.
VIENO masks every level-2 source, retaining pending state, not level 1a/1b.
Primary manual: Concise Functional Checks Manual 4102230 T(0), §3.1.1 test 2,
printed p. 3-1 explicitly identifies VIENO as level-2 vectored interrupt.
After the alias-only change, `re/os/bcos/leftovers/bcos-post-alias-history.log` (removed; in tag `re-leftovers-archive`) catches FDU
re-entry at 85.2034115 s (3B:1AAE -> 3B:0D28) despite VIENO being masked.
The earlier timer-only interpretation of VIENO was incomplete.

Regression evidence before the level-2 correction: the exhaustive 16x16 alias
test passes; UC3003 `runs-archive/uc-validation.dQEC8W/` advances through VIENO,
all three timer counters and ACIA, stopping at test 5 NV2 INTERRUPT MASK FAULT.
This is not an all-tests pass. A shell default-expression issue appended stray
keys after execution had started; fixed in `scripts/test-m40-uc.sh` before rerun.

UC `io_map` now mirrors its register mappings across bits 11-8 (`0x0f00`).
This is separate from TEMP instrumentation. The 4096-entry trace shows a timer
vector 04 entering at 3B:0314 during the floppy vector-08 handler, after BCOS
wrote F084 at 3B:0D50. The previous map only accepted FF84, so VIENO remained
enabled. Both handlers save at 00:0028, and the timer saves the floppy handler's
working R2=2000 over the scheduler's R2=0000. The FDU returns the bad value.
BCOS also uses F08C on exit; both alias the documented UC gate strobes.

Manual evidence: 3963590 R(2), section 3.1, printed page 3-1 (PDF page 12),
diagram labels bits 11-8 NON UTILIZZATI. Scope caveat: this is the governo
selection chapter, not a UC042 gate-level schematic. BCOS's paired F084/F08C
and FF84/FF8C usage independently supports applying the same aliases to UC.

First corrected run: `runs-archive/bcos-boot.NifpkN/`, 100 seconds. At 99 seconds
the old environment page has cleared; screen is blank except bottom-right MOF.
This is changed startup behavior, not a claimed interactive configurator boot.

## 2026-09-11: next-command verification on generated RUN

Follow-up trace analysis of ZcmwFK identifies the exact ERR.163 path:

- Loaded segment 35 is TR00 (RAM 1EDC00 begins `TR000001`).
- Its interpreter-name table at 12:3F28 includes BASIC, OCL and LIMO.
  The successful name comparison takes 35:0232 -> 35:0326.
- 35:1708 checks 12:403C (nonzero), then calls 13:11D0 through its
  import stub. That routine reads the word at +2A of the object pointed
  to by 12:4044. In this replay the pointer is 00:1736, and the word at
  00:1760 is zero. The object has previously been identified as the
  keyboard request/control block; this is NOT enough to call the word
  a privilege flag or to infer a password failure.
- TR00 tests mask 0002 in this word. With the bit clear, 35:033A pushes
  internal error 0026 and calls its reporter at 35:15CA.
- The SYS display routine at 13:7C2A reads 0026, multiplies it by four,
  and fetches ASCII `163` at 12:2CB6..2CB8. This establishes the mapping
  without guessing decimal/hex encoding of the displayed error.
- Main Enter versus keypad Enter is NOT the immediate fix: replay
  `gdFwtw` submits BASIC with physical RETURN (35), still yielding ERR.163.
- `1x859K` submits IBASIC with keypad Enter and yields ERR.153. It is not
  a verified alternative launch command.

Temporary harness change: `BCOS_RUN_ENTER` selects the native input field
for command submission, defaulting to the existing Keypad ENTER (61).
No native emulation changes, flag overrides, or live-session changes.
Remaining investigation: determine the meaning and origin of bit 0002
in this keyboard control block, including its initialization before state C.

Read-only saved-state replay with a disposable copy of
`BCOS_RUN_LABEL_LOAD_TEST.imd`, CLEAR then F8, followed by `ocl` and
keypad Enter: `runs-archive/bcos-run-error.ZcmwFK/after.png` shows SYS ERR.163.
No RAM override, native-code edits, or changes to the live user session.
This matches the previous bare BASIC result, but the meaning of 163 and
the correct interpreter invocation remain unverified. The MOS BASIC guide
describes entering BASIC from MOS SHELL; that is not proof of BCOS syntax.

## 2026-09-11: native key switches and status strip

Added real Normal/Left/Right configuration inputs to keyboard.cpp/.h,
FD/status reports to the keyboard callback, non-default startup reporting
after GO252 command 00, and K1/K2/K3 indicators in m40.lay. Default contacts
are FF; firmware SAVED0 starts FF, hence no all-Normal startup report.
Existing unrelated native modifications are preserved. No commits/push.

Temporary replay extensions: BCOS_RUN_SWITCHES sets configuration fields
via Lua field.user_value at frame 190; BCOS_RUN_FRAMES optionally extends
the bounded run. No BCOS memory override used. QrBoDD was an invalid harness
trial (nonexistent user_settings property), corrected before tests below.
All six individual position reports delivered; none clears ERR.163. See
keyboard/ANK_key_switch_protocol.md for runs, report encodings and BCOS receive PCs.
The initial impression that K3 Right's blank screen was BASIC startup was
explicitly disproved by the error-formatting trace and corrected.

## Initial finding

### 2026-09-11 flag provenance follow-up

Added temporary read-only watches in mame_bcos_run_error.lua
(`BCOS_WATCH_1760`) and mame_bcos_flag_origin.lua (cold boot through the
existing mame_bcos_state.lua input harness). Watch logical aliases by MMU
translation in program, data and stack spaces. First trials eoNRE5 and
7o3SkA covered program space only and cannot support a no-write conclusion.
Corrected replay T7b4Mn covers all memory spaces and reports no writes to
physical 23D60 during CLEAR/F8/BASIC. Corrected fresh K02733 boot 1JMCPm
captures one initialization write: time 72.442468, data space 00:1760,
value 0000, mask FFFF, PC 03:0996. No subsequent writes through 219 seconds.
This establishes observed zero initialization, not the semantic name of bit 1.

Static setter candidate at 12:1FA6..2004 (RAM 1DEA6..1DF04): reads old
flags from rr12+2A, replaces the low byte from an argument, then explicitly
restores old bits 0 and 1 before storing at 12:1FEE. It cannot enable the
missing bit if it was clear. Routine 12:1C4C..1D06 also prepares a result
pointer to a request block +2A; its relation to the missing status update
still needs a complete caller/driver trace. Do not claim full provenance.

Bounded runtime-library PRO tests (all on disk copies, all Normal switches,
no RAM overrides): N6aStj opens BCOS_PRO SUBSYSTEM / MODULE NAME; rBZtba
accepts BASIC and prompts LIBRARY NAME; rn5kP6 blank library gives ERR.004;
KTeasJ explicit BC1A33 also gives ERR.004 BC1A33. No flag writes in these
replays. PRO is a verified working command, not a verified BASIC launch.
Harness adds optional BCOS_RUN_LINE_GAP and keypad digits 1/3 to support
these multi-prompt trials. No new native MAME edits in this investigation.

At 74 seconds rr2=0000:12F8, the scheduler semaphore. At 90 seconds
rr2=2000:12F8 while execution remains in 02:0912..0920. Queue entries at
00:12FC and 00:1304 are nonempty. This is not sufficient evidence of a healthy
idle scheduler: determine how R2 changes before diagnosing a keyboard wait.
