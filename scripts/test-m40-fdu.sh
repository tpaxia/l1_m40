#!/bin/sh
# Bounded, background-only DCOS FDU diagnostic on disposable media.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
run_root=$(mktemp -d "$PWD/runs/fdu-validation.XXXXXX")
cp 'reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/D.IMD' "$run_root/diagnostic.imd"
cp "$run_root/diagnostic.imd" "$run_root/scratch.imd"
export SDL_MAC_BACKGROUND_APP=1
export SDL_VIDEODRIVER=cocoa
# Monitor LOAD activates this diagnostic directly; the next input is slot 2,
# not monitor GO. Then accept default PU and start with confirmation.
test_keys='\n1\n007\n{WAIT:35}2\n\n{WAIT:12}\n{WAIT:5}1\n{WAIT:5}\n'
if [ "$#" -gt 0 ]; then test_keys=$1; fi
test_seconds=${2:-230}
export M40_FINAL_SNAPSHOT="$run_root/screen.png"
export M40_FINAL_SNAPSHOT_TIME=$((test_seconds - 1))
# Third argument selects the number of inserted images, not connected devices:
# all four connectors remain populated to preserve flop1..4 numbering.
test_drives=${3:-2}
set --
if [ "$test_drives" != 1 ]; then
  set -- --mame-arg=-flop4 --mame-arg="$run_root/scratch.imd"
fi
if [ "$test_drives" = 4 ]; then
  cp "$run_root/diagnostic.imd" "$run_root/drive2.imd"
  cp "$run_root/diagnostic.imd" "$run_root/drive3.imd"
  set -- "$@" --mame-arg=-slot4:go280:fdc:2 --mame-arg=8dsdd \
    --mame-arg=-slot4:go280:fdc:3 --mame-arg=8dsdd \
    --mame-arg=-flop2 --mame-arg="$run_root/drive2.imd" \
    --mame-arg=-flop3 --mame-arg="$run_root/drive3.imd"
fi
exec python3 tools/m40_harness.py run \
  --mame-bin "$M40_MAME_BIN" \
  --trace-script "${M40_FDU_SCRIPT:-scripts/lua/mame_m40_timed_keys.lua}" \
  --disk "$run_root/diagnostic.imd" --out-root "$run_root" \
  --name fdu --seconds "$test_seconds" "$@" \
  --keys "$test_keys" \
  --key-delay 70 --inter-key-delay 2 \
  --mame-arg=-nvram_directory --mame-arg="$run_root/nvram"
