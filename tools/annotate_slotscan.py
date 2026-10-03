#!/usr/bin/env python3
"""Annotate the backplane slot scans in re/disassembly/m40-rom/m40rom-4.1.s:
  * preliminary board scan  (0x150-0x1b6) — board-type dispatch + early blank
  * video slot scan         (0x27c-0x2a4) — init/test every video board
Both walk all 16 device-select slots; an EMPTY slot has no READY, faults, and
the NMI handler (0x00ce) resumes at rr12 = the next-slot address.

Replace semantics on the '! ADDR: bytes' markers; comment-only => bytes unchanged.
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- preliminary board scan (0x150-0x1b6) ----
 0x0150:"rr6 = 0",
 0x0152:"rr12 = &next-slot  <- NMI resume target if this slot is empty",
 0x0156:"r1 = 0  -> device-select high byte starts at 0x00",
 0x0158:"r1 = (slot<<8) | 0x0FFF  -> the board's ID port",
 0x015c:"read board ID  (empty slot: no READY -> NMI -> rr12 = next slot)",
 0x015e:"ID == 0xF0 ?",
 0x0162:"",
 0x0164:"reg-select 0x81", 0x0166:"",
 0x0168:"write 0x07 to reg 0x81",
 0x016a:"ID == 0xFE (video) ?",
 0x016e:"not video -> try line board",
 # inline blank-init of a video board found during the scan
 0x0170:"-- video: blank it for now --",
 0x0172:"reg-select 0x01", 0x0174:"reg 0x01 = 0x03",
 0x0176:"reg-select 0x41 (CRTC address)", 0x0178:"select CRTC R6 (rows displayed)",
 0x017a:"", 0x017c:"reg-select 0x43 (CRTC data)", 0x017e:"R6 = 0 -> blank",
 0x0180:"reg-select 0x41", 0x0182:"select CRTC R1 (cols displayed)", 0x0184:"",
 0x0186:"reg-select 0x43", 0x0188:"R1 = 0 -> blank",
 0x018a:"clear indicator regs 0x65..0x67 (r6=0)",
 0x018c:"reg 0x65 + i", 0x018e:"", 0x0190:"", 0x0196:"", 0x0198:"", 0x019a:"", 0x019e:"",
 0x01a0:"mask ID with 0xF1",
 0x01a4:"== 0xD0 (line-board family) ?",
 0x01a8:"",
 0x01aa:"reg-select 0xB1", 0x01ac:"",
 0x01ae:"write 0x01 to reg 0xB1",
 0x01b0:"rh7 = 0xFF  <- flag: line board present (later skips the ROM checksum)",
 0x01b2:"next slot: high byte += 0x10",
 0x01b6:"loop until it carries past 0xF0  (16 slots scanned)",
 # ---- video slot scan (0x27c-0x2a4) ----
 0x027c:"r7 = 0  <- video framebuffer window offset",
 0x027e:"r1 = 0  -> device-select high byte starts at 0x00",
 0x0280:"rr12 = &next-slot  <- NMI resume target if this slot is empty",
 0x0284:"r1 = (slot<<8) | 0x0FFF  -> board ID port",
 0x0288:"read board ID  (empty slot -> NMI -> rr12 = next slot)",
 0x028a:"ID == 0xFE (video) ?",
 0x028e:"no -> next slot",
 0x0290:"rr10 = return (0x29c)",
 0x0294:"rr12 = return too (so an NMI mid-init also unwinds cleanly)",
 0x0296:"init + self-test this video controller  (r1=port, r7=window)",
 0x029c:"advance framebuffer window +0x2000 for the next video board",
 0x02a0:"next slot: high byte += 0x10",
 0x02a4:"loop until it carries past 0xF0  (all 16 slots)",
 # ---- 0xFF80..0xFF8F DMA/interrupt controller init (NVI-paced) ----
 0x02a6:"rr12 = NVI resume target (next group)",
 0x02aa:"write all 16 controller regs 0xFF80..0xFF8F (data = don't-care r0)",
 0x02be:"enable NVI...", 0x02ec:"", 0x02f0:"spin until the device raises NVI -> next group",
 0x02e8:"rr12 = next group",
 0x02fe:"", 0x0300:"spin for NVI",
 0x030e:"", 0x0310:"spin for NVI",
 0x031e:"", 0x0320:"spin for NVI",
 0x0322:"final re-write of 0xFF80..0xFF83",
}

HEADER = {
 0x027c:[
 "",
 "!==============================================================================",
 "! BACKPLANE SLOT SCAN — video pass",
 "! Walk all 16 device-select slots (high byte 0x00,0x10,...,0xF0). Each board",
 "! answers its logical-name ID byte at I/O port (slot<<8)|0x0FFF. An EMPTY slot",
 "! has no READY, so the read faults and the NMI handler (0x00ce) resumes at",
 "! rr12 = the next slot. Every video board (ID 0xFE) is initialised and",
 "! self-tested (0x0bc6) and handed the next 0x2000-byte framebuffer window (r7).",
 "!==============================================================================",],
 0x02a6:[
 "",
 "!------------------------------------------------------------------------------",
 "! Initialise the UC DMA/interrupt controller (0xFF80..0xFF8F, in the MB15652",
 "! gate array).  Writes ALL 16 registers (the data = leftover r0, a don't-care)",
 "! and hand-shakes on the NVI the device raises: `ei nvi`, spin (`jr self`), and",
 "! the NVI handler (0x00f2) resumes at the next rr12 target.  This is the device",
 "! the FDU transfer later strobes via 0xFF84/0xFF8C; it does NOT load an address.",
 "!------------------------------------------------------------------------------",],
}

def insert_header(out, block):
    key = max(block, key=len) if block else ""
    if key and key in out[-len(block)-6:]:
        return
    labels = []
    while out and re.match(r'L_[0-9a-f]+:$', out[-1].strip()):
        labels.insert(0, out.pop())
    out.extend(block); out.extend(labels)

def main():
    lines = open(PATH).read().split("\n")
    out = []
    for ln in lines:
        m = re.search(r'! ([0-9a-f]{4}): ([0-9a-f]+)', ln)
        if m:
            addr = int(m.group(1), 16)
            if addr in HEADER:
                insert_header(out, HEADER[addr])
            if addr in NOTE:
                ln = ln[:m.end()] + ("   " + NOTE[addr] if NOTE[addr] else "")
        out.append(ln)
    open(PATH, "w").write("\n".join(out))
    print("annotated", PATH)

if __name__ == "__main__":
    main()
