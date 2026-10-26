#!/usr/bin/env bash
# Builds the game and packages it for itch.io and GitHub releases.
#   build/scripts/package-release.sh 0.1.0
# Output: build/release/ossuary-<version>-linux-x86_64/ and a .zip of it.
set -euo pipefail

version="${1:?usage: package-release.sh <version, e.g. 0.1.0>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "only linux-x86_64 packages are built so far (this is $(uname -s)-$(uname -m))" >&2
  exit 1
fi
command -v zip >/dev/null 2>&1 || { echo "zip not found" >&2; exit 1; }

"$root/build/scripts/build-linux.sh" >/dev/null
"$root/build/scripts/test.sh" | tail -n 1

name="ossuary-$version-linux-x86_64"
release="$root/build/release"
stage="$release/$name"
rm -rf "$stage" "$release/$name.zip"
mkdir -p "$stage"

cp "$root/build/out/ossuary" "$stage/"
cp -R "$root/build/out/assets" "$stage/assets"
cp "$root/release/linux/ossuary.sh" "$root/release/linux/.itch.toml" "$stage/"
sed "s/@VERSION@/$version/" "$root/release/linux/README.txt" > "$stage/README.txt"
chmod 755 "$stage/ossuary" "$stage/ossuary.sh"

glibc="$(objdump -T "$stage/ossuary" | grep -oE 'GLIBC_[0-9.]+' | sort -Vu | tail -n 1)"
echo "needs: $glibc, $(ldd "$stage/ossuary" | awk '/SDL2|libGL\./ { printf "%s ", $1 }')"

(cd "$release" && zip -qr -X "$name.zip" "$name")
echo "packaged build/release/$name.zip ($(du -h "$release/$name.zip" | cut -f1))"
