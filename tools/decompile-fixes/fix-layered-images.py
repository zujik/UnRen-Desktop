#!/usr/bin/env python3
"""Register empty layered images for LayeredManager defaults after decompile loss."""

from __future__ import annotations

import pathlib
import re
import sys

_MARKER = "# UnRen stub: empty layered images for failed LayeredImageStatement decompile"
_STUB_NAME = "init_stub.rpy"
_LAYERED_MANAGER_RE = re.compile(r'LayeredManager\(\s*["\']([^"\']+)["\']')
_LAYERED_FAIL_RE = re.compile(
    r"LayeredImageStatement\.__entities__\.data_class"
)


def collect_names(game: pathlib.Path) -> list[str]:
    names: set[str] = set()
    for path in game.rglob("*.rpy"):
        text = path.read_text(encoding="utf-8", errors="surrogateescape")
        names.update(_LAYERED_MANAGER_RE.findall(text))
    return sorted(names)


def stub_text(names: list[str]) -> str:
    quoted = ",\n        ".join(repr(name) for name in names)
    return f"""{_MARKER}

init -1 python in layered_image:
    def _empty_container():
        return Container(
            abbrevs={{}},
            groups={{}},
            presets={{}},
            transform_area=None,
            default_transition=None,
        )

    for _name in (
        {quoted}
    ):
        if renpy.get_registered_image(_name) is None:
            renpy.image(_name, _empty_container())
"""


def fix_layered_stub(game: pathlib.Path) -> bool:
    path = game / "mechanics" / "layered_image" / _STUB_NAME
    names = collect_names(game)
    if not names:
        return False
    new_text = stub_text(names) + "\n"
    if path.is_file():
        old = path.read_text(encoding="utf-8", errors="surrogateescape")
        if old == new_text:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(new_text, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-layered-images.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        if fix_layered_stub(game):
            fixed.append(str(game / "mechanics" / "layered_image" / _STUB_NAME))

    if fixed:
        print(f"  Registered empty layered images in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
