#!/bin/sh
# usage: cos_try.sh NAME "STEPS for COS# field edits (from t=500, end before 546)"
# Applies the edits on the keyboard record page (state bcos-cos-ky), saves J0XP,
# then cold-boots the result on the patched ROM with no debugger.
R=/Users/paxia/Projects/L1_M30_M40/scripts/harness; A=/Users/paxia/Projects/L1_M30_M40/runs-archive/restore-hd-20260928; d=$A/install; n=$1
STATE=bcos-cos-ky SHOT_STEP=50 RUN_SECONDS=680 STEPS="$2;546:@Keypad ENTER;590:@Keypad ENTER;620:@Keypad ENTER" $R/bcos_run.sh $d/try-$n-cos >/dev/null
t=$d/try-$n-boot; rm -rf $t; mkdir -p $t; cp $d/try-$n-cos/hd.chd $t/hd.chd; cd $t
ROMPATH="/Users/paxia/Projects/mame_disks/m40/roms/m40-hd65;/Users/paxia/Projects/mame_latest/mame/roms" SHOT_STEP=20 STEPS="" SCRIPT=$R/run_keys.lua OUT=$t RUN_SECONDS=${BOOT_SECONDS:-200} $R/launch.sh $t/hd.chd > launch.out 2>&1
echo "$n: go363=$(grep -c go363 error.log)"
