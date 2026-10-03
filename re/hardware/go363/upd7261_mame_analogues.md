# µPD7261AD — MAME Analogues and Implementation Roadmap

This document examines the three closest MAME HDC implementations, analyses what each one contributes
to a µPD7261AD device, and provides a concrete derivation plan with annotated code.

---

## 1. Available Analogues in MAME

After reading the live source, the strongest candidates are:

| File | Device tag | Command model | Drive backend | Internal MCU? | Lines |
|---|---|---|---|---|---|
| `src/devices/bus/isa/hdc.cpp` | `xt_hdc_device` | 6-byte SCSI-like packets | `harddisk_image_device` via DMA/PIO | No | 1089 |
| `src/devices/machine/pdc.cpp` | `pdc_device` | Z80-hosted, channels to HDC9224 | `mfm_harddisk_connector` via `hdc9224_device` | Yes (Z80) | 594 |
| `src/devices/bus/isa/p1_hdc.cpp` | `p1_hdc_device` | Thin wrapper around `wd2010_device` | `HARDDISK` via WD2010 | No | 139 |

### 1.1 `xt_hdc_device` — `src/devices/bus/isa/hdc.cpp`

**What it is:** The IBM XT 8-bit ISA hard disk controller (WD1002 / Xebec 1210 clone). Emulates the
Shugart Associates System Interface (SASI) — a 6-byte command packet protocol that directly preceded
SCSI. The controller state machine lives entirely in software (no internal MCU modelled).

**Command packet structure (from source):**

```
Byte 0: command opcode
Byte 1: drive[5] | head[4:0]
Byte 2: cyl_h[7:6] | sector[5:0]
Byte 3: cylinder[7:0]
Byte 4: sector count
Byte 5: control (step rate, ECC/retry flags)
```

**Why it is the most useful starting point for µPD7261AD:**

The µPD7261A command protocol is structurally identical to SASI/XT-HDC — a fixed-width command
packet (5 or 6 bytes), drive/head encoding in byte 1, cylinder packed across bytes 2–3, count in
byte 4. The XT HDC implementation shows exactly how to:

- Buffer a multi-byte command, hold off execution until all bytes arrive (`m_data_cnt` countdown)
- Pack/unpack the CHS fields from the wire format
- Handle the `STA_COMMAND` / `STA_INPUT` / `STA_REQUEST` / `STA_INTERRUPT` status bus
- Implement the `dack_r` / `dack_w` pair for DMA transfers through `harddisk_image_device`
- Fall back to PIO when DMA is not selected (`no_dma()` / `CTL_DMA` bit)
- Return a command-status byte (CSB) with error elaboration bytes appended

The command set is also very similar. Direct mappings:

| XT HDC command | XT opcode | µPD7261 equivalent |
|---|---|---|
| TEST READY | 0x00 | — (absorbed into status register) |
| RECALIBRATE | 0x01 | RESTORE (0x00) |
| SENSE | 0x03 | read Status Register |
| FORMAT DRIVE | 0x04 | FORMAT TRACK (0x50) |
| VERIFY | 0x05 | VERIFY (0x40) |
| FORMAT TRACK | 0x06 | FORMAT TRACK (0x50) |
| READ | 0x08 | READ SECTOR (0x20) |
| WRITE | 0x0A | WRITE SECTOR (0x30) |
| SEEK | 0x0B | SEEK (0x10) |
| SET PARAM | 0x0C | SET PARAMETERS (0x70) |
| GET ECC | 0x0D | READ ECC (0x60) |
| RAM DIAG | 0xE0 | DIAGNOSTIC (0x80) |

**Key code patterns to adopt directly:**

