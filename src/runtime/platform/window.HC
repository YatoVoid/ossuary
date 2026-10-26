class Window
{
  U0 *handle;
  U0 *context;
  I64 width;
  I64 height;
  Bool mouse_captured;
  Bool quit_requested;
};

Bool WindowOpen(Window *win, U8 *title, I64 width, I64 height)
{
  MemSet(win, 0, sizeof(Window));

  if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_EVENTS) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return FALSE;
  }

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

  U32 flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE |
              SDL_WINDOW_ALLOW_HIGHDPI;
  win->handle = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED,
                                 SDL_WINDOWPOS_CENTERED, width, height, flags);
  if (!win->handle) {
    "SDL_CreateWindow failed: %s\n", SDL_GetError();
    SDL_Quit();
    return FALSE;
  }
  SDL_SetWindowMinimumSize(win->handle, 640, 360);

  win->context = SDL_GL_CreateContext(win->handle);
  if (!win->context) {
    "OpenGL 3.3 core context unavailable: %s\n", SDL_GetError();
    SDL_DestroyWindow(win->handle);
    SDL_Quit();
    return FALSE;
  }

  if (SDL_GL_SetSwapInterval(-1) != 0)
    SDL_GL_SetSwapInterval(1);

  "OpenGL %s on %s\n", glGetString(GL_VERSION), glGetString(GL_RENDERER);

  I32 w, h;
  SDL_GL_GetDrawableSize(win->handle, &w, &h);
  win->width = w;
  win->height = h;
  return TRUE;
}

U0 WindowClose(Window *win)
{
  if (win->mouse_captured)
    SDL_SetRelativeMouseMode(0);
  if (win->context)
    SDL_GL_DeleteContext(win->context);
  if (win->handle)
    SDL_DestroyWindow(win->handle);
  SDL_Quit();
}

U0 WindowPump(Window *win)
{
  U8 event[SDL_EVENT_BYTES];
  while (SDL_PollEvent(event)) {
    U32 *type = event;
    if (*type == SDL_QUIT)
      win->quit_requested = TRUE;
  }

  I32 w, h;
  SDL_GL_GetDrawableSize(win->handle, &w, &h);
  win->width = w;
  win->height = h;
}

U0 WindowSwap(Window *win)
{
  SDL_GL_SwapWindow(win->handle);
}

Bool WindowFocused(Window *win)
{
  if (SDL_GetWindowFlags(win->handle) & SDL_WINDOW_INPUT_FOCUS)
    return TRUE;
  return FALSE;
}

U0 WindowCaptureMouse(Window *win, Bool capture)
{
  if (win->mouse_captured == capture)
    return;
  SDL_SetRelativeMouseMode(capture);
  win->mouse_captured = capture;

  // Drop motion that piled up while the cursor was free, or the view jumps.
  I32 dx, dy;
  SDL_GetRelativeMouseState(&dx, &dy);
}

U8 *WindowKeys()
{
  return SDL_GetKeyboardState(NULL);
}

U0 WindowMouseDelta(I64 *dx, I64 *dy)
{
  I32 x, y;
  SDL_GetRelativeMouseState(&x, &y);
  *dx = x;
  *dy = y;
}

U64 PlatformCounter()
{
  return SDL_GetPerformanceCounter();
}

U64 PlatformFrequency()
{
  return SDL_GetPerformanceFrequency();
}

U8 *PlatformBasePath()
{
  U8 *sdl_path = SDL_GetBasePath();
  if (!sdl_path)
    return StrNew("./");
  U8 *path = StrNew(sdl_path);
  SDL_free(sdl_path);
  return path;
}
