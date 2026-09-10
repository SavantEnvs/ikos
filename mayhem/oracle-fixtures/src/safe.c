/* Safe seed: loops with widening, a struct, a selector chain, a function pointer, recursion and string
 * intrinsics — every check should be proven safe (`prover` gets an __ikos_assert to prove). */
#include <string.h>

extern int __ikos_nondet_int(void);
extern void __ikos_assert(int);

struct acc {
  int total;
  int count;
  char tag[16];
};

typedef int (*op_fn)(int, int);

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }

static int fact(int n) {
  if (n <= 1) {
    return 1;
  }
  return n * fact(n - 1);
}

int main(void) {
  struct acc a;
  op_fn ops[2] = {add, sub};
  int i, j, k = 0;
  int table[4][4];

  memset(&a, 0, sizeof(a));
  strncpy(a.tag, "safe-seed", sizeof(a.tag) - 1);
  a.tag[sizeof(a.tag) - 1] = '\0';

  for (i = 0; i < 4; i++) {
    for (j = 0; j < 4; j++) {
      table[i][j] = ops[(i + j) & 1](i, j);
    }
  }
  for (i = 0; i < 4; i++) {
    a.total += table[i][i];
    a.count++;
  }
  while (k < 100) {
    k += 7;
  }
  /* (an if/else chain, not a switch: ikos-analyzer expects ikos-pp to have lowered switch
   * instructions and rejects a raw one with "llvm switch instructions are not supported") */
  int sel = __ikos_nondet_int() & 3;
  if (sel == 0) {
    a.total += fact(3);
  } else if (sel == 1) {
    a.total += fact(4);
  } else if (sel == 2) {
    a.total -= 1;
  }
  __ikos_assert(a.count == 4);
  __ikos_assert(k >= 100);
  return a.total + (int)strlen(a.tag);
}
