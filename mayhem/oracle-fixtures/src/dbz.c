/* Division-by-zero seed (ikos `dbz` checker): one branch makes the divisor 0, so the analyzer
 * must report a warning on the division; the modulo and the call-through division are safe. */
extern int __ikos_nondet_int(void);

static int divide(int a, int b) {
  return a / b;
}

int main(void) {
  int x, y, z;
  if (__ikos_nondet_int()) {
    y = 0;
  } else {
    y = 10;
  }
  x = 10 / y;             /* unsafe: y may be 0 */
  z = 100 % (y + 1);      /* y + 1 in {1, 11}: safe */
  z += divide(x, 5);      /* safe */
  return x + z;
}
