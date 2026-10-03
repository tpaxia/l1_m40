#!/usr/bin/env python3
"""Annotate re/disassembly/dcos-bootloader/boot.s -- the SYS0 first-stage bootloader (track 0 of an L1
DCOS 8.4 diagnostic disk; code+tables byte-identical on every disk).

The block is read by the ROM IPL into the <<60>> buffer, then MMU descriptor 25
is aliased onto the same physical memory and the block runs at <<25>>0x000c.
It issues ONE device-load command (a 9-byte descriptor at <<25>>0x0114) to load
the Diagnostic Monitor to <<25>>0x0200, retrying until the FDC status is clean,
then jumps to the Monitor at <<25>>0x0234.

The loader delegates the actual sector read to a ROM (segment-0) routine, chosen
by the booted device's type via a double indirection:
    type -> device-type table (@0x00dc) -> reversed index -> pointer table
    (@0x00e6) -> ROM seg-0 vector offset -> ROM[offset] = routine entry.
For FDU/MFDU (E1/E0) that routine is ROM <<0>>0x1642.

Idempotent: strips prior ' ;; ' notes and re-inserts headers only if absent.
Markers keyed on the '! ADDR: ...' comment mkasm emits on every code/repair line.
"""
import os, re
PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "re", "disassembly", "dcos-bootloader", "boot.s")

BANNER = [
 "! =============================================================================",
 "! SYS0 FIRST-STAGE BOOTLOADER  --  L1 DCOS 8.4 diagnostic disk, track 0",
 "! -----------------------------------------------------------------------------",
 "! Loaded by the ROM IPL: track 0 (26 x 128B) is read into the <<60>> buffer,",
 "! the \"SYS0\" magic is checked, MMU descriptor 25 is aliased onto that buffer,",
 "! and control jumps to the header entry point <<25>>0x000c (this file).",
 "! The code + tables below (first 512 bytes) are identical on all 9 disks; the",
 "! rest of track 0 is disk volume data and is not part of the loader.",
 "!",
 "! What it does: issue ONE load command (9-byte descriptor @0x0114) to read the",
 "! Diagnostic Monitor to <<25>>0x0200 -- retrying on error -- then jp to the",
 "! Monitor entry <<25>>0x0234.  The sector read itself is done by a ROM driver",
 "! routine (segment 0), reached by a type -> table -> ROM-vector indirection.",
 "! =============================================================================",
]

# Enrich the '! ---- 0xAAAA .. 0xBBBB  (kind) ----' region separators.
REGIONNOTE = {
 0x0000: "\"SYS0\" magic (0x53595330)",
 0x0004: "block header: entry <<25>>0x000c (0x9900000c) + flags longword 0x00000001",
 0x00dc: "DEVICE-TYPE TABLE (10 bytes) -- E4 E0 66 E6 E7 E1 60 61 62 65",
 0x00e6: "LOADER-POINTER TABLE (10 words) -- ROM seg-0 vector offsets, REVERSED index",
 0x00fa: "scratch: saved boot marker (0xcccc placeholder) + fill",
 0x0110: "MONITOR ENTRY <<25>>0x0234 (0x99000234) -- jp target after the load",
 0x0114: "LOAD DESCRIPTOR (9 bytes) -- 99 00 02 00 / 0e 00 / 01 00 01",
}

HEADER = {
 0x000c:[
 "",
 "! ---- entry: save the boot marker, load the Monitor, jump to it ----------------",],
 0x0022:[
 "",
 "! ---- loader dispatch (called with rr2 = &descriptor) --------------------------",
 "! Read the config-table TYPE for the booted slot (the ROM's own enumeration, not",
 "! a re-scan), pick the ROM device-load routine for that type, and call it.  Loop",
 "! = retry-on-error: on a bad FDC status, run the recovery routine and try again;",
 "! rr2 (the descriptor) never advances, so this is one load command, not a list.",],
 0x004e:[
 "! Find the type in the device-type table, then fetch its loader from the pointer",
 "! table.  cpirb counts the counter DOWN, so a hit at device index i leaves",
 "! r6 = 9-i: the pointer table is therefore indexed in REVERSE (offset 2*(9-i)).",
 "! The pointer word is a segment-0 (ROM) address whose contents is the routine",
 "! entry -- i.e. the loader lives in the boot ROM (FDU/MFDU E0/E1 -> <<0>>0x1642).",],
 0x0078:[
 "",
 "! ---- removable devices (types 60/61/65/66): pre-translate the start LBA -------",
 "! Before the common dispatch, convert the descriptor's logical start block to a",
 "! cylinder/head/sector using the drive geometry passed by the ROM, then rejoin",
 "! the dispatch at 0x004e.",],
 0x00aa:[
 "",
 "! ---- LBA -> CHS ---------------------------------------------------------------",
 "! rr4 = logical block; divide by sectors-per-track (rl7 hi) for the track, then",
 "! by heads (rl7 lo) for cylinder/head; leaves sector in rl5, cyl/head packed.",],
}

