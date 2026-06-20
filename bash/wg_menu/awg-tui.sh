#!/usr/bin/env bash
# set -x
set -e
[[ -f 'env.sh' ]] && source env.sh
[[ -f './lib/awg-functions.lib.sh' ]] && source ./lib/awg-functions.lib.sh || source awg-functions.lib.sh
set +e

# remove configuration file if thre is one from previous run and create stub
echo '[]' > $TMPCONF
# copy configuration file to temporary dir
[[ -f "$CONF_PATH/$JSON_CONFIG_FILE" ]] && cp -f "$CONF_PATH/$JSON_CONFIG_FILE" $TMPCONF

# Функция для создания нового сервера
create_server_menu() {
  #SERVER_NAME=$(dialog --title "Creating a server" --inputbox "Enter a server name:" 10 60 "wg0" 3>&1 1>&2 2>&3)
  SERVER_NAME=""
  DEFAULT_SERVER_NAME="wg0"
  until [[ "$SERVER_NAME" != '' ]]; do
      SERVER_NAME=$(dialog --title "Creating a server" --inputbox "Enter a server name:" 10 60 "$DEFAULT_SERVER_NAME" 3>&1 1>&2 2>&3)
      EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
      
      if [[ $(jq -r '.[].server.name' "$TMPCONF" | grep -c $SERVER_NAME) -gt 0 ]] ; then
        dialog --title "Error" --msgbox "Имя сервера '$SERVER_NAME' уже занято. Выберите другое." 6 40
        DEFAULT_SERVER_NAME=$SERVER_NAME
        SERVER_NAME=''
      elif [[ ! "$SERVER_NAME" =~ ^[a-zA-Z0-9._]+$ ]]; then
        dialog --title "Error" --msgbox "Имя сервера может содержать только латинские буквы, цифры, точку и символ _" 6 40
        DEFAULT_SERVER_NAME=$SERVER_NAME
        SERVER_NAME=''
      fi
  done

  PRIVATE_KEY=$(dialog --title "Creating a server" --inputbox "Private key:" 10 60 "$($WGCMD genkey)" 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function

  PUBLIC_KEY=$(dialog --title "Creating a server" --inputbox "Public_key:" 10 60 "$(echo $PRIVATE_KEY | $WGCMD pubkey)" 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function

  ADDRESS=''
  DEFAULT_ADDRESS="10.8.0.1"
  until [[ "$ADDRESS" != '' ]]; do
    ADDRESS=$(dialog --title "Creating a server" --inputbox "Enter the internal IP address of the server" 10 60 "10.8.0.1" 3>&1 1>&2 2>&3)
    EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function

    if [[ $(echo "$ADDRESS" | grep -Ec '\d+\.\d+\.\d+\.\d+') -ne 1 ]]; then
      dialog --title "Error" --msgbox "'$ADDRESS' - is not an IP address." 6 40
      DEFAULT_ADDRESS="10.8.0.1"
      ADDRESS=''
    elif [[ $(jq -r '.[].server.address' "$TMPCONF" | grep -c $ADDRESS ) -gt 0 ]] ; then
      dialog --title "Error" --msgbox "'IP address $ADDRESS' already exist." 6 40
      DEFAULT_ADDRESS=$ADDRESS
      ADDRESS=''
    fi
    # this will fix errors escaped from filters above, and remove all symbols before and after the IP address
    ADDRESS=$(echo "$ADDRESS" | grep -Eo '\d+\.\d+\.\d+\.\d+')
  done

  PORT=0
  DEFAULT_PORT=$(gen_rand_in_range 2000 65000)
  until [[ "$PORT" != 0 ]]; do
    PORT=$(dialog --title "Creating a server" --inputbox "Enter WireGuard port \n(2000-65000 - recommended port range):" 10 60 "$DEFAULT_PORT" 3>&1 1>&2 2>&3)
    EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
    if [[ ! "$PORT" =~ ^[0-9]+$ ]] && (( VAR < 1 )); then
      dialog --title "Error" --msgbox "Port should be a number. '$PORT' - is not a number or less then 1." 6 40
      DEFAULT_PORT=51820
      PORT=0
    elif [[ $(jq -r '.[].server.port' "$TMPCONF" | grep -c $PORT) -gt 0 ]] ; then
      dialog --title "Error" --msgbox "Port should number '$PORT' already in use." 6 40
      DEFAULT_PORT=$PORT
      PORT=0
    fi
  done
  # Добавляем дополнительные поля
  PUBLIC_HOSTNAME=$(dialog --title "Creating a server" --inputbox "Public hostname (optional):" 10 60 "" 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  
  DNS=$(dialog --title "Creating a server" --inputbox "DNS server:" 10 60 "1.1.1.1" 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  
  ALLOWED_IPS=$(dialog --title "Creating a server" --inputbox "Allowed IPs for clients:" 10 60 "0.0.0.0/0, ::/0" 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1

  # Генерируем случайные параметры AmneziaWG
  RAND_MTU=$(gen_rand_in_range 576 1500)  # MTU
  RAND_JC=$(gen_rand_in_range 3 10)       # Jc    junkPacketCount           : 3-10
  # S1 should be non equal to S2, but I am not sure :P
  while [ $RAND_S1 -eq $RAND_S2 ]; do
    RAND_S1=$(gen_rand_in_range 15 100)     # S1    initPacketJunkSize        : 15-100
    RAND_S2=$(gen_rand_in_range 15 100)     # S2    responsePacketJunkSize    : 15-100
  done
  # Jmin should be less then Jmax
  while [ $RAND_JMIN -ge $RAND_JMAX ]; do
    RAND_JMIN=$(gen_rand_in_range 15 100)   # Jmin  junkPacketMinSize         : 15-100
    RAND_JMAX=$(gen_rand_in_range 201 1000) # Jmax  junkPacketMaxSize         : 201-1000
  done
  # H1 should be non equal to H2
  while [ $RAND_H1 -eq $RAND_H2 ]; do
    RAND_H1=$(gen_rand_in_range 16 239)   # H1 initPacketMagicHeader     :16-239 (0x10–0xEF)
    RAND_H2=$(gen_rand_in_range 16 239)   # H2 responsePacketMagicHeader :16-239 (0x10–0xEF)
  done
  # Добавление сервера в JSON с полными параметрами
  jq --arg name "$SERVER_NAME" --arg key "$PRIVATE_KEY" --arg pub "$PUBLIC_KEY" --arg addr "$ADDRESS" --arg port "$PORT" \
     --arg hostname "$PUBLIC_HOSTNAME" --arg dns "$DNS" --arg allowed "$ALLOWED_IPS" \
     --argjson jc "$RAND_JC" --argjson jmin "$RAND_JMIN" --argjson jmax "$RAND_JMAX"\
     --argjson s1 "$RAND_S1" --argjson s2 "$RAND_S2" \
     --argjson mtu "$RAND_MTU" --argjson h1 "$RAND_H1" --argjson h2 "$RAND_H2" \
    '. += [{"server": {"name": $name, "privateKey": $key, "publicKey": $pub, "address": $addr, "port": $port, "publicIP": "", "publicHostname": $hostname, "AllowedIPs": $allowed, "DNS": $dns, "junkPacketCount": $jc, "junkPacketMinSize": $jmin, "junkPacketMaxSize": $jmax, "initPacketJunkSize": $s1, "responsePacketJunkSize": $s2, "initPacketMagicHeader": $h1, "responsePacketMagicHeader": $h2, "mtu": $mtu, "enabled": true, "clients": {}}}]' "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
  dialog --msgbox "Server \"$SERVER_NAME\" created!" 6 40
}

# Функция для выбора сервера
manage_servers_menu() {
  while true; do
    CHOICE=$(
      dialog --title "WireGuard Configurator" --menu "Выберите действие:" 15 50 5 \
      "1" "Create Server" \
      "2" "Delete Server" \
      "3" "Disable Server" \
      "4" "Enable Server" \
      "5" "Return" \
      3>&1 1>&2 2>&3
    )
    EXIT_STATUS=$?
    [[ $EXIT_STATUS -ne 0 ]] && return 0
    case "$CHOICE" in 
      1)
        create_server_menu 
        ;;
      2)
        delete_server_menu
        ;;
      3)
        disable_server_menu
        ;;
      4)
        enable_server_menu
        ;;
      5)
        return 0 
        ;;
    esac
  done
}

