#!/usr/bin/env python3
"""Stub Sonya person store when unrpyc leaves StoreStatement as pass."""

from __future__ import annotations

import pathlib
import re
import sys

_STORES_MARKER = '_inited_stores["sonya"]'
_STORES_STUB_MARKER = "# UnRen stub: person store sonya failed to decompile"

_STORES_APPEND = """
    # UnRen stub: person store sonya failed to decompile (StoreStatement).
    class _RegisteredStore(object):
        def __init__(self, store_name, items, presets):
            self.store_name = store_name
            self._items = items
            self._presets = presets

        def build(self):
            rv = Store(self.store_name)
            rv.items.update(self._items)
            rv.presets.update(self._presets)
            return rv

    def _mk_sonya_item(layer, style, group, cost=0, level=0):
        return Item(style, cost, level, None, group, {layer: style}, False)

    _sonya_items = {}
    for _layer, _style, _group in (
        ("facewear_glasses", "explorer_glasses", "facewear"),
        ("top_panties", "common_blue", "top"),
        ("top", "explorer", "top"),
        ("bottom_panties", "common_blue", "bottom"),
        ("bottom", "explorer", "bottom"),
        ("headwear", "default", "headwear"),
        ("stockings", "default", "stockings"),
    ):
        _sonya_items[(_layer, _style)] = _mk_sonya_item(_layer, _style, _group)

    _sonya_presets = {
        "explorer": Preset(
            "Explorer",
            0,
            0,
            None,
            {
                "facewear_glasses": ["explorer_glasses"],
                "top_panties": ["common_blue"],
                "top": ["explorer"],
                "bottom_panties": ["common_blue"],
                "bottom": ["explorer"],
            },
            False,
        ),
        "bondage_costume": Preset(
            "Bondage costume",
            0,
            99,
            None,
            {},
            True,
        ),
    }

    _inited_stores["sonya"] = _RegisteredStore("sonya", _sonya_items, _sonya_presets)
"""

_SONYA_STORE_RPY = """# UnRen: `person store sonya` failed to decompile. Sonya wardrobe stub lives in
# game/mechanics/persons/stores.rpy (search for _inited_stores["sonya"]).
"""


def fix_stores(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if _STORES_MARKER in text:
        return False
    if "init -998 python in persons.stores:" not in text:
        return False
    marker = "# Decompiled by unrpyc"
    idx = text.rfind(marker)
    if idx < 0:
        return False
    path.write_text(text[:idx] + _STORES_APPEND + "\n" + text[idx:], encoding="utf-8")
    return True


def fix_sonya_store_rpy(path: pathlib.Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    if text.strip() == _SONYA_STORE_RPY.strip():
        return False
    if "StoreStatement" not in text and _STORES_STUB_MARKER not in text and "init -997" not in text:
        return False
    path.write_text(_SONYA_STORE_RPY + "\n", encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: fix-sonya-store.py <game-root> [...]", file=sys.stderr)
        return 2

    fixed: list[str] = []
    for root in argv[1:]:
        game = pathlib.Path(root)
        stores = game / "mechanics" / "persons" / "stores.rpy"
        sonya = game / "characters" / "sonya" / "store.rpy"
        if stores.is_file() and fix_stores(stores):
            fixed.append(str(stores))
        if fix_sonya_store_rpy(sonya):
            fixed.append(str(sonya))

    if fixed:
        print(f"  Fixed Sonya store in {len(fixed)} file(s)")
        for path in fixed:
            print(f"    + {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
