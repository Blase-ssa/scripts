#!/usr/bin/env bash
# #########################################
# A set of functions used in the program.
# #########################################

get_input(){
  ## A special function that allows you to pass both an argument and a pipe
  ## When using both pipe and argument, the command-line argument takes precedence.
  local input
  if [[ -n "$1" ]]; then
    # передан как аргумент
    input="$1"
  elif [[ ! -t 0 ]]; then
    # передан через пайп
    input="$(cat)"
  else
    # echo "No input provided" >&2
    return 1
  fi
  printf '%s' "$input"
}

gen_rand_in_range() {
  ## Generate random number in range
  local min=$1
  local max=$2
  echo $((min + RANDOM % (max - min + 1)))
}

offer_client_ip() {
  ## Generate IP for client (Literally: check the last IP recorded in the client list for the server and offer IP+1)
  ## requires:
  ##  - $1 - server name ("wg_config.json".[].server.name)
  [[ $# -eq 0 ]] && return 1 || SERVER=$1
  IP_LIST=$(get_clients_ip_list $SERVER)
  if [[ $(echo $IP_LIST| grep -Ec '\d+\.\d+\.\d+\.\d+') -eq 0 ]]; then 
    last_ip=$(get_server_ip $SERVER)
  else
    last_ip=$(echo "${IP_LIST}"| tail -n 1)
  fi
  b_ip=$(echo $last_ip| tail -n 1 |cut -d'.' -f -3)
  e_ip=$(echo $last_ip| tail -n 1 |cut -d'.' -f 4)
  echo "$b_ip.$(($e_ip + 1))"
  return 0
}

get_server_ip() {
  ## This function returns the IP address of the server
  ## requires:
  ##  - $1 - server name ("wg_config.json".[].server.name)
  ##  - $2 - path to configuration JSON file or -->
  ##  - $TMPCONF to be set
  [[ $# -eq 0 ]] && return 1 || SERVER=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$TMPCONF
  jq "map(select(.server.name == \"$SERVER\"))" $conf_file |jq -r ".[].server.address"
  return $?
}

get_servers_list() {
  ## Returns a list of server names
  ## requires:
  ##  - $1 - path to configuration JSON file or -->
  ##  - $2 - path to configuration JSON file or -->
  ##  - $TMPCONF to be set
  [[ $# -gt 0 ]] && conf_file=$1 || conf_file=$TMPCONF
  jq -r '.[].server.name' "$conf_file"
  return $?
}

get_clients_ip_list() {
  ## This function returns the IP address of all clients of the server
  ## requires:
  ##  - $1 - server name ("wg_config.json".[].server.name)
  ##  - $2 - path to configuration JSON file or -->
  ##  - $TMPCONF to be set
  [[ $# -eq 0 ]] && return 1 || SERVER=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$TMPCONF
  jq "map(select(.server.name == \"$SERVER\"))" $conf_file |jq -r ".[].server.clients[].address"
  return $?
}

delete_server() {
  ## delete server/interface by server name
  ## requires:
  ##   - $1 - server name ("wg_config.json".[].server.name)
  [[ $# -lt 1 ]] && return 1 || SERVER=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$TMPCONF
  jq "map(select(.server.name != \"$SERVER\"))" "$conf_file" > $TMPJSON && mv $TMPJSON "$conf_file"
  return $?
}

delete_user() {
  ## delete user by UID
  ## requires:
  ##   - $1 - UUID (Unique user ID) ("wg_config.json".[].server.clients.[])
  [[ $# -eq 0 ]] && return 1 || UUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$TMPCONF
  jq ".[].server.clients |= del(.[\"$UUID\"])" "$conf_file" > $TMPJSON && mv $TMPJSON "$conf_file"
  return $?
}

get_users_list() {
  ## Returns a list of usernames names of the server
  ## requires:
  ##   - $1 - server name ("wg_config.json".[].server.name)
  [[ $# -lt 1 ]] && return 1 || SERVER=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$TMPCONF
  jq "map(select(.server.name == \"$SERVER\"))" $conf_file |jq -r ".[].server.clients.[].name"
  return $?
}

get_user_uid() {
  [[ $# -lt 2 ]] && return 1
  SERVER=$1
  USRNAME=$2
  [[ $# -gt 3 ]] && conf_file=$2 || conf_file="$CONF_PATH/$JSON_CONFIG_FILE"
  jq "map(select(.server.name == \"$SERVER\"))" "$conf_file" |jq -r ".[].server.clients" |jq "to_entries[] | select(.value.name == \"$USRNAME\")"| jq -r ".key"
  
  return $?
}

get_user_by_uuid() {
  [[ $# -lt 1 ]] && return 1 || UUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file="$CONF_PATH/$JSON_CONFIG_FILE"
  jq -r ".[].server.clients[\"$UUID\"] | select(. != null)" "$conf_file"
}

get_srv_by_uuid() {
  [[ $# -lt 1 ]] && return 1 || UUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file="$CONF_PATH/$JSON_CONFIG_FILE"
  jq --arg uuid "$UUID" '[ .[] | select(.server.clients[$uuid]) | { server: { name: .server.name, address: .server.address, port: .server.port, publicKey: .server.publicKey, publicIP: .server.publicIP, publicHostname: .server.publicHostname, AllowedIPs: .server.AllowedIPs, DNS: .server.DNS, junkPacketCount: .server.junkPacketCount, junkPacketMinSize: .server.junkPacketMinSize, junkPacketMaxSize: .server.junkPacketMaxSize, initPacketJunkSize: .server.initPacketJunkSize, responsePacketJunkSize: .server.responsePacketJunkSize, initPacketMagicHeader: .server.initPacketMagicHeader, responsePacketMagicHeader: .server.responsePacketMagicHeader, mtu: .server.mtu } } ]' "$conf_file"
}

get_public_ip() {
  for service in "zx2c4.com/ip" "ifconfig.me" "ipinfo.io/ip" "icanhazip.com"; do
    ## curl is not installed
    # IP=$(curl -s --connect-timeout 5 "$service" 2>/dev/null | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
    
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

print_conf() {
  ## this function print configuration aut of prepared variables
    if [[ "$WG_MODE" == "wireguard" ]]; then
    # Обычный WireGuard
    cat <<EOF
[Interface]
PrivateKey = $usrPrivateKey
Address = $usrIP/24
DNS = $srvDNS

[Peer]
PublicKey = $srvPubKey
PresharedKey = $usrPreSharedKey
AllowedIPs = $AllowedIPs
PersistentKeepalive = 25
Endpoint = $endpoint:$port
EOF
  else
    # AmneziaWG
    cat <<EOF
[Interface]
PrivateKey = $usrPrivateKey
Address = $usrIP/24
DNS = $srvDNS
MTU = $mtu
Jc = $junkCount
Jmin = $junkMin
Jmax = $junkMax
S1 = $initJunk
S2 = $respJunk
H1 = $initMagic
H2 = $respMagic

[Peer]
PublicKey = $srvPubKey
PresharedKey = $usrPreSharedKey
AllowedIPs = $AllowedIPs
PersistentKeepalive = 25
Endpoint = $endpoint:$port
EOF
  fi
}

generate_qr_png() {
  local endpoint=$1
  local filename=$2
  
  print_conf | qrencode -t PNG -o "$CLIENT_DIR/$filename"
  echo "Generated: $CLIENT_DIR/$filename"
}

generate_config() {
  local endpoint=$1
  local suffix=$2
  local filename="$CLIENT_DIR/${usrName}${suffix}.conf"
  
  print_conf > "$filename"
  echo "Generated: $filename"
}

generate_qr() {
  local endpoint=$1
  local title=$2
  echo "$title"
  
  print_conf | qrencode -t ANSI
  
  echo
  read -p "Press any key to continue."
}

get_srv_json_data_by_uuid() {
  ## This function returns server data, by USER id
  ## requires:
  ##  - $1 - UUID (Unique user ID) ("wg_config.json".[].server.clients.[])
  ##  - $2 - path to configuration JSON file or -->
  ##  - $CONFIG_FILE to be set
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1
  local output
  output=$(jq --arg uuid "$ClientUUID" '
[
  .[]
  | select(.server.clients[$uuid])
  | {
      server: {
        name: .server.name,
        address: .server.address,
        port: .server.port,
        publicKey: .server.publicKey,
        publicIP: .server.publicIP,

        # новый массив публичных адресов
        publicHostnames: .server.publicHostnames,

        # старый ключ для обратной совместимости (если нужен)
        publicHostname: .server.publicHostname,

        AllowedIPs: .server.AllowedIPs,
        DNS: .server.DNS,
        junkPacketCount: .server.junkPacketCount,
        junkPacketMinSize: .server.junkPacketMinSize,
        junkPacketMaxSize: .server.junkPacketMaxSize,
        initPacketJunkSize: .server.initPacketJunkSize,
        responsePacketJunkSize: .server.responsePacketJunkSize,
        initPacketMagicHeader: .server.initPacketMagicHeader,
        responsePacketMagicHeader: .server.responsePacketMagicHeader,
        mtu: .server.mtu
      }
    }
]' "$conf_file")
  echo "${output}"
  [[ ${#output} -gt 5 ]] && return 0 || return 1
}

get_usr_json_data_by_uuid() {
  ## This function returns selected user data
  ## requires:
  ##  - $1 - UUID (Unique user ID) ("wg_config.json".[].server.clients.[])
  ##  - $2 - path to configuration JSON file or -->
  ##  - $CONFIG_FILE to be set
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1
  local output
  output=$(jq -r ".[].server.clients[\"$ClientUUID\"] | select(. != null)" "$conf_file")
  echo "${output}"
  [[ ${#output} -gt 5 ]] && return 0 || return 1
}


## get_srv_* section
get_srv_dns() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.DNS // "1.1.1.1"' <<< "$input"
}

get_srv_allowed_ips() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.AllowedIPs // "0.0.0.0/0, ::/0"' <<< "$input"
}

get_srv_port() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .[].server.port <<< "$input"
}

get_srv_hostName() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .[].server.publicHostname <<< "$input"
}

get_srv_hostnames() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[]' <<< "$(echo $JSON_SRV| jq -r .[].server.publicHostnames)" <<< "$input"
}

get_srv_publicIP() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .[].server.publicIP <<< "$input"
}

get_srv_PubKey() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .[].server.publicKey <<< "$input"
}

## get_srv_awg_* section
get_srv_awg_junkCount() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.junkPacketCount // 4' <<< "$input"
}
get_srv_awg_junkMin() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.junkPacketMinSize // 50' <<< "$input"
}
get_srv_awg_junkMax() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.junkPacketMaxSize // 1000' <<< "$input"
}
get_srv_awg_initJunk() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.initPacketJunkSize // 100' <<< "$input"
}

get_srv_awg_respJunk() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.responsePacketJunkSize // 100' <<< "$input"
}

get_srv_awg_initMagic() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.initPacketMagicHeader // 123' <<< "$input"
}

get_srv_awg_respMagic() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.responsePacketMagicHeader // 221' <<< "$input"
}

get_srv_awg_mtu() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r '.[].server.mtu // 1280' <<< "$input"
}

## get_user_* section
get_user_ip() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .address <<< "$input"
}

get_user_PreSharedKey() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .presharedKey <<< "$input"
}

get_user_PrivateKey() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .privateKey <<< "$input"
}

get_user_Name() {
  local input
  input="$(get_input "$1")" || return 1
  jq -r .name <<< "$input"
}

generate_client_config_json() {
  ## this function prepare variables for client configuration
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1

  JSON_USER="$(get_usr_json_data_by_uuid $ClientUUID)"
  JSON_SRV="$(get_srv_json_data_by_uuid $ClientUUID)"

  srvDNS="$(echo $JSON_SRV| get_srv_dns)"
  AllowedIPs="$(echo $JSON_SRV| get_srv_allowed_ips)"
  port="$(echo $JSON_SRV| get_srv_port)"
  hostName="$(echo $JSON_SRV| get_srv_hostName)"
  # mapfile -t hostnames < <(jq -r '.[]' <<< "$(echo $JSON_SRV| jq -r .[].server.publicHostnames)")
  mapfile -t hostnames < <(echo $JSON_SRV| get_srv_hostnames)
  publicIP="$(echo $JSON_SRV| get_srv_publicIP)"
  [[ "$publicIP" == "null" || -z "$publicIP" ]] && publicIP="$(get_public_ip)"
  srvPubKey="$(echo $JSON_SRV| get_srv_PubKey)"

  # Извлекаем Amnezia-параметры
  if [[ "$WG_MODE" == "wireguard" ]]; then
    junkCount="$(echo $JSON_SRV| get_srv_awg_junkCount)"
    junkMin="$(echo $JSON_SRV| get_srv_awg_junkMin)"
    junkMax="$(echo $JSON_SRV| get_srv_awg_junkMax)"
    initJunk="$(echo $JSON_SRV| get_srv_awg_initJunk)"
    respJunk="$(echo $JSON_SRV| get_srv_awg_respJunk)"
    initMagic="$(echo $JSON_SRV| get_srv_awg_initMagic)"
    respMagic="$(echo $JSON_SRV| get_srv_awg_respMagic)"
    mtu="$(echo $JSON_SRV| get_srv_awg_mtu)"
  fi
  usrIP="$(echo $JSON_USER| get_user_ip)"
  usrPreSharedKey="$(echo $JSON_USER| get_user_PreSharedKey)"
  usrPrivateKey="$(echo $JSON_USER| get_user_PrivateKey)"
  usrName="$(echo $JSON_USER| get_user_Name)"
}

generate_client_config_files() {
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1

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
}

generate_client_config_qrs() {
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1

  generate_client_config_json $UUID "$CONFIG_FILE"

  # Генерируем QR-коды
  if [[ "${#hostnames[@]}" != "null" && ${#hostnames[@]} -gt 0 ]]; then
    for host_name in "${hostnames[@]}"; do
        generate_qr "$host_name" "=== Server: $host_name:$port ==="
    done
  elif [[ "$hostName" != "null" && -n "$hostName" ]]; then
    generate_qr "$hostName" "=== QR Code with Hostname ==="
  fi
  generate_qr "$publicIP" "=== QR Code with IP Address ==="
}

generate_client_config_pngs() {
  [[ $# -eq 0 ]] && return 1 || ClientUUID=$1
  [[ $# -gt 1 ]] && conf_file=$2 || conf_file=$CONFIG_FILE
  [[ "${#ClientUUID}" -lt "4" ]] && return 1

  generate_client_config_json $UUID "$CONFIG_FILE"

  # Генерируем QR-коды
  if [[ "${#hostnames[@]}" != "null" && ${#hostnames[@]} -gt 0 ]]; then
    for host_name in "${hostnames[@]}"; do
        generate_qr_png "$host_name" "=== Server: $host_name:$port ==="
    done
  elif [[ "$hostName" != "null" && -n "$hostName" ]]; then
    generate_qr_png "$hostName" "=== QR Code with Hostname ==="
  fi
  generate_qr_png "$publicIP" "=== QR Code with IP Address ==="
}
