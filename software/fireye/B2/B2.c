// int n = ...;
// int L[n] = ...;
// int R[n] = ...;

#include <stdio.h>

#define KN 10000

int log_2(int x) { int ans = 0; while(x >>= 1) ans++; return ans; }
int max(int a, int b) { return a > b ? a : b; }
int min(int a, int b) { return a < b ? a : b; }

int query(int d[][KN], int l, int r, int maxx) {
    int t = log_2(r - l + 1);
    if (maxx) return max(d[t][l], d[t][r - (1 << t) + 1]);
    return min(d[t][l], d[t][r - (1 << t) + 1]);
}

void init(int d[][KN], int a[], int len, int maxx) {
    for (int i = 0; i < len; i++) d[0][i] = a[i];
    int t = 1;
    for (int i = 1; t <= len; i++) {
        for (int j = 0; j + t < len; j++)
            if (maxx)d[i][j] = max(d[i - 1][j], d[i - 1][j + t]);
            else d[i][j] = min(d[i - 1][j], d[i - 1][j + t]);
        t <<= 1;
    }
}

int main() {
    int dl[20][KN], dr[20][KN];

    init(dl, L, n, 1);
    init(dr, R, n, 0);

    int ans;
    for (int var = 0; var < LOOP; var++) {
        ans = 1;
        for (int i = 1; i <= n; i++) {
            int l = ans, r = n - i + 1;
            while (l <= r) {
                int mid = l + r >> 1;
                if (query(dr, i - 1, i + mid - 2, 0) - query(dl, i - 1, i + mid - 2, 1) + 1 >= mid) {
                    ans = max(ans, mid); l = mid + 1;
                } else r = mid - 1;
            }
        }
    }

    printf("%d\n", ans);
    return 0;
}
