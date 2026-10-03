#!/bin/sh
# Exercise M40 automatic and explicit RAM-board configuration against the
# resident ROM memory test.  A successful ROM memory phase emits console 0x44.

set -eu
script_dir=$(cd "$(dirname "$0")" && pwd)
M40_ROOT=$(cd "$script_dir/.." && pwd); . "$M40_ROOT/scripts/m40env.sh"

mame_bin=$M40_MAME_BIN
rom_path=${M40_ROMPATH:-$M40_ROMS}
test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/m40-ram-test.XXXXXX")

run_mame()
{
	SDL_MAC_BACKGROUND_APP=1 "$mame_bin" m40 \
		-rompath "$rom_path" -nomouse -video none -sound none -nothrottle \
		-autoboot_script "$script_dir/m40-rom-test.lua" \
		"$@"
}

check_automatic()
{
	size=$1
	expected_first=$2
	expected_second=${3:-}
	log="$test_tmp/auto-$size.log"
	run_mame -nvram_directory "$test_tmp/nvram-auto-$size" \
		-seconds_to_run 120 -ram "$size" -verbose >"$log" 2>&1
	rg -q "code = 0x44" "$log"
	rg -q "automatic $expected_first" "$log"
	if [ -n "$expected_second" ]; then
		rg -q "automatic $expected_second" "$log"
	fi
	printf 'PASS automatic %-5s  %s%s\n' "$size" "$expected_first" "${expected_second:+ + $expected_second}"
}

check_explicit_start()
{
	card=$1
	board=$2
	end=$3
	log="$test_tmp/card-$card.log"
	run_mame -nvram_directory "$test_tmp/nvram-card-$card" \
		-seconds_to_run 1 -slot2 "$card" -verbose >"$log" 2>&1
	rg -q "$board, physical 010000-$end" "$log"
	printf 'PASS explicit %-7s %s\n' "$card" "$board"
}

default_log="$test_tmp/default.log"
run_mame -nvram_directory "$test_tmp/nvram-default" \
	-seconds_to_run 120 -verbose >"$default_log" 2>&1
rg -q "automatic ME027-32 512 KB" "$default_log"
rg -q "code = 0x44" "$default_log"
printf 'PASS default 512K      ME027-32 512 KB, resident ROM memory test\n'

check_automatic 256k  "ME027-32 256 KB"
check_automatic 384k  "ME027-32 384 KB"
check_automatic 512k  "ME027-32 512 KB"
check_automatic 640k  "ME027-32 384 KB" "ME027-32 256 KB"
check_automatic 768k  "ME027-32 512 KB" "ME027-32 256 KB"
check_automatic 896k  "ME027-32 512 KB" "ME027-32 384 KB"
check_automatic 1m   "RA57/C 1 MB"
check_automatic 1536k "RA57/B 1.5 MB"
check_automatic 2m   "RA57/A 2 MB"

check_explicit_start me256k "Olivetti ME027-32 256 KB RAM board" 04FFFF
check_explicit_start me384k "Olivetti ME027-32 384 KB RAM board" 06FFFF
check_explicit_start me512k "Olivetti ME027-32 512 KB RAM board" 08FFFF
check_explicit_start ra57d  "Olivetti RA57/D 512 KB RAM board" 08FFFF
check_explicit_start ra57e  "Olivetti RA57/E 512 KB RAM board" 08FFFF
check_explicit_start ra57c  "Olivetti RA57/C 1 MB RAM board" 10FFFF
check_explicit_start ra57b  "Olivetti RA57/B 1.5 MB RAM board" 18FFFF
check_explicit_start ra57a  "Olivetti RA57/A 2 MB RAM board" 20FFFF

explicit_log="$test_tmp/explicit-640K.log"
run_mame -nvram_directory "$test_tmp/nvram-explicit-640K" \
	-seconds_to_run 120 -slot2 me384k -slot5 me256k -verbose >"$explicit_log" 2>&1
rg -q "position 2, Olivetti ME027-32 384 KB RAM board, physical 010000-06FFFF" "$explicit_log"
rg -q "position 5, Olivetti ME027-32 256 KB RAM board, physical 070000-0AFFFF" "$explicit_log"
rg -q "code = 0x44" "$explicit_log"
printf 'PASS explicit 640K    me384k + me256k, resident ROM memory test\n'

mixed_log="$test_tmp/reject-mixed.log"
if run_mame -nvram_directory "$test_tmp/nvram-reject-mixed" \
	-seconds_to_run 1 -ram 640k -slot2 me384k -slot5 me256k >"$mixed_log" 2>&1; then
	printf 'FAIL mixed -ram and explicit cards was accepted\n' >&2
	exit 1
fi
rg -q -- "-ram cannot be combined with explicit" "$mixed_log"
printf 'PASS reject mixed      -ram plus explicit cards\n'

misplaced_log="$test_tmp/reject-misplaced.log"
if run_mame -nvram_directory "$test_tmp/nvram-reject-misplaced" \
	-seconds_to_run 1 -slot5 me256k >"$misplaced_log" 2>&1; then
	printf 'FAIL RAM population not beginning in slot2 was accepted\n' >&2
	exit 1
fi
rg -q "Explicit RAM population must begin in physical position 2" "$misplaced_log"
printf 'PASS reject misplaced  explicit population not beginning in slot2\n'

printf 'All M40 RAM configuration tests passed. Logs: %s\n' "$test_tmp"
