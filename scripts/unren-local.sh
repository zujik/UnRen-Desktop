#!/usr/bin/env bash
# Resolve optional local cache directory for SDK sources and mirror staging.
# Source from other scripts:
#   source "$(dirname "$0")/unren-local.sh"
#   UNREN_LOCAL="$(unren_local_dir "${ROOT}")"
#
# Override with UNREN_LOCAL. Default: sibling directory next to the UnRen-Desktop root.

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
