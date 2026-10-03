#!/usr/bin/env python3
"""Generate M40 ANK host-key maps from the shared US 101-key SVG geometry."""

# copyright-holders: Salvatore Paxia

from __future__ import annotations

import copy
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)
ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")
ET.register_namespace("cc", "http://creativecommons.org/ns#")
ET.register_namespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
ET.register_namespace("sodipodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd")
ET.register_namespace("inkscape", "http://www.inkscape.org/namespaces/inkscape")

HERE = Path(__file__).resolve().parent
TEMPLATE = HERE / "keyboard-101-template.svg"

DIRECT = {
    "Esc": "TOP\nKEY\n39", "F1": "F1\n44", "F2": "F2\n46", "F3": "F3\n63",
    "F4": "F4\n5B", "F5": "F5\n53", "F6": "F6\n4B", "F7": "F7\n56",
    "F8": "F8\n5A", "F9": "KB MODE\n02", "F10": "", "F11": "", "F12": "MAME\nUI",
    "PrtSc": "", "ScrLk": "", "Pause": "HALT/\nERASE\n48",
    "`": "@ '\n2A", "1": "1 !\n01", "2": "2 \"\n04", "3": "3 #\n07",
    "4": "4 $\n17", "5": "5 %\n1D", "6": "6 &\n1E", "7": "7 '\n13",
    "8": "8 (\n21", "9": "9 )\n24", "0": "0\n2E", "-": "- =\n2C",
    "=": "~ ^\n2B", "Backspace": "BS\n31",
    "Tab": "TAB\n05", "Q": "Q\n03", "W": "W\n0C", "E": "E\n08", "R": "R\n1F",
    "T": "T\n11", "Y": "Y\n14", "U": "U\n19", "I": "I\n25", "O": "O\n26",
    "P": "P\n30", "[": "[ {\n36", "]": "] }\n38", "\\": "\\\n0A",
    "CapsLock": "LOCK\n6F/77", "A": "A\n09", "S": "S\n0F", "D": "D\n0D",
    "F": "F\n18", "G": "G\n15", "H": "H\n1B", "J": "J\n1A", "K": "K\n28",
    "L": "L\n22", ";": "; +\n2F", "'": "* :\n34", "Enter": "RETURN\n35",
    "LShift": "SHIFT\n6E/76", "Z": "Z\n0B", "X": "X\n0E", "C": "C\n10",
    "V": "V\n20", "B": "B\n1C", "N": "N\n16", "M": "M\n27", ",": ",\n23",
    ".": ".\n2D", "/": "?\n29", "RShift": "SHIFT\n6E/76",
    "LCtrl": "CONTROL\n70/78", "LWin": "", "LAlt": "HOLD ALT", "Space": "SPACE\n12",
    "RAlt": "HOLD ALT", "RWin": "", "Menu": "", "RCtrl": "CONTROL\n70/78",
    "Insert": "IC/IL\nFETCH\n5C", "Home": "HOME/\nPR\n3F", "PgUp": "BACK\nTAB\n4C",
    "Delete": "DC/DL\n3B", "End": "END/\nRES\n51", "PgDn": "FWD\nTAB\n3A",
    "Up": "↑\n4E", "Left": "←\n4A", "Down": "↓\n3C", "Right": "→\n3E",
    "NumLock": "", "Kp/": "\\\n42", "Kp*": "E↑\n43", "Kp-": "(\n41",
    "Kp7": "7\n4F", "Kp8": "8\n50", "Kp9": "9\n4D", "Kp+": ")\n47",
    "Kp4": "4\n57", "Kp5": "5\n58", "Kp6": "6\n55", "Kp1": "1\n5F",
    "Kp2": "2\n60", "Kp3": "3\n5D", "Kp0": "0\n67", "Kp.": ".\n62",
    "KpEnter": "ENTER\n61",
}

SHIFT = {
    "F1": "F9\n44", "F2": "F10\n46", "F3": "F11\n63", "F4": "F12\n5B",
    "F5": "F13\n53", "F6": "F14\n4B", "F7": "F15\n56", "F8": "F16\n5A",
    "1": "!\n01", "2": "\"\n04", "3": "#\n07", "4": "$\n17", "5": "%\n1D",
    "6": "&\n1E", "7": "'\n13", "8": "(\n21", "9": ")\n24", "-": "=\n2C",
    "=": "^\n2B", "`": "'\n2A", "[": "{\n36", "]": "}\n38", ";": "+\n2F",
    "'": ":\n34", "/": "?\n29", "LShift": "SHIFT", "RShift": "SHIFT",
}

