#!/usr/bin/env python3
"""Stub store.start_anim / store.bottom_anim for spell_cast minigame."""

from __future__ import annotations

import pathlib
import sys

_MARKER = "# UnRen stub: store.start_anim / store.bottom_anim"
_PATH_LINE = '_ASSETS_PATH = "minigames/spell_cast/images"'

_INJECT = '''
    # UnRen stub: store.start_anim / store.bottom_anim (custom image statements failed to decompile).
    def _spell_animation_paths(base_path):
        frames = []
        for i in range(1, 512):
            hit = None
            for pat in (
                f"{base_path}/{i:04d}.webp",
                f"{base_path}/{i:04d}.png",
                f"{base_path}/{i}.webp",
                f"{base_path}/{i}.png",
            ):
                if renpy.loader.loadable(pat):
                    hit = pat
                    break
            if hit is None:
                break
            frames.append(hit)
        if not frames:
            for pat in (f"{base_path}.webp", f"{base_path}.png"):
                if renpy.loader.loadable(pat):
                    return [pat]
        return frames

    def _spell_anim_factory(base_path):
        for suffix in ("", "/bottom", "/bottom_anim"):
            frames = _spell_animation_paths(base_path + suffix)
            if frames:
                child = renpy.displayable(frames[0])
                if len(frames) > 1:
                    try:
                        child = renpy.displayable(
                            renpy.display.animation.Animation(
                                *frames,
                                delay=1.0 / 24.0,
                                loop=True,
                            )
                        )
                    except Exception:
                        pass
                return store.Transform(child)
        return store.Transform(store.Null())

    if not hasattr(store, "start_anim"):
        store.start_anim = _spell_anim_factory
    if not hasattr(store, "bottom_anim"):
        store.bottom_anim = _spell_anim_factory

'''


def fix_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _MARKER in text:
        return False
    idx = text.find(_PATH_LINE)
    if idx < 0:
        return False
    line_end = text.find("\n", idx)
    if line_end < 0:
        return False
    insert_at = line_end + 1
    path.write_text(text[:insert_at] + _INJECT + text[insert_at:], encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-spell-cast-anims.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[pathlib.Path] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        path = game / "minigames" / "spell_cast" / "pycode.rpy"
        if path.is_file() and fix_file(path):
            fixed.append(path)

    if fixed:
        print(f"  Fixed spell_cast anims in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
