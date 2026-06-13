#!/usr/bin/env bash
# Build a release zip excluding .git and local SDK sources.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep UNREN_VERSION "${ROOT}/lib/config.sh" | cut -d'"' -f2)"
OUT="${ROOT}/dist"
ARCHIVE="${OUT}/UnRen-Desktop-${VERSION}.zip"

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
