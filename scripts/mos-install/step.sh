#!/bin/sh
# usage: step.sh NAME [FROM]   (env STEPS, UNTIL=absolute emulated seconds, SHOT_STEP, FLOP=image in drive 1)
# Runs one stage of the MOS install. Work disks live in runs/mos-install/work/
# and are changed in place; FROM names the stage whose saved state and disk
# snapshot to start from (none = cold boot from the starter). At UNTIL-1 s the
# machine state is saved as NAME and the work disks are snapshotted; both go to
# the checkpoint store re/checkpoints/mos-install/ (sta/m40/, snap/NAME/).
set -eu
P=/Users/paxia/Projects/L1_M30_M40; R=$P/scripts/harness; D=$P/re/checkpoints/mos-install; W=$P/runs/mos-install
name=$1; from=${2:-}
rm -rf "$W/out/$name"; mkdir -p "$W/work" "$D/sta/m40" "$D/snap" "$W/out/$name"
if [ -n "$from" ]; then
  cp -c "$D/snap/$from/"* "$W/work/"
  state="-state $from"
else
  cp "$D/wren2-formatted-hdc5f5.chd" "$W/work/hd.chd"
  cp "$D/starter.imd" "$W/work/starter.imd"
  for n in 1 2 3 4 5 6 7; do cp "$P/reference/Disk Images (Stefano Marinelli + others)/Mos/DPC7$n.IMD" "$W/work/dpc7$n.imd"; done
  state=""
fi
chmod u+w "$W/work/"*
export OUT="$W/out/$name" SHOT_STEP=${SHOT_STEP:-20} RUN_SECONDS=${UNTIL:?} ISL=${ISL:-floppy}
export SAVE_T=$((UNTIL - 1)) SAVE_NAME=$name INNER=$R/run_keys.lua
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$OUT"
/Users/paxia/Projects/mame_latest/mame/m40 m40 -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  -slot5 go363 -hard1 "$W/work/hd.chd" -flop1 "$W/work/${FLOP:-starter.imd}" -ram 2m \
  -nvram_directory "$W/nvram" -cfg_directory "$W/cfg" -state_directory "$D/sta" $state \
  -autoboot_script "$R/run_savestate.lua" -video none -sound none -nothrottle -log \
  -seconds_to_run "$UNTIL" > launch.out 2>&1
tail -1 launch.out
rm -rf "$D/snap/$name"; mkdir -p "$D/snap/$name"; cp -c "$W/work/"* "$D/snap/$name/"
ls "$D/sta/m40/" | tr '\n' ' '
