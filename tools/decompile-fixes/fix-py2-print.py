#!/usr/bin/env python3
"""Rewrite Python 2 ``print`` statements in decompiled Ren'Py scripts for py3 runtimes."""

from __future__ import annotations

import pathlib
import re
import sys

_PRINT_RE = re.compile(r"^(\s*)print ([^(].*)$", re.MULTILINE)


def fix_file(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    new, count = _PRINT_RE.subn(r"\1print(\2)", text)
    if count:
        path.write_text(new, encoding="utf-8")
    return count


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-py2-print.py <game-root> [...]", file=sys.stderr)
        return 2

    total_lines = 0
    touched: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if not game.is_dir():
            continue
        for path in sorted(game.rglob("*.rpy")):
            count = fix_file(path)
            if count:
                total_lines += count
                touched.append(f"{path}:{count}")

    if touched:
        print(f"  Fixed {total_lines} Python 2 print line(s) in {len(touched)} file(s)")
        for entry in touched[:12]:
            print(f"    + {entry}")
        if len(touched) > 12:
            print(f"    + ... and {len(touched) - 12} more")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
