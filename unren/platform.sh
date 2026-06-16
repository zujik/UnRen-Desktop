# Cross-platform helpers (Linux + macOS)

is_osx() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
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

_unren_machine() {
    uname -m
}

# Map a game path or .app bundle to the Ren'Py autorun root (game/ + renpy/ live here).
_unren_renpy_autorun_root() {
    local target="$1"
    [[ -n "$target" && -e "$target" ]] || return 1
    if [[ -e "${target}/Contents/Resources/autorun/game" ]]; then
        printf '%s\n' "${target}/Contents/Resources/autorun"
        return 0
    fi
    if [[ -e "${target}/Contents/Resources/game" &&
          ( -e "${target}/Contents/Resources/renpy" || -e "${target}/Contents/Resources/renpy.py" ) ]]; then
        printf '%s\n' "${target}/Contents/Resources"
        return 0
    fi
    if [[ -e "${target}/renpy" && -e "${target}/game" ]]; then
        printf '%s\n' "$target"
        return 0
    fi
    return 1
}

# Bash 3.2 compatibility (macOS /bin/bash).
_unren_tolower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

_unren_toupper() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

_unren_list_contains() {
    local needle="$1" x
    shift
    for x in "$@"; do
        [[ "$x" == "$needle" ]] && return 0
    done
    return 1
}

_unren_read_lines_to_array() {
    local _var="$1" line
    shift
    eval "$_var=()"
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        eval "$_var+=(\"\$line\")"
    done < <("$@")
}

_unren_canonical_path() {
    local f="$1" dir base
    if command -v realpath >/dev/null 2>&1; then
        realpath -s "$f" 2>/dev/null && return 0
    fi
    dir="$(cd -P "$(dirname "$f")" && pwd)"
    base="$(basename "$f")"
    printf '%s/%s\n' "$dir" "$base"
}
