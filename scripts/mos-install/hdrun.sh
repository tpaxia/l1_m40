#!/bin/sh
# usage: hdrun.sh NAME [FROM]  (env STEPS, UNTIL, SHOT_STEP) - boot/resume the installed MOS disk (patched ROM)
set -eu
P=/Users/paxia/Projects/L1_M30_M40; R=$P/scripts/harness; A=$P/runs-archive/restore-hd-20260928; D=$P/runs-archive/mos-install-20261002
name=$1; from=${2:-}; t=$D/hd/$name; rm -rf "$t"; mkdir -p "$t" "$D/hd/sta/m40"
if [ -n "$from" ]; then cp -c "$D/hd/$from/hd.chd" "$t/hd.chd"; state="-state $from"; else cp "$D/mos-hd-bootable.chd" "$t/hd.chd"; state=""; fi
chmod u+w "$t/hd.chd"
export OUT="$t" SHOT_STEP=${SHOT_STEP:-20} RUN_SECONDS=${UNTIL:?} SAVE_T=$((UNTIL - 1)) SAVE_NAME=$name INNER=$R/run_keys.lua
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$t"
/Users/paxia/Projects/mame_latest/mame/m40 m40 -rompath "/Users/paxia/Projects/mame_disks/m40/roms/m40-hd65;/Users/paxia/Projects/mame_latest/mame/roms" -slot5 go363 -hard1 "$t/hd.chd" -ram 2m \
  -nvram_directory "$D/hd/nvram" -cfg_directory "$D/hd/cfg" -state_directory "$D/hd/sta" $state \
  -autoboot_script "$R/run_savestate.lua" -video none -sound none -nothrottle -seconds_to_run "$UNTIL" > launch.out 2>&1
tail -1 launch.out
