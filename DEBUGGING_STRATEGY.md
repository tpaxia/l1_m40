# How we debug the M40 emulation

The methods that worked while bringing up the M40 in MAME: the GO363 hard
disk, the BCOS II and MOS hard-disk installs, and the Z8001, keyboard-port,
bus-arbiter and floppy-DMA fixes. Each rule is followed by the case that
taught it.

## 1. Evidence before code

- Before changing external MAME source, record in this project the hardware
  documentation that supports the change: document, page, the behaviour it
  establishes, and why it leads to the change (`AGENTS.md`). Traces and
  passing tests corroborate; they do not justify a change on their own.
- Where no hardware documentation exists, the original Olivetti software is
  the specification. The GO363 register protocol was recovered from the DCOS
  diagnostics and checked against the Olivetti manual and the NEC uPD7261
  datasheet (`doc/GO363_DCOS_RECOVERY.md`).
- When a manual is ambiguous or wrong, measure the real chip. The Z8001
  PC-segment bit 15 was settled on the physical Z8001 test rig
  (the `z8000_test` rig of the separate Z8000_FPGA project), not from the Zilog manual, which says
  the opposite of what the part does (`re/evidence/z8001-pcseg-bit15-evidence.md`).
- Label anything that rests on a single source as provisional.

## 2. Let the original software be the test

- The DCOS diagnostics are the best oracle: they test one board at a time,
  print exact pass/fail results, and their code shows what the hardware must
  do. Running the real install procedures (Standard 24, HDC5X3, HDC5F5,
  LDHSEL, OSLEM, the MOS starter) found problems that synthetic tests would
  not.
- Use independent programs to cross-check one finding: if BCOS, OSLEM, MOS
  and a diagnostic all agree, the model is probably right; if only one path
  works, keep the change provisional.

## 3. Reproduce cheaply and deterministically

- Always work on disposable copies of disk images; never mount the source
  media writable.
- Script the runs headless (`-video none -nothrottle -seconds_to_run`) with a
  key-and-screenshot Lua script (`scripts/harness/run_keys.lua`)
  so a run can be repeated exactly.
- Checkpoint long procedures: save the machine state and snapshot the disk
  images at each stage, so any stage can be resumed
  (`scripts/mos-install/step.sh`). Save states depend on the
  build's saved fields; after changing a device's state, expect old states
  not to load.
- Compare screenshots by pixel data, not by file hash: MAME embeds its
  version in the PNG.

## 4. Find the first point of divergence

- When one configuration works and another fails, log the same events in
  both and diff them; the first difference is where to look. (MOS: the
  dispatcher request sequence diverged at the first deferred request.)
- When data is wrong, find which bytes differ, then find who wrote them. Watch
  the location; if no CPU write hits it, the writer is a DMA device. (MOS: a
  loaded block shifted by one word; no CPU store touched the physical
  address, so the fault was in the floppy DMA model.)
- Translate addresses carefully: segment numbers, MMU bases, and offsets
  into the original disk image are different spaces. Record verified
  mappings in the reference documents.

## 5. Test a hypothesis without changing the emulator first

- Debugger tricks can confirm a theory before any source edit: re-running an
  instruction to hold an interrupt window open, forcing a register, skipping
  a command. (MOS: holding the `ei nvi` window proved the arbiter-latency
  cause before `uc.cpp` was touched.)
- A workaround that "fixes" the symptom can hide a second bug. Once the real
  fix is in, re-test without the workaround. (MOS: the window hack masked the
  floppy DMA race, which appeared only once NVI timing was correct.)
- Temporary logging inside a device is acceptable to find a fault, as long
  as it is removed afterwards. (The GO280 DMA race was found by logging every
  channel-1 and channel-2 cycle.)

## 6. Prove the change does not break anything else

- Run the same set before and after each change, and compare every
  screenshot pixel for pixel: UC3003 and UCG304, the floppy diagnostic, BCOS
  II 3.3 from floppy, OSLEM 7+, BCOS II and MOS from the hard disk
  (`scripts/test-m40-hd.sh` does the last two automatically).
- Keep the binary from before the change (`m40.pre-…`) so "before" can be
  rerun at any time.

## 7. Write it down

- Evidence notes go in `re/` before the change, with results added after.
- When an investigation ends, move what was learned into the permanent
  reference documents and delete the working notes and experiment leftovers
  (scratch patches, temporary run output).
- Commit leftovers once before deleting them, so they stay in history. The
  probes, patches and logs from July to September 2026 are in the tag
  `re-leftovers-archive` under `re/**/leftovers/`; recover one with
  `git show re-leftovers-archive:<path>`. The notes that cite them mark
  them "(removed; in tag `re-leftovers-archive`)".

## MAME debugger and Lua techniques

- Breakpoint actions with `printf` and `history`, conditional breakpoints
  with `temp0`-style counters, and `dasm`/`dump` to save code and memory to
  files.
- `wpset` watches the program space; data writes need `wpdset` (and stack
  writes the stack space). A watchpoint on the wrong space silently never
  fires.
- Device internals can be read from Lua with
  `emu.item(dev.items["0/m_name"]):read(i)` without side effects. Reading
  memory through the CPU's address space from Lua goes through the MMU and
  can change its state; avoid it in a running guest.
- To find writes to a physical address, tap writes on the CPU spaces and
  translate each one with the MMU descriptors read through `emu.item`.
- Write taps on I/O ports (`install_write_tap`) give a cheap, timestamped
  event log of a device's register traffic.
- Practical pitfalls: only one breakpoint per address fires; breakpoints are
  not saved in save states (arm them from Lua after loading); `-debugscript`
  does not handle multi-line breakpoint actions well; MAME's natural keyboard
  does not type every character, so tap the key directly where needed.

## Related documents

- `AGENTS.md`: the evidence rule for external MAME changes
- `re/mame/MAME_diagnostic_trace_harness.md`: the diagnostic-disk harness
- `doc/GO363_DCOS_RECOVERY.md`, `re/hardware/go363/GO363_HDC5_diagnostics.md`: the hard-disk work
- `re/evidence/uc-arbiter-nvi-latency-evidence.md`: the arbiter and floppy-DMA case
- `re/evidence/z8001-pcseg-bit15-evidence.md`: settling a question on real silicon
