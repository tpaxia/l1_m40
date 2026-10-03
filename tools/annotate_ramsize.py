#!/usr/bin/env python3
"""Annotate the RAM-sizing routine (0x0a94) and finish the NMI handler (0x00ce),
which are two halves of one mechanism: RAM presence is probed by reading through
a scratch MMU window; absent RAM has no READY -> NMI -> the handler resumes the
probe loop at rr12 (its checkpoints 0xaa8 / 0xaea).

Replace semantics on the '! ADDR: bytes' markers; comment-only => bytes unchanged.
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- NMI handler = RAM-probe fault handler (0x00ce) ----
 0x00ce:"pop the 8-byte NMI frame (resume, don't iret)",
 0x00d0:"in the RAM-sizing probe loop? (rr12 low = checkpoint 0xaa8)",
 0x00d4:"",
 0x00d6:"...or the 'record end' checkpoint (0xaea)?",
 0x00da:"neither -> generic NMI: just clear source and resume",
 0x00dc:"read NMI source (0xFF41)",
 0x00e0:"clear it",
 0x00e4:"NMI-source bit 6 set?",
 0x00e6:"set -> location responded: record it (0x0ada)",
 0x00ec:"clear NMI source",
 0x00f0:"resume the probe at rr12 (= skip this window)",
 0x00f2:"NVI handler: pop frame and resume at rr12",
 0x00f4:"",
 # ---- RAM sizing (0x0a94) ----
 0x0a94:"reset SP",
 0x0a98:"r1 = 0x0100 -> rh1 = physical bank #1 (descriptor base-high)",
 0x0a9c:"rr12 = &0xaa8  <- NMI resume = 'skip this window' checkpoint",
 0x0aa0:"rr2 = <<60>>0xc000 : segment 60 is the RAM-probe scratch window",
 0x0aa6:"rh0 = 0  -> 'RAM start not found yet'",
 0x0aa8:"[probe loop] offset += 0x4000 (16 KB step)",
 0x0aac:"no wrap -> probe within the current bank",
 0x0aae:"bank exhausted: rh1++ (next 64 KB physical bank)",
 0x0ab0:"reached bank 0xF0 (top of scanned space)?",
 0x0ab4:"no -> remap descriptor 60 to this bank",
 0x0ab6:"any RAM found so far?",
 0x0ab8:"yes -> go record the end",
 0x0aba:"no RAM at all -> error",
 0x0abc:"SAR = 0x3C = descriptor 60",
 0x0abe:"MMU SAR = 60",
 0x0ac2:"MMU DSC = 0 (start at base-high byte)",
 0x0ac6:"descriptor base-high = rh1 (physical bank)",
 0x0aca:"descriptor base-low = 0",
 0x0ace:"",
 0x0ad0:"descriptor limit = 0xFF (64 KB)",
 0x0ad4:"descriptor attr = 0  -> descriptor 60 now maps bank rh1 into <<60>>",
 0x0ad8:"[probe] read the window (absent RAM: no READY -> NMI -> rr12)",
 0x0ada:"already scanning for the end?",
 0x0adc:"yes -> keep scanning",
 0x0ade:"rh0 = 1 -> 'RAM start found'",
 0x0ae0:"record start bank  (r4)",
 0x0ae2:"record start offset (r5)",
 0x0ae4:"rr12 = &0xaea  <- NMI resume now = 'record end' checkpoint",
 0x0ae8:"keep scanning",
 0x0aea:"[end] record end bank  (r6)",
 0x0aec:"record end offset (r7)",
 0x0aee:"rr2 = end (bank:offset)",
 0x0af0:"rr12 = start (bank:offset)",
 0x0af2:"end -> physical address",
 0x0af6:"start -> physical address",
 0x0afa:"extent = end - start",
 0x0afc:"- 16 KB",
 0x0b02:"extent >= 16 KB -> return OK (carry clear, via rr10)",
 0x0b04:"at the top bank?",
 0x0b08:"no -> retry the scan (0x0a9c)",
 0x0b0a:"[error] set carry = RAM absent or < 16 KB",
 0x0b0c:"return; caller shows code 2 (system-RAM fault)",
}

HEADER = {
 0x00ce:[
 "!------------------------------------------------------------------------------",
 "! NMI HANDLER = RAM-probe fault handler.  A memory read with no READY raises an",
 "! NMI; here rr12 already points at the RAM-sizing loop's resume point, and r13",
 "! (its low half) is that checkpoint's offset.  The handler pops the NMI frame,",
 "! confirms we are in the probe loop (r13 = 0xaa8/0xaea), clears the source at",
 "! 0xFF41, and either records the location (0x0ada) or skips the window (rr12).",
 "!------------------------------------------------------------------------------",],
 0x0a94:[
 "",
 "!==============================================================================",
 "! RAM SIZING  (\"ricerca allocazione fisica RAM\", Collaudi 1-2)",
 "! out: carry clear + contiguous-RAM extent, or carry set = fault (code 2).",
 "! Walks physical memory in 16 KB steps by repeatedly remapping MMU descriptor",
 "! 60 (segment 60 = scratch \"probe window\") to each 64 KB bank and reading it.",
 "! Absent RAM has no READY -> NMI -> the NMI handler (0x00ce) resumes here at",
 "! rr12 (checkpoints 0xaa8 = keep scanning, 0xaea = record end).  Records the",
 "! contiguous start (r4:r5) and end (r6:r7); requires extent >= 16 KB.",
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
