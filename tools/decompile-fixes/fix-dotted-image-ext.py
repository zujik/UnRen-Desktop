#!/usr/bin/env python3
"""Fix unrpyc image paths with a spurious trailing dot (e.g. tip.png.)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

# "tip.png." inside quotes — extension dot duplicated by decompiler
_DOTTED_EXT = re.compile(
    r'("(?:images/)?[A-Za-z0-9_./ -]+\.(?:png|jpg|jpeg|webp|gif|avif))\."'
)


def fix_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8", errors="replace")
    new_text, n = _DOTTED_EXT.subn(r'\1"', text)
    if n:
        path.write_text(new_text, encoding="utf-8")
    return n


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-dotted-image-ext.py <game-dir> [...]", file=sys.stderr)
        return 2

    total = 0
    for arg in argv[1:]:
        base = Path(arg)
        if base.is_file() and base.suffix in {".rpy", ".rpym"}:
            total += fix_file(base)
            continue
        if not base.is_dir():
            continue
        for ext in ("*.rpy", "*.rpym"):
            for path in base.rglob(ext):
                total += fix_file(path)

    if total:
        print(f"fix-dotted-image-ext: repaired {total} dotted image path(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
