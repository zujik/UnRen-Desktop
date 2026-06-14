#!/usr/bin/env python3
"""Ensure achievements module dict exists after decompile truncation."""

from __future__ import annotations

import pathlib
import re
import sys

_NEEDLE = "init -500 python in achievements:"
_INSERT = """    achievements = {}
    _state_storage = store.get_MP_value("achievements_state", {})

"""


def fix_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    changed = False

    if "_state_storage = get_MP_value(" in text:
        text = text.replace(
            '_state_storage = get_MP_value("achievements_state", {})',
            '_state_storage = store.get_MP_value("achievements_state", {})',
        )
        changed = True

    if "achievements = {}" not in text:
        idx = text.find(_NEEDLE)
        if idx < 0:
            return changed
        line_end = text.find("\n", idx)
        if line_end < 0:
            return changed
        insert_at = line_end + 1
        text = text[:insert_at] + "\n" + _INSERT + text[insert_at:]
        changed = True
    elif (
        "achievements = {}" in text
        and "_state_storage = store.get_MP_value" not in text
        and "_state_storage = get_MP_value" not in text
    ):
        idx = text.find("achievements = {}")
        line_end = text.find("\n", idx)
        insert_at = line_end + 1 if line_end >= 0 else idx + len("achievements = {}")
        text = text[:insert_at] + "    _state_storage = store.get_MP_value(\"achievements_state\", {})\n\n" + text[insert_at:]
        changed = True

    if changed:
        path.write_text(text, encoding="utf-8")
    return changed


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-achievements-init.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[pathlib.Path] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        path = game / "01early_code" / "39.rpy"
        if path.is_file() and fix_file(path):
            fixed.append(path)

    if fixed:
        print(f"  Fixed achievements init in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
