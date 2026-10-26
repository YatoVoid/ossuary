#include "../src/ossuary.HC"

#define STEP (1.0 / 60.0)

World g_world;
Input g_input;
I64 g_checks = 0;
I64 g_failures = 0;

U0 Check(Bool ok, U8 *what)
{
  g_checks++;
  if (ok) {
    "  ok    %s\n", what;
  } else {
    g_failures++;
    "  FAIL  %s\n", what;
  }
}

Bool Exceeds(F32 v, F32 limit)
{
  if (v > limit)
    return TRUE;
  return FALSE;
}

U0 ResetInput(Input *in)
{
  InputInit(in);
}

U0 Tick(World *w, Input *in)
{
  WorldUpdate(w, in, STEP);
  MemCpy(in->prev, in->down, sizeof(Bool) * ACT_COUNT);
}

U0 FreshWorld(World *w)
{
  WorldReset(w, 1234);
  ResetInput(&g_input);
}

U0 HoldWardenAsleep(World *w)
{
  w->warden->state = WARDEN_DORMANT;
  w->warden->timer = 1000000.0;
}

// Walks the player toward cell (tx, tz) along the shortest path. Returns
// TRUE once the player stands near the centre of that cell.
Bool BotWalk(World *w, Input *in, I64 tx, I64 tz, I64 max_ticks)
{
  Player *p = &w->player;
  Vec3 goal;
  LevelCellCenter(tx, tz, &goal);

  for (I64 i = 0; i < max_ticks; i++) {
    if (w->outcome != OUTCOME_NONE)
      return FALSE;
    I64 cx = LevelCellOf(p->pos.x), cz = LevelCellOf(p->pos.z);
    Vec3 aim = goal;
    if (cx != tx || cz != tz) {
      LevelBuildFlow(&w->level, tx, tz);
      I64 nx, nz;
      if (!LevelFlowNext(&w->level, cx, cz, &nx, &nz))
        return FALSE;
      LevelCellCenter(nx, nz, &aim);
    } else if (DistXZ(&p->pos, &goal) < 0.2) {
      in->down[ACT_FORWARD] = FALSE;
      return TRUE;
    }
    p->yaw = YawToward(&p->pos, &aim);
    in->down[ACT_FORWARD] = TRUE;
    Tick(w, in);
  }
  in->down[ACT_FORWARD] = FALSE;
  return FALSE;
}

U0 TestLevelLoads()
{
  "level\n";
  World *w = &g_world;
  FreshWorld(w);
  Check(w->relics_total == 5, "five relics placed");
  Check(w->warden != NULL, "warden spawned");
  Check(w->gate != NULL, "gate spawned");
  Check(EntityCount(&w->ents, ENT_CANDLE) == 5, "five candles placed");
  Check(LevelBlocks(&w->level, w->gate->cell_x, w->gate->cell_z), "gate starts shut");
  Check(!LevelBoxBlocked(&w->level, w->player.pos.x, w->player.pos.z, PLAYER_RADIUS),
        "player spawns in open floor");

  LevelBuildFlow(&w->level, w->player_cell_x, w->player_cell_z);
  Check(LevelFlowAt(&w->level, w->exit_x, w->exit_z) == FLOW_UNREACHED,
        "exit unreachable while gate is shut");
  w->level.gate_open = TRUE;
  LevelBuildFlow(&w->level, w->player_cell_x, w->player_cell_z);
  Bool all = TRUE;
  for (I64 z = 0; z < w->level.height; z++)
    for (I64 x = 0; x < w->level.width; x++)
      if (LevelTile(&w->level, x, z) != TILE_WALL && LevelFlowAt(&w->level, x, z) == FLOW_UNREACHED)
        all = FALSE;
  Check(all, "every open cell reachable once the gate opens");
  w->level.gate_open = FALSE;
}

U0 TestWallsStopPlayer()
{
  "collision\n";
  World *w = &g_world;
  FreshWorld(w);
  HoldWardenAsleep(w);
  Player *p = &w->player;
  p->yaw = -HALF_PI;
  g_input.down[ACT_FORWARD] = TRUE;
  for (I64 i = 0; i < 180; i++)
    Tick(w, &g_input);
  g_input.down[ACT_FORWARD] = FALSE;

  Check(LevelCellOf(p->pos.x) == 1, "player stays in the spawn cell when walking into a wall");
  Bool clear = TRUE;
  if (p->pos.x < CELL_SIZE + PLAYER_RADIUS - 0.01)
    clear = FALSE;
  Check(clear, "player body never overlaps the wall");

  p->yaw = -HALF_PI + 0.6;
  F32 z_before = p->pos.z;
  g_input.down[ACT_FORWARD] = TRUE;
  for (I64 i = 0; i < 30; i++)
    Tick(w, &g_input);
  g_input.down[ACT_FORWARD] = FALSE;
  Bool slid = FALSE;
  if (p->pos.z > z_before + 0.1 || p->pos.z < z_before - 0.1)
    slid = TRUE;
  Check(slid, "angled walk into a wall slides along it");
}

