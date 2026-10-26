#define TEX_SIZE 64

class Image
{
  I64 width;
  I64 height;
  U8 *pixels;
};

U0 ImageInit(Image *img, Arena *arena, I64 width, I64 height)
{
  img->width = width;
  img->height = height;
  img->pixels = ArenaPush(arena, width * height * 4);
}

U8 ToByte(F32 v)
{
  I64 b = Saturate(v) * 255.0;
  return b;
}

U0 ImagePut(Image *img, I64 x, I64 y, F32 r, F32 g, F32 b, F32 a = 1.0)
{
  U8 *p = img->pixels + (y * img->width + x) * 4;
  p[0] = ToByte(r);
  p[1] = ToByte(g);
  p[2] = ToByte(b);
  p[3] = ToByte(a);
}

U32 TextureUpload(Image *img, Bool repeat, Bool mipmaps)
{
  U32 tex;
  glGenTextures(1, &tex);
  glBindTexture(GL_TEXTURE_2D, tex);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, img->width, img->height, 0,
               GL_RGBA, GL_UNSIGNED_BYTE, img->pixels);

  I32 wrap = GL_CLAMP_TO_EDGE;
  if (repeat)
    wrap = GL_REPEAT;
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  if (mipmaps) {
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
  } else {
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  }
  return tex;
}

// Offset-row bricks, 4 courses per tile. Each brick gets its own tint and
// the bottom course picks up damp staining.
U0 ImageBrick(Image *img)
{
  I64 brick_w = 32, brick_h = 16, mortar = 2;
  for (I64 y = 0; y < img->height; y++) {
    I64 row = y / brick_h;
    I64 offset = (row & 1) * (brick_w / 2);
    for (I64 x = 0; x < img->width; x++) {
      I64 bx = (x + offset) % img->width;
      I64 col = bx / brick_w;
      I64 lx = bx % brick_w;
      I64 ly = y % brick_h;
      F32 grain = Fbm(x / 8.0, y / 8.0, 8, 11, 3);
      F32 fy = y;

      if (lx < mortar || ly < mortar) {
        F32 m = 0.16 + grain * 0.08;
        ImagePut(img, x, y, m, m * 0.95, m * 0.9);
        continue;
      }

      F32 tint = Hash2f(col, row, 3);
      F32 base = 0.36 + tint * 0.14;
      F32 edge = 1.0;
      if (lx == mortar || ly == mortar)
        edge = 1.18;
      if (lx == brick_w - 1 || ly == brick_h - 1)
        edge = 0.72;
      F32 chip = Hash2f(x / 2, y / 2, 7);
      if (chip > 0.985)
        edge *= 0.8;
      F32 damp = Smoothstep(40.0, 64.0, fy) * 0.25;
      F32 v = base * edge * (0.75 + grain * 0.5) * (1.0 - damp);
      ImagePut(img, x, y, v * 1.08, v * 0.94, v * 0.82);
    }
  }
}

// Two-by-two flagstones with uneven gaps and worn centres.
U0 ImageFlagstone(Image *img)
{
  I64 stone = 32;
  for (I64 y = 0; y < img->height; y++) {
    for (I64 x = 0; x < img->width; x++) {
      I64 sx = x / stone, sy = y / stone;
      I64 lx = x % stone, ly = y % stone;
      F32 grain = Fbm(x / 6.0, y / 6.0, 10, 21, 3);
      I64 gap = 1 + (Hash2(sx, sy, 5) & 1);

      if (lx < gap || ly < gap) {
        F32 m = 0.07 + grain * 0.05;
        ImagePut(img, x, y, m, m, m * 1.05);
        continue;
      }

      F32 cx = lx - stone / 2, cy = ly - stone / 2;
      F32 wear = 1.0 - (cx * cx + cy * cy) / 512.0;
      F32 tint = Hash2f(sx, sy, 9);
      F32 v = (0.26 + tint * 0.1) * (0.7 + grain * 0.6) * (0.85 + wear * 0.15);
      ImagePut(img, x, y, v * 0.95, v * 0.97, v * 1.04);
    }
  }
}

U0 ImageRock(Image *img)
{
  for (I64 y = 0; y < img->height; y++) {
    for (I64 x = 0; x < img->width; x++) {
      F32 n = Fbm(x / 10.0, y / 10.0, 7, 41, 4);
      F32 crack = Absf(ValueNoise(x / 5.0, y / 5.0, 13, 43) - 0.5);
      F32 v = 0.12 + n * 0.22;
      if (crack < 0.03)
        v *= 0.55;
      ImagePut(img, x, y, v, v * 0.96, v * 0.92);
    }
  }
}

U0 ImageCloth(Image *img)
{
  for (I64 y = 0; y < img->height; y++) {
    for (I64 x = 0; x < img->width; x++) {
      F32 streak = ValueNoise(x / 2.0, y / 24.0, 32, 61);
      F32 n = Fbm(x / 6.0, y / 6.0, 10, 63, 3);
      F32 v = 0.09 + streak * 0.1 + n * 0.06;
      ImagePut(img, x, y, v * 1.1, v * 0.9, v * 0.85);
    }
  }
}

U0 ImageIron(Image *img)
{
  for (I64 y = 0; y < img->height; y++) {
    for (I64 x = 0; x < img->width; x++) {
      F32 rust = Fbm(x / 7.0, y / 7.0, 9, 71, 4);
      F32 v = 0.22 + rust * 0.2;
      F32 r = v, g = v, b = v * 1.05;
      if (rust > 0.58) {
        r = v * 1.35;
        g = v * 0.8;
        b = v * 0.5;
      }
      ImagePut(img, x, y, r, g, b);
    }
  }
}

U32 TextureSolid(Arena *scratch, F32 r, F32 g, F32 b)
{
  Image img;
  ImageInit(&img, scratch, 2, 2);
  for (I64 i = 0; i < 4; i++)
    ImagePut(&img, i % 2, i / 2, r, g, b);
  return TextureUpload(&img, TRUE, FALSE);
}

U32 TextureGenerate(Arena *scratch, U0 (*fill)(Image *))
{
  I64 mark = scratch->used;
  Image img;
  ImageInit(&img, scratch, TEX_SIZE, TEX_SIZE);
  fill(&img);
  U32 tex = TextureUpload(&img, TRUE, TRUE);
  scratch->used = mark;
  return tex;
}
