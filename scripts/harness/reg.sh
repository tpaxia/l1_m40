#!/bin/sh
# usage: reg.sh OUTDIR BIN ROMPATH CHD [mame args]   (env ISL, RUN_SECONDS, SHOT_STEP)
set -eu
M40_ROOT=$(cd "$(dirname "$0")/../.." && pwd); . "$M40_ROOT/scripts/m40env.sh"
P=$M40_ROOT; R=$P/scripts/harness
t=$1; bin=$2; rp=$3; chd=$4; shift 4
rm -rf "$t"; mkdir -p "$t"; cp "$chd" "$t/hd.chd"; chmod u+w "$t/hd.chd"
export OUT="$t" STEPS="" SHOT_STEP=${SHOT_STEP:-20} RUN_SECONDS=${RUN_SECONDS:-300} SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$t"
"$bin" m40 -rompath "$rp" -slot5 go363 -hard1 "$t/hd.chd" -ram 2m -nvram_directory "$t/nvram" -cfg_directory "$t/cfg" \
  -autoboot_script "$R/run_keys.lua" -video none -sound none -nothrottle -seconds_to_run "$RUN_SECONDS" "$@" > launch.out 2>&1
tail -1 launch.out
