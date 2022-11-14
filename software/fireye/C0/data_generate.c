#include <stdio.h>
#include <stdlib.h>

int main() {
    int n, A, m, B;
    scanf("%d%d", &n, &A);
    scanf("%d%d", &m, &B);
    printf("int n = %d, A = %d, m = %d, B = %d;\n", n, A, m, B);

    char *s0 = (char *)malloc(n);
    char *s1 = (char *)malloc(m);

    printf("char data0[%d][%d] = {", A, n + 1);
    for (int i = 0; i < A; i++) {
        scanf("%s", s0);
        printf("\"%s\"", s0);
        if (i < A - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("char data1[%d][%d] = {", B, m + 1);
    for (int i = 0; i < B; i++) {
        scanf("%s", s1);
        printf("\"%s\"", s1);
        if (i < B - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("\n");
    return 0;
}
