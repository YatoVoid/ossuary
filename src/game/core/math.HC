F32 Minf(F32 a, F32 b)
{
  if (a < b)
    return a;
  return b;
}

F32 Maxf(F32 a, F32 b)
{
  if (a > b)
    return a;
  return b;
}

F32 Absf(F32 v)
{
  if (v < 0.0)
    return -v;
  return v;
}

F32 Clampf(F32 v, F32 lo, F32 hi)
{
  if (v < lo)
    return lo;
  if (v > hi)
    return hi;
  return v;
}

F32 Saturate(F32 v)
{
  return Clampf(v, 0.0, 1.0);
}

F32 Lerpf(F32 a, F32 b, F32 t)
{
  return a + (b - a) * t;
}

F32 Approach(F32 current, F32 target, F32 step)
{
  if (current < target)
    return Minf(current + step, target);
  return Maxf(current - step, target);
}

F32 Smoothstep(F32 lo, F32 hi, F32 v)
{
  F32 t = Saturate((v - lo) / (hi - lo));
  return t * t * (3.0 - 2.0 * t);
}

F32 WrapAngle(F32 a)
{
  while (a > PI)
    a -= TAU;
  while (a < -PI)
    a += TAU;
  return a;
}

F32 TurnToward(F32 current, F32 target, F32 step)
{
  F32 diff = WrapAngle(target - current);
  if (Absf(diff) < step)
    return target;
  if (diff > 0.0)
    return WrapAngle(current + step);
  return WrapAngle(current - step);
}

I64 FloorToInt(F32 v)
{
  F64 f = floor(v);
  I64 i = f;
  return i;
}

U0 V3Set(Vec3 *v, F32 x, F32 y, F32 z)
{
  v->x = x;
  v->y = y;
  v->z = z;
}

U0 V3Add(Vec3 *out, Vec3 *a, Vec3 *b)
{
  out->x = a->x + b->x;
  out->y = a->y + b->y;
  out->z = a->z + b->z;
}

U0 V3Sub(Vec3 *out, Vec3 *a, Vec3 *b)
{
  out->x = a->x - b->x;
  out->y = a->y - b->y;
  out->z = a->z - b->z;
}

U0 V3Scale(Vec3 *out, Vec3 *a, F32 s)
{
  out->x = a->x * s;
  out->y = a->y * s;
  out->z = a->z * s;
}

U0 V3AddScaled(Vec3 *out, Vec3 *a, Vec3 *b, F32 s)
{
  out->x = a->x + b->x * s;
  out->y = a->y + b->y * s;
  out->z = a->z + b->z * s;
}

F32 V3Dot(Vec3 *a, Vec3 *b)
{
  return a->x * b->x + a->y * b->y + a->z * b->z;
}

U0 V3Cross(Vec3 *out, Vec3 *a, Vec3 *b)
{
  F32 x = a->y * b->z - a->z * b->y;
  F32 y = a->z * b->x - a->x * b->z;
  F32 z = a->x * b->y - a->y * b->x;
  V3Set(out, x, y, z);
}

F32 V3Length(Vec3 *v)
{
  return sqrt(V3Dot(v, v));
}

U0 V3Normalize(Vec3 *out, Vec3 *v)
{
  F32 len = V3Length(v);
  if (len < 0.000001) {
    V3Set(out, 0.0, 0.0, 0.0);
    return;
  }
  V3Scale(out, v, 1.0 / len);
}

F32 DistXZ(Vec3 *a, Vec3 *b)
{
  F32 dx = a->x - b->x;
  F32 dz = a->z - b->z;
  return sqrt(dx * dx + dz * dz);
}

U0 YawForward(F32 yaw, Vec3 *out)
{
  V3Set(out, sin(yaw), 0.0, -cos(yaw));
}

U0 YawRight(F32 yaw, Vec3 *out)
{
  V3Set(out, cos(yaw), 0.0, sin(yaw));
}

F32 YawToward(Vec3 *from, Vec3 *to)
{
  return atan2(to->x - from->x, -(to->z - from->z));
}

U0 Mat4Identity(Mat4 *out)
{
  MemSet(out, 0, sizeof(Mat4));
  out->m[0] = 1.0;
  out->m[5] = 1.0;
  out->m[10] = 1.0;
  out->m[15] = 1.0;
}

U0 Mat4Perspective(Mat4 *out, F32 fovy, F32 aspect, F32 near, F32 far)
{
  F32 f = 1.0 / tan(fovy * 0.5);
  MemSet(out, 0, sizeof(Mat4));
  out->m[0] = f / aspect;
  out->m[5] = f;
  out->m[10] = (far + near) / (near - far);
  out->m[11] = -1.0;
  out->m[14] = (2.0 * far * near) / (near - far);
}

