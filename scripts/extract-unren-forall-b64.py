#!/usr/bin/env python3
"""Extract base64-embedded Python tools from UnRen-forall .bat files.

Lurmel's distribution embeds detect_rpa_ext.py, altrpatool.py, etc. inside
UnRen-current.bat / UnRen-legacy.bat — there are no loose upstream .py files in
the zip. Use this for UnRen-Dependencies mirror staging only (not UnRen-Desktop).
"""

from __future__ import annotations

import argparse
import base64
import re
import sys
from pathlib import Path

# Scripts we mirror as decoded upstream (rpatool comes from codeberg separately).
DEFAULT_NAMES = (
    "detect_renpy_version",
    "detect_rpa_ext",
    "detect_archive",
    "detect_rpyc_version",
    "wos_decrypt_all",
    "altrpatool",
)


def _collect_b64_blocks(text: str, stem: str) -> list[str]:
    """Return ordered base64 payload strings for >\"%stem%.b64\" ( blocks."""
    pattern = re.compile(
        rf'>\s*"%{re.escape(stem)}%\.b64"\s*\((.*?)\)',
        re.DOTALL | re.IGNORECASE,
    )
    chunks: list[str] = []
    for block in pattern.findall(text):
        for line in block.splitlines():
            m = re.search(r'set\s+/p="([^"]*)"', line, re.IGNORECASE)
            if m:
                chunks.append(m.group(1))
    return chunks


def decode_stem(text: str, stem: str) -> bytes | None:
    chunks = _collect_b64_blocks(text, stem)
    if not chunks:
        return None
    payload = "".join(chunks)
    try:
        return base64.b64decode(payload, validate=False)
    except Exception as exc:
        raise ValueError(f"failed to decode {stem}: {exc}") from exc


def extract_from_bat(
    bat_path: Path,
    out_dir: Path,
    names: tuple[str, ...] = DEFAULT_NAMES,
    *,
    prefer_last: bool = True,
) -> list[Path]:
    text = bat_path.read_text(encoding="utf-8", errors="replace")
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    for stem in names:
        if stem == "rpatool":
            continue
        if prefer_last and stem == "altrpatool":
            # Multiple altrpatool blocks (py2/py3 branches) — last wins (py3 path).
            blocks = list(
                re.finditer(
                    rf'>\s*"%{re.escape(stem)}%\.b64"\s*\(',
                    text,
                    re.IGNORECASE,
                )
            )
            if not blocks:
                print(f"SKIP {stem}.py — no b64 block in {bat_path}", file=sys.stderr)
                continue
            start = blocks[-1].start()
            sub = text[start:]
            m = re.search(
                rf'>\s*"%{re.escape(stem)}%\.b64"\s*\((.*?)\)',
                sub,
                re.DOTALL | re.IGNORECASE,
            )
            if not m:
                continue
            payload = ""
            for line in m.group(1).splitlines():
                pm = re.search(r'set\s+/p="([^"]*)"', line, re.IGNORECASE)
                if pm:
                    payload += pm.group(1)
            try:
                data = base64.b64decode(payload, validate=False)
            except Exception as exc:
                print(f"SKIP {stem}.py — decode error: {exc}", file=sys.stderr)
                continue
        else:
            try:
                data = decode_stem(text, stem)
            except ValueError as exc:
                print(f"SKIP {stem}.py — {exc}", file=sys.stderr)
                continue
            if data is None:
                print(f"SKIP {stem}.py — no b64 block in {bat_path}", file=sys.stderr)
                continue

        dest = out_dir / f"{stem}.py"
        dest.write_bytes(data)
        written.append(dest)
        print(f"OK  {dest}")

    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bat_file", type=Path, help="UnRen-current.bat or UnRen-legacy.bat")
    parser.add_argument("out_dir", type=Path, help="Output directory for decoded .py files")
    parser.add_argument(
        "--also-copy-bats",
        type=Path,
        metavar="DIR",
        help="Copy bat bundle (LICENSE context) into this dir alongside scripts",
    )
    args = parser.parse_args(argv)

    if not args.bat_file.is_file():
        print(f"Missing bat file: {args.bat_file}", file=sys.stderr)
        return 1

    written = extract_from_bat(args.bat_file, args.out_dir)
    if args.also_copy_bats:
        import shutil

        src_dir = args.bat_file.parent
        args.also_copy_bats.mkdir(parents=True, exist_ok=True)
        for name in ("UnRen-forall.bat", "UnRen-current.bat", "UnRen-legacy.bat", "UnRen-cfg.txt", "UnRen-link.txt"):
            src = src_dir / name
            if src.is_file():
                shutil.copy2(src, args.also_copy_bats / name)
                print(f"OK  {args.also_copy_bats / name}")

    if not written:
        print("No scripts extracted.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
