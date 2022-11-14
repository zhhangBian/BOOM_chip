#!/bin/bash

solution=$1
data=$2
loop=$3

gcc data_generate.c -o data_generate
./data_generate < ${data}.in > hello.c
echo -e "#define LOOP $loop\n" >> hello.c
cat ${solution}.c >> hello.c
rm data_generate
