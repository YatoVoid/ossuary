#define MAX_LIGHTS      8
#define SCENE_HEIGHT    240
#define FOG_DENSITY     0.085

class Renderer
{
  U32 world;
  I32 u_proj, u_view, u_model, u_snap, u_tex, u_tint, u_emissive;
  I32 u_light_count, u_light_pos, u_light_color, u_light_radius;
  I32 u_ambient, u_fog_color, u_fog_density;

  U32 post;
  I32 p_scene, p_resolution, p_time, p_dread, p_fade, p_fade_color;

  U32 tex_wall, tex_floor, tex_ceiling, tex_cloth, tex_iron, tex_white;
  Mesh box;
  Mesh relic;

  U32 fbo, fbo_color, fbo_depth;
  I64 scene_w, scene_h;
  U32 empty_vao;

  Vec3 eye;
  I64 light_count;
  F32 light_pos[MAX_LIGHTS * 3];
  F32 light_color[MAX_LIGHTS * 3];
  F32 light_radius[MAX_LIGHTS];
  F32 light_dist[MAX_LIGHTS];

  UiBatch ui;
};

class SceneParams
{
  F32 time;
  F32 lantern;
  F32 dread;
  F32 fade;
  Color fade_color;
};

U0 RendererInit(Renderer *r, U8 *asset_dir, Arena *scratch)
{
  MemSet(r, 0, sizeof(Renderer));

  r->world = ShaderLoad(asset_dir, "world");
  r->u_proj = ShaderUniform(r->world, "u_proj");
  r->u_view = ShaderUniform(r->world, "u_view");
  r->u_model = ShaderUniform(r->world, "u_model");
  r->u_snap = ShaderUniform(r->world, "u_snap");
  r->u_tex = ShaderUniform(r->world, "u_tex");
  r->u_tint = ShaderUniform(r->world, "u_tint");
  r->u_emissive = ShaderUniform(r->world, "u_emissive");
  r->u_light_count = ShaderUniform(r->world, "u_light_count");
  r->u_light_pos = ShaderUniform(r->world, "u_light_pos");
  r->u_light_color = ShaderUniform(r->world, "u_light_color");
  r->u_light_radius = ShaderUniform(r->world, "u_light_radius");
  r->u_ambient = ShaderUniform(r->world, "u_ambient");
  r->u_fog_color = ShaderUniform(r->world, "u_fog_color");
  r->u_fog_density = ShaderUniform(r->world, "u_fog_density");

  r->post = ShaderLoad(asset_dir, "post");
  r->p_scene = ShaderUniform(r->post, "u_scene");
  r->p_resolution = ShaderUniform(r->post, "u_resolution");
  r->p_time = ShaderUniform(r->post, "u_time");
  r->p_dread = ShaderUniform(r->post, "u_dread");
  r->p_fade = ShaderUniform(r->post, "u_fade");
  r->p_fade_color = ShaderUniform(r->post, "u_fade_color");

  r->tex_wall = TextureGenerate(scratch, &ImageBrick);
  r->tex_floor = TextureGenerate(scratch, &ImageFlagstone);
  r->tex_ceiling = TextureGenerate(scratch, &ImageRock);
  r->tex_cloth = TextureGenerate(scratch, &ImageCloth);
  r->tex_iron = TextureGenerate(scratch, &ImageIron);
  r->tex_white = TextureSolid(scratch, 1.0, 1.0, 1.0);

  MeshBuildBox(&r->box, scratch);
  MeshBuildRelic(&r->relic, scratch);
  glGenVertexArrays(1, &r->empty_vao);

  UiInit(&r->ui, asset_dir, scratch);
}

U0 RendererFreeTarget(Renderer *r)
{
  if (!r->fbo)
    return;
  glDeleteFramebuffers(1, &r->fbo);
  glDeleteTextures(1, &r->fbo_color);
  glDeleteRenderbuffers(1, &r->fbo_depth);
  r->fbo = 0;
}

