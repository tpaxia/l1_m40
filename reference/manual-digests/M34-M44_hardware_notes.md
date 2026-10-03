# Olivetti M34 / M44 — Service Manual Notes (Ch. 1)

Source: **"Manuale per l'assistenza (M34 – M44)"**, Olivetti L1 line,
doc. `4105730 S (0)`, Prima Edizione Giugno 1985, © 1985 Olivetti Ivrea.
File: `reference/Manuals (Stefano Marinelli + Olivrea)/M34-M44.pdf`.

These notes cover the **first 14 pages** (front matter + Chapter 1 "Generalità"),
with emphasis on the **`Nome Logico`** column and how it gates the CPU I/O ports.

---

## 1. What the M34 / M44 are

- M34 and M44 are the two **new systems of the L1 line**. They are compatible —
  hardware *and* software — with the **M30** and **M40** respectively, both in
  the **emulated** environment and under **MOS**.
- Main innovations vs. M30/M40:
  - New **CPU running at 8 MHz** clock (the CPU is a **Z8001**).
  - New **RAM boards with 150 ns access time**.
  - Most pre‑existing *governi* (controller boards) were re‑qualified for the new
    clock frequency.
- Chassis ("carrozzerie") are unchanged from M30/M40. Like the M40, the M44 also
  uses **external cabinets** for magnetic peripherals in addition to the ones
  integrated in the base unit.

### Packaging

| System | Form factor | Cassettiera (card cage) | Magnetic peripherals |
|---|---|---|---|
| **M34** | "desk top" box | **max 9** board slots | internal shelf only — **no external peripherals** |
| **M44** | "desk size" cabinet | **max 14** board slots | internal bay **+** external cabinets **SB3** and **SB2** |

- **CAB 3558 / SB3** — external cabinet, holds any magnetic peripheral *except* the MTU.
- **SB2** — external cabinet specific to the **MTU**, but can also hold a 60/120 MB hard disk.

---

## 2. Board placement in the cassettiera (§1.2)

Slot numbering direction (viewed from the front):

- **M34**: bottom → top.
- **M44**: right → left.

### Fixed‑position rules

- **Central unit (CPU) board position is rigid:**
  - M34 CPU → **2nd** position.
  - M44 CPU → **1st** position.
- **RAM boards:**
  - M34 → the **first** memory module must go in **slot 1** (slot 1 is outside the
    priority chains and cannot host a *governo*).
  - M44 → the first memory module goes in **position 2**.
  - Memory **expansions** are best placed in the **last two** slots, to avoid
    signal‑propagation delays to the various governi.
- **No vacant slots** are allowed between boards.

### Priority — why slot order matters (§1.2 / Fig. 1‑4)

