#!/usr/bin/env python3
"""Rename library directory entries whose name contains '#' (Olivetti '£',
not typeable at the OX prompt under MAME) to the same name with 'X'.
Usage: alias_pound.py IMG_IN IMG_OUT NAME [NAME ...]   e.g. TOC# DKC#"""
import sys
sys.path.insert(0, '/Users/paxia/Projects/L1_M30_M40/tools')
from l1disk import L1Disk
from l1lib import Image, directory_index, read_directory
img = Image(sys.argv[1]); d = L1Disk(sys.argv[1])
di = directory_index(img); head, ents = read_directory(img, di)
nsec = (len(ents) * 8 + 255) // 256
dirb = bytearray(d.read(di, nsec * 256))
for name in sys.argv[3:]:
    hits = [i for i, e in enumerate(ents) if e[0] == name]
    assert hits, name
    new = name.replace('#', 'X').encode()
    assert not any(e[0] == new.decode() for e in ents), new
    for i in hits:
        dirb[i * 8:i * 8 + 4] = new
    print(f'{name} -> {new.decode()} ({len(hits)} entr{"y" if len(hits) == 1 else "ies"})')
d.write(di, bytes(dirb)); d.save(sys.argv[2])