// The scene is drawn into a small fixed-height target and scaled up with
// nearest filtering, which is where the chunky pixel look comes from.
U0 RendererEnsureTarget(Renderer *r, I64 win_w, I64 win_h)
{
  I64 h = SCENE_HEIGHT;
  I64 w = (h * win_w) / win_h;
  if (r->fbo && w == r->scene_w && h == r->scene_h)
    return;
  RendererFreeTarget(r);
  r->scene_w = w;
  r->scene_h = h;

  glGenTextures(1, &r->fbo_color);
  glBindTexture(GL_TEXTURE_2D, r->fbo_color);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glGenRenderbuffers(1, &r->fbo_depth);
  glBindRenderbuffer(GL_RENDERBUFFER, r->fbo_depth);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, w, h);

  glGenFramebuffers(1, &r->fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, r->fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, r->fbo_color, 0);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, r->fbo_depth);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    Fatal("scene framebuffer incomplete");
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

// Keeps the closest MAX_LIGHTS - 1 lights to the eye. Slot 0 belongs to
// the lantern and is never evicted.
U0 RendererAddLight(Renderer *r, Vec3 *pos, F32 red, F32 green, F32 blue, F32 radius)
{
  Vec3 rel;
  V3Sub(&rel, pos, &r->eye);
  F32 dist = V3Length(&rel);
  if (dist > radius + 24.0)
    return;

  I64 slot = r->light_count;
  if (slot >= MAX_LIGHTS) {
    slot = -1;
    F32 worst = dist;
    for (I64 i = 1; i < MAX_LIGHTS; i++) {
      if (r->light_dist[i] > worst) {
        worst = r->light_dist[i];
        slot = i;
      }
    }
    if (slot < 0)
      return;
  } else {
    r->light_count++;
  }

  r->light_pos[slot * 3] = pos->x;
  r->light_pos[slot * 3 + 1] = pos->y;
  r->light_pos[slot * 3 + 2] = pos->z;
  r->light_color[slot * 3] = red;
  r->light_color[slot * 3 + 1] = green;
  r->light_color[slot * 3 + 2] = blue;
  r->light_radius[slot] = radius;
  r->light_dist[slot] = dist;
}

F32 Flicker(F32 t, F32 phase)
{
  return 0.82 + 0.1 * sin(t * 9.0 + phase) + 0.08 * sin(t * 23.0 + phase * 2.3);
}

U0 RendererGatherLights(Renderer *r, World *w, Camera *cam, SceneParams *sp)
{
  r->eye = cam->pos;
  r->light_count = 0;

  Vec3 lamp, right;
  YawRight(cam->yaw, &right);
  V3AddScaled(&lamp, &cam->pos, &right, 0.25);
  lamp.y -= 0.25;
  F32 shake = 1.0 - sp->dread * 0.35 * (0.5 + 0.5 * sin(sp->time * 31.0));
  F32 glow = sp->lantern * Flicker(sp->time, 0.0) * shake;
  if (sp->lantern > 0.0)
    RendererAddLight(r, &lamp, 1.3 * glow, 0.85 * glow, 0.5 * glow, 12.0);
  else
    RendererAddLight(r, &lamp, 0.05, 0.06, 0.09, 3.0);

  for (I64 i = 0; i < w->ents.count; i++) {
    Entity *e = &w->ents.items[i];
    if (!e->active)
      continue;
    Vec3 at = e->pos;
    switch (e->kind) {
      case ENT_CANDLE: {
        F32 f = Flicker(sp->time, e->phase);
        at.y = 0.45;
        RendererAddLight(r, &at, 1.1 * f, 0.55 * f, 0.22 * f, 5.5);
        break;
      }
      case ENT_RELIC:
        at.y = 1.1;
        RendererAddLight(r, &at, 0.3, 0.75, 0.7, 4.0);
        break;
      case ENT_WARDEN:
        if (e->state == WARDEN_HUNT) {
          at.y = 1.9;
          RendererAddLight(r, &at, 0.7, 0.05, 0.03, 3.5);
        }
        break;
    }
  }

  if (w->level.gate_open) {
    Vec3 sky;
    LevelCellCenter(w->exit_x, w->exit_z, &sky);
    sky.y = WALL_HEIGHT + 1.0;
    RendererAddLight(r, &sky, 0.35, 0.45, 0.7, 9.0);
  }
}

