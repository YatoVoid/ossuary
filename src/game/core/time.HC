#define MAX_FRAME_TIME 0.05

class Clock
{
  U64 freq;
  U64 last;
  F32 dt;
  F64 elapsed;
  I64 frames;
  F32 fps;
  F32 fps_window;
  I64 fps_frames;
};

U0 ClockInit(Clock *clock)
{
  MemSet(clock, 0, sizeof(Clock));
  clock->freq = PlatformFrequency();
  clock->last = PlatformCounter();
}

U0 ClockTick(Clock *clock)
{
  U64 now = PlatformCounter();
  I64 ticks = now - clock->last;
  clock->last = now;

  F64 seconds = ticks;
  F64 freq = clock->freq;
  seconds /= freq;

  clock->elapsed += seconds;
  clock->frames++;
  clock->dt = Minf(seconds, MAX_FRAME_TIME);

  clock->fps_window += seconds;
  clock->fps_frames++;
  if (clock->fps_window > 0.5) {
    F32 frames = clock->fps_frames;
    clock->fps = frames / clock->fps_window;
    clock->fps_window = 0.0;
    clock->fps_frames = 0;
  }
}
