#!/bin/sh
# Regenerate the M40 disassembly from the ROM and re-apply every annotation pass,
# then verify byte-identity. Run this after editing mkasm.py (MAPS) or any
# annotate_*.py. Annotations live in the scripts, NOT in hand edits to the .s.
set -e
cd "$(dirname "$0")/.."

python3 tools/mkasm.py reference/roms/m40rom-4.1 re/disassembly/m40-rom/m40rom-4.1.s
python3 tools/mkasm.py reference/roms/m40rom-6.0 re/disassembly/m40-rom/m40rom-6.0.s

# Order: independent regions, but keep it stable for reproducibility.
for s in annotate_baa annotate_tests annotate_slotscan annotate_ramsize annotate_memtest annotate_ipl annotate_fdu; do
    python3 "tools/$s.py"
done

( cd re/disassembly/m40-rom && make --no-print-directory verify )
