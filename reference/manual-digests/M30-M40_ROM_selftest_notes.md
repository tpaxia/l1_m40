# M30 / M40 — ROM Self-Test & Diagnostics Notes (RE reference)

Source: **"M30 – M40 Manuale dei Collaudi"** (Test Manual), Olivetti L1 line,
base code `3963350 Z`, newsletter `3963353 A` (30‑03‑83), © 1983 Olivetti Ivrea.
File: `reference/Manuals (Stefano Marinelli + Olivrea)/M30 M40 Manuale dei collaudi.pdf`
(182 pp). This note covers **Chapter 1 "Autodiagnostica"** (the ROM self-test,
pp. 1‑1…1‑11) plus the start of **Chapter 2 "Diagnostica"** (disk-loaded tests).
These directly guide disassembly of the ROMs in `reference/roms`.

> **Companion doc:** `reference/manual-digests/M34-M44_hardware_notes.md` (the `Nome Logico` / I/O
> port map). The *governo type codes* here (§7) are the same value space.

---

## 0. Why this manual matters for our ROMs  ⭐

The manual splits the resident firmware into **two hardware generations**:

| ROM generation | Fitted on UC boards | Plausibly matching file(s) *(by date only)* |
|---|---|---|
| **ROM 151** | produced **up to Nov 1982** | `reference/roms/m40rom-15-dec-81` (Dec 1981) |
| **ROM 152** | produced **from Nov 1982** | `reference/roms/m40rom-4.1`, `m40rom-6.0` (banner *17 DEC 82*) |

⚠️ **This mapping is inferred, not documented.** The manual keys 151/152 to the
**UC board production date** and **never mentions REL 4.1 or 6.0**. Separately it
calls "REL x.x" the **"Release delle ROM LOADER"** (a loader-software version,
embedded at ROM offset `0x12`) — a *different* numbering scheme from the ROM-part
151/152. So placing 4.1/6.0 in the "152" era rests only on their *17 DEC 82* date
being after Nov 1982; it has not been confirmed (e.g. against the 151→152
behavioural differences). Where "ROM 152" is used below, read it as "this manual
chapter" — the resident tests it describes match what the disassembly shows.

**Direct RE payoffs from this chapter:**
- The reset path runs a fixed **sequence of steps** (below) — a roadmap for the
  disassembly's entry point.
- There is a **stored ROM CRC** that the "Test ROM" step recomputes. Recall the
  dumps end with a live word *after* the `0xFF` fill (`…FFFF 0277 e8d9` in 4.1,
  `…FFFF 87fe d7c0` in 6.0). **Hypothesis: that trailing word is the stored CRC**
  the self-test checks. Confirm by locating the CRC routine.
- Concrete **MMU segment assignments**, **I/O device-select codes**, **IPL
  channel priority**, and **error codes** — all things the ROM writes/branches on.

---

## 1. Two-part autodiagnostica (p. 1‑1)

- **Resident** (in the UC ROM) — the only part implemented; analyses **only what
  is needed to load programs**, then hands completion to the non-resident part.
