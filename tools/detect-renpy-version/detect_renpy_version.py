#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
import re

# --- 1. Standard method: import renpy ---
try:
    import renpy
    print(renpy.version_tuple[0])
    sys.exit(0)
except Exception:
    pass  # fallback below

def detect_from_script_version(game_dir):
    # 1) Ren'Py 7/8 : script_version.txt
    path = os.path.join(game_dir, "script_version.txt")
    if os.path.isfile(path):
        try:
            with open(path, "r") as f:
                content = f.read().strip()

            # Tuple format : (8, 1, 0)
            m = re.search(r'\(\s*(\d+)\s*,', content)
            if m:
                return int(m.group(1))

            # Simple format : 8.1.0 ou 8
            m = re.match(r'\s*(\d+)', content)
            if m:
                return int(m.group(1))

        except Exception:
            pass

    # 2) Ren'Py 6 : renpy/version.py
    version_py = os.path.join(game_dir, "renpy", "version.py")
    if os.path.isfile(version_py):
        try:
            with open(version_py, "r") as f:
                content = f.read()

            # version = "6.99.14"
            m = re.search(r'version\s*=\s*"(\d+)', content)
            if m:
                return int(m.group(1))

        except Exception:
            pass

    return None


def detect_from_rpyc(game_dir):
    """
    Reads the magic number of .rpyc / .rpymc files.
    Ren'Py 6: magic “RENPY RPC1”  -> major 6 (and some early 7)
    Ren'Py 7: magic “RENPY RPC2”  -> major 7
    Ren'Py 8: magic “RENPY RPC2”  with Python 3 (cannot be easily distinguished
                from 7 using magic alone, other methods are used to complete the process)
    Note: some early Ren'Py 7 may still use “RENPY RPC1” magic, but they are rare and we prioritize the more common case.
    """
    magic_map = {
        b"RENPY RPC1": 6,
        b"RENPY RPC2": 7,  # can also be 8
    }
    for root, dirs, files in os.walk(game_dir):
        for fname in files:
            if fname.endswith(".rpyc") or fname.endswith(".rpymc"):
                fpath = os.path.join(root, fname)
                try:
                    with open(fpath, "rb") as f:
                        header = f.read(10)
                    for magic, major in magic_map.items():
                        if header.startswith(magic):
                            return major
                except Exception:
                    continue
    return None


def detect_from_executable(game_dir):
    """
    Look for version clues in the executables/libs present
    in the game folder (strings “7.” or “8.” close to “Ren'Py”).
    """
    base = os.path.dirname(game_dir)  # parent folder of the game/ folder
    search_dirs = [base, game_dir]
    patterns = [
        (re.compile(r"Ren.?Py\s+(\d)\.\d"), None),
        (re.compile(r"renpy[_\-](\d)\.\d"), re.IGNORECASE),
    ]
    for sdir in search_dirs:
        for fname in os.listdir(sdir):
            fpath = os.path.join(sdir, fname)
            if not os.path.isfile(fpath):
                continue
            # Only small text or log files are read.
            if fname.endswith((".txt", ".log", ".ini", ".cfg", ".json")):
                try:
                    with open(fpath, "r") as f:
                        content = f.read(4096)
                    for pat, flags in patterns:
                        m = pat.search(content)
                        if m:
                            major = int(m.group(1))
                            if major in (6, 7, 8):
                                return major
                except Exception:
                    pass
    return None


def detect_from_archive(game_dir):
    """
    Inspect the .rpa archives to detect the version.
    RPA-1.0 -> Ren'Py 6 early
    RPA-2.0 -> Ren'Py 6
    RPA-3.0 -> Ren'Py 6/7
    RPAN3.0 -> Ren'Py 8 (new neutron archive)
    ZiX-12A -> Ren'Py 8 (new neutron archive)
    ZiX-12B -> Ren'Py 8 (new neutron archive)
    """
    rpa_major_map = {
        b"RPA-1.0": 6,
        b"RPA-2.0": 6,
        b"RPA-3.0": 7,   # Maybe 6 as well, but we'll refine it later.
        b"RPAN3.0": 8,
        b"ZiX-12A": 8,
        b"ZiX-12B": 8,
    }
    found = None
    for fname in os.listdir(game_dir):
        if not fname.endswith(".rpa"):
            continue
        fpath = os.path.join(game_dir, fname)
        try:
            with open(fpath, "rb") as f:
                header = f.read(8)
            for magic, major in rpa_major_map.items():
                if header.startswith(magic):
                    # We keep the highest major found.
                    if found is None or major > found:
                        found = major
        except Exception:
            pass
    return found


def detect_renpy_major(game_path):
    """
    Detects the major Ren'Py version (6, 7, or 8) from the game path.
    game_path can be the game's root folder or the “game/” subfolder.
    """
    # Normalize: we want the “game/” folder
    if os.path.basename(game_path) == "game":
        game_dir = game_path
    else:
        candidate = os.path.join(game_path, "game")
        if os.path.isdir(candidate):
            game_dir = candidate
        else:
            game_dir = game_path  # we try directly

    if not os.path.isdir(game_dir):
        print("ERROR: directory not found: {}".format(game_dir))
        sys.exit(1)

    # 1. script_version.txt (priority but optional)
    major = detect_from_script_version(game_dir)
    if major is not None:
        return major

    # 2. Archives .rpa (Reliable signatures for Ren'Py 8)
    major = detect_from_archive(game_dir)
    if major is not None:
        # RPA-3.0 can be 6 or 7; we refine it with the .rpyc files.
        if major == 7:
            rpyc_major = detect_from_rpyc(game_dir)
            if rpyc_major is not None:
                return rpyc_major
        return major

    # 3. .rpyc files (very reliable for Ren'Py 6 and 7, but do not distinguish between 7 and 8):
    major = detect_from_rpyc(game_dir)
    if major is not None:
        return major

    # 4. Text files in the root folder (may contain version info, especially for Ren'Py 8):
    major = detect_from_executable(game_dir)
    if major is not None:
        return major

    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: {} <game_path>".format(sys.argv[0]))
        sys.exit(1)

    game_path = sys.argv[1]

    major = detect_renpy_major(game_path)

    if major is None:
        print("ERROR: impossible to detect Ren'Py version in : {}".format(game_path))
        sys.exit(1)

    if major not in (6, 7, 8):
        print("ERROR: unexpected Ren'Py version detected : {}".format(major))
        sys.exit(1)

    print(major)


if __name__ == "__main__":
    main()
