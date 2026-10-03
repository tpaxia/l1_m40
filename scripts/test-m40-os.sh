#!/bin/sh
# Bounded OS boot probes, never use original media as writable images.
set -eu
cd "$(dirname "$0")/.."
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/os-${1:?mdos, mdosutil, mdos20, mdos31, mdos32, ese, bcos33, bcos33-config, bcos50, mos, mos-nohd or mos-nomedia}.XXXXXX")
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
  mos|mos-nohd|mos-nomedia)
    python3 tools/imd_trim_empty_tail.py 'reference/Disk Images (Stefano Marinelli + others)/Mos/StarterST506.IMD' "$run_dir/boot.imd" 77
    case "$1" in
      mos)
        /Users/paxia/Projects/mame_latest/mame/chdman createhd -o "$run_dir/blank.chd" -chs 425,12,32 -ss 256
        set -- -flop1 "$run_dir/boot.imd" -slot5 go363 -hard1 "$run_dir/blank.chd"
        ;;
      mos-nohd) set -- -flop1 "$run_dir/boot.imd" -slot5 '' ;;
      mos-nomedia) set -- -flop1 "$run_dir/boot.imd" -slot5 go363 ;;
    esac
    ;;
  *) exit 2 ;;
esac
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}" M40_SERIES_DIR="$run_dir"
printf '%s\n' "$run_dir"
exec /Users/paxia/Projects/mame_latest/mame/m40 m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  -ram 2m "$@" \
  -nvram_directory "$run_dir/nvram" -cfg_directory "$run_dir/cfg" \
  -autoboot_script scripts/m40-os-observe.lua \
  -nomouse -video none -sound none -nothrottle -seconds_to_run 160
