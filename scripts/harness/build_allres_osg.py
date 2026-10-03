#!/usr/bin/env python3
"""ALL_RESIDENT + OSG£ (OSG#, OSG1-3, SMV#, SMV0, PMV0, PMV1, DIRE) copied from K02743.
OSG# opens DIRE, SMV0, PMV0 and PMV1 by name and exits silently if DIRE is missing.

ALL_RESIDENT library directory: data sector 0, 8-byte entries (name, 1-based
header sector, data length). Entry 0 "RE33" holds the entry count. Modules go
to the blank cylinder 74 (data index 3796..3847; 75-76 hold "@" fill) as header + data sectors.
"""
import struct, sys
sys.path.insert(0, '/Users/paxia/Projects/L1_M30_M40/tools')
from l1disk import L1Disk

ROOT = '/Users/paxia/Projects/L1_M30_M40/'
A = L1Disk(ROOT + 'reference/Disk Images/BCOS_II_3.3_FD_ALL_RESIDENT.imd')
K = L1Disk('/private/tmp/k02743-probe/boot.imd')
MODS = {'OSG#': 0x2d6, 'OSG1': 0x2e5, 'OSG2': 0x2e6, 'OSG3': 0x2e7,
        'SMV#': 0x31c, 'SMV0': 0x31e, 'PMV0': 0x2fa, 'PMV1': 0x2fc,
        'DIRE': 0x48c}
# Directory name for OSG# (the £/# character is hard to type in MAME).
ALIAS = {'OSG#': 'OSGX'}

free = (74 - 1) * 52
assert len(set(A.read(free, 52 * 256))) == 1, 'cylinder 74 not blank'
d = bytearray(A.read(0, 4 * 256))
count = struct.unpack('>H', d[4:6])[0]
ents = [d[i:i + 8] for i in range(0, count * 8, 8)]
assert ents[0][:4] == b'RE33' and ents[-3][:4] == b'+DIR'
names = {bytes(e[:4]) for e in ents}
new = []
idx = free
for name, src in MODS.items():
    assert name.encode('latin1') not in names, name
    hdr = K.read(src, 256)
    assert hdr[:4] == name.encode('latin1'), (name, hdr[:8])
    length = struct.unpack('>H', hdr[10:12])[0]
    nsec = 1 + (length + 255) // 256
    A.write(idx, K.read(src, nsec * 256))
    new.append(ALIAS.get(name, name).encode('latin1') + struct.pack('>HH', idx + 1, length))
    print(f'{name} {hdr[:8].decode("latin1")} -> index {idx:#x} ({nsec} sectors, len {length:#x})')
    idx += nsec
    assert idx <= free + 52
ents = ents[:-3] + new + ents[-3:]
d[:len(ents) * 8] = b''.join(bytes(e) for e in ents)
d[4:6] = struct.pack('>H', len(ents))
assert len(ents) * 8 <= 0x400
A.write(0, bytes(d))
# Optional MVO quad (track-0 OS descriptor, both copies), e.g. --mvo 0440-0540-1000-3000
if '--mvo' in sys.argv:
    q = bytes.fromhex(sys.argv[sys.argv.index('--mvo') + 1].replace('-', ''))
    t0 = bytearray(A.track0())
    for base in (0x80, 0x100):
        assert t0[base:base + 4] == bytes([4, 0x40, 5, 0x40])
        t0[base:base + 8] = q
    A.set_track0(bytes(t0))
    print('MVO', q.hex())
A.save(sys.argv[1])
print('entries', count, '->', len(ents), 'saved', sys.argv[1])
