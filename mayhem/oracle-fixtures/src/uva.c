/* Uninitialized-variable + integer seed (ikos `uva`, `sio`, `shc`, `pcmp`, `poa` checkers):
 * a variable read before assignment on one path, a shift by a nondeterministic count, a signed
 * addition that may overflow, and a pointer comparison across two objects. */
extern int __ikos_nondet_int(void);

int g_counter = 0;

int main(void) {
  int u;
  int s = __ikos_nondet_int();
  int k = __ikos_nondet_int();
  int arr[8];
  int other[8];
  int* p = arr + 3;
  int* q = other;
  int r = 0;

  if (s > 0) {
    u = s;
  }
  r += u;                  /* uninitialized when s <= 0 */
  if (k >= 0 && k < 64) {
    r += 1 << k;           /* shift count may exceed 31 */
  }
  r += s + 0x7fffffff;     /* may overflow */
  if (p < q) {             /* pointers into different objects */
    r += 1;
  }
  g_counter += r;
  return g_counter;
}
