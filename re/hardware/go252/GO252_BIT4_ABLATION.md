# GO252 control-bit-4 ablation — 2026-09-15

Question: is the legacy bit-4 keyboard receive path needed by working BCOS?

Baseline MAME: olivetti_m40 at 7be8630dfb7. Temporary variant removed every
BIT(m_kdc_ctrl, 4) contribution in GO252 queueing, dequeueing, status, control
writes and VI gating. Bit-7 handling, TX bit 5, firmware-command mode flag,
and all other behavior were unchanged. This isolates the bit-4 dependency;
it does not replace the broader HLE keyboard model with verified hardware.

Fresh boots, ROM 6.0, -ram 2m, floppy IPL confirmed, isolated config/NVRAM,
working disk copies, headless, 160 emulated seconds. No saved-state replay
and no guest RAM or register patching.

| Disk/input | Baseline | Bit 4 removed | Result |
|---|---|---|---|
| K02733, keypad 860909+Enter at 100s, sys+Enter at 130s | kdc-bit4-config.euZl8A | kdc-bit4-config.vcdA6V | Both reach generator Continue/Exit page |
| BCOS_II_3.3_FD_ALL_RESIDENT, keypad Enter at 100s | kdc-bit4-resident.yxKXZn | kdc-bit4-resident.LS5GjY | Both reach password prompt |

Runs are under runs-archive. Each pair's final 159-screen.png files is byte-identical.
Thus bit 4 is not required for these tested boot/input paths on the current
emulator. This does not prove it has no hardware function, or validate complete
LOAD/RUN/BASIC sessions, every diagnostic, or other keyboard software.

The comment distinguishing BCOS bit 4 from diagnostic bit 7 predates later
BCOS bit-7 driver observations and should not be treated as a hardware fact.

Temporary scripts: scripts/test-m40-kdc-bit4.sh and scripts/lua/mame_kdc_bit4_probe.lua.
The initial control trace covered only 1000/1001 and missed other slot aliases;
its logs must not be used to claim a complete control-write sequence. The
observer now covers 1000–1fff and filters register offsets 00/01, but that
updated trace was not used for these four runs. Conclusions above rely on the
native ablation and visible input/output, not the incomplete trace.

Original GO252 source restored and normal executable rebuilt after the test.
No permanent MAME changes or push are part of this investigation.

## Follow-up: requested permanent removal and regression checks

The user subsequently requested removal. The current GO252 source removes
the five bit-4 contributions and the misleading three-line comment. The
baseline executable was preserved as /private/tmp/m40-bit4-baseline for
comparisons; the rebuilt default executable has bit 4 removed. No unrelated
GO252 behavior or anonymous-namespace comments were changed.

| Check | Baseline run | Removed-bit-4 run | Result |
|---|---|---|---|
| KEYTE1 startup, layout selection, A key | keyte1-leds.zMsRFO | keyte1-leds.4UEjzh | Identical final screen; key 09 received; LED command assertions pass |
| Fresh LOAD → eject → RUN → main Enter | bcos-generated-boot.AAYO0A | bcos-generated-boot.AtIcI1 | Identical password prompt |
| Gardini boot | kdc-bit4-gardini.ykDVis | kdc-bit4-gardini.aMEl6D | Identical utility menu |
| Logical keyboard/modifier/UI regression | Prior 210-case pass | host-keymap.Gw38Dh | All 210 cases pass |

All pairwise final screenshots are byte-identical. KEYTE1's event trace is
not identical: the baseline consumes an additional early FC startup byte,
and subsequent handshake timings differ slightly. The removed-bit-4 build
still completes initialization, receives the requested key, and satisfies
the observed LED-command checks. No adverse user-visible effect was found.

Limits: this is not a complete KEYTE1 pass (REPEAT/rollover remain incomplete),
not full LED TEST 3, and not a post-login BASIC session. The LOAD/RUN test ends
at the password prompt. Gardini was booted but its disk utilities were not run.
Native diff/build checks pass. Changes remain uncommitted and unpushed.
