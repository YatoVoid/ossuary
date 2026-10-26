#link <SDL2>

#define SDL_INIT_TIMER    0x0001
#define SDL_INIT_VIDEO    0x0020
#define SDL_INIT_EVENTS   0x4000

#define SDL_WINDOW_OPENGL        0x0002
#define SDL_WINDOW_SHOWN         0x0004
#define SDL_WINDOW_RESIZABLE     0x0020
#define SDL_WINDOW_INPUT_FOCUS   0x0200
#define SDL_WINDOW_ALLOW_HIGHDPI 0x2000
#define SDL_WINDOWPOS_CENTERED   0x2FFF0000

#define SDL_GL_RED_SIZE              0
#define SDL_GL_GREEN_SIZE            1
#define SDL_GL_BLUE_SIZE             2
#define SDL_GL_DOUBLEBUFFER          5
#define SDL_GL_DEPTH_SIZE            6
#define SDL_GL_CONTEXT_MAJOR_VERSION 17
#define SDL_GL_CONTEXT_MINOR_VERSION 18
#define SDL_GL_CONTEXT_FLAGS         20
#define SDL_GL_CONTEXT_PROFILE_MASK  21

#define SDL_GL_CONTEXT_PROFILE_CORE          0x0001
#define SDL_GL_CONTEXT_FORWARD_COMPATIBLE    0x0002

#define SDL_QUIT 0x100

#define SDL_EVENT_BYTES 64

#define SC_A      4
#define SC_D      7
#define SC_F      9
#define SC_P      19
#define SC_Q      20
#define SC_S      22
#define SC_W      26
#define SC_RETURN 40
#define SC_ESCAPE 41
#define SC_SPACE  44
#define SC_F3     60
#define SC_RIGHT  79
#define SC_LEFT   80
#define SC_DOWN   81
#define SC_UP     82
#define SC_LSHIFT 225
#define SC_RSHIFT 229

extern "c" I32 SDL_Init(U32 flags);
extern "c" U0 SDL_Quit();
extern "c" U8 *SDL_GetError();
extern "c" U8 *SDL_GetBasePath();
extern "c" U0 SDL_free(U0 *ptr);

extern "c" U0 *SDL_CreateWindow(U8 *title, I32 x, I32 y, I32 w, I32 h, U32 flags);
extern "c" U0 SDL_DestroyWindow(U0 *window);
extern "c" U32 SDL_GetWindowFlags(U0 *window);
extern "c" U0 SDL_SetWindowMinimumSize(U0 *window, I32 w, I32 h);

extern "c" I32 SDL_GL_SetAttribute(I32 attr, I32 value);
extern "c" U0 *SDL_GL_CreateContext(U0 *window);
extern "c" U0 SDL_GL_DeleteContext(U0 *context);
extern "c" I32 SDL_GL_SetSwapInterval(I32 interval);
extern "c" U0 SDL_GL_SwapWindow(U0 *window);
extern "c" U0 SDL_GL_GetDrawableSize(U0 *window, I32 *w, I32 *h);

extern "c" I32 SDL_PollEvent(U0 *event);
extern "c" U8 *SDL_GetKeyboardState(I32 *numkeys);
extern "c" U32 SDL_GetRelativeMouseState(I32 *x, I32 *y);
extern "c" I32 SDL_SetRelativeMouseMode(I32 enabled);

extern "c" U64 SDL_GetPerformanceCounter();
extern "c" U64 SDL_GetPerformanceFrequency();
