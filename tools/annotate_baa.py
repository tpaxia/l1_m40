#!/usr/bin/env python3
"""Apply human annotations to re/disassembly/m40-rom/m40rom-4.1.s for the console/video routines
(0x0b7e..0x0c42) and the video-command table (0x0c44). Only touches comments
and inserts '!' comment lines -> bytes are unchanged (verified by `make verify`).

Keyed on the stable trailing '! ADDR: bytes' markers emitted by mkasm.py, so it
is idempotent-ish: re-running replaces the same trailing comments.
"""
import re, sys

PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

# addr(hex) -> short inline comment (appended after the raw-bytes marker)
NOTE = {
 # ---- 0x0b7e: show the 1-digit hex code on every video screen ----
 0x0b7e:"r1=0 (video window index)",
 0x0b80:"rr12 = &console-display (fall-through chain)",
 0x0b84:"r0 = error/step code (r7)",
 0x0b86:"+= '0'  -> ASCII",
 0x0b8a:"> '9' ?",
 0x0b8e:"if <= '9', skip",
 0x0b90:"+= 7  -> 'A'..'F' (hex)",
 0x0b92:"video[seg61 : 0x0001 + r1] = digit",
 0x0b96:"video[0x0005 + r1] = ' '",
 0x0b9c:"video[0x0009 + r1] = ' '",
 0x0ba2:"next video controller window (+0x2000)",
 0x0ba6:"loop until r1 wraps to 0 (all windows)",
 0x0ba8:"fall into the console display",
 # ---- 0x0baa: show the 4-bit code on the diagnostic console panel ----
 0x0baa:"console code latch (0xFFE0) = step/error code",
 0x0bae:"i = 3 (4 bits, 3..0)",
 0x0bb0:"port = 0xFF64 + i  (\"lamp i = 0\" latch)",
 0x0bb4:"",
 0x0bb6:"bit i of the code set?",
 0x0bba:"clear -> use 0xFF64+i",
 0x0bbc:"set  -> port |= 8 -> 0xFF6C+i (\"lamp i = 1\")",
 0x0bbe:"strobe the lamp latch (data = port low byte)",
 0x0bc0:"",
 0x0bc2:"next bit while i >= 0",
 0x0bc4:"return (rr10)",
 # ---- 0x0bc6: detect + init a video controller, test its logic ----
 0x0bc6:"rl1 = r1 low byte = reg-select 0x81 (status)",
 0x0bc8:"read status/type from ctrl reg 0x81",
 0x0bca:"type = low 3 bits",
 0x0bce:"*2 -> word index",
 0x0bd0:"rr4 = &video-command table (0x0c44)",
 0x0bd4:"r0 = table[type] = offset of this type's cmd block",
 0x0bd8:"",
 0x0bda:"empty command block?",
 0x0bdc:"yes -> treat as failure",
 0x0bde:"", 0x0be0:"strobe reg (byte = its own select)",
 0x0be2:"", 0x0be4:"", 0x0be6:"", 0x0be8:"",
 0x0bea:"16 register writes",
 0x0bec:"index = 0",
 0x0bee:"reg-select 0x41 (CRTC addr latch)",
 0x0bf0:"write rl2 to ctrl reg 0x41",
 0x0bf2:"rl0 = next command byte from table",
 0x0bf6:"reg-select 0x43 (CRTC data)",
 0x0bf8:"write command byte to ctrl reg 0x43",
 0x0bfa:"", 0x0bfc:"next of 16",
 # video-RAM read/write test (segment 61)
 0x0bfe:"rr2 = video RAM base (seg 61)",
 0x0c02:"r3 = 0 (r7=0 on entry from slot scan)",
 0x0c04:"2048 read-back passes",
 0x0c08:"pattern = 0x20 (' ')",
 0x0c0c:"write pattern to video RAM cell",
 0x0c0e:"read back, compare",
 0x0c10:"mismatch -> stop (fail)",
 0x0c12:"r3 += 2 per good pass",
 0x0c14:"",
 0x0c16:"r3 = 0x1000 & 0x7ff = 0 if all passed",
 0x0c1a:"nonzero -> FAIL",
 # video-logic (live signal) test: poll status bit 3 for a toggle
 0x0c1c:"reg-select 0x01",
 0x0c1e:"", 0x0c20:"write 3 to ctrl reg 0x01 (arm)",
 0x0c22:"reg-select 0x81 (status)",
 0x0c24:"mask = bit 3 (VSYNC/refresh)",
 0x0c26:"sample status", 0x0c28:"isolate bit 3",
 0x0c2a:"sample status again",
 0x0c2c:"isolate bit 3", 0x0c2e:"changed?",
 0x0c30:"toggled -> video OK",
 0x0c32:"retry",
 0x0c34:"--- FAIL: response word = 0xFFFF ---",
 0x0c36:"r0 = 0xFFFF (video KO in config table)",
 0x0c3a:"return (rr10)",
 0x0c3c:"--- OK: reg-select 0x6a ---",
 0x0c3e:"write 0x6a (enable normal video)",
 0x0c40:"r0 = 0x0000 (video OK in config table)",
 0x0c42:"return (rr10)",
}

