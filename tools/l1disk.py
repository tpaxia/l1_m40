#!/usr/bin/env python3
"""Sector-level access to Olivetti L1 8-inch .IMD images.

Track 0 is FM (26 x 128); data tracks are MFM, 26 sectors x 256 bytes per
side. OS descriptors and library directories address data sectors by a
linear index: index = (cyl - 1) * 52 + head * 26 + sector_offset, where
sector_offset is the 0-based sector position on the track (sector numbers
on these disks are 1..26).
"""
import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from imd import read_imd  # noqa: E402


class L1Disk:
    def __init__(self, path):
        raw = open(path, 'rb').read()
        self.header = raw[:raw.index(0x1A) + 1]
        self.tracks = read_imd(path)
        self.by_ch = {}
        for t in self.tracks:
            mode, cyl, head, nsec, ssz, smap, secs = t
            self.by_ch[(cyl, head)] = t

    def _loc(self, index):
        cyl = 1 + index // 52
        head = (index % 52) // 26
        sec = index % 26
        t = self.by_ch[(cyl, head)]
        smin = min(t[5])
        return t, smin + sec

    def read(self, index, length):
        out = bytearray()
        while len(out) < length:
            t, s = self._loc(index)
            out += t[6][s]
            index += 1
        return bytes(out[:length])

    def write(self, index, data):
        pos = 0
        while pos < len(data):
            t, s = self._loc(index)
            old = bytearray(t[6][s])
            chunk = data[pos:pos + len(old)]
            old[:len(chunk)] = chunk
            t[6][s] = bytes(old)
            pos += len(old)
            index += 1

    def track0(self):
        out = bytearray()
        for head in (0, 1):
            t = self.by_ch.get((0, head))
            if t:
                for s in sorted(t[6]):
                    out += t[6][s]
        return bytes(out)

    def set_track0(self, data):
        pos = 0
        for head in (0, 1):
            t = self.by_ch.get((0, head))
            if not t:
                continue
            for s in sorted(t[6]):
                n = len(t[6][s])
                t[6][s] = bytes(data[pos:pos + n])
                pos += n

    def save(self, path):
        out = bytearray(self.header)
        for mode, cyl, head, nsec, ssz, smap, secs in self.tracks:
            sizecode = {128: 0, 256: 1, 512: 2, 1024: 3}[ssz]
            out += bytes([mode, cyl, head, nsec, sizecode])
            out += bytes(smap)
            for s in smap:
                d = secs[s]
                if d == bytes([d[0]]) * len(d):
                    out += bytes([2, d[0]])
                else:
                    out += bytes([1]) + d
        open(path, 'wb').write(out)
