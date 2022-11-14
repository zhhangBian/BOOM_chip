#include <stdio.h>
#include <stdlib.h>

int main() {
    int n;
    scanf("%d", &n);

    int *L = (int *)malloc(n * sizeof(int));
    int *R = (int *)malloc(n * sizeof(int));
    for (int i = 0; i < n; i++) {
        scanf("%d%d", &L[i], &R[i]);
    }

    printf("int n = %d;\n", n);

    printf("int L[%d] = {", n);
    for (int i = 0; i < n; i++) {
        printf("%d", L[i]);
        if (i < n - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("int R[%d] = {", n);
    for (int i = 0; i < n; i++) {
        printf("%d", R[i]);
        if (i < n - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("\n");
    return 0;
}
