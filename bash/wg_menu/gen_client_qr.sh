#!/usr/bin/env bash
# set -x

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

JSON_USER=$(jq -r ".[].server.clients[\"$UUID\"] | select(. != null)" "$CONFIG_FILE")
#JSON_SRV=$(jq --arg uuid "$UUID" '[ .[] | select(.server.clients[$uuid]) | { server: { name: .server.name, address: .server.address, port: .server.port, publicKey: .server.publicKey, publicIP: .server.publicIP, publicHostname: .server.publicHostname, AllowedIPs: .server.AllowedIPs, DNS: .server.DNS, junkPacketCount: .server.junkPacketCount, junkPacketMinSize: .server.junkPacketMinSize, junkPacketMaxSize: .server.junkPacketMaxSize, initPacketJunkSize: .server.initPacketJunkSize, responsePacketJunkSize: .server.responsePacketJunkSize, initPacketMagicHeader: .server.initPacketMagicHeader, responsePacketMagicHeader: .server.responsePacketMagicHeader, mtu: .server.mtu } } ]' "$CONFIG_FILE")

JSON_SRV=$(get_srv_json_data_by_uuid $UUID)

# JSON_USER=$(get_user_by_uuid $UUID)
# JSON_SRV=$(get_srv_by_uuid $UUID)

srvDNS=$(echo $JSON_SRV| jq -r '.[].server.DNS // "1.1.1.1"')
AllowedIPs=$(echo $JSON_SRV| jq -r '.[].server.AllowedIPs // "0.0.0.0/0, ::/0"')
port=$(echo $JSON_SRV| jq -r .[].server.port)
hostName=$(echo $JSON_SRV| jq -r .[].server.publicHostname)
mapfile -t hostnames < <(jq -r '.[]' <<< "$(echo $JSON_SRV| jq -r .[].server.publicHostnames)")
publicIP=$(echo $JSON_SRV| jq -r .[].server.publicIP)
[[ "$publicIP" == "null" || -z "$publicIP" ]] && publicIP=$(get_public_ip)
srvPubKey=$(echo $JSON_SRV| jq -r .[].server.publicKey)

# Извлекаем Amnezia-параметры
# Извлекаем Amnezia-параметры
if [[ "$WG_MODE" == "wireguard" ]]; then
  junkCount=$(echo $JSON_SRV| get_srv_awg_junkCount)
  junkMin=$(echo $JSON_SRV| get_srv_awg_junkMin)
  junkMax=$(echo $JSON_SRV| get_srv_awg_junkMax)
  initJunk=$(echo $JSON_SRV| get_srv_awg_initJunk)
  respJunk=$(echo $JSON_SRV| get_srv_awg_respJunk)
  initMagic=$(echo $JSON_SRV| get_srv_awg_initMagic)
  respMagic=$(echo $JSON_SRV| get_srv_awg_respMagic)
  mtu=$(echo $JSON_SRV| get_srv_awg_mtu)
fi

usrIP=$(echo $JSON_USER| jq -r .address)
usrPreSharedKey=$(echo $JSON_USER| jq -r .presharedKey)
usrPrivateKey=$(echo $JSON_USER| jq -r .privateKey)

# Генерируем QR-коды
if [[ "${#hostnames[@]}" != "null" && ${#hostnames[@]} -gt 0 ]]; then
  for host_name in "${hostnames[@]}"; do
      generate_qr "$host_name" "=== Server: $host_name:$port ==="
  done
elif [[ "$hostName" != "null" && -n "$hostName" ]]; then
  generate_qr "$hostName" "=== QR Code with Hostname ==="
fi
generate_qr "$publicIP" "=== QR Code with IP Address ==="
