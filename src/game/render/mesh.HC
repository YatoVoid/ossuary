#define VERTEX_FLOATS 8
#define VERTEX_STRIDE 32

class MeshBuilder
{
  F32 *data;
  I64 count;
  I64 cap;
};

class Mesh
{
  U32 vao;
  U32 vbo;
  I64 count;
};

U0 MeshBuilderInit(MeshBuilder *b, Arena *arena, I64 max_vertices)
{
  b->data = ArenaPush(arena, max_vertices * VERTEX_STRIDE);
  b->count = 0;
  b->cap = max_vertices;
}

U0 MeshVertex(MeshBuilder *b, F32 px, F32 py, F32 pz, F32 nx, F32 ny, F32 nz, F32 u, F32 v)
{
  if (b->count >= b->cap)
    Fatal("mesh builder overflow");
  F32 *dst = b->data + b->count * VERTEX_FLOATS;
  dst[0] = px; dst[1] = py; dst[2] = pz;
  dst[3] = nx; dst[4] = ny; dst[5] = nz;
  dst[6] = u;  dst[7] = v;
  b->count++;
}

// Corners go counter-clockwise when seen from the side `n` points to.
U0 MeshQuad(MeshBuilder *b, Vec3 *p0, Vec3 *p1, Vec3 *p2, Vec3 *p3, Vec3 *n,
            F32 u0, F32 v0, F32 u1, F32 v1)
{
  MeshVertex(b, p0->x, p0->y, p0->z, n->x, n->y, n->z, u0, v1);
  MeshVertex(b, p1->x, p1->y, p1->z, n->x, n->y, n->z, u1, v1);
  MeshVertex(b, p2->x, p2->y, p2->z, n->x, n->y, n->z, u1, v0);
  MeshVertex(b, p0->x, p0->y, p0->z, n->x, n->y, n->z, u0, v1);
  MeshVertex(b, p2->x, p2->y, p2->z, n->x, n->y, n->z, u1, v0);
  MeshVertex(b, p3->x, p3->y, p3->z, n->x, n->y, n->z, u0, v0);
}

U0 MeshTriangle(MeshBuilder *b, Vec3 *p0, Vec3 *p1, Vec3 *p2)
{
  Vec3 e1, e2, c, n;
  V3Sub(&e1, p1, p0);
  V3Sub(&e2, p2, p0);
  V3Cross(&c, &e1, &e2);
  V3Normalize(&n, &c);
  MeshVertex(b, p0->x, p0->y, p0->z, n.x, n.y, n.z, 0.5, 0.0);
  MeshVertex(b, p1->x, p1->y, p1->z, n.x, n.y, n.z, 0.0, 1.0);
  MeshVertex(b, p2->x, p2->y, p2->z, n.x, n.y, n.z, 1.0, 1.0);
}

U0 MeshUpload(Mesh *mesh, MeshBuilder *b)
{
  glGenVertexArrays(1, &mesh->vao);
  glBindVertexArray(mesh->vao);
  glGenBuffers(1, &mesh->vbo);
  glBindBuffer(GL_ARRAY_BUFFER, mesh->vbo);
  glBufferData(GL_ARRAY_BUFFER, b->count * VERTEX_STRIDE, b->data, GL_STATIC_DRAW);

  glVertexAttribPointer(0, 3, GL_FLOAT, 0, VERTEX_STRIDE, 0);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(1, 3, GL_FLOAT, 0, VERTEX_STRIDE, 12);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(2, 2, GL_FLOAT, 0, VERTEX_STRIDE, 24);
  glEnableVertexAttribArray(2);

  glBindVertexArray(0);
  mesh->count = b->count;
}

U0 MeshDraw(Mesh *mesh)
{
  glBindVertexArray(mesh->vao);
  glDrawArrays(GL_TRIANGLES, 0, mesh->count);
}

U0 MeshFree(Mesh *mesh)
{
  glDeleteBuffers(1, &mesh->vbo);
  glDeleteVertexArrays(1, &mesh->vao);
  mesh->count = 0;
}

// Unit box, x and z in [-0.5, 0.5], y in [0, 1], so scaling y sets height
// and the model origin sits on the floor.
U0 MeshBuildBox(Mesh *mesh, Arena *scratch)
{
  I64 mark = scratch->used;
  MeshBuilder b;
  MeshBuilderInit(&b, scratch, 36);

  Vec3 a, c, d, e, n;
  V3Set(&n, 0.0, 0.0, 1.0);
  V3Set(&a, -0.5, 0.0, 0.5); V3Set(&c, 0.5, 0.0, 0.5);
  V3Set(&d, 0.5, 1.0, 0.5);  V3Set(&e, -0.5, 1.0, 0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  V3Set(&n, 0.0, 0.0, -1.0);
  V3Set(&a, 0.5, 0.0, -0.5); V3Set(&c, -0.5, 0.0, -0.5);
  V3Set(&d, -0.5, 1.0, -0.5); V3Set(&e, 0.5, 1.0, -0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  V3Set(&n, 1.0, 0.0, 0.0);
  V3Set(&a, 0.5, 0.0, 0.5); V3Set(&c, 0.5, 0.0, -0.5);
  V3Set(&d, 0.5, 1.0, -0.5); V3Set(&e, 0.5, 1.0, 0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  V3Set(&n, -1.0, 0.0, 0.0);
  V3Set(&a, -0.5, 0.0, -0.5); V3Set(&c, -0.5, 0.0, 0.5);
  V3Set(&d, -0.5, 1.0, 0.5);  V3Set(&e, -0.5, 1.0, -0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  V3Set(&n, 0.0, 1.0, 0.0);
  V3Set(&a, -0.5, 1.0, 0.5); V3Set(&c, 0.5, 1.0, 0.5);
  V3Set(&d, 0.5, 1.0, -0.5); V3Set(&e, -0.5, 1.0, -0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  V3Set(&n, 0.0, -1.0, 0.0);
  V3Set(&a, -0.5, 0.0, -0.5); V3Set(&c, 0.5, 0.0, -0.5);
  V3Set(&d, 0.5, 0.0, 0.5);  V3Set(&e, -0.5, 0.0, 0.5);
  MeshQuad(&b, &a, &c, &d, &e, &n, 0.0, 0.0, 1.0, 1.0);

  MeshUpload(mesh, &b);
  scratch->used = mark;
}

// Octahedron standing on its lower tip, height 1, width 0.6.
U0 MeshBuildRelic(Mesh *mesh, Arena *scratch)
{
  I64 mark = scratch->used;
  MeshBuilder b;
  MeshBuilderInit(&b, scratch, 24);

  Vec3 top, bottom, ring[4];
  V3Set(&top, 0.0, 1.0, 0.0);
  V3Set(&bottom, 0.0, 0.0, 0.0);
  V3Set(&ring[0], 0.3, 0.5, 0.0);
  V3Set(&ring[1], 0.0, 0.5, -0.3);
  V3Set(&ring[2], -0.3, 0.5, 0.0);
  V3Set(&ring[3], 0.0, 0.5, 0.3);

  for (I64 i = 0; i < 4; i++) {
    Vec3 *a = &ring[i];
    Vec3 *c = &ring[(i + 1) % 4];
    MeshTriangle(&b, &top, a, c);
    MeshTriangle(&b, &bottom, c, a);
  }

  MeshUpload(mesh, &b);
  scratch->used = mark;
}
