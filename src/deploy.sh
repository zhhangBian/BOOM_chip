#!/bin/bash

src=$(find ./rtl -name "*sv*")

if [ $1=="chiplab" ] 
then
	rm -rf ${CHIPLAB_HOME}/IP/myCPU
	mkdir ${CHIPLAB_HOME}/IP/myCPU
	for f in $src
	do
		cp $f ${CHIPLAB_HOME}/IP/myCPU/
	done
fi

