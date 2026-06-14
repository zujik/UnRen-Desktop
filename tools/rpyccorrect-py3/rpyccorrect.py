#!/usr/bin/env python3
# rpycCorrector v1.04 — ported to Python 3 for UnRen-Desktop
#
# Copyright 2019-2020 "Anne O'nymous" AON/SC4X
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Fixes mangled RPYC signatures/encodings in renpy/script.py and game .rpyc files.

import base64
import binascii
import os
import struct
import sys
import zlib

VERSION = "1.04"
C_DATE = "2019-2020"

COPY_EXT = ".ORIGINAL"
LEGIT_SIG = "RENPY RPC2"

ZLIB_ORIGINAL = "original"
NBD_GZIPED = "neverBackDown"
NKT_FORMAT = "narutoKunoichiTrainer"

advanceChar = "/"
pyFile = None
pyOrgFile = None
workingDirs = []
sigRPYC = None
encodingRPYC = None


def advance():
    global advanceChar
    sys.stdout.write(advanceChar + "\b")
    advanceChar = chr(ord(advanceChar) ^ 115)


def error_report(msg):
    print("\n/!\\ Things gone wrong: " + msg)


def find_dirs(base):
    for f in os.listdir(base):
        path = os.path.join(base, f)
        if os.path.isdir(path):
            workingDirs.append(path)
            find_dirs(path)


def init():
    global workingDirs, pyFile, pyOrgFile

    cwd = os.getcwd()
    game_dir = os.path.join(cwd, "game") if not cwd.endswith("game") else cwd
    if not os.path.isdir(game_dir):
        error_report("missing or invalid 'game' directory.\n  Expected: '{}'".format(game_dir))
        sys.exit(1)

    workingDirs = [game_dir]
    find_dirs(game_dir)

    renpy_dir = os.path.join(cwd, "renpy") if not cwd.endswith("game") else os.path.join(cwd, "..", "renpy")
    if not os.path.isdir(renpy_dir):
        error_report("missing or invalid 'renpy' directory.\n  Expected: '{}'".format(renpy_dir))
        sys.exit(1)

    pyFile = os.path.join(renpy_dir, "script.py")
    if not os.path.isfile(pyFile):
        error_report("missing or invalid 'script.py' file.")
        sys.exit(1)

    pyOrgFile = pyFile + COPY_EXT
    if os.path.exists(pyOrgFile) and os.path.isfile(pyOrgFile) is False:
        error_report("will NOT be able to create the corrected 'script.py' file.")
        sys.exit(1)


