#!/usr/bin/env bash
# Package trimmed SDK folders as tarballs for GitHub Releases.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/dist"
mkdir -p "$OUT"

for slice in py3-8.5.3 py2-7.8.7; do
    src="${ROOT}/sdk/${slice}"
    [[ -d "${src}/lib" ]] || { echo "skip ${slice}: run populate-sdk.sh first" >&2; continue; }
    out="${OUT}/unren-sdk-${slice}.tar.bz2"
    tar -cjf "$out" -C "${ROOT}/sdk" "${slice}"
    echo "Created ${out}"
done
