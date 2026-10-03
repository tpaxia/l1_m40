#!/usr/bin/env python3
"""Copy IMD records verbatim, excluding only zero-filled out-of-range cylinders."""
import sys
from pathlib import Path

source, target, limit = sys.argv[1], sys.argv[2], int(sys.argv[3])
data = Path(source).read_bytes()
pos = data.index(0x1a) + 1
output = bytearray(data[:pos])
removed = 0
while pos < len(data):
    start = pos
    mode, cyl, head, count, size_code = data[pos:pos + 5]
    assert size_code < 7, "unsupported sector size"
    size = 128 << size_code
    pos += 5 + count * (1 + bool(head & 0x80) + bool(head & 0x40))
    empty = True
    for _ in range(count):
        kind = data[pos]
        pos += 1
        if kind == 0:
            continue
        assert 1 <= kind <= 8, "invalid IMD sector"
        length = size if kind & 1 else 1
        payload = data[pos:pos + length]
        assert len(payload) == length
        empty = empty and not any(payload)
        pos += length
    if cyl < limit:
        output.extend(data[start:pos])
    else:
        assert empty, f"refusing to omit nonzero cylinder {cyl}"
        removed += 1
with open(target, "xb") as out:
    out.write(output)
print(f"Copied retained track records byte-for-byte; omitted {removed} zero-filled records")
