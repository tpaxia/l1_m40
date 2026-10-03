#!/usr/bin/env python3
"""HACK/diagnostic: oslem7+ copy whose track-0 boot descriptor loads other
RTS/INIT containers. Usage: build_oslem7_containers.py OUT RTSNAME INITNAME
(e.g. HE4R HE4I). Load segments/addresses are kept."""
import struct, sys
sys.path.insert(0, '/Users/paxia/Projects/L1_M30_M40/tools')
from l1disk import L1Disk
from l1lib import Image
OS = '/Users/paxia/Projects/L1_M30_M40/reference/Disk Images (Stefano Marinelli + others)/Ripristino_HD/oslem7+.imd'
img = Image(OS)
d = L1Disk(OS)
t0 = bytearray(d.track0())
def find(name):
    hs = [h for h in img.headers() if h.name == name]
    assert hs, name
    return hs[-1]
for slot, name in ((0xc0, sys.argv[2]), (0xd0, sys.argv[3])):
    h = find(name)
    cyl, rem = h.index // 52 + 1, h.index % 52
    t0[slot + 8:slot + 10] = struct.pack('>H', h.length)
    t0[slot + 10:slot + 13] = bytes([cyl, rem // 26, rem % 26 + 1])
    print(f'slot +{slot:02x} -> {h.name}{h.version} idx {h.index:#x} len {h.length:#x}')
d.set_track0(bytes(t0))
d.save(sys.argv[1])
