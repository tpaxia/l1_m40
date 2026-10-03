# GO252 keyboard port: control write `03` discards pending receive data

Recorded 2026-10-01, before editing `src/devices/bus/olivetti_l1/go252.cpp` in
the external MAME tree. The user directed this change explicitly.

## Status of the evidence (read this first)

There is **no primary hardware documentation** for the GO252 keyboard port.
The board carries an MC6845, the `MB15651` gate array, video RAM and a
character generator (HARDWARE.md §5); it has no discrete serial chip, so the
keyboard interface is inside the gate array, and `reference/ArchiviOlivetti/
M30-M40_KDC.pdf` is a catalogue page, not a manual (KDC.md "Source warning").
Under AGENTS.md this change would normally stay in the project. It is being
made on the user's instruction, on the software and firmware evidence below,
and must be treated as **provisional**.

## Behaviour being changed

MAME keeps bytes received from the keyboard in a 16-byte queue
(`m_kbd_fifo`). A write of `03` to the port's control register (GO252
register `0x00/0x01`) leaves that queue untouched. The change makes that
write discard the queued bytes and the pending-receive state.

## Evidence

1. **The control words are the MC6850's.** Software writes `03`, `16`, `96`
   and `B6` to GO252 register `0x01`. On an MC6850 these are: `03` master
   reset (CR1-0 = 11), `16` divide-by-64 with 8 data bits and 1 stop bit,
   `96` the same with receive interrupt enable (CR7), `B6` the same with
   transmit interrupt enable (CR6-5 = 01). The UC board's real `EF68B50P`
   ACIA at `0xFF20` gets the same `03` from the ROM (HARDWARE.md, `0xFF20`
   row). Motorola MC6850 data sheet, "Master Reset": the master reset clears
   the status register (except the external conditions on CTS and DCD) and
   initialises both receiver and transmitter; the Receive Data Register Full
   flag is therefore cleared and a byte received earlier is no longer
   presented.
2. **The OS driver resets the port and then expects no old data.** HD-booted
   BCOS (data set FF, `FE#I` in segment `38`): `38:02B2` writes `03`,
   `38:02B6` writes `16`, then `FE#R` (segment `3B`) enables receive (`96`).
   The keyboard driver `1KYB 2203` then takes the last byte received as a
   status byte and fails with `8B05` if bit 0 is set (`23:0942`
   `ldb rl0,rr4(#0x6f)`, `bitb rl0,#0`).
3. **The stale data exists only because of the queue.** The disk's boot
   stage (segment `20`, send routine `20:0346`) writes commands
   `00 02 05 07 09 04 06 08 0A` to the keyboard and reads nothing back.
   Command `02` makes the keyboard send `FB` and its strap byte
   (`keyboard/M40_8049_KEYBOARD.md`: command `02` → `FB`, config). The 8049 firmware
   has one byte of transmit storage and no FIFO (KDC.md §3), so on hardware
   those two bytes go out on the line when generated; what remains for a
   later reader is at most what the host's receive register holds. MAME
   keeps both bytes queued, and after the driver's reset delivers `FB F1`;
   `F1` has bit 0 set.
4. **Trace** (`runs-archive/restore-hd-20260928/install/hd65-kbio/`, patched ROM,
   baseline disk):

   ```
   KBW 1F01=03 pc=200198   KBW 1F01=16 pc=2001C6
   KBR 1F03=FC x32         (keyboard start-up byte, boot stage)
   KBW 1F03=00 02 05 07 09 04 06 08 0A   pc=200358
   KBW 1F01=03 pc=3802B2   KBW 1F01=16 pc=3802B6   KBW 1F01=96 pc=3B0420
   KBR 1F03=FB  KBR 1F03=F1   pc=3B06D0     <- stale reply to the boot stage's 02
   ```

5. **Independent check.** With the baseline disk and nothing else changed, a
   breakpoint at `20:0356` that turns the boot stage's `02` into the no-op
   command `0E` (so no reply is ever queued) lets BCOS II boot to its
   `PASSWORD :` prompt (`install/hd65-stale/`, 37,925 GO363 accesses against
   29,348 for the failing boot).

## What is not established

- That the gate array behaves like a 6850 in every respect; only the reset
  consequence is used here.
- Whether hardware would also lose the second of two unread bytes (receiver
  overrun). The queue is left in place for everything except the reset.

## Proposed change

In `olivetti_l1_go252_device::io_w`, control register case: when
`(data & 0x03) == 0x03`, empty `m_kbd_fifo` (`m_kbd_head`, `m_kbd_tail`,
`m_kbd_count` = 0) and clear `m_kdc_pending`, `m_kdc_data_armed`,
`m_kbd_ident_reply` and `m_kbd_poll_status`. The keyboard's own state
(`m_kbd_irq_mode`, the start-up `FC` timer) is not touched: before command
`00` the keyboard keeps sending `FC`, so the start-up byte reappears within
20 ms of a reset.

Regression set: HD boot of the baseline disk with no workaround; `oslem7+`
floppy boot; BCOS 3.3 floppy boot (`scripts/test-m40-bcos-single.sh`);
KEYTE1 keyboard diagnostic (`scripts/test-m40-keyte1-leds.sh`,
`scripts/test-m40-kdc-bit4.sh`).
