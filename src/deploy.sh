#!/bin/bash

src=$(find ../rtl -name "*.sv*")

if [[ $1 == "chiplab" ]]
then
	echo "delpoying to $CHIPLAB_HOME/myCPU"
	if test -z $CHIPLAB_HOME
	then
		echo "CHIPLAB_HOME not set"
	else
		mkdir -p ${CHIPLAB_HOME}/IP/myCPU
		rm -rf ${CHIPLAB_HOME}/IP/myCPU/*
		for f in $src
		do	
			echo "cp $f ${CHIPLAB_HOME}/IP/myCPU/"
			cp $f ${CHIPLAB_HOME}/IP/myCPU/
		done
	fi
elif [[ $1 == "nscscc" ]]
then
	echo "delpoying to $NSCSCC_HOME/BOOM"
	if test -z $NSCSCC_HOME
	then
		echo "NSCSCC_HOME not set"
	else
		mkdir -p ${NSCSCC_HOME}/BOOM
		rm -rf ${NSCSCC_HOME}/BOOM/*
		for f in $src
		do	
			echo "cp $f ${NSCSC_HOME}/BOOM/"
			cp $f ${NSCSCC_HOME}/BOOM/
		done
	fi
else 
	mkdir -p ${BOOM}/BOOM
	rm -rf ${BOOM}/BOOM/*
	for f in $src
	do	
		cp $f ${BOOM}/BOOM/
	done
fi
