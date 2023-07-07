#include <stdio.h>

int sum(int one, int two) {
    return one + two;
}

int main() {
  int res = sum(1, 2);

  printf("res: %d\n", res);
  return 0;
}
