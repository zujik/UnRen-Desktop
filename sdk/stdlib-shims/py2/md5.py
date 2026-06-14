"""Legacy md5 module for Ren'Py py2 SDK-launched games.

Ren'Py's trimmed python2.7 stdlib ships _md5.so but omits the deprecated md5
wrapper. Old games (e.g. Planet Stronghold) still do ``import md5``.
"""
import _md5

blocksize = 64
digest_size = 16


def new(arg=None):
    return _md5.new(arg)


def md5(arg=None):
    return new(arg)
