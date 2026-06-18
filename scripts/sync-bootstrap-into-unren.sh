#!/usr/bin/env bash
# Inject scripts/bootstrap.sh into UnRen.sh between inline markers (release builds).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${ROOT}/UnRen.sh"
BOOT="${ROOT}/scripts/bootstrap.sh"
START='# UNREN_BOOTSTRAP_INLINE_START'
END='# UNREN_BOOTSTRAP_INLINE_END'

[[ -f "$BOOT" && -f "$TARGET" ]] || { echo "missing UnRen.sh or scripts/bootstrap.sh" >&2; exit 1; }

python3 - "$TARGET" "$BOOT" "$START" "$END" <<'PY'
import pathlib, sys
target, boot, start, end = sys.argv[1:5]
text = pathlib.Path(target).read_text()
body = pathlib.Path(boot).read_text().rstrip() + "\n"
if start not in text or end not in text:
    sys.exit("markers missing in UnRen.sh")
pre, rest = text.split(start, 1)
_, post = rest.split(end, 1)
out = pre + start + "\n" + body + end + post
pathlib.Path(target).write_text(out)
print("Synced bootstrap into UnRen.sh")
PY
