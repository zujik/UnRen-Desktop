#!/usr/bin/env python
# Staging copy from UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80
# https://github.com/Lurmel/UnRen-forall — JoeLurmel / Lurmel
from __future__ import print_function
import sys
import os

GAME_DIR = "game"
CANDIDATES = ["script.rpyc", "screen.rpyc", "options.rpyc", "gui.rpyc"]


def find_rpyc():
    for filename in CANDIDATES:
        for root, dirs, files in os.walk(GAME_DIR):
            if filename in files:
                return os.path.join(root, filename)
    return None


def check_rpyc_version(path):
    with open(path, "rb") as f:
        header = f.read(10)

    if header.startswith(b"RENPY RPC2"):
        return 0
    elif header.startswith(b"RENPY RPC3"):
        return 1
    else:
        return 1


path = find_rpyc()
if path is None:
    print("No rpyc file found in '{0}'".format(GAME_DIR), file=sys.stderr)
    sys.exit(2)

version_code = check_rpyc_version(path)
print("Detected: {0} ({1})".format(
    "RENPY RPC2" if version_code == 0 else "RENPY RPC3/unknown",
    os.path.basename(path)
), file=sys.stderr)
sys.exit(version_code)