- **Non-resident** — loaded from magnetic media; *"not yet implemented"* at the
  time of writing (this is what Chapter 2's disk Monitor later becomes).

The self-test **starts automatically at power-on** and runs **in steps**. Errors
are shown as a **code** on the *diagnostic console*, on *video*, or both.

### Resident self-test organisation (the step list)

1. **test piastra unità centrale** (CPU board)
2. **test piastra di memoria** (memory board)
3. **ricerca governo di caricamento** (find the IPL / load controller)
4. **test governo di caricamento** (test that controller)
5. **caricamento programmi** (load programs / IPL)

---

## 2. ROM 151 — CPU-board test breakdown (p. 1‑2)

`ROM 151 test piastra di Unità Centrale` = these sub-tests, in order:

| Step | What it does | Failure |
|---|---|---|
| **Test Z8001 (CPU)** | Runs an instruction sequence with an *a-priori known* result. | *(not implemented in this release)* |
| **Test ROM** | Recomputes the **"CRC" stored in the ROM** and compares. | suspend, console code **`2`** |
| **Test Z8010 (MMU)** | Write/read **all segment-descriptor registers**. On success → programs **segment `0` = ROM** and **segment `61` = video-controller RAM** (so errors can be shown on video). | suspend, console code **`3`** |
| **Ricerca allocazione fisica RAM** | Uses the **`READY`** signal (its absence raises an **NMI**) to find where RAM lives. RAM must be **contiguous** (no addressing gaps across multiple RAM boards). | RAM absent → code **`4`** (console+video); RAM span **< 16 KB** → code **`5`** (console+video) |
| **Test 8253 (timer) + timer-interrupt logic** | timer counter + interrupt path check | *(see Ch.1 error codes)* |

**RE notes:**
- The **MMU is a Z8010** paging unit driven by the Z8001. Expect early ROM code
  to write a table of **segment descriptor registers** via special I/O.
- `segment 0 → ROM`, `segment 61 → video RAM` are hard bindings to look for.
- The RAM sizing loop is driven by **`READY`/NMI** — watch for an **NMI handler**
  probing ascending addresses and catching the fault to compute RAM extent.
- **≥ 16 KB RAM** is the minimum to proceed.

---

## 3. ROM 152 — how it differs from ROM 151 (p. 1‑9/1)

Self-tests are *similar*, but ROM 152 differs in two fundamental ways:

1. **IPL can load from more media**: not only floppy/minifloppy but also **hard
   disk** and **streaming tape**.
2. **Different error-response structure** (the blinking/non-blinking scheme, §5).

Because our `REL 4.1` / `REL 6.0` dumps are ROM 152, **§3–§7 are the ones to
match against the disassembly.**

---

## 4. IPL channel priority (p. 1‑9/1)

The boot channel (IPL) for the OS or diagnostic monitor is chosen by the **`ISL`
switch on the UC board**. **If that switch is absent**, the fixed priority is:

1. HDU 5010
2. HDU 6813
3. DCU 9448 (fixed part)
4. FDU
5. MFDU
6. STC
7. DCU 9448 (removable part)

**RE:** look for a table/loop iterating candidate controllers in this order,
gated by reading the ISL switch input.

---

## 5. Error codes

### 5a. Non-blinking console codes — ROM 152 (p. 1‑9/1)

| Code | Meaning |
|---|---|
| `1` | Fault in **UC** (CPU board) |
| `2` | Fault in **system RAM** |
| `3` | **Unexpected interrupt-time vector** |
| `4` | **No IPL controller** present |
| `5` | **Waiting** for outcome of first IPL attempt |

> Note the ROM 151 codes differ (from §2): `2`=ROM CRC, `3`=MMU, `4`=RAM absent,
> `5`=RAM<16 KB. Keep the two code sets separate when interpreting a disassembly.

### 5b. Blinking console codes — ROM 152 (p. 1‑9/2)

Errors from the **UC ↔ IPL-controller dialogue**. Four symbols emitted ~1 s apart:

- `.` — **synchronisation** character (frame marker)
- `X` — fault type (**bit-coded**):
  - `1` = controller fault
  - `2` = peripheral fault
  - `4` = read error on the magnetic media
  - `8` = media not inserted, or media without an operating system
- `Y` — **cassettiera slot position** of the controller the code refers to
- `Z` — **unit** on which the fault occurred

### 5c. Video message (p. 1‑9/2)

Alongside the blinking console code, the video shows:

```
X  Y  Z        REL. 4.0
│  │  │           └── Release of the ROM LOADER   (= our "REL 4.1" / "REL 6.0")
└──┴──┴── error code (same meaning as console)
```

---

## 6. System-configuration screen (pp. 1‑10 … 1‑11)

If the self-test passes and IPL loads the diagnostic program, this table is shown:

```
                 NLS 30000  SYSTEM ENVIRONMENT
      RAM    SIZE   wwww   KB
  ******* 00   XX-YYYY 01   XX-YYYY 02   XX-YYYY 03
  ******* 04   XX-YYYY 05   ******* 06   ******* 07
  ******* 08   ******* 09   ******* 0A   ******* 0B
  ******* 0C   ******* 0D   ******* 0E   XX-YYYY 0F
  REFRESH Z

  Hit "ENTER" for Diagnostic Monitor:
```

- **Row 2**: total memory `wwww` KB.
- **Rows 3–6**: one cell per slot `00`…`0F`:
  - `XX` = **governo type code** in that slot (§7),
  - `YYYY` = **response to autodiagnostica** (`%0000` = OK, `%FFFF` = fail),
  - trailing `00`…`0F` = **slot number** (progressive).
- **Row 7 `REFRESH Z`**: does system memory need CPU refresh? `Z = Y|N`.
- The table is built during the **load-controller-search** slot scan.
- During that scan the **video controllers are programmed as diagnostic output**;
  their response word = `%0000` if the video-control-logic test passes, else `%FFFF`.
- **Video RAM mapping**: first controller (lowest slot / closest to UC) at offset
  `%0000`, each further controller **+`%2000` bytes**.
- The **UC board is always reported in the 16th position** (`0F`).

---

## 7. Governo type codes `XX` (p. 1‑11)  ⭐

The slot-scan tags each board with a device-select code (same value space as the
`Nome Logico` in the M34/M44 manual):

| Code | Governo |
|---|---|
| `FF` | Unità centrale (CPU) |
| `FE` | Video-tastiera (video/keyboard) |
| `E1` | FDU (floppy) |
| `E0` | MFDU (minifloppy) |
| `D1` | Linea "TTL" |
| `D2` | Linea "V24" (unattended version) |
| `D3` | Linea "V24" |
| `D4` | Linea "X24" (unattended version) |
| `D5` | Linea "X24" |
| `D7` | Linea "LION 9.6" |
| `CF` | Twin RS232 / Current Loop |
| `B0` | Pin-Pad / Badge Reader |
| `EF` | GIPO IEEE-488 |
| `E4` | HDU (hard disk) |
| `E6` | Streaming tape cartridge |

These are the **high-byte I/O device selects** the ROM writes to when it probes
each slot. Cross-checks with `M34-M44_hardware_notes.md` §3/§4.

---

## 8. Chapter 2 — disk-loaded diagnostics (context, pp. 2‑1 …)

Not the ROM, but describes what the ROM's IPL step hands off to:

- All diagnostic programs can live on any of **4 media**: mini-floppy, floppy,
  hard disk, streaming cartridge.
- A **Diagnostic Monitor** (written in **PLZ/ASN**) loads/catalogs the individual
  test programs; it is loaded and activated **right after** the init + resident-
  diagnostic phases. Programs documented are **Release 5.0 DCOS**.
- Minimum hardware to run them: video/keyboard governo, video, keyboard, IPL governo.
- Loader utilities named in the TOC, useful when analysing IPL/boot images:
  - `LDHSEL` — load diagnostic environment FDU → XU5010/XU6813 (hard disk).
  - `SELECTOR` / `FDU-HDU LOADER` — transfer diagnostic programs between media.
  - IPL-via-HDU sequence: set **ISL switch to HDU**, power on → `SELECTOR RUNNING`
    / `*** KEYBOARD ENABLE ***`, then type `5 0` within 10 s (else time-out).

---

## 9. RE action list (derived)

- [ ] **Find the CRC routine** ("Test ROM"): confirm whether the trailing word
      after the `0xFF` fill (`0277 e8d9` / `87fe d7c0`) is the stored checksum,
      and recover the CRC algorithm/polynomial.
- [ ] Map the **reset entry** to the §1 step list; label CPU/ROM/MMU/RAM/timer tests.
- [ ] Locate the **MMU (Z8010) descriptor setup** — segment `0`=ROM, `61`=video RAM.
- [ ] Find the **NMI handler** used for READY-based RAM sizing; verify the `16 KB`
      minimum and the "contiguous RAM" assumption.
- [ ] Locate the **8253 timer init** and the **timer-interrupt vector** (error `3`).
- [ ] Recover the **IPL controller-scan** loop and the ISL-switch read (order in §4).
- [ ] Map the **error-emit routines** (non-blinking vs blinking console; video line
      with `REL x.x` string at ROM `0x12`).
- [ ] Recover the **slot-scan** that builds the §6 config table and the §7 code map.
- [ ] Compare `REL 4.1` vs `REL 6.0` control flow to see which §3 features (HDU/STC
      IPL) each enumerates — explains the 8 KB → 16 KB size jump.
