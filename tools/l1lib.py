#!/usr/bin/env python3
"""Inspect Olivetti L1 (M30/M40) OSLEM / BCOS II floppy images (.IMD).

Full format documentation: tools/L1_DISK_FORMATS.md (read it first).

Subcommands (IMG is an .IMD file):

  info IMG                 summary: labels, boot descriptor, library, configs
  boot IMG                 decode the track-0 OS (IPL) descriptor
  labels IMG               list track-0 label records (VOL1, HDR1, ERMAP, 0TOC ...)
  modules IMG [--sub]      list every sector-aligned module header
                           (--sub: also the sub-modules inside containers)
  dir IMG                  find and decode the library directory, checking each
                           entry against the module header it points to
  containers IMG           list container modules and their sub-modules
  config IMG               decode configuration modules (J0XP, J0X1, ...)
  extract IMG NAME [-o F]  write module NAME (header + data) to F
                           (NAME may be 'HDIR/E3#R' for a sub-module;
                            --index N picks a specific header sector)
  find IMG TEXT|--hex HEX  search the data area; report containing module
  versions IMG IMG ...     table of module versions across several images

Addresses: "index" = data-sector index (0 = cylinder 1 head 0 sector 1),
"flat" = byte offset in the data area (index * 256). Track 0 is separate.
"""
import argparse
import re
import struct
import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from l1disk import L1Disk  # noqa: E402

SECTOR = 256
# Module names: 4 characters. '#' is the Olivetti '£' (e.g. OSG# = OSG£).
NAME_RE = re.compile(rb'[A-Z0-9#$+/?@ ]{4}')  # name only; version may be binary
HEADER_FLAG_A = {0x00, 0x01, 0x02, 0x08, 0x0e, 0x10, 0x11, 0x1e, 0x80, 0x81, 0x88}
SUB_RE = re.compile(rb'[0-9A-F]{2}#[RI]')


# --------------------------------------------------------------------------
# image access

class Image:
    def __init__(self, path):
        self.path = path
        self.disk = L1Disk(path)
        self.t0 = self.disk.track0()
        raw = bytearray()
        i = 0
        while True:
            try:
                raw += self.disk.read(i, SECTOR)
            except Exception:
                break
            i += 1
        self.data = bytes(raw)
        self.nsec = len(self.data) // SECTOR
        self._headers = None

    def sector(self, index):
        return self.data[index * SECTOR:(index + 1) * SECTOR]

    # ---- module headers -------------------------------------------------
    def headers(self):
        """Sector-aligned module headers: list of Module."""
        if self._headers is None:
            out = []
            for idx in range(self.nsec):
                h = parse_header(self.data, idx * SECTOR)
                if h:
                    h.index = idx
                    out.append(h)
            self._headers = out
        return self._headers

    def module_at(self, flat):
        """Module whose header sector precedes flat (best effort)."""
        best = None
        for h in self.headers():
            if h.offset <= flat:
                best = h
            else:
                break
        return best


class Module:
    """A module header. Offsets are relative to the data area."""

    def __init__(self, data, offset):
        b = data[offset:offset + 0x20]
        self.offset = offset
        self.index = offset // SECTOR
        self.name = b[0:4].decode('latin1')
        self.version = b[4:8].decode('latin1')
        self.flag_a = b[8]
        self.flag_b = b[9]
        self.length = struct.unpack('>H', b[10:12])[0]
        self.word12 = struct.unpack('>H', b[12:14])[0]
        self.segment = struct.unpack('>H', b[14:16])[0]
        self.words = struct.unpack('>6H', b[0x14:0x20])  # +0x14..+0x1f
        self.raw = data

    @property
    def sectors(self):
        # header sector + data sectors (conservative; see L1_DISK_FORMATS.md)
        return 1 + (self.length + SECTOR - 1) // SECTOR

    def body(self):
        return self.raw[self.offset:self.offset + self.sectors * SECTOR]

    def is_container(self):
        return bool(self.sub_offsets())

    def sub_offsets(self):
        """Container sub-module offsets.

        u16 table at +0x1c; it ends at a 0 word or where the table reaches
        the first sub-module (whose offset is the first table value). Every
        entry must point at a module header inside the container. Seen:
        driver containers (HDIR/HDII/H65R: xx#R / xx#I sub-drivers, table
        ends at the first sub), program containers (DKDK, DKST: DKC#, SCT#
        ...), and code modules with appended sub-modules (KIO0: JMDU, JH24,
        JAPP; table ends with 0)."""
        b = self.raw
        o = self.offset
        end = o + 0x20 + self.length
        offs = []
        p = 0x1c
        while p < 0x60:
            v = struct.unpack('>H', b[o + p:o + p + 2])[0]
            if v == 0 or (offs and p >= offs[0]):
                break
            offs.append(v)
            p += 2
        if not offs or offs != sorted(offs) or len(set(offs)) != len(offs):
            return []
        if offs[0] < 0x1e or offs[0] % 2:
            return []
        for x in offs:
            h = parse_header(b, o + x)
            if not h or h.length < 0x10 or o + x + h.length > end + 0x20:
                return []
        return offs

    def subs(self):
        return [Module(self.raw, self.offset + o) for o in self.sub_offsets()]

    def describe(self):
        return (f'{self.name}{self.version}  flags={self.flag_a:02x}{self.flag_b:02x} '
                f'len={self.length:#06x} seg={self.segment:#04x}')


