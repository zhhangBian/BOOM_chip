1. [GCC交叉编译器](https://gitee.com/loongson-edu/la32r-toolchains/releases)

根据架构下载相映`loongarch32r-linux-gnusf-${TOOLCHAINS_DATE}.tar.gz`，并解压。解压后将`loongarch32r-linux-gnusf-${TOOLCHAINS_DATE}/bin/`目录添加到path中。
linux下建议打开
```
vim ~/.bashrc
```
在文件末尾添加以下内容，注意保持此处`${TOOLCHAINS_DATE}`和所下载工具链文件夹名称一致。
```
export PATH=${CHIPLAB_HOME}/toolchains/loongarch32r-linux-gnusf-${TOOLCHAINS_DATE}/bin/:$PATH 
```

2. [NEMU](https://gitee.com/wwt_panache/la32r-nemu/releases)

在当前目录`mkdir nemu`，然后下载`la32r-nemu-interpreter-so`到`nemu`目录。

3. [newlib](http://114.242.206.180:24989/nextcloud/index.php/s/Cd5CqCFg8GrjzsQ)

内容包括`libc.a libg.a libm.a libpmon.a pmon.ld start.o`，在当前目录下解压。

