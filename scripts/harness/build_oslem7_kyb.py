#!/usr/bin/env python3
"""HACK: oslem7+ with its keyboard driver 1KYB 2203 replaced in place by
K02743's 1KYB 1000 (same 6-sector footprint); directory length updated.
Used with the run-time patches in run_descpatch_ext2.lua."""
import struct, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]   # the project folder
sys.path.insert(0, str(ROOT / 'tools'))
from l1disk import L1Disk
from l1lib import Image, directory_index, read_directory
OS = str(ROOT) + '/reference/Disk Images (Stefano Marinelli + others)/Ripristino_HD/oslem7+.imd'
KP = '/private/tmp/k02743-probe/boot.imd'
o, k = Image(OS), Image(KP)
src = [h for h in k.headers() if h.name == '1KYB'][0]
dst = [h for h in o.headers() if h.name == '1KYB'][0]
assert src.sectors <= dst.sectors
d = L1Disk(OS)
d.write(dst.index, src.body() + bytes((dst.sectors - src.sectors) * 256))
di = directory_index(o)
head, ents = read_directory(o, di)
dirb = bytearray(d.read(di, ((len(ents) * 8) + 255) // 256 * 256))
i = next(n for n, e in enumerate(ents) if e[0] == '1KYB')
assert di + ents[i][1] - 1 == dst.index
dirb[i * 8 + 6:i * 8 + 8] = struct.pack('>H', src.length)
d.write(di, bytes(dirb))
d.save(sys.argv[1])
print(f'1KYB {dst.version} -> {src.version} at idx {dst.index:#x}, len {src.length:#x}')
