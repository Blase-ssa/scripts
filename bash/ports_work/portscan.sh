#!/usr/bin/env bash
####################################
# A simple port scanner script
# use `./tcpping.sh -h` to get help
####################################

# Uncomment the string below to print every shell command before execute it.
# set -x

## help function
PRINT_HELP(){
	echo "A simple port scanner script.

Usage:
	$0 <options> -A <IP_1> -A <IP_2>:<IP_N> -P <Port_1> -P <Port_2>:<Port_N>
	$0 -h           		# to get this help msg
	$0 -A <IP> -P <Port> 	# to check single port port on a single target

Options:
	-h	This help
	-A	Target IP or DNS name. Can be used multiple times to specify multiple targets. Use \":\" to specify IP range.
	-P	Target port. Can be used multiple times to specify multiple target ports. Use \":\" to specify port range.
	-s	Time in seconds between attempts (default 0 srconds)
	-t	Timeout for connection (default 5 srconds).
		Timeout is a floating point number with an optional suffix: 's' for seconds (the default), 'm'  for
		minutes, 'h' for hours or 'd' for days.  A duration of 0 disables the associated timeout.
	-D	Add timestamp. Valid formats are 'date', 'seconds' (default) or 'ns' for nanoseconds.
	-v	Verbose.

Examples:
	The simplest way to run:
		$0 example.com 80
	Result:
		1:      example.com:80 --> successful connection.
"
}

# include port_work library
source $(dirname "$0")/port_work.lib

## defaults
STIME=0			# Time in seconds between attempts
TIMESTAMP=0		# Timestamp format. Default = no timestamp
verbose=0
## other variables
args=("$@")
loop_count=0
check_fail_count=0
check_success_count=0
start_date=0
PORTS=()
ADDRS=()
PORST_ARRAY=()

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
			-v)
				verbose=1;;
			-s)
				((i+=1)); STIME=${args[i]};;
			-t)
				((i+=1)); TIMEOUT=${args[i]};;
			-D)
				if [[ ${args[i+1]} == 'date' ]] || [[ ${args[i+1]} == 'seconds' ]] || [[ ${args[i+1]} == 'ns' ]]; then i+=1; TIMESTAMP=${args[i]}; else TIMESTAMP='seconds';fi;;
			-P)
				((i+=1)); PORTS+=(${args[i]});;
			-A)
				((i+=1)); ADDRS+=(${args[i]});;
		esac
	fi
done
### some code tweaks
if [[ $TIMESTAMP != 0 ]]; then start_date=$(get_date); fi

### Check for errors

for Port in "${PORTS[@]}"; do
	if (CHECK_PORT_2B_INT); then
		PORST_ARRAY+=($Port)
	else
		for ((i = $(echo $Port | grep -Po "^\d+"); i <= $(echo $Port | grep -Po "\d+$"); i += 1)); do
			PORST_ARRAY+=($i)
		done
	fi
done

for ADDR in "${ADDRS[@]}"; do
	if CHECK_ADDR_IP_RANGE; then
		# GET_IP_RANGE $ADDR
		ADDR_ARRAY+=($(GET_IP_RANGE $ADDR))
		# for ((i = ; i <= $(echo $Port | grep -Po "\d+$"); i += 1)); do
		# 	ADDR_ARRAY+=($i)
		# done
	else
		ADDR_ARRAY+=($ADDR)
	fi
done

### scan ports
for ADDR in "${ADDR_ARRAY[@]}"; do
	for Port in "${PORST_ARRAY[@]}"; do
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
		sleep ${STIME}
	done
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