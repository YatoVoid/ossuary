#define MAX_ENTITIES 64

#define ENT_NONE   0
#define ENT_RELIC  1
#define ENT_CANDLE 2
#define ENT_WARDEN 3
#define ENT_GATE   4

class Entity
{
  I64 kind;
  Bool active;
  Vec3 pos;
  Vec3 home;
  F32 yaw;
  F32 radius;
  F32 phase;
  F32 timer;
  F32 anim;
  I64 state;
  I64 cell_x;
  I64 cell_z;
  I64 goal_x;
  I64 goal_z;
  I64 prev_x;
  I64 prev_z;
  Vec3 last_seen;
  F32 speed;
};

class EntityPool
{
  Entity items[MAX_ENTITIES];
  I64 count;
};

U0 EntityPoolClear(EntityPool *pool)
{
  MemSet(pool, 0, sizeof(EntityPool));
}

Entity *EntitySpawn(EntityPool *pool, I64 kind, I64 cell_x, I64 cell_z)
{
  for (I64 i = 0; i < MAX_ENTITIES; i++) {
    Entity *e = &pool->items[i];
    if (e->active)
      continue;
    MemSet(e, 0, sizeof(Entity));
    e->kind = kind;
    e->active = TRUE;
    e->cell_x = cell_x;
    e->cell_z = cell_z;
    LevelCellCenter(cell_x, cell_z, &e->pos);
    e->home = e->pos;
    e->radius = 0.4;
    if (i >= pool->count)
      pool->count = i + 1;
    return e;
  }
  Fatal("entity pool full");
  return NULL;
}

U0 EntityKill(Entity *e)
{
  e->active = FALSE;
}

Entity *EntityFirst(EntityPool *pool, I64 kind)
{
  for (I64 i = 0; i < pool->count; i++) {
    Entity *e = &pool->items[i];
    if (e->active && e->kind == kind)
      return e;
  }
  return NULL;
}

I64 EntityCount(EntityPool *pool, I64 kind)
{
  I64 n = 0;
  for (I64 i = 0; i < pool->count; i++)
    if (pool->items[i].active && pool->items[i].kind == kind)
      n++;
  return n;
}
