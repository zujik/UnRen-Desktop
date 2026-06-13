#!/usr/bin/env python3
"""Register empty menu_structure blocks for all referenced menu names."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER = "# UnRen stub: empty menu_structure blocks for failed RawMenu decompile"
_STUB_NAME = "init_stub.rpy"
_BUILD_MENU_RE = re.compile(r'build_menu\(\s*["\']([^"\']+)["\']')
_MENU_RE = re.compile(r'(?<!Show)(?:menu_structure\.)?Menu\(\s*["\']([^"\']+)["\']')


def collect_names(game: pathlib.Path) -> list[str]:
    names: set[str] = set()
    for path in game.rglob("*.rpy"):
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        names.update(_BUILD_MENU_RE.findall(text))
        names.update(_MENU_RE.findall(text))
    return sorted(names)


def stub_text(names: list[str]) -> str:
    blocks = "\n\n".join(
        f"menu_structure {name}:\n    pass" for name in names
    )
    return f"{_MARKER}\n\n{blocks}\n"


def fix_menu_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "menu_structure" / _STUB_NAME
    names = collect_names(game)
    if not names:
        return False
    new_text = stub_text(names)
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == new_text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(new_text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-missing-menus.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if fix_menu_stub(game):
            names = collect_names(game)
            fixed.append(
                f"{game / 'mechanics' / 'menu_structure' / _STUB_NAME} ({len(names)} menus)"
            )

    if fixed:
        print(f"  Registered empty menus in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