U0 RendererDrawPart(Renderer *r, Mesh *mesh, U32 tex, Vec3 *pos, F32 yaw,
                    F32 sx, F32 sy, F32 sz, F32 tr, F32 tg, F32 tb,
                    F32 er = 0.0, F32 eg = 0.0, F32 eb = 0.0)
{
  Mat4 model;
  Mat4Model(&model, pos, yaw, sx, sy, sz);
  ShaderSetMat4(r->u_model, &model);
  glUniform3f(r->u_tint, tr, tg, tb);
  glUniform3f(r->u_emissive, er, eg, eb);
  glBindTexture(GL_TEXTURE_2D, tex);
  MeshDraw(mesh);
}

U0 RendererDrawWarden(Renderer *r, Entity *e, F32 t)
{
  Vec3 fwd, right, at;
  YawForward(e->yaw, &fwd);
  YawRight(e->yaw, &right);

  F32 stride = sin(e->anim * e->speed * 2.2);
  F32 lean = 0.0;
  if (e->state == WARDEN_HUNT)
    lean = 0.12;

  at = e->pos;
  V3AddScaled(&at, &at, &fwd, lean * 0.5);
  RendererDrawPart(r, &r->box, r->tex_cloth, &at, e->yaw, 0.62, 1.85, 0.42, 1.0, 1.0, 1.0);

  V3AddScaled(&at, &e->pos, &fwd, lean);
  at.y = 1.85;
  F32 tilt = sin(t * 0.7) * 0.15;
  RendererDrawPart(r, &r->box, r->tex_cloth, &at, e->yaw + tilt, 0.36, 0.38, 0.36, 0.8, 0.8, 0.8);

  F32 eye = 0.5;
  if (e->state == WARDEN_SEARCH)
    eye = 1.2;
  if (e->state == WARDEN_HUNT)
    eye = 2.4;
  for (I64 side = -1; side <= 1; side += 2) {
    V3AddScaled(&at, &e->pos, &fwd, lean + 0.19);
    V3AddScaled(&at, &at, &right, side * 0.08);
    at.y = 2.0;
    RendererDrawPart(r, &r->box, r->tex_white, &at, e->yaw, 0.06, 0.04, 0.04,
                     0.0, 0.0, 0.0, eye, eye * 0.12, eye * 0.05);

    V3AddScaled(&at, &e->pos, &right, side * 0.4);
    V3AddScaled(&at, &at, &fwd, stride * side * 0.12 + lean);
    at.y = 0.42;
    RendererDrawPart(r, &r->box, r->tex_cloth, &at, e->yaw, 0.11, 1.3, 0.11, 0.9, 0.85, 0.85);
  }
}

U0 RendererDrawGate(Renderer *r, Entity *e)
{
  Vec3 right, at;
  YawRight(e->yaw, &right);
  F32 lift = Smoothstep(0.0, 1.0, e->anim) * (WALL_HEIGHT - 0.25);

  for (I64 i = 0; i < 5; i++) {
    V3AddScaled(&at, &e->pos, &right, -0.8 + i * 0.4);
    at.y = lift;
    RendererDrawPart(r, &r->box, r->tex_iron, &at, e->yaw, 0.09, WALL_HEIGHT, 0.09, 1.0, 1.0, 1.0);
  }
  for (I64 j = 0; j < 2; j++) {
    at = e->pos;
    at.y = lift + 0.4 + j * 1.4;
    RendererDrawPart(r, &r->box, r->tex_iron, &at, e->yaw, CELL_SIZE, 0.08, 0.12, 1.0, 1.0, 1.0);
  }
}

