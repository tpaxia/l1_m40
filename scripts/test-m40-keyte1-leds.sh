#!/bin/sh
# TEMP bounded KEYTE1 run, on a disposable diagnostic disk.
set -eu
cd "$(dirname "$0")/.."
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/keyte1-leds.XXXXXX")
cp 'reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/B.IMD' "$run_dir/diagnostic.imd"
export SDL_MAC_BACKGROUND_APP=1 M40_LED_DIR="$run_dir"
export M40_TRACE_LOG="$run_dir/keys.log"
test_keys='\n1\n013\n{WAIT:35}1\n'
if [ "$#" -gt 0 ]; then test_keys=$1; fi
export M40_KEYS="$test_keys"
export M40_KEY_DELAY=90 M40_INTER_KEY_DELAY=2
printf '%s\n' "$run_dir"
exec "${M40_KDC_BINARY:-/Users/paxia/Projects/mame_latest/mame/m40}" m40 \
  -rompath /Users/paxia/Projects/mame_latest/mame/roms \
  -flop1 "$run_dir/diagnostic.imd" -ram 2m \
  -cfg_directory "$run_dir/cfg" -nvram_directory "$run_dir/nvram" \
  -autoboot_script scripts/lua/mame_keyte1_leds.lua \
  -video none -sound none -nomouse -nothrottle -skip_gameinfo \
  -seconds_to_run "${2:-190}"
