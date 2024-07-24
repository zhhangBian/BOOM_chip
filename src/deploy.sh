#!/bin/bash

src=$(find ./rtl -name "*sv*")

if [ $1=="chiplab" ] 
then
	if [ -z ${CHIPLAB_HOME}  ]
	then
		echo "variable CHIPLAB_HOME not set"
	else
	then
		mkdir ${CHIPLAB_HOME}/IP/myCPU &> /dev/null
		rm -rf ${CHIPLAB_HOME}/IP/myCPU/*
		for f in $src
		do
			cp $f ${CHIPLAB_HOME}/IP/myCPU/
		done
	fi
elif [ $1=="nscscc" ]
then
	if [ -z ${NSCSCC_HOME}  ]
	then
		echo "variable NSCSCC_HOME not set"
	else
	then
		mkdir ${NSCSCC}/IP/myCPU &> /dev/null
		rm -rf ${NSCSCC}/IP/myCPU/*
		for f in $src
		do
			cp $f ${NSCSCC}/IP/myCPU/
		done
	fi
fi

