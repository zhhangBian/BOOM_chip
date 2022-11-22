#include <stdio.h>
#include <stdlib.h>

int main() {
    int m, n;
    scanf("%d%d", &m, &n);
    printf("int m = %d, n = %d;\n", m, n);

    char *s = (char *)malloc(m);
    printf("char s[%d][%d] = {", n, m + 2);
    for (int i = 0; i < n; i++) {
        scanf("%s", s);
        printf("\" %s\"", s);
        if (i < n - 1)
            printf(", ");
        else
            printf("};\n");
    }

    printf("int vis[%d][%d] = {1};\n\n", n, m);

    free(s);
    return 0;
}
