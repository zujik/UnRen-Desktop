#!/usr/bin/env python3
"""Restore main menu / splashscreen screens lost to ShowScreen decompile failures."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER = "# UnRen stub: rebuilt main menu screens after ShowScreen decompile loss"
_STUB_NAME = "main_menu_stub.rpy"

_SHOW_BG = """    label main_menu.show_background_screen(*, add_blur=False):
        show screen main_menu_background
        if show_action_buttons:
            show screen main_menu_action_buttons
        else:
            hide screen main_menu_action_buttons
        return
"""

_HIDE_BG = """    label main_menu.hide_background_screen:
        hide screen main_menu_background
        return
"""

_SHOW_MENU = """    label main_menu.show_main_menu_screen:
        show screen main_menu_buttons
        return
"""

_MAIN_MENU_INIT = """    $ show_action_buttons = True
    $ main_menu = True
    if not renpy.music.get_playing(channel="music"):
        $ renpy.music.play(main_menu_state.music, fadeout=0.5, fadein=1.0)

"""

_STUB = f"""{_MARKER}

default show_action_buttons = True

init 2 python:
    if not hasattr(store, "mm_daphne_parallax_manager"):
        store.mm_daphne_parallax_manager = ParallaxManager()

screen main_menu_background():
    tag main_menu_bg
    zorder 0
    add "gui/title/title.png":
        xalign 0.5
        yalign 0.5

screen main_menu_corridor_liv():
    use main_menu_background

screen main_menu_slytherin_liv():
    use main_menu_background

screen main_menu_gryffindor_liv():
    use main_menu_background

screen main_menu_ravenclaw_liv():
    use main_menu_background

screen main_menu_hufflepuff_liv():
    use main_menu_background

screen main_menu_corridor_l2d():
    use main_menu_background

screen main_menu_slytherin_l2d():
    use main_menu_background

screen main_menu_gryffindor_l2d():
    use main_menu_background

screen main_menu_ravenclaw_l2d():
    use main_menu_background

screen main_menu_hufflepuff_l2d():
    use main_menu_background

screen main_menu_buttons():
    zorder 100
    modal False
    fixed:
        align (0.98, 0.92)
        vbox:
            spacing 8
            imagebutton:
                idle "gui/title/play_button_idle.png"
                hover "gui/title/play_button_hover.png"
                focus_mask "gui/title/play_button_focus_mask.png"
                action Return("play")
            imagebutton:
                idle "gui/title/continue_button_big_idle.png"
                hover "gui/title/continue_button_big_hover.png"
                focus_mask "gui/title/continue_button_big_focus_mask.png"
                action Return("load")
            imagebutton:
                idle "gui/title/preferences_button_big_idle.png"
                hover "gui/title/preferences_button_big_hover.png"
                focus_mask "gui/title/preferences_button_big_focus_mask.png"
                action Return("preferences")
            imagebutton:
                idle "gui/title/extra_button_idle.png"
                hover "gui/title/extra_button_hover.png"
                focus_mask "gui/title/extra_button_focus_mask.png"
                action Return("extra")
            imagebutton:
                idle "gui/title/exit_button_big_idle.png"
                hover "gui/title/exit_button_big_hover.png"
                focus_mask "gui/title/exit_button_big_focus_mask.png"
                action Quit(confirm=False)

screen main_menu_action_buttons():
    zorder 90
    hbox:
        align (0.5, 0.98)
        spacing 12
        for _house in ("corridor", "gryffindor", "slytherin", "ravenclaw", "hufflepuff"):
            textbutton _house.title():
                action Return(("change_background", _house))
                sensitive main_menu_state.current != _house
"""

_SPLASH_FIX = """    if not persistent.accepted_language:
        $ persistent.accepted_language = True
        $ save_persistent()

    if not persistent.accepted_terms:
        $ _return = True
        $ persistent.accepted_terms = True
"""

_SPLASH_RPYC_MARKER = "# UnRen stub: auto-accept splashscreen gates (rpyc play path)"
_SPLASH_RPYC_STUB = f"""{_SPLASH_RPYC_MARKER}

label splashscreen:
    if not persistent.accepted_language:
        $ persistent.accepted_language = True
        $ save_persistent()

    if not persistent.accepted_terms:
        $ persistent.accepted_terms = True
        $ save_persistent()

    return