# Inline notes appended as '  ;; <note>' after the '! ADDR: ...' comment.
NOTE = {
 0x000c:"r2 = boot-success marker (<<1>>0x0308 = 0x5555, set by the ROM IPL)",
 0x0012:"save the marker to scratch <<25>>0x00fa  (ldr, kept as .word)",
 0x0016:"rr2 = &load-descriptor  (<<25>>0x0114)",
 0x001a:"call the loader (retries until the FDC status is clean)",
 0x001c:"rr2 = Monitor entry <<25>>0x0234  (longword @0x0110; ldrl kept as .word)",
 0x0020:"jump into the loaded Diagnostic Monitor",
 0x0022:"rh4 = IPL slot  (<<1>>0x0302, from the ROM) -- no bus re-scan",
 0x0028:"r4 = slot * 4  (config-table stride)",
 0x0030:"rl7 = config-table[slot].TYPE  (<<1>>0x0230) -- the ROM's SYSTEM ENVIRONMENT table",
 0x0036:"removable types 60/61/65/66 -> pre-translate LBA at 0x0078 first",
 0x004e:"rr4 = device-type table (0x00dc)",
 0x0052:"10 entries",
 0x0054:"scan for the booted TYPE; counter counts down (see header)",
 0x0058:"TYPE not in table -> hang (unsupported boot device)",
 0x005a:"r6 = 2*(9-index): reversed word index into the pointer table",
 0x005c:"rr4 = loader-pointer table (0x00e6)",
 0x0060:"r5 = pointer word = a segment-0 (ROM) vector offset",
 0x0064:"segment 0 = the boot ROM",
 0x0068:"r5 = ROM[ptr] = device-load routine entry (FDU/MFDU E0/E1 = 0x1642)",
 0x006a:"call the ROM loader (rr2 = descriptor); status returned in r7",
 0x006c:"r7 = FDC result status (<<1>>0x034a)",
 0x006e:"clean -> return, then jp Monitor",
 0x0070:"else r5 = ROM[0x0072] = recovery routine (0x0d10)",
 0x0074:"reset/recalibrate the governo",
 0x0076:"retry the whole load",
 0x0078:"save the type",
 0x007a:"r6 = geometry: sectors/track (<<1>>0x030c)",
 0x0080:"rh7 = heads (<<1>>0x030e)",
 0x0086:"rl7 = ? (<<1>>0x0306)",
 0x008c:"descriptor[10] (start-block hi)",
 0x0090:"marker 0xa8 -> already translated?",
 0x009c:"rr4 = descriptor start-block longword",
 0x00a0:"translate LBA -> CHS",
 0x00a2:"write the CHS back into the descriptor",
 0x00a8:"rejoin the common dispatch",
}

# Comment blocks placed just before a data-table label.
LABEL_HDR = {
 "L_00dc":[
 "! device index:  0:E4  1:E0  2:66  3:E6  4:E7  5:E1  6:60  7:61  8:62  9:65",],
 "L_00e6":[
 "! reversed: pointer for device index i is the word at offset 2*(9-i).  Values",
 "! are segment-0 offsets; ROM[value] holds the routine entry.  In ROM 4.1:",
 "!   E0/E1 (FDU/MFDU) -> 0x6a -> 0x1642     E6/E7 (STC)  -> 0x7a -> 0x1e2c",
 "!   62 (MTU)         -> 0xa2 -> 0x01c0     E4/66/60/61/65 (HDU) unsupported (16K 6.0)",],
 "L_0114":[
 "! 99 00 02 00 = dest <<25>>0x0200   0e 00 = length 0x0e00 (3584 B = 14x256B sec)",
 "! 01 00 01    = start C/H/S params.  Copied (9 bytes) to <<1>>0x0366 by the ROM",
 "! loader, which reads the run into <<25>>0x0200.  Monitor entry <<25>>0x0234 lies",
 "! inside this image.  (Bytes past 0x011c here are a table used by the Monitor,",
 "! not by this first stage.)",],
}

def strip_note(ln):
    return re.sub(r'\s*;;.*$', '', ln)

def insert_block(out, block):
    """Append a header block unless its last non-empty line is already present."""
    key = block[-1]
    if key in out[-len(block)-4:]:
        return
    out.extend(block)

def main():
    lines = open(PATH).read().split("\n")
    out = []
    # top banner after the '.org 0' line
    for ln in lines:
        # region separators
        mr = re.match(r'! ---- 0x([0-9a-f]{4}) \.\.', ln)
        if mr:
            addr = int(mr.group(1), 16)
            ln = strip_note(ln)
            if addr in REGIONNOTE:
                ln = ln + "   ;; " + REGIONNOTE[addr]
        # label headers
        lbl = ln.strip().rstrip(':')
        if lbl in LABEL_HDR:
            insert_block(out, LABEL_HDR[lbl])
        # code / repair line notes + headers
        m = re.search(r'! ([0-9a-f]{4}):', ln)
        if m:
            addr = int(m.group(1), 16)
            if addr in HEADER:
                insert_block(out, HEADER[addr])
            ln = strip_note(ln)
            if addr in NOTE:
                ln = ln + "   ;; " + NOTE[addr]
        out.append(ln)
        if ln.strip() == ".org\t0" or ln.strip() == ".org 0":
            if BANNER[0] not in out[-6:] and BANNER[0] not in lines[:8]:
                out.append("")
                out.extend(BANNER)
    open(PATH, "w").write("\n".join(out))
    print("annotated", PATH)

if __name__ == "__main__":
    main()
