# Release checklist

## Before tagging

- [ ] `build/scripts/test.sh` passes (`28 checks, 0 failed` or more)
- [ ] Played one run start to finish: take all five relics, escape through the gate
- [ ] Played one losing run: the warden catches you and the end screen shows
- [ ] Pause, focus-loss pause, lantern toggle and running all work
- [ ] If the visuals changed: `build/scripts/make-preview.sh`, then refresh `release/itch/screenshots/` and `cover.png`
- [ ] README, `docs/`, `release/itch/page.md` and `release/linux/README.txt` agree on features, controls and requirements

## Package

- [ ] `build/scripts/package-release.sh <version>` (for example `0.1.1`)
- [ ] It prints `needs: GLIBC_2.34` or lower. If it's higher, build on an older distro (Ubuntu 22.04 container or CI) so players on older systems can run it.
- [ ] Unzip `build/release/ossuary-<version>-linux-x86_64.zip` somewhere else, run `./ossuary.sh` from a different directory, and confirm the game starts

## Publish

- [ ] `export ITCHIO_API_KEY=...` (a key from https://itch.io/user/settings/api-keys; never commit it)
- [ ] `build/scripts/publish-itch.sh <version>`
- [ ] `butler status yatovoid/ossuary-holyc:linux` shows the new version with a ✓ build
- [ ] Download it from the itch.io page on a second machine or a clean VM and launch it
- [ ] Update the page's "Build status" line and post a devlog with the changes
- [ ] `git tag v<version> && git push --tags`, and optionally attach the zip to a GitHub release

## Never

- Commit an API key, put one in a script, or paste one into an issue or chat
- Upload screenshots or video that didn't come from the game
- List a platform that hasn't been built and launched
