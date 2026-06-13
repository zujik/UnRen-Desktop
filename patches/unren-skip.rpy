init 999 python:
    _preferences.skip_unseen = True
    renpy.game.preferences.skip_unseen = True
    renpy.config.allow_skipping = True
    renpy.config.fast_skipping = True
    try:
        config.keymap['skip'] = [ 'K_LCTRL', 'K_RCTRL' ]
    except:
        pass
