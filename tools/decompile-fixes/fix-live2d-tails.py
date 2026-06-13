#!/usr/bin/env python3
"""Remove dangling empty Live2D image blocks left by decompile."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER = "# UnRen: removed dangling empty Live2D image block"
_DANGLING_IMAGE = re.compile(
    r"\nimage live2d [^\n]+:\s*(?:\n\s*pass\s*)?$",
)


def fix_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if "image live2d" not in text:
        return False
    new = _DANGLING_IMAGE.sub("", text.rstrip("\n"))
    if new == text.rstrip("\n"):
        return False
    path.write_text(new.rstrip() + "\n", encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-live2d-tails.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[pathlib.Path] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        live2d = game / "Live2D"
        if not live2d.is_dir():
            continue
        for path in sorted(live2d.rglob("*.rpym")):
            if fix_file(path):
                fixed.append(path)

    if fixed:
        print(f"  Removed dangling Live2D image blocks in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