"""

_DECOMPILE = re.compile(
    r"pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store\.(\w+)\.__entities__\.data_class'>>>>"
)


def _replace_label_block(text: str, label: str, replacement: str) -> str:
    pattern = re.compile(
        rf"(    {re.escape(label)}.*?)(?=\n    label |\ndefault persistent\.main_menu_state)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        return text
    return text[: match.start(1)] + replacement + text[match.end(1) :]


def _fix_sublabel_indent(text: str) -> tuple[str, bool]:
    anchor = "    jump main_menu.loop\n\n"
    idx = text.find(anchor)
    if idx < 0:
        return text, False
    start = idx + len(anchor)
    end = text.find("\ndefault persistent.main_menu_state", start)
    if end < 0:
        return text, False
    block = text[start:end]
    if "        label main_menu." not in block:
        return text, False
    fixed_lines: list[str] = []
    for line in block.split("\n"):
        if line.startswith("        label main_menu."):
            fixed_lines.append(line[4:])
        elif line.startswith("        ") and fixed_lines:
            fixed_lines.append(line)
        elif line.startswith("    ") and not line.startswith("        "):
            fixed_lines.append("    " + line[4:])
        else:
            fixed_lines.append(line)
    fixed = "\n".join(fixed_lines)
    if fixed == block:
        return text, False
    return text[:start] + fixed + text[end:], True


def fix_main_menu_rpy(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    changed = False

    text, indent_fixed = _fix_sublabel_indent(text)
    changed = changed or indent_fixed

    original = text
    text = _replace_label_block(text, "label main_menu.show_background_screen", _SHOW_BG)
    text = _replace_label_block(text, "label main_menu.hide_background_screen", _HIDE_BG)

    already_marked = "# UnRen: restored main menu ShowScreen calls" in text
    if not already_marked:
        text = _replace_label_block(text, "label main_menu.show_main_menu_screen", _SHOW_MENU)
        text = text.replace(
            "    pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.DynamicStatement.__entities__.data_class'>>>>\n"
            "    pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.DynamicStatement.__entities__.data_class'>>>>\n"
            "    pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.DynamicStatement.__entities__.data_class'>>>>\n",
            _MAIN_MENU_INIT,
            1,
        )
        marker = "# UnRen: restored main menu ShowScreen calls\n"
        if marker not in text:
            text = text.replace("label main_menu:\n", f"label main_menu:\n{marker}", 1)

    if text == original and not changed:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def fix_splashscreen(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if "# UnRen: auto-accept splashscreen gates" in text:
        return False
    old = """    if not persistent.accepted_language:
        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.TransitionStatement.__entities__.data_class'>>>>
        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.CallScreenStatement.__entities__.data_class'>>>>
        $ persistent.accepted_language = True
        $ save_persistent()

    if not persistent.accepted_terms:
        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.TransitionStatement.__entities__.data_class'>>>>
        pass # <<<COULD NOT DECOMPILE: Unknown AST node: <class 'store.CallScreenStatement.__entities__.data_class'>>>>
        if not _return:
            $ renpy.quit()
        with Dissolve(0.5)
        $ persistent.accepted_terms = True"""
    if old not in text:
        return False
    new = "# UnRen: auto-accept splashscreen gates\n" + _SPLASH_FIX
    path.write_text(text.replace(old, new), encoding="utf-8")
    return True


def write_stub(game: pathlib.Path) -> bool:
    path = game / "menus" / _STUB_NAME
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == _STUB:
            return False
    path.write_text(_STUB, encoding="utf-8")
    return True


def write_splash_rpyc_override(game: pathlib.Path) -> bool:
    """Shadow splashscreen.rpyc when language/terms gates block rpyc-only play."""
    splash_rpy = game / "menus" / "splashscreen.rpy"
    splash_rpyc = game / "menus" / "splashscreen.rpyc"
    if splash_rpy.is_file() or not splash_rpyc.is_file():
        return False
    new_text = _SPLASH_RPYC_STUB + "\n"
    splash_rpy.write_text(new_text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-main-menu.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if write_stub(game):
            fixed.append(str(game / "menus" / _STUB_NAME))
        main_menu = game / "menus" / "main_menu.rpy"
        if main_menu.is_file() and fix_main_menu_rpy(main_menu):
            fixed.append(str(main_menu))
        splash = game / "menus" / "splashscreen.rpy"
        if splash.is_file() and fix_splashscreen(splash):
            fixed.append(str(splash))
        if write_splash_rpyc_override(game):
            fixed.append(str(game / "menus" / "splashscreen.rpy"))

    if fixed:
        print(f"  Restored main menu in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
