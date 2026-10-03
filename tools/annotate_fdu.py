#!/usr/bin/env python3
"""Annotate the FDU floppy boot loader in re/disassembly/m40-rom/m40rom-4.1.s (toward M2).
The governo is addressed at the FDU slot (high byte at <<1>>0x0302); the low byte
selects a register: 0x1d = uPD765 main status (poll RQM), 0x9f/0x9d = cmd/param,
0xe7 = control latch (shadow <<1>>0x0354), 0xff/0xf7/0xed = status/interrupt.
The boot read is a uPD765 READ DATA command (templates 0x17dc/0x17e6, C0/H0/R1).
Replace semantics on '! ADDR: bytes'; comment-only => bytes unchanged.
"""
import re
PATH = "re/disassembly/m40-rom/m40rom-4.1.s"

NOTE = {
 # ---- FDU IPL handler entry (0x85e = 0x6ee + param 0x170) ----
 0x085e:"FDU IPL handler entry (dispatched from the boot search)",
 0x0868:"probe/select the drive (0x09de)",
 0x086e:"rh1 = FDU slot", 0x0874:"reset the governo (0x0eae)",
 0x089e:"read target = <<60>>0x0000 (segment 60 = boot buffer)",
 0x08a8:"read the boot track into <<60>> (0x14ae)",
 0x08b4:"reg 0xed = status", 0x08b6:"read", 0x08b8:"complete/error?",
 # validation + handoff (0x08fe)
 0x08fe:"[validate the loaded block]",
 0x0902:"", 0x0904:"scan segment 60", 0x090a:"",
 0x0918:"rr0 = first 4 bytes of the block",
 0x091a:"magic == \"SYS0\" (0x53595330) ?",
 0x0922:"no -> not bootable (r7=8)",
 0x0926:"", 0x0928:"",
 0x092e:"save old PSAP", 0x0932:"", 0x0938:"", 0x093e:"copy the PSA vectors into place",
 0x0942:"ENTRY POINT = longword at <<60>>0x0004 (block header)",
 0x0946:"rr4 = entry point",
 0x0948:"reprogram MMU descriptor 60 -> the loaded block",
 0x0984:"stack = <<1>>0x01c0",
 0x098a:"JUMP to the loaded boot program (rr4 = its entry point)",
 # 0x0eae: FDU reset/select pulse
 0x0eae:"reset the governo control latch (0x0354=0) + strobe (0xe7)",
 0x0eb0:"control shadow <<1>>0x0354 = 0",
 0x0eb6:"push control latch to reg 0xe7 (helper 0x12ca)",
 0x0eba:"settle delay",
 # 0x0ec0: FDU init / recalibrate
 0x0ec0:"", 0x0ec6:"save FCW", 0x0ec8:"di vi",
 0x0eca:"rh1 = FDU slot device-select (<<1>>0x0302)",
 0x0ed0:"reset the governo",
 0x0ede:"8253 timer: control = 0x50 (reg 0x9f)", 0x0ee2:"",
 0x0ee4:"read reg 0xe7", 0x0ee6:"",
 0x0ee8:"control shadow = 0x13 (motor/select on)",
 0x0ef0:"push to reg 0xe7",
 0x0ef2:"read reg 0x1d (uPD765 main status)",
 0x0ef6:"reg 0x50 = 0x20", 0x0efa:"write",
 0x0efc:"poll status (0x12da)",
 0x0f10:"issue the read (0x1172)",
 0x0f12:"restore FCW",
 # 0x0f2e: status poll (reg 0xff / 0xed bit 0)
 0x0f2e:"", 0x0f30:"rh1 = FDU slot",
 0x0f36:"reg 0xff", 0x0f38:"read status", 0x0f3a:"bit 0 (ready/complete)?",
 0x0f3e:"reg 0xed", 0x0f40:"read", 0x0f42:"bit 0?",
 # helpers
 0x12ca:"[helper] write control shadow (<<1>>0x0354) to reg 0xe7",
 0x12cc:"reg 0xe7",
 0x12da:"[helper] read reg 0xff bit 0 (status)",
 0x12e2:"reg 0xff", 0x12e4:"read", 0x12e6:"bit 0",
 # 0x1116: build a governo command + issue
 0x1116:"", 0x111a:"cmd block at <<1>>0x0334",
 0x1120:"@block = 0x0207 (seek/specify)",
 0x1124:"drive # from <<1>>0x0303", 0x112e:"patch drive into block",
 0x1132:"issue (0x1172)",
 # 0x1154: poll uPD765 main status for RQM
 0x1154:"[poll RQM] retry counter",
 0x115a:"", 0x115c:"short delay", 0x115e:"timeout--",
 0x1162:"reg 0x1d = uPD765 main status",
 0x1164:"read it",
 0x1168:"rotate: RQM (bit7) into carry",
 0x116a:"not ready -> keep polling",
 # 0x1172: issue the transfer (command + DMA read)
 0x1172:"[read routine]",
 0x117c:"rh1 = FDU slot",
 0x1182:"reg 0x1d = main status", 0x1184:"", 0x1186:"mask ready bits",
 0x118a:"not ready -> error (0x124c)",
 0x118c:"8253/DMAC setup (reg 0x9f)",
 0x118e:"op code from descriptor rr8[1]",
 0x1196:"read op (0x0d)?", 0x119a:"", 0x119e:"",
 0x11a0:"8253 counter setup (0x90/0x98 -> reg 0x9f)",
 0x11a2:"8253 counter (reg 0x9d) = 0x02", 0x11a6:"",
 0x11a8:"", 0x11ac:"clear the 8-byte result buffer <<1>>0x033a",
 # command PIO + DMA data transfer
 0x1260:"[send command byte] poll RQM (0x1150)",
 0x1264:"open the backplane-DMA gate (UC gate array 0xFF84)",
 0x1268:"PIO one command byte to the governo (outib @r1,@rr8)",
 0x126c:"more command bytes -> loop",
 0x126e:"close the DMA gate (0xFF8C) -- sector data itself DMAs to system RAM",
 0x1216:"0xFF84 = backplane-DMA gate", 0x122c:"0xFF8C = DMA control",
 0x129e:"0xFF8C = DMA control",
 0x14d0:"format A: DMA count 0x0800 (16 sect), template 0x17dc",
 0x14da:"format B: DMA count 0x0d00 (26 sect), template 0x17e6",
 # 0x146e / 0x14ae: build the uPD765 command block from a template
 0x146e:"reg 0x9f = 0x50",
 0x1474:"", 0x1478:"retry vector <<1>>0x0352 = 0x13c2",
 0x14ae:"[build read command]",
 0x14b4:"", 0x14c0:"init the FDC (0x1116)",
 0x14d0:"format A: count 0x0800, template 0x17dc",
 0x14da:"format B: count 0x0d00, template 0x17e6",
 0x14e2:"cmd buffer at <<1>>0x0320",
 0x14ec:"copy the 10-byte uPD765 READ template",
 0x14f6:"patch drive #", 0x14fc:"",
}

