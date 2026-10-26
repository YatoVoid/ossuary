#define STATE_TITLE   0
#define STATE_PLAYING 1
#define STATE_PAUSED  2
#define STATE_DEAD    3
#define STATE_WON     4

class StateMachine
{
  I64 current;
  I64 previous;
  F32 time;
  Bool entered;
};

U0 StateInit(StateMachine *sm, I64 first)
{
  sm->current = first;
  sm->previous = first;
  sm->time = 0.0;
  sm->entered = TRUE;
}

U0 StateSet(StateMachine *sm, I64 next)
{
  if (next == sm->current)
    return;
  sm->previous = sm->current;
  sm->current = next;
  sm->time = 0.0;
  sm->entered = TRUE;
}

Bool StateConsumeEnter(StateMachine *sm)
{
  if (!sm->entered)
    return FALSE;
  sm->entered = FALSE;
  return TRUE;
}

U0 StateTick(StateMachine *sm, F32 dt)
{
  sm->time += dt;
}
