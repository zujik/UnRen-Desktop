# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0-alpha.1] - 2026-06-13

### Added

- Renamed project to **UnRen-Desktop** (Linux + macOS).
- `UnRen.command` macOS Finder wrapper.
- Modular `unren/` bash modules (renamed from `lib/` to avoid collision with Ren'Py's `lib/`), plain `tools/` and `patches/` (no base64).
- Trimmed Ren'Py SDK layout under `sdk/` with **Git LFS** for `lib/` and `renpy/` binaries.
- `manifest.json`, `THIRD_PARTY_LICENSES.md`, `scripts/populate-sdk.sh`, `scripts/build-release.sh`.
- Python 3 unrpyc v2 and updated rpatool from UnRen 0.9.0 fork.
- Game-first Python resolution with bundled SDK fallback (dikau-style game detection).

### Changed

- Decompile skips `.rpyc`/`.rpymc` when a matching `.rpy`/`.rpym` already exists (default for options 2, 8, 9). Option 0, `--clobber`, or `UNREN_DECOMPILE_CLOBBER=1` overwrites.
- `UnRen.sh` is now a thin entry point; removed broken apt/brew auto-install block.
- README rewritten for GitHub distribution.

### Removed

- `b64.file` embedded tool encoding (tools are plain files now).

## [1.0.9.9.1] - 2022-10-06

### Changed

- Renamed script without version number, UnRen-Linux-<version_number>.sh to UnRen-Linux.sh
- Moved version and versiondate to top of the file for easily checking version number
- Changed gamename in initial setup as it excludes the script by name, and the filename has changed to remove the version number [Line 237]
- Set x64 Python directory first, then will check others including 32bit

### Fixed

- Check if any RPA file in Game folder and advise "No RPA files found" instead of giving an Error
- Set PYTHONPATH correctly

## [1.0.9.9.0] - 2022-10-05

### Added

- Code to detect the Game script name, and the Game and Python files under the relevant LIB folder, and make them executable.
- Added all the License information as I could find and research.
- New Github repo made under MIT License as per original UnRen.bat.

### Changed

- rpatool code from UnRen-Ultrahackv9

### Fixed

- unren-skip.rpy not being created. The issue was not editing the lines when copying and pasting code so unren-skip.rpy was being overwritten by unren-rollback.rpy.

[comment]: ### Added
[comment]: ### Changed
[comment]: ### Fixed
[comment]: ### Removed