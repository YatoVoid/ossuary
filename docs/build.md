# Build and test

All commands run from the repository root.

## Build

=== "Linux"

    ```sh
    ./build/scripts/build-linux.sh
    ./build/out/ossuary
    ```

=== "macOS"

    ```sh
    ./build/scripts/build-macos.sh
    ./build/out/ossuary
    ```

=== "Windows (WSL2)"

    From PowerShell in the repository folder:

    ```powershell
    .\build\scripts\build-windows.ps1 -Run
    ```

    The script runs the Linux build inside WSL2 and launches the game there. Add `-Test` to run the test suite, and `-Distro Ubuntu` to pick a WSL distribution other than the default.

A build takes a few seconds. It produces:

```
build/out/
  ossuary          the game
  assets/shaders/  GLSL, copied from src/assets
```

The game locates `assets/` next to the executable through `SDL_GetBasePath()`, so it runs from any working directory as long as the two stay together.

### Using a different hcc

Set `HCC` to use a compiler that isn't on `PATH`:

```sh
HCC=~/src/holyc-lang/hcc ./build/scripts/build-linux.sh
```

### What the build does

The whole game is one translation unit. `src/main.HC` includes `src/ossuary.HC`, which includes every other file in dependency order. The script calls hcc once:

```sh
cd src && hcc main.HC -o ../build/out/ossuary
```

On Linux, `#link <SDL2>` and `#link <GL>` in the runtime files add `-lSDL2 -lGL` to the link line. macOS links OpenGL as a framework, so `build-macos.sh` passes `-clibs "-framework OpenGL"`.

## Test

```sh
./build/scripts/test.sh
```

This compiles and runs `tests/world_test.HC`, which drives the real gameplay code with scripted input and no window:

| Group | What it checks |
|---|---|
| Level | Map parses, five relics, warden and gate exist, exit sealed until the gate opens, every cell reachable after |
| Collision | Walking into a wall stops at the wall; walking at an angle slides along it |
| Stealth | Doused lantern unseen from behind, lit lantern seen, walking quiet and sprinting loud at the same distance, walls block sight |
| Failure path | An idle player in lantern light is caught within four seconds; the world stops simulating afterwards |
| Warden movement | Leaves spawn after the grace period, never ends up inside a wall |
| Main path | A bot walks the shortest path to all five relics, the gate stays shut until the last one, opens, alerts the warden, and walking out wins |

Expected output ends with:

```
28 checks, 0 failed
```

The test binary links SDL2 and OpenGL but never initialises them, so it runs on machines without a display.

## Render captures

`tests/render_capture.HC` renders a fixed set of scenes through the real renderer and writes each to a PPM image: title, spawn, relic with the lantern doused, warden hunting, gate open, pause, and the loss screen. Use it to review visual changes without playing. Run it with `SDL_VIDEODRIVER=offscreen` to keep the window off your desktop, or on a machine without a display, as long as the GL driver supports offscreen contexts (NVIDIA and Mesa do).

```sh
cd tests
hcc render_capture.HC -o ../build/out/render_capture
mkdir -p /tmp/shots
../build/out/render_capture /tmp/shots/
```

Convert to PNG with ImageMagick if your viewer doesn't read PPM:

```sh
for f in /tmp/shots/*.ppm; do magick "$f" "${f%.ppm}.png"; done
```

## Preview video

`build/scripts/make-preview.sh` records the README preview. It builds `tests/preview_capture.HC`, which runs the real game loop with scripted input through four staged shots (title, taking a relic, the gate opening, the warden in the dark), saves every frame, and encodes them with ffmpeg:

| File | Format | Used by |
|---|---|---|
| `docs/media/preview.gif` | 480x270, 12 fps, ~3 MB | the README (GitHub won't play a repo-relative MP4 inline) |
| `docs/media/preview.mp4` | 960x540, 30 fps, H.264, ~1.5 MB | the docs site, and as a download link |

```sh
./build/scripts/make-preview.sh
```

It needs ffmpeg. The capture is deterministic (fixed world seeds, fixed 60 Hz timestep), so rerunning it after a rendering change gives the same shots with the new look. Rerun it whenever the visuals change enough that the README would be out of date.

## Build these docs

```sh
pip install -r requirements-docs.txt
mkdocs serve          # live preview at http://127.0.0.1:8000
mkdocs build --strict # what CI runs
```

Pushes to `main` that touch `docs/`, `mkdocs.yml` or `requirements-docs.txt` deploy the site through `.github/workflows/pages.yml`. In the repository settings, set **Pages > Source** to **GitHub Actions** once.
