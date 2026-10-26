# Controls

## Movement and actions

| Keys | Action |
|---|---|
| ++w++ ++a++ ++s++ ++d++ | Move |
| Mouse | Look |
| ++arrow-up++ / ++arrow-down++ | Move forward / back |
| ++arrow-left++ / ++arrow-right++ | Turn |
| ++shift++ | Run (drains stamina) |
| ++f++ | Light or douse the lantern |

The arrow keys turn and move on their own, so the game is playable without a mouse.

## Menus

| Keys | Title screen | Playing | Paused | End screens |
|---|---|---|---|---|
| ++enter++ or ++space++ | Start | | Resume | Play again |
| ++esc++ or ++p++ | Quit | Pause | Resume | Back to title |
| ++q++ | Quit | | Abandon run, back to title | Back to title |
| ++f3++ | FPS counter | FPS counter | FPS counter | FPS counter |

End screens ignore input for the first second so a held key doesn't skip them.

The game also pauses on its own when the window loses focus. The mouse is captured while playing and released in every menu.

## Changing bindings

Bindings are set in `InputInit` in `src/game/input/input.HC`. Each action takes a primary and an optional secondary SDL scancode:

```c
InputBind(in, ACT_FORWARD, SC_W, SC_UP);
InputBind(in, ACT_LANTERN, SC_F);
```

Scancode constants live in `src/runtime/platform/sdl_gl.HC`. They are physical key positions, so movement stays in the WASD position on AZERTY keyboards (where those keys are labelled Z, Q, S, D). There is no in-game rebinding menu yet.

Mouse sensitivity is `MOUSE_SENSITIVITY` in `src/game/world/player.HC`.
