# UnRen-Desktop bootstrap — resolve or download the runtime payload.
# Sourced from UnRen.sh before unren/config.sh is loaded.

# Override with UNREN_RELEASE_TAG / UNREN_BUNDLE / UNREN_PAYLOAD_DIR
UNREN_RELEASE_REPO="${UNREN_RELEASE_REPO:-https://github.com/zujik/UnRen-Desktop}"
UNREN_RELEASE_TAG="${UNREN_RELEASE_TAG:-v2.0.0-alpha.1}"
UNREN_BUNDLE="${UNREN_BUNDLE:-slim}"

_unren_bootstrap_version() {
    printf '%s' "${UNREN_RELEASE_TAG#v}"
}

_unren_bootstrap_bundle_name() {
    local ver bundle
    ver="$(_unren_bootstrap_version)"
    bundle="${UNREN_BUNDLE:-slim}"
    case "$bundle" in
        full) printf 'unren-desktop-full-%s.tar.xz' "$ver" ;;
        slim|*) printf 'unren-desktop-slim-%s.tar.xz' "$ver" ;;
    esac
}

_unren_bootstrap_bundle_url() {
    local name
    name="$(_unren_bootstrap_bundle_name)"
    printf '%s/releases/download/%s/%s' \
        "${UNREN_RELEASE_REPO}" "${UNREN_RELEASE_TAG}" "$name"
}

_unren_bootstrap_checksums_url() {
    printf '%s/releases/download/%s/SHA256SUMS-desktop' \
        "${UNREN_RELEASE_REPO}" "${UNREN_RELEASE_TAG}"
}

_unren_bootstrap_payload_dir() {
    local script_dir="${1:?}"
    printf '%s\n' "${UNREN_PAYLOAD_DIR:-${script_dir}/unren-desktop}"
}

_unren_bootstrap_verify_license_files() {
    local root="${1:?}"
    local missing=0 f slice

    for f in LICENSE NOTICE THIRD_PARTY_LICENSES.md; do
        if [[ ! -f "${root}/${f}" ]]; then
            echo "  missing ${f}" >&2
            missing=1
        fi
    done
    if [[ ! -f "${root}/tools/altrpatool-py3/COPYING" ]]; then
        echo "  missing tools/altrpatool-py3/COPYING" >&2
        missing=1
    fi
    if [[ -d "${root}/sdk" ]]; then
        for slice in "${root}"/sdk/*/; do
            [[ -d "$slice" ]] || continue
            if [[ ! -f "${slice}/LICENSE.txt" ]]; then
                echo "  missing ${slice}/LICENSE.txt" >&2
                missing=1
            fi
        done
    fi
    (( missing )) && return 1
    return 0
}

_unren_bootstrap_sha256_file() {
    local script_dir="${1:?}"
    local payload
    payload="$(_unren_bootstrap_payload_dir "$script_dir")"
    [[ -f "${payload}/.unren-bundle.sha256" ]] && cat "${payload}/.unren-bundle.sha256"
    return 0
}

_unren_bootstrap_verify_sha256() {
    local archive="${1:?}" expected="${2:-}"
    local actual

    if [[ -z "$expected" ]]; then
        echo "[!] No SHA256 available for $(basename -- "$archive"); refusing unverified payload." >&2
        echo "    Set UNREN_BUNDLE_SHA256 for custom release assets." >&2
        return 1
    fi
    if ! command -v sha256sum >/dev/null 2>&1; then
        if command -v shasum >/dev/null 2>&1; then
            actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
        else
            echo "[!] Need sha256sum or shasum to verify UnRen payload." >&2
            return 1
        fi
    else
        actual="$(sha256sum "$archive" | awk '{print $1}')"
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "[!] SHA256 mismatch for $(basename -- "$archive")" >&2
        echo "    expected: $expected" >&2
        echo "    actual:   $actual" >&2
        return 1
    fi
    return 0
}

_unren_bootstrap_download() {
    local url="${1:?}" dest="${2:?}"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 -o "$dest" "$url"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -O "$dest" "$url"
        return $?
    fi
    echo "[!] Need curl or wget to download UnRen payload." >&2
    return 1
}

_unren_bootstrap_release_sha256() {
    local script_dir="${1:?}"
    local payload sums tmp url name expected

    payload="$(_unren_bootstrap_payload_dir "$script_dir")"
    sums="${payload}/.download-SHA256SUMS-desktop"
    tmp="${sums}.part"
    url="$(_unren_bootstrap_checksums_url)"
    name="$(_unren_bootstrap_bundle_name)"

    echo "  Fetching checksums: ${url}" >&2
    mkdir -p "$payload"
    if ! _unren_bootstrap_download "$url" "$tmp"; then
        rm -f "$tmp"
        return 1
    fi
    mv -f "$tmp" "$sums"

    expected="$(awk -v name="$name" '
        {
            file = $2
            sub(/^\*/, "", file)
            sub(/^\.\//, "", file)
            if (file == name) {
                print $1
                found = 1
                exit
            }
        }
        END { if (!found) exit 1 }
    ' "$sums")" || {
        echo "[!] Checksum file did not contain ${name}." >&2
        return 1
    }
    printf '%s\n' "$expected"
}