U0 TestStealth()
{
  "stealth\n";
  World *w = &g_world;
  FreshWorld(w);
  Entity *wd = w->warden;
  Player *p = &w->player;

  LevelCellCenter(3, 1, &wd->pos);
  wd->yaw = HALF_PI;
  F32 dist = DistXZ(&wd->pos, &p->pos);

  p->lantern = FALSE;
  Check(!WardenSees(wd, p, &w->level, dist), "dark player behind the warden goes unseen");
  p->lantern = TRUE;
  Check(WardenSees(wd, p, &w->level, dist), "lit lantern is seen from behind");

  p->noise = 0.35;
  Check(!WardenHears(wd, p, dist), "walking two cells away is not heard");
  p->noise = 1.0;
  Check(WardenHears(wd, p, dist), "sprinting two cells away is heard");

  LevelCellCenter(8, 3, &wd->pos);
  Check(!WardenSees(wd, p, &w->level, DistXZ(&wd->pos, &p->pos)), "walls block line of sight");
}

U0 TestCaughtWhenIdle()
{
  "failure path\n";
  World *w = &g_world;
  FreshWorld(w);
  Entity *wd = w->warden;
  wd->cell_x = 3;
  wd->cell_z = 1;
  LevelCellCenter(3, 1, &wd->pos);
  wd->goal_x = 3;
  wd->goal_z = 1;
  wd->state = WARDEN_WANDER;
  wd->yaw = -HALF_PI;

  I64 ticks = 0;
  while (w->outcome == OUTCOME_NONE && ticks < 60 * 10) {
    Tick(w, &g_input);
    ticks++;
  }
  Check(w->outcome == OUTCOME_CAUGHT, "warden catches a player who stands still in the light");
  Check(ticks < 60 * 4, "catch happens within four seconds");

  I64 frozen = w->player.relics;
  F32 t = w->time;
  Tick(w, &g_input);
  Bool same_time = FALSE;
  if (w->time == t)
    same_time = TRUE;
  Check(same_time && w->player.relics == frozen, "world stops simulating after the outcome");
}

U0 TestFullRun()
{
  "main path\n";
  World *w = &g_world;
  FreshWorld(w);
  HoldWardenAsleep(w);

  I64 order_x[5], order_z[5];
  I64 n = 0;
  for (I64 i = 0; i < w->ents.count; i++) {
    Entity *e = &w->ents.items[i];
    if (e->active && e->kind == ENT_RELIC) {
      order_x[n] = e->cell_x;
      order_z[n] = e->cell_z;
      n++;
    }
  }

  Bool reached_all = TRUE;
  for (I64 r = 0; r < n; r++) {
    if (!BotWalk(w, &g_input, order_x[r], order_z[r], 60 * 60))
      reached_all = FALSE;
    if (r == n - 2)
      Check(!w->level.gate_open, "gate stays shut until the last relic");
  }
  Check(reached_all, "bot reaches every relic");
  Check(w->player.relics == 5, "all five relics collected");
  Check(EntityCount(&w->ents, ENT_RELIC) == 0, "collected relics leave the world");
  Check(w->level.gate_open, "gate opens after the fifth relic");
  Check(w->warden->state == WARDEN_SEARCH || w->warden->state == WARDEN_HUNT,
        "opening the gate alerts the warden");

  HoldWardenAsleep(w);
  BotWalk(w, &g_input, w->exit_x, w->exit_z, 60 * 60);
  Check(w->outcome == OUTCOME_ESCAPED, "walking out the gate wins the run");
  I64 secs = w->time;
  "  run took %d seconds of game time\n", secs;
}

U0 TestWardenWanders()
{
  "warden movement\n";
  World *w = &g_world;
  FreshWorld(w);
  Entity *wd = w->warden;
  w->player.lantern = FALSE;
  Vec3 start = wd->pos;
  for (I64 i = 0; i < 60 * 20; i++) {
    Tick(w, &g_input);
    if (w->outcome != OUTCOME_NONE)
      break;
  }
  Check(Exceeds(DistXZ(&start, &wd->pos), 1.0), "warden leaves its spawn after the grace period");
  Check(!LevelBoxBlocked(&w->level, wd->pos.x, wd->pos.z, 0.05), "warden never ends up inside a wall");
}

I32 Main()
{
  WorldInit(&g_world);
  TestLevelLoads();
  TestWallsStopPlayer();
  TestStealth();
  TestCaughtWhenIdle();
  TestWardenWanders();
  TestFullRun();

  "\n%d checks, %d failed\n", g_checks, g_failures;
  if (g_failures)
    return 1;
  return 0;
}
