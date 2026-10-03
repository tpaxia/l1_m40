# M40 HD branch split — 2026-09-15

Repository: `/Users/paxia/Projects/mame_latest/mame`.

- `olivetti_m40`, commit `e05bfe582c7`: removes experimental GO363 support.
- `olivetti_m40_hd`, commit `2396de81bb0`: restores that support as one feature
  commit on top of the HD-free base, suitable for later merge or cherry-pick.

The split covers GO363 source/header, its bus build registration, the M40
include and slot option, and the public uPD7261 register accessors. The base
uPD7261 files now match upstream. The HD branch preserves the exact committed
tree from before the split, including the experimental logging and geometry
responses; this operation does not claim those are ready for upstream.

The historical HD commit also included unrelated keyboard, video, floppy and
UC fixes. Those remain in the base, as does the physical FLOPPY/HD selector.
Selecting HD does not supply an HD controller on the base branch.

Existing uncommitted GO252 bit-4 removal and UC trace removal were preserved
in the current base working tree, not included in either split commit. Neither
branch was pushed. Older HD commits remain in history; the base's resulting
diff against upstream excludes HD support without rewriting branch history.

Validation: regenerated SDL3 M40 build passed; the rebuilt executable's
`-listslots` lists no GO363 option. The feature diff contains only the six
intended files. Its tree matches pre-split commit `7be8630dfb7` exactly.
No BCOS boot test was repeated for this optional-device separation.
