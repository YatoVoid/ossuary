# Contributing

## Workflow

1. Set up hcc and SDL2 ([Setup](setup.md)).
2. Branch from `main`.
3. Make the change. Keep HolyC as the language for anything that isn't a shader.
4. Run the tests and the game:

    ```sh
    ./build/scripts/test.sh
    ./build/scripts/build-linux.sh && ./build/out/ossuary
    ```

5. For visual changes, run the [render capture tool](build.md#render-captures) before and after and compare.
6. Open a pull request describing what changed and how you checked it. Include before and after captures for anything visual.

## hcc compiler rules

hcc v0.0.15-beta has bugs that compile cleanly and produce wrong results. The code follows these rules everywhere. New code must too.

| Don't | Do | Why |
|---|---|---|
| `if (speed > 0)` with a float | `if (speed > 0.0)` | Comparing a float to an integer literal truncates the float and compares unsigned. `2.7 > 2` is false. |
| `Bool fast = speed > 3.0;` | `if (speed > 3.0) fast = TRUE;` | A stored float comparison is always 0. |
| `return x < 1.5;` | `if (x < 1.5) return TRUE; return FALSE;` | Same bug. |
| `if (flag && x < 1.5)` | Nest the ifs | Rejected by the compiler. |
| `Check(a > b, ...)` with floats | Wrap in a helper that uses `if` | Passing the comparison as an argument stores it. |
| `Vec3 V3Add(Vec3 a, Vec3 b)` | `U0 V3Add(Vec3 *out, Vec3 *a, Vec3 *b)` | Returning a 12-byte float struct by value crashes. |
| `&some_extern_c_function` | Call it directly | Fails to link as a position-independent executable. |

Comparisons between integers are fine in every form. Float arithmetic with integer literals (`x * 2`) is fine. Also note HolyC has no `?:` operator.

A quick check for the first two patterns before committing:

```sh
grep -rnE '(<|>|<=|>=) -?[0-9]+[);]' src tests --include='*.HC'
```

Every hit should be an integer comparison.

## Code style

- Four-space indents in GLSL, two in HolyC, matching the existing files.
- Types and functions in `PascalCase` with a module prefix (`LevelMove`, `WardenUpdate`, `UiText`). Locals and fields in `snake_case`. Constants in `UPPER_SNAKE_CASE`.
- Constants as `#define`s at the top of the file that owns them.
- Comments only where the reason isn't obvious from the code: a constraint, a workaround, a convention another file depends on.
- New files go into `src/ossuary.HC` in dependency order.

## Where things go

| Change | Location |
|---|---|
| A new SDL2 or GL function | Declare it in `src/runtime/`. Wrap SDL calls in `window.HC` if game code needs them. |
| Gameplay rules or entities | `src/game/world/`. Keep GL calls out so tests still run headless. |
| Drawing something new | `src/game/render/renderer.HC` |
| A HUD element or menu | `src/game/ui/` |
| A new game state | `src/game/systems/state_machine.HC` and the switches in `game_loop.HC` |
| Level layout | `g_catacomb` in `src/game/world/level.HC`. Keep exactly one `P`, `W`, `G` and `X`. |

## Tests

Gameplay changes need a check in `tests/world_test.HC` covering the main path and at least one failure path. Tests poke `World` fields directly to set up a situation, then run `WorldUpdate` with scripted input.

After adding a check, break the code it covers and make sure the check fails. A check that can't fail isn't testing anything.

## Docs

The site is built from `docs/` with MkDocs Material. Preview with `mkdocs serve`. Pull requests that touch `docs/` run `mkdocs build --strict`, which fails on broken links. Keep instructions accurate to what has actually been run, and mark anything untested.