The exact insertion order is governed by a **daisy‑chained priority** propagated
down the backplane from the CPU board through each governo (Fig. 1‑4 shows the
`INTER.L1A / INTER.L1B / INTER.L2` acknowledge chain, with the "richiusura daisy
chain" loopback at the CPU).

- **DMA priority**: for governi that work in DMA, priority **decreases** with
  distance from the CPU board (closest = highest).
- **Interrupt priority**: three levels, in descending order:
  - **L1A** — highest level; a board's priority **increases** the closer it is to the CPU.
  - **L1B** — a board's priority **decreases** the closer it is to the CPU.
  - **L2** — lowest level; priority **increases** the closer the board is to the CPU.

---

## 3. `Nome Logico` — the I/O‑port device select  ⭐

**This is the key to I/O decoding.** The tables in §1.2.1 (pages 1‑5 / 1‑6) list,
for every hardware module:

| Column | Meaning |
|---|---|
| `MODULO HARDWARE` | Functional name of the board |
| `NOME PIASTRA` | Physical board part number (e.g. `UC048`, `GO278/B`, `GO257`) |
| `NOME LOGICO` | **Hex device‑select value** the board decodes on the I/O bus |
| `LIVELLO DI INTERRUZIONE` | Interrupt level the board asserts (`L1A` / `L1B` / `L2`) |

### How it gates the ports

The Z8001 has a **separate 16‑bit I/O address space**. A governo is *not* selected
by its physical slot — the slot only fixes its **priority** (§2). It is selected by
matching the **high byte of the I/O port address against its `Nome Logico`**:

```
   Z8001 I/O port address (16 bit)
   ┌───────────────────────┬───────────────────────┐
   │   high byte           │   low byte            │
   │   = NOME LOGICO       │   = register / port   │
   │   (which board answers)│   (which port on it) │
   └───────────────────────┴───────────────────────┘
```

So, e.g., the CPU board `UC048` = `FF` owns port block `FFxx`; the MTU governo
`GO278/B` = `62` owns `62xx`; the encryption/RTC board owns `21xx`/`20xx`, etc.
The low byte then addresses the individual registers inside that board.

> This matches the user's model — "the upper part of the port indicates the
> [board], then the nome logico, then the actual port" — with the refinement that
> the *slot* is physical/daisy‑chain (priority only) and the **`Nome Logico` is
> the high‑byte address decode** that actually routes the I/O cycle.

### Table A — §1.2.1 board sequence, part 1 (page 1‑5)

Valid for **both M34 and M44**.

| Modulo hardware | Nome piastra | **Nome logico** | Int. level | Notes |
|---|---|---|---|---|
| Unità Centrale (CPU) | `UC048` | **`FF`** | ACIA: L1A or L1B (SW‑selectable); TIMER: L2 | |
| Governo MTU | `GO278/B` | **`62`** | L2 | Highest priority within L2 |
| Governo encryption + RTC | `GO257` | **`21`** | L1B | |
| Modulo Real Time Clock | `GO257/A` | **`20`** | L1B | |
| Gov. encryption (pin check) | `GO257/B` | **`21`** | L1B | |
| Governo linea V24 + V24 | `GO236` | **`22/28`** | L1B | *Intelligent* line governi (with µP) |
| Governo linea V24 + LION200 | `GO256` | **`23/27`** | L1B | *Intelligent* |
| Governo linea V24 + LION9.6 | `GO340/A` | **`25/26`** | L1B | *Intelligent* |
| Governo linea ethernet | `GO212/A` | **`6F`** | L1B | |
| Governo multiplexer | `GO322` | **`30`** | L1B / L2 | |
| Governo KDC b/n alfanumerico | `GO252` | **`FE`** | L1B | Video governi **not** on ELB 1382 — lower priority than ELB‑connected ones |
| Governo KDC alfanum. colore | `GO224` | **`FE`** | L1B | (b/n or colour alphanumeric governi must never sit between two b/n graphic video governi) |
| Piastra grafico (con GO252) | `GO255/A` | **`FD`** | | |
| Governo KDC grafico colore | `GO261` | **`F7`** | L1B | |
| Interfaccia grafica | `GO260` | **`--`** | | (no logical name) |
| Governo video alfanumerico | `GO259` | **`FB`** | | |
| Governo rete locale omninet | `GO308` | **`68`** | L1B | |
| Governo KDC b/n alfanumerico | `GO252` | **`FE`** | | Video governi **connected to ELB 1382** — inserted *after* the non‑ELB video governi |
| Piastra grafico (con GO252) | `GO255/A` | **`FD`** | | |
| Governo KDC alfanum. colore | `GO224` | **`FE`** | L1B | |
| Governo KDC grafico colore | `GO261` | **`F7`** | L1B | |
| Interfaccia grafica | `GO260` | **`--`** | | |
| Governo video alfanumerico | `GO259` | **`FB`** | | |

### Table B — §1.2.1 board sequence, part 2 (page 1‑6)

| Modulo hardware | Nome piastra | **Nome logico** | Int. level | Notes |
|---|---|---|---|---|
| Governo linea esterna V24 | `GO300` | **`D3/D2`** | L1A | *Non‑intelligent* line governi (no µP) |
| Governo linea X24 | `GO303` | **`D5`** | L1A | |
| Governo linea LION 9.6 | `GO333` | **`D7`** | L1A | |
| Governo twin, current loop & RS 232 | `GO327` | **`CF`** | L1B | In emulated env., higher priority than non‑intelligent line governi → **program it at level L1A** |
| Governo HDU 18MB (XU 5010) + Controller/Formatter | `GO230` / `GO231` | **`E4`** / `--` | L2 | ↓ this whole group works in **DMA**; place it **after** the video/keyboard governi connected to ELB |
| Gov. interf. ST506 (XU1707/9) | `GO363` | **`65`** | L2 | |
| Governo HDU SMD (XU 1700/03) + Controller/Formatter | `GO302/A` / `GO301/A` | **`61`** / `--` | L2 | |
| Bus adapter + controller for HDU 14MB (XU5006) | `GO299` / `DTC510B0` | **`60`** | L2 | |
| Governo STC 20MB (XU 1120) + Controller/Formatter | `GO200/B` / `GO201/B` | **`E6`** / `--` | L2 | |
| Governo mFDU 320 KB | `GO280/C` | **`E0`** | L2 | |
| Governo FDU / mFDU 1 MB | `GO280/B` | **`E0`** | L2 | |
| Modem integrato MOIN 5.2 | `IF 192` | — | | Goes in the **last** slot; its governo takes whatever priority slot suits it |

### Notes attached to the table (important for emulation)

- **Dual logical names / memory segment:** logical names **`22`, `23`, `25`** refer
  to boards mapping a **full memory segment**; **`28`, `27`, `26`** refer to the same
  boards mapping a **half segment**. (This is why the intelligent line governi show
  two hex values — the device select changes with the segment mode.)
- **Mode‑dependent name:** logical name **`D3`** applies in **normal** mode; **`D2`**
  applies in **unattended** mode (for `GO300`, external V24 line).
- **`--`** in the column = the board has no independent logical name (it's a
  controller/formatter or interface slaved to the governo above it, e.g.
  `GO231`, `GO301/A`, `GO201/B`, `GO260`).

---

## 4. Quick reference — Nome Logico → board (sorted)

| Nome logico | Board(s) |
|---|---|
| `20` | RTC module `GO257/A` |
| `21` | encryption+RTC `GO257`, encryption pin‑check `GO257/B` |
| `22 / 28` | V24+V24 line `GO236` (full/half segment) |
| `23 / 27` | V24+LION200 line `GO256` (full/half segment) |
| `25 / 26` | V24+LION9.6 line `GO340/A` (full/half segment) |
| `30` | multiplexer `GO322` |
| `60` | HDU 14MB bus adapter `GO299` / `DTC510B0` |
| `61` | HDU SMD `GO302/A` |
| `62` | MTU `GO278/B` |
| `65` | ST506 interface `GO363` |
| `68` | omninet LAN `GO308` |
| `6F` | ethernet line `GO212/A` |
| `CF` | twin / current loop / RS232 `GO327` |
| `D3 / D2` | external V24 line `GO300` (normal / unattended) |
| `D5` | X24 line `GO303` |
| `D7` | LION 9.6 line `GO333` |
| `E0` | FDU/mFDU governi `GO280/C`, `GO280/B` |
| `E4` | HDU 18MB `GO230` |
| `E6` | STC 20MB `GO200/B` |
| `F7` | KDC graphic colour `GO261` |
| `FB` | alphanumeric video `GO259` |
| `FD` | graphic board `GO255/A` |
| `FE` | KDC b/n alphanumeric `GO252`, KDC alphanumeric colour `GO224` |
| `FF` | CPU board `UC048` |

> Note the two groups: **`0x60–0x6F` / `0xCF–0xE6`** for peripheral/line/mass‑storage
> governi, and **`0xF7–0xFF`** for video and the CPU itself. Handy as the top‑level
> `switch` on the high byte when building the emulator's I/O dispatch.

---

## 5. Emulator TODO / open questions

- Confirm whether the Z8001 **Special I/O** space (used for MMU/segment control)
  is distinct from the Standard I/O space these `Nome Logico` values live in.
- Determine the **low‑byte register map** per board (not in Chapter 1 — likely in
  Chapter 4 "Hardware di sistema" and the schematics under `reference/Manuals/PARTE 1`).
- Verify the CPU board's **ACIA (L1A/L1B) + TIMER (L2)** interrupt wiring vs. the
  daisy chain in Fig. 1‑4.
- Cross‑check the ROM banners (`REL 4.1` 8 KB, `REL 6.0` 16 KB in `reference/roms`)
  against which board set each release enumerates.
