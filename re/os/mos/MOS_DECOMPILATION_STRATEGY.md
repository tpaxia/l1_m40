# MOS decompilation: strategy

How to turn the Olivetti MOS 5.2 binaries into readable Pascal-like source,
using the original Olivetti development tools running on the emulated M40.
Nothing here has been started; this is the plan.

## Goal

Readable, reviewable Pascal-like pseudocode for chosen parts of MOS: first
small utilities, then drivers (ST506, floppy), then the kernel. Recovering
the whole system is not the goal. Where possible, output should be checked by
recompiling it with the original compiler and comparing the result.

## What we know

**Language.** Nothing found in the manuals says what MOS itself is written
in. They name PASCAL+ the systems language and say the driver and kernel
interfaces are "visible only to PASCAL+ users" (*Introduction to MOS*, Fifth
Edition, June 1987, Release 5.2, chapter 14 and the driver chapters). The
binaries agree:

- Compiled functions open with the same sequence: `sub r15,#n`,
  `ld @r14,#n+4` (a frame-size marker), `ldm …(r15),r2,#6` (arguments
  saved). It appears about 2,000 times in the MOS starter, about 8,800 times
  in the `DPC_ALLES` set, 93 times in kernel segment 4, and in the Pascal+
  compiler, ZPDIS and ZSTUB themselves.
