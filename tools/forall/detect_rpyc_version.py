#!/usr/bin/env python3
# Staging copy from UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80
# https://github.com/Lurmel/UnRen-forall — JoeLurmel / Lurmel
# UnRen-Desktop: also probe .rpa archives and any loose .rpyc (pre-extract games).
from __future__ import print_function

import os
import pickle
import sys
import zlib

GAME_DIR = "game"
CANDIDATES = ["script.rpyc", "screen.rpyc", "options.rpyc", "gui.rpyc"]
SKIP_DIRS = {"sdk", ".sdk-sources-cache"}
SKIP_RPYC_PREFIXES = ("unren-",)


def check_rpyc_header(header):
    if header.startswith(b"RENPY RPC2"):
        return 0
    if header.startswith(b"RENPY RPC3"):
        return 1
    return 1


def _should_skip_path(root, fname):
    if fname.startswith(SKIP_RPYC_PREFIXES):
        return True
    rel = os.path.relpath(root, GAME_DIR)
    if rel == ".":
        return False
    parts = set(rel.replace("\\", "/").split("/"))
    return bool(parts & SKIP_DIRS)


def _candidate_paths(name):
    yield name
    yield os.path.join("game", name)


def find_rpyc_on_disk(names):
    for filename in names:
        for root, dirs, files in os.walk(GAME_DIR):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            if _should_skip_path(root, filename):
                continue
            if filename in files:
                return os.path.join(root, filename)
    return None


def find_any_rpyc_on_disk():
    for root, dirs, files in os.walk(GAME_DIR):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in sorted(files):
            if not (fname.endswith(".rpyc") or fname.endswith(".rpymc")):
                continue
            if _should_skip_path(root, fname):
                continue
            return os.path.join(root, fname)
    return None


def _load_rpa_indexes(path):
    with open(path, "rb") as handle:
        magic_line = handle.readline()

    if magic_line.startswith(b"RPA-3.0 ") or magic_line.startswith(b"RPA-3.2 "):
        vals = magic_line.split()
        offset = int(vals[1], 16)
        key = 0
        key_start = 3 if magic_line.startswith(b"RPA-3.2 ") else 2
        for subkey in vals[key_start:]:
            key ^= int(subkey, 16)
        with open(path, "rb") as handle:
            handle.seek(offset)
            raw = handle.read()
        indexes = pickle.loads(zlib.decompress(raw), encoding="latin1")
        decoded = {}
        for name, entries in indexes.items():
            decoded[name] = []
            for entry in entries:
                if len(entry) == 2:
                    off, length = entry
                    decoded[name].append((off ^ key, length ^ key))
                else:
                    off, length, prefix = entry
                    decoded[name].append((off ^ key, length ^ key, prefix))
        return decoded

    if magic_line.startswith(b"RPA-2.0 "):
        vals = magic_line.split()
        offset = int(vals[1], 16)
        with open(path, "rb") as handle:
            handle.seek(offset)
            raw = handle.read()
        return pickle.loads(zlib.decompress(raw), encoding="latin1")

    return None


def _read_archive_header(rpa_path, inner_name, nbytes=10):
    indexes = _load_rpa_indexes(rpa_path)
    if not indexes:
        return None

    for candidate in _candidate_paths(inner_name):
        if candidate not in indexes:
            continue
        entry = indexes[candidate][0]
        if len(entry) == 3:
            offset, length, prefix = entry
            prefix = prefix if isinstance(prefix, bytes) else prefix.encode("latin1")
        else:
            offset, length = entry
            prefix = b""

        with open(rpa_path, "rb") as handle:
            handle.seek(offset)
            data = prefix + handle.read(max(0, min(nbytes - len(prefix), length - len(prefix))))
        return data[:nbytes]
    return None


def find_rpyc_in_archives(names):
    if not os.path.isdir(GAME_DIR):
        return None, None

    archives = []
    for fname in sorted(os.listdir(GAME_DIR)):
        if not fname.lower().endswith(".rpa"):
            continue
        if fname.lower().endswith((".org", ".bak")):
            continue
        archives.append(os.path.join(GAME_DIR, fname))

    archives.sort(key=lambda p: (0 if os.path.basename(p).lower() == "scripts.rpa" else 1, p.lower()))

    for archive in archives:
        for name in names:
            header = _read_archive_header(archive, name)
            if header:
                return name, archive
    return None, None


def pick_rpyc_sample():
    path = find_rpyc_on_disk(CANDIDATES)
    if path:
        return path, os.path.basename(path), "disk"

    inner, archive = find_rpyc_in_archives(CANDIDATES)
    if inner:
        return archive, inner, "archive"

    path = find_any_rpyc_on_disk()
    if path:
        return path, os.path.basename(path), "disk"

    return None, None, None


def read_sample_header(location, label, source_kind, nbytes=10):
    if source_kind == "disk":
        with open(location, "rb") as handle:
            return handle.read(nbytes)
    if source_kind == "archive":
        return _read_archive_header(location, label, nbytes=nbytes)
    return None


path, label, source_kind = pick_rpyc_sample()
if path is None:
    print("No rpyc file found in '{0}'".format(GAME_DIR), file=sys.stderr)
    sys.exit(2)

header = read_sample_header(path, label, source_kind)
if not header:
    print("No rpyc file found in '{0}'".format(GAME_DIR), file=sys.stderr)
    sys.exit(2)

version_code = check_rpyc_header(header)
where = label
if source_kind == "archive":
    where = "{0} ({1})".format(label, os.path.basename(path))

print(
    "Detected: {0} ({1})".format(
        "RENPY RPC2" if version_code == 0 else "RENPY RPC3/unknown",
        where,
    ),
    file=sys.stderr,
)
sys.exit(version_code)