HEADER = {
 0x085e:[
 "",
 "!==============================================================================",
 "! FDU IPL HANDLER  (entry = handler-table base 0x6ee + param 0x170)",
 "! Reads the boot track to segment 60, validates the \"SYS0\" magic, then jumps to",
 "! the entry point stored in the block header (longword at <<60>>0x0004).",
 "!==============================================================================",],
 0x08fe:[
 "",
 "!------------------------------------------------------------------------------",
 "! Validate + launch the loaded block: require magic \"SYS0\" at <<60>>0x0000, take",
 "! the entry point from <<60>>0x0004, set up the MMU/PSA, and jp to it.",
 "!------------------------------------------------------------------------------",],
 0x0eae:[
 "",
 "!==============================================================================",
 "! FDU FLOPPY BOOT LOADER (IPL handler for E1/E0) -- GO280: uPD765 + AM9517 DMAC",
 "! + 8253.  Governo at the FDU slot (high byte = <<1>>0x0302); low byte = register",
 "! (per manual 3963590): 0x1D=FDC status, 0x1F=FDC data, 0x40-5E=DMAC, 0x9x=8253",
 "! timer, 0xE7=control (CONTR), 0xF6=DMA addr-high, 0xF7=int status, 0xFF=ID(E0/E1).",
 "! Boot read = uPD765 READ DATA (templates 0x17dc/0x17e6: C=0 H=0 R=1), DMA'd via",
 "! DMAC ch2 (+0xF6 high byte) to segment 60.",
 "!==============================================================================",],
 0x1154:[
 "",
 "!------------------------------------------------------------------------------",
 "! Poll the uPD765 main status register (governo reg 0x1d) for RQM, with timeout.",
 "!------------------------------------------------------------------------------",],
 0x1172:[
 "",
 "!------------------------------------------------------------------------------",
 "! Issue a governo/uPD765 operation (command bytes + DMA read of the sector).",
 "! rr8 -> device/command descriptor; op code in rr8[1].",
 "!------------------------------------------------------------------------------",],
 0x14ae:[
 "",
 "!------------------------------------------------------------------------------",
 "! Build a uPD765 READ DATA command block at <<1>>0x0320 from a 10-byte template",
 "! (0x17dc = format A, 0x17e6 = format B), patched with the drive number.",
 "!------------------------------------------------------------------------------",],
}

LABEL_HDR = {
 "L_17dc":[
 "! uPD765 READ DATA command templates (10 bytes): count, 06=READ, HDUS, C, H,",
 "! R=1, N, EOT, GPL, DTL.  Two disk formats: 0x17dc EOT=0x10/GPL=0x10,",
 "! 0x17e6 EOT=0x1a/GPL=0x07.  Read starts at cylinder 0, head 0, sector 1.",],
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
