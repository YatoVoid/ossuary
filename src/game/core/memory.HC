class Arena
{
  U8 *base;
  I64 used;
  I64 cap;
  I64 peak;
  U8 *name;
};

U0 Fatal(U8 *what, U8 *detail = "")
{
  "fatal: %s %s\n", what, detail;
  Exit(1);
}

U0 *MemZalloc(I64 size)
{
  U0 *ptr = CAlloc(size);
  if (!ptr)
    Fatal("out of memory");
  return ptr;
}

U0 ArenaInit(Arena *arena, U8 *name, I64 cap)
{
  arena->base = MemZalloc(cap);
  arena->used = 0;
  arena->peak = 0;
  arena->cap = cap;
  arena->name = name;
}

U0 *ArenaPush(Arena *arena, I64 size)
{
  I64 start = (arena->used + 15) & ~15;
  if (start + size > arena->cap)
    Fatal("arena exhausted:", arena->name);
  arena->used = start + size;
  if (arena->used > arena->peak)
    arena->peak = arena->used;
  U8 *ptr = arena->base + start;
  MemSet(ptr, 0, size);
  return ptr;
}

U0 ArenaReset(Arena *arena)
{
  arena->used = 0;
}

U0 ArenaFree(Arena *arena)
{
  Free(arena->base);
  arena->base = NULL;
  arena->used = 0;
  arena->cap = 0;
}
