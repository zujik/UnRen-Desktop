#!/usr/bin/env python3
"""Stub IW Person definitions lost to DefinePersonStatement decompile failures."""

from __future__ import annotations

import pathlib
import sys

_MARKER = "# UnRen stub: minimal Person definitions after DefinePersonStatement decompile loss"
_STUB_NAME = "init_stub.rpy"

# var_name -> (firstname, lastname or None)
_PERSONS: dict[str, tuple[str, str | None]] = {
    "alexa": ("Alexa", None),
    "amelia": ("Amelia", None),
    "arachnela": ("Arachnela", None),
    "blaise": ("Blaise", "Zabini"),
    "bobby": ("Bobby", None),
    "boy": ("Boy", None),
    "boy_left": ("Boy", None),
    "cho": ("Cho", "Chang"),
    "creevey": ("Creevey", None),
    "crowd": ("Crowd", None),
    "daphne": ("Daphne", "Greengrass"),
    "draco": ("Draco", "Malfoy"),
    "dumbledore": ("Albus", "Dumbledore"),
    "elf_maid": ("Elf Maid", None),
    "fat_lady": ("Fat Lady", None),
    "filch": ("Filch", None),
    "fletcher": ("Fletcher", None),
    "flitwick": ("Filius", "Flitwick"),
    "forest_girl": ("Forest Girl", None),
    "ginny": ("Ginny", "Weasley"),
    "girl": ("Girl", None),
    "girl_left": ("Girl", None),
    "hagrid": ("Rubeus", "Hagrid"),
    "hannah": ("Hannah", "Abbott"),
    "harry": ("Harry", "Potter"),
    "hat": ("Sorting Hat", None),
    "helena": ("Helena", None),
    "hermi": ("Hermione", "Granger"),
    "luna": ("Luna", "Lovegood"),
    "macgonagal": ("Minerva", "McGonagall"),
    "markus": ("Markus", None),
    "mermaid": ("Mermaid", None),
    "myrtle": ("Myrtle", None),
    "new_markus": ("Markus", None),
    "nola": ("Nola", None),
    "old": ("Old Woman", None),
    "parvati": ("Parvati", "Patil"),
    "peeves": ("Peeves", None),
    "perry": ("Perry", None),
    "pince": ("Pince", None),
    "ron": ("Ron", "Weasley"),
    "sally": ("Sally", None),
    "sex": ("Partner", None),
    "snape": ("Severus", "Snape"),
    "sonya": ("Sonya", None),
    "spirit_old": ("Spirit", None),
    "susan": ("Susan", "Bones"),
    "trelawney": ("Sybill", "Trelawney"),
    "vamp": ("Vampire", None),
    "waifu": ("Waifu", None),
    "who": ("Someone", None),
    "xandria": ("Xandria", None),
    "xandria_young": ("Xandria", None),
}


def _layered_image_stub() -> str:
    names = sorted(_PERSONS)
    body_images = ",\n        ".join(repr(f"{n} body") for n in names)
    body_images = f"'empty',\n        {body_images}"

    return f"""init -1 python in layered_image:
    def _empty_container():
        return Container(
            abbrevs={{}},
            groups={{}},
            presets={{}},
            transform_area=None,
            default_transition=None,
        )

    for _name in (
        {body_images}
    ):
        if renpy.get_registered_image(_name) is None:
            renpy.image(_name, _empty_container())
"""


def _persons_stub_block() -> str:
    names = sorted(_PERSONS)
    person_lines: list[str] = []
    for var_name in names:
        first, last = _PERSONS[var_name]
        last_expr = "None" if last is None else repr(last)
        person_lines.append(
            f"""    if "{var_name}" not in inited:
        _body = "{var_name} body"
        define_person(
            "{var_name}",
            {{
                "body": IdleManager(_body),
                "head": HeadManager(_body, crop=(0, 0, 224, 224)),
            }},
            {first!r},
            {last_expr},
        )"""
        )
    return "init 100 python in persons:\n" + "\n".join(person_lines)


def _needs_person_stubs(game: pathlib.Path) -> bool:
    """Skip define_person stubs when original persons.rpyc still defines them."""
    persons_rpy = game / "persons.rpy"
    persons_rpyc = game / "persons.rpyc"
    if persons_rpyc.is_file() and not persons_rpy.is_file():
        return False
    if not persons_rpy.is_file():
        return True
    text = persons_rpy.read_text(encoding="utf-8", errors="surrogateescape")
    if "COULD NOT DECOMPILE" in text:
        return True
    return "define person" not in text and "define_person" not in text


def _stub_text(game: pathlib.Path) -> str:
    blocks = [_MARKER, "", _layered_image_stub().rstrip()]
    if _needs_person_stubs(game):
        blocks.append("")
        blocks.append(_persons_stub_block().rstrip())
    return "\n".join(blocks) + "\n"


def write_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "persons" / _STUB_NAME
    new_text = _stub_text(game)
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == new_text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(new_text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-characters.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if write_stub(game):
            fixed.append(str(game / "mechanics" / "persons" / _STUB_NAME))

    if fixed:
        print(f"  Stubbed Person definitions in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
