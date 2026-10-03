# BCOS K02733: working command prompt

For current user-facing Windows instructions, use
[M40 Windows: configuration through BASIC](../../../installation/BCOS_WINDOWS_BASIC.md).
That guide supersedes historical F8/UI-toggle and pre-reorder drive mappings
in this investigation log. Current BCOS RUN is **PC F12**, TEST is
**left Ctrl+F12**, and the documented UI toggle is **Scroll Lock**.

## Key-operated switches (2026-09-11)

MAME now exposes **Key switch 1/2/3** under **Machine Configuration**,
each with Normal/Left/Right (default Normal). Their K1/K2/K3 positions appear
beside IPL in the status strip. Numbers denote KEYTE1 display order; physical
names remain unknown. No Error setting or host-key aliases are provided.
Restart MAME to use the rebuilt binary; an already-running session does not
acquire these controls. Existing user session/media were not changed.

BCOS accepts their FD/status reports, but all six individual Left/Right
tests still reach ERR.163. These controls are not a verified workaround for
interpreter startup. Details: [switch protocol](../../../keyboard/ANK_key_switch_protocol.md).

## Current MAME drive numbering and IPL panel (2026-09-10)

The rebuilt MAME now provisionally orders its images like BCOS:

| MAME image | BCOS name | Controller unit |
|---|---|---|
| flop1 | FD1 | 1 |
| flop2 | FD2 | 2 |
| flop3 | FD3 | 3 |
| flop4 | FD4 | 0 |

All four connectors are populated by default, keeping these image names stable.
This is a user-facing emulation choice, not proof of the physical select-line
wiring. Controller command decoding is unchanged. Launch scripts use the new
order; boot K02733 with `-flop1`. The interactive launcher mounts only that disk.
Saved states made before this reorder (including A) use the previous device
topology: start fresh. Later state B was saved with the new topology.
The old saved-A replay launcher is disabled by default for this reason.

The default view includes an IPL status strip below the display. Change it via
**Tab → Machine Configuration → Console IPL Switch**: ISL1 is Hard Disk;
ISL2 is Floppy Disk. Enable MAME UI mode with Scroll Lock if needed. The strip
reads the actual switch input; it does not report which media BCOS last accessed
or imply that hard-disk emulation is complete. If using another video view,
select **Screen with IPL selector status** in Video Options. Restart MAME to
load the rebuilt driver/layout.

Headless panel test `runs-archive/ipl-panel.IaBFqA` verifies both switch states and
captures the complete layout as `ipl-floppy.png` and `ipl-hd.png`.

Fresh headless run `runs-archive/bcos-single-fd1.kO9Evf` asserts all four aliases
and reaches the SYS generator at 219 seconds after date and command entry.
This boot-only test did not cover national-keyboard loading. The later user
session and state-B replay below confirm successful USA-ASCII firmware copying.

**Historical evidence below:** floppy aliases in old run descriptions refer to
the pre-reorder binary (flop1=unit0, flop2=unit1), unless explicitly stated otherwise.

## Verified operating sequence

### BCOS drive names and keyboard disk

Six independent unpatched saved-A replays (2026-09-10), using keyboard
disk on flop1 and configurator on flop2, give:

| Input | Result | FDC behavior | Run suffix |
|---|---|---|---|
| FD0 | *ERROR* | no FIFO access | uOPEDh |
| FD1 | K02733; INCOMPATIBLE DISK ON FD1 | selects unit1 | kMa6yt |
| FD2 | MISSING VOLUME LABEL ON FD2 | no FIFO access (saved status blocks read) | Vb2ZWP |
| FD3 | MISSING VOLUME LABEL ON FD3 | RECALIBRATE07 03; ST0=6B, not ready | DkY0sk |
| FD4 | SYS ERR.516 *disk* | RECALIBRATE07 00; READ DATA26 00 ... | oS1tux |
| FD5 | *ERROR* | no FIFO access | kSgTB9 |

Runs are under runs-archive/bcos-label.*. The K02733 volume/owner text is
already present in saved A and remains on rejected/error screens; it does
not mean FD0/2/3/4/5 read that volume. FD1 actually performs label reads.
Each replay clears the saved KE state with keypad*, moves Left once, then
types FDn with Shift and keypad digit/Enter. The batch script that ran
these replays (since removed; it depended on save states from an earlier
build) unset all status-probe and CPU-trace flags. No guest memory patch was used.

