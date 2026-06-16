#!/usr/bin/env bash
# UnRen-Desktop — Ren'Py unpack / decompile / patch tool for Linux and macOS
# Copyright (C) 2022-2026 Kijuz — licensed under GPL-3.0 (see LICENSE)
# https://github.com/zujik/UnRen-Desktop

# macOS ships Bash 3.2; UnRen needs Bash 4+ (namerefs, associative arrays).
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    for _unren_bash in /opt/homebrew/bin/bash /usr/local/bin/bash; do
        if [[ -x "$_unren_bash" ]]; then
            exec "$_unren_bash" "$0" "$@"
        fi
    done
    if [[ "$(uname -s)" == Darwin* ]]; then
        cat >&2 <<'EOF'
[!] UnRen-Desktop requires Bash 4+ (macOS includes Bash 3.2).

  brew install bash
  /opt/homebrew/bin/bash UnRen.command /path/to/game

Or upgrade the payload after: brew install bash
EOF
        exit 1
    fi
fi
unset _unren_bash

set -euo pipefail
set +H

UNREN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNREN_BOOTSTRAP_LOADED=""
for _unren_bootstrap_candidate in \
    "${UNREN_SCRIPT_DIR}/scripts/bootstrap.sh" \
    "${UNREN_SCRIPT_DIR}/unren-desktop/scripts/bootstrap.sh"; do
    if [[ -f "$_unren_bootstrap_candidate" ]]; then
        # shellcheck source=scripts/bootstrap.sh
        source "${_unren_bootstrap_candidate}"
        UNREN_BOOTSTRAP_LOADED=1
        break
    fi
done
unset _unren_bootstrap_candidate

if [[ -z "$UNREN_BOOTSTRAP_LOADED" ]]; then
# UNREN_BOOTSTRAP_INLINE_START
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
            [[ "$(basename -- "$slice")" == "stdlib-shims" ]] && continue
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
}

