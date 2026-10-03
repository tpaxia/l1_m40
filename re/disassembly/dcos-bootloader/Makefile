# Round-trip the SYS0 first-stage bootloader (track 0 of an L1 DCOS 8.4 diag
# disk) to a byte-identical image, then annotate. Requires the patched z8k-coff
# binutils (adds .long_addr; a patched binutils 2.46.0 build).
AS      = z8k-coff-as
LD      = z8k-coff-ld
OBJCOPY = z8k-coff-objcopy
ASFLAGS = -z8001
LDFLAGS = -mz8001 -Ttext 0

.PHONY: all verify regen clean
all: boot.bin.rebuilt

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

boot.coff: boot.o
	$(LD) $(LDFLAGS) $< -o $@ 2>&1 | grep -v 'entry symbol' || true

boot.bin.rebuilt: boot.coff
	$(OBJCOPY) -S -O binary $< $@

# Prove the annotated .s still reassembles to the original 512-byte bootloader.
verify: boot.bin.rebuilt
	@if cmp -s boot.bin.rebuilt boot.bin; then echo "boot: IDENTICAL"; \
	 else echo "boot: DIFFERS"; exit 1; fi

# Regenerate boot.s from boot.bin and re-annotate (overwrites hand edits!).
regen:
	python3 ../../../tools/mkasm.py boot.bin boot.s
	python3 ../../../tools/annotate_boot.py
	$(MAKE) verify

clean:
	rm -f *.o *.coff *.bin.rebuilt
