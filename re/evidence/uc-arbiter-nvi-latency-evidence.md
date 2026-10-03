# UC042 arbiter: latency from a request strobe to NVI

Recorded 2026-10-02, before editing `src/devices/bus/olivetti_l1/uc.cpp` in
the external MAME tree. The user directed this change explicitly.

## Status of the evidence (read this first)

There is **no primary hardware documentation** for the MB15652 gate array's
timing. The CPU side of the argument is documented (Zilog manual, below);
the arbiter side is inferred from software that depends on it. Under
AGENTS.md this change would normally stay in the project. It is being made
on the user's instruction and must be treated as **provisional**.

## Behaviour being changed

`olivetti_l1_uc042_device::arb_update()` arms a 50 µs timer whenever a
channel is granted, and `arb_done()` asserts the CPU's NVI input when it
expires. The 50 µs figure was never taken from hardware: MAME_DRIVER.md §9
lists it as "chosen behaviorally, not from timing data", and HARDWARE.md
§4.1 calls it "a behavioral approximation pending MB15652 timing data".

The change asserts NVI as soon as the arbiter has a grant, with no delay.

## Documentation (CPU side)

Zilog *Z8000 CPU Technical Manual*, January 1983
(`reference/datasheets/Z8000_CPU_Technical_Manual_Jan83.pdf`):

- Section 9.6, printed page 9-14: "Interrupt requests are sampled during the
  penultimate clock cycle of each instruction; however, the decision to
  accept the request is made at the start of the next instruction and the
  instruction fetch is aborted if the pending interrupt is enabled. Thus if
  an interrupt request is pending during the execution of Enable Interrupt
  (or LDPS, LD FCW, SC or IRET which would enable the interrupt), the
  pending interrupt will be acknowledged after the execution of that
  instruction. For example, if a vectored interrupt is pending and the
  instruction sequence to be executed is `EI VI` / `DI VI` then the vectored
  interrupt will be acknowledged between the execution of the EI and DI".
- Section 7 (Exceptions), printed page 7-2: "Because masked interrupt
  requests are not retained by the CPU, the request signal must be asserted
  until the CPU acknowledges the request."

So an `EI NVI` / `DI NVI` pair takes exactly those interrupts whose request
line is already low in the penultimate clock of the `EI`, and a request that
arrives while NVI is masked is not remembered by the CPU: the source has to
hold the line.

## Software that depends on it

MOS ST506 starter (`reference/Disk Images (Stefano Marinelli + others)/Mos/
StarterST506.IMD`), kernel in segment 4, dispatcher request:

```
04:0F44  outb #0xff8b,rl0     ; arbiter: request channel 3
04:0F48  ei   nvi
04:0F4A  di   nvi
```

The code after `04:0F4A` assumes the NVI handler (which acknowledges with a
write to `0xFF83` at `04:0322`) has run. `EI NVI` is 7 clocks; the write
strobe of the `outb` falls in the last clocks of that instruction. For the
request to be low in the penultimate clock of the `EI`, the arbiter must
drive NVI within a few CPU clocks of the strobe: at 4 MHz, of the order of
1 µs, and in any case far less than 50 µs (about 200 clocks).

