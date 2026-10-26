#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$root/build/out"
hcc="${HCC:-hcc}"

if ! command -v "$hcc" >/dev/null 2>&1; then
  echo "hcc not found. Build it from https://github.com/Jamesbarford/holyc-lang (see docs/setup.md)" >&2
  exit 1
fi
if ! pkg-config --exists sdl2 2>/dev/null; then
  echo "SDL2 development files not found (try: libsdl2-dev, SDL2-devel, or sdl2)" >&2
  exit 1
fi

mkdir -p "$out"
rm -rf "$out/assets"
cp -R "$root/src/assets" "$out/assets"
rm -f "$out/assets/README.md"

cd "$root/src"
"$hcc" main.HC -o "$out/ossuary"

echo "built $out/ossuary"
echo "run:  $out/ossuary"
