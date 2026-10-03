#!/bin/sh
# Bounded OS boot probes, never use original media as writable images.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/os-${1:?mdos, mdosutil, mdos20, mdos31, mdos32, ese, bcos33, bcos33-config, bcos50 or mos}.XXXXXX")
case "$1" in
  mdos) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/MDOS30.IMD' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  mdosutil) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/MDOSUTIL.IMD' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  mdos20) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/probejsf.imd' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  mdos31) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/m40.imd' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  mdos32) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/M40MDO32.imd' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  ese) cp 'reference/Disk Images (Stefano Marinelli + others)/Ese L1/ESE.IMD' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  bcos33) cp 'reference/Disk Images/BCOS_II_3.3_FD_ALL_RESIDENT.imd' "$run_dir/boot.imd"; set -- -flop1 "$run_dir/boot.imd" ;;
  bcos33-config) cp 'reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' "$run_dir/boot.imd"; set -- -flop2 "$run_dir/boot.imd" ;;
  bcos50)
    disk-analyse -q -r 360 'reference/Disk Images/K02753_BCOS_II_5.0_ALL_RESIDENT.scp' "$run_dir/boot.imd"
    set -- -flop1 "$run_dir/boot.imd"
    ;;
  mos)
    # The MOS ST506 starter as the install used it: empty cylinder 77 removed,
    # and a WREN2 formatted by DCOS HDC5F5 (re/checkpoints/mos-install/).
    python3 tools/imd_trim_empty_tail.py 'reference/Disk Images (Stefano Marinelli + others)/Mos/StarterST506.IMD' "$run_dir/boot.imd" 77
    cp re/checkpoints/mos-install/wren2-formatted-hdc5f5.chd "$run_dir/hd.chd"
    chmod u+w "$run_dir/hd.chd"
    seconds=230
    set -- -flop1 "$run_dir/boot.imd" -slot5 go363 -hard1 "$run_dir/hd.chd"
    ;;
  *) exit 2 ;;
esac
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}" M40_SERIES_DIR="$run_dir"
printf '%s\n' "$run_dir"
exec "$M40_MAME_BIN" m40 \
  -rompath "$M40_ROMS" \
  -ram 2m "$@" \
  -nvram_directory "$run_dir/nvram" -cfg_directory "$run_dir/cfg" -snapshot_directory "$run_dir/snap" \
  -autoboot_script scripts/m40-os-observe.lua \
  -nomouse -video none -sound none -nothrottle -seconds_to_run "${seconds:-160}"
