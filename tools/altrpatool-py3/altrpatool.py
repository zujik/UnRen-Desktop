#!/usr/bin/env python3

# Made by (SM) aka JoeLurmel @ f95zone.to
# This script is licensed under GNU GPL v3 — see LICENSE for details

from __future__ import print_function
import sys
import os
from pathlib import Path
import argparse
import hashlib
import pickle
import zlib

sys.path.append('..')
try:
    import main  # noqa: F401
except:
    pass

import renpy.object  # noqa: F401
import renpy.config
import renpy.loader
try:
    import renpy.util  # noqa: F401
except:
    pass

class JASArchiveHandlerLocal:
    """
    Standalone JAS Handler (without Ren'Py)
    """

    def __init__(self, file_path):
        self.file = file_path
        self.index = {}
        self._load_index()

    def _decode_header(self, header):
        # The dev always returns this string, so we can use it to find the offsets and key
        return "danstoncullabalayette"

    def _load_index(self):
        with open(self.file, "rb") as f:
            header = f.read(40)

            # 1) decode() → returns a fixed string
            decoded = self._decode_header(header)

            # 2) MD5
            md5hex = hashlib.md5(decoded.encode()).hexdigest()
            x50 = int(md5hex[0], 16) % 8
            x4B = int(md5hex[1], 16) % 4

            # 3) extraction of hex fields
            x22 = header[8+x50 : 24+x50].decode().replace("X", "0")
            x23 = header[25+x4B : 33+x4B].decode().replace("X", "0")

            x4F = int(x22, 16)  # offset index
            x6B = int(x23, 16)  # XOR key

            # 4) reading the index
            f.seek(x4F)
            raw = f.read()
            try:
                index = pickle.loads(zlib.decompress(raw))
            except Exception:
                raise RuntimeError("Impossible de décompresser l’index JAS")

            # 5) decoding the offsets
            fixed = {}
            for name, entries in index.items():
                new_entries = []
                for e in entries:
                    if len(e) == 2:
                        off, size = e
                        new_entries.append((off ^ x6B, size ^ x6B))
                    else:
                        off, size, extra = e
                        new_entries.append((off ^ x6B, size ^ x6B, extra))
                fixed[name] = new_entries

            self.index = fixed

    def list(self):
        return list(self.index.keys())

    def read(self, filename):
        entries = self.index.get(filename)
        if not entries:
            return None

        off, size = entries[0][:2]
        with open(self.file, "rb") as f:
            f.seek(off)
            return f.read(size)


class RenPyArchive:
    def __init__(self, file_path, index=0):
        self.file = str(file_path)
        self.indexes = {}
        self.load(self.file, index)

    def convert_filename(self, filename):
        drive, filename = os.path.splitdrive(
            os.path.normpath(filename).replace(os.sep, '/')
        )
        return filename

    def list(self):
        return list(self.indexes)

    def read(self, filename):
        filename = self.convert_filename(filename)
        idx = self.indexes.get(filename)
        if filename != '.' and isinstance(idx, list):
            if hasattr(renpy.loader, "load_from_archive"):
                subfile = renpy.loader.load_from_archive(filename)
            else:
                subfile = renpy.loader.load_core(filename)
            return subfile.read()
        return None

    def load(self, filename, index):
        base = os.path.splitext(os.path.basename(filename))[0]

        if base not in renpy.config.archives:
            renpy.config.archives.append(base)

        archive_dir = os.path.dirname(os.path.realpath(filename))
        renpy.config.searchpath = [archive_dir]
        renpy.config.basedir = os.path.dirname(renpy.config.searchpath[0])
        renpy.loader.index_archives()

        archives_obj = renpy.loader.archives

        if isinstance(archives_obj, dict):
            items = archives_obj[base][1].items()
        else:
            items = archives_obj[index][1].items()

        for f, idx in items:
            self.indexes[f] = idx


def list_archive(arch_path, archive_class):
    print(f'Contenu de "{arch_path}":')
    archive = archive_class(arch_path)
    for filename in archive.list():
        print("  ", filename)


def discover_extensions():
    exts = []
    if hasattr(renpy.loader, "archive_handlers"):
        for handler in renpy.loader.archive_handlers:
            if hasattr(handler, "get_supported_extensions"):
                exts.extend(handler.get_supported_extensions())
            if hasattr(handler, "get_supported_ext"):
                exts.extend(handler.get_supported_ext())
    else:
        exts.append('.rpa')

    # Ajout manuel si le handler n'est pas détecté
    if '.jas' not in exts:
        exts.append('.jas')

    if '.rpc' not in exts:
        exts.append('.rpc')

    return sorted(set(e.lower() for e in exts))


def discover_archives(search_dir, extensions):
    archives = []
    for root, dirs, files in os.walk(str(search_dir)):
        for file in files:
            try:
                base, ext = file.rsplit('.', 1)
                ext = '.' + ext.lower()
                if ext in extensions and '%' not in file:
                    archives.append(Path(root) / file)
            except ValueError:
                continue
    return archives


def extract_archive(arch_path, output, archive_class):
    print(f'  Unpacking "{arch_path}"')
    archive = archive_class(arch_path)
    files = archive.list()

    output.mkdir(parents=True, exist_ok=True)

    for filename in files:
        contents = archive.read(filename)
        if contents is not None:
            outfile = output / filename
            outfile.parent.mkdir(parents=True, exist_ok=True)
            with open(outfile, 'wb') as f:
                f.write(contents)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--list', action="store_true", dest='list_only',
                        help="List the contents of the archive without extracting them")
    parser.add_argument('-r', action="store_true", dest='remove')
    parser.add_argument('-x', dest='archive', type=str)
    parser.add_argument('-o', dest='output', type=str, default='.')
    args = parser.parse_args()

    output = Path(args.output).resolve()
    archive_filter = args.archive
    remove = args.remove

    extensions = discover_extensions()

    # Mode -x
    if archive_filter:
        target = Path(archive_filter).resolve()
        if not target.exists():
            basename = os.path.basename(archive_filter)
            found = None
            for root, dirs, files in os.walk('.'):
                if basename in files:
                    found = Path(root) / basename
                    break
            if found is None:
                print(f'Archive "{archive_filter}" not found.')
                sys.exit(1)
            target = found.resolve()

        # Choix du handler
        if target.suffix.lower() == ".jas":
            handler = JASArchiveHandlerLocal
        else:
            handler = RenPyArchive

        if args.list_only:
            list_archive(target, handler)
            return

        extract_archive(target, output, handler)

        if remove:
            os.remove(str(target))
        return

    # Défault mode
    archives = discover_archives(Path('.'), extensions)

    if not archives:
        print("No archives found.")
        return

    for arch in archives:
        if arch.suffix.lower() == ".jas":
            handler = JASArchiveHandlerLocal
        else:
            handler = RenPyArchive

        if args.list_only:
            list_archive(arch, handler)
        else:
            extract_archive(arch, output, handler)

    if remove:
        for arch in archives:
            os.remove(str(arch))


if __name__ == "__main__":
    main()