Important diagnostic comparison: BCOS FD4 emits selector00, whereas DCOS
6030T6 PU4 emits04. Both address controller unit0, but the diagnostic also
sets HD=1. Their disk failures must not be equated. BCOS's unit3 selection
is now observed directly, not just inferred.

BCOS's national-keyboard prompt accepts **FD1 through FD4**, not FD0.
Earlier instructions calling MAME `flop1` "BCOS FD0" were incorrect:
physical FDC unit numbers and BCOS logical drive names must not be conflated.
The historical test arguments `fd0`/`fd1` below select physical units only.
Saved-state traces verify FD1 selects physical FDC unit 1 (`flop2`),
FD2 selects physical unit 2 (`flop3`), and **FD4 selects physical unit 0
(`flop1`)**. The normal MAME configuration populates units 0 and 1, so its
two drives are FD4 and FD1 for K02733. A third drive is NOT inherently
required. If FD2 is desired, add `-slot4:go280:fdc:2 8dsdd` and use `-flop3`.
This mapping is established for K02733; do not generalize it to other OSes.
The FD4 replay rAOJUG (no status patch) reaches unit0 and issues disk reads,
but stops with `SYS ERR.516 *disk*`. Keyboard-library loading remains
unverified; do not describe correcting the drive name as a complete fix.

Keyboard media: `flop/K02741_BCOS_II_3.3_JJKEYB.imd` in the MAME tree.
On 2026-09-10, a fresh SCP conversion using `disk-analyse -r 360` matched
all 4,004 decoded sectors of this mounted IMD, including geometry and status.
All 154 tracks (cylinders 0–76, both heads) have 26 readable sectors; only
track 0/head 0 uses FM/128-byte sectors, the others MFM/256-byte sectors.
The converter warns about six unidentified tail tracks at cylinders 77–79,
outside the decoded 77-cylinder disk. Both volume labels identify K02741;
the HDR1 extent identifies JJKEYB. This verifies decoded media consistency,
not successful label reads through the emulated controller. The FD2 error
in the two-drive session occurs because it addresses an unpopulated drive,
not because the trace shows a rejected K02741 label. Successful JJKEYB
loading with the corrected drive population remains to be tested.

### Single-disk boot test

Run `bcos-single-fd1.pTYMDm` verifies K02733 **alone in FD1 / MAME flop2**:
date entry succeeds and SYS loads the generator, visible at 219 seconds.
**K02737 is not required to boot or launch SYS.** It may still be requested
later for configuration components; this test does not cover all generation.
The interactive launcher mounts only K02733 in MAME flop2, leaving flop1 empty.

Run `bcos-single-fd0.Q841Zk`, with K02733 alone in physical unit 0 / flop1 and fresh
cfg/NVRAM, reaches `/HALT` and `MOF`, not a usable prompt. The CPU is in BCOS
segment 02 (219-second PC 02:0920), so this is not evidence that the ROM never
read unit 0. Do not claim hardware can never boot unit 0 from this disk's failure.
Explicit ISL2/floppy IPL retest `bcos-single-fd0.sE2kCv` confirms switch bits
00 and produces the same `/HALT` / `MOF` result through 219 seconds.

Reproduce the bounded 220-second headless tests with:

```sh
BCOS_TYPE=$'860909\n' BCOS_COMMAND=$'sys\n' sh scripts/test-m40-bcos-single.sh fd1
BCOS_TYPE=$'860909\n' BCOS_COMMAND=$'sys\n' sh scripts/test-m40-bcos-single.sh fd0
```

Both use a single disposable K02733 image and leave the other floppy empty.

### Interactive sequence

The native MAME keyboard is back to the committed diagnostic-derived
KUSA/QWERTY baseline. The photo-driven replacement was withdrawn. Keycaps may
be customized and do not establish software functions or national layouts.
K02733 currently loads KITA02.1; selecting KUSA inside BCOS remains unresolved.

1. Boot K02733 on **flop1** (BCOS FD1, controller unit 1), with 2048 KB RAM and fresh NVRAM.
   The interactive launcher copies K02733 before running; original media stays untouched.
