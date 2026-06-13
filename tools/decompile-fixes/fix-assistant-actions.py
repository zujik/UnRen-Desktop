#!/usr/bin/env python3
"""Repair IW layout yes/no prompts after ShowScreen decompile failures."""

from __future__ import annotations

import pathlib
import sys

_MARKER = "# UnRen stub: yes/no prompt screen after decompile loss"
_STUB_NAME = "init_stub.rpy"

_YESNO_SCREEN = """label _yesno_screen(message, tagged=False, **kwargs):
    if config.enter_yesno_transition:
        $ renpy.transition(config.enter_yesno_transition)
    $ _return = renpy.call_screen("yesno_prompt", message=message, tagged=tagged)
    $ renpy.with_statement(config.exit_yesno_transition)
    return _return
"""

_PROMPT_SCREEN = """label _prompt_screen(message):
    if config.enter_yesno_transition:
        $ renpy.transition(config.enter_yesno_transition)
    $ _return = renpy.call_screen("prompt", message=message)
    $ renpy.with_statement(config.exit_yesno_transition)
    return None
"""

_STUB = f"""{_MARKER}

screen yesno_prompt(message, yes_action=Return(True), no_action=Return(False), tagged=False):
    modal True
    zorder 200
    add Solid("#000a")
    frame:
        align (0.5, 0.5)
        xpadding 40
        ypadding 30
        background Solid("#222c")
        vbox:
            spacing 24
            if tagged:
                text "[message!ti]" xalign 0.5 text_align 0.5
            else:
                text message xalign 0.5 text_align 0.5
            hbox:
                xalign 0.5
                spacing 30
                textbutton _("Yes") action yes_action
                textbutton _("No") action no_action

screen prompt(message):
    modal True
    zorder 200
    add Solid("#000a")
    frame:
        align (0.5, 0.5)
        xpadding 40
        ypadding 30
        background Solid("#222c")
        vbox:
            spacing 24
            text message xalign 0.5 text_align 0.5
            textbutton _("OK") action Return(True) xalign 0.5
"""


def _replace_label_block(text: str, label: str, replacement: str) -> str:
    start = text.find(label)
    if start < 0:
        return text
    end = text.find("\nlabel ", start + 1)
    if end < 0:
        end = text.find("\ninit python", start + 1)
    if end < 0:
        return text
    return text[:start] + replacement + text[end:]


def fix_assistant_actions(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if "# UnRen: restored yesno/prompt screens" in text:
        return False
    original = text
    text = _replace_label_block(text, "label _prompt_screen(message):", _PROMPT_SCREEN)
    text = _replace_label_block(text, "label _yesno_screen(message, tagged=False, **kwargs):", _YESNO_SCREEN)
    if text == original:
        return False
    text = text.replace(
        "label _prompt_screen(message):",
        "# UnRen: restored yesno/prompt screens\nlabel _prompt_screen(message):",
        1,
    )
    path.write_text(text, encoding="utf-8")
    return True


def write_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "yesno" / _STUB_NAME
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == _STUB:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_STUB, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-assistant-actions.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if write_stub(game):
            fixed.append(str(game / "mechanics" / "yesno" / _STUB_NAME))
        actions = game / "IWscripts" / "AssistantActions.rpy"
        if actions.is_file() and fix_assistant_actions(actions):
            fixed.append(str(actions))

    if fixed:
        print(f"  Restored yes/no prompts in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
