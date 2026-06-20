#!/usr/bin/env bash

set -e
[[ -f 'env.sh' ]] && source env.sh
[[ -f './lib/awg-functions.lib.sh' ]] && source ./lib/awg-functions.lib.sh || source awg-functions.lib.sh
set +e

[[ $# -gt 0 ]] && UUID="$1"

if [[ $# -gt 1 ]]; then
  CONFIG_FILE="$2"
elif [[ -f "$CONF_PATH/$JSON_CONFIG_FILE" ]]; then
  CONFIG_FILE="$CONF_PATH/$JSON_CONFIG_FILE"
else
  echo 'No configuration file found.'
  exit 1
fi

#JSON_USER=$(jq -r ".[].server.clients[\"$UUID\"] | select(. != null)" "$CONFIG_FILE")
JSON_USER=$(get_usr_json_data_by_uuid $UUID)
#JSON_SRV=$(jq --arg uuid "$UUID" '[ .[] | select(.server.clients[$uuid]) | { server: { name: .server.name, address: .server.address, port: .server.port, publicKey: .server.publicKey, publicIP: .server.publicIP, publicHostname: .server.publicHostname, AllowedIPs: .server.AllowedIPs, DNS: .server.DNS, junkPacketCount: .server.junkPacketCount, junkPacketMinSize: .server.junkPacketMinSize, junkPacketMaxSize: .server.junkPacketMaxSize, initPacketJunkSize: .server.initPacketJunkSize, responsePacketJunkSize: .server.responsePacketJunkSize, initPacketMagicHeader: .server.initPacketMagicHeader, responsePacketMagicHeader: .server.responsePacketMagicHeader, mtu: .server.mtu } } ]' "$CONFIG_FILE")

JSON_SRV=$(get_srv_json_data_by_uuid $UUID)

# JSON_USER=$(get_user_by_uuid $UUID)
# JSON_SRV=$(get_srv_by_uuid $UUID)

generate_client_config_json $UUID "$CONFIG_FILE"

# Генерируем конфигурационные файлы
if [[ "${#hostnames[@]}" != "null" && ${#hostnames[@]} -gt 0 ]]; then
  for host_name in "${hostnames[@]}"; do
      generate_config "$host_name" "_$host_name"
  done
elif [[ "$hostName" != "null" && -n "$hostName" ]]; then
  generate_config "$hostName" "_hostname"
fi
generate_config "$publicIP" "_ip"