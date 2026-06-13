# UnRen-Desktop configuration (edit quick-save/load keys here)
# See: https://www.pygame.org/docs/ref/key.html#key-constants-label

UNREN_VERSION="2.0.0-alpha.1"
UNREN_VERSION_DATE="(20260613)"

QUICK_SAVE_KEY="${QUICK_SAVE_KEY:-K_F5}"
QUICK_LOAD_KEY="${QUICK_LOAD_KEY:-K_F9}"

MIN_GAME_PYVER=2007018

RPATOOL="${UNREN_ROOT}/tools/rpatool-py3/rpatool.py"
ALTRPATOOL="${UNREN_ROOT}/tools/altrpatool-py3/altrpatool.py"
RPYCCORRECT="${UNREN_ROOT}/tools/rpyccorrect-py3/rpyccorrect.py"
DETECT_RENPY_VERSION="${UNREN_ROOT}/tools/detect-renpy-version/detect_renpy_version.py"
FORALL_DIR="${UNREN_ROOT}/tools/forall"
DETECT_ARCHIVE="${FORALL_DIR}/detect_archive.py"
DETECT_RPA_EXT="${FORALL_DIR}/detect_rpa_ext.py"
DETECT_RPYC_VERSION="${FORALL_DIR}/detect_rpyc_version.py"
WOS_DECRYPT_ALL="${FORALL_DIR}/wos_decrypt_all.py"
UNRPYC="${UNREN_ROOT}/tools/unrpyc-py3/unrpyc.py"
PATCHES_DIR="${UNREN_ROOT}/patches"
LAUNCHER_SH_TEMPLATE="${UNREN_ROOT}/unren/templates/renpy-desktop.sh"
LAUNCHER_PY_HEADER="${UNREN_ROOT}/unren/templates/renpy-desktop.py"

SDK_PY3_DIR="${UNREN_ROOT}/sdk/py3-8.5.3"
SDK_PY2_DIR="${UNREN_ROOT}/sdk/py2-7.8.7"
SDK_PY2_699_DIR="${UNREN_ROOT}/sdk/py2-6.99.14.3"
SDK_PY2_567_DIR="${UNREN_ROOT}/sdk/py2-5.6.7"
MANIFEST="${UNREN_ROOT}/manifest.json"
