#!/usr/bin/env python3
"""Minimal ImageDisk (.IMD) reader: extract sector data as a flat image.

Usage:
  imd.py <disk.imd> tracks           # list track table
  imd.py <disk.imd> extract <out.bin> [ntracks]   # concat logical sectors,
                                                   # ordered by sector-number map
The L1 diagnostic disks are 8" SD track 0 (26 sec x 128) then DD data tracks.
We extract sectors in ascending sector-number order per track (physical order
via the sector map), which is the on-disk logical order the loader reads.
"""
import sys, struct

MODES = {0:"500k FM",1:"300k FM",2:"250k FM",3:"500k MFM",4:"300k MFM",5:"250k MFM"}

def read_imd(path):
    data = open(path,"rb").read()
    i = data.index(0x1A)+1           # skip ASCII header + 0x1A
    tracks=[]
    while i < len(data):
        mode,cyl,head,nsec,ssz = data[i:i+5]
        i+=5
        secsize = 128<<ssz
        smap = list(data[i:i+nsec]); i+=nsec
        cmap = hmap = None
        if head & 0x80: cmap=list(data[i:i+nsec]); i+=nsec
        if head & 0x40: hmap=list(data[i:i+nsec]); i+=nsec
        head &= 0x3f
        secs={}
        for s in range(nsec):
            typ=data[i]; i+=1
            if typ==0: sd=b"\x00"*secsize
            elif typ in (1,3,5,7): sd=data[i:i+secsize]; i+=secsize
            elif typ in (2,4,6,8): sd=bytes([data[i]])*secsize; i+=1
            else: raise ValueError("bad sector type %d"%typ)
            secs[smap[s]]=sd
        tracks.append((mode,cyl,head,nsec,secsize,smap,secs))
    return tracks

def main():
    path=sys.argv[1]; cmd=sys.argv[2]
    tracks=read_imd(path)
    if cmd=="tracks":
        for t,(mode,cyl,head,nsec,ssz,smap,secs) in enumerate(tracks):
            print("trk %3d  c=%2d h=%d  %2d sec x %4d  %-9s  sec %d..%d"%
                  (t,cyl,head,nsec,ssz,MODES.get(mode,"?"),min(smap),max(smap)))
    elif cmd=="extract":
        out=sys.argv[3]; n=int(sys.argv[4]) if len(sys.argv)>4 else len(tracks)
        buf=bytearray()
        for (mode,cyl,head,nsec,ssz,smap,secs) in tracks[:n]:
            for s in sorted(secs): buf+=secs[s]
        open(out,"wb").write(buf)
        print("wrote %s: %d bytes (%d tracks)"%(out,len(buf),n))

if __name__=="__main__": main()
