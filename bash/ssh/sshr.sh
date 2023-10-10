#!/bin/bash
###########################################
## A simple script for storing ssh strings.
## The "srv_list" variable contains a list
## of servers in the format:
## Text_before_space - description, will be
##      ignored in the command;
## Everything that comes after the first
##      space will be inserted into the
##      ssh command.
##
## Example 1:
## srv_list=("My_Srv_1 172.16.0.3")
## SSH command:
## ssh 172.16.0.3
## Example 2:
## srv_list=("My_Srv_2 -L 8080:localhost:8080 -L 8443:localhost:8443 username@example.com -P 2222 -i ~/.ssh/example_com_id_rsa")
## SSH command:
## ssh -L 8080:localhost:8080 -L 8443:localhost:8443 username@example.com -P 2222 -i ~/.ssh/example_com_id_rsa
###########################################

srv_list=(
"Srv-1 172.16.0.3"
"Srv-2 user@example.com -P 2222"
"Port_fwd_Srv-2  -L 8080:localhost:8080 -L 8443:localhost:8443 user@example.com -P 2222"
)
iteration=0
echo "Choose a server:"
for srv_str in "${srv_list[@]}"; do
        echo "${iteration}) $srv_str"
        iteration=$(expr $iteration + 1)
        #for i in ${srv_str[@]}; do
        #       echo $i
        #done
done
# Read input
reading_state=true
while $reading_state; do
        read
        if [ $(echo $REPLY|grep -Poc '\d') -eq 0 ] || [ $(echo $REPLY|grep -Poc '\D') -gt 0 ]; then
                echo "Enter numbers, no spaces or other symbols."
        else
                reading_state=false
        fi

done
# Get ssh options
selection=$(echo ${srv_list[$REPLY]}| sed 's/^\S\+//g')

# ssh in to a server
ssh ${selection}
