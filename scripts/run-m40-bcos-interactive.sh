#!/bin/sh
# Visible, persistent user session; original disk images remain untouched.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/bcos-interactive.XXXXXX")
cp 'reference/Disk Images/K02733_BCOS_II_3.3_CONFIGURATOR.imd' "$run_dir/boot.imd"
case "${1:-}" in
  '') set -- ;;
  --keyboard-disk)
    cp reference/images/bcos/K02741_BCOS_II_3.3_JJKEYB.imd "$run_dir/keyboard.imd"
    set -- -flop2 "$run_dir/keyboard.imd"
    ;;
  *) echo "Usage: $0 [--keyboard-disk]" >&2; exit 2 ;;
esac
unset SDL_MAC_BACKGROUND_APP
printf '%s\n' "$run_dir"
exec "$M40_MAME_BIN" m40 \
  -rompath "$M40_ROMS" \
  -flop1 "$run_dir/boot.imd" "$@" \
  -ram 2m -nvram_directory "$run_dir/nvram" \
  -cfg_directory "$run_dir/cfg" -window -nomaximize -nomouse \
  -skip_gameinfo -sound none -nothrottle -uimodekey F12 -ctrlrpath scripts -ctrlr m40-ui \
  -autoboot_script scripts/m40-interactive-start.lua
