#!/usr/bin/env bash
# Resolve UNRen-Local (sibling of UnRen-Desktop). Source from other scripts:
#   source "$(dirname "$0")/unren-local.sh"
#   UNREN_LOCAL="$(unren_local_dir "${ROOT}")"

unren_local_dir() {
    local root="$1"
    if [[ -n "${UNREN_LOCAL:-}" ]]; then
        cd "${UNREN_LOCAL}" && pwd
        return 0
    fi
    local candidate="${root}/../UnRen-Local"
    if [[ -d "$candidate" ]]; then
        cd "$candidate" && pwd
        return 0
    fi
    # Legacy layout: caches lived directly under parent of UnRen-Desktop
    cd "${root}/.." && pwd
}