2. At `DATE YYMMDD`, enter six digits using the **numeric keypad**, followed
   by **keypad Enter**. Tested date: `860909`.
   **Main Enter also completes this BCOS date field**: separately verified
   without aliases in run `wZKNQe` (data read 35). Earlier statements that main
   Enter could not terminate any input incorrectly generalized DCOS behavior.
3. The bottom-line **SYS** prompt already accepts commands. **Do not press Ctrl+J.**
4. Type `SYS`, then keypad Enter. The **SYS BCOS II: Operating System Generator**
   starts and displays its Continue/Exit menu.
5. To exit the generator, type uppercase **E** (Shift+E), release Shift, then
   keypad Enter. BCOS returns to the SYS command prompt.

Headless run `runs-archive/bcos-boot.2xKETx/` verifies date entry, command submission
and program loading: the generator is visible at 159 seconds. This does not
establish completion of system generation or all keyboard editing functions.
Run `runs-archive/bcos-boot.dZFDJG/` additionally verifies Exit back to SYS at
159 seconds. Lowercase e is rejected: use uppercase E for that menu.

## Date-error recovery

### Generated LOAD/RUN boot: SYS ERR.006 fd001

#### Root-cause isolation: direct image replacement misses media change

Fresh-boot comparison on 2026-09-11, same native executable and original-label
image copies, no saved-state restore, RAM patch, or disk relabeling:

| Swap at the RUN prompt | Result |
| --- | --- |
| Eject LOAD, run empty for two emulated seconds, insert RUN | `/SYS` (`bcos-generated-boot.UnOu1f`) |
| Directly replace mounted LOAD with RUN | `SYS ERR.006 fd001` (`bcos-generated-boot.0chSYw`) |

The expected name is copied from the drive record at **00:0BC2**, not a
hard-coded `LOAD` name in the generated configuration. The copy instruction
at **12:0FB8** (write trace PC **12:0FBC**) copies four words, including the
six-byte volume name. On the failing path it copies `LOAD` to **1D:0848** at
113.486684 s. Only the subsequent disk operation refreshes **00:0BC2** to
`RUN` (113.558457 s), then copies that to **1D:08E8** (113.560187 s).
The existing comparison rejects the mismatch. On the successful path the
drive record refreshes after the handoff at about 95.058 s, so the later
request starts with expected `RUN` and succeeds.

The source explains the timing hazard: the 8-inch drive is configured with
`m_motor_always_on`; `floppy_image_device::mon_w(0)` makes it immediately
READY. Direct unload/load can therefore drop and restore READY without
letting the 765 polling timer run between them. The 765 polls at 1.024 ms
intervals rather than latching every READY edge. This is a media-change
emulation issue, not evidence that LOAD and RUN need identical labels.
Repeated FIFO traces confirm C9/C1 notifications for the separated swap
(`NvcHsT`) and neither notification for direct replacement (`1Aif5J`).
No native fix has been applied by this investigation.

**Verified fresh-boot procedure:**

1. Mount original `BCOS_LOAD.imd` in **flop1 / FD1**. Set **Console IPL
   Switch → ISL2 - Floppy Disk** before boot. Do not restore old state C.
2. At `DISMOUNT LOAD-TIME DISK / MOUNT RUN-TIME DISK`, explicitly unload FD1.
   Exit the image menu and let emulation run with the drive empty for at
   least two seconds. Waiting while MAME is paused does not count.
3. Mount original `BCOS_RUN.imd` in the same **flop1 / FD1**, then return to
   emulation. The tested run waits about three seconds before acknowledging.
4. Press **main Return** at `AFTER ANY KEY : GO`. Enter the configured
   uppercase password using **Shift+letters**, followed by **keypad Enter**.
   Enter the six-digit date using **keypad digits**, then **keypad Enter**.
5. `/SYS` is reached with RUN mounted. The relabelled test disk is unnecessary
   for this sequence. Interpreter startup is a separate test.

