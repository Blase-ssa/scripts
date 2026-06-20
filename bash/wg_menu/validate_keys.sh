#!/usr/bin/env bash

[[ -f 'env.sh' ]] && source env.sh
source awg-function.lib.sh

# Функция проверки соответствия ключей
validate_keys() {
    local config_file="$1"
    echo "=== Проверка соответствия ключей ==="
    
    jq -c '.[] | .server' "$config_file" | while read -r server; do
        SERVER_NAME=$(echo "$server" | jq -r '.name')
        PRIVATE_KEY=$(echo "$server" | jq -r '.privateKey')
        PUBLIC_KEY=$(echo "$server" | jq -r '.publicKey')
        
        # Генерируем публичный ключ из приватного
        GENERATED_PUBLIC=$(echo "$PRIVATE_KEY" | $WGCMD pubkey)
        
        echo "Сервер: $SERVER_NAME"
        echo "  Приватный ключ: $PRIVATE_KEY"
        echo "  Публичный ключ в конфиге: $PUBLIC_KEY"
        echo "  Сгенерированный публичный: $GENERATED_PUBLIC"
        
        if [[ "$PUBLIC_KEY" == "$GENERATED_PUBLIC" ]]; then
            echo "  ✓ Ключи сервера соответствуют"
        else
            echo "  ✗ ОШИБКА: Ключи сервера НЕ соответствуют!"
        fi
        echo
        
        # Проверяем клиентов
        echo "$server" | jq -c '.clients | to_entries[]' | while read -r client; do
            CLIENT_NAME=$(echo "$client" | jq -r '.value.name')
            CLIENT_PRIVATE=$(echo "$client" | jq -r '.value.privateKey')
            CLIENT_PUBLIC=$(echo "$client" | jq -r '.value.publicKey')
            
            CLIENT_GENERATED_PUBLIC=$(echo "$CLIENT_PRIVATE" | $WGCMD pubkey)
            
            echo "  Клиент: $CLIENT_NAME"
            echo "    Приватный ключ: $CLIENT_PRIVATE"
            echo "    Публичный ключ в конфиге: $CLIENT_PUBLIC"
            echo "    Сгенерированный публичный: $CLIENT_GENERATED_PUBLIC"
            
            if [[ "$CLIENT_PUBLIC" == "$CLIENT_GENERATED_PUBLIC" ]]; then
                echo "    ✓ Ключи клиента соответствуют"
            else
                echo "    ✗ ОШИБКА: Ключи клиента НЕ соответствуют!"
            fi
            echo
        done
    done
}

# Тест генерации QR-кода
test_qr_generation() {
    local uuid="$1"
    local config_file="$2"
    
    echo "=== Тест генерации QR-кода для UUID: $uuid ==="
    
    # Получаем данные пользователя и сервера
    JSON_USER=$(jq -r ".[].server.clients[\"$uuid\"] | select(. != null)" "$config_file")
    JSON_SRV=$(jq --arg uuid "$uuid" '[ .[] | select(.server.clients[$uuid]) | { server: { name: .server.name, address: .server.address, port: .server.port, publicKey: .server.publicKey, publicIP: .server.publicIP, publicHostname: .server.publicHostname, AllowedIPs: .server.AllowedIPs, DNS: .server.DNS, junkPacketCount: .server.junkPacketCount, junkPacketMinSize: .server.junkPacketMinSize, junkPacketMaxSize: .server.junkPacketMaxSize, initPacketJunkSize: .server.initPacketJunkSize, responsePacketJunkSize: .server.responsePacketJunkSize, initPacketMagicHeader: .server.initPacketMagicHeader, responsePacketMagicHeader: .server.responsePacketMagicHeader, mtu: .server.mtu } } ]' "$config_file")
    
    if [[ -z "$JSON_USER" || "$JSON_USER" == "null" ]]; then
        echo "ОШИБКА: Пользователь с UUID $uuid не найден"
        return 1
    fi
    
    if [[ -z "$JSON_SRV" || "$JSON_SRV" == "[]" ]]; then
        echo "ОШИБКА: Сервер для пользователя с UUID $uuid не найден"
        return 1
    fi
    
    echo "Данные пользователя:"
    echo "$JSON_USER" | jq .
    echo
    echo "Данные сервера:"
    echo "$JSON_SRV" | jq .
    echo
    
    # Проверяем все необходимые поля
    usrName=$(echo "$JSON_USER" | jq -r .name)
    usrPrivateKey=$(echo "$JSON_USER" | jq -r .privateKey)
    srvPubKey=$(echo "$JSON_SRV" | jq -r .[].server.publicKey)
    
    echo "Проверка ключей в QR-коде:"
    echo "  Имя пользователя: $usrName"
    echo "  Приватный ключ клиента: $usrPrivateKey"
    echo "  Публичный ключ сервера: $srvPubKey"
    
    # Генерируем публичный ключ клиента для проверки
    if [[ -n "$usrPrivateKey" && "$usrPrivateKey" != "null" ]]; then
        usrGeneratedPublic=$(echo "$usrPrivateKey" | $WGCMD pubkey)
        echo "  Сгенерированный публичный ключ клиента: $usrGeneratedPublic"
    fi
}

# Основная функция
main() {
    local config_file="${1:-$CONF_PATH/$JSON_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        echo "ОШИБКА: Файл конфигурации не найден: $config_file"
        exit 1
    fi
    
    echo "Проверка файла: $config_file"
    echo
    
    # Проверяем соответствие ключей
    validate_keys "$config_file"
    
    # Получаем первый UUID для тестирования QR-кода
    first_uuid=$(jq -r '.[].server.clients | keys[0]' "$config_file")
    if [[ -n "$first_uuid" && "$first_uuid" != "null" ]]; then
        test_qr_generation "$first_uuid" "$config_file"
    else
        echo "Нет клиентов для тестирования QR-кода"
    fi
}

# Запуск
main "$@"