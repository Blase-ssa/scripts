#!/usr/bin/env bats

setup() {
    export TMPDIR="/tmp"
    export JSON_CONFIG_FILE="$TMPDIR/test_config.json"
    export CONF_PATH="$TMPDIR"
    
    # Создаем тестовый конфиг
    cat > "$JSON_CONFIG_FILE" << 'EOF'
[
  {
    "server": {
      "name": "test_server",
      "privateKey": "test_private_key",
      "address": "10.8.0.1",
      "port": "51820",
      "junkPacketCount": 4,
      "junkPacketMinSize": 50,
      "junkPacketMaxSize": 1000,
      "initPacketJunkSize": 200,
      "responsePacketJunkSize": 200,
      "initPacketMagicHeader": 1234567890,
      "responsePacketMagicHeader": 987654321,
      "mtu": 1280,
      "enabled": true,
      "clients": {
        "test-uuid": {
          "name": "TestClient",
          "address": "10.8.0.2",
          "publicKey": "test_client_public_key",
          "presharedKey": "test_preshared_key",
          "enabled": true
        }
      }
    }
  }
]
EOF
}

teardown() {
    rm -f "$JSON_CONFIG_FILE" "$CONF_PATH/test_server.conf"
}

@test "config generation script exists and is executable" {
    [ -f "../awg-gen-configfiles.sh" ]
}

@test "config generation creates server config file" {
    cd ..
    run bash awg-gen-configfiles.sh "$JSON_CONFIG_FILE"
    [ "$status" -eq 0 ]
    [ -f "$CONF_PATH/test_server.conf" ]
}

@test "generated config contains required sections" {
    cd ..
    bash awg-gen-configfiles.sh "$JSON_CONFIG_FILE"
    
    # Проверяем наличие секций Interface и Peer
    run grep -q "\[Interface\]" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
    
    run grep -q "\[Peer\]" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
}

@test "generated config contains Amnezia parameters" {
    cd ..
    bash awg-gen-configfiles.sh "$JSON_CONFIG_FILE"
    
    run grep -q "Jc = 4" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
    
    run grep -q "MTU = 1280" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
    
    run grep -q "H1 = 1234567890" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
    
    run grep -q "H2 = 987654321" "$CONF_PATH/test_server.conf"
    [ "$status" -eq 0 ]
}