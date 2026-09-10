/* Loop seed: a bubble sort over an array, a string reversal and a sentinel-terminated walk —
 * bounded loops the analyzer must widen and narrow (the classic ikos regression shape). */
#include <string.h>

extern int __ikos_nondet_int(void);

static void bubble_sort(int* v, int n) {
  int i, j, t;
  for (i = 0; i < n - 1; i++) {
    for (j = 0; j < n - 1 - i; j++) {
      if (v[j] > v[j + 1]) {
        t = v[j];
        v[j] = v[j + 1];
        v[j + 1] = t;
      }
    }
  }
}

static void reverse(char* s) {
  int i = 0;
  int j = (int)strlen(s) - 1;
  while (i < j) {
    char c = s[i];
    s[i++] = s[j];
    s[j--] = c;
  }
}

int main(void) {
  int v[16];
  char text[32] = "abstract interpretation";
  int i, n = 0;
  int ends[5] = {3, 1, 4, 1, -1};

  for (i = 0; i < 16; i++) {
    v[i] = __ikos_nondet_int();
  }
  bubble_sort(v, 16);
  reverse(text);
  for (i = 0; ends[i] >= 0; i++) {
    n += ends[i];
  }
  return v[0] + text[0] + n;
}
