#!/bin/sh
# Isolated input regression; no disk writes, guest patches or GUI session.
set -eu
cd /Users/paxia/Projects/L1_M30_M40
run_dir=$(mktemp -d "$PWD/re/runs/host-keymap.XXXXXX")
export SDL_MAC_BACKGROUND_APP=1 M40_KEYMAP_TEST_DIR="$run_dir"
printf '%s\n' "$run_dir"
set -- -uimodekey F12 -ctrlrpath scripts -ctrlr m40-ui
exec /Users/paxia/Projects/mame_latest/mame/m40 m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  -ram 2m -cfg_directory "$run_dir/cfg" \
  -nvram_directory "$run_dir/nvram" -autoboot_delay 0 \
  -autoboot_script re/mame_m40_host_keymap_test.lua \
  -video none -sound none -nomouse -nothrottle -skip_gameinfo "$@" \
  -seconds_to_run 90
