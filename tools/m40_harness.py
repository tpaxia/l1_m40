#!/usr/bin/env python3
"""Python harness for M40 diagnostic-disk MAME runs.

This is the outer orchestration layer.  MAME/Lua still owns in-emulator timing,
input posting and I/O taps; Python owns run directories, command construction,
trace parsing and compact summaries.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import time
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAME_ROOT = Path("/Users/paxia/Projects/mame_latest/mame")
DEFAULT_MAME_BIN = DEFAULT_MAME_ROOT / "mame"
DEFAULT_TRACE_SCRIPT = REPO_ROOT / "scripts" / "lua" / "mame_m40_diag_trace.lua"
DEFAULT_DUMP_SCRIPT = REPO_ROOT / "scripts" / "lua" / "mame_m40_dump_segments.lua"
DEFAULT_OUT_ROOT = REPO_ROOT / "runs"
DIAG_DIR = (
    REPO_ROOT
    / "reference"
    / "Disk Images (Stefano Marinelli + others)"
    / "diagnostici l1 dcos 8.4"
)
CATALOG_JSON = REPO_ROOT / "tools" / "diagnostic_tests" / "catalogs.json"

IO_RE = re.compile(
    r"^(?P<prefix>GO252|GO280|UC-KDC) (?P<rw>[RW]) "
    r"pc=(?P<pc>[0-9A-Fa-f]+) addr=(?P<addr>[0-9A-Fa-f]+) "
    r"reg=(?P<reg>[0-9A-Fa-f]+) data=(?P<data>[0-9A-Fa-f]+) "
    r"raw=(?P<raw>[0-9A-Fa-f]+) mask=(?P<mask>[0-9A-Fa-f]+)"
)
CONSOLE_RE = re.compile(
    r"^CONSOLE pc=(?P<pc>[0-9A-Fa-f]+) data=(?P<data>[0-9A-Fa-f]+)(?: ; (?P<label>.*))?$"
)
SCREEN_BEGIN_RE = re.compile(r"^SCREEN BEGIN pc=(?P<pc>[0-9A-Fa-f]+) seg=(?P<seg>[0-9A-Fa-f]+)")
VRAM_RE = re.compile(
    r"^VRAM pc=(?P<pc>[0-9A-Fa-f]+) off=(?P<off>[0-9A-Fa-f]+) "
    r"data=(?P<data>[0-9A-Fa-f]+) mask=(?P<mask>[0-9A-Fa-f]+)"
)
CRTC_RE = re.compile(r"^CRTC pc=(?P<pc>[0-9A-Fa-f]+) reg=(?P<reg>[0-9A-Fa-f]+) data=(?P<data>[0-9A-Fa-f]+)")
FDU_RE = re.compile(
    r"^FDU (?P<event>[A-Z]+) pc=(?P<pc>[0-9A-Fa-f]+) "
    r"reg=(?P<reg>[0-9A-Fa-f]+) data=(?P<data>[0-9A-Fa-f]+) "
    r"pending=(?P<pending>[01]) ien=(?P<ien>[01]) "
    r"intmo_lat=(?P<intmo_lat>[01]) timer=(?P<timer>[01]) "
    r"intoo_lat=(?P<intoo_lat>[01]) fdc=(?P<fdc>[01]) "
    r"vec=(?P<vec>[0-9A-Fa-f]+) dma_hi=(?P<dma_hi>[0-9A-Fa-f]+) "
    r"dma_ch1=(?P<dma_ch1>[0-9A-Fa-f]+) dma_byte=(?P<dma_byte>[0-9A-Fa-f]+)"
)

FDC_COMMANDS = {
    0x03: ("SPECIFY", 3, 0),
    0x04: ("SENSE DRIVE STATUS", 2, 1),
    0x05: ("WRITE DATA", 9, 7),
    0x06: ("READ DATA", 9, 7),
    0x07: ("RECALIBRATE", 2, 0),
    0x08: ("SENSE INTERRUPT STATUS", 1, 2),
    0x09: ("WRITE DELETED DATA", 9, 7),
    0x0A: ("READ ID", 2, 7),
    0x0C: ("READ DELETED DATA", 9, 7),
    0x0D: ("FORMAT TRACK", 6, 7),
    0x0F: ("SEEK", 3, 0),
}


@dataclass
class ConsoleEvent:
    line: int
    pc: int
    data: int
    label: str = ""


@dataclass
class IoEvent:
    line: int
    prefix: str
    rw: str
    pc: int
    addr: int
    reg: int
    data: int
    raw: int
    mask: int


@dataclass
class TraceSummary:
    path: str
    lines: int = 0
    console: list[ConsoleEvent] = field(default_factory=list)
    io_counts: dict[str, int] = field(default_factory=dict)
    reg_counts: dict[str, int] = field(default_factory=dict)
    kdc_bytes: list[int] = field(default_factory=list)
    screen_snapshots: int = 0
    last_events: list[str] = field(default_factory=list)

    @property
    def console_hex(self) -> list[str]:
        return [f"{event.data:02X}" for event in self.console]

    @property
    def reached_monitor_prompt(self) -> bool:
        return any(event.data == 0xFF for event in self.console)


@dataclass
class ScreenState:
    source: str
    vram_writes: int
    crtc_writes: int
    cols: int
    rows: int
    start: int
    text: str


@dataclass
class FduDecode:
    source: str
    lines: int
    commands: dict[str, int]
    timer_edges: int
    fdc_irq_edges: int
    rd1nt_reads: dict[str, int]
    final_events: list[str]
    timeline: list[str]


def diag_disk(letter: str) -> Path:
    disk = DIAG_DIR / f"{letter.upper()}.IMD"
    if not disk.exists():
        raise SystemExit(f"diagnostic disk not found: {disk}")
    return disk


def load_catalogs(path: Path = CATALOG_JSON) -> list[dict[str, object]]:
    if not path.exists():
        raise SystemExit(f"catalog inventory not found: {path}; run tools/diagnostic_tests/collect_tests.py")
    return json.loads(path.read_text())


def catalog_for_disk(letter: str, catalogs: list[dict[str, object]] | None = None) -> dict[str, object]:
    catalogs = catalogs if catalogs is not None else load_catalogs()
    want = letter.upper()
    for catalog in catalogs:
        if str(catalog.get("letter", "")).upper() == want:
            return catalog
    raise SystemExit(f"diagnostic disk {letter!r} is not present in {CATALOG_JSON}")


def iter_catalog_entries(letter: str | None = None) -> Iterable[tuple[dict[str, object], dict[str, object]]]:
    catalogs = load_catalogs()
    for catalog in catalogs:
        if letter and str(catalog.get("letter", "")).upper() != letter.upper():
            continue
        for entry in catalog.get("entries", []):
            yield catalog, entry


def entry_display_name(entry: dict[str, object]) -> str:
    name = str(entry["name"])
    return name[:6] if len(name) >= 6 else name


def resolve_catalog_entry(letter: str, selector: str) -> dict[str, object]:
    selector = selector.strip().upper()
    catalog = catalog_for_disk(letter)
    entries = list(catalog.get("entries", []))

    if selector.isdigit():
        wanted = int(selector, 10)
        for entry in entries:
            if int(entry["index"]) == wanted:
                return entry

    matches = [
        entry
        for entry in entries
        if str(entry["name"]).upper().startswith(selector)
        or entry_display_name(entry).upper() == selector
    ]
    if len(matches) == 1:
        return matches[0]
    if matches:
        names = ", ".join(f"{int(entry['index']):03d}:{entry['name']}" for entry in matches[:12])
        raise SystemExit(f"ambiguous test selector {selector!r}: {names}")
    raise SystemExit(f"test selector {selector!r} was not found on diagnostic disk {letter.upper()}")


def monitor_load_keys(code: int, go: bool, load_wait: float) -> str:
    keys = f"\\n1\\n{code:03d}\\n"
    if go:
        keys += f"{{WAIT:{load_wait:g}}}4\\n"
    return keys


def timestamp() -> str:
    return time.strftime("%Y%m%d-%H%M%S")


def shell_join(args: Iterable[str | Path]) -> str:
    return " ".join(shlex.quote(str(arg)) for arg in args)


def parse_trace(path: Path, last_count: int = 25) -> TraceSummary:
    summary = TraceSummary(path=str(path))
    io_counts: Counter[str] = Counter()
    reg_counts: Counter[str] = Counter()
    recent: list[str] = []

    with path.open("r", errors="replace") as f:
        for lineno, line in enumerate(f, 1):
            line = line.rstrip("\n")
            summary.lines = lineno
            if len(recent) >= last_count:
                recent.pop(0)
            recent.append(line)

            m = CONSOLE_RE.match(line)
            if m:
                summary.console.append(
                    ConsoleEvent(
                        line=lineno,
                        pc=int(m.group("pc"), 16),
                        data=int(m.group("data"), 16),
                        label=m.group("label") or "",
                    )
                )
                continue

            m = IO_RE.match(line)
            if m:
                event = IoEvent(
                    line=lineno,
                    prefix=m.group("prefix"),
                    rw=m.group("rw"),
                    pc=int(m.group("pc"), 16),
                    addr=int(m.group("addr"), 16),
                    reg=int(m.group("reg"), 16),
                    data=int(m.group("data"), 16),
                    raw=int(m.group("raw"), 16),
                    mask=int(m.group("mask"), 16),
                )
                key = f"{event.prefix} {event.rw}"
                io_counts[key] += 1
                reg_counts[f"{key} reg={event.reg:02X}"] += 1
                if event.prefix == "UC-KDC" and event.rw == "R" and event.reg == 0x22:
                    summary.kdc_bytes.append(event.data)
                continue

            if SCREEN_BEGIN_RE.match(line):
                summary.screen_snapshots += 1

    summary.io_counts = dict(sorted(io_counts.items()))
    summary.reg_counts = dict(sorted(reg_counts.items()))
    summary.last_events = recent
    return summary


def print_summary(summary: TraceSummary) -> None:
    print(f"trace: {summary.path}")
    print(f"lines: {summary.lines}")
    print(f"console: {' '.join(summary.console_hex) or '(none)'}")
    if summary.console:
        last = summary.console[-1]
        label = f" ; {last.label}" if last.label else ""
        print(f"last console: line {last.line} pc={last.pc:08X} data={last.data:02X}{label}")
    print(f"reached monitor prompt: {'yes' if summary.reached_monitor_prompt else 'no'}")
    if summary.kdc_bytes:
        print("kdc bytes:", " ".join(f"{b:02X}" for b in summary.kdc_bytes))
    if summary.screen_snapshots:
        print(f"screen snapshots in trace: {summary.screen_snapshots}")
    if summary.io_counts:
        print("io counts:")
        for key, count in summary.io_counts.items():
            print(f"  {key}: {count}")


def parse_vram_trace(path: Path, default_cols: int = 80, default_rows: int = 25) -> ScreenState:
    # GO252 decodes a 4 KiB VRAM and mirrors it throughout FF0000-FFFFFF.
    # Preserve the same low-12-bit folding used by the device model so traces
    # from software choosing FF2xxx/FF3xxx reconstruct the displayed screen.
    vram = bytearray(0x1000)
    crtc = [0] * 32
    vram_writes = 0
    crtc_writes = 0

    with path.open("r", errors="replace") as f:
        for line in f:
            line = line.rstrip("\n")
            m = VRAM_RE.match(line)
            if m:
                vram[int(m.group("off"), 16) & 0x0fff] = int(m.group("data"), 16) & 0xff
                vram_writes += 1
                continue
            m = CRTC_RE.match(line)
            if m:
                crtc[int(m.group("reg"), 16) & 0x1f] = int(m.group("data"), 16) & 0xff
                crtc_writes += 1

    cols = crtc[1] or default_cols
    rows = crtc[6] or default_rows
    cols = max(1, min(cols, 132))
    rows = max(1, min(rows, 50))
    start = ((crtc[12] << 8) | crtc[13]) & 0x3fff

    lines: list[str] = []
    for row in range(rows):
        chars: list[str] = []
        for col in range(cols):
            off = (((start + row * cols + col) << 1) + 1) & 0x0fff
            ch = vram[off]
            chars.append(chr(ch) if 0x20 <= ch < 0x7f else " ")
        lines.append("".join(chars).rstrip())

    return ScreenState(
        source=str(path),
        vram_writes=vram_writes,
        crtc_writes=crtc_writes,
        cols=cols,
        rows=rows,
        start=start,
        text="\n".join(lines),
    )


def write_screen(path: Path, state: ScreenState) -> None:
    path.write_text(
        "\n".join(
            [
                f"source: {state.source}",
                f"vram_writes: {state.vram_writes}",
                f"crtc_writes: {state.crtc_writes}",
                f"geometry: {state.cols}x{state.rows}",
                f"start: 0x{state.start:04x}",
                "",
                state.text,
                "",
            ]
        )
    )


def describe_contr(value: int) -> str:
    names = [
        ("EN100", 0),
        ("RESFD", 1),
        ("SCANO", 2),
        ("MOTO1", 3),
        ("DIAGN", 4),
        ("ERRO1", 5),
        ("SCRVO", 6),
        ("MOTO2", 7),
    ]
    set_bits = [name for name, bit in names if value & (1 << bit)]
    return ",".join(set_bits) if set_bits else "none"


def describe_rd1nt(value: int) -> str:
    names = [
        ("INTMO", 0),
        ("INTOO", 1),
        ("PERRO", 2),
        ("FUMEO", 3),
    ]
    set_bits = [name for name, bit in names if value & (1 << bit)]
    return ",".join(set_bits) if set_bits else "none"


def fdc_command_key(first: int) -> int:
    # uPD765 command bits 7/6/5 are MT/MFM/SK flags for several commands.
    return first & 0x1f


def fdc_command_name(first: int) -> str:
    key = fdc_command_key(first)
    base = FDC_COMMANDS.get(key, (f"UNKNOWN_{key:02X}", 0, 0))[0]
    flags: list[str] = []
    if first & 0x80:
        flags.append("MT")
    if first & 0x40:
        flags.append("MFM")
    if first & 0x20:
        flags.append("SK")
    return base + (f" [{' '.join(flags)}]" if flags else "")


def decode_st0(value: int) -> str:
    ic = (value >> 6) & 3
    ic_name = ["normal", "abnormal", "invalid", "poll"][ic]
    flags = [ic_name]
    for name, bit in (("SE", 5), ("EC", 4), ("NR", 3), ("HD", 2)):
        if value & (1 << bit):
            flags.append(name)
    flags.append(f"US={value & 3}")
    return ",".join(flags)


def decode_st3(value: int) -> str:
    flags = []
    for name, bit in (("WP", 6), ("RY", 5), ("T0", 4), ("TS", 3), ("HD", 2)):
        if value & (1 << bit):
            flags.append(name)
    flags.append(f"US={value & 3}")
    return ",".join(flags)


def summarize_result(command: list[int], result: list[int]) -> str:
    if not command or not result:
        return ""
    key = fdc_command_key(command[0])
    if key == 0x04 and len(result) >= 1:
        return f"ST3={result[0]:02X}({decode_st3(result[0])})"
    if key == 0x08 and len(result) >= 2:
        return f"ST0={result[0]:02X}({decode_st0(result[0])}) PCN={result[1]:02X}"
    if len(result) >= 7:
        return (
            f"ST0={result[0]:02X}({decode_st0(result[0])}) "
            f"ST1={result[1]:02X} ST2={result[2]:02X} "
            f"C/H/R/N={result[3]:02X}/{result[4]:02X}/{result[5]:02X}/{result[6]:02X}"
        )
    return ""


def parse_fdu_trace(path: Path, max_timeline: int = 1200, tail_count: int = 80) -> FduDecode:
    timeline: list[str] = []
    tail: list[str] = []
    commands: Counter[str] = Counter()
    rd1nt_reads: Counter[str] = Counter()
    timer_edges = 0
    fdc_irq_edges = 0
    current_cmd: list[int] = []
    current_expected = 0
    current_result: list[int] = []

    def add(line: str) -> None:
        if len(timeline) < max_timeline:
            timeline.append(line)
        if len(tail) >= tail_count:
            tail.pop(0)
        tail.append(line)

    def close_result(lineno: int, pc: int) -> None:
        nonlocal current_result
        if current_cmd and current_result:
            summary = summarize_result(current_cmd, current_result)
            suffix = f" ; {summary}" if summary else ""
            add(
                f"{lineno:06d} pc={pc:08X} RESULT {fdc_command_name(current_cmd[0])} "
                f"bytes={' '.join(f'{b:02X}' for b in current_result)}{suffix}"
            )
        current_result = []

    lines = 0
    with path.open("r", errors="replace") as f:
        for lineno, line in enumerate(f, 1):
            lines = lineno
            m = FDU_RE.match(line.rstrip("\n"))
            if not m:
                continue
            event = m.group("event")
            pc = int(m.group("pc"), 16)
            reg = int(m.group("reg"), 16)
            data = int(m.group("data"), 16)
            pending = int(m.group("pending"))
            ien = int(m.group("ien"))
            intmo_lat = int(m.group("intmo_lat"))
            timer = int(m.group("timer"))
            intoo_lat = int(m.group("intoo_lat"))
            fdc = int(m.group("fdc"))
            vec = int(m.group("vec"), 16)
            dma_hi = int(m.group("dma_hi"), 16)
            dma_ch1 = int(m.group("dma_ch1"), 16)
            dma_byte = int(m.group("dma_byte"), 16)
            state = (
                f"pend={pending} ien={ien} intmo={intmo_lat}/{timer} "
                f"intoo={intoo_lat}/{fdc} vec={vec:02X} dma={dma_hi:02X}:{dma_ch1:04X}+{dma_byte:06X}"
            )

            if event == "W" and reg == 0x1F:
                if current_cmd and len(current_cmd) >= current_expected:
                    close_result(lineno, pc)
                    current_cmd = []
                    current_expected = 0
                if not current_cmd:
                    key = fdc_command_key(data)
                    current_expected = FDC_COMMANDS.get(key, (None, 1, 0))[1] or 1
                    current_cmd = [data]
                    name = fdc_command_name(data)
                    commands[name] += 1
                    add(f"{lineno:06d} pc={pc:08X} CMD {name} byte0={data:02X} expect={current_expected} ; {state}")
                else:
                    current_cmd.append(data)
                    add(
                        f"{lineno:06d} pc={pc:08X} CMDPARM {fdc_command_name(current_cmd[0])} "
                        f"{len(current_cmd)}/{current_expected} data={data:02X} ; {state}"
                    )
                continue

            if event == "R" and reg == 0x1F:
                if current_cmd:
                    current_result.append(data)
                    key = fdc_command_key(current_cmd[0])
                    expected_result = FDC_COMMANDS.get(key, (None, 0, 0))[2]
                    if expected_result and len(current_result) >= expected_result:
                        close_result(lineno, pc)
                else:
                    add(f"{lineno:06d} pc={pc:08X} RESULT-ORPHAN data={data:02X} ; {state}")
                continue

            if event == "W" and reg == 0xE7:
                add(f"{lineno:06d} pc={pc:08X} CONTR={data:02X}({describe_contr(data)}) ; {state}")
                continue

            if event == "R" and reg == 0xF7:
                rd1nt_reads[f"{data:02X} {describe_rd1nt(data)}"] += 1
                add(f"{lineno:06d} pc={pc:08X} RD1NT={data:02X}({describe_rd1nt(data)}) ; {state}")
                continue

            if event == "W" and reg == 0xFF:
                add(f"{lineno:06d} pc={pc:08X} E01NT strobe data={data:02X} ; {state}")
                continue

            if event == "TIMER":
                if data:
                    timer_edges += 1
                add(f"{lineno:06d} pc={pc:08X} TIMER data={data:02X} ; {state}")
                continue

            if event == "FDCINT":
                if data:
                    fdc_irq_edges += 1
                add(f"{lineno:06d} pc={pc:08X} FDCINT data={data:02X} ; {state}")
                continue

            if event == "VIACK":
                add(f"{lineno:06d} pc={pc:08X} VIACK vector={data:02X} ; {state}")

    close_result(lines, 0)
    return FduDecode(
        source=str(path),
        lines=lines,
        commands=dict(sorted(commands.items())),
        timer_edges=timer_edges,
        fdc_irq_edges=fdc_irq_edges,
        rd1nt_reads=dict(sorted(rd1nt_reads.items())),
        final_events=tail,
        timeline=timeline,
    )


def write_fdu_timeline(path: Path, decode: FduDecode) -> None:
    lines = [
        f"source: {decode.source}",
        f"lines: {decode.lines}",
        f"timer rising edges: {decode.timer_edges}",
        f"fdc irq rising edges: {decode.fdc_irq_edges}",
        "",
        "commands:",
    ]
    if decode.commands:
        lines.extend(f"  {name}: {count}" for name, count in decode.commands.items())
    else:
        lines.append("  (none)")
    lines.append("")
    lines.append("RD1NT reads:")
    if decode.rd1nt_reads:
        lines.extend(f"  {value}: {count}" for value, count in decode.rd1nt_reads.items())
    else:
        lines.append("  (none)")
    lines.append("")
    lines.append("timeline:")
    lines.extend(decode.timeline)
    lines.append("")
    lines.append("final events:")
    lines.extend(decode.final_events)
    lines.append("")
    path.write_text("\n".join(lines))


def print_fdu_summary(decode: FduDecode) -> None:
    print(f"fdu source: {decode.source}")
    print(f"fdu lines: {decode.lines}")
    print(f"timer rising edges: {decode.timer_edges}")
    print(f"fdc irq rising edges: {decode.fdc_irq_edges}")
    if decode.commands:
        print("fdc commands:")
        for name, count in decode.commands.items():
            print(f"  {name}: {count}")
    if decode.rd1nt_reads:
        print("rd1nt reads:")
        for value, count in decode.rd1nt_reads.items():
            print(f"  {value}: {count}")
    if decode.final_events:
        print("final fdu events:")
        for line in decode.final_events[-12:]:
            print(f"  {line}")


def write_json(path: Path, summary: TraceSummary, metadata: dict[str, object]) -> None:
    data = {
        "metadata": metadata,
        "summary": asdict(summary),
        "console_hex": summary.console_hex,
        "reached_monitor_prompt": summary.reached_monitor_prompt,
    }
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def common_mame_args(args: argparse.Namespace, script: Path, seconds: int | None) -> list[str]:
    cmd = [
        str(args.mame_bin),
        "m40",
    ]
    # Slot-fitting options (e.g. -fdc:0 8dsdd) must precede slot-dependent media
    # options like -flop1, so extra args go first.
    cmd.extend(args.mame_arg)
    cmd += [
        getattr(args, "flop_name", None) or "-flop1",
        str(args.disk),
        "-autoboot_script",
        str(script),
        "-nomouse",
    ]

    if args.headless:
        cmd += ["-video", "none", "-sound", "none", "-nothrottle"]
    else:
        cmd += ["-window", "-video", args.video, "-sound", args.sound]
        if args.nothrottle:
            cmd.append("-nothrottle")

    if seconds is not None:
        cmd += ["-seconds_to_run", str(seconds)]

    return cmd


def run_process(cmd: list[str], env: dict[str, str], cwd: Path, stdout_path: Path) -> int:
    with stdout_path.open("w") as out:
        out.write("$ " + shell_join(cmd) + "\n\n")
        out.flush()
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            env=env,
            stdout=out,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
    return proc.returncode


def cmd_run(args: argparse.Namespace) -> int:
    run_dir = args.out_root / f"{timestamp()}-{args.name}"
    run_dir.mkdir(parents=True, exist_ok=False)
    trace_path = run_dir / "trace.log"
    vram_path = run_dir / "vram.log"
    fdu_path = run_dir / "fdu.log"
    fdu_timeline_path = run_dir / "fdu_timeline.txt"
    screen_path = run_dir / "screen.txt"
    stdout_path = run_dir / "mame.stdout"
    summary_path = run_dir / "summary.json"
    command_path = run_dir / "command.txt"

    env = os.environ.copy()
    env["M40_TRACE_LOG"] = str(trace_path)
    if args.keys is not None:
        env["M40_KEYS"] = args.keys
    if args.key_delay is not None:
        env["M40_KEY_DELAY"] = str(args.key_delay)
    if args.inter_key_delay is not None:
        env["M40_INTER_KEY_DELAY"] = str(args.inter_key_delay)
    if args.screen_interval is not None:
        env["M40_SCREEN_INTERVAL"] = str(args.screen_interval)
    if args.vram_trace:
        env["M40_VRAM_TRACE"] = str(vram_path)
    if args.fdu_trace:
        env["M40_FDU_TRACE"] = str(fdu_path)

    if args.headless:
        env.setdefault("SDL_VIDEODRIVER", "dummy")
        env.setdefault("SDL_AUDIODRIVER", "dummy")

    seconds = args.seconds
    cmd = common_mame_args(args, args.trace_script, seconds)
    command_path.write_text(shell_join(cmd) + "\n")

    print(f"run dir: {run_dir}")
    print(f"trace: {trace_path}")
    print("$ " + shell_join(cmd))
    rc = run_process(cmd, env, args.mame_root, stdout_path)
    print(f"mame exit code: {rc}")

    if not trace_path.exists():
        print(f"trace log was not created: {trace_path}", file=sys.stderr)
        return rc or 2

    summary = parse_trace(trace_path)
    metadata = {
        "kind": "trace",
        "disk": str(args.disk),
        "keys": args.keys,
        "seconds": seconds,
        "headless": args.headless,
        "video": None if args.headless else args.video,
        "sound": None if args.headless else args.sound,
        "mame_root": str(args.mame_root),
        "mame_bin": str(args.mame_bin),
        "returncode": rc,
        "command": cmd,
    }
    if args.vram_trace:
        metadata["vram_trace"] = str(vram_path)
        metadata["screen"] = str(screen_path)
        if vram_path.exists():
            screen = parse_vram_trace(vram_path)
            write_screen(screen_path, screen)
            metadata["screen_state"] = asdict(screen)
            print(f"vram trace: {vram_path}")
            print(f"screen text: {screen_path}")
            visible = [line for line in screen.text.splitlines() if line.strip()]
            if visible:
                print("screen nonblank lines:")
                for line in visible[:12]:
                    print(f"  {line}")
            else:
                print("screen nonblank lines: (none)")
        else:
            print(f"vram trace was not created: {vram_path}", file=sys.stderr)
    if args.fdu_trace:
        metadata["fdu_trace"] = str(fdu_path)
        metadata["fdu_timeline"] = str(fdu_timeline_path)
        if fdu_path.exists():
            print(f"fdu trace: {fdu_path}")
            fdu_decode = parse_fdu_trace(fdu_path)
            write_fdu_timeline(fdu_timeline_path, fdu_decode)
            metadata["fdu_decode"] = {
                "commands": fdu_decode.commands,
                "timer_edges": fdu_decode.timer_edges,
                "fdc_irq_edges": fdu_decode.fdc_irq_edges,
                "rd1nt_reads": fdu_decode.rd1nt_reads,
                "final_events": fdu_decode.final_events,
            }
            print(f"fdu timeline: {fdu_timeline_path}")
            print_fdu_summary(fdu_decode)
        else:
            print(f"fdu trace was not created: {fdu_path}", file=sys.stderr)
    write_json(summary_path, summary, metadata)
    print_summary(summary)
    return rc


def cmd_dump(args: argparse.Namespace) -> int:
    run_dir = args.out_root / f"{timestamp()}-{args.name}"
    dump_dir = run_dir / "segments"
    run_dir.mkdir(parents=True, exist_ok=False)
    dump_dir.mkdir()
    stdout_path = run_dir / "mame.stdout"
    command_path = run_dir / "command.txt"

    env = os.environ.copy()
    env["M40_DUMP_DIR"] = str(dump_dir)
    env["M40_DUMP_SEGMENTS"] = args.segments
    if args.keys is not None:
        env["M40_KEYS"] = args.keys
    if args.key_delay is not None:
        env["M40_KEY_DELAY"] = str(args.key_delay)
    if args.post_key_wait is not None:
        env["M40_POST_KEY_WAIT"] = str(args.post_key_wait)
    if args.dump_delay is not None:
        env["M40_DUMP_DELAY"] = str(args.dump_delay)

    if args.headless:
        env.setdefault("SDL_VIDEODRIVER", "dummy")
        env.setdefault("SDL_AUDIODRIVER", "dummy")

    cmd = common_mame_args(args, args.dump_script, args.seconds)
    command_path.write_text(shell_join(cmd) + "\n")

    print(f"run dir: {run_dir}")
    print(f"dump dir: {dump_dir}")
    print("$ " + shell_join(cmd))
    rc = run_process(cmd, env, args.mame_root, stdout_path)
    print(f"mame exit code: {rc}")
    dumps = sorted(dump_dir.glob("m40_seg_*.bin"))
    for path in dumps:
        print(f"dumped {path.name}: {path.stat().st_size} bytes")
    if not dumps:
        print("no segment dumps produced", file=sys.stderr)
    return rc


def cmd_parse(args: argparse.Namespace) -> int:
    summary = parse_trace(args.trace)
    print_summary(summary)
    if args.json:
        write_json(args.json, summary, {"kind": "parse", "trace": str(args.trace)})
    return 0


def cmd_screen(args: argparse.Namespace) -> int:
    screen = parse_vram_trace(args.vram_trace, args.cols, args.rows)
    if args.output:
        write_screen(args.output, screen)
        print(f"wrote {args.output}")
    print(f"source: {screen.source}")
    print(f"vram writes: {screen.vram_writes}")
    print(f"crtc writes: {screen.crtc_writes}")
    print(f"geometry: {screen.cols}x{screen.rows} start=0x{screen.start:04x}")
    print(screen.text)
    return 0


def cmd_fdu(args: argparse.Namespace) -> int:
    decode = parse_fdu_trace(args.fdu_trace, args.max_timeline, args.tail)
    if args.output:
        write_fdu_timeline(args.output, decode)
        print(f"wrote {args.output}")
    print_fdu_summary(decode)
    return 0


def cmd_tests(args: argparse.Namespace) -> int:
    rows: list[dict[str, object]] = []
    for catalog, entry in iter_catalog_entries(args.diag):
        rows.append(
            {
                "disk": catalog["letter"],
                "code": int(entry["index"]),
                "name": entry["name"],
                "display": entry_display_name(entry),
                "sectors": entry["length"],
                "bytes": entry["byte_length"],
                "note": entry.get("note", ""),
            }
        )

    if args.json:
        args.json.write_text(json.dumps(rows, indent=2, sort_keys=True) + "\n")
        print(f"wrote {args.json}")

    if not rows:
        print("no catalog entries matched")
        return 1

    print("disk code name           sectors bytes  note")
    print("---- ---- -------------- ------- ------ ----")
    for row in rows:
        print(
            f"{row['disk']:>4} {row['code']:03d}  {row['name']:<14} "
            f"{row['sectors']:>7} {row['bytes']:>6}  {row['note']}"
        )
    return 0


def diagnostic_letter_for_run(args: argparse.Namespace) -> str:
    if getattr(args, "diag", None):
        return args.diag.upper()
    stem = args.disk.stem.upper()
    if stem in set("ABCDEFGHR"):
        return stem
    raise SystemExit("run-test needs --diag when --disk is not one of the known diagnostic images")


def cmd_run_test(args: argparse.Namespace) -> int:
    letter = diagnostic_letter_for_run(args)
    entry = resolve_catalog_entry(letter, args.test)
    code = int(entry["index"])
    args.keys = monitor_load_keys(code, args.go, args.load_wait)
    if args.name == "m40":
        action = "go" if args.go else "load"
        args.name = f"{letter}-{action}-{code:03d}-{entry_display_name(entry).lower()}"
    print(f"test: disk {letter} code {code:03d} {entry['name']}")
    print(f"keys: {args.keys}")
    return cmd_run(args)


def cmd_disks(args: argparse.Namespace) -> int:
    for path in sorted(DIAG_DIR.glob("*.IMD")):
        print(f"{path.stem}: {path}")
    return 0


def add_common_run_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--mame-root", type=Path, default=DEFAULT_MAME_ROOT)
    parser.add_argument("--mame-bin", type=Path, default=DEFAULT_MAME_BIN)
    parser.add_argument("--disk", type=Path, default=diag_disk("B"))
    parser.add_argument("--diag", choices=list("ABCDEFGHR"), help="use diagnostic disk letter")
    parser.add_argument("--out-root", type=Path, default=DEFAULT_OUT_ROOT)
    parser.add_argument("--name", default="m40")
    parser.add_argument("--seconds", type=int, default=60, help="bounded run duration; avoids known unbounded live-run stall")
    parser.add_argument("--headless", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--video", default="opengl")
    parser.add_argument("--sound", default="none")
    parser.add_argument("--nothrottle", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--mame-arg", action="append", default=[], help="extra MAME argument; repeat as needed")
    parser.add_argument("--flop-name", dest="flop_name", default=None,
                        help="media option name for the boot floppy (default -flop1: controller unit 1 / BCOS FD1)")


def normalize_args(args: argparse.Namespace) -> argparse.Namespace:
    if getattr(args, "diag", None):
        args.disk = diag_disk(args.diag)
    args.mame_root = args.mame_root.resolve()
    args.mame_bin = args.mame_bin.resolve()
    args.disk = args.disk.expanduser().resolve()
    args.out_root = args.out_root.resolve()
    if hasattr(args, "trace_script"):
        args.trace_script = args.trace_script.resolve()
    if hasattr(args, "dump_script"):
        args.dump_script = args.dump_script.resolve()
    if not args.mame_bin.exists():
        raise SystemExit(f"MAME binary not found: {args.mame_bin}")
    if not args.disk.exists():
        raise SystemExit(f"disk image not found: {args.disk}")
    return args


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_run = sub.add_parser("run", help="run MAME with the diagnostic trace Lua script")
    add_common_run_args(p_run)
    p_run.add_argument("--trace-script", type=Path, default=DEFAULT_TRACE_SCRIPT)
    p_run.add_argument("--keys")
    p_run.add_argument("--key-delay", type=float)
    p_run.add_argument("--inter-key-delay", type=float)
    p_run.add_argument("--screen-interval", type=float)
    p_run.add_argument("--vram-trace", action="store_true", help="enable driver-side M40_VRAM_TRACE and reconstruct screen.txt")
    p_run.add_argument("--fdu-trace", action="store_true", help="enable driver-side M40_FDU_TRACE for FDC/DMA register activity")
    p_run.set_defaults(func=cmd_run)

    p_dump = sub.add_parser("dump", help="run MAME with the segment dump Lua script")
    add_common_run_args(p_dump)
    p_dump.add_argument("--dump-script", type=Path, default=DEFAULT_DUMP_SCRIPT)
    p_dump.add_argument("--segments", default="00,01,1d,1e,21,3d")
    p_dump.add_argument("--keys")
    p_dump.add_argument("--key-delay", type=float)
    p_dump.add_argument("--post-key-wait", type=float)
    p_dump.add_argument("--dump-delay", type=float)
    p_dump.set_defaults(func=cmd_dump)

    p_parse = sub.add_parser("parse", help="summarize an existing trace log")
    p_parse.add_argument("trace", type=Path)
    p_parse.add_argument("--json", type=Path)
    p_parse.set_defaults(func=cmd_parse)

    p_screen = sub.add_parser("screen", help="reconstruct text screen from an M40_VRAM_TRACE log")
    p_screen.add_argument("vram_trace", type=Path)
    p_screen.add_argument("--output", type=Path)
    p_screen.add_argument("--cols", type=int, default=80)
    p_screen.add_argument("--rows", type=int, default=25)
    p_screen.set_defaults(func=cmd_screen)

    p_fdu = sub.add_parser("fdu", help="decode a driver-side M40_FDU_TRACE fdu.log")
    p_fdu.add_argument("fdu_trace", type=Path)
    p_fdu.add_argument("--output", type=Path)
    p_fdu.add_argument("--max-timeline", type=int, default=1200)
    p_fdu.add_argument("--tail", type=int, default=80)
    p_fdu.set_defaults(func=cmd_fdu)

    p_tests = sub.add_parser("tests", help="list cataloged diagnostic programs")
    p_tests.add_argument("--diag", choices=list("ABCDEFGHR"), help="limit to one diagnostic disk")
    p_tests.add_argument("--json", type=Path, help="write the selected inventory as JSON")
    p_tests.set_defaults(func=cmd_tests)

    p_run_test = sub.add_parser("run-test", help="load and optionally GO a cataloged diagnostic program")
    add_common_run_args(p_run_test)
    p_run_test.add_argument("test", help="test code, e.g. 013, or catalog prefix, e.g. KEYTE1")
    p_run_test.add_argument("--trace-script", type=Path, default=DEFAULT_TRACE_SCRIPT)
    p_run_test.add_argument("--go", action=argparse.BooleanOptionalAction, default=True, help="issue monitor GO after LOAD")
    p_run_test.add_argument("--load-wait", type=float, default=35.0, help="seconds to wait after LOAD before GO")
    p_run_test.add_argument("--key-delay", type=float, default=70.0)
    p_run_test.add_argument("--inter-key-delay", type=float, default=8.0)
    p_run_test.add_argument("--screen-interval", type=float)
    p_run_test.add_argument("--vram-trace", action=argparse.BooleanOptionalAction, default=True)
    p_run_test.add_argument("--fdu-trace", action=argparse.BooleanOptionalAction, default=True)
    p_run_test.set_defaults(func=cmd_run_test)

    p_disks = sub.add_parser("disks", help="list known DCOS 8.4 diagnostic disks")
    p_disks.set_defaults(func=cmd_disks)

    args = parser.parse_args(argv)
    if args.cmd in {"run", "dump", "run-test"}:
        args = normalize_args(args)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
