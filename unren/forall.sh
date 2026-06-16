# UnRen-forall staging helpers (JoeLurmel / Lurmel)
# https://github.com/Lurmel/UnRen-forall — see tools/forall/ATTRIBUTION.md

_unren_forall_archive_extensions() {
    local _exts_var="$1"
    local raw py="${UNREN_PYTHON}" line
    local -a _exts=()
    [[ -x "$py" ]] || py="$(command -v python3 2>/dev/null || true)"
    if [[ -z "$py" ]]; then
        _exts=(".rpa" ".jas" ".rpc")
        eval "$_exts_var=(\"\${_exts[@]}\")"
        return 0
    fi
    pushd "${UNREN_APP}" >/dev/null || return 1
    raw="$("$py" "${PYARGS[@]}" "${DETECT_RPA_EXT}" "${UNREN_APP}" 2>/dev/null)" || {
        popd >/dev/null || true
        _exts=(".rpa" ".jas" ".rpc")
        eval "$_exts_var=(\"\${_exts[@]}\")"
        return 0
    }
    popd >/dev/null || true
    while IFS= read -r line; do
        [[ -n "$line" ]] && _exts+=("$line")
    done < <(env -u PYTHONHOME -u PYTHONPATH python3 -c "import ast,sys; [print(x) for x in ast.literal_eval(sys.argv[1])]" "$raw" 2>/dev/null)
    if [[ ${#_exts[@]} -eq 0 ]]; then
        _exts=(".rpa" ".jas" ".rpc")
    fi
    eval "$_exts_var=(\"\${_exts[@]}\")"
}

_unren_forall_collect_archives() {
    local _files_var="$1"
    local -a exts=() _files=() _seen=()
    local dir f base lower upper canon
    _unren_forall_archive_extensions exts
    for dir in "${UNREN_APP}" "${UNREN_GAME}"; do
        [[ -d "$dir" ]] || continue
        for ext in "${exts[@]}"; do
            lower="$(_unren_tolower "$ext")"
            upper="$(_unren_toupper "$ext")"
            for f in "${dir}"/*"${ext}" "${dir}"/*"${lower}" "${dir}"/*"${upper}"; do
                [[ -f "$f" ]] || continue
                base="$(basename "$f")"
                lower="$(_unren_tolower "$base")"
                [[ "$lower" == *.org ]] && continue
                [[ "$lower" == *.bak ]] && continue
                canon="$(_unren_canonical_path "$f")"
                _unren_list_contains "$canon" "${_seen[@]}" && continue
                _seen+=("$canon")
                _files+=("$f")
            done
        done
    done
    eval "$_files_var=(\"\${_files[@]}\")"
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
        echo "  Warning: RPC3/unknown bytecode — forced decompile can break sources; launch from .rpyc when possible."
        echo
    fi
    return 0
}

_unren_has_rpc3_rpyc() {
    _unren_is_rpc3_game "${UNREN_APP}"
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