With the 50 µs delay the NVI line goes active after the `DI`, the dispatcher
never runs, and the kernel stops with indicator code 51 ("Fatal error due to
inconsistencies in the kernel data area", MOS Message Book, AUTODIAG/SYS-5).

## Test without changing MAME

`runs-archive/restore-hd-20260928/mos9/` ([screen](screenshots/restore-hd-20260928__mos9.png)): a debugger breakpoint at `04:0F4A`
re-executes the `EI NVI` at most 60 times per request (reset at `04:0F44`),
which keeps the window open for the 50 µs the model takes. Nothing else is
altered. The starter then runs to `ENTER DATE (MM/DD/YY) :`
(`mos9/s_0390.0.png`). Without the breakpoint it ends in the code 51 blink
loop (`mos1/`).

`runs-archive/restore-hd-20260928/mos8/arb.log` shows every channel-3 request
from `04:0F48` followed by its acknowledge at `04:0322` in that
configuration.

## Other users of the arbiter NVI (to re-test)

- ROM REL 6.0 self-test, `0x02A6–0x0320`: the first block requests channels
  1–3 while they are masked and expects no NVI; each later block writes one
  request with NVI disabled, then `ei nvi` and waits in a `jr` loop. Nothing
  there needs a delay: the request is held, so it is taken after the `ei`.
- UC3003 test 5 (re/hardware/uc/UC3003_NVI.md), UCV305, UCG304, UCY805 (disk A).
- BCOS II and OSLEM dispatchers (HARDWARE.md §4.1: "Control/release writes
  must not themselves start arbitration").

## Proposed change

In `uc.cpp`: remove `m_arb_timer` and `arb_done()`; in `arb_update()`
assert NVI when `grant` is non-zero and clear it otherwise. `nviack_r()` is
unchanged.

One consequence to check: `nviack_r()` clears the line at the acknowledge
and nothing re-asserts it until the next arbiter write, so a request that is
still pending after the handler returns is not delivered again. That is the
existing behaviour and is not changed here.

Regression set: disk-A UC3003, UCG304, UCV305, UCY805 with identical
keystrokes before and after; ROM self-test (boot); MOS ST506 starter with no
debugger; BCOS 3.3 floppy boot; `oslem7+` floppy boot; BCOS II boot from the
hard disk.

## Results (2026-10-02, change applied, uncommitted)

Runs are in `runs-archive/arb-latency-20261002/`, made with `scripts/harness/reg.sh`
(hard-disk boots) and `scripts/harness/diag.sh` (DCOS diagnostics); "old" is the binary before the
change (`m40.pre-arb`), "new" the binary with it. Screens were compared
pixel by pixel at every periodic screenshot.

| Test | Old | New |
|---|---|---|
| UCG304 (disk A 009, UC042 gate-array test), 1 cycle | `base-009` | identical; all 8 tests, `HARDWARE OK`, 0 errors (`new-009/s_0210.0.png`) |
| UC3003 (disk A 008), 1 cycle | tests 1–6 pass, test 7 `BANK FAULT(OR ROM SIZE WRONG)` (known) | identical |
| UCV305 (010), UCY805 (011) | stopped at the parameter prompts (generic keystrokes) | identical; the tests themselves were **not** run |
| ROM self-test + BCOS II 3.3 floppy boot to `DATE` | `reg-bcos33-old` | identical |
| `oslem7+` floppy boot to `DYSP OK== PRTR OK==` | `reg-oslem-old` | identical |
| BCOS II from the hard disk (patched ROM) to `PASSWORD :` | `reg-hd-old` | identical |

MOS ST506 starter, no debugger (`mos-new/`): the code 51 stop is gone; every
dispatcher request is acknowledged (`mos-new2/arb.log`). The starter then
stops with indicator code 34 at about 93 s, before it touches the GO363.

Cause of the code 34, as far as traced:

- The driver-initialisation loop in segment `21` copies a routine to
  `0B:20F4` (`ldirb` at `21:3194`, source `21:59F4`) and calls it; the source
  is wrong, so the call returns garbage and the loop reports 34.
- The source is wrong because 960 bytes of segment `21` from `21:5570` are
  shifted up by one word: the word `0016` at `21:556E` appears again at
  `21:5570`, and the block is back in step at `21:5930`
  (`wr-old/k21.asm` against `wr-new/k21.asm`). On the floppy this is
  cylinder 47, head 1, sector 20, offset `0xAE`: the middle of a sector.
- No CPU write puts that data there (`phys2-new/phys.log`: the only CPU
  writes to physical `0x0DBB6C–73` are a zero fill at 84.59 s), so it comes
  from the GO280's DMA: one buffered word was stored twice and the transfer
  ended one word short.
- A 1 µs timer in place of the immediate assertion fails the same way
  (`mos-1us/`), so it is the changed interrupt timing the guest sees, not
  the way MAME raises the line.

With the old 50 µs delay plus the breakpoint hold the same transfer is
correct. What differs is when the dispatcher runs: with the short latency a
request made with NVI masked (`04:1118 outb #ff8b ; ret`) is delivered as
soon as the caller restores FCW (`04:1246` / `04:174E ldctl fcw,r0`), so
tasks are switched while floppy transfers are in progress. The cause of the duplicated
word is in the next section.

## The duplicated word: GO280 model, DREQ1 cleared through `synchronize()`

Found with temporary logging in `go280.cpp` (removed again; log in
`runs-archive/arb-latency-20261002/dmalog/error.log`). This is an emulator
scheduling fault, not a hardware behaviour: nothing about what the board
does is changed by the correction.

`dma_dack1_w()` dropped the channel-1 request with
`machine().scheduler().synchronize(... dma_channel1_clear ...)`. A
`synchronize()` callback only cuts the running device's timeslice short when
its timer becomes the head of the timer list (`emu/schedule.cpp`,
`emu_timer::adjust`). When another timer is already due (here, the one the
CPU queued for its own input-line change), the AM9517 keeps running to the
end of its slice, completes the channel-1 cycle with DREQ1 still set, and
starts a second one with the same buffered word. Normal and failing cycles
from the log:

```
92.7769920 DACK1 0   92.7769920 CLR1   92.7769923 CH1 0DBB6C wr 34E2   (normal)

92.7770240 DACK1 0   92.7770242 CH1 0DBB6E wr 0016   92.7770245 DACK1 end
92.7770240 CLR1  (runs late)
92.7770255 DACK1 0   92.7770258 CH1 0DBB70 wr 0016   (repeat, same word)
```

Correction: `dma_dack1_w()` calls `m_dmac->dreq1_w(0)` directly.

With both changes (`m40.arb-dmafix`):

- MOS ST506 starter, stock ROM, no debugger: `ENTER DATE (MM/DD/YY) :`
  (`mos-dmafix/s_0270.0.png`).
- UC3003, UCG304, BCOS II 3.3 floppy boot, `oslem7+` floppy boot, BCOS II
  from the hard disk: every screenshot identical to the old binary
  (`fix-008`, `fix-009`, `reg-*-fix`).
- FDU diagnostic XU6030 (disk D 007, `scripts/test-m40-fdu.sh`), including
  its DMA test: final screen identical to the old binary.