ALT = {
    "F9": "RED\nCLEAR\n37", "L": "LIST\n54", "S": "SAVE/\nEXIT\n3D",
    "O": "OLD\n66", "R": "RUN\n64", "D": "DRAW\n40", "A": "AUTO#\n5E",
    "K": "SKIP\n52", "C": "CLEAR\n49", "H": "HALT/\nERASE\n48",
    "Backspace": "DEL/ESC\n06", "Kp-": "KP ,\n59", "Kp0": "00\n68",
    "Kp.": "000\n65", "LAlt": "HOLD ALT", "RAlt": "HOLD ALT",
}

ESE_COMMAND = {
    "F9": "KB MODE", "R": "RUN", "L": "LIST", "O": "OLD",
    "S": "SAVE", "A": "AUTO#", "D": "DRAW", "H": "ERASE",
    "K": "SKIP", "C": "CLEAR", "Insert": "FETCH", "Delete": "DEL\nLINE",
    "Enter": "RETURN\n35", "KpEnter": "EOL\n61", "LAlt": "HOLD ALT", "RAlt": "HOLD ALT",
    "LShift": "SHIFT", "RShift": "SHIFT",
}

KEYWORDS = {
    "A": "IF", "B": "STEP", "C": "FOR", "D": "DEF", "E": "DISP", "F": "FN",
    "G": "CALL", "H": "ON", "I": "WRITE:", "J": "GOTO", "K": "GOSUB",
    "L": "RETURN", "M": "END", "N": "NEXT", "O": "AND", "P": "OR",
    "Q": "REM", "R": "PRINT", "S": "THEN", "T": "USING", "U": "READ",
    "V": "TO", "W": "FKEY#", "X": "STOP", "Y": "INPUT", "Z": "DATA",
    "F9": "KB MODE", "LShift": "SHIFT", "RShift": "SHIFT",
}

UNASSIGNED = {k for k, v in DIRECT.items() if not v}
UI_KEYS = {"F12"}


def key_name(group: ET.Element) -> str | None:
    title = group.find(f"{{{SVG}}}title")
    return title.text.split(":", 1)[0] if title is not None and title.text else None


def set_label(group: ET.Element, label: str) -> None:
    path = group.find(f"{{{SVG}}}path")
    nums = re.findall(r"[-+]?[0-9]*\.?[0-9]+", path.get("d", "")) if path is not None else []
    key_width = float(nums[2]) if len(nums) >= 3 else 28.0
    texts = group.findall(f".//{{{SVG}}}text")
    if not texts:
        if not label:
            return
        if path is None:
            return
        if len(nums) < 3:
            return
        x0, y0, width = map(float, nums[:3])
        text = ET.SubElement(group, f"{{{SVG}}}text", {
            "x": f"{x0 + width / 2:.3f}", "y": f"{y0 + 12.5:.3f}",
            "style": "font-size:8.00px;font-family:'Arial Narrow',Helvetica,Arial,sans-serif;font-weight:bold;text-anchor:middle;fill:#000000",
            "dominant-baseline": "middle",
        })
        texts = [text]
    text = texts[0]
    old_children = list(text)
    old_count = max(1, len(old_children))
    old_style = text.get("style", "")
    match = re.search(r"font-size:([0-9.]+)px", old_style)
    old_size = float(match.group(1)) if match else 8.0
    old_line_height = old_size * 1.3
    if len(old_children) >= 2 and old_children[1].get("dy"):
        old_line_height = float(old_children[1].get("dy"))
    for child in list(text):
        text.remove(child)
    text.text = None
    lines = label.split("\n") if label else []
    x = text.get("x", "0")
    y = float(text.get("y", "0"))
    center_y = y + old_line_height * (old_count - 1) / 2
    longest = max((len(line) for line in lines), default=0)
    size = 8.0 if not longest else min(8.0, max(4.25, (key_width - 5.0) / (0.62 * longest)))
    if len(lines) >= 3:
        size = min(size, 5.5)
    style = text.get("style", "")
    style = re.sub(r"font-size:[^;]+", f"font-size:{size:.2f}px", style)
    text.set("style", style)
    if not lines:
        return
    line_height = size * 1.15
    start = center_y - line_height * (len(lines) - 1) / 2
    for i, line in enumerate(lines):
        span = ET.SubElement(text, f"{{{SVG}}}tspan", {"x": x, "y": f"{start + i * line_height:.3f}"})
        span.text = line


def set_fill(group: ET.Element, color: str) -> None:
    path = group.find(f"{{{SVG}}}path")
    if path is None:
        return
    style = path.get("style", "")
    if "fill:" in style:
        style = re.sub(r"fill:[^;]+", f"fill:{color}", style)
    else:
        style = f"fill:{color};" + style
    path.set("style", style)


