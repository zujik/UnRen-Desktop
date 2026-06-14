#!/usr/bin/env python3
"""Fix unrpyc screen-language keywords that were replaced with style names."""

from __future__ import annotations

import pathlib
import re
import sys

# register_sl_displayable("keyword", ..., "style_name") — unrpyc often emits style_name.
_SL_KEYWORD_FIXES = (
    (re.compile(r"^(\s*)imagetext_button(\s+)(?=[\"'\[_])"), r"\1imagetextbutton\2"),
    (re.compile(r"^(\s*)commonbutton_button(\s+)(?=[\"'\[_])"), r"\1coloredtextbutton\2"),
)


def fix_file(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    lines = text.splitlines(keepends=True)
    changed = 0
    out: list[str] = []
    for line in lines:
        new_line = line
        for pattern, repl in _SL_KEYWORD_FIXES:
            new_line = pattern.sub(repl, new_line)
        if new_line != line:
            changed += 1
        out.append(new_line)
    if changed:
        path.write_text("".join(out), encoding="utf-8")
    return changed


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-sl-keywords.py <game-root> [<game-root> ...]", file=sys.stderr)
        return 2

    files = 0
    lines = 0
    for root in argv[1:]:
        game = pathlib.Path(root)
        if not game.is_dir():
            continue
        for path in sorted(game.rglob("*.rpy")):
            n = fix_file(path)
            if n:
                files += 1
                lines += n

    if files:
        print(f"  Fixed {lines} screen-language line(s) in {files} file(s) (imagetextbutton / coloredtextbutton)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