U0 Mat4Ortho(Mat4 *out, F32 left, F32 right, F32 bottom, F32 top)
{
  Mat4Identity(out);
  out->m[0] = 2.0 / (right - left);
  out->m[5] = 2.0 / (top - bottom);
  out->m[10] = -1.0;
  out->m[12] = -(right + left) / (right - left);
  out->m[13] = -(top + bottom) / (top - bottom);
}

U0 Mat4LookAt(Mat4 *out, Vec3 *eye, Vec3 *target, Vec3 *up)
{
  Vec3 f, s, u, d;
  V3Sub(&d, target, eye);
  V3Normalize(&f, &d);
  V3Cross(&d, &f, up);
  V3Normalize(&s, &d);
  V3Cross(&u, &s, &f);

  out->m[0] = s.x;  out->m[4] = s.y;  out->m[8] = s.z;
  out->m[1] = u.x;  out->m[5] = u.y;  out->m[9] = u.z;
  out->m[2] = -f.x; out->m[6] = -f.y; out->m[10] = -f.z;
  out->m[3] = 0.0;  out->m[7] = 0.0;  out->m[11] = 0.0;
  out->m[12] = -V3Dot(&s, eye);
  out->m[13] = -V3Dot(&u, eye);
  out->m[14] = V3Dot(&f, eye);
  out->m[15] = 1.0;
}

// Translate, then yaw about +Y, then scale. Yaw follows the same
// convention as the camera so an entity facing `yaw` looks where the
// player would at that yaw.
U0 Mat4Model(Mat4 *out, Vec3 *pos, F32 yaw, F32 sx, F32 sy, F32 sz)
{
  F32 c = cos(-yaw);
  F32 s = sin(-yaw);
  MemSet(out, 0, sizeof(Mat4));
  out->m[0] = c * sx;
  out->m[2] = -s * sx;
  out->m[5] = sy;
  out->m[8] = s * sz;
  out->m[10] = c * sz;
  out->m[12] = pos->x;
  out->m[13] = pos->y;
  out->m[14] = pos->z;
  out->m[15] = 1.0;
}

U0 RngSeed(Rng *rng, U64 seed)
{
  rng->state = seed;
  if (!rng->state)
    rng->state = 0x9E3779B97F4A7C15;
}

U64 RngNext(Rng *rng)
{
  U64 x = rng->state;
  x ^= x << 13;
  x ^= x >> 7;
  x ^= x << 17;
  rng->state = x;
  return x;
}

I64 RngRange(Rng *rng, I64 n)
{
  I64 v = (RngNext(rng) >> 33) & 0x7FFFFFFF;
  return v % n;
}

F32 RngFloat(Rng *rng)
{
  I64 bits = (RngNext(rng) >> 40) & 0xFFFFFF;
  F32 v = bits;
  return v / 16777216.0;
}

I64 Hash2(I64 x, I64 y, I64 seed)
{
  I64 h = x * 374761393 + y * 668265263 + seed * 144269504;
  h = (h ^ (h >> 13)) * 1274126177;
  return (h ^ (h >> 16)) & 0xFFFF;
}

F32 Hash2f(I64 x, I64 y, I64 seed)
{
  F32 v = Hash2(x, y, seed);
  return v / 65535.0;
}

// Tileable value noise: lattice coordinates wrap at `period` so textures
// built from it repeat without seams.
F32 ValueNoise(F32 x, F32 y, I64 period, I64 seed)
{
  I64 x0 = FloorToInt(x);
  I64 y0 = FloorToInt(y);
  F32 fx = x - x0;
  F32 fy = y - y0;
  fx = fx * fx * (3.0 - 2.0 * fx);
  fy = fy * fy * (3.0 - 2.0 * fy);

  I64 ax = ((x0 % period) + period) % period;
  I64 ay = ((y0 % period) + period) % period;
  I64 bx = (ax + 1) % period;
  I64 by = (ay + 1) % period;

  F32 top = Lerpf(Hash2f(ax, ay, seed), Hash2f(bx, ay, seed), fx);
  F32 bottom = Lerpf(Hash2f(ax, by, seed), Hash2f(bx, by, seed), fx);
  return Lerpf(top, bottom, fy);
}

F32 Fbm(F32 x, F32 y, I64 period, I64 seed, I64 octaves)
{
  F32 sum = 0.0;
  F32 amp = 0.5;
  F32 norm = 0.0;
  for (I64 i = 0; i < octaves; i++) {
    sum += ValueNoise(x, y, period, seed + i * 31) * amp;
    norm += amp;
    amp *= 0.5;
    x *= 2.0;
    y *= 2.0;
    period *= 2;
  }
  return sum / norm;
}
