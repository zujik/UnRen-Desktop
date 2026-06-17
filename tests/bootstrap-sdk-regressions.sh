#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

make_sdk_slice() {
    local root="$1" slice="$2" lib="$3"
    mkdir -p "${root}/sdk/${slice}/${lib}"
    : > "${root}/sdk/${slice}/renpy.py"
    printf '#!/usr/bin/env sh\nexit 1\n' > "${root}/sdk/${slice}/${lib}/python"
    chmod +x "${root}/sdk/${slice}/${lib}/python"
}

# Copy a real SDK runtime + stdlib from the repo for smoke-test integration checks.
seed_sdk_slice_from_repo() {
    local dest_root="$1" slice="$2" lib="$3"
    local src_root="${ROOT}/sdk/${slice}"

    [[ -d "${src_root}/lib" ]] || return 1
    if [[ -d "${src_root}/lib/python3.12/encodings" ]]; then
        mkdir -p "${dest_root}/sdk/${slice}/lib"
        cp -a "${src_root}/lib/python3.12" "${dest_root}/sdk/${slice}/lib/"
    fi
    if [[ -d "${src_root}/lib/python2.7/encodings" ]]; then
        mkdir -p "${dest_root}/sdk/${slice}/lib"
        cp -a "${src_root}/lib/python2.7" "${dest_root}/sdk/${slice}/lib/"
    fi
    if [[ -d "${src_root}/${lib}" ]]; then
        mkdir -p "${dest_root}/sdk/${slice}/${lib}"
        cp -af "${src_root}/${lib}/." "${dest_root}/sdk/${slice}/${lib}/"
    fi
}

_test_sdk_platform() {
    case "$(uname -s)" in
        Darwin) printf 'mac-universal\n' ;;
        *) printf 'linux-x86_64\n' ;;
    esac
}

_test_py3_lib_dir() {
    case "$(_test_sdk_platform)" in
        mac-universal) printf 'lib/py3-mac-universal\n' ;;
        *) printf 'lib/py3-linux-x86_64\n' ;;
    esac
}

test_py3_does_not_use_stale_py2_slice() {
    local tmp app sdk_root sdk_lib platform py3_lib
    platform="$(_test_sdk_platform)"
    py3_lib="$(_test_py3_lib_dir)"
    tmp="$(mktemp -d)"

    app="${tmp}/game-root"
    UNREN_ROOT="${tmp}/unren-desktop"
    mkdir -p "${app}/game" "${UNREN_ROOT}"
    printf '8.0.0\n' > "${app}/game/script_version.txt"
    make_sdk_slice "$UNREN_ROOT" "py2-7.8.7" "lib/py2-linux-x86_64"

    # shellcheck source=../unren/sdk-resolve.sh
    source "${ROOT}/unren/sdk-resolve.sh"
    # shellcheck source=../unren/sdk-fetch.sh
    source "${ROOT}/unren/sdk-fetch.sh"

    if _unren_resolve_sdk_runtime "$app" 3 "$platform" sdk_root sdk_lib; then
        fail "resolved py3 game to stale py2 SDK: ${sdk_root} ${sdk_lib}"
    fi

    if ! UNREN_APP="$app" _unren_auto_fetch_sdk_enabled "$app" 3 "$platform"; then
        fail "auto-fetch was disabled by an unusable py2 SDK slice"
    fi

    make_sdk_slice "$UNREN_ROOT" "py3-8.5.3" "$py3_lib"
    seed_sdk_slice_from_repo "$UNREN_ROOT" "py3-8.5.3" "$py3_lib" ||
        fail "repo SDK missing py3-8.5.3 (git lfs pull)"
    _unren_resolve_sdk_runtime "$app" 3 "$platform" sdk_root sdk_lib ||
        fail "failed to resolve py3 SDK after it became available"
    [[ "$sdk_root" == "${UNREN_ROOT}/sdk/py3-8.5.3" ]] ||
        fail "resolved unexpected SDK root: ${sdk_root}"

    rm -rf "$tmp"
}

make_payload_tree() {
    local dest="$1" include_license="${2:-1}"
    mkdir -p "${dest}/unren" "${dest}/tools/altrpatool-py3"
    printf 'UNREN_VERSION="test"\n' > "${dest}/unren/config.sh"
    printf 'copying\n' > "${dest}/tools/altrpatool-py3/COPYING"
    if [[ "$include_license" == 1 ]]; then
        printf 'license\n' > "${dest}/LICENSE"
        printf 'notice\n' > "${dest}/NOTICE"
        printf 'third-party\n' > "${dest}/THIRD_PARTY_LICENSES.md"
    fi
}