select_server() { 
	SERVERS=($(get_servers_list))
	SERVER=$(dialog --title "Выберите сервер" --menu "Выберите сервер для управления:" 15 50 5 $( i=1; for srv in ${SERVERS[@]}; do echo "$i $srv"; i=$((i+1)); done ) 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  echo "${SERVERS[$(($SERVER - 1))]}"
  return 0
}

# Функция для добавления пользователя к серверу
add_user_menu() { 
  SERVER=$(select_server)
  CLIENT_NAME=$(dialog --title "Добавление пользователя" --inputbox "Введите имя клиента:" 10 60 3>&1 1>&2 2>&3) 
  CLIENT_ADDRESS=$(dialog --title "Добавление пользователя" --inputbox "Введите IP клиента:" 10 60 $(offer_client_ip "$SERVER") 3>&1 1>&2 2>&3) 
  # CLIENT_ADDRESS=$(offer_client_ip $SERVER)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  
  CLIENT_PRIVATE_KEY=$(dialog --title "Добавление пользователя" --inputbox "Введите приватный ключ клиента:" 10 60 "$($WGCMD genkey)" 3>&1 1>&2 2>&3)
  CLIENT_PUBLIC_KEY=$(dialog --title "Добавление пользователя" --inputbox "Введите публичный ключ клиента:" 10 60 "$(echo "$CLIENT_PRIVATE_KEY" | $WGCMD pubkey)" 3>&1 1>&2 2>&3)
  CLIENT_PRESHARED_KEY=$(dialog --title "Добавление пользователя" --inputbox "Введите PRESHARED KEY клиента:" 10 60 "$($WGCMD genpsk)" 3>&1 1>&2 2>&3)

  jq \
    --arg server "$SERVER" \
    --arg id "$(echo "$CLIENT_NAME" | cut -c1)$(date -I)-$(date +%s)" \
    --arg name "$CLIENT_NAME" \
    --arg addr "$CLIENT_ADDRESS" \
    --arg priv "$CLIENT_PRIVATE_KEY" \
    --arg pub "$CLIENT_PUBLIC_KEY" \
    --arg shared "$CLIENT_PRESHARED_KEY" \
    --arg created "$(date -u +'%Y-%m-%d_T%H:%M:%S')" \
    --arg updated "$(date -u +'%Y-%m-%d_T%H:%M:%S')" \
    'map(if .server.name == $server then .server.clients[$id] = {"name": $name, "address": $addr, "privateKey": $priv, "publicKey": $pub, "presharedKey": $shared, "createdAt": "$created", "updatedAt": "$updated", "enabled": true } else . end)' "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
    EXIT_STATUS=$?; [[ $EXIT_STATUS -eq 0 ]] && dialog --msgbox "Клиент $CLIENT_NAME добавлен к серверу $SERVER!" 6 40 || dialog --msgbox "ERROR: Клиент $CLIENT_NAME не был добавлен к серверу $SERVER!" 15 50
    return 0
}
# Функция для удаления сервера


delete_server_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  dialog --yesno "Are you sure you want to delete server \"$SERVER\"?" 6 40
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  delete_server $SERVER
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 || dialog --msgbox "Сервер $SERVER удален!" 6 40
  return 0
}

