#!/bin/sh
# Disposable-media, bounded UC3003 diagnostic and optional alias test.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_dir=$(mktemp -d "$PWD/runs/uc-validation.XXXXXX")
export SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=cocoa
if [ "${1:-}" = aliases ]; then
  exec "$M40_MAME_BIN" m40 \
    -rompath "$M40_ROMS" \
    -nvram_directory "$run_dir/nvram" -nomouse -video none -sound none \
    -nothrottle -seconds_to_run 5 -autoboot_script scripts/m40-uc-alias-test.lua
fi
cp 'reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/A.IMD' "$run_dir/boot.imd"
export M40_FINAL_SNAPSHOT="$run_dir/screen.png"
export M40_FINAL_SNAPSHOT_TIME="${2:-179}"
test_keys='\n1\n008\n{WAIT:35}4\n'
if [ "$#" -gt 0 ]; then test_keys=$1; fi
exec python3 tools/m40_harness.py run \
  --mame-bin "$M40_MAME_BIN" \
  --trace-script scripts/lua/mame_m40_timed_keys.lua --disk "$run_dir/boot.imd" \
  --out-root "$run_dir" --name uc --seconds "${3:-180}" \
  --keys "$test_keys" --key-delay 70 --inter-key-delay 2 \
  --mame-arg=-nvram_directory --mame-arg="$run_dir/nvram"
