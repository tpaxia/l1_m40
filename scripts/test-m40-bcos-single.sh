#!/bin/sh
# One disposable K02733 image, no companion, bounded background boot.
set -eu
cd "$(dirname "$0")/.."
mkdir -p runs
case "${1:?specify fd0 or fd1}" in
  fd0) drive=-flop4 ;; # Historical argument: physical controller unit 0.
  fd1) drive=-flop1 ;; # Physical controller unit 1, BCOS FD1.
  *) exit 2 ;;
esac
run_dir=$(mktemp -d "$PWD/runs/bcos-single-$1.XXXXXX")
cp 'reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' "$run_dir/boot.imd"
export SDL_MAC_BACKGROUND_APP=1 M40_SERIES_DIR="$run_dir"
export BCOS_KEYPAD=1 BCOS_KBD_TRACE=1
printf '%s\n' "$run_dir"
exec /Users/paxia/Projects/mame_latest/mame/m40 m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  "$drive" "$run_dir/boot.imd" -ram 2m \
  -nvram_directory "$run_dir/nvram" -cfg_directory "$run_dir/cfg" \
  -autoboot_script "${BCOS_BOOT_SCRIPT:-scripts/lua/mame_bcos_state.lua}" \
  -nomouse -video none -sound none -nothrottle -seconds_to_run 220
