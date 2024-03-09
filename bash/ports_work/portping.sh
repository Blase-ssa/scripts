#!/usr/bin/env bash
####################################
# A simple port availability check script.
# use `./tcpping.sh -h` to get help
####################################

# Uncomment the string below to print every shell command before execute it.
# set -x

## help function
PRINT_HELP(){
	echo "A simple port availability check script.

Usage:
	$0 <options> <IP> <Port>
	$0 -h           # to get this help msg
	$0 <IP> <Port>  # to check port

Options:
	-h	This help
	-c	Count of attempts
	-f	Infinity nember of attempts
	-w	Ping until success
	-s	Time in seconds between attempts (default 0 srconds)
	-t	Timeout for connection (default 5 srconds).
		Timeout is a floating point number with an optional suffix: 's' for seconds (the default), 'm'  for
		minutes, 'h' for hours or 'd' for days.  A duration of 0 disables the associated timeout.
	-P	Protocol. Should be 'tcp' or 'udp'
	-D	Add timestamp. Valid formats are 'date', 'seconds' (default) or 'ns' for nanoseconds.
	-v	Verbose.

Examples:
	The simplest way to run:
		$0 example.com 80
	Result:
		1:      example.com:80 --> successful connection.
	
	To run with a timestamp, you can run a command like the following:
		$0 -D example.com 80
			OR
		$0 -D seconds example.com 80
	Result:
		2024-03-08 21:17:48+01:00:  example.com:80 --> successful connection.
	
	Also, if you add the '-v' parameter, you can get expanded output after executing the command:
		$0 -D -v example.com 80
	Result:
		2024-03-08 21:19:58+01:00:  example.com:80 --> successful connection.

		Total try count:        1
		Failed attempts:        0
		Successful connections: 1
		Script started at 2024-03-08 21:19:58+01:00
		Script ended at 2024-03-08 21:19:58+01:00

	Without '-D' the output will be a little simpler.
		$0 -v example.com 80
	Result:
		1:      example.com:80 --> successful connection.

		Total try count:        1
		Failed attempts:        0
		Successful connections: 1
	If you need to catch the moment the service starts, it is useful to use the following command:
		$0 -D -t 2s -s 5 -v -w example.com 80
	Result:
		2024-03-08 21:26:02+01:00:  example.com:80 --> failed to connect.
		2024-03-08 21:26:09+01:00:  example.com:80 --> failed to connect.
		2024-03-08 21:26:16+01:00:  example.com:80 --> failed to connect.
		2024-03-08 21:26:21+01:00:  example.com:80 --> successful connection.
		Exit on success

		Total try count:        4
		Failed attempts:        3
		Successful connections: 1
		Script started at 2024-03-08 21:26:02+01:00
		Script ended at 2024-03-08 21:26:21+01:00

PS: I needed a simple script to check the availability of ports from a container where there is neither nc nor nmap.
And in general, I was satisfied with this code:
	(echo >/dev/tcp/<IP>/<Port>) &>/dev/null && return true || return false
But I got a little carried away and wrote this script.
"
}

# include port_work library
source $(dirname "$0")/port_work.lib

## defaults
AC=1			# Count of attempts
F=0				# Infinity nember of attempts
W=0				# Ping until success
STIME=5			# Time in seconds between attempts
TIMESTAMP=0		# Timestamp format. Default = no timestamp
verbose=0
## other variables
args=("$@")
loop_count=0
check_fail_count=0
check_success_count=0
start_date=0

## Main
### Print help and exit
if [[ $# < 1 ]] || [[ $1 == '-h' ]] ; then
	PRINT_HELP
	exit 0
fi

### Analysis of optional arguments.
for ((i = 0; i < $#; i+=1)); do
	if [[ ${args[i]} =~ "-" ]] && [[ $(echo "${args[i]}"| wc -m) == 3 ]]; then
		case ${args[i]} in
			-c)
				((i+=1)); AC=${args[i]};;
			-v)
				verbose=1;;
			-f)
				F=1;;
			-w)
				W=1;;
			-s)
				((i+=1)); STIME=${args[i]};;
			-t)
				((i+=1)); TIMEOUT=${args[i]};;
			-P)
				((i+=1)); PROTOCOL=${args[i]};;
			-D)
				if [[ ${args[i+1]} == 'date' ]] || [[ ${args[i+1]} == 'seconds' ]] || [[ ${args[i+1]} == 'ns' ]]; then i+=1; TIMESTAMP=${args[i]}; else TIMESTAMP='seconds';fi;;
		esac
	fi
done
### some code tweaks
if [[ $TIMESTAMP != 0 ]]; then start_date=$(get_date); fi
if [[ $W == 1 ]] && [[ $AC == 1 ]]; then F=1; fi

Port=${args[-1]}
ADDR=${args[-2]}

### Check for errors
CHECK_PROTOCOL
if !(CHECK_PORT_2B_INT); then
	echo "Port (\"${Port}\") is not integer."
	echo "Or out of the range 0 < Port < 65536."
	echo "Run \"$0 -h\" - to get help"
	exit 1
fi
#### ckek address
if !(CHECK_ADDR_DNS) || !(CHECK_ADDR_IP); then
	echo "Address should be IP or DNS name. (\"${ADDR}\")"
	echo "Run \"$0 -h\" - to get help"
fi

while true; do
	((loop_count+=1))
	if [[ $TIMESTAMP != 0 ]]; then
		echo -ne "$(get_date):  "
	else
		echo -ne "${loop_count}:\t"
	fi
	echo -n "${ADDR}:${Port} --> "
	check_port_stat=$(TCP_PING)
	if [[ $check_port_stat == 0 ]]; then
		echo "successful connection."
		((check_success_count+=1))
	else
		echo "failed to connect."
		((check_fail_count+=1))
	fi
	
	if [[ $W == 1 ]] && [[ $check_success_count -gt 0 ]]; then
		echo "Exit on success"
		break;
	fi
	if [[ $F -eq 0 ]] && [[ $loop_count -ge $AC ]]; then
		break;
	fi
	sleep ${STIME}
done

if [[ $verbose -gt 0 ]]; then
	echo
	echo -e "Total try count:\t${loop_count}"
	echo -e "Failed attempts:\t${check_fail_count}"
	echo -e "Successful connections: ${loop_count}"
	if [[ $TIMESTAMP != 0 ]]; then
		echo "Script started at ${start_date}"
		echo "Script ended at	$(get_date)"
	fi 
fi