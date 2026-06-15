#!/usr/bin/env bash
# Build a release zip excluding .git and local SDK sources.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep '^UNREN_VERSION=' "${ROOT}/unren/config.sh" | head -1 | cut -d'"' -f2)"
OUT="${ROOT}/dist"
ARCHIVE="${OUT}/UnRen-Desktop-${VERSION}.zip"

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }
python3 -m json.tool "${ROOT}/manifest.json" >/dev/null

mkdir -p "$OUT"
rm -f "$ARCHIVE"

(
    cd "$ROOT"
    zip -r "$ARCHIVE" . \
        -x './.git/*' \
        -x './dist/*' \
        -x '**/.DS_Store' \
        -x './b64.file'
)

echo "Created ${ARCHIVE}"