_unren_bootstrap_extract() {
    local archive="${1:?}" dest="${2:?}"
    mkdir -p "$dest"
    rm -rf "${dest:?}/"*
    if ! tar -xJf "$archive" -C "$dest" --strip-components=1 2>/dev/null; then
        rm -rf "${dest:?}/"*
        tar -xJf "$archive" -C "$dest"
    fi
}

_unren_bootstrap_install() {
    local script_dir="${1:?}"
    local payload url archive expected sha_file tmp local_archive=0

    payload="$(_unren_bootstrap_payload_dir "$script_dir")"
    if [[ -n "${UNREN_BOOTSTRAP_ARCHIVE:-}" && -f "${UNREN_BOOTSTRAP_ARCHIVE}" ]]; then
        local_archive=1
    fi

    expected="${UNREN_BUNDLE_SHA256:-}"
    sha_file="$(_unren_bootstrap_sha256_file "$script_dir")"
    [[ -z "$expected" && -n "$sha_file" ]] && expected="$sha_file"
    if [[ -z "$expected" && "$local_archive" == 0 ]]; then
        expected="$(_unren_bootstrap_release_sha256 "$script_dir")" || return 1
    fi
    mkdir -p "$payload"

    if [[ "$local_archive" == 1 ]]; then
        archive="${UNREN_BOOTSTRAP_ARCHIVE}"
        echo "  Using local archive: ${archive}" >&2
    else
        url="$(_unren_bootstrap_bundle_url)"
        archive="${payload}/.download-$(_unren_bootstrap_bundle_name)"
        echo "  Installing UnRen payload (${UNREN_BUNDLE}) ..." >&2
        echo "  URL: ${url}" >&2
        mkdir -p "$payload"
        tmp="${archive}.part"
        if ! _unren_bootstrap_download "$url" "$tmp"; then
            rm -f "$tmp"
            return 1
        fi
        mv -f "$tmp" "$archive"
    fi
    if [[ -n "$expected" || "$local_archive" == 0 ]]; then
        _unren_bootstrap_verify_sha256 "$archive" "$expected" || return 1
    else
        echo "  Warning: local archive has no SHA256; set UNREN_BUNDLE_SHA256 to verify it." >&2
    fi
    _unren_bootstrap_extract "$archive" "$payload" || return 1
    rm -f "${payload}/.download-"*.tar.xz 2>/dev/null || true
    if ! _unren_bootstrap_verify_license_files "$payload"; then
        echo "[!] Download incomplete — license files missing. Refusing to run." >&2
        return 1
    fi
    printf '%s\n' "${expected}" > "${payload}/.unren-bundle.sha256" 2>/dev/null || true
    echo "  Payload ready: ${payload}" >&2
    return 0
}

_unren_resolve_install_root() {
    local script_dir="${1:?}"
    local payload

    if [[ -f "${script_dir}/unren/config.sh" ]]; then
        printf '%s\n' "$script_dir"
        return 0
    fi

    payload="$(_unren_bootstrap_payload_dir "$script_dir")"
    if [[ -f "${payload}/unren/config.sh" ]]; then
        printf '%s\n' "$payload"
        return 0
    fi

    if [[ -n "${UNREN_BOOTSTRAP_SKIP:-}" ]]; then
        echo "[!] UnRen payload missing and UNREN_BOOTSTRAP_SKIP is set." >&2
        return 1
    fi

    if _unren_bootstrap_install "$script_dir"; then
        printf '%s\n' "$payload"
        return 0
    fi

    cat >&2 <<EOF
[!] Could not install UnRen-Desktop payload.

Place a full copy here:
  ${script_dir}/unren/config.sh

Or allow download-on-first-run (needs curl or wget):
  export UNREN_BUNDLE=slim    # or full (includes sdk/)
  ./UnRen.sh

Release: ${UNREN_RELEASE_TAG} from ${UNREN_RELEASE_REPO}
EOF
    return 1
}
