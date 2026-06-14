# UnRen-Desktop: stub for dev-only labels removed from release builds.
# Installed only when the game references Dev_Room but does not define it
# (common when unren-dev.rpy sets config.developer = True).

label Dev_Room:
    jump Prologue
