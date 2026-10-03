# M40 MMU cache-invalidation removal — 15 September 2026

Branch: `olivetti_m40`, base `ff05c043022`.

Removed the three `invalidate_caches()` calls from `uc.cpp::mmu_w`, and the
comment claiming they were required on mode writes. The mode-register shadow
and all translation/protection behavior remain unchanged. Existing GO252/GO280
register-naming edits were restored from their saved stash and preserved.

MAME's `memory_access_cache` caches memory-handler lookup, not RAM contents or
Z8010 address translations. The M40 handlers remain installed across MMU mode
changes and invoke translation for each access. Thus mode writes do not change
the cached handler. No replacement callback was added.

## Validation

Rebuilt SDL3 M40 successfully. All runs used BIOS 6.0, headless execution and
disposable disk copies. No native debug code was introduced.

- UC3003: tests 1–6 execute without a reported error, including the Z8010 trap
  request test, VIENO, timers, ACIA and both interrupt tests. Test 7 stops with
  `BANK FAULT(OR ROM SIZE WRONG)`, the previously documented endpoint for these
  parameters, not a new all-tests pass. Evidence:
  [screen](../../runs-archive/uc-validation.VPMPSE/screen.png).
- BCOS K02733: keypad date `860909`, then `sys` and keypad Enter reach the
  generator's Continue/Exit screen. Evidence:
  [screen](../../runs-archive/kdc-bit4-config.fQfg2C/159-screen.png).
- Generated BCOS: LOAD boot, eject at 90 seconds, insert RUN at 92, main Enter
  at 95 reach the password prompt. Evidence:
  [screen](../../runs-archive/bcos-generated-boot.Oi1VEl/159.png).

All three completed processes exited with status zero. No post-login BASIC
execution was tested in this run. This establishes no observed regression at
the tested endpoints, not exhaustive hardware correctness.

The initial default UC script stopped at the parameter dialog and was not a
diagnostic result (`uc-validation.qKvmwB`). The successful full invocation was:

```sh
scripts/test-m40-uc.sh '\n1\n008\n{WAIT:35}4\n{WAIT:12}\n\n\n{WAIT:8}\n{WAIT:5}1\n{WAIT:5}\n' 239 240
```

BCOS invocations:

```sh
BCOS_GENERATED_SWAP=1 BCOS_GENERATED_SECONDS=160 sh scripts/test-m40-generated-boot.sh
BCOS_KEYPAD=1 BCOS_TYPE=$'860909\n' BCOS_COMMAND=$'sys\n' sh scripts/test-m40-kdc-bit4.sh config
```

The removal is left uncommitted on `olivetti_m40`. Nothing was pushed; the
separate `z8010_bus_interface` branch was not changed.
