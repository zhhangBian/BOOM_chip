#!/bin/bash 

usage(){
echo "Usage: configure [option]" 
echo "Standard options:"
echo "  --help                print this message"           
echo "  --run software        set software list(use ',' select multiple softwares)
                        Available software: func/func_lab3 func/func_lab4 
                        func/func_lab6 func/func_lab7 func/func_lab8 func/func_lab9
                        dhrystone coremark"
} 

RUN_FUNC=n
CONFIG_LOG="./configure.sh"

#get opt 
TEMP=`getopt -o h -a -l run:,disable-trace,help -n "$0" -- "$@"` 
if [ $? != 0 ]
then 
    echo "Terminating......" >&2
    exit 1 
fi 

eval set -- "$TEMP" 

while true
do 
    case "$1" in 
        -run|--run)
            RUN_SOFTWARE=$2 
            CONFIG_LOG="$CONFIG_LOG $1 $2"
            shift 2 ;;
        -h|-help|--help)
            usage 
            exit ;;
        --|-)
            shift 
            break ;;
        *)
            usage 
            exit ;;
    esac 
done 

#echo $ENABLE_TRACE
#echo $RUN_SOFTWARE 

mkdir -p ./obj 

OLD_IFS="$IFS"
IFS=","
SOFTWARE_LIST=($RUN_SOFTWARE)
IFS="$OLD_IFS"

for software in ${SOFTWARE_LIST[@]} 
do
    case $software in 
        func/func_lab3) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        func/func_lab4) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        func/func_lab6) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        func/func_lab7) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        func/func_lab8) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        func/func_lab9) 
            RUN_FUNC=y
            mkdir -p ./obj/func
            ;;
        coremark)
            RUN_FUNC=n
            ;;
        dhrystone)
            RUN_FUNC=n
            ;;
        *)
            echo "Software $software unavailable!!" 
            exit
            ;;
    esac 
done

CONFIG_SOFT="./config-software.mak"
CONFIG_LOG_FILE="./config.log"

if [ ! -f "$CONFIG_SOFT" ]; then 
    touch $CONFIG_SOFT 
else 
    rm $CONFIG_SOFT 
    touch $CONFIG_SOFT 
fi 

echo "RUN_SOFTWARE=$RUN_SOFTWARE" >> $CONFIG_SOFT 
echo "RUN_FUNC=$RUN_FUNC" >> $CONFIG_SOFT 

if [ ! -f "$CONFIG_LOG_FILE" ]; then 
    touch $CONFIG_LOG_FILE 
else 
    rm $CONFIG_LOG_FILE 
    touch $CONFIG_LOG_FILE 
fi 

echo "#chiplab fpga configure log" >> $CONFIG_LOG_FILE
echo "#Configured with: $CONFIG_LOG" >> $CONFIG_LOG_FILE

