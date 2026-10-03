# Drive-selection wiring audit

## Result (2026-09-10)

The local manuals establish the controller connector pinout and the drive's
jumper-selected inputs, but not the complete GO280 decoder-to-drive wiring.
Do not use these documents to claim controller code00 is intentionally
physical drive4. BCOS's observed FD4->code00 is software execution evidence,
not a recovered hardware truth table. No MAME changes were made for this audit.

## GO280 connector: verified directly from the diagram

Source: `reference/Manuals (Stefano Marinelli + Olivrea)/M30 - M40 - M31 Governi Mini Floppy-Floppy Descrizione di funzionamento.pdf`,
3963590 R(2), printed4-6 / PDF47. J131 is the 50-pin FDU connector;
J129 is the 34-pin MFDU connector.

| Signal | J131 FDU pin | J129 MFDU pin |
|---|---:|---:|
| SEL0F | 26 | 6 |
| SEL1F | 28 | 10 |
| SEL2F | 30 | 12 |
| SEL3F | 32 | 14 |

Section3.2, printed3-9/PDF20, identifies US000/US100 as the FDC's
two unit-select outputs. The block diagram printed2-4/PDF11 lists the
four peripheral select lines, but does not show the intervening decoder
gate connections or truth table. CF11051 and CF11050 diagrams on printed
3-25/3-26 describe Olibus/DMA and PLO logic, not that missing truth table.

## Drive jumper selection: verified, with applicability caveat

Source: `reference/Manuals (Stefano Marinelli + Olivrea)/FDU 990_Funzionamento.pdf`,
3961710 V(1), printed2-1/PDF22, figure2-1.

SEL1L, SEL2L, SEL3L, SEL4L are active-low inputs. A drive's jumper selects
which input it responds to. The diagram labels these S1/drive1 through
S4/drive4. Cable order does not itself set the drive number.

Important: this is an AT068/AT079 drive-level description, not a complete
GO280 installation diagram. The earlier block diagram printed1-1/PDF7
explicitly labels its controller interface GO152. Identical-looking SEL
names with different suffixes are not sufficient proof of their pin mapping.

## AM001 is a different connection path

Same FDU990 manual, printed4-1/PDF68: AM001 adapts controllers designed for
FDU999 to FDU990. It has separate connectors J131/J134 for two drives and
selects both drives when the adapter is selected. Printed4-8/PDF75 describes
binary SEL1F/SEL2F inputs and jumper-selected adapter decoding. It is not
evidence that GO280's four one-hot SEL0F–SEL3F outputs go through AM001.
Do not splice the AM001 diagram into the GO280 chain without an installation
schematic establishing that topology.

The separate service PDF `fdu990.pdf` contains an installation supplement
657.26.1-G.01 (PDF60–62) describing AM001 configurations, including a
two-enclosure limit for that configuration and an AT068 jumper at5–13.
That is not a blanket two-drive limit for GO280 and not a general jumper
prescription for a direct GO280 installation.

## Missing evidence needed to close the table

The functional manual references the M30/M40 electrical schematic collection
3963950 W. The FDU manual references FDU990 schematics3962000 P. Full relevant
schematic sheets were not found in the local manual inventory (some other
collections are index-only). Need the GO280 FDC US000/US100 decoder sheet
and the applicable cable/drive-input pinout, or continuity measurements on
the actual board/cable. Until then the US bits -> SELnF -> SELnL/Sn mapping
must remain unverified; no speculative drive renumbering is warranted.
