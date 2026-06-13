#!/usr/bin/env python3
"""Append pass to .rpy files truncated with an empty trailing block."""

from __future__ import annotations

import pathlib
import re
import sys

# Block headers unrpyc often leaves empty at EOF (Ren'Py requires a body).
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
    "menu",
    "elif ",
    "else",
)

_TAIL_LINE = re.compile(r"^(?P<indent>\s*)(?P<body>.+?):\s*$")


def _needs_pass(line: str) -> re.Match[str] | None:
    match = _TAIL_LINE.match(line)
    if not match:
        return None
    body = match.group("body").strip()
    if not body or body.startswith("#"):
        return None
    if body.endswith(('"', "'")) or body.endswith(")"):
        return None
    for head in _BLOCK_HEADS:
        if body == head.rstrip() or body.startswith(head):
            return match
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
        print("usage: fix-atl-tails.py <game-root> [<game-root> ...]", file=sys.stderr)
        return 2

    fixed: list[pathlib.Path] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if not game.is_dir():
            continue
        for path in sorted(game.rglob("*.rpy")):
            if fix_file(path):
                fixed.append(path)

    if fixed:
        print(f"  Fixed {len(fixed)} file(s) with empty trailing blocks")
        for path in fixed[:8]:
            print(f"    + {path}")
        if len(fixed) > 8:
            print(f"    + ... and {len(fixed) - 8} more")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
