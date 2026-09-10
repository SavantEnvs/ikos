/* Buffer-overflow seed (ikos `boa` checker): a nondeterministic index into a small array,
 * a strcpy into an undersized buffer and a bounded loop that is safe. */
#include <string.h>

extern int __ikos_nondet_int(void);

int main(void) {
  int a[10];
  char small[4];
  const char* msg = "hello, world";
  int i, sum = 0;

  for (i = 0; i < 10; i++) {
    a[i] = i * 2;          /* safe */
  }
  i = __ikos_nondet_int();
  if (i >= 0 && i <= 10) {
    sum += a[i];           /* unsafe: i == 10 is out of bounds */
  }
  strcpy(small, msg);      /* unsafe: 13 bytes into 4 */
  memcpy(a, a + 5, 5 * sizeof(int));  /* safe */
  return sum + small[0];
}
