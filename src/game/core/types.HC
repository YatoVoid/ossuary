#define PI      3.14159265358979
#define TAU     6.28318530717958
#define HALF_PI 1.57079632679490

class Vec2
{
  F32 x, y;
};

class Vec3
{
  F32 x, y, z;
};

class Color
{
  F32 r, g, b, a;
};

class Mat4
{
  F32 m[16];
};

class Rng
{
  U64 state;
};
