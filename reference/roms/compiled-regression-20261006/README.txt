Compiled MAME boot-fix verification — 2026-10-06

RESULT: All 19 software boot checks PASS, emulator exits all zero.
A.5 MOS root menu, hacked-6.0 MOS root menu and BCOS HD /SYS match their
saved reference screens pixel for pixel. All nine DCOS monitors pass.
All intervention logs are empty, and every source-media hash is unchanged.

The UC042 low-OUT1 pending-request clear and GO363 F9/FB zero-return changes
are compiled into MAME. run.py repeats the published M40 media boot tests
plus original A.5 MOS HD boot and root login, from fresh source-media copies.
There are no modifying Lua interventions: PROVISIONAL=0 and CLEAR_TIMER=0.
The observer only samples state, takes screenshots, sets the IPL switch,
and enters the documented keyboard/media-swap sequences.

manifest.json records the tested binary checksum, base source commit and
all media hashes. mame.diff records the exact compiled changes relative to
that base commit. Per-run command.json records the selected BIOS and disabled
probe environment; interventions.log must be empty for every run.

verify.py compares the three HD final screens pixel for pixel with the saved
BCOS /SYS and MOS root-menu references. ESE/MDOS use the READY-text region,
the other floppy software uses its OS display, and DCOS uses the shared
monitor-menu region, excluding version-specific title text. Source media
hashes are checked again. exit-status.json records all emulator exits.

The complete GO363 common-register behavior remains to be recovered, and
the prior HDC505 timer measurement issue remains separate from these boot
regressions. The zero returns are a healthy-board approximation, now included
in the source at the user's explicit request.
