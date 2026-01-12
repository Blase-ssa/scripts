#!/bin/bash
###########################################
## A simple script for calling ssh connections.
## All connections configured in ~/.ssh/config
###########################################
config_file="~/.ssh/config"


config_file="$(eval echo $config_file)"
while true; do
  if [[ -f $config_file ]]; then
    srv_list=($(grep "Host " $config_file |cut -d' ' -f 2))
  else
    echo "ERROR: SSH configuration file \"$config_file\" - does not exist."
    exit 1
  fi
  if [[ -z $srv_list ]]; then
    echo "ERROR: SSH configuration file \"$config_file\" exist, but has no hosts"
    exit 1
  fi
  iteration=0
  echo "Choose a server:"
  for srv_str in "${srv_list[@]}"; do
    echo "${iteration}) $srv_str"
    iteration=$(($iteration + 1))
  done
  echo "-) Exit"
  # Read input
  read selection
  
  case $selection in
    -)
      echo "Bye."
      exit 0
      ;;
    c)
      clear
      ;;
    [[:digit:]]*)
      if [[ $selection -gt ${#srv_list[@]} ]]; then
        echo "ERROR: \"$selection\" is out if range."
      else
        # ssh in to a server
        ssh ${srv_list[$selection]}
      fi
      ;;
    *)
      echo "Wrong option provided"
      ;;
  esac
done
