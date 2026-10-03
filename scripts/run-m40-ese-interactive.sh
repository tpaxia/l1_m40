#!/bin/sh
# Visible ESE session using a disposable writable copy of the original disk.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/ese-interactive.XXXXXX")
cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/ESE.IMD' "$run_dir/boot.imd"
unset SDL_MAC_BACKGROUND_APP SDL_VIDEODRIVER
printf '%s\n' "$run_dir"
exec "$M40_MAME_BIN" m40 \
  -rompath "$M40_ROMS" \
  -flop1 "$run_dir/boot.imd" -ram 2m \
  -nvram_directory "$run_dir/nvram" -cfg_directory "$run_dir/cfg" \
  -window -nomaximize -nomouse -skip_gameinfo -sound none -nothrottle \
  -uimodekey F12 -ctrlrpath scripts -ctrlr m40-ui \
  -autoboot_script scripts/m40-ese-interactive-start.lua
