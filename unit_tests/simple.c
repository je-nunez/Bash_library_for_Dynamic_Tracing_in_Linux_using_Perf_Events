
/*
 * A simple test program in C on which to set
 * the dynamic probes.
 */

#include <stdio.h>

extern void
my_func(int my_param) {
    printf("%d\n", my_param);
}

int
main() {
    my_func(4);
    return 0;
}

