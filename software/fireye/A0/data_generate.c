#include <stdio.h>

int main() {
    int n, k;
    scanf("%d", &n);
    scanf("%d", &k);
    printf("int n = %d;\n", n);
    printf("int k = %d;\n", k);
    printf("int data[%d] = {", k);

    for (int i = 0; i < k; i++) {
        int x;
        scanf("%d", &x);
        printf("%d", x);
        if (i < k - 1)
            printf(", ");
        else
            printf("};\n");
    }

    return 0;
}
