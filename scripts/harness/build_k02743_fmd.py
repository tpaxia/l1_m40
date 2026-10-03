#!/usr/bin/env python3
"""K02743 with the resident floppy driver swapped: the library directory entry
named 0FMU (which the active J0XP configuration loads) is pointed at a 0FMD
module instead. SRC=patc uses the 0FMD PATC copy on K02743 (sector 0x909,
not in its directory); SRC=allres copies ALL_RESIDENT's 0FMD 02.9 into K02743
over the old 0FMU sectors when it fits."""
import struct, sys
sys.path.insert(0, '/Users/paxia/Projects/L1_M30_M40/tools')
from l1disk import L1Disk
K = L1Disk('/private/tmp/k02743-probe/boot.imd')
d = bytearray(K.read(0, 8 * 256))
count = struct.unpack('>H', d[4:6])[0]
i = next(i for i in range(0, count * 8, 8) if d[i:i + 4] == b'0FMU')
old_start, old_len = struct.unpack('>HH', d[i + 4:i + 8])
src = sys.argv[2] if len(sys.argv) > 2 else 'patc'
if src == 'patc':
    hdr = K.read(0x909, 16)
    assert hdr[:8] == b'0FMDPATC', hdr
    new_start, new_len = 0x909 + 1, struct.unpack('>H', hdr[10:12])[0]
else:
    A = L1Disk('/Users/paxia/Projects/L1_M30_M40/reference/Disk Images/BCOS_II_3.3_FD_ALL_RESIDENT.imd')
    hdr = A.read(0x2a, 16); assert hdr[:4] == b'0FMD', hdr
    new_len = struct.unpack('>H', hdr[10:12])[0]
    assert new_len <= old_len, (hex(new_len), hex(old_len))
    nsec = 1 + (new_len + 255) // 256
    K.write(old_start - 1, A.read(0x2a, nsec * 256))
    new_start = old_start
d[i + 4:i + 8] = struct.pack('>HH', new_start, new_len)
K.write(0, bytes(d))
K.save(sys.argv[1])
print(f'0FMU entry {old_start:#x}+{old_len:#x} -> {new_start:#x}+{new_len:#x} ({src})')