**CONF2 retest:** from this successful boot's saved `/SYS` state, with
original-label RUN and ISL2, `conf2` + keypad Enter returns
`/SYS ERR.153 CONF2` (`bcos-run-error.53qqPf`). The earlier report of157
was a screenshot-reading mistake: the actual message buffer contains ASCII
`.153 CONF2` at RAM2D29E. The delayed swap resolves006, but CONF2 is absent
from the generated RUN's BC1A33 library. TR00 exhausts its program search,
sets internal001D at35:23C4, and the message table maps it to153.
CONF2 is present as `CONF2 .Y` in **UTS233 on K02737_BCOS_II_3.3.imd**,
not on this RUN. The generation manual says CONF2 updates MODC on the
user's LOAD disk; that identifies the disk it modifies, not proof that its
program is supplied on LOAD or RUN. Launching CONF2 from UTS233 is not yet
tested; do not swap out RUN for LOAD as an attempted remedy.

**Program execution verified:** `pro` + **keypad Enter** from the clean
`/SYS` state launches **BCOS_PRO SUBSYSTEM** and reaches **MODULE NAME :**
using original-label RUN (`bcos-run-error.7qXbZ0`). No companion disk,
relabeling, or RAM override is needed. This verifies PRO startup only.

**BASIC retest on the clean boot:** `basic` + keypad Enter still returns
`SYS ERR.163` (`bcos-run-error.repLQj`). Trace confirms the same TR00
mask0002 check at00:1760, whose word is0000. Resolving media change does
not resolve this interpreter-entry restriction. The newly scanned error
reference (Downloads/000-040-corrected.pdf, PDF35) defines163 as
`"TEST" presetting not active`, action TEST + RUN. **Now verified:** at
`/SYS`, **left Ctrl + F12** toggles TEST with the current host binding
(PC F12 -> ANK F8/5A; the original automated tests used PC F8).
With TEST enabled, `basic` plus
**keypad Enter** reaches `EDIT`. The new status strip displays L2 on.
All rotary switches remain Normal. The ANK1426 BASIC-keyword RUN key
(right Windows /64) is not BCOS's RUN command key. See
[TEST mode and LED evidence](../../../keyboard/BCOS_TEST_mode_and_keyboard_LEDs.md).

**BASIC through PRO (2026-09-14):** clean-state tests reach MODULE NAME:
BASIC and LIBRARY NAME, but BC1A33, blank, and candidate BCO1 each produce
ERR.004. BCO1 is a resident-module name, not a verified library designation.
No tested PRO sequence has launched BASIC yet; its correct library-field
selection remains unresolved. See runs rq2gCh, RHsmZp, and7o3lt4.

**PRGDIR external utility tests (2026-09-14):** K02737 contains PRGDIR's
BASIC executable and OCL parameter-dialog module in UTS233. With RUN on
FD1 and utility copy pre-mounted on FD2, direct PRGDIR gives153 (TPoL3j),
PRO/PRGDIR/UTS233 gives004 (MpHN9a). Inserting FD2 after state restoration
instead changes the latter result to630 FD1 (Tgdegq, verified in RAM).
No successful external launch or copy to RUN yet. PRDKDK is the documented
module-copy utility (Utilities Guide printed2.67-2.71), not a raw-sector
copy; preserve both PRGDIR module types when selecting what to copy.

Reproduce the successful bounded headless test (password of this generated
test configuration is SPAM):

```sh
BCOS_GENERATED_ISL2=1 BCOS_GENERATED_SWAP=1 BCOS_GENERATED_SECONDS=180 \
BCOS_FOLLOWUP=$'SPAM\n' BCOS_FOLLOWUP_AT=100 \
BCOS_COMMAND=$'860909\n' BCOS_COMMAND_AT=110 \
sh scripts/test-m40-generated-boot.sh
```

The launcher copies both disks and uses fresh configuration/NVRAM. Add
`BCOS_GENERATED_DIRECT_SWAP=1` to reproduce the failing control. Detailed
trace provenance and limitations are in `re/os/bcos/BCOS_DEBUG_LEDGER.md`.

#### Tested disk-only workaround (not a root-cause fix)

Historical recovery for an already-failed saved state; prefer the fresh-boot
sequence above.

`flop/BCOS_RUN_LABEL_LOAD_TEST.imd` contains the generated RUN disk's full
contents with only its six-byte VOL1 name changed from RUN to LOAD. Verified
decoded-sector comparison: only C0/H0/S7 label-name bytes differ; all module
and filesystem data are unchanged. The original BCOS_LOAD.imd and BCOS_RUN.imd
were not modified. The copy was made by a one-off script that renamed only
the VOL1 label (since removed from `tools/`).

