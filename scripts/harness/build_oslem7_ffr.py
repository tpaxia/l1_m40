#!/usr/bin/env python3
"""HACK: oslem7+ copy with sub-module(s) inside its H65R/H65I containers
replaced by K02743's versions (default FF#R from HDIR into H65R).
Usage: build_oslem7_ffr.py OUT [SUB ...]   e.g. FF#R FF#I
The sub-module span (to the next sub-module) must fit; the rest is zeroed."""
import sys
sys.path.insert(0, '/Users/paxia/Projects/L1_M30_M40/tools')
from l1disk import L1Disk
from l1lib import Image
OS = '/Users/paxia/Projects/L1_M30_M40/reference/Disk Images (Stefano Marinelli + others)/Ripristino_HD/oslem7+.imd'
KP = '/private/tmp/k02743-probe/boot.imd'
o, k = Image(OS), Image(KP)
d = L1Disk(OS)
PAIRS = {'R': ('H65R', 'HDIR'), 'I': ('H65I', 'HDII')}

def span(img, cont, name):
    c = [h for h in img.headers() if h.name == cont][-1]
    offs = c.sub_offsets()
    end = 0x20 + c.length
    for i, off in enumerate(offs):
        s = c.subs()[i]
        if s.name == name:
            nxt = offs[i + 1] if i + 1 < len(offs) else end
            return c, off, nxt - off, s
    raise SystemExit(f'{name} not in {cont}')

for name in sys.argv[2:] or ['FF#R']:
    oc, ko = PAIRS[name[-1]]
    c, off, n, s = span(o, oc, name)
    kc, koff, kn, ks = span(k, ko, name)
    assert kn <= n, (name, hex(kn), hex(n))
    flat = c.offset + off
    blob = k.data[kc.offset + koff:kc.offset + koff + kn] + bytes(n - kn)
    d.write(flat // 256, d.read(flat // 256, ((flat % 256) + n + 255) // 256 * 256)[:flat % 256] + blob
            + d.read(flat // 256, ((flat % 256) + n + 255) // 256 * 256)[flat % 256 + n:])
    print(f'{oc}/{name}: {s.version} -> {ks.version} ({kn:#x} of {n:#x} bytes) at flat {flat:#x}')
d.save(sys.argv[1])
