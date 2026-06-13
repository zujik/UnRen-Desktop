# Cross-platform helpers (Linux + macOS)

is_osx() {
    [[ "$(uname -s)" == "Darwin" ]]
}

unren_session_uses_wayland() {
    [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]
}

unren_base64_decode() {
    if is_osx; then
        base64 --decode
    else
        base64 -d
    fi
}

stat_file_size() {
    if is_osx; then
        stat -f '%z' "$1" 2>/dev/null
    else
        stat -c '%s' "$1" 2>/dev/null
    fi
}

stat_file_name() {
    if is_osx; then
        stat -f '%N' "$1" 2>/dev/null
    else
        stat -c '%n' "$1" 2>/dev/null
    fi
}

unren_die() {
    printf -- '%s\n\n' "$*" >&2
    exit 1
}
