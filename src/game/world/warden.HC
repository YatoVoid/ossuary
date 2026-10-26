#define WARDEN_DORMANT 0
#define WARDEN_WANDER  1
#define WARDEN_SEARCH  2
#define WARDEN_HUNT    3

#define WARDEN_WANDER_SPEED 1.5
#define WARDEN_SEARCH_SPEED 2.4
#define WARDEN_HUNT_SPEED   3.7
#define WARDEN_SIGHT_LIT    13.0
#define WARDEN_SIGHT_DARK   5.0
#define WARDEN_CLOSE_SENSE  2.5
#define WARDEN_HEARING      11.0
#define WARDEN_CATCH        0.8
#define WARDEN_LOSE_TIME    1.6
#define WARDEN_SEARCH_TIME  6.0
#define WARDEN_GRACE        5.0
#define WARDEN_RADIUS       0.3

U0 WardenSpawn(Entity *w)
{
  w->state = WARDEN_DORMANT;
  w->timer = WARDEN_GRACE;
  w->radius = WARDEN_RADIUS;
  w->goal_x = w->cell_x;
  w->goal_z = w->cell_z;
  w->prev_x = w->cell_x;
  w->prev_z = w->cell_z;
}

// A lit lantern gives the player away from any direction. In the dark the
// warden only notices what is in front of it, or something brushing past.
Bool WardenSees(Entity *w, Player *p, Level *lv, F32 dist)
{
  if (dist < WARDEN_CLOSE_SENSE)
    return LevelLineOfSight(lv, &w->pos, &p->pos);

  if (p->lantern) {
    if (dist > WARDEN_SIGHT_LIT)
      return FALSE;
  } else {
    if (dist > WARDEN_SIGHT_DARK)
      return FALSE;
    F32 facing = WrapAngle(YawToward(&w->pos, &p->pos) - w->yaw);
    if (Absf(facing) > 1.05)
      return FALSE;
  }
  return LevelLineOfSight(lv, &w->pos, &p->pos);
}

Bool WardenHears(Entity *w, Player *p, F32 dist)
{
  if (p->noise < 0.01)
    return FALSE;
  if (dist < WARDEN_HEARING * p->noise)
    return TRUE;
  return FALSE;
}

U0 WardenPickWander(Entity *w, Level *lv, Rng *rng)
{
  I64 options_x[4], options_z[4];
  I64 n = 0;
  for (I64 d = 0; d < 4; d++) {
    I64 nx = w->cell_x + g_dir_x[d], nz = w->cell_z + g_dir_z[d];
    if (LevelBlocks(lv, nx, nz))
      continue;
    if (nx == w->prev_x && nz == w->prev_z)
      continue;
    options_x[n] = nx;
    options_z[n] = nz;
    n++;
  }
  if (n == 0) {
    w->goal_x = w->prev_x;
    w->goal_z = w->prev_z;
    return;
  }
  I64 pick = RngRange(rng, n);
  w->goal_x = options_x[pick];
  w->goal_z = options_z[pick];
}

U0 WardenPickNext(Entity *w, Level *lv, Rng *rng)
{
  if (w->state == WARDEN_WANDER) {
    WardenPickWander(w, lv, rng);
    return;
  }
  I64 nx, nz;
  if (LevelFlowNext(lv, w->cell_x, w->cell_z, &nx, &nz)) {
    w->goal_x = nx;
    w->goal_z = nz;
  } else {
    WardenPickWander(w, lv, rng);
  }
}

U0 WardenWalkGrid(Entity *w, Level *lv, Rng *rng, F32 step)
{
  Vec3 target, delta;
  LevelCellCenter(w->goal_x, w->goal_z, &target);
  V3Sub(&delta, &target, &w->pos);
  delta.y = 0.0;
  F32 dist = V3Length(&delta);

  if (dist <= step) {
    w->pos.x = target.x;
    w->pos.z = target.z;
    if (w->goal_x != w->cell_x || w->goal_z != w->cell_z) {
      w->prev_x = w->cell_x;
      w->prev_z = w->cell_z;
    }
    w->cell_x = w->goal_x;
    w->cell_z = w->goal_z;
    WardenPickNext(w, lv, rng);
    return;
  }

  V3AddScaled(&w->pos, &w->pos, &delta, step / dist);
  w->yaw = TurnToward(w->yaw, YawToward(&w->pos, &target), step * 2.5);
}

U0 WardenLunge(Entity *w, Player *p, Level *lv, F32 step)
{
  Vec3 delta;
  V3Sub(&delta, &p->pos, &w->pos);
  delta.y = 0.0;
  F32 dist = V3Length(&delta);
  if (dist < 0.001)
    return;
  LevelMove(lv, &w->pos, delta.x / dist * step, delta.z / dist * step, WARDEN_RADIUS);
  w->yaw = TurnToward(w->yaw, YawToward(&w->pos, &p->pos), step * 3.0);
  w->cell_x = LevelCellOf(w->pos.x);
  w->cell_z = LevelCellOf(w->pos.z);
  w->goal_x = w->cell_x;
  w->goal_z = w->cell_z;
}

U0 WardenAlert(Entity *w)
{
  if (w->state == WARDEN_HUNT)
    return;
  w->state = WARDEN_SEARCH;
  w->timer = WARDEN_SEARCH_TIME * 2.0;
}

// Returns TRUE when the warden has caught the player.
Bool WardenUpdate(Entity *w, Player *p, Level *lv, Rng *rng, F32 dt)
{
  F32 dist = DistXZ(&w->pos, &p->pos);
  w->anim += dt;

  if (w->state == WARDEN_DORMANT) {
    w->timer -= dt;
    if (w->timer < 0.0) {
      w->state = WARDEN_WANDER;
      WardenPickNext(w, lv, rng);
    }
    return FALSE;
  }

  Bool sees = WardenSees(w, p, lv, dist);
  Bool hears = WardenHears(w, p, dist);

  switch (w->state) {
    case WARDEN_WANDER:
      if (sees) {
        w->state = WARDEN_HUNT;
        w->timer = WARDEN_LOSE_TIME;
      } else if (hears) {
        w->state = WARDEN_SEARCH;
        w->timer = WARDEN_SEARCH_TIME;
      }
      break;
    case WARDEN_SEARCH:
      if (sees) {
        w->state = WARDEN_HUNT;
        w->timer = WARDEN_LOSE_TIME;
        break;
      }
      if (hears)
        w->timer = Maxf(w->timer, WARDEN_SEARCH_TIME);
      w->timer -= dt;
      if (w->timer < 0.0)
        w->state = WARDEN_WANDER;
      break;
    case WARDEN_HUNT:
      if (sees) {
        w->timer = WARDEN_LOSE_TIME;
      } else {
        w->timer -= dt;
        if (w->timer < 0.0) {
          w->state = WARDEN_SEARCH;
          w->timer = WARDEN_SEARCH_TIME;
        }
      }
      break;
  }

  F32 speed = WARDEN_WANDER_SPEED;
  if (w->state == WARDEN_SEARCH)
    speed = WARDEN_SEARCH_SPEED;
  if (w->state == WARDEN_HUNT)
    speed = WARDEN_HUNT_SPEED;
  w->speed = speed;

  Bool lunge = FALSE;
  if (dist < CELL_SIZE * 1.25)
    lunge = w->state == WARDEN_HUNT && sees;
  if (lunge)
    WardenLunge(w, p, lv, speed * dt);
  else
    WardenWalkGrid(w, lv, rng, speed * dt);

  if (DistXZ(&w->pos, &p->pos) < WARDEN_CATCH)
    return TRUE;
  return FALSE;
}
