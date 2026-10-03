# Project rules

## Changes to MAME source outside this project

Before editing any MAME file outside this repository, find primary hardware
documentation that supports the specific behavior being changed. Suitable
evidence includes a manufacturer datasheet, hardware manual, or schematic.
Record the document, page or figure, the behavior it establishes, and the
reasoning that connects it to the proposed code change in this project first.

Emulator traces, software disassembly, and a passing test can corroborate a
change, but do not by themselves justify altering external MAME source. If
the documentation is missing or ambiguous, keep the proposed patch and test
results in this project and leave the external MAME source untouched. Preserve
unrelated local changes in the external tree.

For GO363, the available board description omits the register protocol. The
user has directed us to recover it from DCOS. A GO363 change may therefore
use the original DCOS diagnostic/installer code as primary behavioral evidence
when it is paired with the contemporary Olivetti diagnostic manual and, for
uPD7261 behavior, the NEC datasheet. Before editing external MAME, document
the exact DCOS binary location and instructions, the inferred register
behavior, and how an independent DCOS path or test checks that inference.
Label anything supported by only one software path as provisional and keep
it in this project until it is corroborated.
