UnRen-Desktop — quick guide
============================

After first run you may see:

  UnRen.sh
  unren-desktop/          (tools; SDK slices land in unren-desktop/sdk/)

macOS
-----
Download UnRen.command and save it in your home folder, or a folder you use
often (for example ~/UnRen-Desktop).

Drag your game folder or .app onto UnRen.command. On first run it downloads
what it needs (UnRen.sh and unren-desktop/), opens a terminal, and shows the
menu — extract archives, decompile scripts, enable dev options, and more.

Press g to run the game, even if you only have a Windows build. UnRen-Desktop
downloads a Ren'Py SDK slice on demand to launch it on macOS.

Linux
-----
Download UnRen.sh and save it in your game folder. You should see game/, lib/,
and renpy/ there already.

Double-click UnRen.sh (if your desktop allows executing scripts), or run from
a terminal:

  ./UnRen.sh

First run downloads unren-desktop/ beside the script, then shows the menu —
extract, decompile, patches, and more. Press g to run the game, even on a
Windows-only download; UnRen fetches an SDK slice when needed.

https://github.com/zujik/UnRen-Desktop
