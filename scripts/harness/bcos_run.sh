#!/bin/sh
# usage: bcos_run.sh EXPDIR   (env STEPS, RUN_SECONDS, SHOT_STEP, BASE, STATE, EXTRA)
# Resume the HD-booted BCOS II from the /SYS state (patched ROM roms-hd65, no
# debugger). Copies BASE/hd.chd into EXPDIR; machine time resumes at 300 s.
set -eu
R=/Users/paxia/Projects/L1_M30_M40/scripts/harness; A=/Users/paxia/Projects/L1_M30_M40/runs-archive/restore-hd-20260928
B=${BASE:-$A/install/bcos-base}; t=$1; rm -rf "$t"; mkdir -p "$t"; cp "$B/hd.chd" "$t/hd.chd"
ROMPATH="/Users/paxia/Projects/mame_disks/m40/roms/m40-hd65;/Users/paxia/Projects/mame_latest/mame/roms" SCRIPT=${SCRIPT:-$R/run_keys.lua} OUT=$t $R/launch.sh "$t/hd.chd" \
  -state_directory "$B/sta" -state "${STATE:-bcos-sys}" ${EXTRA:-} > "$t/launch.out" 2>&1
tail -1 "$t/launch.out"
