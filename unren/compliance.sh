# UnRen-Desktop — runtime license compliance (see manifest.json)

_unren_verify_compliance() {
    local py="${PYTHON3:-python3}"
    local verifier="${UNREN_ROOT}/scripts/verify_compliance.py"

    if [[ ! -f "$verifier" ]]; then
        return 0
    fi
    if ! command -v "$py" >/dev/null 2>&1; then
        echo "[!] python3 not found — skipping compliance audit." >&2
        return 0
    fi

    "$py" "$verifier" "${UNREN_ROOT}"
}
