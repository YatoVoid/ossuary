// Records the README preview: the real game loop and renderer, with
// scripted input in place of the keyboard. Every second 60 Hz frame is
// written as a numbered PPM, giving 30 fps footage.
//
// build/scripts/make-preview.sh builds this, runs it, and encodes the
// frames to MP4 and GIF.
#include "../src/ossuary.HC"

#define GL_RGB            0x1907
#define GL_PACK_ALIGNMENT 0x0D05
#define FRAME_DT          (1.0 / 60.0)

U8 *g_out_dir = "./";
I64 g_tick = 0;
I64 g_saved = 0;

U0 SaveFrame(Window *win)
{
  I64 w = win->width, h = win->height;
  I64 row = w * 3;
  U8 *pixels = MAlloc(row * h);
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glReadPixels(0, 0, w, h, GL_RGB, GL_UNSIGNED_BYTE, pixels);

  U8 *header = MStrPrint("P6\n%d %d\n255\n", w, h);
  I64 header_len = StrLen(header);
  I64 size = header_len + row * h;
  U8 *file = MAlloc(size);
  MemCpy(file, header, header_len);
  for (I64 y = 0; y < h; y++)
    MemCpy(file + header_len + y * row, pixels + (h - 1 - y) * row, row);

  U8 *path = MStrPrint("%s%05d.ppm", g_out_dir, g_saved);
  if (!FileWrite(path, file, size, O_CREAT | O_RDWR | O_TRUNC))
    "could not write %s\n", path;
  g_saved++;

  Free(path);
  Free(file);
  Free(header);
  Free(pixels);
}

// One 60 Hz frame of the game, mirroring GameUpdate's state changes.
U0 Step(Game *g)
{
  Input *in = &g->input;
  WindowPump(&g->window);
  g->clock.elapsed += FRAME_DT;
  StateTick(&g->sm, FRAME_DT);

  if (g->sm.current == STATE_PLAYING) {
    WorldUpdate(&g->world, in, FRAME_DT);
    if (g->world.outcome == OUTCOME_CAUGHT)
      StateSet(&g->sm, STATE_DEAD);
    else if (g->world.outcome == OUTCOME_ESCAPED)
      StateSet(&g->sm, STATE_WON);
  }

  GameRender(g, FRAME_DT);
  if (g_tick % 2 == 0)
    SaveFrame(&g->window);
  WindowSwap(&g->window);
  g_tick++;

  MemCpy(in->prev, in->down, sizeof(Bool) * ACT_COUNT);
}

U0 Hold(Game *g, I64 frames)
{
  for (I64 i = 0; i < frames; i++)
    Step(g);
}

U0 ReleaseAll(Input *in)
{
  MemSet(in->down, 0, sizeof(Bool) * ACT_COUNT);
  in->look_x = 0.0;
  in->look_y = 0.0;
}

U0 Stage(Game *g, I64 cell_x, I64 cell_z, I64 look_x, I64 look_z)
{
  WorldReset(&g->world, 77);
  g->world.warden->state = WARDEN_DORMANT;
  g->world.warden->timer = 1000000.0;
  g->world.time = 0.6;
  g->world.message_time = 0.0;
  Vec3 look;
  LevelCellCenter(cell_x, cell_z, &g->world.player.pos);
  LevelCellCenter(look_x, look_z, &look);
  g->world.player.yaw = YawToward(&g->world.player.pos, &look);
  g->world.player_cell_x = cell_x;
  g->world.player_cell_z = cell_z;
  LevelBuildFlow(&g->world.level, cell_x, cell_z);
  ReleaseAll(&g->input);
  g->sm.current = STATE_PLAYING;
  g->sm.previous = STATE_PLAYING;
  g->sm.time = 0.0;
}

