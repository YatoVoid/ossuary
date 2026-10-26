# FAQ

## Setup and build

### `hcc: command not found`

hcc isn't on your `PATH`. With the default install it's in `/usr/local/bin`; with `INSTALL_PREFIX=$HOME/.local` it's in `~/.local/bin`. Either add that directory to `PATH` or point the scripts at the binary directly:

```sh
HCC=/path/to/hcc ./build/scripts/build-linux.sh
```

### `make install` fails copying `libtos.a`

The library directory under the install prefix doesn't exist yet. Create it and rerun:

```sh
mkdir -p ~/.local/lib ~/.local/include
make install
```

### `cannot find -lSDL2` at link time

The linker needs the unversioned `libSDL2.so`, which usually comes only with the development package: `libsdl2-dev` (Debian, Ubuntu, WSL2), `SDL2-devel` (Fedora), `sdl2` (Arch), `brew install sdl2` (macOS).

### `cannot find -ltos`

hcc links its standard library from the prefix it was built with. If you moved the install, rebuild hcc with the correct `INSTALL_PREFIX` or pass `--install-dir=<prefix>` to hcc.

### The window opens and closes with "OpenGL 3.3 core context unavailable"

Your driver doesn't provide GL 3.3 core. Check with `glxinfo -B`. Common causes: running on a software fallback in a VM, missing Mesa packages, or an old WSL without WSLg. Updating WSL (`wsl --update`) usually fixes the last one.

### `fatal: missing shader source`

The game couldn't find `assets/shaders/` next to its executable. Run the build script again, which copies `src/assets` to `build/out/assets`, or copy the directory yourself if you moved the binary.

### `cmake` isn't available and I can't install packages

`uv tool install cmake` or `pipx install cmake` installs it to `~/.local/bin` without root.

## Platforms

### Is there a native Windows build?

No. hcc generates assembly for Linux and macOS only and has no Windows backend, so there is no `.exe`. The game builds and runs inside WSL2, and WSLg shows the window on the Windows desktop with GPU acceleration. `build/scripts/build-windows.ps1` wraps this.

A native Windows build would need either a Windows target in hcc or a working HolyC-to-C path. hcc's `-transpile` mode exists but is experimental and emits POSIX headers.

### Does it work on Apple Silicon?

hcc supports AArch64 macOS, SDL2 is in Homebrew, and macOS still ships OpenGL 4.1 core, so it should. It hasn't been tested yet. Please report results.

### Can this run on TempleOS?

No. It uses SDL2 and OpenGL from the host OS and HolyC as implemented by hcc. TempleOS has neither library, and its own graphics and system APIs aren't available here. See [What it is not](index.md#what-it-is-not).

## Code

### My float comparison doesn't work

Probably an hcc bug, not your logic. See [hcc compiler rules](contributing.md#hcc-compiler-rules). The short version: compare floats only against float values (`0.0`, not `0`), and use float comparisons only directly inside `if` or `while`.

### Why is everything in one translation unit?

hcc compiles one input file into one program, and HolyC code conventionally includes source directly. `src/ossuary.HC` lists every file in dependency order. See [Project layout](architecture.md#project-layout).

### Why are there no image files?

Textures are generated in HolyC at startup and the font is a byte table in `src/game/ui/font.HC`. It keeps the repository small and shows HolyC doing real work. Loading image files is on the [roadmap](roadmap.md).