From saved state C, mount that test image in flop1/FD1, then clear the keyboard
error with keypad* and acknowledge the system error with main F8. Replay
lwW50S reaches `/SYS` with no RAM override. This avoids both006 and the missing
TR00 caused by inserting actual LOAD. If stopped at TR00 C20B, return to C
with MAME Load State (F7, C), then mount the test image before retrying.
This recovery sequence is based on replay of C, not recovery from D in place.

The subsequent `BASIC` command alone returns SYSERR163; it is not evidence of
a working BASIC session. CONF2 alone previously returned SYSERR153 on RUN.
The independent headless replay `runs-archive/bcos-run-error.ZcmwFK/` also
returns SYSERR163 for bare `OCL`, using the relabelled RUN copy without
a RAM override. Neither interpreter entry is a verified next instruction.
The error is now traced to TR00's check of mask 0002 in the word at
00:1760 (keyboard control block 00:1736 +2A). BASIC/OCL are recognized;
the clear bit causes internal error 0026, displayed as 163. The meaning
and initialization of that bit remain unresolved. Main Enter also gives
163 (`gdFwtw`); IBASIC gives 153 (`1x859K`). See the debug ledger for PCs.
Do not give either bare command as a verified next step. Earlier blank
cold-start tests are superseded by the ISL2 fresh-boot comparison above.
The native media-change issue remains unpatched.

**Do not use swapping back to LOAD as a runtime fix.** Although it clears006
and yields `/SYS`, LOAD lacks runtime module TR00. Submitting CONF2 with
LOAD mounted led to flashing TR00 C20B (stateD). The loader explicitly raises
C20B after a failed module-directory search. TR00 is present in RUN's
JJR133 directory, absent from LOAD's JJL133 directory.

The March1983 configuration guide, PDF33–34 / printed2.9–2.10, specifies
that LOAD supplies resident modules during initialization, while RUN must
remain online during normal use for transient modules and system libraries.
The prior advice to run CONF2 while retaining LOAD was incorrect.
Isolated replay0fZNxl using RUN and the diagnostic expected-volume correction
below avoids TR00 C20B, but CONF2 produces SYSERR153 CONF2. Its availability
in this generated system remains unverified; do not suggest it as a tested
next command. No user media or live session was changed by this replay.

User state C (2026-09-10 23:10) reproduces the error after booting generated
LOAD, replacing it with RUN, and entering password/date. These are now
distinct generated images: LOAD contains JJL133; RUN has volume RUN/ownerTP
and contains JJR133 plus BC1A33. Earlier descriptions of RUN as merely an
identical copy describe its initial creation, not its post-generation state.

Read-only retry4zGNxZ: CLEAR49 then F8/5A reproduces006. Reads of controller
unit1 C0/H0 sectors5–8 finish successfully (ST0=01, ST1=ST2=00). BCOS compares
expected volume `LOAD  ` at1D:0848 with actual `RUN   ` at1D:08E8 using
CPSIR at13:4338. Mismatch takes13:4346 and internal condition12, mapped to
displayed006. Thus the reproduced failure is a volume-name mismatch, not a
failed sector read. Its origin was subsequently traced to the old drive
volume record during direct image replacement; see the fresh-boot comparison.

Diagnostic-only replayd7rpKo changes that single six-byte expected-name field
in copied-state RAM to RUN, then retries normally. It reaches `/SYS`.
This is not a production fix or permission to relabel the original disk:
the live session, source state and LOAD/RUN images were not patched.

### First output disk: drive name, volume code and owner

#### Reusable formatted blank (2026-09-14)

The MAME `flop` folder now contains `BCOS_EMPTY.imd` (writable working
blank) and `BCOS_EMPTY_CLEAN.imd` (read-only clean master). Copy the master
to a fresh writable image for each output disk; do not mount the master as
a generation destination. Neither file replaces the existing LOAD/RUN disks.

These are **sector-formatted blanks, not BCOS-initialized volumes**. They
contain no label, directory or ERMAP service records. Generation acceptance
has not yet been tested; the previously successful donor workaround was a
copy of K02741, which retained its BCOS service records. If the generator
rejects this blank, use BCOS initialization or that disposable donor-copy
procedure, not a rename of the blank's host filename.

