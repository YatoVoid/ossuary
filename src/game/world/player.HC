#define PLAYER_RADIUS     0.28
#define PLAYER_EYE        1.55
#define WALK_SPEED        2.9
#define SPRINT_SPEED      5.0
#define MOUSE_SENSITIVITY 0.0022
#define KEY_TURN_SPEED    2.6
#define PITCH_LIMIT       1.3
#define STAMINA_DRAIN     0.28
#define STAMINA_REGEN     0.16
#define STAMINA_LOCKOUT   0.25

class Player
{
  Vec3 pos;
  F32 yaw;
  F32 pitch;
  F32 stamina;
  Bool winded;
  Bool sprinting;
  Bool moving;
  Bool lantern;
  F32 bob;
  F32 bob_amount;
  F32 noise;
  I64 relics;
};

U0 PlayerSpawn(Player *p, Vec3 *at, F32 yaw)
{
  MemSet(p, 0, sizeof(Player));
  p->pos = *at;
  p->yaw = yaw;
  p->stamina = 1.0;
  p->lantern = TRUE;
}

U0 PlayerEye(Player *p, Vec3 *out)
{
  F32 bob = sin(p->bob) * 0.035 * p->bob_amount;
  V3Set(out, p->pos.x, PLAYER_EYE + bob, p->pos.z);
}

U0 PlayerUpdate(Player *p, Input *in, Level *lv, F32 dt)
{
  p->yaw += in->look_x * MOUSE_SENSITIVITY;
  p->yaw += InputAxis(in, ACT_TURN_LEFT, ACT_TURN_RIGHT) * KEY_TURN_SPEED * dt;
  p->yaw = WrapAngle(p->yaw);
  p->pitch -= in->look_y * MOUSE_SENSITIVITY;
  p->pitch = Clampf(p->pitch, -PITCH_LIMIT, PITCH_LIMIT);

  if (InputPressed(in, ACT_LANTERN))
    p->lantern = !p->lantern;

  F32 fwd_in = InputAxis(in, ACT_BACK, ACT_FORWARD);
  F32 side_in = InputAxis(in, ACT_LEFT, ACT_RIGHT);
  Vec3 fwd, right, wish;
  YawForward(p->yaw, &fwd);
  YawRight(p->yaw, &right);
  V3Scale(&wish, &fwd, fwd_in);
  V3AddScaled(&wish, &wish, &right, side_in);
  F32 len = V3Length(&wish);
  if (len > 0.01) {
    p->moving = TRUE;
    V3Scale(&wish, &wish, 1.0 / len);
  } else {
    p->moving = FALSE;
  }

  if (p->stamina < 0.001)
    p->winded = TRUE;
  if (p->stamina > STAMINA_LOCKOUT)
    p->winded = FALSE;

  p->sprinting = p->moving && InputDown(in, ACT_SPRINT) && !p->winded;
  F32 speed = WALK_SPEED;
  if (p->sprinting) {
    speed = SPRINT_SPEED;
    p->stamina = Maxf(p->stamina - STAMINA_DRAIN * dt, 0.0);
  } else {
    p->stamina = Minf(p->stamina + STAMINA_REGEN * dt, 1.0);
  }

  LevelMove(lv, &p->pos, wish.x * speed * dt, wish.z * speed * dt, PLAYER_RADIUS);

  if (p->moving) {
    p->bob += speed * dt * 2.6;
    if (p->bob > TAU)
      p->bob -= TAU;
    p->bob_amount = Approach(p->bob_amount, 1.0, dt * 4.0);
    if (p->sprinting)
      p->noise = 1.0;
    else
      p->noise = 0.35;
  } else {
    p->bob_amount = Approach(p->bob_amount, 0.0, dt * 3.0);
    p->noise = 0.0;
  }
}
