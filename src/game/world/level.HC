#define LEVEL_MAX_SIDE 48
#define LEVEL_CELLS    (LEVEL_MAX_SIDE * LEVEL_MAX_SIDE)
#define MAX_MARKERS    64

#define CELL_SIZE   2.0
#define WALL_HEIGHT 2.6

#define TILE_FLOOR 0
#define TILE_WALL  1
#define TILE_GATE  2
#define TILE_EXIT  3

#define FLOW_UNREACHED -1

// # wall   . floor   P player   R relic   W warden   c candle
// G gate (shut until every relic is taken)   X way out
U8 *g_catacomb[] = {
  "###########################",
  "#P...#........c#.........##",
  "#....#.######..#.#######..#",
  "#c.....#R...#....#.....#..#",
  "######.#....##.###.###.#.##",
  "#......#.....#...#.#R#.#..#",
  "#.####.###.#.###.#.#.#.##.#",
  "#.#..#.....#...#...#...#..#",
  "#.#R.#####.###.#####.###.##",
  "#.#..#...#...#.....#.....c#",
  "#.##.#.#.###.#.###.###.####",
  "#......#.....W...#...#....#",
  "###.#######.###.##.#.####.#",
  "#c..#.....#...#.R#.#......#",
  "#.###.###.###.#..#.######.#",
  "#.....#.#...#.####......#.#",
  "#.#####.#.#.#....c.####.#.#",
  "#...R...#.#......###....#.#",
  "#########################G#",
  "#########################X#",
  "###########################",
};

class Marker
{
  U8 kind;
  I64 x;
  I64 z;
};

class Level
{
  I64 width;
  I64 height;
  U8 tiles[LEVEL_CELLS];
  I32 flow[LEVEL_CELLS];
  I32 queue[LEVEL_CELLS];
  I64 flow_x;
  I64 flow_z;
  Marker markers[MAX_MARKERS];
  I64 marker_count;
  Bool gate_open;
  Mesh walls;
  Mesh floor;
  Mesh ceiling;
};

U0 LevelLoad(Level *lv, U8 **rows, I64 row_count)
{
  MemSet(lv, 0, sizeof(Level));
  lv->width = StrLen(rows[0]);
  lv->height = row_count;
  lv->flow_x = -1;
  lv->flow_z = -1;
  if (lv->width > LEVEL_MAX_SIDE || lv->height > LEVEL_MAX_SIDE)
    Fatal("level too large");

  for (I64 z = 0; z < lv->height; z++) {
    U8 *row = rows[z];
    if (StrLen(row) != lv->width)
      Fatal("level rows must all be the same width:", row);

    for (I64 x = 0; x < lv->width; x++) {
      U8 ch = row[x];
      U8 tile = TILE_FLOOR;
      switch (ch) {
        case '#': tile = TILE_WALL; break;
        case 'G': tile = TILE_GATE; break;
        case 'X': tile = TILE_EXIT; break;
      }
      lv->tiles[z * LEVEL_MAX_SIDE + x] = tile;

      if (ch != '#' && ch != '.' && lv->marker_count < MAX_MARKERS) {
        Marker *m = &lv->markers[lv->marker_count++];
        m->kind = ch;
        m->x = x;
        m->z = z;
      }
    }
  }
}

U8 LevelTile(Level *lv, I64 cx, I64 cz)
{
  if (cx < 0 || cz < 0 || cx >= lv->width || cz >= lv->height)
    return TILE_WALL;
  return lv->tiles[cz * LEVEL_MAX_SIDE + cx];
}

Bool LevelBlocks(Level *lv, I64 cx, I64 cz)
{
  U8 tile = LevelTile(lv, cx, cz);
  if (tile == TILE_WALL)
    return TRUE;
  if (tile == TILE_GATE && !lv->gate_open)
    return TRUE;
  return FALSE;
}

I64 LevelCellOf(F32 v)
{
  return FloorToInt(v / CELL_SIZE);
}

U0 LevelCellCenter(I64 cx, I64 cz, Vec3 *out)
{
  V3Set(out, (cx + 0.5) * CELL_SIZE, 0.0, (cz + 0.5) * CELL_SIZE);
}