U0 PlaceWarden(World *w, I64 cell_x, I64 cell_z, F32 yaw, I64 state)
{
  Entity *wd = w->warden;
  wd->cell_x = cell_x;
  wd->cell_z = cell_z;
  wd->goal_x = cell_x;
  wd->goal_z = cell_z;
  LevelCellCenter(cell_x, cell_z, &wd->pos);
  wd->yaw = yaw;
  wd->state = state;
}

// Walks to a cell the way a player would: following the flow field and
// turning at a human rate instead of snapping to each new heading.
Bool WalkTo(Game *g, I64 tx, I64 tz, Bool sprint, I64 max_frames)
{
  World *w = &g->world;
  Player *p = &w->player;
  Input *in = &g->input;
  Vec3 goal;
  LevelCellCenter(tx, tz, &goal);
  Bool arrived = FALSE;

  for (I64 i = 0; i < max_frames; i++) {
    if (g->sm.current != STATE_PLAYING)
      break;
    I64 cx = LevelCellOf(p->pos.x), cz = LevelCellOf(p->pos.z);
    Vec3 aim = goal;
    if (cx != tx || cz != tz) {
      LevelBuildFlow(&w->level, tx, tz);
      I64 nx, nz;
      if (!LevelFlowNext(&w->level, cx, cz, &nx, &nz))
        break;
      LevelCellCenter(nx, nz, &aim);
      LevelBuildFlow(&w->level, cx, cz);
    } else if (DistXZ(&p->pos, &goal) < 0.25) {
      arrived = TRUE;
      break;
    }
    p->yaw = TurnToward(p->yaw, YawToward(&p->pos, &aim), FRAME_DT * 3.2);
    in->down[ACT_FORWARD] = TRUE;
    in->down[ACT_SPRINT] = sprint;
    Step(g);
  }
  ReleaseAll(in);
  return arrived;
}

U0 ShotTitle(Game *g, I64 frames)
{
  WorldReset(&g->world, TITLE_SEED);
  g->sm.current = STATE_TITLE;
  g->sm.time = 0.0;
  Hold(g, frames);
}

// Lantern lit, a short walk round a corner to a relic in its alcove.
U0 ShotRelic(Game *g)
{
  Stage(g, 22, 7, 20, 7);
  WorldMessage(&g->world, "FIVE RELICS LIE IN THE DARK. FIND THEM.", 4.0);
  Hold(g, 20);
  WalkTo(g, 21, 7, FALSE, 200);
  WalkTo(g, 20, 6, FALSE, 200);
  WalkTo(g, 20, 5, FALSE, 120);
  Hold(g, 45);
}

// The last relic taken: the gate grinds open at the end of the catacomb.
U0 ShotGate(Game *g)
{
  Stage(g, 25, 14, 25, 18);
  g->world.player.relics = 5;
  g->world.level.gate_open = TRUE;
  WardenAlert(g->world.warden);
  g->world.warden->state = WARDEN_DORMANT;
  WorldMessage(&g->world, "SOMEWHERE, IRON GRINDS. THE GATE IS OPEN.", 5.0);
  Hold(g, 60);
  WalkTo(g, 25, 16, FALSE, 240);
  Hold(g, 40);
}

// Lantern doused in a dark corridor, a candle at the far end. Something
// crosses the candlelight. The lantern goes back on too late.
U0 ShotWarden(Game *g)
{
  Stage(g, 6, 3, 1, 3);
  g->world.player.lantern = FALSE;
  g->world.player.relics = 3;
  PlaceWarden(&g->world, 1, 3, 0.0, WARDEN_HUNT);
  Hold(g, 75);

  g->input.down[ACT_LANTERN] = TRUE;
  Step(g);
  ReleaseAll(&g->input);
  Hold(g, 215);
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc > 1)
    g_out_dir = argv[1];

  Game *g = &g_game;
  if (!GameInit(g))
    return 1;

  ShotTitle(g, 170);
  ShotRelic(g);
  ShotGate(g);
  ShotWarden(g);
  ShotTitle(g, 120);

  "captured %d frames\n", g_saved;
  GameShutdown(g);
  return 0;
}
