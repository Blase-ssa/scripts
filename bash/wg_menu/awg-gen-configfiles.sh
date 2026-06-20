#!/usr/bin/env bash
# set -x
[[ -f 'env.sh' ]] && source env.sh
source awg-function.lib.sh

if [[ $# -gt 0 ]]; then
  CONFIG_FILE="$1"
else
  CONFIG_FILE="$CONF_PATH/$JSON_CONFIG_FILE"
fi

if [[ ! -f $CONFIG_FILE ]]; then
  echo 'No configuration file found.' 
  exit 1
fi

# # Set default config file if not passed through command line
# if [ -z "$JSON_CONFIG_FILE" ]; then
#   JSON_CONFIG_FILE="${CONF_PATH}/conf.json"
# else
#   CONF_PATH=$(dirname $JSON_CONFIG_FILE)
# fi

# Проходим по каждому серверу в JSON
jq -c '.[] | .server' "$CONFIG_FILE" | while read -r server; do
  if [[ $(echo "$server" | jq -r '.enabled') == "true" ]]; then
    SERVER_NAME=$(echo "$server" | jq -r '.name')
    PRIVATE_KEY=$(echo "$server" | jq -r '.privateKey')
    ADDRESS=$(echo "$server" | jq -r '.address')
    PORT=$(echo "$server" | jq -r '.port')

    SRV_FILE="${CONF_PATH}/${SERVER_NAME}.json"

    # Создаем конфигурационный файл сервера
    echo "Создаю конфигурацию для сервера $SERVER_NAME..."

    # Создаем конфигурацию в зависимости от режима
    if [[ "$WG_MODE" == "wireguard" ]]; then
        # Обычный WireGuard без Amnezia-параметров
        cat <<EOF > "${CONF_PATH}/${SERVER_NAME}.conf"
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $ADDRESS/24
ListenPort = $PORT
PreUp =
PostUp =  iptables -t nat -A POSTROUTING -s $(echo $ADDRESS| tail -n 1 |cut -d'.' -f -3).0/24 -o eth0 -j MASQUERADE; iptables -A INPUT -p udp -m udp --dport $PORT -j ACCEPT; iptables -A FORWARD -i $SERVER_NAME -j ACCEPT; iptables -A FORWARD -o $SERVER_NAME -j ACCEPT;
PreDown =
PostDown =  iptables -t nat -D POSTROUTING -s $(echo $ADDRESS| tail -n 1 |cut -d'.' -f -3).0/24 -o eth0 -j MASQUERADE; iptables -D INPUT -p udp -m udp --dport $PORT -j ACCEPT; iptables -D FORWARD -i $SERVER_NAME -j ACCEPT; iptables -D FORWARD -o $SERVER_NAME -j ACCEPT;

EOF
    else
        # AmneziaWG с дополнительными параметрами
        JUNK_COUNT=$(echo "$server" | jq -r '.junkPacketCount // 4')
        JUNK_MIN=$(echo "$server" | jq -r '.junkPacketMinSize // 50')
        JUNK_MAX=$(echo "$server" | jq -r '.junkPacketMaxSize // 1000')
        INIT_JUNK=$(echo "$server" | jq -r '.initPacketJunkSize // 200')
        RESP_JUNK=$(echo "$server" | jq -r '.responsePacketJunkSize // 200')
        INIT_MAGIC=$(echo "$server" | jq -r '.initPacketMagicHeader // 1234567890')
        RESP_MAGIC=$(echo "$server" | jq -r '.responsePacketMagicHeader // 987654321')
        MTU=$(echo "$server" | jq -r '.mtu // 1280')

        cat <<EOF > "${CONF_PATH}/${SERVER_NAME}.conf"
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $ADDRESS/24
ListenPort = $PORT
MTU = $MTU
Jc = $JUNK_COUNT
Jmin = $JUNK_MIN
Jmax = $JUNK_MAX
S1 = $INIT_JUNK
S2 = $RESP_JUNK
H1 = $INIT_MAGIC
H2 = $RESP_MAGIC
PreUp =
PostUp =  iptables -t nat -A POSTROUTING -s $(echo $ADDRESS| tail -n 1 |cut -d'.' -f -3).0/24 -o eth0 -j MASQUERADE; iptables -A INPUT -p udp -m udp --dport $PORT -j ACCEPT; iptables -A FORWARD -i $SERVER_NAME -j ACCEPT; iptables -A FORWARD -o $SERVER_NAME -j ACCEPT;
PreDown =
PostDown =  iptables -t nat -D POSTROUTING -s $(echo $ADDRESS| tail -n 1 |cut -d'.' -f -3).0/24 -o eth0 -j MASQUERADE; iptables -D INPUT -p udp -m udp --dport $PORT -j ACCEPT; iptables -D FORWARD -i $SERVER_NAME -j ACCEPT; iptables -D FORWARD -o $SERVER_NAME -j ACCEPT;

EOF
    fi

    # Обрабатываем клиентов
    echo "Добавляю клиентов для $SERVER_NAME..."
    echo "$server" | jq -c '.clients | to_entries[]' | while read -r client; do
      if [[ $(echo "$client" | jq -r '.value.enabled') == "true" ]]; then
        CLIENT_NAME=$(echo "$client" | jq -r '.value.name')
        CLIENT_ADDRESS=$(echo "$client" | jq -r '.value.address')
        CLIENT_PUBLIC_KEY=$(echo "$client" | jq -r '.value.publicKey')
        CLIENT_PRE_SHARED_KEY=$(echo "$client" | jq -r '.value.presharedKey')

        cat <<EOF >> "${CONF_PATH}/${SERVER_NAME}.conf"
## Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRE_SHARED_KEY
AllowedIPs = $CLIENT_ADDRESS/32

EOF
    fi
      echo "Добавлен клиент: $CLIENT_NAME ($CLIENT_ADDRESS)"
    done
  fi
  echo "Конфигурация $SERVER_NAME.conf создана."
done

echo "Все конфигурационные файлы успешно созданы!"
