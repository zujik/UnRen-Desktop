#!/usr/bin/env python3
"""Stub tutorial persistent settings and init after decompile loss."""

from __future__ import annotations

import pathlib
import sys

_STUB_NAME = "init_stub.rpy"
_MARKER = "# UnRen stub: tutorial menu/init failed to decompile"
_STUB = '''# UnRen stub: tutorial menu/init failed to decompile (RawMenu in main.rpy).

default persistent.tutorial_settings = get_MP_value(
    "tutorial_settings",
    [True, None, None, 0],
)

init -500 python in tutorial:
    memory_fragments = 0
    level = 0
    girl = None

    def _ensure_settings():
        settings = store.persistent.tutorial_settings
        if settings is None:
            settings = [True, None, None, 0]
            store.persistent.tutorial_settings = settings
        while len(settings) < 4:
            settings.append(None)
        if settings[3] is None:
            settings[3] = 0
        return settings

    def init(start=False):
        global memory_fragments, level
        settings = _ensure_settings()
        level = settings[3]
        if start:
            memory_fragments = 0
        level_up_changing(level)

    def level_up():
        global level
        settings = _ensure_settings()
        level = min(level + 1, 4)
        settings[3] = level
        level_up_changing(level)


label tutorial.enter:
    return


label tutorial.levels:
    return
'''

_CHANGING_OLD = """init 100 python hide in tutorial:
    level_up_changing(store.persistent.tutorial_settings[3])"""

_CHANGING_NEW = """init 100 python hide in tutorial:
    _settings = store.persistent.tutorial_settings
    if _settings is None:
        _settings = store.persistent.tutorial_settings = [True, None, None, 0]
    _level = _settings[3] if len(_settings) > 3 and _settings[3] is not None else 0
    store.tutorial.level = _level
    level_up_changing(_level)"""


def fix_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "tutorial" / _STUB_NAME
    if path.is_file():
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_STUB + "\n", encoding="utf-8")
    return True


def fix_changing(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "tutorial" / "changing.rpy"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _CHANGING_NEW.splitlines()[1] in text:
        return False
    if _CHANGING_OLD not in text:
        return False
    path.write_text(text.replace(_CHANGING_OLD, _CHANGING_NEW, 1), encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-tutorial-settings.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if fix_stub(game):
            fixed.append(str(game / "mechanics" / "tutorial" / _STUB_NAME))
        if fix_changing(game):
            fixed.append(str(game / "mechanics" / "tutorial" / "changing.rpy"))

    if fixed:
        print(f"  Fixed tutorial settings in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
