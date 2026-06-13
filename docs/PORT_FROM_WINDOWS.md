# Port candidates from UnRen-forall (Windows)

Reference: `../../UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80/`

High value for UnRen-Desktop (not yet implemented):

| Feature | Windows option | Notes |
|---------|----------------|-------|
| RPA rename `.org` not subfolder | current/legacy | Avoid duplicate labels; we use `.rpa.bak` |
| Encrypted / modified RPA headers | 7, altrpatool | WOS, JASON, SVAC — needs Python port |
| rpycCorrector pre-pass | before decompile | `misc/rpycCorrector_1.04` in archive |
| Ren'Py sync folder cleanup | n | `%APPDATA%/renpy/<game>/` |
| `detect_renpy_version.py` | auto | When `script_version` missing |
| Multi-option menu chains | e.g. `72k1` | Single-run pipeline strings |
| `.rpy.org` backup on decompile | 9.x | Compare decompile vs shipped `.rpy` |
| MC rename patch | forall launcher | Universal MC name change |
| Registry / drag-drop | Windows-only | Skip on Linux |

Lower priority: auto-update, 7z path, Chinese chcp, Windows Terminal hints.
