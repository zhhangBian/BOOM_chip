#include <stdio.h>
#include <string.h>

#define CPSIZE 1048576

char src[CPSIZE] = "this is src";
char dst[CPSIZE] = "this is dst";

int main() {
    memcpy(dst, src, CPSIZE);
    printf("%s\n", dst);

    return 0;
}
