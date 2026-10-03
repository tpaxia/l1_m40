# PROVISIONAL experiment: GO363 board completion for DCOS ERMAP `0x0d00`

Status: **not proven / not applied**. Produced 2026-09-25 while chasing the
HDC5X3 ERMAP timeout. Kept in-project per AGENTS.md; the external MAME tree was
restored to its pre-experiment state afterwards.

## Why this was tried

The HDC5X3/ERMAP runs (findings now in `re/hardware/go363/GO363_HDC5_diagnostics.md`) showed that DCOS `007.HDC5X3` option 1 issues NEC `0x68`
(seek) plus board command `0x0d00`, then spins at linear `0x0312BE` on the flag
`<<3>>0x0166`. That flag is written only by DCOS's GO363 completion handler, and
no completion was being produced for `0x0d00`. The GO363 model already synthesises
a delayed completion for the Standard 24 setup command `0x0e00`, so the experiment
extended that same treatment to `0x0d00`.

## The experiment (relative to `src/devices/bus/olivetti_l1/go363.cpp`)

```diff
@@ io_w, board command decode (case 0x4d)
-		else if (m_board_command == 0x0e00)
+		else if (m_board_command == 0x0e00 || m_board_command == 0x0d00)
 		{
 			m_command_timer->adjust(attotime::from_msec(1));
 		}
@@ command_done
-	if (m_board_command == 0x0e00)
+	if (m_board_command == 0x0e00 || m_board_command == 0x0d00)
 	{
 		m_board_interrupt_pending = true;
 		m_interrupt = m_board_vi_enabled;
 		update_vi();
 		return;
 	}
```

## Result: FAILED, and it told us why

After the change and a rebuild, the format replay was repeated with a PC sampler
(`runs-archive/ermap-dump2/`, see `pc.txt`). The handler now runs exactly once
(`0x0411C0` appears once in the trace, and a VI is acknowledged at `0312BE`), but
the ERMAP spin loop is entered anyway:

```
distinct PCs after t=304 (order first-seen):
0312BE 272
0312C6 525
0411C0 1
```

So the completion was delivered, DCOS acknowledged it at `0312BE`, and then still
took the `jump if zero` path back to `0312BE`. That means the flag `0x030166` was
**not** set by that interrupt, because the interrupt did not present the vector
that DCOS's ERMAP program expects, or the completion arrived before ERMAP had
installed its handler. Either way, "just raise the ordinary board completion" is
insufficient, so the experiment was reverted.

Next hypothesis (unverified): ERMAP installs its own handler/vector (the same
program sets `0x4a = 0x30` three times) and the GO363 must present the completion
on the vector ERMAP's own handler is installed for — or the completion must be
deferred until after ERMAP reaches its wait loop (the `0x0e00` delay of 1 ms is
not obviously long enough here). A breakpoint on `0x030F22` (the flag writer) in
the emulator's debugger should settle which of the two it is; the earlier attempt
to use `cpu.debug:bpset` from `-autoboot_script` failed because `m.debugger` is nil
in that path, so use MAME's `-debug` or the `debugger` console instead.

## How to re-apply

The exact source state at the time of the experiment is captured in
`re/hardware/go363/leftovers/mame-worktree-20260925.patch` (removed; in tag `re-leftovers-archive`) (whole modified-tree diff as of 2026-09-25).
The experiment is the `0x0d00` addition shown above; apply it on top of that
snapshot, then rebuild with the normal M40 command in
`doc/MAME_DRIVER.md` §10.
