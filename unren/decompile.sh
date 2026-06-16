# Decompile .rpyc files with unrpyc (Python 3)

_unren_decompile_roots() {
    local _roots_var="$1"
    local -a _roots=()
    local d
    eval "$_roots_var=()"
    for d in "${UNREN_APP}/game" "${UNREN_GAME}"; do
        [[ -d "$d" ]] || continue
        d="$(cd -P -- "$d" 2>/dev/null && pwd)" || continue
        if ((${#_roots[@]} > 0)) && _unren_list_contains "$d" "${_roots[@]}"; then
            continue
        fi
        _roots+=("$d")
    done
    if [[ "${UNREN_GAME}" != */game && -d "${UNREN_GAME}/game" ]]; then
        d="$(cd -P -- "${UNREN_GAME}/game" 2>/dev/null && pwd)" || d=""
        if [[ -n "$d" ]] && { ((${#_roots[@]} == 0)) || ! _unren_list_contains "$d" "${_roots[@]}"; }; then
            _roots+=("$d")
        fi
    fi
    _unren_array_copy_ref "$_roots_var" _roots
}

_unren_decompile_primary_root() {
    local -a roots=()
    _unren_decompile_roots roots
    if [[ ${#roots[@]} -gt 0 ]]; then
        printf '%s\n' "${roots[0]}"
        return 0
    fi
    printf '%s\n' "${UNREN_GAME}"
}

_unren_decompile_find() {
    local -a roots=()
    local root
    _unren_decompile_roots roots
    for root in "${roots[@]}"; do
        find "$root" \( -name '*.rpyc' -o -name '*.rpymc' \) -type f -print0 2>/dev/null
    done
}

_unren_decompile_is_unren_patch() {
    case "${1##*/}" in
        unren-*.rpyc|unren-*.rpymc) return 0 ;;
    esac
    return 1
}

_unren_decompile_has_rpyc() {
    local hit=
    while IFS= read -r -d '' hit || [[ -n "${hit:-}" ]]; do
        [[ -n "$hit" && -f "$hit" ]] && return 0
    done < <(_unren_decompile_find)
    return 1
}

_unren_decompile_relpath() {
    local rpyc="$1"
    local -a roots=()
    local root
    _unren_decompile_roots roots
    for root in "${roots[@]}"; do
        if [[ "$rpyc" == "${root}/"* ]]; then
            printf '%s\n' "${rpyc#"${root}/"}"
            return 0
        fi
    done
    printf '%s\n' "$(basename "$rpyc")"
}

_unren_decompile_auto_opts() {
    local _opts_var="$1"
    local major py_major has_sl1=0 opt
    eval "local -a _opts=(\"\${${_opts_var}[@]}\")"

    for opt in "${_opts[@]}"; do
        [[ "$opt" == "--sl1-as-python" ]] && has_sl1=1
    done

    if (( ! has_sl1 )); then
        major="$(_unren_script_version_major_from_app "$UNREN_APP")"
        py_major="$(_unren_guess_python_major "$UNREN_APP" "$(_unren_renpy_platform)")"
        if [[ "$py_major" == "2" || "$major" -lt 7 ]]; then
            _opts+=(--sl1-as-python)
            echo "  Ren'Py ${major}/py${py_major}: enabling --sl1-as-python (screen language v1)" >&2
            echo >&2
        fi
    fi
    eval "$_opts_var=(\"\${_opts[@]}\")"
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

_unren_decompile_targets() {
    local want_clobber=$1
    local force_all=$2
    local _out_var="$3"
    local -a _out=()
    local rpyc rel source

    while IFS= read -r -d '' rpyc; do
        _unren_decompile_is_unren_patch "$rpyc" && continue
        source="$(_unren_decompile_source_path "$rpyc")"
        if [[ ! -f "$source" ]]; then
            rel="$(_unren_decompile_relpath "$rpyc")"
            _out+=("$rel")
            continue
        fi
        if (( force_all )); then
            rel="$(_unren_decompile_relpath "$rpyc")"
            _out+=("$rel")
            continue
        fi
        if (( want_clobber )) && _unren_rpy_is_stub "$source"; then
            rel="$(_unren_decompile_relpath "$rpyc")"
            _out+=("$rel")
            continue
        fi
    done < <(_unren_decompile_find)
    eval "$_out_var=(\"\${_out[@]}\")"
}

unren_decompile() {
    local -a opts=() targets=() searched=()
    local unrpyc_py py_runner=() rc want_clobber=0 force_all=0 skipped=0 try_harder=0
    local decompile_root dir unren_kept=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clobber) want_clobber=1 ;;
            --try-harder) try_harder=1; opts+=("$1") ;;
            *) opts+=("$1") ;;
        esac
        shift
    done

    [[ "${UNREN_DECOMPILE_CLOBBER:-0}" == "1" ]] && want_clobber=1
    [[ "${UNREN_DECOMPILE_FORCE_ALL:-0}" == "1" ]] && force_all=1
    (( want_clobber )) && opts+=(--clobber)

    if unren_guard_skip_decompile; then
        return 0
    fi

    if _unren_has_rpc3_rpyc && [[ "${UNREN_DECOMPILE_RPC3:-}" != 1 ]]; then
        echo "  RPC3 bytecode — decompile skipped (sources are unreliable on RPC3 games)."
        echo "  Launch with g to run from .rpyc. Set UNREN_DECOMPILE_RPC3=1 to force decompile anyway."
        echo
        return 0
    fi

    decompile_root="$(_unren_decompile_primary_root)"

    if ! _unren_decompile_has_rpyc; then
        echo "  No .rpyc files found. Searched:"
        _unren_decompile_roots searched
        for dir in "${searched[@]}"; do
            echo "    ${dir}"
        done
        echo
        return 0
    fi

    if (( ! force_all )); then
        while IFS= read -r -d '' rpyc; do
            if _unren_decompile_is_unren_patch "$rpyc"; then
                (( unren_kept++ )) || true
                continue
            fi
            source="$(_unren_decompile_source_path "$rpyc")"
            [[ -f "$source" ]] || continue
            if (( want_clobber )); then
                _unren_rpy_is_stub "$source" || (( skipped++ )) || true
            else
                (( skipped++ )) || true
            fi
        done < <(_unren_decompile_find)
    else
        while IFS= read -r -d '' rpyc; do
            _unren_decompile_is_unren_patch "$rpyc" && (( unren_kept++ )) || true
        done < <(_unren_decompile_find)
    fi

    _unren_decompile_targets "$want_clobber" "$force_all" targets
    if [[ ${#targets[@]} -eq 0 ]]; then
        if (( try_harder && skipped > 0 )); then
            if _unren_has_rpc3_rpyc; then
                echo "  All compiled scripts already have matching .rpy/.rpym (${skipped} file(s))."
                echo "  RPC3 bytecode — skipping --try-harder force overwrite (launch from .rpyc)."
                echo
                return 0
            fi
            echo "  All compiled scripts already have matching .rpy/.rpym (${skipped} file(s))."
            echo "  Running --try-harder deobfuscate pass (overwriting existing sources)."
            echo
            force_all=1
            want_clobber=1
            opts+=(--clobber)
            skipped=0
            _unren_decompile_targets "$want_clobber" "$force_all" targets
        fi
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
    fi

    if (( skipped > 0 )); then
        echo "  Keeping ${skipped} existing .rpy/.rpym file(s); decompiling ${#targets[@]} file(s)"
        echo
    elif (( ! want_clobber )); then
        echo "  Skipping .rpyc/.rpymc with existing .rpy/.rpym (${#targets[@]} file(s) to decompile)"
        echo
    fi

    if (( unren_kept > 0 )); then
        echo "  Keeping UnRen patch sources (${unren_kept} unren-*.rpyc skipped)"
        echo
    fi

    unren_forall_rpyc_version_warn
    unren_wos_decrypt_if_needed

    {
        local renpy_major py_major
        renpy_major="$(_unren_script_version_major_from_app "$UNREN_APP")"
        py_major="$(_unren_guess_python_major "$UNREN_APP" "$(_unren_renpy_platform)")"
        echo "  Game: Ren'Py ${renpy_major}/py${py_major}"
        if (( renpy_major > 0 && renpy_major < 8 )); then
            echo "  unrpyc targets Ren'Py 8 — Ren'Py ${renpy_major} version notices summarized (not repeated per file)"
        fi
        echo
    }

    _unren_decompile_auto_opts opts

    if (( try_harder )); then
        if _unren_has_rpc3_rpyc; then
            echo "  rpycCorrector: RPC3 bytecode — skipping."
            echo
        elif _unren_has_mangled_rpyc; then
            unren_rpyc_correct
        else
            echo "  rpycCorrector: standard RPYC signatures — skipping."
            echo
        fi
    fi

    unrpyc_py="$(unren_resolve_unrpyc_python)"
    if [[ "$unrpyc_py" != "$UNREN_PYTHON" ]]; then
        py_runner=(env -u PYTHONHOME -u PYTHONPATH)
        echo "  Using ${unrpyc_py} for decompile (faster parallel unrpyc)"
        echo
    fi

    local errortemp
    errortemp="$(mktemp "${TMPDIR:-/tmp}/unren-rpyc.XXXXXX")"
    pushd "$decompile_root" >/dev/null || return 0
    set +e
    "${py_runner[@]}" "$unrpyc_py" "$UNRPYC" "${opts[@]}" "${targets[@]}" >"$errortemp" 2>&1
    rc=$?
    set -e
    awk '
        /^Warning: analysis found signs that this .rpyc file was generated by ren/ { rpyc_ver++; skip=3; next }
        /^Unknown AST node:/ { unknown++; next }
        /^Warning: Encountered a user-defined displayable/ { displayable++; skip=5; next }
        skip > 0 { skip--; next }
        !/^Co.*exec_prefix/ && !/^Traceback/ && !/^  File / && !/^ModuleNotFoundError/ && !/^The multiprocessing module/ && !/Attempting to deobfuscate/ && !/strategy extract_slot_/ {
            if (length) print "  > "$0
        }
        END {
            if (rpyc_ver) {
                print "  > (" rpyc_ver " Ren'\''Py 6/7 vs unrpyc-8 notice(s) suppressed — decompile continued; real errors still shown)"
            }
            if (unknown) {
                print "  > (" unknown " Unknown AST node warning(s) — custom game statements; see docs/TESTING.md)"
            }
            if (displayable) {
                print "  > (" displayable " custom displayable warning(s) — substituted style names)"
            }
        }
    ' "$errortemp"
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
    if ! declare -F unren_decompile_fixes >/dev/null 2>&1 \
        && [[ -f "${UNREN_ROOT}/unren/decompile-fixes.sh" ]]; then
        # shellcheck source=unren/decompile-fixes.sh
        source "${UNREN_ROOT}/unren/decompile-fixes.sh"
    fi
    if declare -F unren_decompile_fixes >/dev/null 2>&1; then
        unren_decompile_fixes
    fi
    return 0
}
