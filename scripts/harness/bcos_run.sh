#!/bin/sh
# usage: bcos_run.sh EXPDIR   (env STEPS, RUN_SECONDS, SHOT_STEP, BASE, STATE, EXTRA)
# Resume the HD-booted BCOS II from the /SYS state (patched ROM roms-hd65, no
# debugger). Copies BASE/hd.chd into EXPDIR; machine time resumes at 300 s.
set -eu
M40_ROOT=$(cd "$(dirname "$0")/../.." && pwd); . "$M40_ROOT/scripts/m40env.sh"
R=$M40_ROOT/scripts/harness; C=$M40_ROOT/re/checkpoints/bcos-hd
B=${BASE:-$C/bcos-base}; t=$1; rm -rf "$t"; mkdir -p "$t"; cp "$B/hd.chd" "$t/hd.chd"
ROMPATH="$M40_ROMS_HD65" SCRIPT=${SCRIPT:-$R/run_keys.lua} OUT=$t $R/launch.sh "$t/hd.chd" \
  -state_directory "$B/sta" -state "${STATE:-bcos-sys}" ${EXTRA:-} > "$t/launch.out" 2>&1
tail -1 "$t/launch.out"
