#!/bin/sh
# usage: test-m40-hd.sh [bcos|mos|all]   (env M40_MAME_BIN, M40_UPDATE_EXPECTED=1)
# Boots the BCOS II and MOS hard-disk systems on the patched hd65 ROM, from
# disposable copies of re/checkpoints/ (byte-identical to the images published
# in mame_disks; M40_HD_BCOS / M40_HD_MOS select other images), and compares
# the final screen pixel by pixel with scripts/expected/: BCOS II to /SYS (password A, date, time), MOS to the root
# menu (login, date, time, login again). M40_UPDATE_EXPECTED=1 stores the
# screens as the new references.
set -eu
cd "$(dirname "$0")/.."
M40_ROOT=$PWD; . scripts/m40env.sh
mkdir -p runs
P=$PWD
BIN=$M40_MAME_BIN
ROMPATH=$M40_ROMS_HD65
NL='
'
status=0

run() {   # name chd seconds steps
  name=$1; chd=$2; secs=$3; steps=$4
  t=$(mktemp -d "$P/runs/hd-$name.XXXXXX")
  cp "$chd" "$t/hd.chd"; chmod u+w "$t/hd.chd"
  printf '%s: %s\n' "$name" "$t"
  ( cd "$t" && OUT="$t" STEPS="$steps" SHOT_STEP=20 RUN_SECONDS="$secs" \
      SDL_MAC_BACKGROUND_APP=1 SDL_VIDEODRIVER=dummy \
      "$BIN" m40 -rompath "$ROMPATH" -ram 2m -slot5 go363 -hard1 "$t/hd.chd" \
      -nvram_directory "$t/nvram" -cfg_directory "$t/cfg" -snapshot_directory "$t/snap" \
      -autoboot_script "$P/scripts/harness/run_keys.lua" \
      -nomouse -video none -sound none -nothrottle -seconds_to_run "$secs" > "$t/launch.out" 2>&1 )
  shot=$(ls "$t"/s_*.png | sort | tail -1)
  exp="$P/scripts/expected/hd-$name.png"
  if [ "${M40_UPDATE_EXPECTED:-}" = 1 ]; then
    mkdir -p "$P/scripts/expected"; cp "$shot" "$exp"; echo "$name: reference updated from $(basename "$shot")"
  elif python3 - "$shot" "$exp" <<'EOF'
import sys
from PIL import Image
a, b = (Image.open(p).convert('RGB') for p in sys.argv[1:3])
sys.exit(0 if a.size == b.size and a.tobytes() == b.tobytes() else 1)
EOF
  then echo "$name: PASS"
  else echo "$name: FAIL (compare $shot with $exp)"; status=1
  fi
}

case "${1:-all}" in
  bcos|all) run bcos "${M40_HD_BCOS:-$P/re/checkpoints/bcos-hd/hd-bcos-kusa.chd}" 300 \
      "200:=A;204:@Keypad ENTER;225:=860909;232:@Keypad ENTER;250:=120000;257:@Keypad ENTER" ;;
esac
case "${1:-all}" in
  # MOS asks for the date and time after the first login, then for the user
  # name again; "/" is the ANK key "? (29)".
  mos|all) run mos "${M40_HD_MOS:-$P/re/checkpoints/mos-install/mos-hd-bootable.chd}" 480 \
      "203:=root$NL;262:=10;264:@? (29);266:=02;268:@? (29);270:=87;272:=$NL;280:=10;282:@? (29);284:=30;286:@? (29);288:=00;290:=$NL;402:=root$NL" ;;
  bcos) ;;
  *) echo "usage: $0 [bcos|mos|all]" >&2; exit 2 ;;
esac
exit $status
