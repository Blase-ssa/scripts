#!/usr/bin/env bash
# This script was created to publish data about server availability.
# But it can be used to publish other data.
#
# Require: netcat nslookup
#
set -o allexport

# DNS name
ENV_DNS="8.8.8.8"
# log file name
SRV_LOG="netcat.log"
# server port
SRV_PORT=8000
## timeout waiting for connection to nc server in seconds
## Set to 0 to disable timeout and enable "stable algorithm"
SRV_TIMEOUT=0 #360
# Maximum log size in bytes
MAX_LOG_SIZE=5000000
# http header
SRV_HEADER="HTTP/1.1 200 Everything Is Just Fine
Server: Stat Exporter
Content-Type: application/json; charset=UTF-8"

## .env file contain 2 variables ENV_SRV1 and ENV_SRV2
## these 2 variables contains 2 server names to check helth status
source .env

json_date(){
    ## json template:
    echo "{
  \"self\":{
    \"date_hr\":\"$(date --rfc-3339 seconds)\",
    \"date_mr\":\"$(date +%s)\"
  },
  \"servers\": [
    {
      \"FQDN\": \"${ENV_SRV1}\",
      \"lookup\":{
        \"Address_count\": \"$(( $(nslookup ${ENV_SRV1} - ${ENV_DNS} |grep -ci 'Address') - 1 ))\",
        \"IP\":\"$(nslookup ${ENV_SRV1} - ${ENV_DNS} |grep -im2 "Address"|tail -n1| grep -Po '\d+\.\d+\.\d+\.\d+$')\"
      },
      \"ping\":\"$(ping ${ENV_SRV1} -c 1 |grep -Po 'time=\K\d+\.\d+')\"
    },
    {
      \"FQDN\": \"${ENV_SRV2}\",
      \"lookup\":{
        \"Address_count\": \"$(( $(nslookup ${ENV_SRV2} - ${ENV_DNS} |grep -ci 'Address') - 1 ))\",
        \"IP\":\"$(nslookup ${ENV_SRV2} - ${ENV_DNS} |grep -im2 "Address"|tail -n1| grep -Po '\d+\.\d+\.\d+\.\d+$')\"
      },
      \"ping\":\"$(ping ${ENV_SRV2} -c 1 |grep -Po 'time=\K\d+\.\d+')\"
    }
  ]
}"
}
run_web_srv(){
    ## function open web socket and wait for request
    echo -e "${SRV_HEADER}\n\n${JSON_DATA}\n" | nc -l $SRV_PORT -q 1 -v
}

while true; do 
    LOG_MSG=''
    
    ## Checking whether the maximum allowed log size has been exceeded.
    if (( $(stat -c%s $SRV_LOG) > $MAX_LOG_SIZE )); then
      echo "Clean log file"
      echo "" > $SRV_LOG;
    fi

    ## generate response data
    JSON_DATA=$(json_date)
    
    ## start the server every ${SRV_TIMEOUT}.
    if [[ $SRV_TIMEOUT == 0 ]]; then
      ## >> Stable algorithm, but to get up-to-date data, you need to request it twice.. <<
      LOG_MSG=$(run_web_srv) # |tee -a $SRV_LOG
    else
      ## >> Unstable algorithm, but up-to-date data. <<
      LOG_MSG=$(timeout --preserve-status ${SRV_TIMEOUT} bash -c run_web_srv)
    fi
    
    ## Checking whether something needs to be written to the logs.
    if (( ${#LOG_MSG} > 0 )); then
      ## send timestamp into log
      date --rfc-3339 seconds |tee -a $SRV_LOG
      echo "${LOG_MSG}" |tee -a $SRV_LOG
    fi
done
