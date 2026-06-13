#!/usr/bin/env python3
"""Stub transforms and screens lost to failed ATL/screen decompile."""

from __future__ import annotations

import pathlib
import re
import sys

_SCREEN_DEF_RE = re.compile(r"^\s*screen\s+([a-zA-Z_][a-zA-Z0-9_]*)", re.M)
_SCREEN_USE_RE = re.compile(
    r"^\s*use\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(\([^)]*\))?",
    re.M,
)

_SCREEN_SIGNATURES: dict[str, str] = {
    "advanced_right_page": "",
    "cabinet_bg": "",
    "cabinet_hall_bg": "",
    "divination_classroom_bg": "",
    "dorms_bg": "current_room=None",
    "dorms_corridor_bg": "current_room=None",
    "entrance_bg": "",
    "goals_right_page": "",
    "left_page": "titles=(), viewport=False",
    "left_page_old_plot": "viewport=False",
    "memories_left_page": "memories_type=None",
    "memories_right_page": "memories_type=None",
    "navigation": "main_menu=False, use_left_tabs=False, use_numbers=False",
    "notes_left_page": "",
    "notes_right_page": "",
    "right_page": "titles=(), viewport=False",
    "right_page_old_plot": "viewport=False",
    "scheduler": "current_schedule=None",
    "screenshot_slots": "slot=1, adjustment=None",
    "stats_left_page": "",
    "tutorial_top_tabs": "names=None, text_size=25",
    "walkthrough_button": "",
}

_SCREENS_MARKER = "# UnRen stub: empty screens for failed screen decompile"

_MASK_MARKER = "# UnRen stub: puzzle_15_mask_wipe_l2d transform"
_MASK_STUB = f"""{_MASK_MARKER}
transform puzzle_15_mask_wipe_l2d:
    pass
"""

_QUICK_MARKER = "# UnRen stub: quick_buttons screen"
_QUICK_STUB = f"""{_QUICK_MARKER}
screen quick_buttons():
    zorder 50
    if False:
        text ""
"""

_DIARY_MARKER = "# UnRen stub: girl diary screens/transforms lost to decompile"
_DIARY_STUB = f"""{_DIARY_MARKER}

screen girl_diary_background(girl):
    frame:
        xfill True
        yfill True

screen girl_diary_input:
    pass

transform girls_diary_text_transform:
    pass

transform girls_diary_image_transform:
    pass
"""

_CHOICE_MARKER = "# UnRen stub: choice screen for display_menu"
_CHOICE_STUB = f"""{_CHOICE_MARKER}

screen choice(items):
    modal True
    zorder 100
    vbox:
        xalign 0.5
        yalign 0.5
        spacing 15
        for i in items:
            textbutton i.caption:
                action i.action
                sensitive i.sensitive
"""


def fix_choice_screen(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "screens" / "choice_stub.rpy"
    if path.is_file():
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        if _CHOICE_MARKER in text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_CHOICE_STUB + "\n", encoding="utf-8")
    return True


def fix_diary_stubs(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "diary" / "init_stub.rpy"
    if path.is_file():
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        if _DIARY_MARKER in text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_DIARY_STUB + "\n", encoding="utf-8")
    return True


def collect_missing_screens(game: pathlib.Path) -> list[str]:
    defined: set[str] = set()
    used: set[str] = set()
    for path in game.rglob("*.rpy"):
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        defined.update(_SCREEN_DEF_RE.findall(text))
        for match in _SCREEN_USE_RE.finditer(text):
            name = match.group(1)
            if name != "expression":
                used.add(name)
    return sorted(used - defined)


def screen_stub_block(name: str, signature: str) -> str:
    if signature:
        header = f"screen {name}({signature}):"
    else:
        header = f"screen {name}:"
    body = "    frame:\n        xfill True\n        yfill True"
    if name.endswith("_bg") or name == "walkthrough_button":
        body = "    pass"
    return f"{header}\n{body}"


def screens_stub_text(names: list[str]) -> str:
    blocks: list[str] = []
    for name in names:
        signature = _SCREEN_SIGNATURES.get(name, "")
        blocks.append(screen_stub_block(name, signature))
    return _SCREENS_MARKER + "\n\n" + "\n\n".join(blocks) + "\n"


def fix_missing_screens(game: pathlib.Path) -> tuple[bool, int]:
    names = collect_missing_screens(game)
    if not names:
        return False, 0
    unknown = [name for name in names if name not in _SCREEN_SIGNATURES]
    if unknown:
        print(
            f"  warn: stubbing {len(unknown)} screen(s) with default signatures: "
            + ", ".join(unknown),
            file=sys.stderr,
        )
    path = game / "mechanics" / "screens" / "init_stub.rpy"
    new_text = screens_stub_text(names)
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == new_text:
            return False, 0
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(new_text, encoding="utf-8")
    return True, len(names)


def fix_mask_transform(game: pathlib.Path) -> bool:
    path = game / "minigames" / "puzzle15" / "code.rpy"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if "puzzle_15_mask_wipe_l2d" in text:
        return False
    anchor = "transform puzzle_15_mask_common_transform():"
    idx = text.find(anchor)
    if idx < 0:
        return False
    line_end = text.find("\n", idx)
    if line_end < 0:
        return False
    insert_at = text.find("\n", line_end + 1)
    if insert_at < 0:
        insert_at = len(text)
    else:
        insert_at += 1
    path.write_text(text[:insert_at] + "\n" + _MASK_STUB + text[insert_at:], encoding="utf-8")
    return True


def fix_quick_buttons(game: pathlib.Path) -> bool:
    path = game / "scripts" / "quick_buttons.rpy"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _QUICK_MARKER in text or "screen quick_buttons" in text:
        return False
    path.write_text(text.rstrip() + "\n\n" + _QUICK_STUB + "\n", encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-iw-runtime-stubs.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if fix_mask_transform(game):
            fixed.append(str(game / "minigames" / "puzzle15" / "code.rpy"))
        if fix_quick_buttons(game):
            fixed.append(str(game / "scripts" / "quick_buttons.rpy"))
        if fix_diary_stubs(game):
            fixed.append(str(game / "mechanics" / "diary" / "init_stub.rpy"))
        if fix_choice_screen(game):
            fixed.append(str(game / "mechanics" / "screens" / "choice_stub.rpy"))
        changed, count = fix_missing_screens(game)
        if changed:
            fixed.append(
                f"{game / 'mechanics' / 'screens' / 'init_stub.rpy'} ({count} screens)"
            )

    if fixed:
        print(f"  Added runtime stubs in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
