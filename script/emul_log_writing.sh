#!/bin/bash
################################################
## This script reads data from SOURCE_LOG
## by random numbers of lines and writes
## that portion to DEST_LOG
################################################

SOURCE_LOG='/vagrant/access.log'
DEST_LOG='/var/log/access.log'
trap "START_LINE=1; >${DEST_LOG}" ERR #set trap for absent fixline.log if true then START_LINE=1
FIX_LINES='/vagrant/script/fixline.log' #store in fixline last read line from source log
source /vagrant/script/fixline.log 2>/dev/null #get last read line

gen_num_lines() { #func generating random value for range line to read from sorce log
        echo `shuf -i 15-50 -n 1`
}
NUM_LINES=$(gen_num_lines) #put random range in variable
END_LINE=$((${START_LINE}+${NUM_LINES})) #set new last line for read from sorce log
TOTAL_LINES=`wc -l ${SOURCE_LOG} | awk '{print $1}'`

echo ${START_LINE} ${NUM_LINES} ${END_LINE} ${TOTAL_LINES}

if [[ ${END_LINE} -gt ${TOTAL_LINES} ]]; then
        END_LINE=${TOTAL_LINES}
        echo "The source log is totally readen!!!"
		echo "END_LINE=1" >${FIX_LINES}
fi
sed -n "${START_LINE},${END_LINE}p" ${SOURCE_LOG} >>${DEST_LOG}


echo "START_LINE=$((${END_LINE}+1))">fixline.log #put last read line to fixline.log