# Setup

You need three things:

1. **hcc**, the HolyC compiler from [Jamesbarford/holyc-lang](https://github.com/Jamesbarford/holyc-lang). It uses the system C compiler to assemble and link, so you need gcc or clang too.
2. **SDL2**, the shared library.
3. **An OpenGL 3.3 core driver.** Any GPU from the last decade, Mesa included.

The configuration the project is developed and tested on:

| Component | Version |
|---|---|
| OS | Arch Linux x86_64, KDE Plasma (Wayland) |
| hcc | v0.0.15-beta, commit `06ca611` (2026-09-06) |
| SDL2 | 2.32 (sdl2-compat) |
| GPU / driver | Intel RPL-S, Mesa 26.2, GL 4.6 core |
| C toolchain | gcc 16.2 |

The macOS and Windows steps below follow the hcc and SDL2 documentation but have not been run for this project yet. Reports are welcome.

## 1. Install build tools

=== "Linux"

    ```sh
    # Debian / Ubuntu
    sudo apt install build-essential cmake git
    # Fedora
    sudo dnf install gcc make cmake git
    # Arch
    sudo pacman -S base-devel cmake git
    ```

=== "macOS"

    ```sh
    xcode-select --install
    brew install cmake
    ```

=== "Windows (WSL2)"

    In an administrator PowerShell:

    ```powershell
    wsl --install -d Ubuntu
    ```

    Reboot, open the Ubuntu shell, and run everything after this point inside it:

    ```sh
    sudo apt install build-essential cmake git
    ```

## 2. Build and install hcc

=== "Linux / WSL2"

    ```sh
    git clone https://github.com/Jamesbarford/holyc-lang.git
    cd holyc-lang
    make
    sudo make install
    make unit-test
    ```

=== "macOS"

    ```sh
    git clone https://github.com/Jamesbarford/holyc-lang.git
    cd holyc-lang
    make
    make install      # add sudo if /usr/local is not writable
    make unit-test
    ```

    On Apple Silicon hcc emits native AArch64 code.

### Installing without root

The install prefix is compiled into hcc, so it has to be passed at build time as well as install time:

```sh
mkdir -p ~/.local/bin ~/.local/lib ~/.local/include
make INSTALL_PREFIX=$HOME/.local
make install
```

`~/.local/lib` must exist before `make install`, or copying `libtos` fails. Make sure `~/.local/bin` is on your `PATH`.

If cmake isn't available from your package manager, `uv tool install cmake` or `pipx install cmake` installs a working copy to `~/.local/bin`.

### Check it works

```sh
hcc --version
printf 'U0 Main()\n{\n  "hello from hcc\\n";\n}\n' > hello.HC
hcc hello.HC -o hello && ./hello
```

## 3. Install SDL2

=== "Linux / WSL2"

    | Distro | Command |
    |---|---|
    | Debian / Ubuntu / WSL2 | `sudo apt install libsdl2-dev` |
    | Fedora | `sudo dnf install SDL2-devel` |
    | Arch | `sudo pacman -S sdl2` (or `sdl2-compat`) |

=== "macOS"

    ```sh
    brew install sdl2
    ```

The game reads no C headers. Its SDL2 and OpenGL declarations are written in HolyC. The `-dev` packages are still the easiest way to get the unversioned `libSDL2.so` that the linker looks for.

OpenGL comes with the system: `libGL` from Mesa or your GPU vendor on Linux, `OpenGL.framework` on macOS.

## 4. Check OpenGL (WSL2 and Linux)

```sh
sudo apt install mesa-utils        # or your distro's equivalent
glxinfo -B | grep "OpenGL core profile version"
```

You need 3.3 or higher. On WSL2 this goes through Mesa's D3D12 driver; current Windows builds report 4.x.

Next: [Build and test](build.md).