def parse_header(data, offset):
    b = data[offset:offset + 16]
    if len(b) < 16 or not NAME_RE.match(b):
        return None
    if b[:4] in (b'    ', b'////', b'@@@@'):
        return None
    if b[8] not in HEADER_FLAG_A:
        return None
    length = struct.unpack('>H', b[10:12])[0]
    if length == 0 or length > 0xfff0:
        return None
    return Module(data, offset)


# --------------------------------------------------------------------------
# track 0

def t0_labels(img):
    out = []
    for m in re.finditer(rb'VOL1|HDR1|ERMAP|0TOC|SYSCO|SSID|DDR1', img.t0):
        o = m.start()
        text = img.t0[o:o + 80]
        out.append((o, re.sub(rb'[^ -~]', b'.', text).decode().rstrip()))
    return out


def boot_descriptor(img):
    """Track-0 OS descriptor at 0x80: MVO quad + 16-byte module entries."""
    t = img.t0
    base = 0x80
    mvo = struct.unpack('>4H', t[base:base + 8])
    entries = []
    for k in range(base + 0x10, base + 0x70, 0x10):
        e = t[k:k + 16]
        if not any(e) or e[0] == 0xff:
            continue
        entry_seg, entry_off = e[0] & 0x7f, struct.unpack('>H', e[2:4])[0]
        load_seg, load_off = e[4] & 0x7f, struct.unpack('>H', e[6:8])[0]
        length = struct.unpack('>H', e[8:10])[0]
        cyl, head, sec = e[10], e[11], e[12]
        name = ''
        if 0 < cyl < 0xff and sec:
            idx = (cyl - 1) * 52 + head * 26 + sec - 1
            h = parse_header(img.data, idx * SECTOR) if idx < img.nsec else None
            name = h.name + h.version if h else '?'
        else:
            idx = None
        entries.append(dict(slot=k, entry=(entry_seg, entry_off),
                            load=(load_seg, load_off), length=length,
                            chs=(cyl, head, sec), index=idx, module=name,
                            raw=e.hex(' ')))
    tail = t[base + 0x70:base + 0x80]
    return dict(mvo=mvo, entries=entries, tail=tail)


# --------------------------------------------------------------------------
# library directory

def read_directory(img, di):
    """Directory at data index di: (header_entry, entries). Entry = name(4) +
    start(u16) + length(u16); start is 1-based and relative to di, so the
    module header sits at index di + start - 1. Entry 0 is the library
    header: name = library id, start field = number of entries (incl. 0)."""
    off = di * SECTOR
    count = struct.unpack('>H', img.data[off + 4:off + 6])[0]
    ents = []
    for i in range(min(count, 2048)):
        e = img.data[off + i * 8:off + i * 8 + 8]
        if len(e) < 8:
            break
        ents.append((e[:4].decode('latin1'),) + struct.unpack('>HH', e[4:8]))
    return ents[0] if ents else None, ents


def directory_index(img):
    """Directory location from the boot descriptor tail (t0+0xFE, 1-based);
    falls back to scanning when that does not look like a directory."""
    w = struct.unpack('>H', img.t0[0xfe:0x100])[0]
    if 0 < w <= img.nsec and _dir_score(img, w - 1) >= 3:
        return w - 1
    best = max(range(img.nsec), key=lambda di: _dir_score(img, di))
    return best if _dir_score(img, best) >= 5 else None