# Section header blocks inserted before the instruction (and its label) at addr.
HEADER = {
0x0b7e:[
"!==============================================================================",
"! DIAGNOSTIC CODE DISPLAY  (video + console)",
"! Shows the 1-hex-digit power-on step / error code (in r7) on every attached",
"! video screen, then on the UC diagnostic console panel. Ref: Manuale dei",
"! Collaudi 1-9..1-10 (\"messaggi dell'autodiagnostica\").",
"!------------------------------------------------------------------------------",
"! show code on VIDEO: write its ASCII hex digit into each seg-61 window",
"!==============================================================================",
],
0x0baa:[
"!------------------------------------------------------------------------------",
"! show code on the CONSOLE: 0xFFE0 = numeric latch; 0xFF64..0xFF6F = 4 lamps,",
"! one per code bit (0xFF64+i clears lamp i, 0xFF6C+i sets it).  in: r7=code.",
"!------------------------------------------------------------------------------",
],
0x0bc6:[
"",
"!==============================================================================",
"! VIDEO CONTROLLER DETECT / INIT / SELF-TEST        in: r1=ctrl I/O port,",
"!                                                       rr10=return",
"! The low byte of r1 (rl1) is the controller register-select; the high byte is",
"! the board select found by the slot scan.  Reads the controller type (reg",
"! 0x81, low 3 bits), programs its CRTC registers (0x41/0x43) from the per-type",
"! command table at 0x0c44, then tests video RAM and the live-signal logic.",
"! out: r0 = 0x0000 (video OK) or 0xFFFF (fail) -> config-table response word.",
"! Ref: Manuale dei Collaudi 1-10/1-11 (video controllers as diag output).",
"!==============================================================================",
],
}

TABLE_HDR = [
"! Video-controller command table.  8 entries (one per type 0..7) each holding",
"! the offset (from 0x0c44) of that controller's CRTC init byte-string; the",
"! strings follow, terminated by 0x3fff.  Indexed via (status reg 0x81 & 7).",
]

def insert_header(out, block):
    if block and block[-1] in out[-len(block)-4:]:  # dedupe guard
        return
    labels = []                       # pull the header above a preceding label
    while out and re.match(r'L_[0-9a-f]+:$', out[-1].strip()):
        labels.insert(0, out.pop())
    out.extend(block)
    out.extend(labels)

def main():
    lines = open(PATH).read().split("\n")
    out = []
    for ln in lines:
        if ln.strip().rstrip(':') == "L_0c44":
            insert_header(out, TABLE_HDR)
        m = re.search(r'! ([0-9a-f]{4}): ([0-9a-f]+)', ln)   # loose: matches even if a note follows
        if m:
            addr = int(m.group(1), 16)
            if addr in HEADER:
                insert_header(out, HEADER[addr])
            if addr in NOTE and NOTE[addr] and re.search(r': [0-9a-f]+\s*$', ln):
                ln = ln.rstrip() + "   " + NOTE[addr]   # append only if no note yet
        out.append(ln)
    open(PATH, "w").write("\n".join(out))
    print("annotated", PATH)

if __name__ == "__main__":
    main()
