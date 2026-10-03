#!/bin/sh
# TEMP bit-4 ablation probe: disposable disks, fresh boot, no RAM patches.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/kdc-bit4-${1:?config, resident or gardini}.XXXXXX")
case "$1" in
  config) source_disk='reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' ;;
  resident) source_disk='reference/Disk Images/BCOS_II_3.3_FD_ALL_RESIDENT.imd' ;;
  gardini) source_disk='reference/Disk Images (Stefano Marinelli + others)/Gardini/gardini.imd' ;;
  *) exit 2 ;;
esac
cp "$source_disk" "$run_dir/boot.imd"
export SDL_MAC_BACKGROUND_APP=1 M40_SERIES_DIR="$run_dir"
printf '%s\n' "$run_dir"
exec "$M40_MAME_BIN" m40 \
  -rompath "$M40_ROMS" \
  -flop1 "$run_dir/boot.imd" -ram 2m \
  -cfg_directory "$run_dir/cfg" -snapshot_directory "$run_dir/snap" -nvram_directory "$run_dir/nvram" \
  -autoboot_script scripts/lua/mame_kdc_bit4_probe.lua \
  -nomouse -video none -sound none -nothrottle -seconds_to_run 160
