# Ossuary: itch.io page description

Paste everything below the line into **Edit game > Description**. itch.io's editor keeps headings, bold text and lists when pasted from a rendered view (open this file on GitHub and copy from there).

---

## Five relics. One gate. Something else down here.

You wake in a catacomb with a lantern. Five relics are hidden in its corridors, and taking the last one opens the iron gate out. Something tall walks the dark. It listens for footsteps, and it can see your lantern from the far end of a corridor.

Light the way and be seen. Douse it and feel along the walls by candlelight.

### What it is

Ossuary is a short first-person horror prototype with a single hand-built catacomb level and one enemy, the warden. It renders at 240p with wobbly PS1-style geometry, fog, film grain and dithering, and every texture is generated in code when the game starts.

It's also an experiment: the whole game is written in **HolyC**, the language from TempleOS. It's compiled for Linux with [hcc](https://github.com/Jamesbarford/holyc-lang) and draws through SDL2 and OpenGL. It doesn't need TempleOS or a VM.

### How to play

- Find all **five relics**. The counter in the bottom-left tracks them.
- Taking the last relic opens the **gate** in the far corner. Walk through it to escape.
- The **warden** wanders until it notices you. It hears footsteps, and running is much louder than walking. With your lantern lit it can see you from far away. In the dark it only sees what's right in front of it.
- **Running** drains stamina. Run dry and you're stuck walking until you catch your breath.
- If it reaches you, the run is over.

### Controls

| Key | Action |
|---|---|
| W A S D | Move |
| Mouse | Look |
| Arrow keys | Move and turn (playable without a mouse) |
| Shift | Run |
| F | Light / douse the lantern |
| Enter or Space | Start, resume, play again |
| Esc or P | Pause |
| Q | Back to title (from pause) |
| F3 | FPS counter |

### Features

- Stealth built around your light source: the lantern is both how you see and how you're seen
- A warden that wanders, investigates noise, and hunts by pathfinding through the level
- Sprinting and stamina, with footstep noise the warden can hear
- 240p retro rendering: vertex snapping, fog, a lantern plus candle point lights, grain, dithering, and a dread tint that rises as the warden gets close
- Procedurally generated brick, stone and cloth textures
- Pauses automatically when the window loses focus

### Build status

**Prototype, version 0.1.0.** One level, a run of a few minutes, no audio yet, no settings menu, and fixed key bindings. It's complete enough to play start to finish, so you can win or be caught. It's rough around the edges.

### System requirements

- **Linux x86_64** with glibc 2.34 or newer (Ubuntu 22.04+, Debian 12+, Fedora 35+, current Arch and Mint)
- **SDL2** and an **OpenGL 3.3** driver, which most desktops already have. If they're missing, `ossuary.sh` prints the install command for your distro.
- Unzip and run `./ossuary.sh`, or install through the itch app and press Launch.

There's no Windows or macOS download. The HolyC compiler can't produce Windows programs, so Windows players need WSL2 and must build from source. macOS builds from source but hasn't been tested.

### Source and docs

The full HolyC source, build instructions and design notes are on GitHub:

- Source: https://github.com/YatoVoid/ossuary
- Docs: https://yatovoid.github.io/ossuary/

Bug reports are welcome in the comments or as GitHub issues.

### Credits

- Game: YatoVoid
- HolyC compiler (hcc): James Barford
- HolyC and TempleOS: Terry A. Davis
- Libraries: SDL2, OpenGL

The game's code and this page were written with help from an AI assistant (Claude). All screenshots and the preview are captured from the game itself.
