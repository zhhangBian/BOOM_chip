
// int k = ...;
// int n = ...;
// int data[k] = {...};

#include <stdio.h>

#define KN 1000000

int pos[KN] = {1};

int max(int a, int b) { return a > b ? a : b; }

int main() {
    pos[0] = 0;

    int ans = 0;
    for(int i = 0; i < k; i++) {
		int x = data[i];
		for(int j = x; j <= n; j += x) pos[j] ^= 1;
		int tmp = 0;
		for(int j = 1; j <= n; j++) tmp += pos[j];
		ans = max(ans, tmp);
	}

    printf("%d\n", ans);
    return 0;
}
