# Reassemble the M30/M40 ROM disassemblies to byte-identical binaries.
# Requires the patched z8k-coff binutils (adds .long_addr; a patched binutils 2.46.0 build).
AS      = z8k-coff-as
LD      = z8k-coff-ld
OBJCOPY = z8k-coff-objcopy
ASFLAGS = -z8001
LDFLAGS = -mz8001 -Ttext 0

ROMS    = m40rom-4.1 m40rom-6.0
ORIG    = ../../../reference/roms

.PHONY: all verify regen clean
all: $(addsuffix .bin,$(ROMS))

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

# Link (resolves ldar/relative relocations) then extract raw binary.
%.coff: %.o
	$(LD) $(LDFLAGS) $< -o $@ 2>&1 | grep -v 'entry symbol' || true

%.bin: %.coff
	$(OBJCOPY) -S -O binary $< $@

# Prove each rebuilt image is byte-identical to the original dump.
verify: all
	@for r in $(ROMS); do \
	  if cmp -s $$r.bin $(ORIG)/$$r; then echo "$$r: IDENTICAL"; \
	  else echo "$$r: DIFFERS"; exit 1; fi; done

# Regenerate the .s from the original ROMs (overwrites hand edits!).
regen:
	python3 ../../../tools/mkasm.py $(ORIG)/m40rom-4.1 m40rom-4.1.s
	python3 ../../../tools/mkasm.py $(ORIG)/m40rom-6.0 m40rom-6.0.s

clean:
	rm -f *.o *.bin