Bool LevelBoxBlocked(Level *lv, F32 x, F32 z, F32 r)
{
  I64 x0 = LevelCellOf(x - r), x1 = LevelCellOf(x + r);
  I64 z0 = LevelCellOf(z - r), z1 = LevelCellOf(z + r);
  for (I64 cz = z0; cz <= z1; cz++)
    for (I64 cx = x0; cx <= x1; cx++)
      if (LevelBlocks(lv, cx, cz))
        return TRUE;
  return FALSE;
}

// Axis-separated so the mover slides along walls instead of sticking.
// Steps are assumed shorter than a cell, which the frame-time clamp ensures.
U0 LevelMove(Level *lv, Vec3 *pos, F32 dx, F32 dz, F32 r)
{
  if (dx != 0.0) {
    pos->x += dx;
    if (LevelBoxBlocked(lv, pos->x, pos->z, r)) {
      if (dx > 0.0)
        pos->x = LevelCellOf(pos->x + r) * CELL_SIZE - r - 0.001;
      else
        pos->x = (LevelCellOf(pos->x - r) + 1) * CELL_SIZE + r + 0.001;
    }
  }
  if (dz != 0.0) {
    pos->z += dz;
    if (LevelBoxBlocked(lv, pos->x, pos->z, r)) {
      if (dz > 0.0)
        pos->z = LevelCellOf(pos->z + r) * CELL_SIZE - r - 0.001;
      else
        pos->z = (LevelCellOf(pos->z - r) + 1) * CELL_SIZE + r + 0.001;
    }
  }
}

Bool LevelLineOfSight(Level *lv, Vec3 *a, Vec3 *b)
{
  F32 dist = DistXZ(a, b);
  I64 steps = dist / 0.2;
  if (steps < 1)
    steps = 1;
  F32 fsteps = steps;
  for (I64 i = 1; i < steps; i++) {
    F32 t = i / fsteps;
    F32 x = Lerpf(a->x, b->x, t);
    F32 z = Lerpf(a->z, b->z, t);
    if (LevelBlocks(lv, LevelCellOf(x), LevelCellOf(z)))
      return FALSE;
  }
  return TRUE;
}

I64 g_dir_x[4] = {1, -1, 0, 0};
I64 g_dir_z[4] = {0, 0, 1, -1};

// Breadth-first distance field toward (tx, tz). Anything chasing the
// target walks downhill one cell at a time.
U0 LevelBuildFlow(Level *lv, I64 tx, I64 tz)
{
  for (I64 i = 0; i < LEVEL_CELLS; i++)
    lv->flow[i] = FLOW_UNREACHED;
  lv->flow_x = tx;
  lv->flow_z = tz;
  if (LevelBlocks(lv, tx, tz))
    return;

  I64 head = 0, tail = 0;
  lv->flow[tz * LEVEL_MAX_SIDE + tx] = 0;
  lv->queue[tail++] = tz * LEVEL_MAX_SIDE + tx;

  while (head < tail) {
    I64 idx = lv->queue[head++];
    I64 cx = idx % LEVEL_MAX_SIDE;
    I64 cz = idx / LEVEL_MAX_SIDE;
    I64 next_dist = lv->flow[idx] + 1;
    for (I64 d = 0; d < 4; d++) {
      I64 nx = cx + g_dir_x[d], nz = cz + g_dir_z[d];
      if (LevelBlocks(lv, nx, nz))
        continue;
      I64 nidx = nz * LEVEL_MAX_SIDE + nx;
      if (lv->flow[nidx] != FLOW_UNREACHED)
        continue;
      lv->flow[nidx] = next_dist;
      lv->queue[tail++] = nidx;
    }
  }
}

I64 LevelFlowAt(Level *lv, I64 cx, I64 cz)
{
  if (cx < 0 || cz < 0 || cx >= lv->width || cz >= lv->height)
    return FLOW_UNREACHED;
  return lv->flow[cz * LEVEL_MAX_SIDE + cx];
}

Bool LevelFlowNext(Level *lv, I64 cx, I64 cz, I64 *out_x, I64 *out_z)
{
  I64 best = LevelFlowAt(lv, cx, cz);
  if (best == FLOW_UNREACHED)
    return FALSE;
  Bool found = FALSE;
  for (I64 d = 0; d < 4; d++) {
    I64 nx = cx + g_dir_x[d], nz = cz + g_dir_z[d];
    I64 v = LevelFlowAt(lv, nx, nz);
    if (v != FLOW_UNREACHED && v < best) {
      best = v;
      *out_x = nx;
      *out_z = nz;
      found = TRUE;
    }
  }
  return found;
}

