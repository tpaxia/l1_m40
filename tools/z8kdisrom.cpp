// Linear Z8001 (segmented) disassembler driver for the Olivetti M30/M40 ROMs.
// Usage: z8kdisrom <rom> [start_hex] [end_hex]
//   Defaults: start = reset PC offset (word @ 0x0006), end = EOF.
// Prints: OFFSET:  raw-bytes   mnemonic
#include "z8kdis.h"
#include <cstdio>
#include <cstdint>
#include <vector>
#include <string>

static std::vector<uint8_t> load(const char* p) {
    std::vector<uint8_t> v;
    FILE* f = fopen(p, "rb");
    if (!f) { perror("open"); return v; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    v.resize(n); if (fread(v.data(), 1, n, f) != (size_t)n) v.clear();
    fclose(f); return v;
}

static uint16_t be16(const std::vector<uint8_t>& d, size_t o) {
    return (uint16_t)((d[o] << 8) | d[o + 1]);
}

int main(int argc, char** argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s <rom> [start] [end]\n", argv[0]); return 1; }
    auto rom = load(argv[1]);
    if (rom.empty()) return 1;

    // Reset vector (Z8001 segmented): reserved@0, FCW@2, PC-seg@4, PC-off@6.
    uint16_t fcw = be16(rom, 2), pcseg = be16(rom, 4), pcoff = be16(rom, 6);
    fprintf(stderr, "; reset: FCW=%04x  PCseg=%04x(seg %d)  PCoff=%04x\n",
            fcw, pcseg, (pcseg >> 8) & 0x7f, pcoff);

    size_t start = pcoff, end = rom.size();
    if (argc >= 3) start = strtoul(argv[2], nullptr, 16);
    if (argc >= 4) end = strtoul(argv[3], nullptr, 16);

    z8k::Disassembler dis;
    size_t pc = start;
    while (pc < end) {
        auto inst = dis.disassemble(rom.data() + pc, rom.size() - pc,
                                    (uint32_t)pc, z8k::Mode::Segmented);
        int len = inst.length; if (len <= 0) len = 2;
        printf("%04zx:  ", pc);
        for (int i = 0; i < len; i++) printf("%02x", rom[pc + i]);
        for (int i = len; i < 8; i++) printf("  ");
        printf("   %s\n", inst.text.c_str());
        pc += len;
    }
    return 0;
}
