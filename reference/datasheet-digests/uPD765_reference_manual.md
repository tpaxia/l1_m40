# NEC µPD765 Floppy Disk Controller — Reference Manual

> **Device:** NEC µPD765A / µPD765B  
> **Compatible:** Intel 8272A, Zilog Z0765A, WD37C65, GM82C765B, UMC UM8272A  
> **Package:** 40-pin DIP (µPD765AC), 44-pin PLCC  
> **Process:** NMOS / CMOS (B-variant)  
> **Supply:** +5 V ±5 %, T_A = −10 °C to +70 °C

---

## Table of Contents

1. [Overview](#1-overview)
2. [Signal Description & Pin-Out](#2-signal-description--pin-out)
3. [System Interface](#3-system-interface)
4. [I/O Port Map](#4-io-port-map)
5. [Registers](#5-registers)
   - 5.1 Digital Output Register (DOR)
   - 5.2 Main Status Register (MSR)
   - 5.3 Data Register
   - 5.4 Status Register ST0
   - 5.5 Status Register ST1
   - 5.6 Status Register ST2
   - 5.7 Status Register ST3
   - 5.8 Digital Input Register (DIR) — AT/PS2
   - 5.9 Configuration Control Register (CCR) — AT/PS2
   - 5.10 Status Register A — PS/2
   - 5.11 Status Register B — PS/2
6. [Command Execution Model](#6-command-execution-model)
7. [Command Set — Complete Reference](#7-command-set--complete-reference)
   - 7.1 Read Data (06h)
   - 7.2 Read Deleted Data (0Ch)
   - 7.3 Write Data (05h)
   - 7.4 Write Deleted Data (09h)
   - 7.5 Read a Track / Read Diagnostic (02h)
   - 7.6 Read ID (0Ah)
   - 7.7 Format a Track (0Dh)
   - 7.8 Scan Equal (11h)
   - 7.9 Scan Low or Equal (19h)
   - 7.10 Scan High or Equal (1Dh)
   - 7.11 Recalibrate (07h)
   - 7.12 Sense Interrupt Status (08h)
   - 7.13 Specify / Fix Drive Data (03h)
   - 7.14 Sense Drive Status (04h)
   - 7.15 Seek (0Fh)
   - 7.16 Version (10h)
   - 7.17 Invalid Command
8. [Timing Parameters](#8-timing-parameters)
9. [DMA Interface](#9-dma-interface)
10. [Interrupt Behaviour](#10-interrupt-behaviour)
11. [Programming Guide](#11-programming-guide)
12. [µPD765A vs µPD765B Differences](#12-upd765a-vs-upd765b-differences)
13. [Compatible Devices](#13-compatible-devices)

---

## 1. Overview

The µPD765 is a single-chip Floppy Disk Controller (FDC) capable of controlling up to **four floppy disk drives** simultaneously. It implements the full **IBM Shugart-compatible** disk interface and offloads the majority of disk-control housekeeping from the host processor.

Key features:

- **15 executable commands** covering all read, write, format, seek, and scan operations
- Supports both **FM (single density)** and **MFM (double density)** recording modes
- Built-in **data separator** (VCO Sync output) reducing external component count
- **DMA and non-DMA** (interrupt-driven polled) transfer modes
- **Automatic polling** of up to four drives for the Ready signal between commands
- Generates **step pulses**, **head-select**, **direction**, and **write-gate** signals directly
- Compatible with the **uPD8257** and Intel 8237 DMA controllers
- Typical external support circuitry: ~5.5 TTL ICs for a complete FDC subsystem

The FDC is organised around a **register stack** accessed through a single data port (3F5h). A **Main Status Register** (3F4h) governs all handshaking with the host.

---

## 2. Signal Description & Pin-Out

### Host Interface

| Signal | Dir | Description |
|--------|-----|-------------|
| D7–D0 | Bidir | 8-bit bidirectional data bus |
| A0 | In | Address bit 0; selects MSR (0) vs Data Register (1) |
| /CS | In | Chip select (active low) |
| /RD | In | Read strobe (active low) |
| /WR | In | Write strobe (active low) |
| /RESET | In | Hardware reset (active low); clears all internal state |
| INT | Out | Interrupt request to CPU/PIC |
| DRQ | Out | DMA transfer request |
| /DACK | In | DMA acknowledge (active low) |
| TC | In | Terminal Count from DMA controller |

### Drive Interface (×4 drives via external demux)

| Signal | Dir | Description |
|--------|-----|-------------|
| /WE | Out | Write Enable / Write Gate |
| /WD | Out | Write Data (MFM/FM serial stream) |
| RD | In | Read Data (serial from drive) |
| /STEP | Out | Step pulse to stepper motor |
| DIR | Out | Step direction (1 = inward, 0 = outward) |
| /HDSEL | Out | Head select (0 = head 0, 1 = head 1) |
| /MO0–/MO3 | Out | Motor On, one per drive |
| /DS0–/DS3 | Out | Drive Select, one per drive |
| /TRK0 | In | Track 0 sense |
| /INDEX | In | Index hole sensor |
| /WPRT | In | Write Protect sense |
| /RDY | In | Drive Ready |
| /FAULT | In | Drive Fault (µPD765 only; not on 8272A) |

### Miscellaneous

| Signal | Dir | Description |
|--------|-----|-------------|
| VCO SYNC | Out | VCO synchronisation clock for external PLL/data separator |
| MFM | Out | High when in MFM mode; low when in FM mode |
| CLK | In | 8 MHz system clock (MFM) or 4 MHz (FM) |
| VCC | — | +5 V supply |
| GND | — | Ground |

---

## 3. System Interface

```
                    ┌──────────────┐
  CPU / DMA ────────┤  µPD765 FDC  ├──────── Floppy Drive(s)
  D[7:0], /RD, /WR  │              │  STEP, DIR, /WD, RD,
  A0, /CS, /RESET   │              │  /HDSEL, /WE, /TRK0,
  INT, DRQ, /DACK   │              │  /INDEX, /WPRT, /RDY
  TC                └──────────────┘
```

The chip requires minimal external glue:
- A **1-of-4 demultiplexer** (e.g. 74LS139) to decode /DS0–/DS3 from the two internal drive-select lines
- A **line receiver** for the Read Data path
- A **write precompensation** and **PLL/data separator** circuit (VCO SYNC output aids this)
- Optional **bus transceiver** for the data bus if board capacitance is high

---

## 4. I/O Port Map

All registers share the **same base address** pair. The primary controller occupies base `3F0h`; the secondary uses `370h`.

| Offset | Primary | Secondary | R/W | Register | System |
|--------|---------|-----------|-----|----------|--------|
| +0 | 3F0h | 370h | R | Status Register A | PS/2 only |
| +1 | 3F1h | 371h | R | Status Register B | PS/2 only |
| +2 | 3F2h | 372h | W | Digital Output Register (DOR) | All |
| +4 | 3F4h | 374h | R | Main Status Register (MSR) | All |
| +4 | 3F4h | 374h | W | Data Rate Select Register (DSR) | PS/2 only |
| +5 | 3F5h | 375h | R/W | Data Register (command/result/data) | All |
| +7 | 3F7h | 377h | R | Digital Input Register (DIR) | AT/PS2 |
| +7 | 3F7h | 377h | W | Configuration Control Register (CCR) | AT/PS2 |

**DMA channel:** 2 (fixed on PC-compatible systems)  
**IRQ line:** 6 (default; triggers INT 0Eh in the BIOS vector table)

> **Note:** The core µPD765 itself exposes only A0 for register selection. The full I/O map above describes the **PC-compatible** FDC subsystem built around it.

---

## 5. Registers

### 5.1 Digital Output Register (DOR) — 3F2h, Write Only

Controls drive motors, drive selection, DMA mode, and controller reset.

```
  Bit  7    6    5    4    3    2    1    0
      MOTD MOTC MOTB MOTA DMA REST DR1  DR0
```

| Bit(s) | Name | Description |
|--------|------|-------------|
| 7 | MOTD | Motor enable drive D: 1 = on, 0 = off |
| 6 | MOTC | Motor enable drive C: 1 = on, 0 = off |
| 5 | MOTB | Motor enable drive B: 1 = on, 0 = off |
| 4 | MOTA | Motor enable drive A: 1 = on, 0 = off |
| 3 | DMA | 1 = DMA + IRQ enabled; 0 = disabled |
| 2 | REST | 1 = FDC enabled; 0 = FDC held in reset |
| 1–0 | DR1:DR0 | Drive select: 00=A, 01=B, 10=C, 11=D |

**Important:**
- A drive **cannot be selected** unless its corresponding motor bit is also set (setting them simultaneously is valid).
- Writing `00h` to DOR performs a controller reset: all motors off, DMA disabled, REST=0.
- All DOR bits are cleared on a hardware /RESET.
- Drives C and D are not supported on all PC-compatible systems.

**Example — select and start drive A with DMA:**
```asm
mov al, 0x1C   ; MOTA=1, DMA=1, REST=1, DR=00
out 0x3F2, al
```

**Example — assert controller reset:**
```asm
mov al, 0x00
out 0x3F2, al
```

---

### 5.2 Main Status Register (MSR) — 3F4h, Read Only

The MSR **may be read at any time** during any phase of operation, including mid-command. It is the primary handshaking register.

```
  Bit  7    6    5    4    3    2    1    0
      MRQ  DIO NDMA BUSY ACTD ACTC ACTB ACTA
```

| Bit | Name | Description |
|-----|------|-------------|
| 7 | MRQ | Main Request: 1 = Data Register ready for I/O |
| 6 | DIO | Data I/O direction: 1 = FDC→CPU (read); 0 = CPU→FDC (write) |
| 5 | NDMA | 1 = non-DMA mode active; 0 = DMA mode |
| 4 | BUSY | 1 = FDC executing a command |
| 3 | ACTD | Drive D seek/recalibrate in progress |
| 2 | ACTC | Drive C seek/recalibrate in progress |
| 1 | ACTB | Drive B seek/recalibrate in progress |
| 0 | ACTA | Drive A seek/recalibrate in progress |

**Usage protocol for sending a command byte:**
```
poll MSR: wait until (MSR & 0xC0) == 0x80   ; MRQ=1, DIO=0
write byte to 3F5h
repeat for each command byte
```

**Usage protocol for reading a result byte:**
```
poll MSR: wait until (MSR & 0xC0) == 0xC0   ; MRQ=1, DIO=1
read byte from 3F5h
repeat for each result byte
```

> **Maximum polling timeout:** Allow up to 175 µs on Intel-compatible controllers; original µPD765 may be slower.

---

### 5.3 Data Register — 3F5h, Read/Write

The data register provides **indirect access** to an internal register stack. Command bytes, data, and result bytes all pass through this single port.

- A command is **1 to 9 bytes**; the first byte (opcode) tells the FDC how many additional bytes follow.
- The FDC routes each byte to the correct internal register automatically — no index register is needed.
- Result bytes must all be read before the FDC will accept a new command.

---

### 5.4 Status Register ST0

Returned in byte 0 of the result phase of most commands. Also returned by Sense Interrupt Status.

```
  Bit  7    6    5    4    3    2    1    0
      IC1  IC0   SE   EC   NR   HD  US1  US0
```

| Bit(s) | Name | Description |
|--------|------|-------------|
| 7–6 | IC1:IC0 | Interrupt Code (see table below) |
| 5 | SE | Seek End: FDC completed seek, recalibrate, or implicit-seek read/write |
| 4 | EC | Equipment Check: drive fault or track 0 not found after 79 step pulses |
| 3 | NR | Not Ready: drive not ready during command |
| 2 | HD | Head Address: 0 = head 0, 1 = head 1 |
| 1–0 | US1:US0 | Unit Select: currently addressed drive (00–11 = drives A–D) |

**Interrupt Code (IC) values:**

| IC | Meaning |
|----|---------|
| 00 | Normal termination — command completed without error |
| 01 | Abnormal termination — command started but could not complete correctly |
| 10 | Invalid command — FDC could not begin execution |
| 11 | Abnormal termination due to polling — drive became not ready |

---

### 5.5 Status Register ST1

Returned in byte 1 of the result phase after data transfer commands.

```
  Bit  7    6    5    4    3    2    1    0
       EN   --   DE   TO  NDAT  NW  NID  --
       (always 0 at bit 6 and bit 0)
```

| Bit | Name | Description |
|-----|------|-------------|
| 7 | EN | End of Cylinder: sector count exceeded sectors-per-track |
| 6 | — | Unused, always 0 |
| 5 | DE | Data Error: CRC error detected in ID address field or data field |
| 4 | TO | Time-Out / Overrun: DMA or CPU did not service data within required time |
| 3 | NDAT | No Data: addressed sector not found, or ID address mark not readable |
| 2 | NW | Not Writable: write-protect active during a write command |
| 1 | NID | No ID Address Mark: ID AM not found within one disk revolution; or no DAM found |
| 0 | — | Unused, always 0 |

> ST1 bit 0 and ST2 bit 4 (NDAM) are related and generally mirror each other.

---

### 5.6 Status Register ST2

Returned in byte 2 of the result phase after data transfer commands.

```
  Bit  7    6    5    4    3    2    1    0
       --  DADM CRCE WCYL  SEQ SERR BCYL NDAM
```

| Bit | Name | Description |
|-----|------|-------------|
| 7 | — | Unused, always 0 |
| 6 | DADM | Deleted Address Mark: deleted DAM found during Read Data, or valid DAM found during Read Deleted Data |
| 5 | CRCE | CRC Error in Data Field |
| 4 | WCYL | Wrong Cylinder: track address in ID mark differs from controller's expected cylinder |
| 3 | SEQ | Seek Equal (µPD765 only): seek-equal condition satisfied in a Scan command; 0 on 8272A |
| 2 | SERR | Seek Error (µPD765 only): corresponding sector not found when seeking; 0 on 8272A |
| 1 | BCYL | Bad Cylinder: track address in ID mark differs and equals FFh (IBM soft-sector bad-track marker) |
| 0 | NDAM | No Data Address Mark: valid or deleted DAM could not be found |

---

### 5.7 Status Register ST3

Returned as the sole result byte of the Sense Drive Status command.

```
  Bit  7    6    5    4    3    2    1    0
      ESIG WPDR  RDY TRK0 DSDR HDDR  DS1  DS0
```

| Bit | Name | Description |
|-----|------|-------------|
| 7 | ESIG | Error Signal (µPD765 only): drive /FAULT signal active |
| 6 | WPDR | Write Protect: disk is write-protected |
| 5 | RDY | Ready: drive ready signal active (µPD765 only; always 1 on 8272A) |
| 4 | TRK0 | Track 0: head is positioned over track 0 |
| 3 | DSDR | Double Sided: drive supports two heads |
| 2 | HDDR | Head: 0 = head 0 active, 1 = head 1 active |
| 1–0 | DS1:DS0 | Drive Select: mirrors the US1:US0 sent in the command |

---

### 5.8 Digital Input Register (DIR) — 3F7h, Read Only (AT/PS2)

Detects disk change and (on PS/2) reports the current data transfer rate.

```
  Bit  7    6–1    0
      CHAN  (var)  HiDe / RAT
```

| Bit | Name | Description |
|-----|------|-------------|
| 7 | CHAN | Disk Change: 1 = disk changed since last command |
| 6–3 | — | Reserved / platform-specific |
| 2–1 | RAT1:RAT0 | Data Rate (PS/2 non-Model-30): 00=500k, 01=300k, 10=250k, 11=1M bps |
| 0 | HiDe | High-Density: 1 = 250/300 kbps mode, 0 = 500k/1M bps mode (PS/2) |

---

### 5.9 Configuration Control Register (CCR) — 3F7h, Write Only (AT/PS2)

Sets the data transfer rate to match the media type.

```
  Bit  7–2   1    0
       --   RAT1 RAT0
```

| RAT1 | RAT0 | Rate | Typical Use |
|------|------|------|-------------|
| 0 | 0 | 500 kbps | 1.2 MB 5.25" HD, 1.44 MB 3.5" |
| 0 | 1 | 300 kbps | 360 kB 5.25" DD in 1.2 MB drive |
| 1 | 0 | 250 kbps | 360 kB 5.25" DD, 720 kB 3.5" |
| 1 | 1 | 1 Mbps | High-speed (rare, PS/2 Model 30) |

**Data Rate vs. Disk Capacity reference:**

| Rate | Disk | Size | Drive |
|------|------|------|-------|
| 250 kbps | 360 kB | 5.25" | 360 kB |
| 250 kbps | 720 kB | 3.5" | 1.44 MB |
| 300 kbps | 360 kB | 5.25" | 1.2 MB (reading DD) |
| 500 kbps | 1.2 MB | 5.25" | 1.2 MB |
| 500 kbps | 1.44 MB | 3.5" | 1.44 MB |

---

### 5.10 Status Register A — PS/2 Only (3F0h, Read Only)

Reflects the state of physical drive control lines.

| Bit | Name | PS/2 (non-Model 30) | Model 30 |
|-----|------|---------------------|----------|
| 7 | INTP | Interrupt Pending (1=active) | Interrupt Pending |
| 6 | DRV2 | Second drive installed (0=yes) | DMA Request |
| 5 | STEP | Step pulse active (1=yes) | Step pulse (0=active) |
| 4 | TRK0 | Head at track 0 (1=yes) | Head at track 0 (0=yes) |
| 3 | HDSL | Head select (0=head 0, 1=head 1) | Head select |
| 2 | INDX | Index mark (0=detected, 1=not) | Index (0=not, 1=detected) |
| 1 | WP | Write protect (0=protected, 1=not) | Write protect (0=not, 1=protected) |
| 0 | DIR | Head direction (0=outward, 1=inward) | Head direction (opposite polarity) |

---

### 5.11 Status Register B — PS/2 Only (3F1h, Read Only)

| Bit | Name | PS/2 (non-Model 30) | Model 30 |
|-----|------|---------------------|----------|
| 7 | — | Reserved | DRV2 (second drive) |
| 6 | — | Reserved | DS3 |
| 5 | DS0 | Drive 0 select | DS2 |
| 4 | WE | Write Enabled | WE |
| 3 | RDAT | Read Data (toggles on +ve RD DATA) | RDAT |
| 2 | WDAT | Write Data (toggles on WR DATA) | WDAT |
| 1 | MOT1 | Motor 1 on | DS1 |
| 0 | MOT0 | Motor 0 on | DS0 |

---

## 6. Command Execution Model

Every command passes through exactly **three phases**:

```
┌───────────────┐    ┌────────────────┐    ┌───────────────┐
│  COMMAND      │───▶│  EXECUTION     │───▶│   RESULT      │
│  PHASE        │    │  PHASE         │    │   PHASE       │
│               │    │                │    │               │
│ CPU writes    │    │ FDC operates   │    │ CPU reads     │
│ opcode +      │    │ on disk,       │    │ ST0–ST3 +     │
│ parameters    │    │ transfers data │    │ sector ID     │
│ via 3F5h      │    │ via DMA/IRQ    │    │ via 3F5h      │
└───────────────┘    └────────────────┘    └───────────────┘
```

**Rules:**
1. During the **Command Phase**, check `(MSR & 0xC0) == 0x80` before each byte write.
2. During the **Execution Phase**, do **not** read the MSR; the FDC manages data flow autonomously via DRQ/DACK (DMA mode) or INT (non-DMA mode).
3. During the **Result Phase**, check `(MSR & 0xC0) == 0xC0` before each byte read.
4. **All result bytes must be consumed** — the FDC will not accept a new command until the result phase is fully drained.
5. Commands with **no result phase** (Recalibrate, Seek, Specify) still require a subsequent **Sense Interrupt Status** (08h) to reset the interrupt and confirm completion.

---

## 7. Command Set — Complete Reference

### Abbreviation Key

| Abbr | Meaning |
|------|---------|
| MT | Multi-Track: operate on both heads of the cylinder |
| MF | MFM Mode: 1=MFM (double density), 0=FM (single density) |
| SK | Skip Deleted Data Address Marks |
| HD | Head number (0 or 1) |
| US1:US0 | Unit (drive) Select |
| N | Sector size code: bytes = 128 × 2^N |
| EOT | End of Track: final sector number on the cylinder |
| GPL | Gap 3 Length |
| DTL | Data Length (only when N=0) |
| ND | Non-DMA mode flag (in Specify command) |

---

### 7.1 Read Data — `06h` (MF/MT/SK modifiers in bits 7–5)

Reads one or more sectors with a valid Data Address Mark from disk to memory.

**Command Phase (9 bytes):**

| Byte | Bits | Field |
|------|------|-------|
| 0 | `MT MF SK 0 0 1 1 0` | Opcode |
| 1 | `? ? ? ? ? HD US1 US0` | Head & drive |
| 2 | — | Cylinder number |
| 3 | — | Head number (must equal HD in byte 1) |
| 4 | — | Sector number (first sector) |
| 5 | — | Bytes per sector (N: 0=128, 1=256, 2=512, 3=1024…) |
| 6 | — | End of Track (last sector number on track) |
| 7 | — | Gap 3 length |
| 8 | — | Data Length (only if N=0; else set to FFh) |

**Result Phase (7 bytes):**

| Byte | Content |
|------|---------|
| 0 | ST0 |
| 1 | ST1 |
| 2 | ST2 |
| 3 | Cylinder |
| 4 | Head |
| 5 | Sector number |
| 6 | Sector size code (N) |

**Behaviour:** Reads from the specified sector to EOT. The MT bit allows the operation to continue on the opposite head after reaching EOT on the current head. Sectors with a Deleted DAM are skipped if SK=1; if SK=0 and a Deleted DAM is found, ST2.DADM is set and the command terminates.

---

### 7.2 Read Deleted Data — `0Ch`

Identical to Read Data but targets **sectors with a Deleted Data Address Mark** only. Sectors with a normal DAM are skipped (SK=1) or cause ST2.DADM to be set (SK=0).

**Command Phase (9 bytes):** Same structure as Read Data with opcode `MT MF SK 0 1 1 0 0`.

**Result Phase:** Same 7-byte format as Read Data.

---

### 7.3 Write Data — `05h`

Transfers one or more sectors from memory to disk, writing a valid Data Address Mark for each.

**Command Phase (9 bytes):**

| Byte | Bits |
|------|------|
| 0 | `MT MF 0 0 0 1 0 1` |
| 1–8 | Same fields as Read Data |

**Result Phase:** Same 7-byte format as Read Data.

**Note:** Write Protect status (ST1.NW) is set and the command aborted if the disk is write-protected.

---

### 7.4 Write Deleted Data — `09h`

Same as Write Data but writes a **Deleted Data Address Mark** for every sector. Opcode: `MT MF 0 0 1 0 0 1`.

---

### 7.5 Read a Track (Diagnostic) — `02h`

Reads an **entire track** as a contiguous block, beginning at the first sector after the Index Address Mark, ignoring logical sector numbers in the ID fields.

**Command Phase (9 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 MF SK 0 0 0 1 0` |
| 1–8 | Same as Read Data |

**Constraints:**
- Multi-track (MT) operations are **not permitted** with this command.
- The read buffer must be large enough for an entire track.
- To read both heads, issue the command twice.

**Result Phase:** Same 7-byte format as Read Data.

**Sector ID table in result phase:**

| M | HD_prog | Last sector | Cylinder result | Head result | Sector result |
|---|---------|------------|----------------|------------|--------------|
| 0 | 0 | before EOT | cyl_prog | HD_prog | sec_prog |
| 0 | 0 | at EOT | cyl_prog+1 | HD_prog | 1 |
| 1 | 0 | before EOT | cyl_prog | HD_prog | sec_prog |
| 1 | 0 | at EOT | cyl_prog | HD_prog | 1 |
| 1 | 1 | at EOT | cyl_prog+1 | ~HD_prog | 1 |

---

### 7.6 Read ID — `0Ah`

Reads the **ID Address Mark of the first sector** the head encounters. Used to determine the current head position.

**Command Phase (2 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 MF 0 0 1 0 1 0` |
| 1 | `? ? ? ? ? HD US1 US0` |

**Result Phase:** Same 7-byte format as Read Data (reports the found sector's CHS and size).

**Error:** If no ID AM is found within one full disk revolution, ST0.IC=01, ST1.NID is set.

---

### 7.7 Format a Track — `0Dh`

Formats a complete track by writing sector headers and fill data for each sector.

**Command Phase (6 bytes):**

| Byte | Bits/Content |
|------|-------------|
| 0 | `0 MF 0 0 1 1 0 1` |
| 1 | `? ? ? ? ? HD US1 US0` |
| 2 | Bytes per sector (N) |
| 3 | Sectors per track |
| 4 | Gap 3 length |
| 5 | Fill byte pattern (written into data fields) |

**Format Buffer:** The FDC reads a 4-byte descriptor for each sector from memory (via DMA or interrupt):

| Offset | Field |
|--------|-------|
| +0 | Cylinder |
| +1 | Head |
| +2 | Sector number |
| +3 | Sector size code (N) |

Formatting begins at the Index pulse and runs for one full revolution. The controller issues an interrupt before writing each sector so the CPU/DMA can supply the 4-byte descriptor.

**Result Phase:** Same 7-byte format as Read Data.

---

### 7.8 Scan Equal — `11h`

Compares data from disk with data provided by the host byte-by-byte. Sets ST2.SEQ when an equal sector is found.

**Command Phase (9 bytes):**

| Byte | Bits |
|------|------|
| 0 | `MT MF SK 1 0 0 0 1` |
| 1–7 | Same as Read Data bytes 1–7 |
| 8 | Scan Test: 1 = contiguous sectors, 2 = alternate sectors |

**Result Phase:** Same 7-byte format as Read Data.

---

### 7.9 Scan Low or Equal — `19h`

Like Scan Equal, but succeeds when disk data ≤ host data. Opcode: `MT MF SK 1 1 0 0 1`.

---

### 7.10 Scan High or Equal — `1Dh`

Like Scan Equal, but succeeds when disk data ≥ host data. Opcode: `MT MF SK 1 1 1 0 1`.

---

### 7.11 Recalibrate — `07h`

Moves the read/write head to **track 0**.

**Command Phase (2 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 0 0 0 0 1 1 1` |
| 1 | `? ? ? ? ? 0 US1 US0` |

**Result Phase:** None. An interrupt is raised on completion. Issue **Sense Interrupt Status** to read ST0 and verify success.

**Mechanism:** DIR is set to 0 (outward); up to **79 step pulses** are issued. After each pulse, /TRK0 is checked. If /TRK0 goes active, SE is set in ST0 and the command ends. If /TRK0 is not found after 79 pulses, SE and EC are both set.

**Important:** A calibration is mandatory after power-up. Drives with more than 80 tracks may require **multiple Recalibrate commands**.

---

### 7.12 Sense Interrupt Status — `08h`

Reads the interrupt status and **resets the interrupt signal**. Must be issued after Recalibrate, Seek, and Seek Relative to acknowledge the interrupt.

**Command Phase (1 byte):**

| Byte | Bits |
|------|------|
| 0 | `0 0 0 0 1 0 0 0` |

**Result Phase (2 bytes):**

| Byte | Content |
|------|---------|
| 0 | ST0 |
| 1 | Present cylinder number |

**Special case:** If issued with **no interrupt pending**, ST0 is returned as `80h` (Invalid Command code).

**Interrupts that require a Sense Interrupt Status:**
- Beginning of result phase: Read Data, Write Data, Read Deleted Data, Write Deleted Data, Read Track, Format Track, Read ID, Verify
- After completion (no result phase): Recalibrate, Seek, Seek Relative
- Every data byte exchange in non-DMA mode

---

### 7.13 Specify / Fix Drive Data — `03h`

Programs the mechanical timing constants for head movements.

**Command Phase (3 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 0 0 0 0 0 1 1` |
| 1 | `SRT[3:0] HUT[3:0]` (Step Rate / Head Unload Time) |
| 2 | `HLT[6:0] ND` (Head Load Time / Non-DMA mode) |

**Timing fields:**

| Field | Range | Increment | Notes |
|-------|-------|-----------|-------|
| SRT (Step Rate Time) | 1–16 ms | 1 ms steps | Encoded as 16 − SRT in the nibble; rate-dependent |
| HUT (Head Unload Time) | 16–240 ms | 16 ms steps | |
| HLT (Head Load Time) | 2–254 ms | 2 ms steps | |
| ND | 0 or 1 | — | 0=DMA mode, 1=Non-DMA mode |

**Result Phase:** None.

> All timing values are **data-rate dependent**. Recalculate when the data rate is changed via the CCR.

---

### 7.14 Sense Drive Status — `04h`

Returns the physical status of a drive via ST3.

**Command Phase (2 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 0 0 0 0 1 0 0` |
| 1 | `? ? ? ? ? HD US1 US0` |

**Result Phase (1 byte):**

| Byte | Content |
|------|---------|
| 0 | ST3 |

---

### 7.15 Seek — `0Fh`

Moves the read/write head to a specified cylinder.

**Command Phase (3 bytes):**

| Byte | Bits |
|------|------|
| 0 | `0 0 0 0 1 1 1 1` |
| 1 | `? ? ? ? ? HD US1 US0` |
| 2 | New cylinder number |

**Result Phase:** None. An interrupt is raised on completion. Issue **Sense Interrupt Status** to verify.

**Mechanism:** DIR is set based on whether the target cylinder is greater or less than the current cylinder; step pulses are generated until the cylinder numbers match.

---

### 7.16 Version — `10h`

Identifies the FDC variant. Supported only on the µPD765B and later compatibles.

**Command Phase (1 byte):**

| Byte | Bits |
|------|------|
| 0 | `? ? ? 1 0 0 0 0` |

**Result Phase (1 byte):**

| Value | Controller |
|-------|-----------|
| `90h` | µPD765B |
| `80h` | µPD765A or µPD765A-2 |
| `80h` (as Invalid) | Controller does not support extended commands |

If the FDC does not support this command, it is treated as an Invalid Command and returns `80h` in ST0 via the normal invalid-command result path.

---

### 7.17 Invalid Command

Any opcode not matching a valid command causes the FDC to enter a standby state and return:

**Result Phase (1 byte):**

| Byte | Content |
|------|---------|
| 0 | ST0 = `80h` (IC=10, all other bits 0) |

---

## 8. Timing Parameters

### Absolute Maximum Ratings

| Parameter | Value |
|-----------|-------|
| Supply Voltage (VCC) | −0.5 V to +7 V |
| Input Voltage | −0.5 V to VCC + 0.5 V |
| Output Voltage | −0.5 V to VCC + 0.5 V |
| Storage Temperature | −65 °C to +150 °C |
| Operating Temperature | −10 °C to +70 °C |

### DC Characteristics (VCC = 5 V ±5%, TA = 25°C typical)

| Parameter | Symbol | Min | Typ | Max | Unit |
|-----------|--------|-----|-----|-----|------|
| Output Low Voltage | VOL | — | — | 0.45 V | V |
| Input High Voltage | VIH | 2.0 | — | — | V |
| Input Low Voltage | VIL | — | — | 0.8 V | V |

### Key Data Transfer Timing

| Mode | Bit Rate | Byte Rate | IRQ Interval (non-DMA) |
|------|----------|-----------|----------------------|
| MFM | 500 kbps | ~62.5 kB/s | every ~13 µs |
| FM | 250 kbps | ~31.25 kB/s | every ~27 µs |

> In **non-DMA mode**, the processor must respond to each interrupt within ~13 µs (MFM) or ~27 µs (FM). If it cannot, the TO bit (ST1.4) is set.

---

## 9. DMA Interface

The µPD765 uses **DMA Channel 2** exclusively on PC-compatible systems.

### DMA Transfer Sequence

1. FDC asserts **DRQ** when a byte is ready (read) or needed (write)
2. DMA Controller asserts **DACK** + **RD** (read) or **WR** (write)
3. DRQ is de-asserted when DACK goes low
4. After the last byte, DMA Controller asserts **TC** (Terminal Count)
5. TC triggers the FDC's Result Phase and generates **INT**

### Setting Up DMA for a Single-Sector Read (example, x86 assembly)

```asm
; Assumes ES:BX = target buffer address (20-bit segmented)
; Compute 20-bit physical address from ES:BX

disable_dma1:
    mov  al, 14h         ; disable & init DMA1
    out  08h, al

mode:
    mov  al, 56h         ; single transfer, write to memory, channel 2
    out  0Bh, al         ; for write to disk use 5Ah

get_address:
    mov  ax, es
    mov  cl, 04h
    shl  ax, cl
    add  ax, bx          ; AX = low 16 bits of physical address
    jc   carry

no_carry:
    mov  bx, es
    shr  bh, cl          ; BH = bits [19:16] of physical address (page)
    jmp  buffer_address

carry:
    mov  bx, es
    shr  bh, cl
    adc  bh, 00h

buffer_address:
    out  0Ch, al         ; reset DMA flip-flop
    out  04h, al         ; low-order address byte
    mov  al, ah
    out  04h, al         ; high-order address byte
    mov  al, bh
    out  81h, al         ; page register

count:
    out  0Ch, al         ; reset flip-flop
    mov  al, 0FFh
    out  05h, al
    mov  al, 01h
    out  05h, al         ; count = 511 (one 512-byte sector)

release_channel:
    mov  al, 02h
    out  0Ah, al         ; release DMA channel 2

enable_dma1:
    mov  al, 10h
    out  08h, al         ; enable DMA1
```

> For multiple sectors, the second byte written to port 05h should be `(2 × number_of_sectors) − 1`.

---

## 10. Interrupt Behaviour

### When INT is Asserted

The FDC raises INT in the following situations:

| Situation | Response Required |
|-----------|------------------|
| Beginning of Result Phase (data commands) | Read all result bytes from 3F5h |
| Completion of Recalibrate | Issue Sense Interrupt Status |
| Completion of Seek | Issue Sense Interrupt Status |
| Completion of Seek Relative | Issue Sense Interrupt Status |
| Non-DMA mode: each data byte ready/needed | Read or write one byte at 3F5h |

### Polling Mode (Non-DMA)

When NDMA=1 in MSR:
- For **reads** from disk: INT goes high when each byte is available; cleared by reading 3F5h.
- For **writes** to disk: INT goes high when the FDC needs a byte; cleared by writing 3F5h.
- If interrupts cannot be serviced fast enough, poll **MSR bit 7 (MRQ)** — it behaves identically to INT in non-DMA mode.

### Automatic Polling Between Commands

Between commands (and between step pulses during Seek), the FDC automatically polls the **Ready line** of all four drives. If Ready changes state (e.g. due to a disk door opening or closing), the FDC asserts INT. A Sense Interrupt Status command is required to acknowledge and identify the source.

---

## 11. Programming Guide

### Typical Read Operation Sequence

```
1.  Write DOR: select drive, start motor, enable DMA+REST
2.  Wait for motor spin-up (~200 ms on a cold start)
3.  Issue Recalibrate (07h) → wait for INT → issue Sense Interrupt Status (08h)
4.  Confirm ST0.SE=1 and present cylinder = 0
5.  Programme DMA for the transfer (destination buffer, byte count, channel 2)
6.  Issue Read Data (06h) with cylinder/head/sector/N/EOT/GPL/DTL
7.  Wait for INT (end of execution phase)
8.  Read 7 result bytes from 3F5h (ST0, ST1, ST2, C, H, R, N)
9.  Check ST0.IC == 00 for success; inspect ST1/ST2 for errors
10. Write DOR: turn motor off if done
```

### Controller Reset Sequence

```
1.  Write 00h to DOR (3F2h) → asserts reset
2.  Wait ≥ 4 µs
3.  Write 0Ch to DOR (REST=1, DMA=1, drive select=0) → releases reset
4.  Issue four Sense Interrupt Status commands (one per possible drive)
    to clear the reset interrupts
5.  Issue Specify (03h) to programme step rate / head load/unload times
```

### Checking MSR Before Each Data Register Access (C pseudocode)

```c
#define MSR  0x3F4
#define DATA 0x3F5

void fdc_write_byte(uint8_t b) {
    while ((inb(MSR) & 0xC0) != 0x80)
        ;   /* wait: MRQ=1, DIO=0 (CPU→FDC) */
    outb(DATA, b);
}

uint8_t fdc_read_byte(void) {
    while ((inb(MSR) & 0xC0) != 0xC0)
        ;   /* wait: MRQ=1, DIO=1 (FDC→CPU) */
    return inb(DATA);
}
```

---

## 12. µPD765A vs µPD765B Differences

| Feature | µPD765A | µPD765B |
|---------|---------|---------|
| Version command result | `80h` | `90h` |
| ST2.SEQ (Seek Equal) | Used in Scan commands | Not used (always 0) |
| ST2.SERR (Seek Error) | Used in Scan commands | Not used (always 0) |
| ST3.ESIG (Fault) | Reflects /FAULT pin | Not available |
| ST3.RDY (Ready) | Reflects /RDY pin | Always 1 |
| CMOS process | No | Yes (lower power) |
| Maximum clock | 8 MHz | 8 MHz |

The µPD765B is a CMOS version with lower power consumption and slightly different ST2/ST3 behaviour. Both are pin- and software-compatible for standard operations.

---

## 13. Compatible Devices

| Manufacturer | Part Number | Notes |
|-------------|-------------|-------|
| NEC | µPD765A | Original NMOS; 40-pin DIP |
| NEC | µPD765B | CMOS version; lower power |
| Intel | 8272A | IBM PC/XT choice; software compatible |
| Zilog | Z0765A / Z765A | Pin- and software-compatible |
| Western Digital | WD37C65 | Extended feature set |
| UMC | UM8272A | Clone |
| LGS/Goldstar/Semicon | GM82C765B | CMOS clone |
| SMSC/SMC | FDC37C65C+ | Super I/O integration |

All of the above implement the same 15-command base instruction set and the same register map at 3F5h. Differences typically appear in:
- Extended commands (Version, Verify, Seek Relative, Register Summary)
- FIFO depth and programmable threshold (82077A and later)
- Perpendicular recording support (82077AA)
- Integration with parallel port, serial port, and other Super I/O functions (FDC37C65C+, WD37C65)

---

*Document compiled from NEC µPD765A/B data sheets, NEC Application Note 8 (March 1979), Intel 8272A data sheet (November 1986), and PC-compatible FDC programming references.*