`tools/make_m40_blank_imd.py` creates the images using K02741's geometry
and sector order, copying no sector data: 77 cylinders, two heads, 26 sectors
per track; cylinder 0/head 0 is 500-kbit/s FM with 128-byte sectors, all
remaining tracks are 500-kbit/s MFM with 256-byte sectors. Every sector is
normal and filled with E5. Readback checks passed for all 154 tracks/4004
sectors, and MAME's `floptool` successfully loaded the IMD and converted it
to a temporary MFI for validation. This does not test BCOS initialization.

The old `BCOS_EMPTY_8DSDD_20260910.mfi` is untouched. Its 32-byte header
describes no tracks or sectors, so the new IMD is a newly formatted blank,
not a faithful conversion of usable contents from that MFI.

The user's Desktop capture `Screenshot 2026-09-10 at 10.55.27 PM.png`
shows the OCS generator requesting removal of the firmware disk and insertion
of the **first output diskette (LOAD-TIME DISK)**, with these fields:

| Field | Displayed value | Meaning |
|---|---|---|
| DRIVE NAME | FD2 | Destination drive; currently MAME flop2, controller unit2 |
| VOLUME CODE | LOAD | BCOS volume name specified for the first output disk |
| OWNER | TP | Owner identifier shown for this generation session |

These names belong to different layers. `FD2` identifies where the disk is
mounted, not its volume name. `LOAD` is the volume code specified by the
BCOS generation workflow, not a name derived from the host filename.
`TP` is the owner field, not part of the drive or image filename. This capture
does not establish whether LOAD/TP were defaulted or entered earlier, nor
whether the new labels have already been written successfully.

The host file used for this attempt is
`flop/BCOS_WORK_COPY_K02741.imd` in the MAME tree. It was made as a byte-for-byte
copy of the formatted K02741 keyboard disk, so initially retains that disk's
labels and files. BCOS can change the contents/volume label during generation
without renaming this `.imd` file. Do not confuse the requested new volume
code LOAD with the source image's original K02741 label. Use only this
disposable copy as output; keep K02733 mounted in FD1.

Subsequently, at the user's request, the working image was renamed to
`flop/BCOS_LOAD.imd` and copied to `flop/BCOS_RUN.imd`. Both files were
173,863 bytes and compared identical at creation. RUN is a copy of the
current LOAD image, not yet a separately generated runtime disk. Renaming
or copying the host files does not change their internal BCOS volume labels.
If the live session still lists the old filename, remount the renamed image
through MAME File Manager before further writes.

The preceding completely unformatted image
`BCOS_EMPTY_8DSDD_20260910.mfi` produced the user-reported
`/SYS ERR.510 fd002`. Its tracks had no sectors. The formatted copy was
provided as the next test; neither the precise meaning of510 nor successful
completion of output generation has yet been verified. "Empty disk" must
not be documented as necessarily meaning an unformatted flux image.

### After USA-ASCII copy: misleading "Press S bar"

State B replay confirms USA-ASCII13 displays "Firmware file copied" after
reading K02741 on FD2. At the following "Press S bar" prompt, **main Enter**
(physical35), not Space or an alias, advances to "Dismount firmware files
diskette". If KE is present, first press keypad* once to clear it.
Verified in disposable replay `runs-archive/bcos-space.HPzRky`; the interactive
session was not altered. Space replay `bcos-space.urGNq2` reproduces KE.

Space correctly arrives as12 and translates to3120 (ASCII20). DRL1 at
12:1AA0 tests R5=0 (zero text capacity), branches to the KE path at1A2E.
The control block at00:1736 has function mask007F0000 at+46; main Enter
translates to608E and its function bit22 is enabled. Thus changing the
physical Space mapping is not justified. The wording/input-mode mismatch
is observed, but its original cause remains unproven. Copying USA firmware
does not establish that the running configurator has switched translation
tables; the captured active table still maps main Enter to608E.

### Generator menu: lowercase c and two separate error states

The Continue/Exit menu requires uppercase C or E. Lowercase c + Enter displays
`*ERROR*`. Its acknowledgement is **main keyboard F8**, not CLEAR.
An invalid key at that acknowledgement prompt causes the additional **KE** state.

