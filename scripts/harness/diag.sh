#!/bin/sh
# usage: diag.sh OUTDIR CODE [mame-binary]   (env RUN_SECONDS, SHOT_STEP, TAIL)
# Boot diagnostic disk A, load program CODE from the monitor, accept default
# parameters, run one cycle; screenshots every SHOT_STEP seconds.
set -eu
M40_ROOT=$(cd "$(dirname "$0")/../.." && pwd); . "$M40_ROOT/scripts/m40env.sh"
P=$M40_ROOT
t=$1; code=$2; bin=${3:-$M40_MAME_BIN}
rm -rf "$t"; mkdir -p "$t"
cp "$P/reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/${DISK:-A}.IMD" "$t/boot.imd"
NL='
'
STEPS="70:=$NL;73:=1$NL;77:=$code$NL;115:=4$NL;127:=$NL;130:=$NL;133:=$NL;141:=$NL;146:=1$NL;152:=$NL${TAIL:-;212:=0$NL;237:=0$NL;262:=0$NL;287:=0$NL}"
export STEPS OUT="$t" SHOT_STEP=${SHOT_STEP:-10} RUN_SECONDS=${RUN_SECONDS:-420}
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$t"
"$bin" m40 -rompath "$M40_ROMS" -flop1 "$t/boot.imd" \
  -nvram_directory "$t/nvram" -cfg_directory "$t/cfg" \
  -autoboot_script "$P/scripts/harness/run_keys.lua" \
  -video none -sound none -nothrottle -seconds_to_run "$RUN_SECONDS" > launch.out 2>&1
tail -1 launch.out
