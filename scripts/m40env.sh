# Common settings for the M40 scripts; sourced, not run. The sourcing script
# sets M40_ROOT to the project folder first.
#
# M40_MAME_BIN  MAME binary built with the M40 driver. Default: the `m40`
#               build in `mame_latest/mame/` next to this project.
#
# Provides M40_ROMS and M40_ROMS_HD65: MAME ROM folders built from
# reference/roms/ (under runs/, rebuilt when missing). M40_ROMS holds the
# stock system ROMs; M40_ROMS_HD65 replaces REL 6.0 with the patched ROM
# that boots from the GO363 hard disk. Both include the character generator.

: "${M40_MAME_BIN:=$M40_ROOT/../mame_latest/mame/m40}"
if [ ! -x "$M40_MAME_BIN" ]; then
  echo "No MAME binary at $M40_MAME_BIN; set M40_MAME_BIN to your M40 MAME build." >&2
  exit 1
fi

m40_build_roms() {   # m40_build_roms DIR REL60-IMAGE
  # One script builds the folder (mkdir is the lock); scripts started at the
  # same time wait for its .done marker instead of using a half-copied set.
  [ -f "$1/.done" ] && return
  mkdir -p "$(dirname "$1")"
  if mkdir "$1.lock" 2>/dev/null; then
    r=$M40_ROOT/reference/roms
    rm -rf "$1"; mkdir -p "$1/m40"
    cp "$r/9428ds-2067.bin" "$r/m40rom-15-dec-81" "$r/m40rom-4.1" "$1/m40/"
    cp "$r/m40rom-4.1" "$1/m40/m40rom-17-dec-82"
    cp "$r/$2" "$1/m40/m40rom-6.0.bin"
    touch "$1/.done"; rmdir "$1.lock"
  else
    while [ ! -f "$1/.done" ]; do sleep 1; done
  fi
}
M40_ROMS=$M40_ROOT/runs/roms
M40_ROMS_HD65=$M40_ROOT/runs/roms-hd65
m40_build_roms "$M40_ROMS" m40rom-6.0
m40_build_roms "$M40_ROMS_HD65" m40rom-6.0-hd65.bin
export M40_ROOT M40_MAME_BIN M40_ROMS M40_ROMS_HD65
