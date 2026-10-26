#!/usr/bin/env bash
# Records the README preview from the game itself and encodes it to
# docs/media/preview.mp4 and docs/media/preview.gif. Needs hcc, SDL2 with
# a working OpenGL 3.3 driver, and ffmpeg.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$root/build/out"
media="$root/docs/media"
hcc="${HCC:-hcc}"

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found" >&2; exit 1; }

clibs=""
if [ "$(uname -s)" = "Darwin" ]; then
  clibs="-framework OpenGL"
fi

"$root/build/scripts/build-linux.sh" >/dev/null 2>&1 || "$root/build/scripts/build-macos.sh" >/dev/null
"$hcc" "$root/tests/preview_capture.HC" -o "$out/preview_capture" -clibs "$clibs"

frames="$(mktemp -d)"
trap 'rm -rf "$frames"' EXIT

# Offscreen keeps the capture window off the desktop; set
# PREVIEW_VIDEODRIVER=x11 (or wayland) if your driver can't do offscreen GL.
SDL_VIDEODRIVER="${PREVIEW_VIDEODRIVER:-offscreen}" "$out/preview_capture" "$frames/"

# The game's film grain changes every pixel every frame, which defeats
# both encoders; a light denoise cuts the GIF from ~16 MB to ~3 MB.
ffmpeg -loglevel error -y -framerate 30 -i "$frames/%05d.ppm" \
  -vf "scale=960:540:flags=area,hqdn3d=3:3:6:6" \
  -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p -movflags +faststart \
  "$media/preview.mp4"

ffmpeg -loglevel error -y -framerate 30 -i "$frames/%05d.ppm" \
  -vf "fps=12,scale=480:-2:flags=area,hqdn3d=8:8:14:14,split[a][b];[a]palettegen=max_colors=48:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
  "$media/preview.gif"

ls -lh "$media/preview.mp4" "$media/preview.gif"