- The starter carries the Pascal run-time error messages ("CASE LABEL NOT
  FOUND", "DISPOSE POINTER OUT OF RANGE", "SET RANGE OUT OF IMPLEMENTATION
  LIMITS", "RELEASE CALLED WITH NIL POINTER").
- The kernel also contains hand-written assembly: the dispatcher, the
  `ei nvi / di nvi` sequences, port I/O.

Caveat: the Fortran compiler may share the back end, so the entry sequence
alone does not prove Pascal.

**Tools on the installed system** (`m40-mos-hd.chd`, `/IPL/DPC`):

| Tool | What it is | Use here |
|---|---|---|
| `ZPC` | Olivetti Z8000 Pascal+ Compiler V2.0 (front end, code generator, disassembly pass) | Compile test programs to learn code patterns; recompile decompiled output |
| `ZPDIS` | Z8000 Pascal+ Disassembler 6.1 (Olivetti Advanced Technology Center, 1981–83) | Interleaved source/assembly listings of compiler object files |
| `ZLOC`, `OLINK` | Linkers; `ZLOC` writes `z.sym` and `z.map` | Learn the load-module layout and symbol format |
| `ZSTUB` | Builds `SYS_I`, `USR_I` and `TABLE` from module/procedure directives | Understand the call gates between modules |
| `DEB` | Debugger (likely the symbolic PASCAL+ debugger) | Inspect running code |
| `COMMON/LIB`, `COMMON/INTERF`, `COMMON/INCL` | Run-time and system libraries, interface objects, include files | Signatures for library calls; declarations, if the include files are source |

**Our own tools:** the MAME M40 with debugger (breakpoints, history,
watchpoints, memory dumps), the Z8000 disassembler library and round-trip
assembler flow used for the ROM (`re/disassembly/m40-rom/m40rom-6.0.s`), the floppy toolkit
(`tools/l1lib.py`), and the staged run harness with save states
(`scripts/mos-install/`; checkpoints in `runs-archive/mos-install-20261002/`).

**Manuals** in `reference/Manuals (Stefano Marinelli + Olivrea)/`: *Introduction
to MOS*, *Programmer Guide*, *Program Development Tools Reference*, *System
Software Generation and Installation*, *System Software Maintenance*.

## Phases

### 1. Get the binaries and their format

- Write a reader for the MOS file system on the hard-disk image (volumes,
  directories, files), so any file can be copied out without the emulator.
  The volume label and SSID structures are already partly known from the
  install work; the rest has to be worked out.
- Work out the load-module format: header, segments, relocation, entry
  points, and whether any symbol information survives. The *System Software
  Generation* manual (SYSCONF, SIPL, map files) and the `ZLOC` map output
  are the starting points.
- Cross-check with memory dumps from the running system in MAME: what a
  module looks like once loaded and relocated.

### 2. Look for source-level material first

Before decompiling anything, list and read `COMMON/INCL`, `COMMON/INTERF`,
`FORT/INCL` and similar directories. If the include files are Pascal+
source, they give record layouts, constants and procedure names for the
system interfaces, which would name a large part of what the decompiler
finds. Also check the shipped modules and libraries for symbol tables.

### 3. Build the compiler pattern catalogue

On the emulated MOS:

1. Write small Pascal+ test programs, one construct each: procedure entry
   and exit, parameters (value, `var`, records, arrays), locals, globals,
   `if`, `case` (jump tables), `for`, `while`, `repeat`, `with`, sets,
   strings, pointers and `new`/`dispose`, function results, nested
   procedures and static links, segmented pointers, monitors and processes
   (PASCAL+ concurrency), system calls.
2. Compile each with `ZPC`, with and without `-d`, and list it with `ZPDIS`.
3. Record each construct's exact Z8000 code as a pattern with its variable
   parts.

Getting source onto the system: type it through the scripted keyboard, or
better, write it into the disk image with the file-system writer from
phase 1.

### 4. Name the library calls

Build signatures for the routines in the run-time and system libraries
(`rtp_ui.lib`, `P_PAU_ui.lib`, `SYS.LIB`, the COBOL and BASIC run-times) and
match them in the MOS binaries, so calls to the run-time get their real
names, in the manner of IDA's FLIRT signatures.

### 5. Map the system interfaces

Use `ZSTUB`'s output format and the `TABLE`/`SYS_I`/`USR_I` structures to
find the service tables that connect user modules, drivers and the kernel.
Combined with the manuals' service descriptions, this names the kernel's
entry points.

### 6. The decompiler

A Python tool built on the existing disassembler:

1. Find functions from the entry sequence and call targets.
2. Build control-flow graphs; separate compiled functions from hand-written
   assembly (those stay assembly, annotated).
3. Apply the phase-3 patterns to recover expressions, statements, loops,
   `case` tables, parameter and local layouts.
4. Apply names from phases 2, 4 and 5; infer record layouts from offset use.
5. Emit Pascal-like source per module.

### 7. Validate by recompiling

Feed decompiled output back to `ZPC` and compare the generated code with the
original, function by function, as the ROM work already does for assembly
(`re/disassembly/m40-rom/README.md`, `make verify`). Differences point at wrong patterns or
types. Exact matches are the goal for small modules; for larger ones,
runtime comparison in MAME (traces of the original and the recompiled
module) is the fallback.

## Order of targets

1. Small `CMD` utilities (`LS`, `COPY`, `MKDIR`): short, well understood,
   good for tuning patterns.
2. `FLD` and `MKBOOT`: already exercised by the install, with known
   behaviour.
3. The ST506 and floppy drivers (configuration units 15 and 14): directly
   useful for the emulation.
4. Kernel modules, starting with the parts already traced (dispatcher,
   start-up, the indicator-code error paths).

## Risks and unknowns

- Symbols are probably stripped from the shipped modules; names may come
  only from interfaces, manuals and messages.
- The compiler on the disk (V2.0) may not be the one that built MOS 5.2.15,
  so some patterns may differ.
- The MOS file-system and load-module formats are not documented in what we
  have; they have to be worked out from code and data.
- Optimisations, if the compiler did any, make the patterns less regular.
- Typing source into the emulator is slow; phase 1's file-system writer is
  what makes phase 3 practical.

## First steps

1. List `COMMON/INCL`, `COMMON/INTERF` and `COMMON/LIB` on the running system
   and dump a few files.
2. Compile and list one trivial Pascal+ program with `ZPC` and `ZPDIS`, to
   confirm the tools work and see the output format.
3. Start the MOS file-system reader on `m40-mos-hd.chd`.
