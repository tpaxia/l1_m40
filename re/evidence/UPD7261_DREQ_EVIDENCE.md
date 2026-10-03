# uPD7261 DMA request at sector boundaries

## Primary documentation

NEC, *uPD7261A/B Hard Disk Controller*, in
[`reference/datasheets/NEC_uPD7261B_datasheet.pdf`](../../reference/datasheets/NEC_uPD7261B_datasheet.pdf).
The source scan is available at
<https://deramp.com/downloads/mfe_archive/050-Component%20Specifications/NEC/NEC%20uPD7261B.pdf>.

- Printed page 6-10 (PDF page 8), “DMA Read Timing” and “DMA Write Timing”:
  DREQ is deasserted after the host's read or write transfer. The diagrams
  show the signal transition, but do not prescribe emulator function calls.
- Printed pages 6-23–6-24 (PDF pages 21–22), “Read Data”: after a sector is
  transferred, the controller updates the sector count and location. If
  sectors remain, DMA transfer restarts for the next sector.

The existing MAME `upd7261_device::data_r()` and `data_w()` reached the end
of a sector buffer with DREQ still asserted. The subsequent sector could not
produce a new DREQ assertion edge. The change deasserts DREQ when the buffer
is consumed, before the state timer advances to the next sector:

```cpp
if ((m_status & S_DRQ) && (m_buf_index == m_buf_count))
{
    set_dreq(false);
    m_state_timer->adjust(attotime::zero);
}
```

This applies to both data access methods. It is an implementation inference
from the documented DMA timing and multisection sequence, not a verbatim
instruction from the manual. A local scratch patch is stored as
`UPD7261_sector_dreq.patch`; the exact change is recorded here because this
repository ignores patch files.

With that patch and a *temporary experimental GO363 model*, the disposable
WREN2 image run observed 16 sector DMA transfers and a completion interrupt.
That test corroborates the uPD7261 fix; it does not establish correct GO363
register semantics or a completed Standard 24 installation. The experimental
GO363 edits were removed from external MAME source because the uPD7261 manual
does not document the GO363 board. The external MAME tree retains only this
uPD7261 change among edits made for this investigation; its unrelated
`src/mame/olivetti/m20.cpp` local modification was preserved.
