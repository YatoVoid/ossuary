class Camera
{
  Vec3 pos;
  F32 yaw;
  F32 pitch;
  F32 fov;
  F32 near;
  F32 far;
  Mat4 view;
  Mat4 proj;
};

U0 CameraInit(Camera *cam)
{
  MemSet(cam, 0, sizeof(Camera));
  cam->fov = 70.0 * PI / 180.0;
  cam->near = 0.05;
  cam->far = 60.0;
}

U0 CameraForward(Camera *cam, Vec3 *out)
{
  F32 cp = cos(cam->pitch);
  V3Set(out, sin(cam->yaw) * cp, sin(cam->pitch), -cos(cam->yaw) * cp);
}

U0 CameraUpdate(Camera *cam, F32 aspect)
{
  Vec3 fwd, target, up;
  CameraForward(cam, &fwd);
  V3Add(&target, &cam->pos, &fwd);
  V3Set(&up, 0.0, 1.0, 0.0);
  Mat4LookAt(&cam->view, &cam->pos, &target, &up);
  Mat4Perspective(&cam->proj, cam->fov, aspect, cam->near, cam->far);
}
