#!/usr/bin/env python3
"""Repair community_tl init after decompile drops languages_data setup."""

from __future__ import annotations

import pathlib
import sys

_MARKER = "# UnRen: community_tl languages_data init"
_NEEDLE = "init 1 python in community_tl:"


def fix_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _MARKER in text:
        return False
    if _NEEDLE not in text:
        return False

    changed = False

    if "languages_data = {}" not in text:
        text = text.replace(
            f"{_NEEDLE}\n    languages_data[\"polish\"]",
            f"{_NEEDLE}\n    languages_data = {{}}\n\n    languages_data[\"polish\"]",
            1,
        )
        if "languages_data = {}" not in text:
            text = text.replace(
                _NEEDLE,
                f"{_NEEDLE}\n    languages_data = {{}}\n",
                1,
            )
        changed = True

    if "percentage_sorted_names" not in text:
        tail = """
    for _lang_key, _lang_info in languages_data.items():
        _lang_info.setdefault("display_name", _lang_info.get("name", _lang_key))

    percentage_sorted_names = sorted(
        languages_data.keys(),
        key=lambda k: languages_data[k].get("complete", 0),
        reverse=True,
    )
"""
        decomp = "# Decompiled by unrpyc"
        if decomp in text:
            text = text.replace(decomp, tail + decomp, 1)
        else:
            text = text.rstrip() + tail + "\n"
        changed = True

    if not changed:
        return False

    if _MARKER not in text:
        text = text.replace(_NEEDLE, f"{_NEEDLE}\n    # {_MARKER.lstrip('# ')}", 1)

    path.write_text(text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-community-tl.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[pathlib.Path] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        path = game / "tl" / "community_tl.rpy"
        if path.is_file() and fix_file(path):
            fixed.append(path)

    if fixed:
        print(f"  Fixed community_tl in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
