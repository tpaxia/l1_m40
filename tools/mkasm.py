#!/usr/bin/env python3
"""Round-trippable Z8001 disassembly generator for the Olivetti M30/M40 ROMs.

Produces a .s that reassembles (patched z8k-coff binutils) to a byte-identical
binary, verified here. Approach:
  * objdump (same binutils as the assembler) disassembles each code segment;
  * PC-relative ops (jr/calr/djnz/dbjnz/ldar) get LABEL operands (a bare number
    is taken as a raw displacement by the assembler); absolute ops round-trip
    with objdump's numeric operand as-is;
  * long-form segmented addresses are forced with `.long_addr` (detected from
    the raw bytes: address word at offset 2 has bit15 set);
  * data segments are emitted as `.word` / `.byte`;
  * any instruction the assembler rejects or re-encodes differently is repaired
    to a raw `.word` (guaranteed identical) by an iterative loop.

Usage: mkasm.py <rom.bin> <out.s>
"""
import subprocess, sys, os, re, tempfile

AS, LD, OCP, ODP = "z8k-coff-as", "z8k-coff-ld", "z8k-coff-objcopy", "z8k-coff-objdump"

# PC-relative mnemonics: operand must be a label, not a bare number.
PCREL = {"jr", "calr", "djnz", "dbjnz", "ldar"}

# Segment maps per ROM (keyed by size). kind: 'code' | 'word' | 'ascii'
MAPS = {
    0x200: [  # SYS0 first-stage bootloader (first 512 bytes of a diag disk's track 0;
              # code+tables byte-identical across all L1 DCOS 8.4 disks). Runs at <<25>>.
        (0x0000, 0x0004, 'ascii'),   # "SYS0" magic
        (0x0004, 0x000c, 'word'),    # entry point <<25>>0x000c + flags longword
        (0x000c, 0x00dc, 'code'),    # bootloader: dispatch, device search, LBA->CHS
        (0x00dc, 0x00e6, 'word'),    # device-type table (E4 E0 66 E6 E7 E1 60 61 62 65)
        (0x00e6, 0x00fa, 'word'),    # loader-pointer table (10 words -> ROM seg-0 offsets)
        (0x00fa, 0x0110, 'word'),    # scratch (saved boot marker) + fill
        (0x0110, 0x0114, 'word'),    # Monitor entry point <<25>>0x0234
        (0x0114, 0x0200, 'word'),    # load-descriptor table (+ zero pad)
    ],
    0x2000: [  # m40rom-4.1
        (0x0000, 0x0008, 'word'),
        (0x0008, 0x0028, 'ascii'),   # " 17 DEC. 82  REL 4.1 " banner (in unused trap slots)
        (0x0028, 0x00ce, 'word'),    # PSA vectors
        (0x00ce, 0x00f6, 'code'),    # NMI + NVI handlers
        (0x00f6, 0x0106, 'word'),    # gap before reset entry
        (0x0106, 0x039c, 'code'),    # main firmware
        (0x039c, 0x03a4, 'ascii'),   # "$BBU ON " battery-backup warm-start marker
        (0x03a4, 0x06e6, 'code'),
        (0x06e6, 0x071c, 'word'),    # IPL device priority lists + per-device handler table
        (0x071c, 0x0c44, 'code'),
        (0x0c44, 0x0cd4, 'word'),    # video-controller command table (indexed by ctrl type)
        (0x0cd4, 0x17dc, 'code'),
        (0x17dc, 0x17f0, 'word'),    # µPD765 READ DATA command templates (two disk formats)
        (0x17f0, 0x1fae, 'code'),
        (0x1fae, 0x2000, 'word'),    # 0xFF padding + trailing checksum word
    ],
    0x4000: [  # m40rom-6.0
        (0x0000, 0x0008, 'word'),
        (0x0008, 0x0028, 'ascii'),
        (0x0028, 0x00ce, 'word'),
        (0x00ce, 0x00f6, 'code'),
        (0x00f6, 0x0106, 'word'),
        (0x0106, 0x2996, 'code'),
        (0x2996, 0x4000, 'word'),
    ],
}

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def objdump_code(binpath, start, stop):
    r = run([ODP, "-D", "-b", "binary", "-m", "z8001",
             "--start-address=%d" % start, "--stop-address=%d" % stop, binpath])
    out = []
    for line in r.stdout.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\t([0-9a-f ]+?)\t+(.*)', line)
        if not m: continue
        addr = int(m.group(1), 16)
        raw = b""
        for tok in m.group(2).split():
            raw += bytes.fromhex(tok if len(tok) % 2 == 0 else "0"+tok)
        out.append((addr, raw, re.sub(r'\s+', ' ', m.group(3).strip())))
    return out

def split_mnem(text):
    p = text.split(" ", 1)
    return p[0], (p[1] if len(p) > 1 else "")

def direct_addr_operand(ops):
    """Return the address int if operand list holds a bare direct address."""
    for tok in ops.split(","):
        tok = tok.strip()
        mm = re.match(r'^(0x[0-9a-f]+)(\(r)?', tok)
        if mm and not tok.startswith("#") and not tok.startswith("@"):
            return int(mm.group(1), 16)
    return None

def collect(binpath, segmap):
    """Return per-segment instruction lists and the label target set."""
    segs = {}
    labels = set()
    for a, b, kind in segmap:
        if kind != 'code': continue
        insts = objdump_code(binpath, a, b)
        segs[a] = insts
        for addr, raw, text in insts:
            mn, ops = split_mnem(text)
            if mn in PCREL:
                t = direct_addr_operand(ops)
                if t is not None:
                    labels.add(t)
    return segs, labels

