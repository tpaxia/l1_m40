#!/usr/bin/env python3
"""Annotate the RAM allocation + memory-board-test stage in re/disassembly/m40-rom/m40rom-4.1.s:
  * 0x0b0e — map the discovered RAM into MMU segments (64 KB each)
  * 0x035c — BBU (Battery Backup Unit) warm-start check ("$BBU ON " marker)
  * 0x03a4 — cold-start clear + line-board dispatch
  * 0x03ba — memory pattern test ("test piastra di memoria")
Replace semantics on the '! ADDR: bytes' markers; comment-only => bytes unchanged.
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- 0x0b0e: map discovered RAM into MMU segments ----
 0x0b0e:"SAR = descriptor 2 (first bulk-RAM segment)",
 0x0b10:"MMU SAR = 2", 0x0b14:"MMU DSC = 0",
 0x0b18:"descriptor base-high = rh4",
 0x0b1c:"descriptor base-low  = rh5",
 0x0b20:"block counter = 0",
 0x0b22:"advance base by 256 bytes",
 0x0b26:"", 0x0b28:"carry -> base-high++",
 0x0b2a:"reached end of RAM (rr6)?",
 0x0b2c:"yes -> write the final (partial) descriptor",
 0x0b2e:"block++",
 0x0b30:"< 256 blocks (64 KB)? keep filling this descriptor",
 0x0b32:"256 blocks done",
 0x0b34:"descriptor limit = 0xFF (64 KB)",
 0x0b38:"descriptor attr = 0",
 0x0b3c:"next descriptor (SAR++)",
 0x0b3e:"loop",
 0x0b40:"final descriptor limit = remaining blocks",
 0x0b44:"attr = 0",
 0x0b48:"", 0x0b4a:"", 0x0b4c:"", 0x0b4e:"", 0x0b50:"",
 0x0b52:"SAR = descriptor 1 (small system/stack segment)",
 0x0b54:"", 0x0b58:"",
 0x0b5c:"base = 0x400 below RAM top",
 0x0b60:"", 0x0b62:"",
 0x0b64:"descriptor 1 base-high = rh6", 0x0b68:"base-low = rh7",
 0x0b6c:"", 0x0b6e:"limit = 3 (~1 KB)", 0x0b72:"attr = 0",
 0x0b76:"move the stack into RAM (<<1>>0x01c0)",
 0x0b7c:"return",
 # ---- 0x035c: BBU warm-start check ----
 0x035c:"read ff41 (BBU / NMI status)",
 0x0360:"BBU-held-RAM bit 0 set?",
 0x0362:"no -> cold start",
 0x0364:"rr12 = &cold-start (if the compare below faults)",
 0x0368:"rr8 = &\"$BBU ON \" marker",
 0x036c:"rr2 = <<1>>0x03f8 (marker in battery-backed RAM)",
 0x0372:"8 bytes",
 0x0376:"RAM marker == \"$BBU ON \" ?",
 0x037a:"no -> cold start",
 0x037c:"warm start: load saved descriptor from <<1>>0x0210",
 0x0384:"",
 0x0386:"reprogram the MMU descriptor from saved state",
 0x038a:"", 0x038e:"", 0x0392:"", 0x0396:"",
 0x039a:"resume at the saved entry point (warm boot)",
 # ---- 0x03a4: cold-start prep ----
 0x03a4:"rr2 = <<1>>0x03ff",
 0x03aa:"clear value 0",
 0x03ac:"clear r3 bytes of low RAM",
 0x03ae:"",
 0x03b0:"r0 = NSP (line-board flag set during the scan)",
 0x03b2:"line board present?",
 0x03b4:"yes -> 0x4ca (skip the RAM pattern test)",
 # ---- 0x03ba: memory pattern test ----
 0x03ba:"rr6 = <<2>>0x0000 : start of mapped RAM",
 0x03c0:"", 0x03c4:"", 0x03c6:"", 0x03c8:"r9 = end-bank marker",
 0x03ca:"", 0x03cc:"NSP = 0",
 0x03ce:"rr12 = &fault handler (0x0430)",
 0x03d2:"rr2 = start",
 0x03d4:"after fill -> next pattern (0x3de)",
 0x03d8:"pattern 1 = 0x5555",
 0x03dc:"-> fill loop",
 0x03de:"after -> 0x3e8",
 0x03e2:"pattern 2 = 0x3131",
 0x03e6:"-> verify-old / write-new",
 0x03e8:"after -> 0x0494 (done)",
 0x03ec:"pattern 3 = 0xFFFF",
 0x03f0:"-> verify-old / write-new",
 0x03f2:"[fill] reached end (rr4)?",
 0x03f4:"yes -> verify pass",
 0x03f6:"write pattern",
 0x03f8:"next word", 0x03fa:"",
 0x03fc:"next segment", 0x03fe:"",
 0x0400:"[verify + write complement] rr2 = start",
 0x0402:"r0 = pattern",
 0x0404:"r0 = ~pattern",
 0x0406:"reached end?",
 0x0408:"yes -> return (rr10 = next stage)",
 0x040a:"read == pattern?",
 0x040c:"no -> memory fault (0x0430)",
 0x040e:"write the complement",
 0x0410:"", 0x0412:"", 0x0414:"", 0x0416:"",
 0x0418:"[verify old, write new] rr2 = start",
 0x041a:"reached end?",
 0x041c:"yes -> verify this pattern (0x0400)",
 0x0422:"read == expected previous value (r0)?",
 0x0424:"no -> memory fault (0x0430)",
 0x0426:"write new pattern",
 0x0428:"", 0x042a:"", 0x042c:"", 0x042e:"",
}

HEADER = {
 0x0b0e:[
 "",
 "!==============================================================================",
 "! MAP RAM INTO SEGMENTS  (in: rr4 = RAM start, rr6 = RAM end)",
 "! Programs MMU descriptors from #2 upward to cover the contiguous physical RAM",
 "! in 64 KB chunks (base, limit 0xFF, attr 0), the last sized to the remainder.",
 "! Then sets descriptor 1 = a small system/stack segment near the RAM top and",
 "! moves the stack into it (<<1>>0x01c0).",
 "!==============================================================================",],
 0x035c:[
 "",
 "!==============================================================================",
 "! BBU (Battery Backup Unit) WARM-START CHECK",
 "! If ff41 bit 0 says the BBU kept RAM alive and the marker \"$BBU ON \" is present",
 "! at <<1>>0x03f8, restore the saved MMU descriptor from <<1>>0x0210 and resume at",
 "! the saved entry point -- a warm boot.  Otherwise fall through to cold start.",
 "!==============================================================================",],
 0x03a4:[
 "!------------------------------------------------------------------------------",
 "! Cold start: zero low RAM, then branch by the line-board flag (NSP).",
 "!------------------------------------------------------------------------------",],
 0x03ba:[
 "",
 "!==============================================================================",
 "! MEMORY PATTERN TEST  (\"test piastra di memoria\")",
 "! Marching test over all mapped RAM (rr6 = start .. rr4 = end): write 0x5555,",
 "! verify + write its complement, then 0x3131, then 0xFFFF.  Any miscompare jumps",
 "! to the fault handler (0x0430).  Loops: 0x3f2 fill, 0x418 verify-old/write-new,",
 "! 0x400 verify/write-complement.",
 "!==============================================================================",],
 0x0430:[
 "!------------------------------------------------------------------------------",
 "! Memory-test fault handler: computes the faulting address from the RAM bounds",
 "! and (comparing against NSP / r11) decides the outcome. (details TBD)",
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
