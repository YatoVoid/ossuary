# Assets

Only shaders live here. The build copies this directory next to the binary as `assets/`, and the game loads `assets/shaders/<name>.vert` and `.frag` at startup.

| File | Used for |
|---|---|
| `shaders/world.*` | Level and entity geometry: point lights, fog, vertex snapping |
| `shaders/post.*` | Upscale from the 240p scene target, vignette, dread tint, grain, dithering |
| `shaders/ui.*` | HUD and menu text and rectangles |

Textures and the font are generated in HolyC at startup (`src/game/render/texture.HC`, `src/game/ui/font.HC`). To use image files instead, add a loader that fills an `Image` and passes it to `TextureUpload`.

Shaders target GLSL 330 core so the same source runs on Linux, macOS (4.1 core), and WSLg.
