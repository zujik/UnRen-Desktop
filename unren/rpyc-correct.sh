# rpycCorrector pre-pass (AON/SC4X v1.04, py3 port)

_unren_has_mangled_rpyc() {
    local script="${UNREN_APP}/renpy/script.py"
    [[ -f "$script" ]] || return 1
    env -u PYTHONHOME -u PYTHONPATH python3 - "$script" <<'PY'
import sys

path = sys.argv[1]
sig = None
enc = None
with open(path, encoding="utf-8", errors="replace") as fh:
    for line in fh:
        if line.startswith("RPYC2_HEADER") and sig is None:
            q = '"' if '"' in line else "'"
            sig = line[line.find(q) + 1 : line.rfind(q)]
        stripped = line.strip()
        if stripped == "data = zlib.compress(data, 9)":
            enc = "original"
        elif 'zlib.compress(data, 9).encode("hex")' in line:
            enc = "nbd"
        elif stripped == 'f.write(struct.pack("IIII", 0, 0, 0, 0))':
            enc = "nkt"
if sig != "RENPY RPC2" or enc != "original":
    raise SystemExit(0)
raise SystemExit(1)
PY
}

unren_rpyc_correct() {
    local py="${UNREN_RPA_PYTHON-}" rc

    if [[ ! -f "${UNREN_APP}/renpy/script.py" ]]; then
        echo "  rpycCorrector: no renpy/script.py — skipping signature fix."
        echo
        return 0
    fi

    if [[ -z "$py" ]]; then
        py="$(unren_resolve_rpatool_python)"
    fi

    echo "  Running rpycCorrector (mangled RPYC signature / encoding fix)..."
    echo

    pushd "${UNREN_APP}" >/dev/null || return 1
    set +e
    env -u PYTHONHOME -u PYTHONPATH "$py" "${RPYCCORRECT}" 2>&1 | awk '
        /\r/ { next }
        /^Searching for the used/ { next }
        /^Signature:/ { next }
        /^Encoding :/ { next }
        /Things gone wrong/ { if (length) print "  > "$0; next }
        { if (length) print "  > "$0 }
    '
    rc=$?
    set -e
    popd >/dev/null || return 1

    if (( rc != 0 )); then
        echo
        echo "  rpycCorrector finished with exit ${rc} (may mean files were not altered)."
        echo
    fi
    return 0
}
