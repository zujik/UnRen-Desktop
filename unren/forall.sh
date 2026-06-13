# UnRen-forall staging helpers (JoeLurmel / Lurmel)
# https://github.com/Lurmel/UnRen-forall — see tools/forall/ATTRIBUTION.md

_unren_forall_archive_extensions() {
    local -n _exts=$1
    local raw py="${UNREN_PYTHON}" line
    _exts=()
    [[ -x "$py" ]] || py="$(command -v python3 2>/dev/null || true)"
    [[ -n "$py" ]] || {
        _exts=(".rpa" ".jas" ".rpc")
        return 0
    }
    pushd "${UNREN_APP}" >/dev/null || return 1
    raw="$("$py" "${PYARGS[@]}" "${DETECT_RPA_EXT}" "${UNREN_APP}" 2>/dev/null)" || {
        popd >/dev/null || true
        _exts=(".rpa" ".jas" ".rpc")
        return 0
    }
    popd >/dev/null || true
    while IFS= read -r line; do
        [[ -n "$line" ]] && _exts+=("$line")
    done < <(env -u PYTHONHOME -u PYTHONPATH python3 -c "import ast,sys; [print(x) for x in ast.literal_eval(sys.argv[1])]" "$raw" 2>/dev/null)
    if [[ ${#_exts[@]} -eq 0 ]]; then
        _exts=(".rpa" ".jas" ".rpc")
    fi
}

_unren_forall_collect_archives() {
    local -n _files=$1
    local -a exts=() ext
    local dir f base lower canon
    declare -A _seen=()
    _files=()
    _unren_forall_archive_extensions exts
    for dir in "${UNREN_APP}" "${UNREN_GAME}"; do
        [[ -d "$dir" ]] || continue
        for ext in "${exts[@]}"; do
            lower="${ext,,}"
            for f in "${dir}"/*"${ext}" "${dir}"/*"${lower}" "${dir}"/*"${ext^^}"; do
                [[ -f "$f" ]] || continue
                base="$(basename "$f")"
                [[ "${base,,}" == *.org ]] && continue
                [[ "${base,,}" == *.bak ]] && continue
                canon="$(realpath -s "$f" 2>/dev/null || printf '%s' "$f")"
                [[ -n "${_seen[$canon]+x}" ]] && continue
                _seen[$canon]=1
                _files+=("$f")
            done
        done
    done
}

_unren_forall_pick_extractor() {
    local f="$1"
    if env -u PYTHONHOME -u PYTHONPATH python3 "${DETECT_ARCHIVE}" "$f" 2>/dev/null; then
        printf '%s\n' rpatool
    else
        printf '%s\n' altrpatool
    fi
}

unren_forall_rpyc_version_warn() {
    local rc
    pushd "${UNREN_APP}" >/dev/null || return 0
    set +e
    env -u PYTHONHOME -u PYTHONPATH python3 "${DETECT_RPYC_VERSION}" 2>&1 | sed 's/^/  /'
    rc=$?
    set -e
    popd >/dev/null || true
    if (( rc == 1 )); then
        echo "  Warning: RPC3/unknown bytecode — decompile may fail or need option 9."
        echo
    fi
    return 0
}

unren_wos_decrypt_if_needed() {
    local loader="${UNREN_APP}/renpy/wos_rpyc_loader.py"
    local py="${UNREN_PYTHON}" rc
    [[ -f "$loader" ]] || return 0
    [[ -x "$py" ]] || {
        echo "  ! WOS decrypt needs game Python (renpy/wos_rpyc_loader.py present)"
        return 1
    }
    echo "  WOS encryption detected — decrypting .rpyc under game/ ..."
    echo
    pushd "${UNREN_APP}" >/dev/null || return 1
    set +e
    UNREN_APP="${UNREN_APP}" "${py}" "${PYARGS[@]}" "${WOS_DECRYPT_ALL}" 2>&1 \
        | awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }'
    rc=$?
    set -e
    popd >/dev/null || return 1
    if (( rc != 0 )); then
        echo "  ! WOS decrypt finished with errors (exit ${rc})"
    fi
    echo
    return 0
}