_unren_bootstrap_verify_sha256() {
    local archive="${1:?}" expected="${2:-}"
    local actual

    [[ -n "$expected" ]] || return 0
    if ! command -v sha256sum >/dev/null 2>&1; then
        echo "[!] sha256sum not found — skipping checksum verify." >&2
        return 0
    fi
    actual="$(sha256sum "$archive" | awk '{print $1}')"
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

_unren_bootstrap_extract() {
    local archive="${1:?}" dest="${2:?}"
    mkdir -p "$dest"
    if ! tar -xJf "$archive" -C "$dest" --strip-components=1 2>/dev/null; then
        rm -rf "${dest:?}/"*
        tar -xJf "$archive" -C "$dest"
    fi
}

_unren_bootstrap_replace_payload() {
    local payload="${1:?}" staging="${2:?}"
    local preserve="" item base

    mkdir -p "$payload"
    if [[ -d "${payload}/sdk" ]]; then
        preserve="$(mktemp -d "$(dirname "$payload")/.unren-sdk-preserve.XXXXXX")"
        mv "${payload}/sdk" "${preserve}/sdk"
    fi

    (
        shopt -s dotglob nullglob
        rm -rf "${payload:?}/"*
    )
    cp -a "${staging}/." "$payload/"

    if [[ -n "$preserve" && -d "${preserve}/sdk" ]]; then
        mkdir -p "${payload}/sdk"
        for item in "${preserve}"/sdk/py[23]-*; do
            [[ -e "$item" ]] || continue
            base="$(basename -- "$item")"
            [[ -e "${payload}/sdk/${base}" ]] && continue
            mv "$item" "${payload}/sdk/${base}"
        done
    fi
    [[ -n "$preserve" ]] && rm -rf "$preserve"
}

_unren_bootstrap_install() {
    local script_dir="${1:?}"
    local payload url archive expected sha_file tmp staging

    payload="$(_unren_bootstrap_payload_dir "$script_dir")"
    expected="${UNREN_BUNDLE_SHA256:-}"
    sha_file="$(_unren_bootstrap_sha256_file "$script_dir")"
    [[ -z "$expected" && -n "$sha_file" ]] && expected="$sha_file"
    mkdir -p "$payload"

    if [[ -n "${UNREN_BOOTSTRAP_ARCHIVE:-}" && -f "${UNREN_BOOTSTRAP_ARCHIVE}" ]]; then
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
    _unren_bootstrap_verify_sha256 "$archive" "$expected" || return 1
    staging="$(mktemp -d "$(dirname "$payload")/.unren-bootstrap.XXXXXX")"
    if ! _unren_bootstrap_extract "$archive" "$staging"; then
        rm -rf "$staging"
        return 1
    fi
    if ! _unren_bootstrap_verify_license_files "$staging"; then
        echo "[!] Download incomplete — license files missing. Refusing to run." >&2
        rm -rf "$staging"
        return 1
    fi
    _unren_bootstrap_replace_payload "$payload" "$staging"
    rm -rf "$staging"
    rm -f "${payload}/.download-"*.tar.xz 2>/dev/null || true
    [[ -n "$expected" ]] && printf '%s\n' "${expected}" > "${payload}/.unren-bundle.sha256" 2>/dev/null || true
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
# UNREN_BOOTSTRAP_INLINE_END
fi

UNREN_ROOT="$(_unren_resolve_install_root "${UNREN_SCRIPT_DIR}")" || exit 1
export UNREN_ROOT

if [[ ! -f "${UNREN_ROOT}/unren/config.sh" ]]; then
    cat >&2 <<EOF
Error: incomplete UnRen-Desktop install.

Missing: ${UNREN_ROOT}/unren/config.sh

Bootstrap mode (recommended):

  Linux — copy UnRen.sh into the game folder (alongside game/, lib/, renpy/):
    ./UnRen.sh
    or double-click UnRen.sh if your desktop allows executing scripts.

  macOS — save UnRen.command in ~/UnRen-Desktop (or your home folder):
    drag the game folder or .app onto UnRen.command
    (downloads UnRen.sh and unren-desktop/ on first run)

First run downloads tools into unren-desktop/ beside the script.
SDK slices download on demand for Windows-only games — press g to launch.

Full offline copy (forum / git clone):
  GameFolder/UnRen.sh  GameFolder/unren/  GameFolder/tools/  ...
EOF
    exit 1
fi

# shellcheck source=unren/config.sh
source "${UNREN_ROOT}/unren/config.sh"
# shellcheck source=unren/platform.sh
source "${UNREN_ROOT}/unren/platform.sh"
# shellcheck source=unren/sdk-resolve.sh
source "${UNREN_ROOT}/unren/sdk-resolve.sh"
# shellcheck source=unren/sdk-fetch.sh
source "${UNREN_ROOT}/unren/sdk-fetch.sh"
# shellcheck source=unren/runtime.sh
source "${UNREN_ROOT}/unren/runtime.sh"
# shellcheck source=unren/python-resolve.sh
source "${UNREN_ROOT}/unren/python-resolve.sh"
# shellcheck source=unren/patches.sh
source "${UNREN_ROOT}/unren/patches.sh"
# shellcheck source=unren/forall.sh
source "${UNREN_ROOT}/unren/forall.sh"
# shellcheck source=unren/extract.sh
source "${UNREN_ROOT}/unren/extract.sh"
# shellcheck source=unren/rpyc-correct.sh
source "${UNREN_ROOT}/unren/rpyc-correct.sh"
# shellcheck source=unren/decompile.sh
source "${UNREN_ROOT}/unren/decompile.sh"
# shellcheck source=unren/rpc3.sh
source "${UNREN_ROOT}/unren/rpc3.sh"
# shellcheck source=unren/game-guards.sh
source "${UNREN_ROOT}/unren/game-guards.sh"
# shellcheck source=unren/decompile-fixes.sh
source "${UNREN_ROOT}/unren/decompile-fixes.sh"
# shellcheck source=unren/extras.sh
source "${UNREN_ROOT}/unren/extras.sh"
# shellcheck source=unren/mac.sh
source "${UNREN_ROOT}/unren/mac.sh"
# shellcheck source=unren/launch-game.sh
source "${UNREN_ROOT}/unren/launch-game.sh"
# shellcheck source=unren/menu-state.sh
source "${UNREN_ROOT}/unren/menu-state.sh"
# shellcheck source=unren/compliance.sh
source "${UNREN_ROOT}/unren/compliance.sh"
# shellcheck source=unren/menu.sh
source "${UNREN_ROOT}/unren/menu.sh"

_unren_verify_compliance || true

unren_main "$@"
