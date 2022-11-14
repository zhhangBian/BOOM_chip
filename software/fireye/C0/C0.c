// int n = ..., A = ..., m = ..., B = ...;
// char data0[A][n + 1] = ...;
// char data1[B][m + 1] = ...;

// #define LOOP ...

#include <stdio.h>

#define N 100

int mpN[6][6], mpM[6][6];
int ans;

struct Trie {
    int ch[N][26];
    int tot;
} t[2] = {{{1}, 0}, {{1}, 0}};

void insert(struct Trie *t, char *s) {
    int x = 0;
    for (int i = 0; s[i] != '\0'; i++) {
        if (!t->ch[x][s[i] - 'a'])
            t->ch[x][s[i] - 'a'] = ++t->tot;
        x = t->ch[x][s[i] - 'a'];
    }
}

void dfs(int x, int y) {
    if (x == n + 1) {
        ++ans;
        return;
    }
    for (int i = 0; i < 26; i++) {
        int lastN = mpN[x - 1][y], lastM = mpM[x][y - 1];
        int nx = t[0].ch[lastN][i], ny = t[1].ch[lastM][i];
        if (!(nx && ny)) continue;
        mpN[x][y] = nx;
        mpM[x][y] = ny;

        nx = x, ny = y + 1;
        if (ny > m) ++nx, ny = 1;
        dfs(nx, ny);
    }
}

void run() {
    for (int i = 0; i < A; i++) {
        insert(&t[0], data0[i]);
    }
    for (int i = 0; i < B; i++) {
        insert(&t[1], data1[i]);
    }
    for (int i = 0; i < LOOP; i++) {
        ans = 0;
        dfs(1, 1);
    }
}

int main() {
    t[0].ch[0][0] = 0;
    t[1].ch[0][0] = 0;

    run();
    printf("%d\n", ans);

    return 0;
}
