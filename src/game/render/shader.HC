#define SHADER_LOG_BYTES 2048

U32 ShaderCompile(U32 type, U8 *src, U8 *label)
{
  U32 shader = glCreateShader(type);
  glShaderSource(shader, 1, &src, NULL);
  glCompileShader(shader);

  I32 ok = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    U8 log[SHADER_LOG_BYTES];
    glGetShaderInfoLog(shader, SHADER_LOG_BYTES, NULL, log);
    "%s:\n%s\n", label, log;
    Fatal("shader failed to compile:", label);
  }
  return shader;
}

U32 ShaderLink(U8 *name, U8 *vs_src, U8 *fs_src)
{
  U8 *vs_label = MStrPrint("%s.vert", name);
  U8 *fs_label = MStrPrint("%s.frag", name);
  U32 vs = ShaderCompile(GL_VERTEX_SHADER, vs_src, vs_label);
  U32 fs = ShaderCompile(GL_FRAGMENT_SHADER, fs_src, fs_label);
  Free(vs_label);
  Free(fs_label);

  U32 program = glCreateProgram();
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  glLinkProgram(program);
  glDeleteShader(vs);
  glDeleteShader(fs);

  I32 ok = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &ok);
  if (!ok) {
    U8 log[SHADER_LOG_BYTES];
    glGetProgramInfoLog(program, SHADER_LOG_BYTES, NULL, log);
    "%s:\n%s\n", name, log;
    Fatal("shader program failed to link:", name);
  }
  return program;
}

U8 *ShaderReadSource(U8 *dir, U8 *file)
{
  U8 *path = MStrPrint("%sshaders/%s", dir, file);
  U8 *src = FileRead(path);
  if (!src)
    Fatal("missing shader source", path);
  Free(path);
  return src;
}

U32 ShaderLoad(U8 *asset_dir, U8 *name)
{
  U8 *vs_file = MStrPrint("%s.vert", name);
  U8 *fs_file = MStrPrint("%s.frag", name);
  U8 *vs = ShaderReadSource(asset_dir, vs_file);
  U8 *fs = ShaderReadSource(asset_dir, fs_file);
  U32 program = ShaderLink(name, vs, fs);
  Free(vs);
  Free(fs);
  Free(vs_file);
  Free(fs_file);
  return program;
}

I32 ShaderUniform(U32 program, U8 *name)
{
  return glGetUniformLocation(program, name);
}

U0 ShaderSetMat4(I32 loc, Mat4 *m)
{
  glUniformMatrix4fv(loc, 1, 0, m->m);
}
