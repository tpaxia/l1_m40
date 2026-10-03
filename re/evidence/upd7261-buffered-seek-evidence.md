# uPD7261 buffered seek and recalibrate timing evidence

## Primary hardware documentation

NEC, *uPD7261A/B Hard Disk Controller*, `reference/datasheets/NEC_uPD7261B_datasheet.pdf`:

- Printed page 6-19, Figure 3: bit 3 of the Seek (`0x6x`) and Recalibrate
  (`0x5x`) command bytes selects buffered mode when set. Thus DCOS commands
  `0x68` and `0x58` select buffered stepping.
- Printed page 6-21, Recalibrate, "Buffered Mode with Polling" and
  "Buffered Mode with Polling Disabled": the controller sends stepping
  pulses at approximately 50 microseconds between pulses. In nonpolling
  mode, command completion depends on track zero or the seek error limit.
- Printed pages 6-21–6-22, Seek, "Soft-Sector (Buffered Stepping...)":
  the controller sends high speed pulses; the drive asserts SKC after moving
  to the target cylinder. The normal stepping duration is an error deadline,
  not the duration to wait for a successful buffered seek. Figure 20 on
  printed page 6-36 illustrates the buffered seek sequence.

## Current emulator behavior and proposed change

`src/devices/machine/upd7261.cpp` in the external MAME tree logs bit 3 as
"buffered" but passes every Seek and Recalibrate through
`m_specify.stp(cylinders)`. That function computes the programmable normal
step time. With 924 cylinders, mode STP=8, and a 10 MHz controller clock,
the current formula schedules roughly 15.6 seconds; buffered pulses at
approximately 50 microseconds take roughly 46 milliseconds. The model has
no separate SKC input, so use the buffered pulse duration as its successful
completion approximation. Keep the existing normal-mode calculation when
bit 3 is clear. This does not assert that the physical drive always settles
at the final pulse; the exact SKC delay is not represented by this model.

## Independent software path and checks

Original DCOS Disk G image,
`reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD`:
the shared HDC routines issue `0x58` from linear `0x214a14` and `0x68` from
linear `0x215384` in the ERMAP option-1 and option-2 runs. The captured
register writes are in `runs-archive/ermap-wren2-20260925/error.log` (lines
150, 416, 544, 591, 707, and 754). The option-1 final Seek occurs before
the wait at linear `0x0312be`. DCOS program `007.HDC5X3` is described in
the contemporary Olivetti *M30 M40 Manuale dei collaudi*, section 17.6.

The two independent ERMAP menu paths both issue these buffered opcodes.
Their captured traces corroborate the bit interpretation and make the
completion timing observable; they do not establish the precise SKC delay.
After the timing change, inspect the option-1 and option-2 traces and the
preserved CHD to determine whether ERMAP progresses. A successful emulator
replay would corroborate the model but is not the basis for the hardware
behavior above.
