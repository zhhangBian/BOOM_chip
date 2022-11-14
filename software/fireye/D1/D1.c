// int x = ..., y = ..., n = ...
// int data0[n] = ...;
// int data1[n] = ...;

#include <stdio.h>
#include <string.h>

#define MAXN 1000000

int in[MAXN] = {1}, out[MAXN] = {1};
int mn[MAXN] = {1}, mx [MAXN] = {1};

int max(int a, int b) { return a > b ? a : b; }
int min(int a, int b) { return a < b ? a : b; }

int main() {
    int ans;

    for (int l = 0; l < LOOP; l++) {
        memset(mn, -1, (max(x, y) + 1) * sizeof(int));
        memset(mx, -1, (max(x, y) + 1) * sizeof(int));
        memset(in,  0, (max(x, y) + 1) * sizeof(int));
        memset(out, 0, (max(x, y) + 1) * sizeof(int));

        int a, b;
        for (int i = 0; i < n; i++) {
            a = data0[i];
            b = data1[i];
            if (mn[a] == -1)
    			mn[a] = b;
    		else
    			mn[a] = min(mn[a], b);
    		mx[a] = max(mx[a], b);
        }

        int reduce = 0;
        int down = 0;
        int sum = 0;

        for (int i = 0; i < y + 1; i++) {
            if (mx[i] != -1){
    			in[mx[i]]++;

    			out[mn[i]]++;
    			sum += mn[i];
    			down++;
    		}
        }

        ans = 0x7fffffff;
        int up = 0, upsum = 0;
        for (int p = y + 1; p >= 0; p--){
    		if (in[p] > 0){
    			up += in[p];
    			upsum += in[p] * p;
    		}
    		if (out[p] > 0){
    			down -= out[p];
    			sum -= out[p] * p;
    		}
    		int df = 2 * ((upsum - up * p) + (down * p - sum));
    		ans = min(ans, df);
    	}
    }

    printf("%d\n", ans + x - 1);
    return 0;
}