```cpp
// — Status register bits (rename to match µPD7261 datasheet) —
#define ST_BSY  0x80   // was: not explicit in xt_hdc — BSY implicit while STA_COMMAND clear
#define ST_DRQ  0x40   // was: STA_REQUEST (0x10) + STA_COMMAND clear
#define ST_IRQ  0x08   // was: STA_INTERRUPT (0x20)

// — Multi-byte command accumulation (adopt verbatim) —
void upd7261_device::data_w(uint8_t data)
{
    if (m_data_cnt == 0) {
        m_current_cmd = data & 0xF0;
        switch (m_current_cmd) {
            // set m_data_cnt per command...
        }
    }
    m_buffer[m_buf_ptr++] = data;
    if (--m_data_cnt == 0)
        m_timer->adjust(attotime::from_msec(1)); // deferred execution
}

// — CHS unpack (adapt from get_chsn()) —
void upd7261_device::get_chsn()
{
    m_drv    = BIT(m_buffer[0], 1);          // drive select in opcode byte
    m_head   = m_buffer[1] & 0x0f;
    m_cylinder = (m_buffer[2] << 8) | m_buffer[3];
    m_sector   = m_buffer[4];
    m_count    = m_buffer[5];                 // µPD7261 has explicit count byte
}

// — DMA read path (adopt dack_r pattern) —
uint8_t upd7261_device::dack_r()
{
    if (m_dma_read == 0) {
        harddisk_image_device *hd = get_hd(m_drv);
        hd->read(get_lba(), m_dma_buf);
        m_dma_read = 512;
        m_dma_size -= 512;
        m_dma_src   = m_dma_buf;
        advance_sector();
    }
    uint8_t result = *m_dma_src++;
    if (--m_dma_read == 0 && m_dma_size == 0)
        complete_command(false);
    return result;
}
```

**What needs to change vs. xt_hdc:**

- Status register bits have different positions: µPD7261 uses bit 7=BSY, bit 6=DRQ, bit 3=IRQ.
  The XT HDC spreads these across STA_* constants in a different arrangement. Remap carefully.
- The XT HDC command byte encoding uses an upper nibble for drive select (bit 5 of byte 1).
  The µPD7261 encodes drive select in bit 1 of the command byte itself.
- The XT HDC always receives 6 bytes. The µPD7261 has variable-length packets (1–6 bytes depending
  on command). The countdown table needs adjustment.
- IRQ acknowledge is a write to a dedicated register (offset 2) on the µPD7261; the XT HDC uses
  `control_w()` with bit 1 to clear IRQ. This is a simple remap.
- SET PARAMETERS on the µPD7261 carries `cylinders` as a 16-bit big-endian field in bytes 2–3
  (same as XT HDC bytes 6–7 in the extended packet). Byte ordering matches; just move the fields
  forward by 1 slot.

---

### 1.2 `pdc_device` — `src/devices/machine/pdc.cpp`

**What it is:** The ROLM 9751 Peripheral Device Controller. A self-contained board with its own
Zilog Z80, an NEC uPD765A FDC, an SMC HDC9224 Winchester controller, and an Intel 8237 DMA
controller — all emulated as one `device_t`. The Z80 runs firmware from a 27128 ROM.

**Why it is relevant to µPD7261AD:**

The PDC is the only device in MAME that correctly models an *intelligent* peripheral controller —
i.e., one that has its own CPU executing firmware and presents a high-level command interface to the
host. The µPD7261A has exactly this structure: its internal 8048 core executes microcode; the host
sees only the command/status register pair.

The PDC shows:

1. **How to instantiate a real CPU as a sub-device** (`Z80` in PDC; would be `I8048` or a custom
   MCU for µPD7261) with its own address maps (`pdc_mem`, `pdc_io`).
2. **How the host-side interface is implemented separately from the MCU-side interface** — the host
   writes to shared registers (`reg_p0`–`reg_p7`), and the Z80 polls them. The µPD7261AD would use
   the same pattern: shared registers between the 8048-side and the host bus.
3. **How to wire DMA between the internal CPU and external system RAM** — the 8237 DMA channel 1
   moves data between the PDC's Z80 SRAM and the host M68K RAM via callbacks
   (`m_m68k_r_cb` / `m_m68k_w_cb`). The µPD7261 uses the same concept with its /DRQ signal.
