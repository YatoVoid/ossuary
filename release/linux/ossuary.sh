#!/bin/sh
# Starts Ossuary, or explains which system library is missing instead of
# failing with a bare loader error.
here="$(dirname "$(readlink -f "$0")")"

missing="$(ldd "$here/ossuary" 2>/dev/null | awk '/not found/ { print $1 }')"
if [ -n "$missing" ]; then
  echo "Ossuary can't start because these libraries are missing:" >&2
  for lib in $missing; do echo "  $lib" >&2; done
  cat >&2 <<'EOF'

Install SDL2 and OpenGL for your distribution:
  Debian / Ubuntu / Mint:  sudo apt install libsdl2-2.0-0 libgl1
  Fedora:                  sudo dnf install SDL2 mesa-libGL
  Arch / Manjaro:          sudo pacman -S sdl2-compat mesa
  openSUSE:                sudo zypper install libSDL2-2_0-0 Mesa-libGL1
EOF
  exit 1
fi

exec "$here/ossuary" "$@"
