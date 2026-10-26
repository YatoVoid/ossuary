U0 MenuOverlay(UiBatch *ui, F32 alpha)
{
  Color shade;
  ColorSet(&shade, 0.0, 0.0, 0.0, alpha);
  UiRect(ui, 0.0, 0.0, ui->width, ui->height, &shade);
}

U0 MenuControls(UiBatch *ui, F32 y, Color *c)
{
  F32 line = UiLineHeight(ui, 1.0);
  UiTextCentered(ui, y, 1.0, "WASD  MOVE      MOUSE  LOOK      ARROWS  MOVE + TURN", c);
  UiTextCentered(ui, y + line, 1.0, "SHIFT  RUN      F  LANTERN      ESC  PAUSE", c);
}

U0 MenuDrawTitle(UiBatch *ui, F32 t)
{
  Color title, sub, prompt, hint;
  F32 flicker = 0.85 + 0.15 * sin(t * 7.0) * sin(t * 2.3);
  ColorSet(&title, 0.9 * flicker, 0.84 * flicker, 0.7 * flicker);
  ColorSet(&sub, 0.7, 0.66, 0.58, 0.85);
  ColorSet(&hint, 0.6, 0.57, 0.5, 0.7);
  F32 blink = 0.5 + 0.5 * sin(t * 3.0);
  ColorSet(&prompt, 0.86, 0.82, 0.72, 0.35 + blink * 0.65);

  MenuOverlay(ui, 0.35);
  F32 h = ui->height;
  UiTextCentered(ui, floor(h * 0.2), 4.0, "OSSUARY", &title);
  UiTextCentered(ui, floor(h * 0.2) + UiLineHeight(ui, 4.0), 1.0,
                 "FIVE RELICS. ONE GATE. SOMETHING ELSE DOWN HERE.", &sub);
  UiTextCentered(ui, floor(h * 0.56), 1.5, "PRESS ENTER", &prompt);
  UiTextCentered(ui, floor(h * 0.56) + UiLineHeight(ui, 1.5), 1.0,
                 "YOUR LANTERN CARRIES. DOUSE IT TO HIDE.", &hint);
  MenuControls(ui, h - UiLineHeight(ui, 1.0) * 3.0, &hint);
}

U0 MenuDrawPause(UiBatch *ui)
{
  Color title, body;
  ColorSet(&title, 0.86, 0.82, 0.72);
  ColorSet(&body, 0.7, 0.66, 0.58);

  MenuOverlay(ui, 0.65);
  F32 y = floor(ui->height * 0.32);
  UiTextCentered(ui, y, 3.0, "PAUSED", &title);
  y += UiLineHeight(ui, 3.0) + UiLineHeight(ui, 1.0);
  UiTextCentered(ui, y, 1.0, "ENTER  RESUME", &body);
  UiTextCentered(ui, y + UiLineHeight(ui, 1.0), 1.0, "Q  ABANDON THE RUN", &body);
  MenuControls(ui, ui->height - UiLineHeight(ui, 1.0) * 3.0, &body);
}

U0 MenuDrawEnd(UiBatch *ui, World *w, Bool escaped, F32 t)
{
  Color title, body, prompt;
  if (escaped)
    ColorSet(&title, 0.82, 0.88, 0.95, Saturate(t));
  else
    ColorSet(&title, 0.8, 0.12, 0.1, Saturate(t));
  ColorSet(&body, 0.86, 0.82, 0.72, Saturate(t - 0.5));
  ColorSet(&prompt, 0.86, 0.82, 0.72, Saturate(t - 1.0) * (0.6 + 0.4 * sin(t * 3.0)));

  U8 *heading = "YOU WERE TAKEN";
  if (escaped)
    heading = "YOU ESCAPED";

  F32 y = floor(ui->height * 0.3);
  UiTextCentered(ui, y, 3.0, heading, &title);
  y += UiLineHeight(ui, 3.0) + UiLineHeight(ui, 1.0);

  U8 stats[64];
  I64 secs = w->time;
  StrPrint(stats, "RELICS %d/%d     TIME %d:%02d", w->player.relics, w->relics_total,
           secs / 60, secs % 60);
  UiTextCentered(ui, y, 1.0, stats, &body);
  UiTextCentered(ui, y + UiLineHeight(ui, 1.0) * 2.0, 1.0, "ENTER  GO AGAIN      Q  TITLE", &prompt);
}
