#!/usr/bin/env bats

setup() {
    export TMPDIR="/tmp"
    export JSON_CONFIG_FILE="$TMPDIR/test_config.json"
    
    # Создаем тестовый конфиг
    cat > "$JSON_CONFIG_FILE" << 'EOF'
[
  {
    "server": {
      "name": "test_server",
      "publicKey": "server_public_key",
      "port": "51820",
      "publicIP": "1.2.3.4",
      "publicHostname": "test.example.com",
      "DNS": "1.1.1.1",
      "AllowedIPs": "0.0.0.0/0, ::/0",
      "junkPacketCount": 4,
      "junkPacketMinSize": 50,
      "junkPacketMaxSize": 1000,
      "initPacketJunkSize": 200,
      "responsePacketJunkSize": 200,
      "initPacketMagicHeader": 1234567890,
      "responsePacketMagicHeader": 987654321,
      "mtu": 1280,
      "clients": {
        "test-uuid": {
          "name": "TestClient",
          "address": "10.8.0.2",
          "privateKey": "client_private_key",
          "presharedKey": "client_preshared_key"
        }
      }
    }
  }
]
EOF
    
    source "../lib/awg-functions.lib.sh"
}

teardown() {
    rm -f "$JSON_CONFIG_FILE" TestClient*.conf
}

@test "client config generation script exists" {
    [ -f "../gen_client_config.sh" ]
}

@test "get_user_by_uuid returns user data" {
    run get_user_by_uuid "test-uuid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TestClient"* ]]
    [[ "$output" == *"10.8.0.2"* ]]
}

@test "get_srv_by_uuid returns server data" {
    run get_srv_by_uuid "test-uuid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test_server"* ]]
    [[ "$output" == *"51820"* ]]
}

@test "client config generation creates config files" {
    cd ..
    run bash gen_client_config.sh "test-uuid" "$JSON_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Должны быть созданы файлы с hostname и IP
    [ -f "TestClient_hostname.conf" ] || [ -f "TestClient_ip.conf" ] || [ -f "TestClient.conf" ]
}

@test "generated client config contains required sections" {
    cd ..
    bash gen_client_config.sh "test-uuid" "$JSON_CONFIG_FILE"
    
    # Находим созданный файл
    config_file=$(ls TestClient*.conf | head -1)
    [ -n "$config_file" ]
    
    # Проверяем содержимое
    run grep -q "\[Interface\]" "$config_file"
    [ "$status" -eq 0 ]
    
    run grep -q "\[Peer\]" "$config_file"
    [ "$status" -eq 0 ]
    
    run grep -q "PrivateKey = client_private_key" "$config_file"
    [ "$status" -eq 0 ]
}