make_payload_archive() {
    local source_dir="$1" archive="$2"
    tar -cJf "$archive" -C "$source_dir" .
}

test_bootstrap_preserves_sdk_and_rejects_partial_payloads() {
    local tmp script_dir payload good_src good_archive bad_src bad_archive
    tmp="$(mktemp -d)"

    script_dir="${tmp}/starter"
    payload="${script_dir}/unren-desktop"
    good_src="${tmp}/good"
    bad_src="${tmp}/bad"
    good_archive="${tmp}/good.tar.xz"
    bad_archive="${tmp}/bad.tar.xz"

    mkdir -p "${payload}/sdk/py2-7.8.7" "$script_dir"
    printf 'cached\n' > "${payload}/sdk/py2-7.8.7/sentinel"
    make_payload_tree "$good_src" 1
    mkdir -p "${good_src}/sdk/stdlib-shims/py2"
    printf 'shim\n' > "${good_src}/sdk/stdlib-shims/py2/md5.py"
    make_payload_tree "$bad_src" 0
    make_payload_archive "$good_src" "$good_archive"
    make_payload_archive "$bad_src" "$bad_archive"

    # shellcheck source=../scripts/bootstrap.sh
    source "${ROOT}/scripts/bootstrap.sh"

    export UNREN_PAYLOAD_DIR="$payload" UNREN_BOOTSTRAP_ARCHIVE="$good_archive"
    _unren_bootstrap_install "$script_dir" ||
        fail "good payload did not install"
    [[ -f "${payload}/sdk/py2-7.8.7/sentinel" ]] ||
        fail "slim reinstall removed cached SDK slice"
    [[ -f "${payload}/sdk/stdlib-shims/py2/md5.py" ]] ||
        fail "slim reinstall lost packaged SDK support files"

    rm -rf "${payload}/unren"
    export UNREN_BOOTSTRAP_ARCHIVE="$bad_archive"
    if _unren_bootstrap_install "$script_dir"; then
        fail "bad payload without license files installed successfully"
    fi
    [[ ! -e "${payload}/unren/config.sh" ]] ||
        fail "failed bootstrap left a valid-looking config.sh"
    [[ -f "${payload}/sdk/py2-7.8.7/sentinel" ]] ||
        fail "failed bootstrap removed cached SDK slice"

    rm -rf "$tmp"
}

