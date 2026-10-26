U0 InputSystemUpdate(Input *in, Window *win)
{
  MemCpy(in->prev, in->down, sizeof(Bool) * ACT_COUNT);

  WindowPump(win);
  in->focused = WindowFocused(win);

  U8 *keys = WindowKeys();
  for (I64 i = 0; i < ACT_COUNT; i++) {
    Binding *b = &in->bindings[i];
    Bool held = keys[b->primary] != 0;
    if (b->secondary >= 0 && keys[b->secondary])
      held = TRUE;
    in->down[i] = held;
  }

  I64 dx = 0, dy = 0;
  WindowMouseDelta(&dx, &dy);
  if (win->mouse_captured && in->focused) {
    in->look_x = dx;
    in->look_y = dy;
  } else {
    in->look_x = 0.0;
    in->look_y = 0.0;
  }
}