Verified recovery on the US PC keyboard:

1. If **KE** is displayed, press **keypad `*` once** to clear its E. If already
   cleared, do not press it again: CLEAR is not enabled in the application wait.
2. Press **main F8**, without Shift, to acknowledge the remaining `*ERROR*`.
3. Hold **main Shift**, press **main C**, then release both.
4. Press **keypad Enter**.

Run `UddofU` reproduced lowercase c, the extra KE from CLEAR, acknowledged KE,
then used F8, Shift+C, keypad Enter. The 199/219-second screens reach **OCS:
SYSTEM ENVIRONMENT CHOICE**. No restart, aliases or emulated memory patches.
The application error wait enables only mask 00800000: DRL1 function 98 maps to
bit23; KITA maps physical 5A (PC F8) to 6198. This differs from the 9E KE reset.

### SYS and date input errors

At SYS, pressing keypad Enter without typing a command reproduces
`SYS ERR.152` (`wZKNQe`). This is distinct from the date-field KE/error-reset
loop below: main Enter already completed the date successfully. Do not press a
second Enter to confirm the SYS prompt; type the command first. Run `0pkW5W`
confirms that simply typing SYS after ERR.152 is ignored until acknowledgement.
Recovery verified in `zOSsDM`: press **keypad `*`**, then main S Y S and
keypad Enter. SYS loads the generator normally; no restart is needed.

After invalid input BCOS deliberately waits for an error-reset event. With the
restored native bindings, **keypad `*` sends 49**, which KITA translates to
**609E**. The error loop at 12:22D8–22E6 waits for low byte 9E. Right Ctrl,
currently labelled RES, sends **51** and does not acknowledge this error.

Existing digits are retained. Run `EeDOUV` successfully used:

`86 → premature keypad Enter → keypad * → 0909 → keypad Enter`

Backspace sends 31, not numeric-field DEL CHAR. The BCOS manual (utility guide,
PDF page 153) describes cursor movement, DEL CHAR, INS CHAR and RESET; do not
assume modern PC text-editor behavior. See [keyboard/ANK1402_KEYMAP.md](../../../keyboard/ANK1402_KEYMAP.md).

## Launch commands

Visible user session, only when wanted:

```sh
scripts/run-m40-bcos-interactive.sh
```

This uses native bindings, with main-row digits and main Enter distinct from
keypad digits and keypad Enter. Convenience aliases were removed at the user's
request. It switches to normal speed at emulated second 90.
The driver's synthetic Ctrl+Enter-to-keypad-Enter shortcut was also removed.
Any non-working-machine warning still needs
acknowledgement; `-skip_gameinfo` does not suppress every warning.

Bounded, headless command-execution test:

```sh
BCOS_KEYPAD=1 BCOS_BOOT_SECONDS=160 \
BCOS_BOOT_SCRIPT=scripts/lua/mame_bcos_state.lua BCOS_KBD_TRACE=1 \
BCOS_TYPE=$'860909\n' BCOS_COMMAND=$'sys\n' \
scripts/boot-m40-bcos.sh
```

The launcher uses disposable media, fresh NVRAM, `SDL_MAC_BACKGROUND_APP=1`,
`-video none -sound none -nomouse`, and a 160-second emulated-time limit.
The observer injects physical matrix input and saves read-only snapshots/traces
in the printed run directory. No emulated RAM/I/O patches or status overrides.

Add `BCOS_FOLLOWUP=$'E\n'` to the environment above to test Exit back to SYS.
The observer generates physical Shift+E followed by unshifted keypad Enter.

## Controlled comparisons

- `8GLYpT`: date, Ctrl+J, SYS, Enter → `SYS ERR.153 JSYS`.
- `2xKETx`: same sequence **without Ctrl+J** → generator starts.
  Ctrl+J contributed J in this configuration; earlier OSLEM Ctrl+J instructions
  must not be applied to this already-working SYS prompt. The precise modifier
  interpretation is not yet established.
- `tIQA8Z`: generator starts, lowercase e + Enter → menu displays e and ERROR.
  Do not report this as a keyboard freeze or successful Exit.

All these tests use the restored native KUSA mapping, except the earlier 49
recovery test which also preceded the withdrawn photo-driven replacement.
