#!/bin/bash

src=$(find . -name "*.sv*")

if [[ $1 == "chiplab" ]]
then
	if test -z $CHIPLAB_HOME
	then
		echo "CHIPLAB_HOME not set"
	else
		mkdir -p ${CHIPLAB_HOME}/IP/myCPU
		rm -rf ${CHIPLAB_HOME}/IP/myCPU/*
		for f in $src
		do	
			cp $f ${CHIPLAB_HOME}/IP/myCPU/
		done
	fi
elif [[ $1 == "nscscc" ]]
then
	if test -z $NSCSCC_HOME
	then
		echo "NSCSCC_HOME not set"
	else
		mkdir -p ${NSCSCC_HOME}/BOOM
		rm -rf ${NSCSCC_HOME}/BOOM/*
		for f in $src
		do	
			cp $f ${NSCSCC_HOME}/BOOM/
		done
	fi
fi