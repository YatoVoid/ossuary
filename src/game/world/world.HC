#define OUTCOME_NONE    0
#define OUTCOME_CAUGHT  1
#define OUTCOME_ESCAPED 2

#define RELIC_PICKUP_RANGE 0.9

class World
{
  Level level;
  EntityPool ents;
  Player player;
  Rng rng;
  Entity *warden;
  Entity *gate;
  I64 exit_x;
  I64 exit_z;
  I64 relics_total;
  I64 player_cell_x;
  I64 player_cell_z;
  I64 outcome;
  F32 time;
  F32 dread;
  U8 *message;
  F32 message_time;
};

U0 WorldMessage(World *w, U8 *text, F32 seconds = 3.5)
{
  w->message = text;
  w->message_time = seconds;
}

U0 WorldPlaceCandle(World *w, Entity *e)
{
  for (I64 d = 0; d < 4; d++) {
    if (LevelTile(&w->level, e->cell_x + g_dir_x[d], e->cell_z + g_dir_z[d]) != TILE_WALL)
      continue;
    e->pos.x += g_dir_x[d] * (CELL_SIZE * 0.5 - 0.18);
    e->pos.z += g_dir_z[d] * (CELL_SIZE * 0.5 - 0.18);
    return;
  }
}

U0 WorldSpawnEntities(World *w)
{
  Level *lv = &w->level;
  EntityPoolClear(&w->ents);
  w->warden = NULL;
  w->gate = NULL;
  w->relics_total = 0;

  for (I64 i = 0; i < lv->marker_count; i++) {
    Marker *m = &lv->markers[i];
    Vec3 at;
    switch (m->kind) {
      case 'P':
        LevelCellCenter(m->x, m->z, &at);
        PlayerSpawn(&w->player, &at, HALF_PI);
        break;
      case 'R': {
        Entity *relic = EntitySpawn(&w->ents, ENT_RELIC, m->x, m->z);
        relic->phase = RngFloat(&w->rng) * TAU;
        w->relics_total++;
        break;
      }
      case 'c': {
        Entity *candle = EntitySpawn(&w->ents, ENT_CANDLE, m->x, m->z);
        candle->phase = RngFloat(&w->rng) * TAU;
        WorldPlaceCandle(w, candle);
        break;
      }
      case 'W':
        w->warden = EntitySpawn(&w->ents, ENT_WARDEN, m->x, m->z);
        WardenSpawn(w->warden);
        break;
      case 'G':
        w->gate = EntitySpawn(&w->ents, ENT_GATE, m->x, m->z);
        if (LevelTile(lv, m->x - 1, m->z) == TILE_WALL)
          w->gate->yaw = 0.0;
        else
          w->gate->yaw = HALF_PI;
        break;
      case 'X':
        w->exit_x = m->x;
        w->exit_z = m->z;
        break;
    }
  }

  if (!w->warden || !w->gate)
    Fatal("level needs a warden (W) and a gate (G)");
}

U0 WorldReset(World *w, U64 seed)
{
  RngSeed(&w->rng, seed);
  w->level.gate_open = FALSE;
  w->outcome = OUTCOME_NONE;
  w->time = 0.0;
  w->dread = 0.0;
  WorldSpawnEntities(w);
  w->player_cell_x = LevelCellOf(w->player.pos.x);
  w->player_cell_z = LevelCellOf(w->player.pos.z);
  LevelBuildFlow(&w->level, w->player_cell_x, w->player_cell_z);
  WorldMessage(w, "FIVE RELICS LIE IN THE DARK. FIND THEM.", 5.0);
}

U0 WorldInit(World *w)
{
  MemSet(w, 0, sizeof(World));
  LevelLoad(&w->level, g_catacomb, sizeof(g_catacomb) / sizeof(U8 *));
  WorldReset(w, 0x5EED);
}

U0 WorldCollectRelics(World *w)
{
  Player *p = &w->player;
  for (I64 i = 0; i < w->ents.count; i++) {
    Entity *e = &w->ents.items[i];
    if (!e->active || e->kind != ENT_RELIC)
      continue;
    if (DistXZ(&e->pos, &p->pos) > RELIC_PICKUP_RANGE)
      continue;

    EntityKill(e);
    p->relics++;
    I64 left = w->relics_total - p->relics;
    if (left == 0) {
      w->level.gate_open = TRUE;
      LevelBuildFlow(&w->level, w->player_cell_x, w->player_cell_z);
      WardenAlert(w->warden);
      WorldMessage(w, "SOMEWHERE, IRON GRINDS. THE GATE IS OPEN.", 5.0);
    } else if (left == 1) {
      WorldMessage(w, "ONE RELIC REMAINS.");
    } else {
      WorldMessage(w, "A RELIC. IT HUMS IN YOUR HAND.");
    }
  }
}

U0 WorldUpdateDread(World *w, F32 dt)
{
  Entity *wd = w->warden;
  F32 dist = DistXZ(&wd->pos, &w->player.pos);
  F32 target = Saturate(1.0 - (dist - 1.5) / 11.0) * 0.7;
  if (wd->state == WARDEN_SEARCH)
    target = Maxf(target, 0.3);
  if (wd->state == WARDEN_HUNT)
    target = Maxf(target + 0.3, 0.6);
  w->dread = Approach(w->dread, Saturate(target), dt * 0.8);
}

U0 WorldUpdate(World *w, Input *in, F32 dt)
{
  if (w->outcome != OUTCOME_NONE)
    return;

  w->time += dt;
  if (w->message_time > 0.0)
    w->message_time -= dt;

  Player *p = &w->player;
  PlayerUpdate(p, in, &w->level, dt);

  I64 cx = LevelCellOf(p->pos.x), cz = LevelCellOf(p->pos.z);
  if (cx != w->player_cell_x || cz != w->player_cell_z) {
    w->player_cell_x = cx;
    w->player_cell_z = cz;
    LevelBuildFlow(&w->level, cx, cz);
  }

  WorldCollectRelics(w);

  for (I64 i = 0; i < w->ents.count; i++) {
    Entity *e = &w->ents.items[i];
    if (!e->active)
      continue;
    switch (e->kind) {
      case ENT_RELIC:
      case ENT_CANDLE:
        e->phase += dt;
        break;
      case ENT_GATE:
        if (w->level.gate_open)
          e->anim = Approach(e->anim, 1.0, dt * 0.35);
        break;
      case ENT_WARDEN:
        if (WardenUpdate(e, p, &w->level, &w->rng, dt))
          w->outcome = OUTCOME_CAUGHT;
        break;
    }
  }

  WorldUpdateDread(w, dt);

  if (LevelTile(&w->level, cx, cz) == TILE_EXIT)
    w->outcome = OUTCOME_ESCAPED;
}
