// Renders a fixed set of scenes through the real game renderer and writes
// each one to a PPM, so visual changes can be reviewed without playing.
#include "../src/ossuary.HC"

#define GL_RGB          0x1907
#define GL_PACK_ALIGNMENT 0x0D05
#define FRAME_DT        (1.0 / 60.0)

U8 *g_out_dir = "./";

U0 SaveFrame(Window *win, U8 *name)
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

  U8 *path = MStrPrint("%s%s.ppm", g_out_dir, name);
  if (FileWrite(path, file, size, O_CREAT | O_RDWR | O_TRUNC))
    "wrote %s\n", path;
  else
    "could not write %s\n", path;

  Free(path);
  Free(file);
  Free(header);
  Free(pixels);
}

U0 Settle(Game *g, I64 frames, Bool simulate)
{
  for (I64 i = 0; i < frames; i++) {
    WindowPump(&g->window);
    g->clock.elapsed += FRAME_DT;
    StateTick(&g->sm, FRAME_DT);
    if (simulate)
      WorldUpdate(&g->world, &g->input, FRAME_DT);
    GameRender(g, FRAME_DT);
    WindowSwap(&g->window);
  }
}

U0 Stage(Game *g, I64 state, I64 cell_x, I64 cell_z, F32 yaw)
{
  WorldReset(&g->world, 77);
  g->world.warden->state = WARDEN_DORMANT;
  g->world.warden->timer = 1000000.0;
  g->world.time = 10.0;
  g->world.message_time = 0.0;
  LevelCellCenter(cell_x, cell_z, &g->world.player.pos);
  g->world.player.yaw = yaw;
  g->sm.current = state;
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

I32 Main(I32 argc, U8 **argv)
{
  if (argc > 1)
    g_out_dir = argv[1];

  Game *g = &g_game;
  if (!GameInit(g))
    return 1;

  g->sm.current = STATE_TITLE;
  Settle(g, 90, FALSE);
  SaveFrame(&g->window, "01_title");

  Stage(g, STATE_PLAYING, 1, 1, HALF_PI);
  WorldMessage(&g->world, "FIVE RELICS LIE IN THE DARK. FIND THEM.", 5.0);
  Settle(g, 30, FALSE);
  SaveFrame(&g->window, "02_spawn");

  Stage(g, STATE_PLAYING, 10, 3, -HALF_PI);
  g->world.player.lantern = FALSE;
  g->world.player.relics = 2;
  Settle(g, 30, FALSE);
  SaveFrame(&g->window, "03_relic_dark");

  Stage(g, STATE_PLAYING, 5, 3, -HALF_PI);
  PlaceWarden(&g->world, 3, 3, HALF_PI, WARDEN_HUNT);
  g->world.dread = 0.85;
  g->world.player.stamina = 0.4;
  Settle(g, 30, FALSE);
  SaveFrame(&g->window, "04_warden_hunt");

  Stage(g, STATE_PLAYING, 25, 15, PI);
  g->world.level.gate_open = TRUE;
  g->world.gate->anim = 0.55;
  g->world.player.relics = 5;
  WorldMessage(&g->world, "SOMEWHERE, IRON GRINDS. THE GATE IS OPEN.", 5.0);
  Settle(g, 30, FALSE);
  SaveFrame(&g->window, "05_gate_open");

  g->sm.current = STATE_PAUSED;
  Settle(g, 5, FALSE);
  SaveFrame(&g->window, "06_paused");

  Stage(g, STATE_PLAYING, 5, 3, -HALF_PI);
  PlaceWarden(&g->world, 4, 3, HALF_PI, WARDEN_HUNT);
  g->world.time = 161.0;
  g->world.player.relics = 3;
  g->world.outcome = OUTCOME_CAUGHT;
  PlayerEye(&g->world.player, &g->camera.pos);
  g->sm.current = STATE_DEAD;
  Settle(g, 150, FALSE);
  SaveFrame(&g->window, "07_taken");

  GameShutdown(g);
  return 0;
}
