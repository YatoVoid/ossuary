#ifdef IS_LINUX
#link <GL>
#endif

#define GL_DEPTH_BUFFER_BIT   0x00000100
#define GL_COLOR_BUFFER_BIT   0x00004000

#define GL_TRIANGLES          0x0004
#define GL_LEQUAL             0x0203
#define GL_SRC_ALPHA          0x0302
#define GL_ONE_MINUS_SRC_ALPHA 0x0303
#define GL_BACK               0x0405
#define GL_CULL_FACE          0x0B44
#define GL_DEPTH_TEST         0x0B71
#define GL_BLEND              0x0BE2
#define GL_UNPACK_ALIGNMENT   0x0CF5
#define GL_TEXTURE_2D         0x0DE1
#define GL_UNSIGNED_BYTE      0x1401
#define GL_FLOAT              0x1406
#define GL_RGBA               0x1908
#define GL_RENDERER           0x1F01
#define GL_VERSION            0x1F02
#define GL_NEAREST            0x2600
#define GL_LINEAR             0x2601
#define GL_NEAREST_MIPMAP_LINEAR 0x2702
#define GL_TEXTURE_MAG_FILTER 0x2800
#define GL_TEXTURE_MIN_FILTER 0x2801
#define GL_TEXTURE_WRAP_S     0x2802
#define GL_TEXTURE_WRAP_T     0x2803
#define GL_REPEAT             0x2901
#define GL_RGBA8              0x8058
#define GL_CLAMP_TO_EDGE      0x812F
#define GL_DEPTH_COMPONENT24  0x81A6
#define GL_TEXTURE0           0x84C0
#define GL_ARRAY_BUFFER       0x8892
#define GL_STREAM_DRAW        0x88E0
#define GL_STATIC_DRAW        0x88E4
#define GL_FRAGMENT_SHADER    0x8B30
#define GL_VERTEX_SHADER      0x8B31
#define GL_COMPILE_STATUS     0x8B81
#define GL_LINK_STATUS        0x8B82
#define GL_FRAMEBUFFER_COMPLETE 0x8CD5
#define GL_COLOR_ATTACHMENT0  0x8CE0
#define GL_DEPTH_ATTACHMENT   0x8D00
#define GL_FRAMEBUFFER        0x8D40
#define GL_RENDERBUFFER       0x8D41

extern "c" U8 *glGetString(U32 name);
extern "c" U0 glEnable(U32 cap);
extern "c" U0 glDisable(U32 cap);
extern "c" U0 glCullFace(U32 mode);
extern "c" U0 glDepthFunc(U32 func);
extern "c" U0 glDepthMask(U8 flag);
extern "c" U0 glBlendFunc(U32 src, U32 dst);
extern "c" U0 glViewport(I32 x, I32 y, I32 w, I32 h);
extern "c" U0 glClearColor(F32 r, F32 g, F32 b, F32 a);
extern "c" U0 glClear(U32 mask);
extern "c" U0 glPixelStorei(U32 name, I32 param);
extern "c" U0 glReadPixels(I32 x, I32 y, I32 w, I32 h, U32 format, U32 type, U0 *data);

extern "c" U32 glCreateShader(U32 type);
extern "c" U0 glShaderSource(U32 shader, I32 count, U8 **src, I32 *len);
extern "c" U0 glCompileShader(U32 shader);
extern "c" U0 glGetShaderiv(U32 shader, U32 name, I32 *out);
extern "c" U0 glGetShaderInfoLog(U32 shader, I32 max, I32 *len, U8 *log);
extern "c" U0 glDeleteShader(U32 shader);
extern "c" U32 glCreateProgram();
extern "c" U0 glAttachShader(U32 program, U32 shader);
extern "c" U0 glLinkProgram(U32 program);
extern "c" U0 glGetProgramiv(U32 program, U32 name, I32 *out);
extern "c" U0 glGetProgramInfoLog(U32 program, I32 max, I32 *len, U8 *log);
extern "c" U0 glUseProgram(U32 program);
extern "c" U0 glDeleteProgram(U32 program);
extern "c" I32 glGetUniformLocation(U32 program, U8 *name);
extern "c" U0 glUniform1i(I32 loc, I32 v);
extern "c" U0 glUniform1f(I32 loc, F32 v);
extern "c" U0 glUniform2f(I32 loc, F32 x, F32 y);
extern "c" U0 glUniform3f(I32 loc, F32 x, F32 y, F32 z);
extern "c" U0 glUniform1fv(I32 loc, I32 count, F32 *v);
extern "c" U0 glUniform3fv(I32 loc, I32 count, F32 *v);
extern "c" U0 glUniformMatrix4fv(I32 loc, I32 count, U8 transpose, F32 *v);

extern "c" U0 glGenVertexArrays(I32 n, U32 *out);
extern "c" U0 glBindVertexArray(U32 vao);
extern "c" U0 glDeleteVertexArrays(I32 n, U32 *vaos);
extern "c" U0 glGenBuffers(I32 n, U32 *out);
extern "c" U0 glBindBuffer(U32 target, U32 buffer);
extern "c" U0 glBufferData(U32 target, I64 size, U0 *data, U32 usage);
extern "c" U0 glDeleteBuffers(I32 n, U32 *buffers);
extern "c" U0 glVertexAttribPointer(U32 index, I32 size, U32 type, U8 norm, I32 stride, I64 offset);
extern "c" U0 glEnableVertexAttribArray(U32 index);
extern "c" U0 glDrawArrays(U32 mode, I32 first, I32 count);

extern "c" U0 glGenTextures(I32 n, U32 *out);
extern "c" U0 glBindTexture(U32 target, U32 tex);
extern "c" U0 glActiveTexture(U32 unit);
extern "c" U0 glTexImage2D(U32 target, I32 level, I32 internal, I32 w, I32 h, I32 border, U32 format, U32 type, U0 *data);
extern "c" U0 glTexParameteri(U32 target, U32 name, I32 param);
extern "c" U0 glGenerateMipmap(U32 target);
extern "c" U0 glDeleteTextures(I32 n, U32 *tex);

extern "c" U0 glGenFramebuffers(I32 n, U32 *out);
extern "c" U0 glBindFramebuffer(U32 target, U32 fbo);
extern "c" U0 glFramebufferTexture2D(U32 target, U32 attach, U32 textarget, U32 tex, I32 level);
extern "c" U32 glCheckFramebufferStatus(U32 target);
extern "c" U0 glDeleteFramebuffers(I32 n, U32 *fbos);
extern "c" U0 glGenRenderbuffers(I32 n, U32 *out);
extern "c" U0 glBindRenderbuffer(U32 target, U32 rbo);
extern "c" U0 glRenderbufferStorage(U32 target, U32 format, I32 w, I32 h);
extern "c" U0 glFramebufferRenderbuffer(U32 target, U32 attach, U32 rbtarget, U32 rbo);
extern "c" U0 glDeleteRenderbuffers(I32 n, U32 *rbos);
