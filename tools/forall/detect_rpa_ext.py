#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Staging copy from UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80
# https://github.com/Lurmel/UnRen-forall — JoeLurmel / Lurmel (v0.4)

from __future__ import print_function
import os
import sys


def normalize_path(arg):
    p = arg.strip().strip('\'"')
    return p


if len(sys.argv) > 1:
    raw = sys.argv[1]
    game_dir = normalize_path(raw)
else:
    game_dir = os.getcwd()

game_dir = os.path.abspath(game_dir)
os.chdir(game_dir)


def try_renpy_handlers():
    try:
        import renpy.object
        import renpy.loader

        try:
            import renpy.error
            import renpy.config
        except Exception:
            pass

        try:
            ah = renpy.loader.archive_handlers
        except Exception:
            return None

        handlers = getattr(ah, "handlers", ah)

        exts = []
        try:
            for h in handlers:
                if hasattr(h, "get_supported_extensions"):
                    exts.extend(h.get_supported_extensions())
                elif hasattr(h, "get_supported_ext"):
                    exts.extend(h.get_supported_ext())
        except Exception:
            return None

        exts = sorted(set(e for e in exts if isinstance(e, (str, bytes))))
        return exts or None

    except Exception:
        return None


def is_rpa_file(path):
    try:
        with open(path, "rb") as f:
            sig = f.read(8)
        return sig.startswith(b"RPA-")
    except Exception:
        return False


def scan_present_archives(base_dir):
    exts = set()

    def scan(d):
        try:
            for name in os.listdir(d):
                full = os.path.join(d, name)
                if not os.path.isfile(full):
                    continue
                if os.path.splitext(name)[1].lower() == '.org':
                    continue
                if is_rpa_file(full):
                    _, ext = os.path.splitext(name)
                    if ext:
                        exts.add(ext.lower())
        except Exception:
            pass

    scan(base_dir)

    game_sub = os.path.join(base_dir, "game")
    if os.path.isdir(game_sub):
        scan(game_sub)

    return sorted(exts)


def detect_archive_extensions(base_dir):
    exts = try_renpy_handlers()
    if exts:
        return exts

    exts = scan_present_archives(base_dir)
    if exts:
        return exts

    return [".rpa"]


def main():
    exts = detect_archive_extensions(game_dir)

    try:
        out = sys.stdout
        if hasattr(out, "buffer"):
            out.buffer.write((repr(exts) + "\n").encode("utf-8", "replace"))
        else:
            print(repr(exts))
    except Exception:
        print(exts)

    sys.exit(0 if exts else 1)


if __name__ == "__main__":
    main()
