#!/usr/bin/env python3
"""Trial HD restore: write DKC backups of data sets FF and 80 straight onto a
copy of the formatted + LDHSEL WREN2 image, and add the SSID "1EX" entry that
JX24 would create.

Layout evidence (all from the disks, see OSLEM_STATUS.md trial-restore notes):
- SSID sector = LBA 8 (copy LBA 11); header +8 first free sector (1-based),
  +0x0c free count; entries at +0x40, 32 bytes each (JX24 at 0x2ba).
- JX24 entry: "1EX0000 ", start, size, start, size, start, 00000002.
- HDU1ST24 / JH24: physical LBA = volume sector n + start - 2, so backup
  index i (volume sector i+1) goes to LBA start - 1 + i.
- Data-set TOC in FF: FF at volume sector 1 (len 0xF83), 80 at 0xF84
  (len 0x372D).
- Backup volumes carry 3848 data sectors each (cyl 1-74); the track-0 count
  field is data sectors + 1.
"""
import struct, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]   # the project folder
sys.path.insert(0, str(ROOT / 'tools'))
from l1disk import L1Disk

D = str(ROOT) + '/reference/Disk Images (Stefano Marinelli + others)/Ripristino_HD/'
raw_in, raw_out = sys.argv[1], sys.argv[2]
MNR = int(sys.argv[3], 16) if len(sys.argv) > 3 else 0x3EA00

def volume(name):
    d = L1Disk(D + name + '.imd')
    t0 = d.track0()
    count = struct.unpack('>I', t0[0x12c:0x130])[0] - 1
    return d.read(0, count * 256)

ff = volume('ff1') + volume('ff2')
d80 = b''.join(volume(n) for n in ('80-1', '80-2', '80-3', '80-4'))
assert len(ff) == 0xF83 * 256 and len(d80) == 0x372D * 256

hd = bytearray(open(raw_in, 'rb').read())
ssid = 8 * 256
assert hd[ssid:ssid + 4] == b'SSID'
start, free = struct.unpack('>II', hd[ssid + 8:ssid + 16])
assert (start, free) == (17, 0x3FD70)
ent = ssid + 0x40
assert hd[ent] == 0x20
hd[ent:ent + 32] = b'1EX0000 ' + struct.pack('>IIIIII', start, MNR, start, MNR, start, 2)
hd[ssid + 8:ssid + 16] = struct.pack('>II', start + MNR, free - MNR)
hd[11 * 256:12 * 256] = hd[ssid:ssid + 256]          # SSID copy

def put(vsec, data):
    lba = start - 2 + vsec
    hd[lba * 256:lba * 256 + len(data)] = data
    return lba

print('FF  -> LBA %d..%d' % (put(1, ff), 15 + 0xF83))
print('80  -> LBA %d..%d' % (put(0xF84, d80), 15 + 0xF84 + 0x372D - 1))
open(raw_out, 'wb').write(hd)
