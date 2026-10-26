#define WINDOW_TITLE   "Ossuary"
#define WINDOW_WIDTH   1280
#define WINDOW_HEIGHT  720
#define SCRATCH_BYTES  (8 * 1024 * 1024)
#define TITLE_SEED     0x0551
#define END_INPUT_DELAY 1.0

class Game
{
  Window window;
  Input input;
  Clock clock;
  Arena scratch;
  Renderer renderer;
  World world;
  Camera camera;
  StateMachine sm;
  U8 *asset_dir;
  Bool running;
  Bool show_fps;
};

Game g_game;

U0 GameEnterState(Game *g)
{
  switch (g->sm.current) {
    case STATE_TITLE:
      WindowCaptureMouse(&g->window, FALSE);
      WorldReset(&g->world, TITLE_SEED);
      break;
    case STATE_PLAYING:
      if (g->sm.previous != STATE_PAUSED)
        WorldReset(&g->world, PlatformCounter());
      WindowCaptureMouse(&g->window, TRUE);
      break;
    default:
      WindowCaptureMouse(&g->window, FALSE);
      break;
  }
}

U0 GameUpdate(Game *g, F32 dt)
{
  Input *in = &g->input;
  StateMachine *sm = &g->sm;
  StateTick(sm, dt);

  if (InputPressed(in, ACT_DEBUG))
    g->show_fps = !g->show_fps;

  switch (sm->current) {
    case STATE_TITLE:
      if (InputPressed(in, ACT_CONFIRM))
        StateSet(sm, STATE_PLAYING);
      else if (InputPressed(in, ACT_PAUSE) || InputPressed(in, ACT_QUIT))
        g->running = FALSE;
      break;

    case STATE_PLAYING:
      if (InputPressed(in, ACT_PAUSE) || !in->focused) {
        StateSet(sm, STATE_PAUSED);
        break;
      }
      WorldUpdate(&g->world, in, dt);
      if (g->world.outcome == OUTCOME_CAUGHT)
        StateSet(sm, STATE_DEAD);
      else if (g->world.outcome == OUTCOME_ESCAPED)
        StateSet(sm, STATE_WON);
      break;

    case STATE_PAUSED:
      if (InputPressed(in, ACT_CONFIRM) || InputPressed(in, ACT_PAUSE))
        StateSet(sm, STATE_PLAYING);
      else if (InputPressed(in, ACT_QUIT))
        StateSet(sm, STATE_TITLE);
      break;

    case STATE_DEAD:
    case STATE_WON:
      if (sm->time < END_INPUT_DELAY)
        break;
      if (InputPressed(in, ACT_CONFIRM))
        StateSet(sm, STATE_PLAYING);
      else if (InputPressed(in, ACT_QUIT) || InputPressed(in, ACT_PAUSE))
        StateSet(sm, STATE_TITLE);
      break;
  }
}

U0 GameFrameCamera(Game *g, SceneParams *sp, F32 dt)
{
  Camera *cam = &g->camera;
  World *w = &g->world;
  F32 t = g->clock.elapsed;
  F32 st = g->sm.time;

  MemSet(sp, 0, sizeof(SceneParams));
  sp->time = t;
  sp->dread = w->dread;
  if (w->player.lantern)
    sp->lantern = 1.0;

  switch (g->sm.current) {
    case STATE_TITLE:
      LevelCellCenter(11, 3, &cam->pos);
      cam->pos.y = 1.45 + sin(t * 0.5) * 0.04;
      cam->yaw = -HALF_PI + sin(t * 0.17) * 0.4;
      cam->pitch = -0.06 + sin(t * 0.23) * 0.04;
      sp->lantern = 0.55;
      sp->dread = 0.12;
      sp->fade = Saturate(1.0 - st * 0.7);
      return;

    case STATE_DEAD: {
      Entity *wd = w->warden;
      F32 want = YawToward(&w->player.pos, &wd->pos);
      cam->yaw = TurnToward(cam->yaw, want, dt * 6.0);
      cam->pitch = Approach(cam->pitch, 0.35, dt * 1.5);
      cam->pos.y = Approach(cam->pos.y, 0.5, dt * 0.9);
      sp->dread = 1.0;
      sp->fade = Saturate(st * 0.5) * 0.85;
      ColorSet(&sp->fade_color, 0.09, 0.0, 0.0);
      return;
    }

    case STATE_WON:
      cam->pitch = Approach(cam->pitch, 0.9, dt * 0.4);
      sp->fade = Saturate(st * 0.45) * 0.9;
      ColorSet(&sp->fade_color, 0.72, 0.76, 0.84);
      return;
  }

  PlayerEye(&w->player, &cam->pos);
  cam->yaw = w->player.yaw;
  cam->pitch = w->player.pitch;
  if (g->sm.current == STATE_PLAYING)
    sp->fade = Saturate(1.0 - w->time / 1.5);
}

U0 GameDrawUi(Game *g)
{
  UiBatch *ui = &g->renderer.ui;
  UiBegin(ui, g->window.width, g->window.height);

  switch (g->sm.current) {
    case STATE_TITLE:
      MenuDrawTitle(ui, g->clock.elapsed);
      break;
    case STATE_PLAYING:
      HudDraw(ui, &g->world, g->clock.fps, g->show_fps);
      break;
    case STATE_PAUSED:
      HudDraw(ui, &g->world, g->clock.fps, g->show_fps);
      MenuDrawPause(ui);
      break;
    case STATE_DEAD:
      MenuDrawEnd(ui, &g->world, FALSE, g->sm.time);
      break;
    case STATE_WON:
      MenuDrawEnd(ui, &g->world, TRUE, g->sm.time);
      break;
  }

  UiEnd(ui);
}

Bool GameInit(Game *g)
{
  MemSet(g, 0, sizeof(Game));
  if (!WindowOpen(&g->window, WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT))
    return FALSE;

  U8 *base = PlatformBasePath();
  g->asset_dir = MStrPrint("%sassets/", base);
  Free(base);

  ArenaInit(&g->scratch, "scratch", SCRATCH_BYTES);
  InputInit(&g->input);
  ClockInit(&g->clock);
  CameraInit(&g->camera);
  RendererInit(&g->renderer, g->asset_dir, &g->scratch);
  WorldInit(&g->world);
  LevelBuildMeshes(&g->world.level, &g->scratch);
  StateInit(&g->sm, STATE_TITLE);
  g->running = TRUE;
  return TRUE;
}

U0 GameRender(Game *g, F32 dt)
{
  SceneParams sp;
  GameFrameCamera(g, &sp, dt);
  RendererDrawScene(&g->renderer, &g->world, &g->camera, &sp,
                    g->window.width, g->window.height);
  GameDrawUi(g);
}

U0 GameShutdown(Game *g)
{
  WindowClose(&g->window);
  ArenaFree(&g->scratch);
  Free(g->asset_dir);
}

I32 GameRun()
{
  Game *g = &g_game;
  if (!GameInit(g))
    return 1;

  while (g->running) {
    ClockTick(&g->clock);
    InputSystemUpdate(&g->input, &g->window);
    if (g->window.quit_requested)
      break;

    GameUpdate(g, g->clock.dt);
    while (StateConsumeEnter(&g->sm))
      GameEnterState(g);

    GameRender(g, g->clock.dt);
    WindowSwap(&g->window);
  }

  GameShutdown(g);
  return 0;
}
