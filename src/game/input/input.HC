#define ACT_FORWARD    0
#define ACT_BACK       1
#define ACT_LEFT       2
#define ACT_RIGHT      3
#define ACT_TURN_LEFT  4
#define ACT_TURN_RIGHT 5
#define ACT_SPRINT     6
#define ACT_LANTERN    7
#define ACT_CONFIRM    8
#define ACT_PAUSE      9
#define ACT_QUIT       10
#define ACT_DEBUG      11
#define ACT_COUNT      12

class Binding
{
  I64 primary;
  I64 secondary;
};

class Input
{
  Binding bindings[ACT_COUNT];
  Bool down[ACT_COUNT];
  Bool prev[ACT_COUNT];
  F32 look_x;
  F32 look_y;
  Bool focused;
};

U0 InputBind(Input *in, I64 action, I64 primary, I64 secondary = -1)
{
  in->bindings[action].primary = primary;
  in->bindings[action].secondary = secondary;
}

U0 InputInit(Input *in)
{
  MemSet(in, 0, sizeof(Input));
  InputBind(in, ACT_FORWARD, SC_W, SC_UP);
  InputBind(in, ACT_BACK, SC_S, SC_DOWN);
  InputBind(in, ACT_LEFT, SC_A);
  InputBind(in, ACT_RIGHT, SC_D);
  InputBind(in, ACT_TURN_LEFT, SC_LEFT);
  InputBind(in, ACT_TURN_RIGHT, SC_RIGHT);
  InputBind(in, ACT_SPRINT, SC_LSHIFT, SC_RSHIFT);
  InputBind(in, ACT_LANTERN, SC_F);
  InputBind(in, ACT_CONFIRM, SC_RETURN, SC_SPACE);
  InputBind(in, ACT_PAUSE, SC_ESCAPE, SC_P);
  InputBind(in, ACT_QUIT, SC_Q);
  InputBind(in, ACT_DEBUG, SC_F3);
  in->focused = TRUE;
}

Bool InputDown(Input *in, I64 action)
{
  return in->down[action];
}

Bool InputPressed(Input *in, I64 action)
{
  return in->down[action] && !in->prev[action];
}

F32 InputAxis(Input *in, I64 negative, I64 positive)
{
  F32 v = 0.0;
  if (in->down[negative])
    v -= 1.0;
  if (in->down[positive])
    v += 1.0;
  return v;
}