4. **How to attach `mfm_harddisk_connector` with typed drive options** (ST-213, ST-225, ST-251,
   GENERIC) — this is the right way to attach ST-506/ST-412 drives in modern MAME.

**Key patterns to adopt from PDC:**

```cpp
// Drive attachment — use MFMHD instead of plain HARDDISK for ST-506 accuracy
static void upd7261_drives(device_slot_interface &device)
{
    device.option_add("generic", MFMHD_GENERIC);
    device.option_add("st213",   MFMHD_ST213);
    device.option_add("st225",   MFMHD_ST225);
    device.option_add("st251",   MFMHD_ST251);
}

void upd7261_device::device_add_mconfig(machine_config &config)
{
    // If modelling the 8048 core:
    // I8048(config, m_mcu, 6_MHz_XTAL);
    // m_mcu->set_addrmap(AS_PROGRAM, &upd7261_device::mcu_mem);
    // m_mcu->set_addrmap(AS_IO, &upd7261_device::mcu_io);

    // ST-506 drives (MFM byte-mode, 3000 RPM, 20ms seek rate)
    MFM_HD_CONNECTOR(config, "drive0", upd7261_drives, nullptr, MFM_BYTE, 3000, 20, MFMHD_GEN_FORMAT);
    MFM_HD_CONNECTOR(config, "drive1", upd7261_drives, nullptr, MFM_BYTE, 3000, 20, MFMHD_GEN_FORMAT);
}
```

**What to skip from PDC:**

- The PDC models the FDC (uPD765A) alongside the HDC — the µPD7261 is HDC-only.
- The PDC's Z80 runs actual ROM firmware, so it is testable against real code. The µPD7261's 8048
  microcode is internal to the chip and not separately ROM-dumpable; there is nothing to load. You
  therefore skip the MCU entirely and implement its behaviour in C++ directly (as the XT HDC does).
- The PDC's HDC9224 is already a separate, fully-implemented MAME device. For the µPD7261 you are
  writing the device itself, not wrapping another device.

---

### 1.3 `p1_hdc_device` — `src/devices/bus/isa/p1_hdc.cpp`

**What it is:** The Poisk-1 B942 MFM hard disk controller card, a Soviet XT clone that uses a
WD2010 chip (the register-compatible successor to WD1010). This is the thinnest possible ISA HDC
card wrapper in MAME — 139 lines total.

**Why it is useful:**

It shows the minimal bus-card pattern: install a ROM, install an I/O window, forward everything
into the chip device. For a µPD7261 ISA card wrapper (rather than the chip itself), this is the
template.

```cpp
// Minimal ISA card wrapper for µPD7261 — modelled on p1_hdc_device
class isa8_upd7261_device : public device_t, public device_isa8_card_interface
{
public:
    isa8_upd7261_device(const machine_config &, const char *, device_t *, uint32_t);

protected:
    virtual void device_add_mconfig(machine_config &) override;
    virtual void device_start() override;
    virtual void device_reset() override;

private:
    required_device<upd7261_device> m_hdc;

    uint8_t  hdc_r(offs_t offset) { return m_hdc->read(offset); }
    void     hdc_w(offs_t offset, uint8_t data) { m_hdc->write(offset, data); }
};

void isa8_upd7261_device::device_start()
{
    set_isa_device();
    // Map 8 registers at 0x320–0x327 (example; adjust per actual card)
    m_isa->install_device(0x0320, 0x0327,
        read8sm_delegate(*this, FUNC(isa8_upd7261_device::hdc_r)),
        write8sm_delegate(*this, FUNC(isa8_upd7261_device::hdc_w)));
    m_isa->set_dma_channel(3, this, false);
}
```

---

## 2. Recommended Derivation Strategy

The right approach is a hybrid of xt_hdc's command model and pdc's drive attachment:

```
xt_hdc_device                    pdc_device
      │                                │
      │  command accumulation          │  MFM_HD_CONNECTOR drive attachment
      │  CHS unpack                    │  devcb IRQ/DRQ pattern
      │  DMA dack_r/dack_w             │
      │  timer-deferred execution      │
      └──────────────┬─────────────────┘
                     ▼
              upd7261_device
         (new src/devices/machine/upd7261.cpp)
                     │
                     │  wrapped by
                     ▼
           isa8_upd7261_device
      (new src/devices/bus/isa/upd7261_isa.cpp)
```

### 2.1 Step-by-Step Derivation

**Step 1 — Copy xt_hdc_device state machine, strip ISA scaffolding**

Start with `hdc.cpp`'s `xt_hdc_device` class, extracted into a standalone
`src/devices/machine/upd7261.cpp`. Remove all ISA-bus code (`device_isa8_card_interface`,
`install_device`, `install_rom`). Keep:

- `m_buffer[8]` command accumulation
- `m_data_cnt` countdown
- `m_timer` deferred dispatch via `TIMER_CALLBACK_MEMBER`
- `m_cylinder[2]`, `m_head[2]`, `m_sector[2]`, `m_sector_cnt[2]`, `m_cylinders[2]`, `m_heads[2]`
- `dack_r()` / `dack_w()` / `m_hdcdma_*` fields
- `m_irq_handler` / `m_drq_handler` devcb lines

**Step 2 — Remap status register bits**

```cpp
// XT HDC → µPD7261 status bit remap
// XT: STA_READY(0x01) STA_INPUT(0x02) STA_COMMAND(0x04) STA_SELECT(0x08)
//     STA_REQUEST(0x10) STA_INTERRUPT(0x20)
// µPD7261 (from datasheet): BSY(0x80) DRQ(0x40) ECC(0x20) DER(0x10) IRQ(0x08) CMD(0x04)

#define ST_BSY   0x80
#define ST_DRQ   0x40
#define ST_ECC   0x20
#define ST_DER   0x10
#define ST_IRQ   0x08
#define ST_CMD   0x04   // command accepted / controller ready for next byte
```

**Step 3 — Adjust command packet lengths**

The XT HDC always expects 6 bytes (or 6+8=14 for SET PARAM). The µPD7261 varies:

```cpp
// In cmd_w(), first-byte handler:
switch (m_current_cmd) {
    case CMD_RESTORE:       m_data_cnt = 0; execute_now(); return;  // 1 byte only
    case CMD_SEEK:          m_data_cnt = 2; break;  // + cyl_h, cyl_l
    case CMD_READ_SECTOR:   m_data_cnt = 4; break;  // + cyl_h, cyl_l, head|sector, count
    case CMD_WRITE_SECTOR:  m_data_cnt = 4; break;
    case CMD_VERIFY:        m_data_cnt = 4; break;
    case CMD_FORMAT_TRACK:  m_data_cnt = 3; break;
    case CMD_READ_ECC:      m_data_cnt = 0; execute_now(); return;
    case CMD_SET_PARAMS:    m_data_cnt = 5; break;  // + drv, cyl_h, cyl_l, heads, sectors
    case CMD_DIAGNOSTIC:    m_data_cnt = 0; execute_now(); return;
    case CMD_RESET:         device_reset(); return;
}
m_status |= ST_BSY;
```

**Step 4 — Replace `HARDDISK` with `MFM_HD_CONNECTOR`**

Adopt the PDC's drive attachment. In `device_add_mconfig`:

```cpp
MFM_HD_CONNECTOR(config, "drive0", upd7261_drives, nullptr, MFM_BYTE, 3000, 20, MFMHD_GEN_FORMAT);
MFM_HD_CONNECTOR(config, "drive1", upd7261_drives, nullptr, MFM_BYTE, 3000, 20, MFMHD_GEN_FORMAT);
```

In `pc_hdc_file()` equivalent:

```cpp
mfm_harddisk_device *upd7261_device::get_hd(int drv)
{
    const char *tag = (drv == 0) ? "drive0" : "drive1";
    auto *conn = subdevice<mfm_hd_connector_device>(tag);
    if (!conn) return nullptr;
    return conn->get_device();
}
```