def is_long_form(raw, ops):
    """Long-form seg address = address word at byte 2 has bit15 set."""
    return direct_addr_operand(ops) is not None and len(raw) >= 4 and (raw[2] & 0x80)

def relabel(ops, labels):
    """Rewrite the direct address in a PC-relative operand to a label symbol."""
    def sub(m):
        t = int(m.group(0), 16)
        return "L_%04x" % t if t in labels else m.group(0)
    return re.sub(r'0x[0-9a-f]+', sub, ops)

def build(rom, binpath, segmap, segs, labels, force_word):
    lines = ["\t.z8001", "\t.text", "\t.org\t0", ""]
    linemap = {}   # source line index -> instr addr (for error repair)
    for a, b, kind in segmap:
        lines.append("! ---- 0x%04x .. 0x%04x  (%s) ----" % (a, b, kind))
        if kind == 'ascii':
            s = rom[a:b]
            lines.append('\t! "%s"' % "".join(chr(c) if 32<=c<127 else '.' for c in s))
            for i in range(a, b, 8):
                if i in labels: lines.append("L_%04x:" % i)
                lines.append("\t.byte\t" + ",".join("0x%02x" % c for c in rom[i:min(i+8,b)]))
        elif kind == 'word':
            for off in range(a, b, 2):
                if off in labels: lines.append("L_%04x:" % off)
                lines.append("\t.word\t0x%04x" % ((rom[off]<<8)|rom[off+1]))
        else:  # code
            for addr, raw, text in segs[a]:
                if addr in labels: lines.append("L_%04x:" % addr)
                mn, ops = split_mnem(text)
                if addr in force_word:
                    for off in range(0, len(raw), 2):
                        if (addr+off) in labels and off: lines.append("L_%04x:" % (addr+off))
                        w = (raw[off]<<8)|raw[off+1]
                        lines.append("\t.word\t0x%04x\t\t! %04x: %s" % (w, addr+off, text))
                    continue
                if is_long_form(raw, ops):
                    lines.append("\t.long_addr")
                if mn in PCREL:
                    ops = relabel(ops, labels)
                out = ("%s %s" % (mn, ops)).strip()
                linemap[len(lines)] = addr
                lines.append("\t%-34s! %04x: %s" % (out, addr, raw.hex()))
        lines.append("")
    return "\n".join(lines) + "\n", linemap

def assemble(src):
    # Assemble + LINK (no --relax): the link resolves ldar/relative relocations
    # so PC-relative label operands encode byte-exactly.
    with tempfile.TemporaryDirectory() as d:
        s=os.path.join(d,"r.s"); o=os.path.join(d,"r.o")
        c=os.path.join(d,"r.coff"); b=os.path.join(d,"r.bin")
        open(s,"w").write(src)
        r=run([AS,"-z8001",s,"-o",o])
        if r.returncode!=0: return None, r.stderr
        r=run([LD,"-mz8001","-Ttext","0",o,"-o",c])
        if r.returncode!=0 and not os.path.exists(c): return None, r.stderr
        run([OCP,"-S","-O","binary",c,b])
        return open(b,"rb").read(), None

def main():
    binpath, outp = sys.argv[1], sys.argv[2]
    rom = open(binpath,"rb").read()
    segmap = MAPS[len(rom)]
    segs, labels = collect(binpath, segmap)
    labels = {t for t in labels if t % 2 == 0 and 0 <= t < len(rom)}
    # A label must land on an instruction start; if it falls mid-instruction
    # (objdump mis-aligned a data table as code), force that instruction to
    # .word so the label can be placed per-word.
    force_word = set()
    for a, b, kind in segmap:
        if kind != 'code': continue
        starts = {addr for addr, _, _ in segs[a]}
        for addr, raw, _ in segs[a]:
            for off in range(2, len(raw), 2):
                if (addr+off) in labels and (addr+off) not in starts:
                    force_word.add(addr)
    for it in range(40):
        src, linemap = build(rom, binpath, segmap, segs, labels, force_word)
        # line-number -> addr map (1-based, header adds offset); recompute against src
        got, err = assemble(src)
        if err is not None:
            added = False
            for lm in re.finditer(r':(\d+): Error', err):
                ln = int(lm.group(1)) - 1  # 0-based index into lines list
                # find nearest code line at/above ln
                for probe in (ln, ln-1, ln+1):
                    if probe in linemap:
                        force_word.add(linemap[probe]); added=True; break
            if not added:
                print("ASM ERROR (unrepairable):\n"+err[:1500]); sys.exit(1)
            continue
        if got == rom:
            open(outp,"w").write(src)
            print("OK: %s reassembles byte-identical (%d bytes, iter %d, %d .word repairs)"
                  % (outp, len(rom), it, len(force_word)))
            return
        # diff -> map differing bytes to covering instrs
        n=min(len(got),len(rom))
        diffs=[i for i in range(n) if got[i]!=rom[i]] + list(range(n,max(len(got),len(rom))))
        addrset=set()
        for a,b,kind in segmap:
            if kind!='code': continue
            for addr,raw,_ in segs[a]:
                if any(addr<=d<addr+len(raw) for d in diffs): addrset.add(addr)
        new = addrset - force_word
        if not new:
            open(outp,"w").write(src)
            print("MISMATCH unrepairable: %d diffs (sizes %d/%d)"%(len(diffs),len(got),len(rom)))
            for i in diffs[:20]: print("  @0x%04x"%i)
            sys.exit(2)
        force_word |= new
    print("did not converge"); sys.exit(3)

if __name__ == "__main__":
    main()
