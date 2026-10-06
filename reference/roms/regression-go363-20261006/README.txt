M40 published-media regression — 2026-10-06

Scope: software described in ~/Projects/mame_disks/m40/README.md.
MAME branch m40_z8010_sup_test, commit 8b508304acb9c9e04e50910d6edf0aba40bb1944.
Executable SHA256: 7a690f08b56593e1b2daa9c4fde1dbef06a978282fd6fd1b9539e7d444e56ff9.
The external tree was not edited. Its existing three-file diff is mame.diff.
Media source hashes and executable identity are in manifest.json.

Configuration: UC042, 2 MB RAM, fresh configuration and NVRAM per run,
stock ROM 6.0 for floppy systems, published hacked hd65 ROM for HD systems.
Every floppy run also has GO363 in slot5 and a disposable MOS HD attached;
floppy IPL is selected explicitly. HD runs select HD IPL. All media are copies.
The experimental common-register model is supplied by probe.lua: low-byte
reads at GO363 F9/FB return zero. The A.5 UC timer experiment also runs unless
CLEAR_TIMER=0: pending UC timer interrupts are cleared while OUT1 is low.
This is a test of the current executable plus local provisional probes,
not a claim that those probes are committed to the external MAME driver.

Boot results with provisional probes:
  ESE.IMD                                      READY at 160 seconds
  MDOS30.IMD                                   READY at 160 seconds
  MDOSUTIL.IMD                                 READY at 160 seconds
  BCOS_II_3.3_FD_ALL_RESIDENT.imd                mono-user environment, disk removal allowed
  K02733_BCOS_II_3.3_CONFIGURATOR.imd            DATE YYMMDD
  BCOS_LOAD.imd + BCOS_RUN.imd                  /SYS at 220 seconds
  Gardini_Utilities.imd                        NLS-3000 utility menu
  DCOS A/B/C/D/E/F/G/H/R                        diagnostic monitor, all nine pass
  m40-bcos-hd-kusa.chd                         /SYS at 300 seconds
  m40-mos-hd.chd                               root menu at 480 seconds

BCOS generated-system test ejects LOAD at t=90, inserts RUN at t=93,
acknowledges at t=97, enters SPAM and the date, and reaches /SYS.
Hard-disk login sequences are the existing project regression sequences.
Both provisional HD final screens match scripts/expected/hd-{bcos,mos}.png
pixel for pixel (RGB); verification.json records comparisons and media check.
HD runs with all probes disabled are also included as *-baseline; both pass
the same pixel comparison. There were no boot regressions in this set.

DCOS: the first 70-second Enter was too early on stock ROM 6.0. A delayed
natural-keyboard Enter at t=110 reaches the monitor. A-H monitor runs are
*-monitor; R has the delayed event in its original run. This tests DCOS boot
and the monitor, not every diagnostic program or controller function.
The previously observed A.5 HDC505 test-4 timer failure is still unresolved;
this regression does not establish that the board passes the full diagnostic.

MDOS crosschecks: additional no-GO363, no-probe and GO363-only-probe runs
were made. The original MDOS30 and MDOSUTIL final screenshots are exactly
identical to ESE's READY screenshot. The image viewer suppressed repeated
content, briefly causing them to be mistaken for blank screens; pixel checks
corrected that interpretation. This was not a guest failure.

Provisional runs log UC timer clear at t=0.122325, PC=00021a. Common F9/FB
interventions, if any, are recorded in interventions.log. No common F9/FB
read overrides were exercised in these runs. The stock/custom 6.0 paths
therefore do not directly validate A.5's native common-register protocol.

Not independently bootable, excluded by the published guide: keyboard disk,
blank media and companion media. Systems listed as not included (MDOSC and
BCOS 5.0) are not present in this published regression set.

Each run directory contains command.json, launch.out, screenshots, key events,
CPU samples, and intervention log. run.py builds the initial suite;
recheck.py records any changed settings for follow-up runs. Scripts should
use a fresh destination directory for reruns. No guest ROM or RAM patches
were used beyond the published hacked 6.0 ROM, and no source media was mounted
writable. Original-media hashes are checked again by verify.py.