def find_signature():
    sys.stdout.write("Searching for the used RPYC signature  ")

    source = pyOrgFile if os.path.isfile(pyOrgFile) else pyFile
    with open(source, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if not line.startswith("RPYC2_HEADER"):
                advance()
                continue
            u_quote = '"' if '"' in line else "'"
            return line[line.find(u_quote) + 1:line.rfind(u_quote)]

    print(" ")
    error_report("can NOT find the RPYC header signature.")
    sys.exit(1)


def find_encoding():
    sys.stdout.write("Searching for the used RPYC encoding  ")

    source = pyOrgFile if os.path.isfile(pyOrgFile) else pyFile
    with open(source, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if line == "data = zlib.compress(data, 9)":
                return ZLIB_ORIGINAL
            if line == 'data = zlib.compress(data, 9).encode("hex").encode("base64")':
                return NBD_GZIPED
            if line == 'f.write(struct.pack("IIII", 0, 0, 0, 0))':
                return NKT_FORMAT
            advance()

    print(" ")
    error_report("RPYC files are using an unknown encoding.")
    sys.exit(1)


def correct_script():
    sys.stdout.write("Correcting 'script.py' file  ")

    try:
        os.rename(pyFile, pyOrgFile)
    except OSError:
        error_report("can NOT rename 'script.py'.")
        sys.exit(1)

    with open(pyOrgFile, "r", encoding="utf-8", errors="replace") as src_fh, \
            open(pyFile, "w", encoding="utf-8") as dest_fh:
        for line in src_fh:
            if line.startswith("RPYC2_HEADER"):
                dest_fh.write('RPYC2_HEADER = "{}"\n'.format(LEGIT_SIG))
            elif encodingRPYC == ZLIB_ORIGINAL:
                dest_fh.write(line)
            elif encodingRPYC == NBD_GZIPED:
                if line.strip() == 'data = zlib.compress(data, 9).encode("hex").encode("base64")':
                    dest_fh.write(line[0:line.find('.encode("hex")')] + "\n")
                elif line == '            return data.decode("base64").decode("hex").decode("zlib")\n':
                    dest_fh.write('            return data.decode("zlib")\n')
                elif line == '        return data.decode("base64").decode("hex").decode("zlib")\n':
                    dest_fh.write("        return zlib.decompress(data)\n")
                else:
                    dest_fh.write(line)
            else:
                dest_fh.write(line)
            advance()

    print(" ")


def _nbd_decode(data):
    return zlib.decompress(binascii.unhexlify(base64.b64decode(data)))


def correct_rpyc(dest_name):
    src_name = dest_name + COPY_EXT

    short = dest_name[0:5] + "..." + dest_name[-57:] if len(dest_name) > 65 else dest_name
    sys.stdout.write("  PROCESSING    " + short + "  ")

    if os.path.isfile(src_name):
        print("\r  ALREADY DONE  ")
        return

    if os.path.exists(src_name):
        print("\r  FAILURE       ")
        error_report("can NOT create a copy of the file.")
        return

    try:
        os.rename(dest_name, src_name)
    except OSError:
        print("\r  FAILURE       ")
        error_report("Can NOT rename the file.")
        return

    try:
        src_fh = open(src_name, "rb")
        dest_fh = open(dest_name, "wb")
    except OSError:
        print("\r  FAILURE       ")
        error_report("Can NOT open files.")
        return

    try:
        src_fh.read(len(sigRPYC))
        dest_fh.write(LEGIT_SIG.encode("ascii"))

        for _ in range(3):
            dest_fh.write(struct.pack("III", 0, 0, 0))

        h_pos = src_fh.tell()

        while True:
            src_fh.seek(h_pos)
            if encodingRPYC == NKT_FORMAT:
                slot, start, length, _unused = struct.unpack("IIII", src_fh.read(16))
            else:
                slot, start, length = struct.unpack("III", src_fh.read(12))
            if slot == 0:
                break
            h_pos += 12

            src_fh.seek(start)
            data = src_fh.read(length)

            if encodingRPYC == NBD_GZIPED:
                data = _nbd_decode(data)
                data = zlib.compress(data, 9)

            dest_fh.seek(0, 2)
            start = dest_fh.tell()
            dest_fh.write(data)

            dest_fh.seek(len(LEGIT_SIG) + 12 * (slot - 1), 0)
            dest_fh.write(struct.pack("III", slot, start, len(data)))

        src_fh.seek(-16, 2)
        dest_fh.seek(0, 2)
        dest_fh.write(src_fh.read(16))

    except Exception as e:
        print("\r  FAILURE       ")
        error_report("Can NOT proceed the file.\n\t{} : {}".format(type(e), e))
        dest_fh.close()
        src_fh.close()
        try:
            os.remove(dest_name)
            os.rename(src_name, dest_name)
        except OSError:
            error_report("Can NOT revert the file name.")
        return

    print("\r  DONE          ")
    dest_fh.close()
    src_fh.close()


def main():
    global sigRPYC, encodingRPYC

    print("rpycCorrector - v:{} (c) AON/SC4X {} [py3 port]\n".format(VERSION, C_DATE))
    init()

    sigRPYC = find_signature()
    print("\rSignature: {} [{} signature]".format(
        sigRPYC, "altered" if sigRPYC != LEGIT_SIG else "original"))

    encodingRPYC = find_encoding()
    print("\rEncoding : {} [{} encoding]\n".format(
        encodingRPYC, "altered" if encodingRPYC != ZLIB_ORIGINAL else "original"))

    if sigRPYC == LEGIT_SIG and encodingRPYC == ZLIB_ORIGINAL:
        error_report("RPYC files seem to not be altered, or are altered in an unsupported way.")
        sys.exit(1)

    if os.path.isfile(pyOrgFile) is False:
        correct_script()

    for d in workingDirs:
        for f in os.listdir(d):
            if f.endswith(".rpyc"):
                correct_rpyc(os.path.join(d, f))


if __name__ == "__main__":
    main()
