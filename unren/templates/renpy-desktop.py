# UnRen-Desktop launcher bootstrap (unren/templates/renpy-desktop.py)
#
# Installed as GameName.py beside GameName.sh. Always launch via GameName.sh.
#
# The body below is copied from the matching SDK renpy.py at install time.
# Re-run UnRen option g, 8, or 9 to regenerate.
#
# Display overrides (set before running GameName.sh):
#   SDL_VIDEODRIVER=x11      force X11 / XWayland (useful on Wayland desktops)
#   SDL_VIDEODRIVER=wayland  try native Wayland (modern py3 Linux builds)
#   UNREN_SDL_VIDEODRIVER=…  same as SDL_VIDEODRIVER when SDL_VIDEODRIVER is unset
#
# Legacy py2 / SDK-fallback games auto-set SDL_VIDEODRIVER=x11 on Wayland sessions
# inside GameName.sh to avoid "wayland not available" startup crashes.
# py3 games: no override — SDL autodetects Wayland or X11.
