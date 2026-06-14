#!/usr/bin/env python
# Staging copy from UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80
# https://github.com/Lurmel/UnRen-forall — JoeLurmel / Lurmel
import sys


def detect_archive_type(path):
    try:
        with open(path, "rb") as f:
            header = f.read(8)
            if header.startswith(b"RPA-") or header.startswith(b"SVAC-") or header.startswith(b"RWA-3.0 "):
                return 0
            else:
                return 1
    except Exception as e:
        sys.stderr.write("Error: {}\n".format(e))
        return 1


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: detect_archive.py <archive_file>")
        sys.exit(1)

    archive_file = sys.argv[1]
    result = detect_archive_type(archive_file)
    sys.exit(result)
