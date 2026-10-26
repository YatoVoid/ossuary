# Roadmap

## Done

- [x] hcc builds, installs and runs on Linux
- [x] SDL2 window, input and OpenGL 3.3 core context from pure HolyC
- [x] Grid level from an ASCII map with generated wall, floor and ceiling meshes
- [x] Procedural textures and bitmap font generated in HolyC
- [x] Point lighting, fog, low-resolution render target, post-processing
- [x] Player movement, mouse look, stamina, lantern
- [x] Warden AI with sight, hearing, BFS pathfinding and four behaviour states
- [x] Relics, gate, win and loss conditions
- [x] Title, pause and end screens, HUD
- [x] Headless gameplay test suite and render capture tool
- [x] Build scripts for Linux, macOS and Windows through WSL2

## Next

Ordered roughly by impact on the game.

- [ ] **Audio.** Footsteps, the warden's steps and breathing, the gate. SDL2's audio API is enough, and sound would do more for the horror than any visual change.
- [ ] **Confirm macOS and WSL2.** Run both build paths on real machines and fix whatever turns up.
- [ ] **CI for the game.** Build hcc and run `test.sh` on Linux in GitHub Actions.
- [ ] **Settings.** Mouse sensitivity, invert Y, key rebinding, saved to a file.
- [ ] **More levels.** The loader already takes any rectangular ASCII map; this needs a level list and a transition.
- [ ] **Fixed-timestep simulation.** Makes behaviour independent of frame rate and replays deterministic.

## Later

- [ ] Image file loading for textures (for example, uncompressed TGA, which is easy to parse in HolyC)
- [ ] Doors, hiding spots, and items that make noise elsewhere
- [ ] A second enemy type that uses the existing flow field differently
- [ ] Gamepad support through SDL's game controller API
- [ ] Upstream fixes to hcc for the float comparison and struct return bugs this project works around

## Not planned

- **TempleOS compatibility.** The project uses the language, not the operating system.
- **Native Windows build in this repo.** That depends on a Windows backend in hcc.
- **A general-purpose engine.** The code is organised so parts can be reused, but it stays shaped around this game until a second game needs it.
