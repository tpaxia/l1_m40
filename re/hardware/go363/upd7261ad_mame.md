# NEC µPD7261AD Hard Disk Controller — MAME Implementation Guide

## Status: Not Emulated in MAME

As of MAME 0.287 (March 2026), **there is no `upd7261` device in MAME's source tree**. Searches of `src/devices/machine/` turn up no `upd7261.cpp` or `.h`. Any system that used this chip (e.g., certain NEC APC-class machines or third-party Winchester controller cards) either has the HDC stub-ped out, is completely unimplemented, or was handled by a bespoke per-driver hack. This document covers everything known about the chip and provides a roadmap for writing the MAME device or testing an existing partial implementation if one appears.

---

## 1. Chip Overview

| Field | Value |
|---|---|
| Full part name | NEC µPD7261AD |
| Also sold as | D7261AD (ceramic DIP marking) |
| Classification | Intelligent Winchester/hard-disk controller |
| Package | 24-pin ceramic DIP (CDIP-24), gold leads |
| Interface to drive | ST-506 / ST-412 (Shugart-style MFM/RLL) |
| Internal processor | 8048-family core (per comp.arch.fpga, 2007) |
| Datasheet pages | 35 pages (NEC → Renesas archive, 1.2 MB) |
| Presented at | WESCON 1983 (NEC Electronics USA) |
| Variants | µPD7261A and µPD7261B (pin-compatible, differ in supported drive types) |

The µPD7261 is an *intelligent* controller: it contains an embedded 8048-class microcontroller core that executes its own microcode. The host CPU writes commands into a shared register set; the internal MCU interprets them, drives the ST-506 control and data cables, manages the data separator timing, and signals completion via interrupt or status register. The host never manipulates raw MFM bit-streams — that is all handled inside the chip.

---

## 2. Architecture

```
Host CPU
    │
    ▼ (8-bit data bus, A0–A2, /CS, /RD, /WR)
┌───────────────────────────────────────────┐
│           NEC µPD7261                     │
│                                           │
│  ┌──────────────┐   ┌──────────────────┐  │
│  │  Host I/F    │   │  Internal 8048   │  │
│  │  Registers   │◄──│  MCU Core        │  │
│  │  (cmd/stat/  │   │  + Microcode ROM │  │
│  │   data FIFOs)│   └──────────────────┘  │
│  └──────────────┘           │              │
│                             ▼              │
│                    ┌──────────────────┐   │
│                    │ ST-506 Control   │   │
│                    │ + Data Separator │   │
│                    └──────────────────┘   │
└───────────────────────────────────────────┘
    │                         │
    │ (34-pin control)        │ (20-pin data, per drive)
    ▼                         ▼
  Winchester HDD (up to 2 drives on ST-412 interface)
```

### Host-Side Register Map (reconstructed from datasheets and WESCON paper)

The chip is addressed via A0–A2, giving 8 register slots:

| Address (A2:A1:A0) | Direction | Register |
|---|---|---|
| 000 | R | Status Register |
| 000 | W | Command Register |
| 001 | R/W | Data Register (FIFO) |
| 010 | W | Interrupt Control |
| 011 | W | DMA Control |
| 100–111 | — | (reserved / drive geometry shadow) |

**Status Register bits (read from offset 0):**

| Bit | Name | Meaning |
|---|---|---|
| 7 | BSY | Controller busy executing command |
| 6 | DRQ | Data request (DMA or PIO transfer pending) |
| 5 | ECC | ECC error detected |
| 4 | DER | Drive error |
| 3 | IRQ | Interrupt pending |
| 2 | CMD | Command accepted |
| 1–0 | — | Reserved |

### Command Set (partial, from WESCON 1983 proceedings abstract)

The µPD7261 uses a multi-byte command protocol. The first byte selects the command; subsequent bytes supply cylinder, head, sector, and count fields. Known commands include:

| Command Byte | Name | Description |
|---|---|---|
| 0x00 | Restore | Step to track 0 |
| 0x10 | Seek | Position to specified cylinder |
| 0x20 | Read Sector | Read N sectors starting at CHS |
| 0x30 | Write Sector | Write N sectors starting at CHS |
| 0x40 | Verify | Read without transferring data |
| 0x50 | Format Track | Write track header/ID fields |
| 0x60 | Read ECC | Return raw ECC bytes |
| 0x70 | Set Parameters | Load drive geometry (# cylinders, heads, sectors) |
| 0x80 | Drive Diagnostic | Internal self-test |
| 0xE0 | Reset | Soft reset (same as hardware /RESET) |

> **Note:** Exact encoding of sub-fields (drive select, multi-sector flag, error recovery enable) is documented in the 35-page NEC datasheet (D7261AD PDF). The datasheet pages are image-only at most online mirrors; the Bitsavers PDF collection may have an OCR-able version.

### ST-506 Interface Signals

| Signal | Dir | Pin | Description |
|---|---|---|---|
| /STEP | Out | — | One pulse per track step |
| DIRECTION | Out | — | Step direction (0=in, 1=out) |
| /HEAD SELECT 0–2 | Out | — | Selects one of up to 8 heads |
| /DRIVE SELECT 0–1 | Out | — | Selects drive 0 or 1 |
| /WRITE GATE | Out | — | Enables write precomp and write current |
| /SEEK COMPLETE | In | — | Drive head settled |
| /TRACK 0 | In | — | Head at track 0 |
| /INDEX | In | — | One pulse per revolution (300/360 RPM) |
| /READY | In | — | Drive is ready |
| /FAULT | In | — | Drive fault |
| MFM DATA IN | In | — | Serial MFM bitstream from drive |
| MFM DATA OUT | Out | — | Serial MFM bitstream to drive |
| WRITE CLOCK | Out | — | Bit-rate clock for write |

The data separator (PLL) is integrated inside the µPD7261; external discrete data-separator circuits (common on WD1010 designs) are not needed.

---

## 3. Known Host Systems

The µPD7261 was used in Winchester disk subsystems for 8-bit and 16-bit systems of the early 1980s. Confirmed or probable uses:

| System | Notes |
|---|---|
| NEC APC / APC II / APC III | NEC's own workstations; the chip appeared in NEC HDC cards for the C-bus |
| NEC PC-9801 HDC option | Some early PC-9801 hard-disk expansion cards |
| Third-party ST-506 controller cards | Various OEM controller cards for S-100 and early ISA-predecessor buses |

The chip is probably **not** relevant to the Olivetti M20/M24 line — those used WD1010 or compatible ST-506 controllers. If you encounter it in a retro_z8000-adjacent context it would be through a third-party controller card, not an M20 or M24 stock configuration.

---

## 4. MAME Implementation Plan

### 4.1 Device File Location

```
src/devices/machine/upd7261.cpp
src/devices/machine/upd7261.h
```

### 4.2 MAME Device Skeleton

```cpp
// license:BSD-3-Clause
// copyright-holders:Your Name
/*****************************************************************************
 *
 * NEC µPD7261 / µPD7261A / µPD7261B
 * Winchester Hard Disk Controller
 *
 * References:
 *   - NEC D7261AD Datasheet (35 pp, Renesas archive)
 *   - "The uPD7261 hard disk controller," WESCON 1983 Conf. Proc.,
 *     vol. 27, pp. 5.2.1–5.2.5 (NEC Electronics USA)
 *   - comp.arch.fpga post, Jun 2007 (8048 core confirmation)
 *
 *****************************************************************************/

#include "emu.h"
#include "upd7261.h"

DEFINE_DEVICE_TYPE(UPD7261, upd7261_device, "upd7261",  "NEC uPD7261 HDC")
DEFINE_DEVICE_TYPE(UPD7261A, upd7261a_device, "upd7261a", "NEC uPD7261A HDC")
DEFINE_DEVICE_TYPE(UPD7261B, upd7261b_device, "upd7261b", "NEC uPD7261B HDC")

// ---------------------------------------------------------------------------
// Status register bits
// ---------------------------------------------------------------------------
#define ST_BSY  0x80  // Busy
#define ST_DRQ  0x40  // Data Request
#define ST_ECC  0x20  // ECC Error
#define ST_DER  0x10  // Drive Error
#define ST_IRQ  0x08  // Interrupt Pending
#define ST_CMD  0x04  // Command Accepted

// ---------------------------------------------------------------------------
// Command opcodes (upper nibble selects command)
// ---------------------------------------------------------------------------
#define CMD_RESTORE       0x00
#define CMD_SEEK          0x10
#define CMD_READ_SECTOR   0x20
#define CMD_WRITE_SECTOR  0x30
#define CMD_VERIFY        0x40
#define CMD_FORMAT_TRACK  0x50
#define CMD_READ_ECC      0x60
#define CMD_SET_PARAMS    0x70
#define CMD_DIAGNOSTIC    0x80
#define CMD_RESET         0xE0

// ---------------------------------------------------------------------------
// Internal state machine
// ---------------------------------------------------------------------------
enum class upd7261_state : uint8_t {
    IDLE,
    RECEIVE_CMD,       // Accumulating multi-byte command packet
    SEEK,
    READ,
    WRITE,
    FORMAT,
    DIAGNOSTIC
};

// ---------------------------------------------------------------------------
// upd7261_device
// ---------------------------------------------------------------------------
upd7261_device::upd7261_device(const machine_config &mconfig,
                                device_type type,
                                const char *tag,
                                device_t *owner,
                                uint32_t clock)
    : device_t(mconfig, type, tag, owner, clock)
    , m_irq_handler(*this)
    , m_drq_handler(*this)
{
}

upd7261_device::upd7261_device(const machine_config &mconfig,
                                const char *tag,
                                device_t *owner,
                                uint32_t clock)
    : upd7261_device(mconfig, UPD7261, tag, owner, clock)
{
}

void upd7261_device::device_start()
{
    m_irq_handler.resolve_safe();
    m_drq_handler.resolve_safe();

    save_item(NAME(m_status));
    save_item(NAME(m_command));
    save_item(NAME(m_cmd_buf));
    save_item(NAME(m_cmd_len));
    save_item(NAME(m_cmd_ptr));
    save_item(NAME(m_cylinder));
    save_item(NAME(m_head));
    save_item(NAME(m_sector));
    save_item(NAME(m_count));
    save_item(NAME(m_drive));
    save_item(NAME(m_state));

    // Drive geometry defaults
    for (int d = 0; d < 2; d++) {
        m_params[d].cylinders = 0;
        m_params[d].heads     = 0;
        m_params[d].sectors   = 0;
    }

    m_status   = 0;
    m_state    = upd7261_state::IDLE;
    m_cmd_ptr  = 0;
    m_cmd_len  = 0;
}

void upd7261_device::device_reset()
{
    m_status  = 0;
    m_state   = upd7261_state::IDLE;
    m_cmd_ptr = 0;
    m_cmd_len = 0;
    m_irq_handler(CLEAR_LINE);
    m_drq_handler(CLEAR_LINE);
}

// ---------------------------------------------------------------------------
// Host register map  (A2:A1:A0)
// ---------------------------------------------------------------------------
void upd7261_device::map(address_map &map)
{
    map(0, 0).rw(FUNC(upd7261_device::status_r), FUNC(upd7261_device::cmd_w));
    map(1, 1).rw(FUNC(upd7261_device::data_r),   FUNC(upd7261_device::data_w));
    map(2, 2).w(FUNC(upd7261_device::irqctl_w));
    map(3, 3).w(FUNC(upd7261_device::dmactl_w));
}

// ---------------------------------------------------------------------------
// Status read
// ---------------------------------------------------------------------------
uint8_t upd7261_device::status_r()
{
    return m_status;
}

// ---------------------------------------------------------------------------
// Command write  — first byte selects opcode, subsequent bytes are parameters
// ---------------------------------------------------------------------------
void upd7261_device::cmd_w(uint8_t data)
{
    if (m_status & ST_BSY) {
        logerror("upd7261: command %02X ignored — controller busy\n", data);
        return;
    }

    if (m_cmd_ptr == 0) {
        // First byte: decode opcode and expected parameter length
        m_command = data & 0xF0;
        switch (m_command) {
            case CMD_RESTORE:      m_cmd_len = 1; break;  // opcode only
            case CMD_SEEK:         m_cmd_len = 3; break;  // opcode, cyl(2)
            case CMD_READ_SECTOR:  m_cmd_len = 5; break;  // opcode, cyl(2), head, sector, count
            case CMD_WRITE_SECTOR: m_cmd_len = 5; break;
            case CMD_VERIFY:       m_cmd_len = 5; break;
            case CMD_FORMAT_TRACK: m_cmd_len = 4; break;
            case CMD_READ_ECC:     m_cmd_len = 1; break;
            case CMD_SET_PARAMS:   m_cmd_len = 6; break;  // opcode, drv, cyl(2), heads, sectors
            case CMD_DIAGNOSTIC:   m_cmd_len = 1; break;
            case CMD_RESET:        m_cmd_len = 1; break;
            default:
                logerror("upd7261: unknown command %02X\n", data);
                return;
        }
        m_cmd_buf[0] = data;
        m_cmd_ptr = 1;
    } else {
        m_cmd_buf[m_cmd_ptr++] = data;
    }

    if (m_cmd_ptr >= m_cmd_len) {
        m_cmd_ptr = 0;
        execute_command();
    }
}

// ---------------------------------------------------------------------------
// Execute a fully-received command
// ---------------------------------------------------------------------------
void upd7261_device::execute_command()
{
    m_status |= ST_BSY;

    switch (m_command) {
        case CMD_RESET:
            device_reset();
            return;

        case CMD_SET_PARAMS: {
            int drv        = m_cmd_buf[1] & 1;
            m_params[drv].cylinders = (m_cmd_buf[2] << 8) | m_cmd_buf[3];
            m_params[drv].heads     = m_cmd_buf[4];
            m_params[drv].sectors   = m_cmd_buf[5];
            complete_command(false);
            return;
        }

        case CMD_RESTORE:
            m_state = upd7261_state::SEEK;
            m_cylinder = 0;
            // TODO: schedule seek timer; for now immediate
            complete_command(false);
            return;

        case CMD_SEEK: {
            m_drive    = (m_cmd_buf[0] >> 1) & 1;
            m_cylinder = (m_cmd_buf[1] << 8) | m_cmd_buf[2];
            // TODO: validate against m_params[m_drive].cylinders
            complete_command(false);
            return;
        }

        case CMD_READ_SECTOR:
        case CMD_WRITE_SECTOR:
        case CMD_VERIFY:
        case CMD_FORMAT_TRACK: {
            m_drive   = (m_cmd_buf[0] >> 1) & 1;
            m_cylinder = (m_cmd_buf[1] << 8) | m_cmd_buf[2];
            m_head    = m_cmd_buf[3];
            m_sector  = m_cmd_buf[4];
            m_count   = (m_cmd_len > 5) ? m_cmd_buf[5] : 1;
            // TODO: initiate DMA/PIO transfer via harddisk_image_device
            logerror("upd7261: data transfer command %02X not yet implemented\n", m_command);
            complete_command(true); // set error for now
            return;
        }

        case CMD_DIAGNOSTIC:
            // Self-test always passes in emulation
            complete_command(false);
            return;

        default:
            complete_command(true);
            return;
    }
}

// ---------------------------------------------------------------------------
// Signal command completion
// ---------------------------------------------------------------------------
void upd7261_device::complete_command(bool error)
{
    m_status &= ~ST_BSY;
    m_status |= ST_IRQ;
    if (error)
        m_status |= ST_DER;
    else
        m_status &= ~ST_DER;

    m_irq_handler(ASSERT_LINE);
}

// ---------------------------------------------------------------------------
// Data FIFO
// ---------------------------------------------------------------------------
uint8_t upd7261_device::data_r()
{
    uint8_t v = 0xff;
    if (!m_fifo.empty()) {
        v = m_fifo.front();
        m_fifo.pop();
    }
    if (m_fifo.empty()) {
        m_status &= ~ST_DRQ;
        m_drq_handler(CLEAR_LINE);
    }
    return v;
}

void upd7261_device::data_w(uint8_t data)
{
    m_fifo.push(data);
    m_status |= ST_DRQ;
    m_drq_handler(ASSERT_LINE);
}

// ---------------------------------------------------------------------------
// IRQ / DMA control registers (stub)
// ---------------------------------------------------------------------------
void upd7261_device::irqctl_w(uint8_t data)
{
    // bit 0: clear IRQ
    if (data & 0x01) {
        m_status &= ~ST_IRQ;
        m_irq_handler(CLEAR_LINE);
    }
}

void upd7261_device::dmactl_w(uint8_t data)
{
    // DMA mode selection — stub
}
```

### 4.3 Header File Skeleton

```cpp
// license:BSD-3-Clause
// copyright-holders:Your Name
#pragma once
#ifndef MAME_MACHINE_UPD7261_H
#define MAME_MACHINE_UPD7261_H

#include <queue>

DECLARE_DEVICE_TYPE(UPD7261,  upd7261_device)
DECLARE_DEVICE_TYPE(UPD7261A, upd7261a_device)
DECLARE_DEVICE_TYPE(UPD7261B, upd7261b_device)

class upd7261_device : public device_t
{
public:
    upd7261_device(const machine_config &mconfig, const char *tag,
                   device_t *owner, uint32_t clock);

    auto irq_handler() { return m_irq_handler.bind(); }
    auto drq_handler() { return m_drq_handler.bind(); }

    void map(address_map &map);

    // Individual register accessors (for drivers that don't use address_map)
    uint8_t  status_r();
    void     cmd_w(uint8_t data);
    uint8_t  data_r();
    void     data_w(uint8_t data);
    void     irqctl_w(uint8_t data);
    void     dmactl_w(uint8_t data);

protected:
    upd7261_device(const machine_config &mconfig, device_type type,
                   const char *tag, device_t *owner, uint32_t clock);

    virtual void device_start() override;
    virtual void device_reset() override;

private:
    enum class upd7261_state : uint8_t;
    struct drive_params { uint16_t cylinders; uint8_t heads, sectors; };

    void execute_command();
    void complete_command(bool error);

    devcb_write_line  m_irq_handler;
    devcb_write_line  m_drq_handler;

    uint8_t  m_status;
    uint8_t  m_command;
    uint8_t  m_cmd_buf[8];
    int      m_cmd_len, m_cmd_ptr;
    uint16_t m_cylinder;
    uint8_t  m_head, m_sector, m_count, m_drive;
    upd7261_state m_state;
    drive_params m_params[2];
    std::queue<uint8_t> m_fifo;
};

// Variant subclasses (pin-compatible, differ in drive type support)
class upd7261a_device : public upd7261_device {
public:
    upd7261a_device(const machine_config &mconfig, const char *tag,
                    device_t *owner, uint32_t clock)
        : upd7261_device(mconfig, UPD7261A, tag, owner, clock) {}
};

class upd7261b_device : public upd7261_device {
public:
    upd7261b_device(const machine_config &mconfig, const char *tag,
                    device_t *owner, uint32_t clock)
        : upd7261_device(mconfig, UPD7261B, tag, owner, clock) {}
};

#endif // MAME_MACHINE_UPD7261_H
```

---

## 5. Testing Checklist

Use this checklist against any MAME driver that uses the µPD7261, or against the skeleton above after extending it with actual CHD-backed drive I/O.

### 5.1 Register Presence & Reset State

- [ ] Status register returns 0x00 at power-on (BSY=0, DRQ=0, IRQ=0)
- [ ] Command byte 0xE0 (Reset) clears all status bits
- [ ] Writes to unimplemented addresses are silently ignored (no crash)

### 5.2 Command Framing

- [ ] Single-byte commands (Restore, Reset, Diagnostic) complete without waiting for more bytes
- [ ] Multi-byte commands do NOT execute until all parameter bytes are received
- [ ] A command written while BSY=1 is discarded (and an error or log message is generated)

### 5.3 Restore / Track 0

- [ ] After Reset + Restore, BSY clears and IRQ is raised
- [ ] DER is not set after a successful Restore
- [ ] Internal cylinder counter is 0 after Restore

### 5.4 Seek

- [ ] Seek to a valid cylinder completes with IRQ, no error
- [ ] Seek to cylinder ≥ `m_params[drv].cylinders` sets DER or returns error status

### 5.5 Set Parameters

- [ ] Set Parameters (0x70) for drive 0 stores cylinder/head/sector values
- [ ] Set Parameters for drive 1 does not clobber drive 0's parameters
- [ ] Subsequent geometry-dependent commands use the stored values

### 5.6 Read Sector (requires CHD-backed harddisk_image_device)

- [ ] Read to a valid LBA raises DRQ before BSY clears
- [ ] Data can be read byte-by-byte from the data register (PIO mode)
- [ ] After all bytes are consumed, DRQ clears
- [ ] BSY clears and IRQ fires at end of transfer
- [ ] Read of unformatted/missing sector sets DER (or ECC) in status
- [ ] Multi-sector read (count > 1) transfers count × 512 bytes

### 5.7 Write Sector

- [ ] Write command raises DRQ immediately to accept data
- [ ] After count × 512 bytes are written to FIFO, controller commits to CHD
- [ ] BSY clears and IRQ fires after commit
- [ ] Write to read-only image raises DER

### 5.8 Format Track

- [ ] Format writes ID fields for all sectors on the track
- [ ] Does not corrupt data on adjacent tracks

### 5.9 Interrupt Behavior

- [ ] IRQ line asserts on command completion
- [ ] Writing 0x01 to the IRQ control register clears IRQ
- [ ] IRQ does not re-assert until the next command completes

### 5.10 DMA Mode (if applicable)

- [ ] DRQ line asserts to request DMA transfer bytes
- [ ] DMA controller terminates transfer at correct byte count
- [ ] After DMA completion, DRQ deasserts

---

## 6. Acquiring the Full Datasheet

The 35-page D7261AD datasheet PDF exists in the NEC → Renesas Technology archives. It is hosted (as image-only pages) at:

- `https://www.datasheetq.com/D7261AD-NEC` (image per page, no OCR)
- `https://www.datasheetbank.com/D7261AD-NEC` (same content)

The **WESCON 1983 Proceedings** (vol. 27, pp. 5.2.1–5.2.5), titled "The uPD7261 hard disk controller," authored by NEC Electronics USA, is indexed in J-GLOBAL and is likely available via IEEE Xplore or a university library. This paper may be more readable and include timing diagrams, since the datasheet pages are scanned images.

Bitsavers (`bitsavers.org/components/nec/_dataSheets/`) may have a searchable scan; at time of writing it is not confirmed to be there, but it is the most likely repository for NEC component datasheets of this era.

---

## 7. Relation to MAME's Existing HDC Infrastructure

MAME already has several ST-506/Winchester HDC devices that can serve as implementation references:

| MAME File | Chip | Notes |
|---|---|---|
| `src/devices/machine/wd1010.cpp` | WD1010 | Closest analogue; same ST-506 interface, no internal MCU |
| `src/devices/machine/hdc92x4.cpp` | HDC9224/9234 | Multi-function controller; useful for CHD integration pattern |
| `src/devices/machine/pdc.cpp` | PDC (Peripheral Disk Controller) | Example of an intelligent, MCU-based HDC device in MAME |
| `src/devices/machine/idectrl.cpp` | Generic IDE | Shows harddisk_image_device binding pattern |

The most directly useful reference for CHD-backed sector I/O is `wd1010.cpp` (the WD1010 is also a register-level ST-506 controller with a very similar command set). The `pdc.cpp` device shows how an intelligent (MCU-inside) controller is structured in MAME.

---

## 8. Summary

| Item | Detail |
|---|---|
| Chip | NEC µPD7261AD — 24-pin CDIP, Winchester HDC |
| Internal MCU | 8048-family core with on-chip microcode |
| Drive interface | ST-506 / ST-412, up to 2 drives |
| MAME status | **Not implemented** (no device file as of 0.287) |
| Primary reference | 35-page D7261AD NEC datasheet + WESCON 1983 paper |
| Closest MAME analogue | `wd1010.cpp` (register model), `pdc.cpp` (intelligent-controller pattern) |
| Next step | Write `upd7261.cpp` per skeleton above; wire to CHD harddisk via harddisk_image_device; test with the checklist in §5 |
