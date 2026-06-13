#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Staging copy from UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80
# https://github.com/Lurmel/UnRen-forall — JoeLurmel / Lurmel
# UnRen-Desktop patch: import wos_rpyc_loader from game root (UNREN_APP).

import os
import hashlib
from pathlib import Path
import struct
import sys
import traceback

_game_root = os.environ.get("UNREN_APP", os.getcwd())
if _game_root not in sys.path:
    sys.path.insert(0, _game_root)

try:
    from renpy.wos_rpyc_loader import MAGIC_RPYC, SECRET_KEY
except ImportError:
    sys.stderr.write("renpy.wos_rpyc_loader not found under {}\n".format(_game_root))
    sys.exit(1)


def _wos_derive_key_stream(key_material, length):
    stream = bytearray()
    counter = 0
    while len(stream) < length:
        h = hashlib.sha256(key_material + struct.pack("<I", counter)).digest()
        stream.extend(h)
        counter += 1
    return bytes(stream[:length])


def _wos_xor_crypt(data, key_material):
    key_stream = _wos_derive_key_stream(key_material, len(data))
    return bytes(a ^ b for a, b in zip(data, key_stream))


def wos_decrypt_rpyc(filepath):
    with open(filepath, "rb") as f:
        magic = f.read(len(MAGIC_RPYC))
        if magic != MAGIC_RPYC:
            return None

        nonce_len = struct.unpack("<H", f.read(2))[0]
        nonce = f.read(nonce_len)

        original_len = struct.unpack("<I", f.read(4))[0]
        checksum = f.read(32)

        encrypted_data = f.read()

    rpyc_key = hashlib.sha256(SECRET_KEY + b"_rpyc").digest()

    candidates = []

    game_dir = Path("game").resolve()

    try:
        rel = os.path.relpath(Path(filepath).resolve(), game_dir).replace("\\", "/")
        candidates.append(rel)
    except Exception:
        pass

    candidates.append(os.path.basename(filepath))

    seen = set()
    for c in candidates:
        if c in seen:
            continue
        seen.add(c)

        file_key = hashlib.sha256(rpyc_key + c.encode()).digest()
        combined_key = file_key + nonce
        decrypted = _wos_xor_crypt(encrypted_data, combined_key)
        decrypted = decrypted[:original_len]

        if hashlib.sha256(decrypted).digest() == checksum:
            return decrypted

    return None


INPUT_DIR = Path("game")

DRY_RUN = False


def _enable_vt_windows():
    try:
        import ctypes
        kernel = ctypes.windll.kernel32
        handle = kernel.GetStdHandle(-11)
        mode = ctypes.c_ulong(0)
        kernel.GetConsoleMode(handle, ctypes.byref(mode))
        kernel.SetConsoleMode(handle, mode.value | 0x0004)
    except Exception:
        pass


_enable_vt_windows()

USE_COLORS = True
CYA = "\033[96m" if USE_COLORS else ""
GRE = "\033[92m" if USE_COLORS else ""
RED = "\033[91m" if USE_COLORS else ""
YEL = "\033[93m" if USE_COLORS else ""
RES = "\033[0m" if USE_COLORS else ""


def safe_rename(src: Path, dst: Path):
    if DRY_RUN:
        display_stat(f"Rename {src} → {dst}", f"{YEL}DRY-RUN")
    else:
        src.rename(dst)


def safe_write(path: Path, data: bytes):
    if DRY_RUN:
        display_stat(f"Write {path}", f"{YEL}DRY-RUN")
    else:
        with open(path, "wb") as f:
            f.write(data)


def display_stat(message, stat=None):
    if stat is None:
        sys.stdout.write(f"\r[      ] {message}")
    else:
        sys.stdout.write(f"\r[ {stat}{RES} ] {message}\n")
    sys.stdout.flush()


def process_file(path: Path, stats):
    rel_name = str(path.relative_to(INPUT_DIR))
    display_stat(f"{rel_name}")
    stats["rpyc"] += 1

    try:
        with open(path, "rb") as f:
            magic = f.read(len(MAGIC_RPYC))
        if magic != MAGIC_RPYC:
            display_stat(f"{rel_name}", f"{CYA}SKIP")
            stats["skip"] += 1
            return
    except Exception:
        display_stat(f"{rel_name}", f"{RED}NOK ")
        stats["nok"] += 1
        return

    try:
        data = wos_decrypt_rpyc(str(path))

        if not data:
            display_stat(f"{rel_name}", f"{RED}NOK ")
            stats["nok"] += 1
            return

        dec_path = path.with_suffix(path.suffix + ".dec")
        safe_write(dec_path, data)

        org_path = path.with_suffix(path.suffix + ".org")
        if not org_path.exists():
            safe_rename(path, org_path)

        final_path = path
        if final_path.exists():
            if not DRY_RUN:
                final_path.unlink()
        safe_rename(dec_path, final_path)

        display_stat(f"{rel_name}", f"{GRE} OK ")
        stats["ok"] += 1

    except Exception:
        display_stat(f"{rel_name}", f"{RED}NOK ")
        stats["nok"] += 1
        traceback.print_exc()


def main():
    stats = {"rpyc": 0, "ok": 0, "nok": 0, "skip": 0}

    previous_dir = None
    for path in INPUT_DIR.rglob("*.rpyc"):
        current_dir = path.parent
        if current_dir != previous_dir:
            print(f"\n-> .\\{current_dir}:")
            previous_dir = path.parent
        if path.is_file():
            process_file(path, stats)

    print(
        f"\n\nRPYC = '{stats['rpyc']}', OK = {GRE}'{stats['ok']}'{RES}, NOK = {RED}'{stats['nok']}'{RES}, SKIP = {CYA}'{stats['skip']}'{RES}\n"
    )


if __name__ == "__main__":
    main()
