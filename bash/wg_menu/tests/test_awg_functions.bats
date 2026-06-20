#!/usr/bin/env bats

setup() {
    export TMPDIR="/tmp"
    export TMPJSON="$TMPDIR/tmp.json"
    export TMPCONF="$TMPDIR/test_conf.json"
    export JSON_CONFIG_FILE="$TMPDIR/test_config.json"
    
    # Создаем тестовый конфиг
    cat > "$TMPCONF" << 'EOF'
[
  {
    "server": {
      "name": "wg0",
      "privateKey": "test_private_key",
      "publicKey": "test_public_key",
      "address": "10.8.0.1",
      "port": "51820",
      "enabled": true,
      "clients": {
        "test-uuid-1": {
          "name": "TestUser1",
          "address": "10.8.0.2",
          "enabled": true
        },
        "test-uuid-2": {
          "name": "TestUser2", 
          "address": "10.8.0.3",
          "enabled": true
        }
      }
    }
  },
  {
    "server": {
      "name": "wg1",
      "privateKey": "test_private_key2",
      "publicKey": "test_public_key2",
      "address": "10.9.0.1",
      "port": "51821",
      "enabled": true,
      "clients": {}
    }
  }
]
EOF
    
    source "../lib/awg-functions.lib.sh"
}

teardown() {
    rm -f "$TMPCONF" "$TMPJSON" "$JSON_CONFIG_FILE"
}

@test "get_servers_list returns correct server names" {
    run get_servers_list "$TMPCONF"
    [ "$status" -eq 0 ]
    [[ "$output" == *"wg0"* ]]
    [[ "$output" == *"wg1"* ]]
}

@test "get_server_ip returns correct IP for server" {
    run get_server_ip "wg0" "$TMPCONF"
    [ "$status" -eq 0 ]
    [ "$output" = "10.8.0.1" ]
}

@test "get_clients_ip_list returns client IPs" {
    run get_clients_ip_list "wg0" "$TMPCONF"
    [ "$status" -eq 0 ]
    [[ "$output" == *"10.8.0.2"* ]]
    [[ "$output" == *"10.8.0.3"* ]]
}

@test "get_users_list returns user names" {
    run get_users_list "wg0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TestUser1"* ]]
    [[ "$output" == *"TestUser2"* ]]
}

@test "offer_client_ip suggests next available IP" {
    run offer_client_ip "wg0"
    [ "$status" -eq 0 ]
    [ "$output" = "10.8.0.4" ]
}

@test "offer_client_ip for server without clients uses server IP base" {
    run offer_client_ip "wg1"
    [ "$status" -eq 0 ]
    [ "$output" = "10.9.0.2" ]
}

@test "get_user_uid returns correct UUID" {
    run get_user_uid "wg0" "TestUser1"
    [ "$status" -eq 0 ]
    [ "$output" = "test-uuid-1" ]
}

@test "delete_server removes server from config" {
    cp "$TMPCONF" "$TMPJSON"
    run delete_server "wg1"
    [ "$status" -eq 0 ]
    
    # Проверяем что сервер удален
    run get_servers_list "$TMPCONF"
    [[ "$output" != *"wg1"* ]]
    [[ "$output" == *"wg0"* ]]
}

@test "delete_user removes user from config" {
    cp "$TMPCONF" "$TMPJSON"
    run delete_user "test-uuid-1"
    [ "$status" -eq 0 ]
    
    # Проверяем что пользователь удален
    run get_users_list "wg0"
    [[ "$output" != *"TestUser1"* ]]
    [[ "$output" == *"TestUser2"* ]]
}

@test "functions return error with no arguments" {
    run offer_client_ip
    [ "$status" -eq 1 ]
    
    run get_server_ip
    [ "$status" -eq 1 ]
    
    run get_clients_ip_list
    [ "$status" -eq 1 ]
    
    run get_users_list
    [ "$status" -eq 1 ]
}