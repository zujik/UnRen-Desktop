#!/usr/bin/env python3
"""Runtime license compliance audit for UnRen-Desktop.

Parses manifest.json, verifies per-dependency license files exist and contain
expected markers, and optionally re-downloads missing assets from the UnRen-Dependencies
mirror when UNREN_MIRROR_DOWNLOAD=1 (default).
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


LICENSE_MARKERS: dict[str, list[str]] = {
    "MIT": ["Permission is hereby granted"],
    "GPL-3.0": ["GNU GENERAL PUBLIC LICENSE", "GPL"],
    "BSD-2-Clause": ["Anne O'nymous", "Redistribution and use"],
    "WTFPL": ["WTFPL", "Do What The Fuck"],
}


def _load_manifest(root: Path) -> dict[str, Any]:
    manifest_path = root / "manifest.json"
    if not manifest_path.is_file():
        raise SystemExit(f"[!] manifest.json not found: {manifest_path}")
    with manifest_path.open(encoding="utf-8") as fh:
        return json.load(fh)


def _license_ok(path: Path, license_type: str) -> bool:
    if not path.is_file():
        return False
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    if len(text.strip()) < 40:
        return False
    markers = LICENSE_MARKERS.get(license_type, [])
    if not markers:
        return True
    lowered = text.lower()
    return all(m.lower() in lowered for m in markers)


def _verify_rpyc_source_header(root: Path, dep: dict[str, Any]) -> bool:
    header_file = dep.get("source_header_file")
    if not header_file:
        return True
    path = root / header_file
    if not path.is_file():
        return False
    try:
        head = path.read_text(encoding="utf-8", errors="replace")[:2500]
    except OSError:
        return False
    return (
        "Anne O'nymous" in head
        and "Redistribution and use" in head
        and "DISCLAIMED" in head
    )


def _download(url: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(url, timeout=60) as resp:
            data = resp.read()
        dest.write_bytes(data)
        return True
    except (urllib.error.URLError, OSError, TimeoutError) as exc:
        print(f"    Download failed ({url}): {exc}", file=sys.stderr)
        return False


def _redownload_dependency(root: Path, name: str, dep: dict[str, Any]) -> bool:
    license_url = dep.get("license_download_url", "")
    license_rel = dep.get("expected_license_file", "")
    if not license_url or not license_rel:
        print(f"    No mirror URL configured for {name}.", file=sys.stderr)
        return False

    license_path = root / license_rel
    print(f"    Fetching license: {license_url}")
    if not _download(license_url, license_path):
        return False

    archive_url = dep.get("download_url", "")
    tool_rel = dep.get("tool_path", "")
    if archive_url and tool_rel:
        archive_name = archive_url.rsplit("/", 1)[-1]
        staging = root / ".unren-compliance-cache" / name / archive_name
        print(f"    Fetching tool archive: {archive_url}")
        if _download(archive_url, staging):
            print(
                f"    Archive saved to {staging} — extract manually or extend "
                "bootstrap unpack when UnRen-Dependencies releases are live."
            )
        else:
            print("    Tool archive download failed; license file was refreshed.")

    return _license_ok(license_path, dep.get("license_type", ""))


def verify_compliance(root: Path, *, allow_mirror: bool = True) -> int:
    manifest = _load_manifest(root)
    block = manifest.get("compliance_block") or manifest.get("compliance") or {}
    project_license = block.get("project_license", "unknown")
    print(f"Auditing tool safety and compliance (project: {project_license})...")

    for req in block.get("required_files", []):
        req_path = root / req
        if not req_path.is_file():
            print(f"[!] Required project file missing: {req}")
            if allow_mirror:
                print("    Project bundle incomplete — cannot guarantee compliance.")
            return 1
        print(f"[✓] {req}")

    dependencies: dict[str, Any] = manifest.get("dependencies") or {}
    if not dependencies:
        print("[!] No dependencies block in manifest.json")
        return 1

    failures = 0
    for name, dep in dependencies.items():
        license_rel = dep.get("expected_license_file", "")
        license_type = dep.get("license_type", "")
        license_path = root / license_rel if license_rel else None

        ok = license_path is not None and _license_ok(license_path, license_type)
        if name == "rpyc_corrector" and ok:
            ok = _verify_rpyc_source_header(root, dep)

        if ok:
            print(f"[✓] {name} verified and compliant.")
            continue

        failures += 1
        label = license_rel or "(no path)"
        print(f"[!] Warning: License missing or invalid for {name} ({label}).")

        if not allow_mirror:
            continue

        print("    Initiating secure re-download to guarantee compliance...")
        if _redownload_dependency(root, name, dep):
            if name == "rpyc_corrector":
                if not _verify_rpyc_source_header(root, dep):
                    print(
                        f"[!] {name}: BSD-2-Clause source header check failed in "
                        f"{dep.get('source_header_file')}. Preserve Anne O'nymous "
                        "copyright in tools/rpyccorrect-py3/rpyccorrect.py."
                    )
                    failures += 1
                else:
                    failures -= 1
                    print(f"[✓] {name} re-verified after download.")
            else:
                failures -= 1
                print(f"[✓] {name} re-verified after download.")
        else:
            print(f"[!] Could not restore compliance for {name}.")

    if failures > 0:
        print(f"\nCompliance audit finished with {failures} issue(s).")
        strict = os.environ.get("UNREN_STRICT_COMPLIANCE", "").strip() in ("1", "yes", "true")
        return 1 if strict else 0

    print("\nCompliance audit passed.")
    return 0


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    root = Path(argv[0]).resolve() if argv else Path.cwd()
    allow_mirror = os.environ.get("UNREN_MIRROR_DOWNLOAD", "1").strip() not in (
        "0",
        "no",
        "false",
    )
    return verify_compliance(root, allow_mirror=allow_mirror)


if __name__ == "__main__":
    raise SystemExit(main())