def _dir_score(img, di):
    off = di * SECTOR
    count = struct.unpack('>H', img.data[off + 4:off + 6])[0]
    if not (4 <= count <= 1024) or not re.match(rb'[ -~]{4}$', img.data[off:off + 4]):
        return 0
    score = 0
    for i in range(1, min(count, 40)):
        e = img.data[off + i * 8:off + i * 8 + 8]
        if len(e) < 8:
            break
        start = struct.unpack('>H', e[4:6])[0]
        hi = di + start - 1
        if 0 <= hi < img.nsec and img.data[hi * SECTOR:hi * SECTOR + 4] == e[:4]:
            score += 1
    return score


# --------------------------------------------------------------------------
# configuration modules

def decode_config(img, h):
    b = img.data[h.offset:h.offset + 0x60]
    res = [b[0x20 + i * 4:0x24 + i * 4].decode('latin1') for i in range(5)]
    return dict(name=h.name + h.version,
                resident=[r for r in res if r.strip()],
                mode=b[0x3c:0x40].decode('latin1'),
                start=b[0x40:0x44].decode('latin1'),
                word44=struct.unpack('>H', b[0x44:0x46])[0],
                name46=b[0x46:0x4a].decode('latin1'),
                layout_ok=all(re.match(r'[A-Z0-9# ]{4}$', r) for r in res))


# --------------------------------------------------------------------------
# commands

def cmd_boot(img, a):
    d = boot_descriptor(img)
    print('MVO quad: ' + '-'.join(f'{w:04X}' for w in d['mvo']))
    for e in d['entries']:
        c, h, s = e['chs']
        where = f"idx {e['index']:#06x}" if e['index'] is not None else ''
        print(f"  +{e['slot']:03x}  entry {e['entry'][0]:02X}:{e['entry'][1]:04X}  "
              f"load {e['load'][0]:02X}:{e['load'][1]:04X}  len {e['length']:#06x}  "
              f"C{c} H{h} S{s} {where}  {e['module']}")
    tail = d['tail']
    print('  tail +0f0: ' + tail.hex(' ') + '  ' +
          re.sub(rb'[^ -~]', b'.', tail).decode())


def cmd_labels(img, a):
    for o, text in t0_labels(img):
        print(f'  t0+{o:04x}  {text}')


def cmd_modules(img, a):
    for h in img.headers():
        print(f'{h.index:#06x}  flat {h.offset:#08x}  {h.describe()}  '
              f'sectors {h.sectors}' + ('  [container]' if h.is_container() else ''))
        if a.sub:
            for s in h.subs():
                print(f'          +{s.offset - h.offset:#06x}  {s.describe()}')


def cmd_containers(img, a):
    for h in img.headers():
        if h.is_container():
            subs = h.subs()
            print(f'{h.index:#06x}  {h.name}{h.version}  len={h.length:#06x}  '
                  f'seg={h.segment:#04x}  subs: ' +
                  ' '.join(f'{s.name}{s.version}' for s in subs))
            for s in subs:
                print(f'          +{s.offset - h.offset:#06x}  {s.describe()}')


def cmd_dir(img, a):
    di = a.index if a.index is not None else directory_index(img)
    if di is None:
        print('no library directory found')
        return
    head, ents = read_directory(img, di)
    print(f'directory at index {di:#x}  header {head[0]!r} entries={head[1]} '
          f'word={head[2]:#06x}')
    if True:
        for name, start, length in ents[1:]:
            hi = di + start - 1
            h = parse_header(img.data, hi * SECTOR) if 0 <= hi < img.nsec else None
            mark = 'ok ' if h and h.name == name else '-- '
            ver = h.version if h and h.name == name else ''
            print(f'   {mark}{name:4s} start={start:#06x} len={length:#06x} '
                  f'-> idx {hi:#06x} {ver}')


def cmd_config(img, a):
    for h in img.headers():
        if re.match(r'J0X.', h.name):
            c = decode_config(img, h)
            if not c['layout_ok']:
                print(f"{h.index:#06x}  {c['name']}  (other layout; raw +0x20: "
                      f"{img.data[h.offset + 0x20:h.offset + 0x50].hex(' ')})")
                continue
            print(f"{h.index:#06x}  {c['name']}  resident={' '.join(c['resident'])}  "
                  f"mode={c['mode']}  start={c['start']!r}  +44={c['word44']:#06x}  "
                  f"+46={c['name46']!r}")


