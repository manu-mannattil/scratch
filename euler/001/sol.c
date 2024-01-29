/* com: : ${TMPDIR:=/tmp/} ${CC=gcc}
 * com: \{ ${CC} {} -o ${TMPDIR}{/.}; \} && ${TMPDIR}{/.} {@}
 */

#include <stdio.h>

int main(int argc, const char* argv[]) {
    /* Brute force. */
    int i, total = 0;
    for (i = 1; i < 1000; i++) {
        if (i % 3 == 0 || i % 5 == 0)
            total += i;
    }

    printf("Brute force = %d\n", total);
    return 0;
}
