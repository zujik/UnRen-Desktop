#!/usr/bin/env python3
"""Scan/fix .rpy and .rpym files truncated with an empty trailing block."""

from __future__ import annotations

import pathlib
import re
import sys

_BLOCK_HEADS = (
    "at transform",
    "image ",
    "transform ",
    "layeredimage ",
    "style ",
    "label ",
    "init",
    "python",
    "fixed",
    "frame",
    "vbox",
    "hbox",
    "imagebutton",
    "imagetextbutton",
    "coloredtextbutton",
    "textbutton",
    "button",
    "timer",
    "add ",
    "text ",
    "viewport",
    "grid",
    "side",
    "drag",
    "draggroup",
    "mousearea",
    "window",
    "bar",
    "input",
    "key",
    "hotspot",
    "hotbar",
    "show ",
    "scene ",
    "screen ",
    "menu",
    "elif ",
    "else",
    "define ",
    "default ",
    "hide ",
    "with ",
    "camera",
    "voice ",
    "play ",
    "queue ",
    "stop ",
    "pause ",
)

_TAIL_LINE = re.compile(r"^(?P<indent>\s*)(?P<body>.+?):\s*$")


def _needs_pass(line: str) -> re.Match[str] | None:
    match = _TAIL_LINE.match(line)
    if not match:
        return None
    body = match.group("body").strip()
    if not body or body.startswith("#"):
        return None
    if body.startswith("image live2d"):
        return None
    # Dialogue / strings:  e "Hello":  or  "Hello":
    if body.endswith(('"', "'")):
        return None
    for head in _BLOCK_HEADS:
        if body == head.rstrip() or body.startswith(head):
            return match
    return None


def scan_file(path: pathlib.Path) -> str | None:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    stripped = text.rstrip("\n")
    if not stripped:
        return None
    last = stripped.splitlines()[-1]
    match = _needs_pass(last)
    if match:
        return last.strip()
    return None


def fix_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    stripped = text.rstrip("\n")
    if not stripped:
        return False
    last = stripped.splitlines()[-1]
    match = _needs_pass(last)
    if not match:
        return False
    indent = f"{match.group('indent')}    "
    path.write_text(f"{stripped}\n{indent}pass\n", encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-atl-tails.py [--scan] <game-root> [...]", file=sys.stderr)
        return 2

    args = argv[1:]
    scan_only = False
    if args[0] == "--scan":
        scan_only = True
        args = args[1:]

    hits: list[tuple[pathlib.Path, str]] = []
    fixed: list[pathlib.Path] = []

    for root in args:
        game = pathlib.Path(root)
        if not game.is_dir():
            continue
        for ext in ("*.rpy", "*.rpym"):
            for path in sorted(game.rglob(ext)):
                tail = scan_file(path)
                if tail:
                    hits.append((path, tail))
                if not scan_only and fix_file(path):
                    fixed.append(path)

    if scan_only:
        print(f"  {len(hits)} file(s) with empty trailing blocks")
        for path, tail in hits[:30]:
            print(f"    {path}: {tail}")
        if len(hits) > 30:
            print(f"    ... and {len(hits) - 30} more")
        return 0

    if fixed:
        print(f"  Fixed {len(fixed)} file(s) with empty trailing blocks")
        for path in fixed[:12]:
            print(f"    + {path}")
        if len(fixed) > 12:
            print(f"    + ... and {len(fixed) - 12} more")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
