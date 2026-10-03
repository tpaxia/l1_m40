# Reverse engineering

The working notes behind the M40 emulation. The settled results are
collected in [`../doc/`](../doc/); this folder keeps the investigations, the
evidence for each emulator change, and the disassembled sources.

| Folder | Contents | Start with |
|---|---|---|
| [disassembly/](disassembly/README.md) | Round-trippable sources of the M40 ROMs and the DCOS bootloader; listings of diagnostic programs | [m40-rom/](disassembly/m40-rom/README.md) |
| [hardware/](hardware/README.md) | One folder per board: UC (central unit), GO252 (video/keyboard), GO280 (floppy), GO363 (hard disk) | [ROM_disassembly_findings.md](hardware/uc/ROM_disassembly_findings.md) |
| [os/](os/README.md) | One folder per operating system: BCOS II, OSLEM, MDOS, MOS, DCOS, and L1WSE on the M24 | [OS_boot_media_survey.md](os/OS_boot_media_survey.md) |
| [evidence/](evidence/README.md) | One note per change to MAME, written before the change: the documentation behind it, the test, the result | [uc-arbiter-nvi-latency-evidence.md](evidence/uc-arbiter-nvi-latency-evidence.md) |
| [mame/](mame/README.md) | The diagnostic trace harness, and dated records of the MAME branch work | [MAME_diagnostic_trace_harness.md](mame/MAME_diagnostic_trace_harness.md) |
| [checkpoints/](checkpoints/README.md) | Saved machine states and hard-disk images for resuming the BCOS and MOS installs | |

## Status words used in the indexes

- **Current**: describes the emulator and the machine as they are now.
- **Provisional**: rests on one source or on inference from software; see
  [`../AGENTS.md`](../AGENTS.md).
- **Historical**: a record of how something was found, or of a state the
  project has moved past. Its conclusions are carried by a current document.
- **Superseded**: replaced by another note; kept for its detail.

Many notes cite runs as `runs-archive/<run>/`. That folder is the local run
archive (git-ignored; backed up as described in
[evidence/screenshots/](evidence/screenshots/README.md)). The final screen of
each cited run is copied there and linked from the citation as `[screen]`.

Each note is dated in its own text; where a note and a `doc/` page
disagree, the `doc/` page is newer.