def without_scan_code(label: str) -> str:
    """Remove the final scan-code line from labels used in user-facing maps."""
    lines = label.split("\n")
    if lines and re.fullmatch(r"[0-9A-F]{2}(?:/[0-9A-F]{2})?", lines[-1]):
        lines.pop()
    return "\n".join(lines)


def render(filename: str, overlay: dict[str, str], active: set[str], color: str, caption: str) -> Path:
    tree = ET.parse(TEMPLATE)
    root = tree.getroot()
    root.insert(0, ET.Comment(" copyright-holders: Salvatore Paxia; generated by generate-m40-ank-maps.py "))
    for group in root.findall(f".//{{{SVG}}}g"):
        name = key_name(group)
        if name not in DIRECT:
            continue
        label = without_scan_code(overlay.get(name, DIRECT[name]))
        set_label(group, label)
        if name in UI_KEYS:
            fill = "#b4d7ff"
        elif name in active:
            fill = color
        elif name in UNASSIGNED:
            fill = "#e8e8e8"
        else:
            fill = "#ffffff"
        set_fill(group, fill)
        title = group.find(f"{{{SVG}}}title")
        if title is not None:
            title.text = f"{name}: {caption}; {label.replace(chr(10), ' / ') or 'unassigned'}"
    for text_node in root.findall(f".//{{{SVG}}}text"):
        style = text_node.get("style", "")
        if "font-family:" in style:
            text_node.set("style", re.sub(r"font-family:[^;]+", "font-family:Arial", style))
    out = HERE / filename
    tree.write(out, encoding="utf-8", xml_declaration=True)
    return out


def make_combo(outputs: list[tuple[str, Path, str]]) -> Path:
    width, panel_h, scale = 1060, 338, 1.5
    top, caption_h, gap = 70, 35, 22
    height = top + len(outputs) * (caption_h + panel_h + gap) + 20
    root = ET.Element(f"{{{SVG}}}svg", {"width": str(width), "height": str(height), "viewBox": f"0 0 {width} {height}"})
    root.append(ET.Comment(" copyright-holders: Salvatore Paxia; generated by generate-m40-ank-maps.py "))
    ET.SubElement(root, f"{{{SVG}}}rect", {"width": "100%", "height": "100%", "fill": "white"})
    title = ET.SubElement(root, f"{{{SVG}}}text", {"x": str(width/2), "y": "36", "text-anchor": "middle", "font-family": "Arial", "font-size": "24", "font-weight": "bold"})
    title.text = "M40 ANK Keyboard Mapping"
    y = top
    for caption, path, swatch in outputs:
        ET.SubElement(root, f"{{{SVG}}}rect", {"x": "22", "y": str(y+5), "width": "14", "height": "14", "fill": swatch, "stroke": "#333"})
        text = ET.SubElement(root, f"{{{SVG}}}text", {"x": "44", "y": str(y+17), "font-family": "Arial", "font-size": "15", "font-weight": "bold"})
        text.text = caption
        source = ET.parse(path).getroot()
        layer = source.find(f"{{{SVG}}}g")
        holder = ET.SubElement(root, f"{{{SVG}}}g", {"transform": f"translate(17,{y+caption_h}) scale({scale})"})
        if layer is not None:
            holder.append(copy.deepcopy(layer))
        y += caption_h + panel_h + gap
    out = HERE / "m40-ank-keyboard-mapping-combo.svg"
    ET.ElementTree(root).write(out, encoding="utf-8", xml_declaration=True)
    return out


def main() -> None:
    normal_active = {k for k, v in DIRECT.items() if v} - UI_KEYS
    direct = render("keyboard-101-m40-ank.svg", {}, normal_active, "#ffffff", "direct ANK mapping")
    shift = render("keyboard-101-m40-ank-shift.svg", SHIFT, set(SHIFT), "#b4b4ff", "Shift layer")
    alt = render("keyboard-101-m40-ank-alt.svg", ALT, set(ALT), "#a9e6a1", "host Alt layer")
    ese = render("keyboard-101-m40-ese.svg", ESE_COMMAND, set(ESE_COMMAND), "#9ed8ff", "ESE command overlay")
    keywords = render("keyboard-101-m40-ese-kbmode.svg", KEYWORDS, set(KEYWORDS), "#ffcc80", "ESE KB MODE plus Shift")
    make_combo([
        ("Direct host mapping to ANK positions", direct, "#ffffff"),
        ("Shift layer — Shift + key", shift, "#b4b4ff"),
        ("Host Alt layer — hold Alt + key", alt, "#a9e6a1"),
        ("ESE command overlay", ese, "#9ed8ff"),
        ("ESE KB MODE keyword layer — F9 toggle, then Shift + letter", keywords, "#ffcc80"),
    ])


if __name__ == "__main__":
    main()
