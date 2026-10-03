# Evidence for MAME changes

Under [`../../AGENTS.md`](../../AGENTS.md), every change to the external MAME
source is preceded by a note here: the documentation that supports it (page
and figure), the reasoning, the test, and afterwards the result. Notes named
`*.experiment.md` record changes that were tried and withdrawn.

## Changes now in MAME (branch `m40_z8010_sup_test`)

| Note | Change | Status |
|---|---|---|
| [uc-arbiter-nvi-latency-evidence.md](uc-arbiter-nvi-latency-evidence.md) | UC042: the arbiter raises NVI with the grant instead of after 50 µs; GO280: DREQ1 cleared when DACK1 goes active. Needed by MOS | Provisional: no MB15652 timing data |
| [z8001-pcseg-bit15-evidence.md](z8001-pcseg-bit15-evidence.md) | Z8001 keeps bit 15 of the PC segment word as loaded; settled on a physical Z8001 | Current |
| [go252-kdc-master-reset-evidence.md](go252-kdc-master-reset-evidence.md) | GO252: control write `03` discards pending keyboard data | Provisional: no GO252 keyboard-port documentation |
| [go252-chargen-evidence.md](go252-chargen-evidence.md) | GO252 draws text from the dumped GI 9428DS character ROM | Current |
| [upd7261-read-data-timing-evidence.md](upd7261-read-data-timing-evidence.md) | uPD7261 read, write and verify take a minimum per-sector time (HDC5F5 timed out) | Current |
| [go363-post-read-completion-evidence.md](go363-post-read-completion-evidence.md) | The HDC5F5 timeout analysis that led to the read-timing change | Historical |
| [go363-format-id-buffer-evidence.md](go363-format-id-buffer-evidence.md) | GO363 ID buffer for Verify ID after Format; register `0x41` drives the ninth head | Provisional (one DCOS path) |
| [upd7261-buffered-seek-evidence.md](upd7261-buffered-seek-evidence.md) | Buffered Seek and Recalibrate timing | Current |
| [upd7261-verify-id-ermap-evidence.md](upd7261-verify-id-ermap-evidence.md) | Verify ID during DCOS ERMAP formatting | Provisional |
| [UPD7261_DREQ_EVIDENCE.md](UPD7261_DREQ_EVIDENCE.md) | uPD7261 DMA requests at sector boundaries | Current |

## Experiments not applied

| Note | What was tried | Outcome |
|---|---|---|
| [go363-ermap-0d00-completion.experiment.md](go363-ermap-0d00-completion.experiment.md) | Board-level completion for ERMAP `0x0d00` | Failed; reverted |
| [upd7261-command-int-reset.experiment.md](upd7261-command-int-reset.experiment.md) | Recompute INT on command acceptance | Did not fix ERMAP; reverted |
| [upd7261-zero-distance-seek-timing.experiment.md](upd7261-zero-distance-seek-timing.experiment.md) | Completion time of a seek to the current cylinder | Rejected: no tried value fixed ERMAP |

The scripts and patches these notes cite as removed are in the git tag
`re-leftovers-archive`.
