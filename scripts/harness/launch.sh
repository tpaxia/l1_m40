#!/bin/sh
# usage: OUT=dir RUN_SECONDS=n launch.sh chd [extra mame args]
set -eu
M40_ROOT=$(cd "$(dirname "$0")/../.." && pwd); . "$M40_ROOT/scripts/m40env.sh"
CHD=$1; shift
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy
cd "$OUT"
exec "$M40_MAME_BIN" m40 \
  -rompath "${ROMPATH:-$M40_ROMS}" \
  -slot5 go363 -hard1 "$CHD" \
  -ram 2m -nvram_directory "$OUT/nvram" -cfg_directory "$OUT/cfg" \
  -autoboot_script "${SCRIPT:-$M40_ROOT/scripts/harness/run.lua}" \
  ${DEBUG:+-debug -debugger none -debuglog} -video none -sound none -nothrottle -log -seconds_to_run "${RUN_SECONDS:-150}" "$@"