test_py3_does_not_use_stale_py2_slice
test_app_bundle_script_version_and_mac_sdk() {
    local tmp app sdk_root sdk_lib major
    tmp="$(mktemp -d)"

    app="${tmp}/Hollow.app/Contents/Resources/autorun"
    UNREN_ROOT="${tmp}/unren-desktop"
    mkdir -p "${app}/game" "${UNREN_ROOT}"
    printf '8.0.0\n' > "${app}/game/script_version.txt"
    make_sdk_slice "$UNREN_ROOT" "py3-8.5.3" "lib/py3-mac-universal"
    seed_sdk_slice_from_repo "$UNREN_ROOT" "py3-8.5.3" "lib/py3-mac-universal" ||
        fail "repo SDK missing py3-8.5.3 stdlib (git lfs pull)"

    # shellcheck source=../unren/platform.sh
    source "${ROOT}/unren/platform.sh"
    # shellcheck source=../unren/sdk-resolve.sh
    source "${ROOT}/unren/sdk-resolve.sh"

    major="$(_unren_script_version_major_from_app "${tmp}/Hollow.app")"
    [[ "$major" == 8 ]] ||
        fail "app bundle major was ${major}, expected 8"

    if ! _unren_resolve_sdk_runtime "$app" 3 mac-universal sdk_root sdk_lib; then
        _unren_resolve_sdk_runtime "$app" 3 linux-x86_64 sdk_root sdk_lib ||
            fail "SDK smoke test failed (need git lfs pull on this platform)"
    fi
    [[ "$sdk_lib" == *py3-mac-universal* || "$sdk_lib" == *py3-linux-x86_64* ]] ||
        fail "unexpected lib dir: ${sdk_lib}"

    rm -rf "$tmp"
}
test_app_bundle_script_version_and_mac_sdk
test_decompile_empty_targets_bash32() {
    local tmp targets
    tmp="$(mktemp -d)"

    UNREN_APP="${tmp}/game"
    UNREN_GAME="${UNREN_APP}/game"
    mkdir -p "$UNREN_GAME"

    # shellcheck source=../unren/platform.sh
    source "${ROOT}/unren/platform.sh"
    # shellcheck source=../unren/decompile.sh
    source "${ROOT}/unren/decompile.sh"

    _unren_decompile_targets 0 0 targets ||
        fail "_unren_decompile_targets failed on empty game tree"
    [[ ${#targets[@]} -eq 0 ]] ||
        fail "expected no decompile targets, got ${#targets[@]}"

    rm -rf "$tmp"
}
test_decompile_empty_targets_bash32
test_menu_all_patches_applied_bash32() {
    local tmp
    tmp="$(mktemp -d)"

    UNREN_ROOT="${ROOT}"
    UNREN_APP="${tmp}/game"
    UNREN_GAME="${UNREN_APP}/game"
    mkdir -p "$UNREN_GAME"
    touch "${UNREN_GAME}/unren-dev.rpy" "${UNREN_GAME}/unren-quick.rpy" \
        "${UNREN_GAME}/unren-skip.rpy" "${UNREN_GAME}/unren-rollback.rpy"

    UNREN_MENU_PATCH_DEV=1
    UNREN_MENU_PATCH_QUICK=1
    UNREN_MENU_PATCH_SKIP=1
    UNREN_MENU_PATCH_ROLLBACK=1
    UNREN_MENU_HAS_ARCHIVES=0
    UNREN_MENU_HAS_RPYC=0
    UNREN_MENU_HAS_RPC3=0
    UNREN_MENU_GUARD_IW=0

    # shellcheck source=../unren/platform.sh
    source "${ROOT}/unren/platform.sh"
    # shellcheck source=../unren/menu-state.sh
    source "${ROOT}/unren/menu-state.sh"

    _unren_menu_patch_nums_pending >/dev/null ||
        fail "patch nums pending crashed with all patches applied"
    _unren_menu_refresh_state ||
        fail "menu refresh crashed with all patches applied"

    rm -rf "$tmp"
}
test_menu_all_patches_applied_bash32
test_py2_699_sdk_smoke_mac() {
    local sdk_root lib_dir

    [[ -x "${ROOT}/sdk/py2-6.99.14.3/lib/darwin-x86_64/python" ]] || return 0
    [[ -d "${ROOT}/sdk/py2-6.99.14.3/lib/pythonlib2.7/encodings" ]] || return 0

    # shellcheck source=../unren/sdk-resolve.sh
    source "${ROOT}/unren/sdk-resolve.sh"

    sdk_root="${ROOT}/sdk/py2-6.99.14.3"
    lib_dir="${sdk_root}/lib/darwin-x86_64"
    _unren_sdk_runtime_usable "py2-6.99.14.3" "$sdk_root" "$lib_dir" ||
        fail "py2-6.99.14.3 darwin-x86_64 SDK failed smoke test (need -EO + pythonlib2.7)"
}
test_py2_699_sdk_smoke_mac
test_magic_shop_renpy_major() {
    local app major

    [[ -d "${ROOT}/../Downloads/Magic_Shop_1.03-win/renpy" ]] && \
        app="${ROOT}/../Downloads/Magic_Shop_1.03-win" || \
        app="${HOME}/Downloads/Magic_Shop_1.03-win"
    [[ -f "${app}/renpy/vc_version.py" ]] || return 0

    # shellcheck source=../unren/config.sh
    source "${ROOT}/unren/config.sh"
    # shellcheck source=../unren/sdk-resolve.sh
    source "${ROOT}/unren/sdk-resolve.sh"
    # shellcheck source=../unren/python-resolve.sh
    source "${ROOT}/unren/python-resolve.sh"

    major="$(_unren_script_version_major_from_app "$app")"
    [[ "$major" == 6 ]] || fail "Magic Shop major was ${major}, expected 6 (not vc_version build id)"
    [[ "$(_unren_guess_python_major "$app" mac-universal)" == 2 ]] ||
        fail "Magic Shop should resolve to py2"
}
test_magic_shop_renpy_major
test_bootstrap_preserves_sdk_and_rejects_partial_payloads

printf 'bootstrap-sdk-regressions: ok\n'
