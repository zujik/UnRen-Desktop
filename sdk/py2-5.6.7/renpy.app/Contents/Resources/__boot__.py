def _argv_emulation():
    import sys
    # only use if started by LaunchServices
    for arg in sys.argv[1:]:
        if arg.startswith('-psn'):
            import argvemulator
            argvemulator.ArgvCollector().mainloop()
            break
_argv_emulation()


def _chdir_resource():
    import os
    os.chdir(os.environ['RESOURCEPATH'])
_chdir_resource()


def _disable_linecache():
    import linecache
    def fake_getline(filename, lineno):
        return ''
    linecache.orig_getline = linecache.getline
    linecache.getline = fake_getline
_disable_linecache()


def _run(*scripts):
    global __file__
    import os, sys, site
    sys.frozen = 'macosx_app'
    base = os.environ['RESOURCEPATH']
    site.addsitedir(base)
    site.addsitedir(os.path.join(base, 'Python', 'site-packages'))
    if not scripts:
        import __main__
    for script in scripts:
        path = os.path.join(base, script)
        sys.argv[0] = __file__ = path
        execfile(path, globals(), globals())


_run("Ren'Py Launcher.py")
