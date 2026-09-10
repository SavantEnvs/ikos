/* Null-pointer seed (ikos `nullity` checker): a pointer that is NULL on one path, an
 * unchecked malloc result, and a struct field access through a possibly-null pointer. */
#include <stdlib.h>

extern int __ikos_nondet_int(void);

struct point {
  int x;
  int y;
};

static int get_x(struct point* p) {
  return p->x;             /* unsafe when called with NULL */
}

int main(void) {
  struct point local = {1, 2};
  struct point* p = &local;
  int* q = NULL;
  int r = 0;

  if (__ikos_nondet_int()) {
    p = NULL;
  }
  r += get_x(p);           /* p may be NULL */
  q = (int*)malloc(sizeof(int) * 4);
  q[1] = 7;                /* malloc may return NULL */
  r += q[1];
  free(q);
  return r;
}
