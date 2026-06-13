#!/usr/bin/env python3
"""Stub character memory scopes and changing menus after decompile loss."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER = "# UnRen stub: init memories blocks failed to decompile"
_STUB_NAME = "init_stub.rpy"
_LEGACY_STUB_MARKER = "SEEN_SWIMSUITS_KEYS"

_RAW_MENU_MARKER = (
    "init pass # <<<COULD NOT DECOMPILE: Unknown AST node: "
    "<class 'store.menu_structure.RawMenu.__entities__.data_class'>>>>"
)

_CHANGING_MENUS: dict[str, tuple[str, ...]] = {
    "daphne": ("daphne_changing", "daphne_changing_back"),
    "hermi": ("hermi_changing", "hermi_changing_back"),
    "luna": ("luna_changing", "luna_changing_back"),
    "susan": ("susan_changing", "susan_changing_back"),
    "ginny": ("ginny_changing", "ginny_changing_back"),
    "macgonagal": ("macgon_changing",),
    "nola": ("nola_changing",),
}

_STUB = f"""{_MARKER}

init -90 python in memories:
    def _girl_scope(include_back=False):
        scope = {{"changing_menu_state": None}}
        if include_back:
            scope["changing_menu_state_back"] = None
        return scope

    _blocks = (
        ("daphne", "Daphne", True),
        ("hermi", "Hermione", True),
        ("luna", "Luna", True),
        ("susan", "Susan", True),
        ("ginny", "Ginny", True),
        ("macgon", "McGonagall", False),
        ("nola", "Nola", False),
    )
    for block_name, caption, include_back in _blocks:
        if block_name in _inited_scopes:
            continue
        init_memories(block_name, caption, [], _girl_scope(include_back))
"""

_GIRLS_CHANGING_STUB_NAME = "init_stub.rpy"
_GIRLS_CHANGING_STUB_MARKER = "# UnRen stub: dressing-room helpers failed to decompile"
_GIRLS_CHANGING_STUB = f"""{_GIRLS_CHANGING_STUB_MARKER}

init -50 python in girls_changing:
    def open_reached_items(person):
        return

    def show_all(person):
        return

    def hide_all(person):
        return

    def hide_all_back(person):
        return

    def show_all_menus():
        return

    def hide_all_menus():
        return
"""

_GIRLS_CHANGING_MARKER = _GIRLS_CHANGING_STUB_MARKER
_GIRLS_CHANGING_OLD = """init python in girls_changing:
    def check_reached_items():"""

_GIRLS_CHANGING_NEW = f"""init python in girls_changing:
    {_GIRLS_CHANGING_MARKER}

    def open_reached_items(person):
        return

    def show_all(person):
        return

    def hide_all(person):
        return

    def hide_all_back(person):
        return

    def show_all_menus():
        return

    def hide_all_menus():
        return

    def check_reached_items():"""


def fix_girls_changing_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "girls_changing" / _GIRLS_CHANGING_STUB_NAME
    if path.is_file() and _GIRLS_CHANGING_STUB_MARKER in path.read_text(
        encoding="utf-8", errors="surrogateescape"
    ):
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_GIRLS_CHANGING_STUB + "\n", encoding="utf-8")
    return True


def fix_girls_changing_helpers(game: pathlib.Path) -> bool:
    path = game / "scripts" / "girls_changing.rpy"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _GIRLS_CHANGING_MARKER in text:
        return False
    if _GIRLS_CHANGING_OLD not in text:
        return False
    path.write_text(text.replace(_GIRLS_CHANGING_OLD, _GIRLS_CHANGING_NEW, 1), encoding="utf-8")
    return True


_DEFINE_MENU_RE = re.compile(
    r"^define girls_changing\.(\w+_menu(?:_back)?) = menu_structure\.build_menu\(",
    re.MULTILINE,
)


def fix_memories_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "memories" / _STUB_NAME
    if path.is_file():
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        if _MARKER in text and _LEGACY_STUB_MARKER not in text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_STUB + "\n", encoding="utf-8")
    return True


def fix_changing_menus(game: pathlib.Path) -> list[str]:
    fixed: list[str] = []
    for folder, menu_names in _CHANGING_MENUS.items():
        path = game / "characters" / folder / "changing.rpy"
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        if _RAW_MENU_MARKER not in text:
            continue
        count = text.count(_RAW_MENU_MARKER)
        names = list(menu_names)
        if count != len(names):
            print(
                f"  warn: {path} has {count} RawMenu stub(s), expected {len(names)}",
                file=sys.stderr,
            )
        idx = 0
        while _RAW_MENU_MARKER in text:
            if idx < len(names):
                menu_name = names[idx]
                replacement = f"menu_structure {menu_name}:\n    pass\n"
                idx += 1
            else:
                replacement = "menu_structure unren_unknown_changing_menu:\n    pass\n"
            text = text.replace(_RAW_MENU_MARKER, replacement, 1)
        path.write_text(text, encoding="utf-8")
        fixed.append(str(path))
    return fixed


def fix_girls_changing_defines(game: pathlib.Path) -> bool:
    path = game / "scripts" / "girls_changing.rpy"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if "define 2 girls_changing." in text:
        return False
    new_text, count = _DEFINE_MENU_RE.subn(
        r"define 2 girls_changing.\1 = menu_structure.build_menu(",
        text,
    )
    if count == 0:
        return False
    path.write_text(new_text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-memories-scopes.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if fix_memories_stub(game):
            fixed.append(str(game / "mechanics" / "memories" / _STUB_NAME))
        fixed.extend(fix_changing_menus(game))
        if fix_girls_changing_stub(game):
            fixed.append(str(game / "mechanics" / "girls_changing" / _GIRLS_CHANGING_STUB_NAME))
        if fix_girls_changing_helpers(game):
            fixed.append(str(game / "scripts" / "girls_changing.rpy"))
        if fix_girls_changing_defines(game):
            fixed.append(str(game / "scripts" / "girls_changing.rpy"))

    if fixed:
        print(f"  Fixed memories/changing menus in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