def resolve(img, name, index=None):
    parts = name.split('/')
    cands = [h for h in img.headers() if h.name == parts[0]
             and (index is None or h.index == index)]
    if not cands:
        raise SystemExit(f'module {parts[0]} not found')
    if len(parts) == 1:
        return cands[0]
    for c in cands:
        for s in c.subs():
            if s.name == parts[1]:
                return s
    raise SystemExit(f'sub-module {parts[1]} not found in {parts[0]}')


def cmd_extract(img, a):
    h = resolve(img, a.name, a.index)
    if h.offset % SECTOR == 0 and '/' not in a.name:
        blob = h.body()
    else:
        blob = img.data[h.offset:h.offset + 0x20 + h.length]
    out = a.output or f"{h.name.replace('#', '_')}_{h.version.strip() or 'x'}.bin"
    open(out, 'wb').write(blob)
    print(f'{h.describe()}  at flat {h.offset:#x}: {len(blob)} bytes -> {out}')


def cmd_find(img, a):
    pat = bytes.fromhex(a.hex) if a.hex else a.text.encode('latin1')
    for m in re.finditer(re.escape(pat), img.data):
        o = m.start()
        h = img.module_at(o)
        where = f'{h.name}{h.version}+{o - h.offset:#x}' if h else '?'
        print(f'flat {o:#08x}  idx {o // SECTOR:#06x}+{o % SECTOR:#04x}  in {where}  '
              f'{img.data[o:o + 16].hex(" ")}')
    for m in re.finditer(re.escape(pat), img.t0):
        print(f'track0 +{m.start():#06x}')


def cmd_versions(a):
    imgs = [Image(p) for p in a.images]
    table = {}
    for n, img in enumerate(imgs):
        for h in img.headers():
            table.setdefault(h.name, [set() for _ in imgs])[n].add(h.version)
            for s in h.subs():
                table.setdefault(f'{h.name}/{s.name}', [set() for _ in imgs])[n].add(s.version)
    names = [p.rsplit('/', 1)[-1][:18] for p in a.images]
    print('module     ' + ''.join(f'{n:20s}' for n in names))
    for k in sorted(table):
        row = table[k]
        if a.common and sum(1 for s in row if s) < 2:
            continue
        print(f'{k:10s} ' + ''.join(f"{','.join(sorted(s)) or '-':20s}" for s in row))


def cmd_info(img, a):
    print(f'{img.path}\n  data sectors {img.nsec}, track0 {len(img.t0)} bytes')
    print('labels:')
    cmd_labels(img, a)
    print('boot descriptor:')
    cmd_boot(img, a)
    di = directory_index(img)
    if di is not None:
        head, ents = read_directory(img, di)
        print(f'library directory: index {di:#x}, header {head[0]!r}, '
              f'{head[1]} entries')
    print(f'module headers: {len(img.headers())}; containers: ' +
          ' '.join(h.name + h.version for h in img.headers() if h.is_container()))
    print('configuration modules:')
    cmd_config(img, a)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for c in ('info', 'boot', 'labels', 'containers', 'config'):
        s = sub.add_parser(c)
        s.add_argument('image')
    s = sub.add_parser('modules')
    s.add_argument('image')
    s.add_argument('--sub', action='store_true')
    s = sub.add_parser('dir')
    s.add_argument('image')
    s.add_argument('--index', type=lambda x: int(x, 0), help='directory data index')
    s = sub.add_parser('extract')
    s.add_argument('image')
    s.add_argument('name')
    s.add_argument('-o', '--output')
    s.add_argument('--index', type=lambda x: int(x, 0))
    s = sub.add_parser('find')
    s.add_argument('image')
    s.add_argument('text', nargs='?')
    s.add_argument('--hex')
    s = sub.add_parser('versions')
    s.add_argument('images', nargs='+')
    s.add_argument('--common', action='store_true',
                   help='only modules present on at least two images')
    a = p.parse_args()
    if a.cmd == 'versions':
        return cmd_versions(a)
    img = Image(a.image)
    globals()['cmd_' + a.cmd](img, a)


if __name__ == '__main__':
    main()
