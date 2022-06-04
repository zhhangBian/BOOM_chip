1. [GCC交叉编译器](https://gitee.com/loongson-edu/la32r-toolchains/releases)

根据架构下载相映**loongarch32r-linux-gnusf-*.tar.gz**，并在本目录下解压。

2. [NEMU](https://gitee.com/wwt_panache/la32r-nemu/releases)

```bash
mkdir nemu
wget https://gitee.com/wwt_panache/la32r-nemu/attach_files/1063904/download/la32r-nemu-interpreter-so -P ./nemu
```

3. [newlib](http://114.242.206.180:24989/nextcloud/index.php/s/Cd5CqCFg8GrjzsQ)

内容包括`libc.a libg.a libm.a libpmon.a pmon.ld start.o`，在本目录下解压缩。

