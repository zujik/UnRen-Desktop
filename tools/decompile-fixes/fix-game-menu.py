#!/usr/bin/env python3
"""Repair IW main-menu → game-menu routing after DynamicStatement decompile loss."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER_MAIN = "# UnRen: restored game menu routing"
_MARKER_GAME = "# UnRen: restored game_menu.interact setup"

_PLAY_BLOCK = """    if _return == "play":
        $ renpy.jump_out_of_context("first_start")
"""

_MENU_BLOCK = f"""    {_MARKER_MAIN}
    if _return in ("preferences", "extra", "load"):
        $ game_menu_to_show = _return
        $ show_action_buttons = False
        call main_menu.show_background_screen (add_blur=True)
        hide screen main_menu_buttons

        call game_menu.interact (game_menu_to_show)

        $ show_action_buttons = True
        call main_menu.show_background_screen
        call main_menu.show_main_menu_screen
        with Dissolve(0.3)
"""

_GAME_MENU_INTERACT = f"""    label game_menu.interact(name):
        {_MARKER_GAME}
        $ current_game_menu = name
        with Dissolve(0.3)

        label game_menu.loop:
        if not renpy.has_label(current_game_menu):
            $ raise Exception(f"Unknown game menu: {{current_game_menu!r}}")
            return

        call expression current_game_menu

        if isinstance(_return, ShowMenu.ShowOther):
            $ current_game_menu = _return.name
            with Dissolve(0.3)
            jump game_menu.loop

        elif _return not in (True, False, None):
            $ raise Exception(f"Unknown return value: {{_return!r}} after calling {{current_game_menu!r}}")

        with Dissolve(0.3)
        return
"""


def fix_main_menu(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _MARKER_MAIN in text:
        return False
    original = text

    text = re.sub(
        r"    if _return == \"play\":\n(?:.*?\n)*?            \$ renpy\.jump_out_of_context\(\"first_start\"\)\n",
        _PLAY_BLOCK,
        text,
        count=1,
        flags=re.DOTALL,
    )

    old_menu = re.compile(
        r"    if _return in \(\"preferences\", \"extra\", \"load\"\):\n"
        r"        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.DynamicStatement\.__entities__\.data_class'>>>>\n"
        r"        \$ show_action_buttons = False\n"
        r"        call main_menu\.show_background_screen \(add_blur=True\)\n"
        r"        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.HideScreenStatement\.__entities__\.data_class'>>>>\n\n"
        r"        call game_menu\.interact \(game_menu_to_show\)\n\n"
        r"        \$ show_action_buttons = True\n"
        r"        call main_menu\.show_background_screen\n"
        r"        call main_menu\.show_main_menu_screen\n"
        r"        with Dissolve\(0\.3\)\n",
        re.MULTILINE,
    )
    text, n = old_menu.subn(_MENU_BLOCK, text, count=1)
    if n == 0:
        return False

    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def fix_game_menu_interact(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _MARKER_GAME in text:
        return False

    pattern = re.compile(
        r"    label game_menu\.interact\(name\):\n"
        r"        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.TransitionStatement\.__entities__\.data_class'>>>>\n\n"
        r"        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.DynamicStatement\.__entities__\.data_class'>>>>\n"
        r"        label game_menu\.loop:\n"
        r"        if not renpy\.has_label\(current_game_menu\):\n"
        r"            \$ raise Exception\(f\"Unknown game menu: \{current_game_menu!r\}\"\)\n"
        r"            return\n\n"
        r"        call expression current_game_menu\n\n"
        r"        if isinstance\(_return, ShowMenu\.ShowOther\):\n"
        r"            \$ current_game_menu = _return\.name\n"
        r"            pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.TransitionStatement\.__entities__\.data_class'>>>>\n"
        r"            jump game_menu\.loop\n\n"
        r"        elif _return not in \(True, False, None\):\n"
        r"            \$ raise Exception\(f\"Unknown return value: \{_return!r\} after calling \{current_game_menu!r\}\"\)\n\n"
        r"        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.TransitionStatement\.__entities__\.data_class'>>>>\n"
        r"        return\n",
        re.MULTILINE,
    )
    if not pattern.search(text):
        return False
    path.write_text(pattern.sub(_GAME_MENU_INTERACT, text, count=1), encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-game-menu.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        main_menu = game / "menus" / "main_menu.rpy"
        if main_menu.is_file() and fix_main_menu(main_menu):
            fixed.append(str(main_menu))
        game_menu = game / "menus" / "game_menu.rpy"
        if game_menu.is_file() and fix_game_menu_interact(game_menu):
            fixed.append(str(game_menu))

    if fixed:
        print(f"  Restored game menu routing in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
