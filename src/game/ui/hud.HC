U0 HudRelics(UiBatch *ui, World *w, F32 x, F32 y)
{
  F32 s = ui->scale;
  Color lit, unlit, label;
  ColorSet(&lit, 0.45, 0.95, 0.85);
  ColorSet(&unlit, 0.35, 0.33, 0.3, 0.6);
  ColorSet(&label, 0.86, 0.82, 0.72, 0.85);

  UiTextShadowed(ui, x, y, 1.0, "RELICS", &label);
  F32 pip_y = y + UiLineHeight(ui, 1.0);
  for (I64 i = 0; i < w->relics_total; i++) {
    F32 px = x + i * 9.0 * s;
    if (i < w->player.relics) {
      UiRect(ui, px, pip_y, 6.0 * s, 6.0 * s, &lit);
    } else {
      UiRect(ui, px, pip_y, 6.0 * s, s, &unlit);
      UiRect(ui, px, pip_y + 5.0 * s, 6.0 * s, s, &unlit);
      UiRect(ui, px, pip_y, s, 6.0 * s, &unlit);
      UiRect(ui, px + 5.0 * s, pip_y, s, 6.0 * s, &unlit);
    }
  }
}

U0 HudStamina(UiBatch *ui, Player *p)
{
  if (p->stamina > 0.995)
    return;
  F32 s = ui->scale;
  F32 w = 90.0 * s;
  F32 x = floor((ui->width - w) * 0.5);
  F32 y = ui->height - 18.0 * s;

  Color back, fill;
  ColorSet(&back, 0.0, 0.0, 0.0, 0.5);
  if (p->winded)
    ColorSet(&fill, 0.75, 0.2, 0.15, 0.85);
  else
    ColorSet(&fill, 0.86, 0.82, 0.72, 0.7);
  UiRect(ui, x - s, y - s, w + 2.0 * s, 4.0 * s, &back);
  UiRect(ui, x, y, w * p->stamina, 2.0 * s, &fill);
}

U0 HudDraw(UiBatch *ui, World *w, F32 fps, Bool show_fps)
{
  F32 s = ui->scale;
  F32 margin = 10.0 * s;
  Color bone, dim, crosshair;
  ColorSet(&bone, 0.86, 0.82, 0.72);
  ColorSet(&dim, 0.86, 0.82, 0.72, 0.55);
  ColorSet(&crosshair, 0.9, 0.85, 0.75, 0.35);

  HudRelics(ui, w, margin, ui->height - margin - UiLineHeight(ui, 1.0) - 6.0 * s);
  HudStamina(ui, &w->player);

  UiRect(ui, floor(ui->width * 0.5), floor(ui->height * 0.5), s, s, &crosshair);

  if (!w->player.lantern) {
    U8 *note = "LANTERN DOUSED  (F)";
    UiTextShadowed(ui, ui->width - margin - UiTextWidth(ui, note, 1.0),
                   ui->height - margin - UiLineHeight(ui, 1.0), 1.0, note, &dim);
  }

  if (w->message_time > 0.0) {
    Color msg;
    ColorSet(&msg, 0.86, 0.82, 0.72, Saturate(w->message_time));
    F32 x = floor((ui->width - UiTextWidth(ui, w->message, 1.0)) * 0.5);
    UiTextShadowed(ui, x, floor(ui->height * 0.24), 1.0, w->message, &msg);
  }

  if (show_fps) {
    U8 buf[32];
    I64 rounded = fps + 0.5;
    StrPrint(buf, "FPS %d", rounded);
    UiTextShadowed(ui, margin, margin, 1.0, buf, &bone);
  }
}