Note: `mfm_harddisk_device` uses `read_track()` / `write_track()` at the MFM stream level.
For a register-level emulation (no bitstream accuracy needed), you can instead use
`harddisk_image_device` directly (as xt_hdc does) and live with the slight inaccuracy. The
MFM connector gives you proper track-level timing if you eventually want to emulate the
data separator and ECC correctly.

**Step 5 — Wire IRQ acknowledge**

```cpp
// offset 2 = IRQ control register (µPD7261 specific)
void upd7261_device::irqctl_w(uint8_t data)
{
    if (data & 0x01) {        // bit 0 = clear IRQ
        m_status &= ~ST_IRQ;
        m_irq_handler(CLEAR_LINE);
    }
}
// Compare: xt_hdc uses control_w() testing bit 1 of the control byte
// Pattern is identical, just a different register offset
```

**Step 6 — Implement the ISA card wrapper**

Adopt `p1_hdc_device` structure verbatim, substituting `wd2010_device` → `upd7261_device`.

---

## 3. Files to Create / Modify

```
src/devices/machine/upd7261.cpp      ← new, ~300–400 lines
src/devices/machine/upd7261.h        ← new, ~80 lines
src/devices/bus/isa/upd7261_isa.cpp  ← new, ~120 lines (card wrapper)
src/devices/bus/isa/upd7261_isa.h    ← new, ~40 lines
src/devices/machine/CMakeLists.txt   ← add upd7261.cpp
src/devices/bus/isa/CMakeLists.txt   ← add upd7261_isa.cpp
```

---

## 4. Differences vs. Each Reference — Summary Table

| Aspect | xt_hdc_device | pdc_device | p1_hdc_device | **µPD7261AD target** |
|---|---|---|---|---|
| Command framing | 6-byte fixed | Z80 firmware | Via WD2010 | 1–6 bytes, variable |
| Drive byte position | Byte 1 bit 5 | N/A (HDC9224) | Via WD2010 | Byte 0 bit 1 |
| CHS cylinder bits | Byte 2[7:6] \| byte 3 | N/A | Via WD2010 | Byte 2 (hi) \| Byte 3 (lo) |
| Status bit layout | STA_* constants | reg_p39 | Via WD2010 | BSY=0x80, DRQ=0x40, IRQ=0x08 |
| IRQ clear method | `control_w` bit 1 | Z80 interrupt | Via WD2010 | Write 0x01 to offset 2 |
| Drive attachment | `HARDDISK` device | `MFM_HD_CONNECTOR` | `HARDDISK` | `MFM_HD_CONNECTOR` |
| Modelled MCU | None | Z80 + ROM | None | None (transparent) |
| DMA pattern | `dack_r/w` callbacks | 8237 DMA | Via WD2010 | Adopt `dack_r/w` from xt_hdc |
| PIO fallback | Yes (`no_dma()`) | N/A | Via WD2010 | Yes (same pattern) |
| SET PARAM format | 14-byte extended | N/A | Via WD2010 | 6-byte inline |

---

## 5. Concrete Starting Template

The fastest path to a working skeleton is to clone `xt_hdc_device` and apply the diffs described
above. Here is the minimal delta from xt_hdc to get a compilable µPD7261:

