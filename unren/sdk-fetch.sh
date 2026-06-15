# Fetch trimmed SDK slices from GitHub Releases (slim bootstrap / Windows-only games).

_unren_sdk_release_repo() {
    printf '%s\n' "${UNREN_RELEASE_REPO:-https://github.com/zujik/UnRen-Desktop}"
}

_unren_sdk_release_tag() {
    printf '%s\n' "${UNREN_RELEASE_TAG:-v2.0.0-alpha.1}"
}

_unren_sdk_slice_archive_name() {
    printf 'unren-sdk-%s.tar.bz2\n' "$1"
}

_unren_sdk_slice_download_url() {
    local slice="$1" repo tag name
    repo="$(_unren_sdk_release_repo)"
    tag="$(_unren_sdk_release_tag)"
    name="$(_unren_sdk_slice_archive_name "$slice")"
    printf '%s/releases/download/%s/%s' "$repo" "$tag" "$name"
}

_unren_sdk_slice_local_archive() {
    local slice="$1"
    if [[ -n "${UNREN_SDK_SLICE_ARCHIVE:-}" && -f "${UNREN_SDK_SLICE_ARCHIVE}" ]]; then
        printf '%s\n' "${UNREN_SDK_SLICE_ARCHIVE}"
        return 0
    fi
    if [[ -n "${UNREN_SDK_SLICE_DIR:-}" && -f "${UNREN_SDK_SLICE_DIR}/$(_unren_sdk_slice_archive_name "$slice")" ]]; then
        printf '%s\n' "${UNREN_SDK_SLICE_DIR}/$(_unren_sdk_slice_archive_name "$slice")"
        return 0
    fi
    if [[ -f "${UNREN_ROOT}/../dist/$(_unren_sdk_slice_archive_name "$slice")" ]]; then
        printf '%s\n' "${UNREN_ROOT}/../dist/$(_unren_sdk_slice_archive_name "$slice")"
        return 0
    fi
    return 1
}

_unren_auto_fetch_sdk_enabled() {
    [[ "${UNREN_AUTO_FETCH_SDK:-}" == 0 ]] && return 1
    [[ "${UNREN_FETCH_SDK:-}" == 1 ]] && return 0
    [[ "${UNREN_AUTO_FETCH_SDK:-}" == 1 ]] && return 0
    # Slim bootstrap: payload has no usable sdk/ tree.
    if [[ ! -d "${UNREN_ROOT}/sdk" ]]; then
        return 0
    fi
    local slice
    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        if _unren_sdk_slice_exists "$slice" "${UNREN_APP:-}"; then
            return 1
        fi
    done < <(_unren_sdk_fallback_chain "${UNREN_APP:-}")
    return 0
}

_unren_fetch_sdk_slice() {
    local slice="$1"
    local dest_root="${UNREN_ROOT}/sdk" url archive tmp local

    if _unren_sdk_slice_exists "$slice" "${UNREN_APP:-}"; then
        return 0
    fi

    mkdir -p "$dest_root"
    if local="$(_unren_sdk_slice_local_archive "$slice" 2>/dev/null)"; then
        archive="$local"
        echo "  Using local SDK archive: ${archive}" >&2
    else
        url="$(_unren_sdk_slice_download_url "$slice")"
        archive="${dest_root}/.download-$(_unren_sdk_slice_archive_name "$slice")"
        echo "  Fetching SDK slice ${slice} ..." >&2
        echo "  URL: ${url}" >&2
        tmp="${archive}.part"
        if command -v curl >/dev/null 2>&1; then
            curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url" || return 1
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$tmp" "$url" || return 1
        else
            echo "[!] Need curl or wget to fetch SDK slice." >&2
            return 1
        fi
        mv -f "$tmp" "$archive"
    fi

    tar -xjf "$archive" -C "$dest_root"
    rm -f "${dest_root}/.download-"*.tar.bz2 2>/dev/null || true

    if ! _unren_sdk_slice_exists "$slice" "${UNREN_APP:-}"; then
        echo "[!] SDK slice ${slice} missing after extract." >&2
        return 1
    fi
    echo "  SDK slice ready: ${dest_root}/${slice}" >&2
    return 0
}

_unren_try_auto_fetch_sdk_slices() {
    local app="$1" py_major="$2" platform="$3"
    local slice fetched=0

    _unren_auto_fetch_sdk_enabled || return 1

    if _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" _sdk_r _sdk_l; then
        return 0
    fi

    echo "  No usable SDK in game or UnRen payload — fetching runtime slice(s) ..." >&2
    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        _unren_sdk_slice_exists "$slice" "$app" && continue
        if _unren_fetch_sdk_slice "$slice"; then
            fetched=1
            if _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" _sdk_r _sdk_l; then
                return 0
            fi
        fi
    done < <(_unren_sdk_fallback_chain "$app")

    (( fetched )) && return 0
    echo "[!] Could not fetch any SDK slice from GitHub Releases." >&2
    echo "    Upload unren-sdk-*.tar.bz2 to the release (scripts/package-sdk-release.sh)." >&2
    echo "    Or use UNREN_BUNDLE=full, or set UNREN_SDK_SLICE_DIR to local archives." >&2
    return 1
}
