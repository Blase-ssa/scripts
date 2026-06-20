#!/usr/bin/env bash
# set -x
# get_public_ip() {
#   # Пробуем несколько сервисов для получения публичного IP
#   for service in "ifconfig.me" "ipinfo.io/ip" "icanhazip.com" "ident.me"; do
#     IP=$(curl -s --connect-timeout 5 "$service" 2>/dev/null | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
#     [[ -n "$IP" ]] && echo "$IP" && return 0
#   done
#   return 1
# }

get_public_ip() {
  for service in "zx2c4.com/ip" "ifconfig.me" "ipinfo.io/ip" "icanhazip.com"; do
    IP=$(ncurl "$service" | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
    [[ -n "$IP" ]] && echo "$IP" && return 0
  done
  return 1
}

ncurl() {
  ## simple HTTP request with netcat
  local service=$1
  local server=$(echo $service|sed 's|/|\n|g'|head -n 1 )
  local path=$(echo $service|sed "s|$server|/|g" |sed 's|//|/|g')
  printf "GET $path HTTP/1.1\r\nHost: $server\r\nConnection: close\r\n\r\n" | nc $server 80
}

# Если скрипт вызван напрямую
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && get_public_ip