```diff
-DEFINE_DEVICE_TYPE(XT_HDC, xt_hdc_device, "xt_hdc", "Generic PC-XT Fixed Disk Controller")
+DEFINE_DEVICE_TYPE(UPD7261, upd7261_device, "upd7261", "NEC uPD7261 HDC")

-#define STA_READY     0x01
-#define STA_INPUT     0x02
-#define STA_COMMAND   0x04
-#define STA_SELECT    0x08
-#define STA_REQUEST   0x10
-#define STA_INTERRUPT 0x20
+#define ST_BSY  0x80
+#define ST_DRQ  0x40
+#define ST_ECC  0x20
+#define ST_DER  0x10
+#define ST_IRQ  0x08
+#define ST_CMD  0x04

 // In data_w(), first byte:
-m_data_cnt = 6;
-switch (data) {
-    case CMD_SETPARAM: m_data_cnt += 8; break;
-    ...
-}
+switch (m_current_cmd) {
+    case CMD_RESTORE:      execute_now(); return;
+    case CMD_SEEK:         m_data_cnt = 2; break;
+    case CMD_READ_SECTOR:  m_data_cnt = 4; break;
+    case CMD_WRITE_SECTOR: m_data_cnt = 4; break;
+    case CMD_VERIFY:       m_data_cnt = 4; break;
+    case CMD_FORMAT_TRACK: m_data_cnt = 3; break;
+    case CMD_READ_ECC:     execute_now(); return;
+    case CMD_SET_PARAMS:   m_data_cnt = 5; break;
+    case CMD_DIAGNOSTIC:   execute_now(); return;
+    case CMD_RESET:        device_reset(); return;
+}

 // In get_chsn():
-m_head[m_drv]     = m_buffer[1] & 0x1f;
-m_sector[m_drv]   = m_buffer[2] & 0x3f;
-m_cylinder[m_drv] = (m_buffer[2] & 0xc0) << 2 | m_buffer[3];
-m_sector_cnt[m_drv] = m_buffer[4];
+m_drv              = BIT(m_buffer[0], 1);
+m_cylinder[m_drv]  = (m_buffer[1] << 8) | m_buffer[2];
+m_head[m_drv]      = m_buffer[3];
+m_sector[m_drv]    = m_buffer[4] & 0x3f;
+m_sector_cnt[m_drv]= (m_cmd_len > 5) ? m_buffer[5] : 1;

 // In pc_hdc_result() / complete_command():
-m_status |= STA_INTERRUPT | STA_INPUT | STA_REQUEST | STA_COMMAND | STA_READY;
+m_status &= ~ST_BSY;
+m_status |= ST_IRQ;
+m_irq_handler(ASSERT_LINE);

 // Add IRQ-ack register (new):
+void upd7261_device::irqctl_w(uint8_t data)
+{
+    if (data & 0x01) { m_status &= ~ST_IRQ; m_irq_handler(CLEAR_LINE); }
+}
```

---

## 6. References

| Source | URL |
|---|---|
| xt_hdc_device (live) | `github.com/mamedev/mame/blob/master/src/devices/bus/isa/hdc.cpp` |
| pdc_device (live) | `github.com/mamedev/mame/blob/master/src/devices/machine/pdc.cpp` |
| p1_hdc_device (live) | `github.com/mamedev/mame/blob/master/src/devices/bus/isa/p1_hdc.cpp` |
| NEC D7261AD datasheet | datasheetq.com/D7261AD-NEC (35 pp, image-only) |
| WESCON 1983 paper | J-GLOBAL 200902000200264012 |
| WD1000 PR discussion | github.com/mamedev/mame/pull/5550 |

---

## 7. Embedding in a Machine Driver (Non-ISA Systems)

The ISA wrapper in §2 covers PC-style cards, but most systems that shipped a µPD7261 mapped it
directly into the host address space. This is also the pattern relevant to a Z8000-class machine.
The reference here is how `tekigw.cpp` embeds its wd1010:

```cpp
// From src/mame/tektronix/tekigw.cpp (Tektronix 6100) — wd1010 embedded directly:
map(0xfffb00, 0xfffb0f).rw(m_hdc, FUNC(wd1010_device::read), FUNC(wd1010_device::write)).umask16(0xff);
```

### 7.1 Machine Driver Embedding Template

