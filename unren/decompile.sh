# Decompile .rpyc files with unrpyc (Python 3)

_unren_script_version_major() {
    local sv
    sv="$(grep -rh 'config\.script_version' "${UNREN_GAME}/script_version.rpy" "${UNREN_GAME}/script_version.txt" 2>/dev/null \
        | head -1 | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
    [[ -n "$sv" ]] && printf '%s\n' "$sv" || printf '0\n'
}

_unren_decompile_source_path() {
    local compiled=$1
    case "$compiled" in
        *.rpyc) printf '%s\n' "${compiled%.rpyc}.rpy" ;;
        *.rpymc) printf '%s\n' "${compiled%.rpymc}.rpym" ;;
    esac
}

_unren_rpy_is_stub() {
    local rpy=$1
    local bytes
    [[ -f "$rpy" ]] || return 1
    bytes=$(wc -c < "$rpy" 2>/dev/null | tr -d ' ')
    (( bytes < 10 )) && return 0
    grep -qiE '^(# )?(unrpyc|ERROR|failed to decompile)' "$rpy" 2>/dev/null && return 0
    return 1
}

_unren_decompile_auto_opts() {
    local -n _opts=$1
    local major py_major has_sl1=0 opt

    for opt in "${_opts[@]}"; do
        [[ "$opt" == "--sl1-as-python" ]] && has_sl1=1
    done

    if (( ! has_sl1 )); then
        major="$(_unren_script_version_major)"
        py_major="$(_unren_guess_python_major "$UNREN_APP" "$(_unren_renpy_platform)")"
        if [[ "$py_major" == "2" || "$major" -lt 7 ]]; then
            _opts+=(--sl1-as-python)
            echo "  Ren'Py ${major}/py${py_major}: enabling --sl1-as-python (screen language v1)" >&2
            echo >&2
        fi
    fi
}

_unren_decompile_targets() {
    local want_clobber=$1
    local force_all=$2
    local -n _out=$3
    local rpyc rel source

    _out=()

    while IFS= read -r -d '' rpyc; do
        source="$(_unren_decompile_source_path "$rpyc")"
        if [[ ! -f "$source" ]]; then
            rel="${rpyc#$UNREN_GAME/}"
            _out+=("$rel")
            continue
        fi
        if (( force_all )); then
            rel="${rpyc#$UNREN_GAME/}"
            _out+=("$rel")
            continue
        fi
        if (( want_clobber )) && _unren_rpy_is_stub "$source"; then
            rel="${rpyc#$UNREN_GAME/}"
            _out+=("$rel")
            continue
        fi
    done < <(find "$UNREN_GAME" \( -name '*.rpyc' -o -name '*.rpymc' \) -type f -print0 2>/dev/null)
}

unren_decompile() {
    local -a opts=() targets=()
    local unrpyc_py py_runner=() rc want_clobber=0 force_all=0 skipped=0
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--clobber" ]]; then
            want_clobber=1
        else
            opts+=("$1")
        fi
        shift
    done

    [[ "${UNREN_DECOMPILE_CLOBBER:-0}" == "1" ]] && want_clobber=1
    [[ "${UNREN_DECOMPILE_FORCE_ALL:-0}" == "1" ]] && force_all=1
    (( want_clobber )) && opts+=(--clobber)

    if ! find "$UNREN_GAME" \( -name '*.rpyc' -o -name '*.rpymc' \) -type f -print -quit 2>/dev/null | grep -q .; then
        echo "No .rpyc files found in ${UNREN_GAME}!"
        echo
        return 0
    fi

    if (( ! force_all )); then
        while IFS= read -r -d '' rpyc; do
            source="$(_unren_decompile_source_path "$rpyc")"
            [[ -f "$source" ]] || continue
            if (( want_clobber )); then
                _unren_rpy_is_stub "$source" || (( skipped++ )) || true
            else
                (( skipped++ )) || true
            fi
        done < <(find "$UNREN_GAME" \( -name '*.rpyc' -o -name '*.rpymc' \) -type f -print0 2>/dev/null)
    fi

    _unren_decompile_targets "$want_clobber" "$force_all" targets
    if [[ ${#targets[@]} -eq 0 ]]; then
        if (( skipped > 0 )); then
            echo "  All compiled scripts already have matching .rpy/.rpym — skipping decompile (${skipped} file(s))."
            echo "  Use UNREN_DECOMPILE_FORCE_ALL=1 to overwrite existing sources."
        else
            echo "  No compiled scripts to decompile."
        fi
        echo
        return 0
    fi

    if (( skipped > 0 )); then
        echo "  Keeping ${skipped} existing .rpy/.rpym file(s); decompiling ${#targets[@]} file(s)"
        echo
    elif (( ! want_clobber )); then
        echo "  Skipping .rpyc/.rpymc with existing .rpy/.rpym (${#targets[@]} file(s) to decompile)"
        echo
    fi

    _unren_decompile_auto_opts opts

    unrpyc_py="$(unren_resolve_unrpyc_python)"
    if [[ "$unrpyc_py" != "$UNREN_PYTHON" ]]; then
        py_runner=(env -u PYTHONHOME -u PYTHONPATH)
        echo "  Using ${unrpyc_py} for decompile (faster parallel unrpyc)"
        echo
    fi

    local errortemp
    errortemp="$(mktemp "${TMPDIR:-/tmp}/unren-rpyc.XXXXXX")"
    pushd "$UNREN_GAME" >/dev/null || return 0
    set +e
    "${py_runner[@]}" "$unrpyc_py" "$UNRPYC" "${opts[@]}" "${targets[@]}" >"$errortemp" 2>&1
    rc=$?
    set -e
    awk '!/^Co.*exec_prefix/ && !/^Traceback/ && !/^  File / && !/^ModuleNotFoundError/ && !/^The multiprocessing module/ && !/Attempting to deobfuscate/ && !/strategy extract_slot_/{ if (length) print "  > "$0 }' "$errortemp"
    if (( rc != 0 )); then
        echo
        echo "  Decompile finished with errors (exit ${rc})."
        awk '{ print "  ! "$0 }' "$errortemp" | tail -20
        echo
    elif grep -q "failed to decompile" "$errortemp" 2>/dev/null; then
        echo
        echo "  Decompile finished with some file failures (see summary above)."
        if (( force_all )); then
            echo "  Existing .rpy files are kept when a file fails under --clobber."
        fi
        echo
    fi
    rm -f "$errortemp"
    popd >/dev/null || return 0
    return 0
}
