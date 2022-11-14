#include <stdio.h>
#include <stdlib.h>

int main() {
    int x, y, n;
    scanf("%d%d%d", &x, &y, &n);

    int *data0 = (int *)malloc(n * sizeof(int));
    int *data1 = (int *)malloc(n * sizeof(int));

    for (int i = 0; i < n; i++) {
        scanf("%d%d", &data0[i], &data1[i]);
    }

    printf("int x = %d, y = %d, n = %d;\n", x, y, n);

    printf("int data0[%d] = {", n);
    for (int i = 0; i < n; i++) {
        printf("%d", data0[i]);
        if (i < n - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("int data1[%d] = {", n);
    for (int i = 0; i < n; i++) {
        printf("%d", data1[i]);
        if (i < n - 1)
            printf(", ");
        else
            printf("};\n");
    }

    free(data0);
    free(data1);
}
