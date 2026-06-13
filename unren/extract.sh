# Extract RPA / JAS / RPC archives (rpatool + altrpatool fallback)

_unren_archive_needs_altrpatool() {
    local f="$1" magic
    case "$f" in
        *.jas|*.JAS|*.rpc|*.RPC) return 0 ;;
    esac
    [[ -f "$f" ]] || return 1
    magic="$(head -c 16 "$f" 2>/dev/null | tr -d '\0')"
    [[ "$magic" == *RWA-* || "$magic" == *SVAC-* || "$magic" == *WOS* ]] && return 0
    return 1
}

_unren_run_altrpatool() {
    local archive="$1" out_dir="${2:-.}" py rc
    py="${UNREN_PYTHON}"
    [[ -x "$py" ]] || {
        echo "  ! altrpatool needs game/SDK Python (not found)"
        return 1
    }
    echo "  Using altrpatool for ${archive} ..."
    pushd "${UNREN_APP}" >/dev/null || return 1
    set +e
    "${py}" "${PYARGS[@]}" "${ALTRPATOOL}" -x "$archive" -o "$out_dir" -r 2>&1 \
        | awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }'
    rc=$?
    set -e
    popd >/dev/null || return 1
    return "$rc"
}

_unren_run_rpatool() {
    local f="$1" rpatool_py py_runner=()
    rpatool_py="$(unren_resolve_rpatool_python)"
    py_runner=(env -u PYTHONHOME -u PYTHONPATH)
    "${py_runner[@]}" "$rpatool_py" "$RPATOOL" -x -v "$f" 2>&1 \
        | awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }'
}

unren_extract() {
    local f rpatool_py py_runner=() rc renamed=0
    echo "  Searching for archives in ${UNREN_GAME}"
    echo

    pushd "$UNREN_GAME" >/dev/null || return 1

    if ! compgen -G "*.rpa" >/dev/null && \
       ! compgen -G "*.jas" >/dev/null && \
       ! compgen -G "*.JAS" >/dev/null && \
       ! compgen -G "*.rpc" >/dev/null && \
       ! compgen -G "*.RPC" >/dev/null; then
        echo "  No RPA/JAS/RPC packages found."
        popd >/dev/null || return 1
        return 0
    fi

    for f in *.rpa *.jas *.JAS *.rpc *.RPC; do
        [[ -f "$f" ]] || continue
        echo "  Extracting ${f} ..."
        rc=0
        if _unren_archive_needs_altrpatool "$f"; then
            _unren_run_altrpatool "$f" "." || rc=$?
        else
            _unren_run_rpatool "$f" || rc=$?
            if (( rc != 0 )); then
                echo "  rpatool failed — trying altrpatool ..."
                _unren_run_altrpatool "$f" "." || rc=$?
            fi
        fi
        if (( rc != 0 )); then
            echo "  ! Extraction failed for ${f} (exit ${rc})"
            echo
            continue
        fi
        case "$f" in
            *.rpa)
                if [[ -z "${UNREN_KEEP_RPA:-}" ]]; then
                    mv -f "$f" "${f}.bak"
                    echo "  Renamed ${f} -> ${f}.bak"
                    renamed=1
                else
                    echo "  Kept ${f} (UNREN_KEEP_RPA set)"
                fi
                ;;
            *)
                if [[ -z "${UNREN_KEEP_RPA:-}" ]]; then
                    mv -f "$f" "${f}.bak"
                    echo "  Renamed ${f} -> ${f}.bak"
                    renamed=1
                fi
                ;;
        esac
        echo
    done

    (( renamed )) || true
    popd >/dev/null || return 1
}
