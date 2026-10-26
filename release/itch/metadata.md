# itch.io metadata

Project: https://yatovoid.itch.io/ossuary-holyc (butler target `yatovoid/ossuary-holyc`).

butler can only upload builds. Everything on this page has to be entered by hand in **Edit game** on itch.io, because itch.io has no API for page content.

## Basics

| Field | Value |
|---|---|
| Title | Ossuary |
| Project URL | `ossuary-holyc` |
| Short description or tagline | Five relics. One gate. Something else down here. A first-person catacomb horror prototype written in HolyC. |
| Classification | Games |
| Kind of project | Downloadable |
| Release status | Prototype |
| Pricing | No payments, or Name your own price with a $0 minimum |

## Uploads

| File | Channel | Label | Platform checkbox |
|---|---|---|---|
| `ossuary-<version>-linux-x86_64` (pushed by butler) | `linux` | Ossuary <version>, Linux x86_64 | Linux |

butler marks the platform automatically from the channel name `linux`. Check that the upload shows the Linux icon. Leave Windows and macOS unticked.

## Details

| Field | Value |
|---|---|
| Genre | Survival |
| Tags (max 10) | horror, first-person, stealth, retro, psx, low-poly, atmospheric, short, singleplayer, holyc |
| AI generation disclosure | **Yes.** Code and text: written with an AI assistant. Graphics: no (all images are the game's own output). Sound: n/a (no audio). |
| App store links | none |
| Custom noun | leave blank |

## Metadata (More details)

| Field | Value |
|---|---|
| Made with | HolyC, hcc, SDL2, OpenGL |
| Inputs | Keyboard, Mouse |
| Accessibility | Playable without a mouse (arrow keys turn) |
| Average session | A few minutes |
| Languages | English |
| Multiplayer | none |
| Links | Source code: https://github.com/YatoVoid/ossuary; Documentation: https://yatovoid.github.io/ossuary/ |
| Community | Comments |
| Visibility | Draft until the page has been checked, then Public |

## Media

| Slot | File | Notes |
|---|---|---|
| Cover image (630x500) | `release/itch/cover.png` | warden frame from the capture with the game's own title logo |
| Screenshot 1 | `docs/media/preview.gif` | animated, 3 MB; itch.io plays GIF screenshots |
| Screenshots 2-7 | `release/itch/screenshots/01-title.png` … `06-taken.png` | 1280x720, straight from the renderer |
| Gameplay video or trailer | YouTube or Vimeo URL only | itch.io doesn't host video files. Upload `docs/media/preview.mp4` (unlisted is fine) and paste the link. Label it "Gameplay preview (staged in-engine capture)". |
| Theme | background `#0d0b0a`, text `#d8cdb6`, links `#3fc8b0` | matches the bone-and-relic colours of the in-game UI |

All media comes from `build/scripts/make-preview.sh` (game frames) plus the cover composite. Nothing is mocked up or stock.