delete_user_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  MSG="Select user to be deleted from the server \"$SERVER\""
  [[ $# > 1 ]] && USER=$2 || USER=$(select_user_menu $SERVER "$MSG")
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  UUID=$(get_user_uid $SERVER $USER)
  dialog --yesno "Are you sure you want to delete user \"$USER\" from the server \"$SERVER\"? $(echo -e "\nUser Info:\n\tName:\t \"$USER\"\n\tUID:\t \"$UUID\"")" 15 60
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  

  delete_user $UUID
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 || dialog --msgbox "User \"$USER\" from the server \"$SERVER\"!" 6 40
  return 0
}

select_user_menu(){
  SERVER=$1
  MSG=$2
  USERS=($(get_users_list $SERVER))
  USER=$(dialog --title "Select User" --menu "$MSG:" 15 50 5 $( i=1; for usr in ${USERS[@]}; do echo "$i $usr"; i=$((i+1)); done ) 3>&1 1>&2 2>&3)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  echo "${USERS[$(($USER - 1))]}"
  return 0
}

disable_server_menu() {
  ## TBD WIP
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  dialog --yesno "Are you sure you want to delete server \"$SERVER\"?" 6 40
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 # Cancel is pressed, exit function
  disable_server $SERVER
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1 || dialog --msgbox "Сервер $SERVER удален!" 6 40
  return 0
}

