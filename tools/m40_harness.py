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
    p_run_test.set_defaults(func=cmd_run_test)

    p_disks = sub.add_parser("disks", help="list known DCOS 8.4 diagnostic disks")
    p_disks.set_defaults(func=cmd_disks)

    args = parser.parse_args(argv)
    if args.cmd in {"run", "dump", "run-test"}:
        args = normalize_args(args)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
