#!/bin/bash

IP_PATTERN="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
PIDFILE='/var/run/logchecker.pid'
LOGFILE=/var/log/access.log
MSG='/vagrant/script/message.txt'
touch ${MSG}
source /vagrant/script/mail_addr
READ_ITER=''
trap "LAST_LINE=1" ERR #set trap for absent lastline.log if true then START_LINE=1
LAST_LINE_STORE='/vagrant/script/lastline.log' #store in lastline.log last read line from LOGFILE
source ${LAST_LINE_STORE} 2>/dev/null #get last read line
trap - ERR
NOWDATE=`date "+%F %T"`
LASTDATE=/vagrant/script/lastdate.txt
touch ${LASTDATE}
TOTAL_LINES=`wc -l ${LOGFILE} | awk '{print $1}'`

check_PID() {
	if [[ -f ${pidfile} ]]; then
		echo "Uihodim, pasany, tut zaniato"
		exit $?
	fi
}

put_PID() {
	trap '$(kill_PID_on_exit)' INT TERM EXIT
	echo $$ >${PIDFILE}
}

kill_PID_on_exit() {
	trap - INT TERM EXIT
	rm -f ${PIDFILE}
	exit 0
}

check_actual_accesslog() {
	if [[ ! -e ${LOGFILE} ]]; then
		echo "ERROR: nginx logfile is absent" >${MSG}
		send_letter
		kill_PID_on_exit
	elif [[ ! -s ${LOGFILE} ]]; then
		echo "WARNING: nginx logfile is zero" >${MSG}
		send_letter
		kill_PID_on_exit
	fi
}
tail_from_last_line() {
	READ_ITER=$(sed "${LAST_LINE},$ p" ${LOGFILE})
	echo ${READ_ITER}
}

save_last_line() {
	if [[ -s ${LOGFILE} ]]; then
		echo "LAST_LINE=${TOTAL_LINES}" >${LAST_LINE_STORE}
	else
		echo "LAST_LINE=1" >${LAST_LINE_STORE}
	fi
}
most_frequent_client_IP() {
	grep -Po "${IP_PATTERN}" ${LOGFILE} | sort | uniq -c | sort -rn | head
}

most_frequent_URL() {
	awk -F\" '{print $2}' /var/log/access.log | awk '{print $2}' | sort | uniq -c | sort -rn
}

all_errors() {
	awk '($9 ~ /[45]../) {print $9}' /var/log/access.log
}

all_responses() {
	awk '{print $9}' /var/log/access.log | sort | uniq -c | sort -nr
}


rotate_date(){
	echo ${NOWDATE} >${LASTDATE}
}

make_letter() {
	if [[ -z ${TEXT} ]]; then
		echo "No new visits since last report" >${MSG}
	else
		echo "10 most frequently visits IP:" >>${MSG}
		echo ${TEXT} | most_frequent_client_IP >>${MSG}
		echo -e "\nMost frequently visited URLs:" >>${MSG}
		echo ${TEXT} | most_frequent_URL >>${MSG}
		echo -e "\nAll errors:" >>${MSG}
		echo ${TEXT} | all_errors >>${MSG}
		echo -e "\nAll responses summary" >>${MSG}
		echo ${TEXT} | all_responses >>${MSG}
	fi
}

send_letter(){
	cat ${MSG} | /bin/mail -s "Nginx access report since `cat ${LASTDATE}` by ${NOWDATE}" ${MAILADDR}
	mv -f ${MSG} /vagrant/script/last_message.txt
}

check_PID
put_PID
TEXT=$(tail_from_last_line)
make_letter
send_letter
save_last_line
rotate_date

