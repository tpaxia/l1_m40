#!/bin/sh
# Fresh generated-system boot on copies; no state/volume-name patches.
set -eu
cd "$(dirname "$0")/.."
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/bcos-generated-boot.XXXXXX")
cp /Users/paxia/Projects/mame_latest/mame/flop/BCOS_LOAD.imd "$run_dir/load.imd"
cp /Users/paxia/Projects/mame_latest/mame/flop/BCOS_RUN.imd "$run_dir/run.imd"
export SDL_MAC_BACKGROUND_APP=1 BCOS_GENERATED_DIR="$run_dir"
export M40_SERIES_DIR="$run_dir" BCOS_KEYPAD=1
printf '%s\n' "$run_dir"
exec "${M40_KDC_BINARY:-/Users/paxia/Projects/mame_latest/mame/m40}" m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms -flop1 "$run_dir/load.imd" \
  -ram 2m -cfg_directory "$run_dir/cfg" -nvram_directory "$run_dir/nvram" \
  -autoboot_script scripts/lua/mame_bcos_generated_boot.lua \
  -video none -sound none -nomouse -nothrottle -seconds_to_run "${BCOS_GENERATED_SECONDS:-120}"
