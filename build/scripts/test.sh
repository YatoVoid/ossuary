#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$root/build/out"
hcc="${HCC:-hcc}"

clibs=""
if [ "$(uname -s)" = "Darwin" ]; then
  clibs="-framework OpenGL"
fi

mkdir -p "$out"
cd "$root/tests"
"$hcc" world_test.HC -o "$out/world_test" -clibs "$clibs"
"$out/world_test"
