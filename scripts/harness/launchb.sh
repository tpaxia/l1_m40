#!/bin/sh
# launch.sh with a selectable binary (BIN)
set -eu
CHD=$1; shift
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$OUT"
exec ${BIN:-/Users/paxia/Projects/mame_latest/mame/m40} m40 \
  -rompath ${ROMPATH:-/Users/paxia/Projects/mame_latest/mame/roms} \
  -slot5 go363 -hard1 "$CHD" \
  -ram 2m -nvram_directory "$OUT/nvram" -cfg_directory "$OUT/cfg" \
  -autoboot_script "$SCRIPT" \
  ${DEBUG:+-debug -debugger none -debuglog} -video none -sound none -nothrottle -log -seconds_to_run "${RUN_SECONDS:-150}" "$@"
