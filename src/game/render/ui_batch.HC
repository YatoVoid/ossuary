#define UI_MAX_QUADS      4096
#define UI_VERTEX_FLOATS  8
#define UI_VERTEX_STRIDE  32
#define UI_QUAD_FLOATS    (6 * UI_VERTEX_FLOATS)

class UiBatch
{
  U32 program;
  I32 u_proj;
  I32 u_font;
  U32 vao;
  U32 vbo;
  U32 font;
  F32 *verts;
  I64 quads;
  F32 width;
  F32 height;
  F32 scale;
};

U0 UiInit(UiBatch *ui, U8 *asset_dir, Arena *scratch)
{
  MemSet(ui, 0, sizeof(UiBatch));
  ui->program = ShaderLoad(asset_dir, "ui");
  ui->u_proj = ShaderUniform(ui->program, "u_proj");
  ui->u_font = ShaderUniform(ui->program, "u_font");
  ui->font = FontBuildAtlas(scratch);
  ui->verts = MemZalloc(UI_MAX_QUADS * UI_QUAD_FLOATS * sizeof(F32));

  glGenVertexArrays(1, &ui->vao);
  glBindVertexArray(ui->vao);
  glGenBuffers(1, &ui->vbo);
  glBindBuffer(GL_ARRAY_BUFFER, ui->vbo);
  glBufferData(GL_ARRAY_BUFFER, UI_MAX_QUADS * UI_QUAD_FLOATS * sizeof(F32), NULL, GL_STREAM_DRAW);
  glVertexAttribPointer(0, 2, GL_FLOAT, 0, UI_VERTEX_STRIDE, 0);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(1, 2, GL_FLOAT, 0, UI_VERTEX_STRIDE, 8);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(2, 4, GL_FLOAT, 0, UI_VERTEX_STRIDE, 16);
  glEnableVertexAttribArray(2);
  glBindVertexArray(0);
}

U0 UiBegin(UiBatch *ui, I64 width, I64 height)
{
  ui->quads = 0;
  ui->width = width;
  ui->height = height;
  I64 s = height / 270;
  if (s < 1)
    s = 1;
  ui->scale = s;
}

U0 UiVertex(F32 *v, F32 x, F32 y, F32 u, F32 t, Color *c)
{
  v[0] = x; v[1] = y; v[2] = u; v[3] = t;
  v[4] = c->r; v[5] = c->g; v[6] = c->b; v[7] = c->a;
}

U0 UiQuad(UiBatch *ui, F32 x, F32 y, F32 w, F32 h,
          F32 u0, F32 v0, F32 u1, F32 v1, Color *c)
{
  if (ui->quads >= UI_MAX_QUADS)
    return;
  F32 *v = ui->verts + ui->quads * UI_QUAD_FLOATS;
  UiVertex(v,      x,     y,     u0, v0, c);
  UiVertex(v + 8,  x,     y + h, u0, v1, c);
  UiVertex(v + 16, x + w, y + h, u1, v1, c);
  UiVertex(v + 24, x,     y,     u0, v0, c);
  UiVertex(v + 32, x + w, y + h, u1, v1, c);
  UiVertex(v + 40, x + w, y,     u1, v0, c);
  ui->quads++;
}

U0 UiRect(UiBatch *ui, F32 x, F32 y, F32 w, F32 h, Color *c)
{
  F32 u = ((FONT_SOLID % FONT_COLS) * FONT_CELL + 4.0) / FONT_ATLAS_W;
  F32 v = ((FONT_SOLID / FONT_COLS) * FONT_CELL + 4.0) / FONT_ATLAS_H;
  UiQuad(ui, x, y, w, h, u, v, u, v, c);
}

F32 UiTextWidth(UiBatch *ui, U8 *text, F32 size)
{
  I64 len = StrLen(text);
  if (len == 0)
    return 0.0;
  F32 px = size * ui->scale;
  return (len * FONT_ADVANCE - 1) * px;
}

F32 UiLineHeight(UiBatch *ui, F32 size)
{
  return (FONT_GLYPH_H + 3) * size * ui->scale;
}

U0 UiText(UiBatch *ui, F32 x, F32 y, F32 size, U8 *text, Color *c)
{
  F32 px = size * ui->scale;
  F32 pen = x;
  for (U8 *s = text; *s; s++) {
    if (*s != ' ') {
      I64 g = FontGlyphIndex(*s);
      F32 gx = (g % FONT_COLS) * FONT_CELL;
      F32 gy = (g / FONT_COLS) * FONT_CELL;
      UiQuad(ui, pen, y, FONT_GLYPH_W * px, FONT_GLYPH_H * px,
             gx / FONT_ATLAS_W, gy / FONT_ATLAS_H,
             (gx + FONT_GLYPH_W) / FONT_ATLAS_W, (gy + FONT_GLYPH_H) / FONT_ATLAS_H, c);
    }
    pen += FONT_ADVANCE * px;
  }
}

U0 UiTextCentered(UiBatch *ui, F32 y, F32 size, U8 *text, Color *c)
{
  F32 x = floor((ui->width - UiTextWidth(ui, text, size)) * 0.5);
  UiText(ui, x, y, size, text, c);
}

U0 UiTextShadowed(UiBatch *ui, F32 x, F32 y, F32 size, U8 *text, Color *c)
{
  Color shadow;
  shadow.r = 0.0; shadow.g = 0.0; shadow.b = 0.0; shadow.a = c->a * 0.8;
  F32 off = ui->scale;
  UiText(ui, x + off, y + off, size, text, &shadow);
  UiText(ui, x, y, size, text, c);
}

U0 UiEnd(UiBatch *ui)
{
  if (ui->quads == 0)
    return;

  Mat4 proj;
  Mat4Ortho(&proj, 0.0, ui->width, ui->height, 0.0);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glUseProgram(ui->program);
  ShaderSetMat4(ui->u_proj, &proj);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, ui->font);
  glUniform1i(ui->u_font, 0);

  glBindVertexArray(ui->vao);
  glBindBuffer(GL_ARRAY_BUFFER, ui->vbo);
  glBufferData(GL_ARRAY_BUFFER, ui->quads * UI_QUAD_FLOATS * sizeof(F32), ui->verts, GL_STREAM_DRAW);
  glDrawArrays(GL_TRIANGLES, 0, ui->quads * 6);
  glDisable(GL_BLEND);
}

U0 ColorSet(Color *c, F32 r, F32 g, F32 b, F32 a = 1.0)
{
  c->r = r;
  c->g = g;
  c->b = b;
  c->a = a;
}