U0 LevelWallFace(MeshBuilder *b, I64 cx, I64 cz, I64 side)
{
  F32 x0 = cx * CELL_SIZE, x1 = (cx + 1) * CELL_SIZE;
  F32 z0 = cz * CELL_SIZE, z1 = (cz + 1) * CELL_SIZE;
  F32 h = WALL_HEIGHT;
  F32 v_top = WALL_HEIGHT / CELL_SIZE;
  Vec3 p0, p1, p2, p3, n;

  switch (side) {
    case 0:
      V3Set(&n, -1.0, 0.0, 0.0);
      V3Set(&p0, x1, 0.0, z0); V3Set(&p1, x1, 0.0, z1);
      V3Set(&p2, x1, h, z1);   V3Set(&p3, x1, h, z0);
      break;
    case 1:
      V3Set(&n, 1.0, 0.0, 0.0);
      V3Set(&p0, x0, 0.0, z1); V3Set(&p1, x0, 0.0, z0);
      V3Set(&p2, x0, h, z0);   V3Set(&p3, x0, h, z1);
      break;
    case 2:
      V3Set(&n, 0.0, 0.0, -1.0);
      V3Set(&p0, x1, 0.0, z1); V3Set(&p1, x0, 0.0, z1);
      V3Set(&p2, x0, h, z1);   V3Set(&p3, x1, h, z1);
      break;
    default:
      V3Set(&n, 0.0, 0.0, 1.0);
      V3Set(&p0, x0, 0.0, z0); V3Set(&p1, x1, 0.0, z0);
      V3Set(&p2, x1, h, z0);   V3Set(&p3, x0, h, z0);
      break;
  }
  MeshQuad(b, &p0, &p1, &p2, &p3, &n, 0.0, 0.0, 1.0, v_top);
}

U0 LevelBuildMeshes(Level *lv, Arena *scratch)
{
  I64 mark = scratch->used;
  I64 cells = lv->width * lv->height;
  MeshBuilder walls, floor, ceiling;
  MeshBuilderInit(&walls, scratch, cells * 4 * 6);
  MeshBuilderInit(&floor, scratch, cells * 6);
  MeshBuilderInit(&ceiling, scratch, cells * 6);

  Vec3 p0, p1, p2, p3, up, down;
  V3Set(&up, 0.0, 1.0, 0.0);
  V3Set(&down, 0.0, -1.0, 0.0);

  for (I64 cz = 0; cz < lv->height; cz++) {
    for (I64 cx = 0; cx < lv->width; cx++) {
      U8 tile = LevelTile(lv, cx, cz);
      if (tile == TILE_WALL)
        continue;

      for (I64 d = 0; d < 4; d++)
        if (LevelTile(lv, cx + g_dir_x[d], cz + g_dir_z[d]) == TILE_WALL)
          LevelWallFace(&walls, cx, cz, d);

      F32 x0 = cx * CELL_SIZE, x1 = (cx + 1) * CELL_SIZE;
      F32 z0 = cz * CELL_SIZE, z1 = (cz + 1) * CELL_SIZE;
      V3Set(&p0, x0, 0.0, z1); V3Set(&p1, x1, 0.0, z1);
      V3Set(&p2, x1, 0.0, z0); V3Set(&p3, x0, 0.0, z0);
      MeshQuad(&floor, &p0, &p1, &p2, &p3, &up, 0.0, 0.0, 1.0, 1.0);

      if (tile == TILE_EXIT)
        continue;
      V3Set(&p0, x0, WALL_HEIGHT, z0); V3Set(&p1, x1, WALL_HEIGHT, z0);
      V3Set(&p2, x1, WALL_HEIGHT, z1); V3Set(&p3, x0, WALL_HEIGHT, z1);
      MeshQuad(&ceiling, &p0, &p1, &p2, &p3, &down, 0.0, 0.0, 1.0, 1.0);
    }
  }

  MeshUpload(&lv->walls, &walls);
  MeshUpload(&lv->floor, &floor);
  MeshUpload(&lv->ceiling, &ceiling);
  scratch->used = mark;
}
