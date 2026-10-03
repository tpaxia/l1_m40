#!/usr/bin/env python3
"""Annotate the start of IPL / "ricerca governo di caricamento" in re/disassembly/m40-rom/m40rom-4.1.s:
  * 0x04ca — store the RAM bounds into the system area (seg 1)
  * 0x053a — helper: read back an MMU descriptor's base
  * 0x0590 — build the SYSTEM ENVIRONMENT config table (enumerate all 16 slots)
Replace semantics on the '! ADDR: bytes' markers; comment-only => bytes unchanged.
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- store RAM config into the system area (seg 1) ----
 0x04ca:"store RAM bounds into the system area (<<1>>0x0220..)",
 0x04ce:"<<1>>0x0226 = RAM end + 4",
 0x04d6:"<<1>>0x022a = RAM end",
 0x04e4:"read descriptor base (helper 0x53a)",
 0x04e6:"<<1>>0x0224 = base",
 0x04f8:"re-run RAM sizing for fresh bounds",
 0x0502:"<<1>>0x0220 = RAM start",
 0x0508:"<<1>>0x0222 = start base",
 # ---- MMU descriptor-read helper ----
 0x053a:"MMU SAR = rh1 (segment)",
 0x053e:"", 0x0540:"MMU DSC = 0",
 0x0544:"read descriptor base-high",
 0x0548:"read descriptor base-low",
 0x054c:"", 0x054e:"r0 = base-high + base-low",
 0x0550:"return",
 # ---- config-table build ----
 0x0590:"r7 = 0",
 0x0592:"rh1 = 0 -> slot high nibble 0",
 0x0594:"rr12 = &absent-handler (NMI if slot empty)",
 0x0598:"r2 = slot",
 0x059a:"", 0x059e:"table index = slot * 4",
 0x05a2:"rl1 = 0xFF -> the slot's type-ID register",
 0x05a4:"read board type-ID (absent -> NMI -> 0x5c6)",
 0x05a6:"slot 0xE0 (FDU/MFDU) special-case?",
 0x05aa:"", 0x05ac:"response = 0",
 0x05ae:"store type (XX) at <<1>>0x0230 + slot*4",
 0x05b4:"video board?",
 0x05b8:"", 0x05ba:"",
 0x05bc:"yes -> fetch its diag response (0x0996)",
 0x05be:"store response (YYYY) at +2",
 0x05c4:"",
 0x05c6:"[absent slot] type = 0xFFFF",
 0x05ce:"",
 0x05d0:"response = 0xFFFF",
 0x05d8:"next slot (high nibble += 1)",
 0x05dc:"loop over all 16 slots",
 # ---- IPL device search & load ----
 0x065c:"rr8 = &priority list (HDU-first, 0x6e6)",
 0x0660:"read ff41 (ISL switch)",
 0x0664:"ISL bit 1 set (HDU first)?",
 0x0666:"",
 0x0668:"clear -> FDU-first list (0x6e8)",
 0x066c:"slot index = 0",
 0x066e:"read config-table[slot] type",
 0x0674:"== the wanted device type (@rr8)?",
 0x0676:"no -> next slot",
 0x0678:"found this device: save state",
 0x067a:"", 0x067c:"", 0x0680:"record found slot",
 0x0686:"", 0x068a:"", 0x068c:"", 0x068e:"device index in the list",
 0x0692:"rr4 = &handler table (0x6ee)",
 0x0696:"rr6 = {param, handler} for this device type",
 0x069a:"", 0x069c:"", 0x069e:"", 0x06a0:"", 0x06a2:"", 0x06a4:"", 0x06aa:"", 0x06ac:"",
 0x06b6:"call the device's boot handler",
 0x06b8:"wait for the load result (<<1>>0x02fc)",
 0x06be:"",
 0x06c0:"", 0x06c2:"",
 0x06c4:"next slot (+4)",
 0x06c6:"all 16 slots done?",
 0x06c8:"",
 0x06ca:"next device type in the priority list",
 0x06cc:"end of list?",
 0x06d0:"",
 0x06d2:"boot succeeded? (<<1>>0x0308 == 0x5555)",
 0x06da:"no -> retry the whole search",
 0x06dc:"show 'waiting for IPL'",
 0x06de:"", 0x06e4:"retry",
}

# Comment blocks inserted before a data-table label.
LABEL_HDR = {
 "L_06e6":[
 "! IPL device-type priority lists (nome logico bytes).  The ISL switch (ff41",
 "! bit 1) picks the start: set -> 0x6e6 (E4=HDU first), clear -> 0x6e8 (E1=FDU",
 "! first).  E4=HDU  EF=GIPO/IEEE-488 (DCU)  E1=FDU  E0=MFDU  E6=STC.  00 = end.",],
 "L_06ee":[
 "! Per-device handler table: {param, handler-offset} x N, indexed by list",
 "! position.  handler 0x0eae = FDU/MFDU (floppy) loader; 0x1a5e = GIPO/HDU;",
 "! 0x1e2c = STC; 0xffff = HDU-direct (no handler -> via GIPO).",],
}

HEADER = {
 0x04ca:[
 "",
 "!------------------------------------------------------------------------------",
 "! Publish the memory map: store the discovered RAM start/end into the system",
 "! area in seg 1 (<<1>>0x0220..0x022a) for the OS/monitor to read.",
 "!------------------------------------------------------------------------------",],
 0x053a:[
 "",
 "!------------------------------------------------------------------------------",
 "! Helper: read back MMU descriptor rh1's base bytes (SAR=rh1, DSC=0) and return",
 "! their sum in r0 (a segment's physical base).",
 "!------------------------------------------------------------------------------",],
 0x0590:[
 "",
 "!==============================================================================",
 "! BUILD CONFIG TABLE  (\"ricerca governo di caricamento\" — enumerate the bus)",
 "! Scan all 16 slots; read each board's type-ID (nome logico) at register 0xFF;",
 "! store the type (XX) at <<1>>0x0230 + slot*4 and its diagnostic response (YYYY)",
 "! at +2.  An empty slot faults (NMI) -> 0xFFFF/0xFFFF.  This is the data behind",
 "! the \"NLS 30000 SYSTEM ENVIRONMENT\" screen (Collaudi 1-10).",
 "!==============================================================================",],
 0x065c:[
 "",
 "!==============================================================================",
 "! IPL DEVICE SEARCH & LOAD  (ricerca + test governo di caricamento, Collaudi 1-9)",
 "! Pick a boot-device priority list by the ISL switch (0xFF41 bit 1): set -> HDU",
 "! first (0x6e6), clear -> FDU first (0x6e8).  For each device type in the list,",
 "! scan the config table (<<1>>0x0230) for a matching board; when found, call its",
 "! handler (table 0x6ee) to load the boot program.  Retry until <<1>>0x0308=0x5555.",
 "!==============================================================================",],
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
        lbl = ln.strip().rstrip(':')
        if lbl in LABEL_HDR and LABEL_HDR[lbl][0] not in out[-6:]:
            out.extend(LABEL_HDR[lbl])
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
