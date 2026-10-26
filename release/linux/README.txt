OSSUARY  @VERSION@  (prototype)
First-person catacomb horror, written in HolyC.

RUN
  ./ossuary.sh
  (or ./ossuary directly; keep the assets folder next to it)

REQUIREMENTS
  Linux x86_64 with glibc 2.34 or newer
    (Ubuntu 22.04+, Debian 12+, Fedora 35+, Arch, Mint 21+)
  SDL2 and an OpenGL 3.3 driver. Most desktops already have both.
  If they're missing, ossuary.sh prints the install command for your distro.

GOAL
  Find the five relics in the catacomb. Taking the last one opens the
  iron gate in the south-east corner. Walk through it to escape.
  Something else walks the corridors. It hears you running and sees
  your lantern from a long way off.

CONTROLS
  W A S D         move
  Mouse           look
  Arrow keys      move forward/back and turn (playable without a mouse)
  Shift           run (drains stamina, and the warden hears it)
  F               light or douse the lantern
  Enter / Space   start, resume, play again
  Esc / P         pause
  Q               quit to title (from pause or end screens), quit (title)
  F3              FPS counter

KNOWN LIMITS
  One level, no audio, no settings menu. Bindings and mouse
  sensitivity are fixed in this build.

SOURCE, DOCS, ISSUES
  https://github.com/YatoVoid/ossuary
  https://yatovoid.github.io/ossuary/