disable_server() {
	[[ $# < 1 ]] && return 1 || SERVER=$1
	jq "map(if .server.name == \"$SERVER\" then .server.enabled = false else . end)" "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
	return $?
}

enable_server() {
	[[ $# < 1 ]] && return 1 || SERVER=$1
	jq "map(if .server.name == \"$SERVER\" then .server.enabled = true else . end)" "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
	return $?
}

generate_config_file_menu() {
	## TBD
  cp -f $TMPCONF "$CONF_PATH/$JSON_CONFIG_FILE"
  log=$(bash awg-gen-configfiles.sh)
  dialog --msgbox "$log" 10 60
	return 0
}

manage_users_menu() {
  while true; do
    CHOICE=$(
      dialog --title "WireGuard Configurator" --menu "Выберите действие:" 15 50 5 \
      "1" "Create User" \
      "2" "Delete User" \
      "3" "Disable User" \
      "4" "Enable User" \
      "5" "Generate QR Code" \
      "6" "Generate Config Files" \
      "7" "Return" \
      3>&1 1>&2 2>&3
    )
    EXIT_STATUS=$?
    [[ $EXIT_STATUS -ne 0 ]] && return 0
    case "$CHOICE" in 
      1)
        add_user_menu 
        ;;
      2)
        delete_user_menu
        ;;
      3)
        disable_user_menu
        ;;
      4)
        enable_user_menu
        ;;
      5)
        generate_qr_menu
        ;;
      6)
        generate_config_menu
        ;;
      7)
        return 0 
        ;;
    esac
  done

}

disable_user_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  MSG="Select user to disable from server \"$SERVER\""
  [[ $# > 1 ]] && USER=$2 || USER=$(select_user_menu $SERVER "$MSG")
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  UUID=$(get_user_uid $SERVER $USER)
  jq ".[].server.clients[\"$UUID\"].enabled = false" "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
  dialog --msgbox "User \"$USER\" disabled!" 6 40
}

enable_user_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  MSG="Select user to enable from server \"$SERVER\""
  [[ $# > 1 ]] && USER=$2 || USER=$(select_user_menu $SERVER "$MSG")
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  UUID=$(get_user_uid $SERVER $USER)
  jq ".[].server.clients[\"$UUID\"].enabled = true" "$TMPCONF" > $TMPJSON && mv $TMPJSON "$TMPCONF"
  dialog --msgbox "User \"$USER\" enabled!" 6 40
}

generate_qr_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  MSG="Select user to generate QR code for server \"$SERVER\""
  [[ $# > 1 ]] && USER=$2 || USER=$(select_user_menu $SERVER "$MSG")
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  UUID=$(get_user_uid $SERVER $USER)
  bash gen_client_qr.sh "$UUID" "$TMPCONF"
  return 0
}

generate_config_menu() {
  [[ $# > 0 ]] && SERVER=$1 || SERVER=$(select_server)
  MSG="Select user to generate config files for server \"$SERVER\""
  [[ $# > 1 ]] && USER=$2 || USER=$(select_user_menu $SERVER "$MSG")
  EXIT_STATUS=$?; [[ $EXIT_STATUS -ne 0 ]] && return 1
  UUID=$(get_user_uid $SERVER $USER)
  bash gen_client_config.sh "$UUID" "$TMPCONF"
  dialog --msgbox "Config files generated for user \"$USER\"!" 6 40
  return 0
}

main_menu(){
  while true; do
    CHOICE=$(
      dialog --title "WireGuard Configurator" --menu "Выберите действие:" 15 50 5 \
      "1" "Create Server" \
      "2" "Add users" \
      "3" "Manage Servers" \
      "4" "Manage Users" \
      "5" "Apply all changes" \
      "6" "Exit" \
      3>&1 1>&2 2>&3
    )
    EXIT_STATUS=$?
    [[ $EXIT_STATUS -ne 0 ]] && exit 0
    case "$CHOICE" in 
      1) 
        create_server_menu 
        ;; 
      2) 
        add_user_menu
        ;; 
      3) 
        manage_servers_menu
        ;; 
      4) 
        manage_users_menu
        ;; 
      5)
        generate_config_file_menu
        ;; 
      6)
        break 
        ;; 
    esac
  done
}

# Main
main_menu
# clear
echo "Выход из программы."
