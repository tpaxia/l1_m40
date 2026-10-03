#!/usr/bin/env python3
"""Annotate the reset self-test flow in re/disassembly/m40-rom/m40rom-4.1.s:
  * post-reset init (0x122)         * ROM checksum / Test ROM (0x1be)
  * 8253 timer test (0x1e8)         * Z8010 MMU descriptor test (0x220)
  * MMU descriptor programming (0x25c)
Also CORRECTS the video-RAM-test notes (0xc02..0xc16): rr2's offset half (r3)
IS advanced, so it walks 4 KB of seg-61 RAM (not a single cell).

Replace semantics on the '! ADDR: bytes' markers -> re-runnable, corrective.
Comment-only + '!' inserts => bytes unchanged (checked by `make verify`).
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- post-reset init ----
 0x0122:"", 0x0126:"DRAM refresh control = 0x9200 (enable + rate)",
 0x0128:"SP (rr14) = <<0>>0x00fe",
 0x012c:"", 0x0130:"PSAP -> <<0>>0x0000 (PSA at ROM start)",
 0x0132:"",
 0x0134:"", 0x0136:"8253 ctrl: counter0 = mode2 (rate gen)",
 0x013a:"", 0x013c:"8253 ctrl: counter1 = mode0",
 0x0140:"", 0x0142:"8253 ctrl: counter2 = mode3 (square wave)",
 0x0146:"read config/jumpers (port 0xFFA0)",
 0x014a:"", 0x014c:"UC control latch 0xFF20 = 0x03",
 # ---- ROM CHECKSUM (Test ROM) ----
 0x01b8:"NSP = r7", 0x01ba:"", 0x01bc:"skip checksum if r7 flag set",
 0x01be:"sum0:sum1 (rr0) = 0  <- running checksum",
 0x01c0:"rr2 = <<0>>0x0000  <- pointer (r2=seg, r3=offset)",
 0x01c2:"rr4 = 0 (byte scratch; rh4/rh5 stay 0)",
 0x01c4:"r6 = 0 (carry addend)",
 0x01c6:"count = 0x0ffe pairs = 8188 bytes (all but the 4-byte checksum)",
 0x01ca:"b1 = ROM[offset]",
 0x01cc:"b1 ^= offset & 0xff",
 0x01ce:"offset++  (r3 is the low half of rr2)",
 0x01d0:"b2 = ROM[offset]",
 0x01d2:"b2 ^= offset & 0xff",
 0x01d4:"offset++",
 0x01d6:"sum1 += b1", 0x01d8:"  + end-around carry",
 0x01da:"sum0 += b2", 0x01dc:"  + end-around carry",
 0x01de:"next pair",
 0x01e0:"rr4 = stored checksum (4 bytes @ 0x1ffc)",
 0x01e2:"byte-swap to accumulator layout (rh4<->rl5)",
 0x01e4:"computed (rr0) == stored (rr4) ?",
 0x01e6:"MISMATCH -> hang here forever (ROM fault)",
 # ---- 8253 timer functional test ----
 0x01e8:"counter0 reload = 2 (prescaler feeding counter1)",
 0x01ea:"", 0x01ee:"counter0 = 0x0002",
 0x01f2:"counter1 reload = 0x03be", 0x01f6:"",
 0x01fa:"counter1 = 0x03be, counting down (mode0)",
 0x01fe:"", 0x0200:"latch counter1 for reading (ctrl 0x40)",
 0x0204:"poll counter (rh0)++",
 0x0206:"256 polls w/o terminal count -> hang (stuck/slow)",
 0x0208:"read counter1 LSB", 0x020c:"read counter1 MSB",
 0x0210:"counter1 wrapped through 0 (bit15 set)?",
 0x0212:"not yet -> keep polling",
 0x0214:"", 0x0216:"reprogram counter1 (mode0)",
 0x021a:"polls taken >= 0x28 ?", 0x021e:"< 0x28 -> timer too fast -> hang",
 # ---- Z8010 MMU descriptor R/W test ----
 0x0220:"r0 = 0 (test pattern + SAR/DSC)",
 0x0222:"MMU SAR = 0 (descriptor 0)",
 0x0226:"MMU DSC = 0 (byte 0)",
 0x022a:"write 0x00 to descriptor byte, auto-inc SAR",
 0x022e:"...256 bytes = all 64 descriptors x 4",
 0x0230:"SAR = 0", 0x0234:"DSC = 0",
 0x0238:"read descriptor byte back",
 0x023c:"== 0x00 ?", 0x023e:"MISMATCH -> hang (MMU fault)",
 0x0240:"...256 bytes",
 0x0242:"pattern = 0xff (rl0=0xff, rh0=0)",
 0x0246:"SAR = 0", 0x024a:"DSC = 0",
 0x024e:"fill every descriptor byte with 0xff (mark all segs invalid)",
 0x0252:"...256 bytes", 0x0254:"SAR = 0", 0x0258:"DSC = 0",
 # ---- MMU descriptor programming + enable translation ----
 0x025c:"rr2 = &descriptor init table (0x00f6)",
 0x0260:"MMU port = R/W descriptor + auto-inc SAR",
 0x0264:"4 bytes = 1 descriptor",
 0x0266:"load descriptor 0 = segment 0 (ROM) [SAR=0]",
 0x026a:"", 0x026c:"SAR = 0x3d = 61",
 0x0270:"12 bytes = 3 descriptors",
 0x0272:"load descriptors 61,62,63 = video windows",
 0x0276:"", 0x0278:"MMU mode = 0xC0 (MSEN|TRNS) -> ENABLE TRANSLATION",
 # ---- CORRECTIONS to the video-RAM test (it WALKS 4 KB, not 1 cell) ----
 0x0c02:"r3 = video offset = 0 (r7=0); rr2 = seg61:offset",
 0x0c0c:"video[seg61 : offset] = pattern (word)",
 0x0c0e:"read back, compare",
 0x0c12:"offset += 2   <- WALKS video RAM (2048 words = 4 KB)",
 0x0c16:"did the walk finish? (offset reached 0x1000)",
}

HEADER = {
 0x0122:[
 "!==============================================================================",
 "! POST-RESET INIT: DRAM refresh, stack, PSAP, 8253 timers, config port.",
 "!==============================================================================",],
 0x0150:[
 "",
 "!------------------------------------------------------------------------------",
 "! Preliminary board scan: step the device-select high byte (rh1 += 0x10),",
 "! read each board's ID at port 0x?FFF, and inline-init a video (ID 0xFE) or",
 "! line (ID 0xD?) board so diagnostics have an output device early.",
 "!------------------------------------------------------------------------------",],
 0x01be:[
 "",
 "!==============================================================================",
 "! ROM CHECKSUM  (\"Test ROM\", Manuale dei Collaudi 1-2)",
 "! Two interleaved 16-bit sums-with-end-around-carry over the whole ROM (even",
 "! bytes -> sum1, odd bytes -> sum0), each byte first XORed with its offset low",
 "! byte. Compared against the 4-byte value stored at the very top (0x1ffc).",
 "! Verified: reproduces the stored word for both 4.1 (d977 e802) and 6.0.",
 "! On mismatch the CPU hangs at 0x1e6 (no console output possible yet).",
 "!==============================================================================",],
 0x01e8:[
 "",
 "!------------------------------------------------------------------------------",
 "! 8253 TIMER test (Collaudi 1-3).  counter0 (mode2) prescales the clock for",
 "! counter1 (mode0), preloaded 0x03be.  Poll-latch counter1 until it counts",
 "! through 0 (bit15 set); the CPU poll-count must land in [0x28,0x100) --",
 "! too fast -> hang @0x21e, stuck/too slow -> hang @0x206.",
 "!------------------------------------------------------------------------------",],
 0x0220:[
 "",
 "!==============================================================================",
 "! Z8010 MMU DESCRIPTOR TEST  (\"Test Z8010\", Collaudi 1-2)",
 "! Write 0x00 to all 256 descriptor bytes (64 segs x 4) via SAR+auto-inc, read",
 "! back and compare; mismatch -> hang. Then fill them all with 0xFF to mark",
 "! every segment invalid before the real descriptors are loaded.",
 "!==============================================================================",],
 0x025c:[
 "",
 "!------------------------------------------------------------------------------",
 "! Load the live MMU map from the table at 0x00f6 and switch the MMU into",
 "! translate mode: segment 0 -> ROM (phys 0x000000), segments 61..63 -> video",
 "! windows (phys 0xff0000 / 0xf00000, 64 KB each).  After this, <<61>> reaches",
 "! video RAM.  Ref: Collaudi 1-2 (\"segment 0 = ROM, segment 61 = video RAM\").",
 "!------------------------------------------------------------------------------",],
}

# Descriptor-table explanation, inserted after the 0x00f6 block banner.
DESC_ANCHOR = "! ---- 0x00f6 .. 0x0106  (word) ----"
DESC_HDR = [
 "! MMU descriptor init table (base_hi, base_lo, limit, attr) x4, loaded at 0x25c:",
 "!   desc 0  : 00 00 ff 00  seg0  -> phys 0x000000, limit 0xff (64 KB)  = ROM",
 "!   desc 61 : ff 00 ff 00  seg61 -> phys 0xff0000, 64 KB              = video",
 "!   desc 62 : f0 00 ff 00  seg62 -> phys 0xf00000, 64 KB              = video",
 "!   desc 63 : 00 00 ff 00  seg63 -> phys 0x000000",
]

def insert_header(out, block):
    # dedupe on the most distinctive (longest) line, not the generic separator
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
        if ln.strip() == DESC_ANCHOR:
            out.append(ln)
            if DESC_HDR[0] not in out[-len(DESC_HDR)-3:]:
                out.extend(DESC_HDR)
            continue
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