U0 RendererDrawEntities(Renderer *r, World *w, F32 t)
{
  for (I64 i = 0; i < w->ents.count; i++) {
    Entity *e = &w->ents.items[i];
    if (!e->active)
      continue;
    Vec3 at = e->pos;
    switch (e->kind) {
      case ENT_CANDLE: {
        RendererDrawPart(r, &r->box, r->tex_white, &at, 0.0, 0.1, 0.26, 0.1, 0.8, 0.75, 0.6);
        F32 f = Flicker(t, e->phase);
        at.y = 0.27;
        RendererDrawPart(r, &r->box, r->tex_white, &at, t * 3.0, 0.045, 0.09 * f, 0.045,
                         0.0, 0.0, 0.0, 1.6 * f, 0.85 * f, 0.3 * f);
        break;
      }
      case ENT_RELIC: {
        RendererDrawPart(r, &r->box, r->tex_wall, &at, 0.0, 0.55, 0.7, 0.55, 0.9, 0.9, 0.9);
        F32 pulse = 0.75 + 0.25 * sin(e->phase * 2.5);
        at.y = 0.85 + sin(e->phase * 1.7) * 0.06;
        RendererDrawPart(r, &r->relic, r->tex_white, &at, e->phase * 1.3, 0.75, 0.55, 0.75,
                         0.3, 0.6, 0.55, 0.25 * pulse, 0.7 * pulse, 0.62 * pulse);
        break;
      }
      case ENT_WARDEN:
        RendererDrawWarden(r, e, t);
        break;
      case ENT_GATE:
        RendererDrawGate(r, e);
        break;
    }
  }
}

U0 RendererDrawScene(Renderer *r, World *w, Camera *cam, SceneParams *sp, I64 win_w, I64 win_h)
{
  RendererEnsureTarget(r, win_w, win_h);
  F32 aspect = r->scene_w;
  aspect /= r->scene_h;
  CameraUpdate(cam, aspect);
  RendererGatherLights(r, w, cam, sp);

  glBindFramebuffer(GL_FRAMEBUFFER, r->fbo);
  glViewport(0, 0, r->scene_w, r->scene_h);
  glClearColor(0.01, 0.012, 0.02, 1.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_CULL_FACE);
  glCullFace(GL_BACK);

  glUseProgram(r->world);
  ShaderSetMat4(r->u_proj, &cam->proj);
  ShaderSetMat4(r->u_view, &cam->view);
  glUniform2f(r->u_snap, r->scene_w * 0.5, r->scene_h * 0.5);
  glUniform1i(r->u_tex, 0);
  glActiveTexture(GL_TEXTURE0);
  glUniform1i(r->u_light_count, r->light_count);
  glUniform3fv(r->u_light_pos, r->light_count, r->light_pos);
  glUniform3fv(r->u_light_color, r->light_count, r->light_color);
  glUniform1fv(r->u_light_radius, r->light_count, r->light_radius);
  glUniform3f(r->u_ambient, 0.04, 0.04, 0.055);
  glUniform3f(r->u_fog_color, 0.01, 0.012, 0.02);
  glUniform1f(r->u_fog_density, FOG_DENSITY);

  Vec3 origin;
  V3Set(&origin, 0.0, 0.0, 0.0);
  RendererDrawPart(r, &w->level.walls, r->tex_wall, &origin, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
  RendererDrawPart(r, &w->level.floor, r->tex_floor, &origin, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
  RendererDrawPart(r, &w->level.ceiling, r->tex_ceiling, &origin, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
  RendererDrawEntities(r, w, sp->time);

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glViewport(0, 0, win_w, win_h);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  glUseProgram(r->post);
  glBindTexture(GL_TEXTURE_2D, r->fbo_color);
  glUniform1i(r->p_scene, 0);
  glUniform2f(r->p_resolution, r->scene_w, r->scene_h);
  glUniform1f(r->p_time, sp->time);
  glUniform1f(r->p_dread, sp->dread);
  glUniform1f(r->p_fade, sp->fade);
  glUniform3f(r->p_fade_color, sp->fade_color.r, sp->fade_color.g, sp->fade_color.b);
  glBindVertexArray(r->empty_vao);
  glDrawArrays(GL_TRIANGLES, 0, 3);
}
