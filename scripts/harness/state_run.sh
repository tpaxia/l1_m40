#!/bin/sh
# usage: state_run.sh EXPDIR  (env: BASE=state dir with hd.chd + sta/, STATE=name,
#        STEPS, PROBE, LIMIT, RUN_SECONDS, SHOT_STEP; WRAP=run_savestate.lua with
#        INNER=run_state_probe.lua SAVE_T SAVE_NAME saves a new state into EXPDIR/sta).
#        Copies BASE/hd.chd into EXPDIR.
set -eu
M40_ROOT=$(cd "$(dirname "$0")/../.." && pwd); . "$M40_ROOT/scripts/m40env.sh"
R=$M40_ROOT/scripts/harness; C=$M40_ROOT/re/checkpoints/bcos-hd
t=$1; rm -rf "$t"; mkdir -p "$t"; cp "$BASE/hd.chd" "$t/hd.chd"
printf 'go\n' > "$t/debug.cmd"
DEBUG=1 SCRIPT=${WRAP:-$R/run_state_probe.lua} ISL=floppy OUT=$t $R/launch.sh "$t/hd.chd" \
  -flop1 $C/oslem7.imd -state_directory "${SAVE_DIR:-$BASE/sta}" -state "$STATE" \
  -debugscript "$t/debug.cmd" ${EXTRA:-} > "$t/launch.out" 2>&1
