# Extract RPA / JAS / RPC archives (forall detect + rpatool / altrpatool)

_unren_run_altrpatool() {
    local archive="$1" out_dir="${2:-.}" py rc rel_arch rel_out
    py="${UNREN_PYTHON}"
    [[ -x "$py" ]] || {
        echo "  ! altrpatool needs game/SDK Python (not found)"
        return 1
    }
    rel_arch="$(realpath -s "$archive")"
    rel_out="$(realpath -s "$out_dir")"
    echo "  Using altrpatool for $(basename "$archive") ..."
    pushd "${UNREN_APP}" >/dev/null || return 1
    set +e
    "${py}" "${PYARGS[@]}" "${ALTRPATOOL}" \
        -x "$(realpath --relative-to="${UNREN_APP}" "$rel_arch")" \
        -o "$(realpath --relative-to="${UNREN_APP}" "$rel_out")" -r 2>&1 \
        | awk '!/^Co.*exec_prefix/ && !/Could not extract file  from archive:/{ if (length) print "  > "$0 }'
    rc=$?
    set -e
    popd >/dev/null || return 1
    return "$rc"
}

_unren_run_rpatool() {
    local archive="$1" out_dir="${2:-$(dirname "$archive")}" rpatool_py py_runner=() base
    rpatool_py="$(unren_resolve_rpatool_python)"
    py_runner=(env -u PYTHONHOME -u PYTHONPATH)
    base="$(basename "$archive")"
    echo "  Using rpatool for ${base} ..."
    pushd "$out_dir" >/dev/null || return 1
    set +e
    "${py_runner[@]}" "$rpatool_py" "$RPATOOL" -x -v "$base" 2>&1 \
        | awk '!/^Co.*exec_prefix/ && !/Could not extract file  from archive:/{ if (length) print "  > "$0 }'
    local rc=$?
    set -e
    popd >/dev/null || return 1
    return "$rc"
}

_unren_run_extract_one() {
    local f="$1" tool rc arch_dir
    [[ -f "$f" ]] || return 1
    arch_dir="$(dirname "$f")"
    rc=0
    tool="$(_unren_forall_pick_extractor "$f")"
    if [[ "$tool" == altrpatool ]]; then
        _unren_run_altrpatool "$f" "$arch_dir" || rc=$?
    else
        _unren_run_rpatool "$f" "$arch_dir" || rc=$?
        if (( rc != 0 )) && [[ -f "$f" ]]; then
            echo "  rpatool failed — trying altrpatool ..."
            _unren_run_altrpatool "$f" "$arch_dir" || rc=$?
        fi
    fi
    return "$rc"
}

unren_extract() {
    local -a archives=() f rc renamed=0
    echo "  Searching for archives under ${UNREN_APP} (forall detect_rpa_ext)"
    echo

    _unren_forall_collect_archives archives
    if [[ ${#archives[@]} -eq 0 ]]; then
        echo "  No RPA/JAS/RPC packages found."
        echo
        return 0
    fi

    for f in "${archives[@]}"; do
        [[ -f "$f" ]] || continue
        echo "  Extracting ${f#"${UNREN_APP}/"} ..."
        rc=0
        _unren_run_extract_one "$f" || rc=$?
        if (( rc != 0 )); then
            echo "  ! Extraction failed (exit ${rc})"
            echo
            continue
        fi
        if [[ -z "${UNREN_KEEP_RPA:-}" ]]; then
            mv -f "$f" "${f}.bak"
            echo "  Renamed $(basename "$f") -> $(basename "$f").bak"
            renamed=1
        else
            echo "  Kept $(basename "$f") (UNREN_KEEP_RPA set)"
        fi
        echo
    done

    (( renamed )) || true
}