```cpp
// In the system driver class:
class mysystem_state : public driver_device
{
public:
    mysystem_state(const machine_config &mconfig, device_type type, const char *tag)
        : driver_device(mconfig, type, tag)
        , m_maincpu(*this, "maincpu")
        , m_hdc(*this, "hdc")
        , m_pic(*this, "pic")        // interrupt controller, if present
        , m_dmac(*this, "dmac")      // DMA controller, if present
    { }

    void mysystem(machine_config &config);

private:
    required_device<cpu_device> m_maincpu;
    required_device<upd7261_device> m_hdc;
    required_device<pic8259_device> m_pic;
    required_device<am9517a_device> m_dmac;

    void mem_map(address_map &map);
};

// Address map — map the 4 (or 8) registers into host space.
// For a 16-bit host (Z8001, 8086), use umask16 to place the 8-bit
// registers on even or odd bytes as the board wiring dictates:
void mysystem_state::mem_map(address_map &map)
{
    // 8-bit host: direct
    // map(0xff80, 0xff87).m(m_hdc, FUNC(upd7261_device::map));

    // 16-bit host, registers on low byte of each word:
    map(0xff80, 0xff8f).m(m_hdc, FUNC(upd7261_device::map)).umask16(0x00ff);
}

// Machine config — instantiate the chip and wire the two output lines:
void mysystem_state::mysystem(machine_config &config)
{
    // ... CPU, RAM, etc. ...

    UPD7261(config, m_hdc, 10_MHz_XTAL);   // clock per board schematic

    // IRQ: route to the interrupt controller (or a CPU input line):
    m_hdc->irq_handler().set(m_pic, FUNC(pic8259_device::ir5_w));
    // Alternative, direct to CPU:
    // m_hdc->irq_handler().set_inputline(m_maincpu, INPUT_LINE_IRQ2);

    // DRQ: route to a DMA controller channel:
    m_hdc->drq_handler().set(m_dmac, FUNC(am9517a_device::dreq2_w));
    // DMA controller reads/writes the HDC data register during DACK:
    m_dmac->in_ior_callback<2>().set(m_hdc, FUNC(upd7261_device::dack_r));
    m_dmac->out_iow_callback<2>().set(m_hdc, FUNC(upd7261_device::dack_w));

    // Drives (declared inside upd7261's device_add_mconfig, or here explicitly):
    // MFM_HD_CONNECTOR defaults come from the device; override drive type per system:
    // subdevice<mfm_hd_connector_device>("hdc:drive0")->set_default_option("st225");
}
```

### 7.2 Embedding Checklist

- [ ] Decide register decode width: A0–A1 only (4 regs, /CS decodes rest) vs. full A0–A2.
      Boards commonly wire only A0 to the chip and decode /CS per-pair — check the schematic.
- [ ] On a 16-bit host, determine whether registers sit on even bytes (umask16(0x00ff)) or
      odd bytes (umask16(0xff00)); Z8001 byte lane wiring makes this easy to get backwards.
- [ ] IRQ polarity: the chip's INT output is active-high; if the board inverts it before the
      PIC, add `.invert()` to the devcb.
- [ ] If the host has no DMA controller, leave drq_handler unconnected and the device falls
      back to PIO through the data register (same as xt_hdc `no_dma()` path).
- [ ] Add the CHD hard disk to the software list or use `-hard1 image.chd` at the command line;
      geometry in the CHD metadata must match what the guest OS's SET PARAMETERS issues, or
      reads will land on the wrong LBA.
- [ ] For save-state support, all embedding-level latches (e.g. a board-level IRQ mask register)
      need their own `save_item` in the driver, separate from the chip's internal state.

### 7.3 Slot-Device Alternative

If the system had the HDC on an optional expansion board (rather than the motherboard), model it
as a slot card on the system's native bus instead of embedding it in the driver. This is the same
p1_hdc pattern from §1.3, substituting the bus type — e.g. a hypothetical Z8000-system bus card:

```cpp
class z8kbus_upd7261_device : public device_t, public device_z8kbus_card_interface
{
    // identical structure to isa8_upd7261_device in §2.1 Step 6,
    // with install_device() calls against the native bus instead of m_isa
};
```

This keeps the HDC optional per-machine (`-bus1 hdc7261`) and out of systems that shipped
without it.
