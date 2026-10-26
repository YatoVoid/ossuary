#!/usr/bin/env bash
# Uploads a packaged build to itch.io with butler.
#   ITCHIO_API_KEY=... build/scripts/publish-itch.sh 0.1.0
# Run package-release.sh with the same version first. The key is passed
# to butler through its environment and never printed.
set -euo pipefail

version="${1:?usage: publish-itch.sh <version>}"
target="${ITCH_TARGET:-yatovoid/ossuary-holyc}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
stage="$root/build/release/ossuary-$version-linux-x86_64"

if [ -z "${ITCHIO_API_KEY:-}" ]; then
  cat >&2 <<'EOF'
ITCHIO_API_KEY is not set.
Create a key at https://itch.io/user/settings/api-keys and export it:
  export ITCHIO_API_KEY=...        (don't commit it or paste it anywhere public)
EOF
  exit 1
fi
if ! command -v butler >/dev/null 2>&1; then
  echo "butler not found. Install it: https://itch.io/docs/butler/installing.html" >&2
  exit 1
fi
if [ ! -d "$stage" ]; then
  echo "no package for $version. Run: build/scripts/package-release.sh $version" >&2
  exit 1
fi

export BUTLER_API_KEY="$ITCHIO_API_KEY"
if ! butler push "$stage" "$target:linux" --userversion "$version" --if-changed; then
  cat >&2 <<EOF

Upload failed. Common causes:
  - "invalid game": $target doesn't exist, or the key's account doesn't own it.
    Create the project on itch.io first, or set ITCH_TARGET=user/game.
  - 401/403: the key is wrong, revoked, or lacks upload permission.
EOF
  exit 1
fi
butler status "$target:linux"
