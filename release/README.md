# Releases

```text
release/
├── CHECKLIST.md          steps for every release
├── linux/                files copied into the Linux package
│   ├── ossuary.sh        launcher: checks for SDL2/GL, then runs the game
│   ├── .itch.toml        tells the itch app to launch ossuary.sh
│   └── README.txt        player-facing readme (@VERSION@ is filled in)
└── itch/                 itch.io page content
    ├── page.md           description to paste into the page editor
    ├── metadata.md       every page field: tags, genre, media slots
    ├── cover.png         630x500 cover
    └── screenshots/      1280x720 frames from the game

build/scripts/
├── package-release.sh    build, test, stage and zip  -> build/release/
└── publish-itch.sh       butler push to yatovoid/ossuary-holyc:linux
```

Build output goes to `build/release/`, which is ignored by git.

```sh
build/scripts/package-release.sh 0.1.0
ITCHIO_API_KEY=... build/scripts/publish-itch.sh 0.1.0
```

## Platforms

| Platform | Package | Why |
|---|---|---|
| Linux x86_64 | yes | built and tested |
| macOS | no | hcc supports it, but nobody has built or tested on a Mac yet |
| Windows | no | hcc can't produce Windows executables; WSL2 users build from source |

SDL2 isn't bundled. A copy taken from a recent distro depends on a newer glibc than the game itself, which would make the package fail on more systems, not fewer. Players install SDL2 from their distro instead, and the launcher tells them how.
