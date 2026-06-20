#!/usr/bin/env bash
set -e
[[ -f '../env.sh' ]] && source ../env.sh || source env.sh
[[ -f '../lib/awg-functions.lib.sh' ]] && source ../lib/awg-functions.lib.sh || awg-functions.lib.sh
set +e

new_public_ip=$(get_public_ip)

if [[ $# -gt 0 ]]; then
  CONFIG_FILE="$1"
elif [[ -f "$CONF_PATH/$JSON_CONFIG_FILE" ]]; then
  CONFIG_FILE="$CONF_PATH/$JSON_CONFIG_FILE"
else
  echo 'No configuration file found.'
  exit 1
fi

# Создаем временную директорию clients
CLIENTS_DIR="/tmp/clients"
rm -rf "$CLIENTS_DIR"
mkdir -p "$CLIENTS_DIR"

echo "Генерация QR-кодов для всех клиентов..."

# Проходим по всем серверам и их клиентам
jq -c '.[] | .server' "$CONFIG_FILE" | while read -r server; do
  if [[ $(echo "$server" | jq -r '.enabled') == "true" ]]; then
    SERVER_NAME=$(echo "$server" | jq -r '.name')
    # Извлекаем данные сервера
    srvPubKey=$(echo "$server" | jq -r '.publicKey')
    port=$(echo "$server" | jq -r '.port')
    hostName=$(echo "$server" | jq -r '.publicHostname')
    mapfile -t hostnames < <(jq -r '.[]' <<< "$(echo "$server" | jq -r .publicHostnames)")
    publicIP=$(echo "$server" | jq -r '.publicIP')
    [[ "$publicIP" == "null" || -z "$publicIP" ]] && publicIP=$new_public_ip
    srvDNS=$(echo "$server" | jq -r '.DNS // "1.1.1.1"')
    AllowedIPs=$(echo "$server" | jq -r '.AllowedIPs // "0.0.0.0/0, ::/0"')
    
    # Amnezia параметры
    junkCount=$(echo "$server" | jq -r '.junkPacketCount // 4')
    junkMin=$(echo "$server" | jq -r '.junkPacketMinSize // 50')
    junkMax=$(echo "$server" | jq -r '.junkPacketMaxSize // 1000')
    initJunk=$(echo "$server" | jq -r '.initPacketJunkSize // 100')
    respJunk=$(echo "$server" | jq -r '.responsePacketJunkSize // 100')
    initMagic=$(echo "$server" | jq -r '.initPacketMagicHeader // 123')
    respMagic=$(echo "$server" | jq -r '.responsePacketMagicHeader // 221')
    mtu=$(echo "$server" | jq -r '.mtu // 1280')
    
    # Обрабатываем клиентов
    echo "$server" | jq -c '.clients | to_entries[]' | while read -r client; do
      if [[ $(echo "$client" | jq -r '.value.enabled') == "true" ]]; then
        CLIENT_NAME=$(echo "$client" | jq -r '.value.name')
        usrIP=$(echo "$client" | jq -r '.value.address')
        usrPrivateKey=$(echo "$client" | jq -r '.value.privateKey')
        usrPreSharedKey=$(echo "$client" | jq -r '.value.presharedKey')
        
        # Создаем папку для клиента
        CLIENT_DIR="$CLIENTS_DIR/${SERVER_NAME}_${CLIENT_NAME}"
        mkdir -p "$CLIENT_DIR"

        # Генерируем QR-коды
        if [[ "${#hostnames[@]}" != "null" && ${#hostnames[@]} -gt 0 ]]; then
          for host_name in "${hostnames[@]}"; do
              generate_qr_png "$host_name" "${host_name}_$port.png"
          done
        elif [[ "$hostName" != "null" && -n "$hostName" ]]; then
          generate_qr_png "$hostName" "${hostName}_$port.png"
        fi
        generate_qr_png "$publicIP" "$publicIP.png"
        
        echo "Созданы QR-коды для клиента: $SERVER_NAME/$CLIENT_NAME"
      fi
    done
  fi
done

echo "Все QR-коды созданы в директории: $CLIENTS_DIR"
echo "Структура:"
find "$CLIENTS_DIR" -type f -name "*.png" | sort