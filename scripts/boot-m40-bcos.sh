#!/bin/sh
# Bounded background BCOS launch, with isolated NVRAM and disposable media.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/bcos-boot.XXXXXX")
cp 'reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' "$run_dir/boot.imd"
cp 'reference/Disk Images/K02737_BCOS_II_3.3.imd' "$run_dir/companion.imd"
export SDL_MAC_BACKGROUND_APP=1
export M40_SERIES_DIR="$run_dir"
export M40_SERIES_TIMES="${BCOS_SERIES_TIMES:-74}"
printf '%s\n' "$run_dir"
exec "$M40_MAME_BIN" m40 \
  -rompath "$M40_ROMS" \
  -flop4 "$run_dir/companion.imd" -flop1 "$run_dir/boot.imd" \
  -ram 2m -nvram_directory "$run_dir/nvram" \
  -autoboot_script "${BCOS_BOOT_SCRIPT:-scripts/lua/mame_m40_snapshot_series.lua}" \
  -nomouse -video none -sound none -nothrottle -seconds_to_run "${BCOS_BOOT_SECONDS:-76}"
