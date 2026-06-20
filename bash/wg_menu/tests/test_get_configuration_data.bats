#!/usr/bin/env bats
##

## Prepare for test 
setup() {
    ## Declare variables 
    export TMPDIR="/tmp"
    export TMPJSON="$TMPDIR/tmp.json"
    export TMPCONF="$TMPDIR/test_conf.json"
    export JSON_CONFIG_FILE="$TMPDIR/test_conf2.json"
    export CONFIG_FILE="$JSON_CONFIG_FILE"
    
    ## Creating a test config
    cat > "$TMPCONF" << 'EOF'
[
    {
    "server": {
      "name": "wg0",
      "privateKey": "test_private_key",
      "publicKey": "test_public_key",
      "address": "10.8.0.1",
      "port": "51820",
      "publicIP": "104.18.26.120",
      "publicHostname": "example.com",
      "publicHostnames": [
        "example.com",
        "test1-example.com",
        "test2-example.com",
        "104.18.26.120"
      ],
      "AllowedIPs": "0.0.0.0/0, ::/0",
      "DNS": "8.8.8.8",
      "junkPacketCount": 9,
      "junkPacketMinSize": 27,
      "junkPacketMaxSize": 720,
      "initPacketJunkSize": 20,
      "responsePacketJunkSize": 81,
      "initPacketMagicHeader": 125,
      "responsePacketMagicHeader": 147,
      "mtu": 1142,
      "enabled": true,
      "clients": {
        "UUID_1_SRV_WG0": {
          "name": "test-user-1",
          "address": "10.8.0.2",
          "privateKey": "test-user-1_privateKey",
          "publicKey": "test-user-1_publicKey",
          "presharedKey": "test-user-1_presharedKey",
          "createdAt": "created",
          "updatedAt": "updated",
          "enabled": true
        },
        "UUID_2_SRV_WG0": {
          "name": "test-user-2",
          "address": "10.8.0.3",
          "privateKey": "test-user-2_privateKey",
          "publicKey": "test-user-2_publicKey",
          "presharedKey": "test-user-2_presharedKey",
          "createdAt": "created",
          "updatedAt": "updated",
          "enabled": true
        },
        "UUID_4_SRV_WG0": {
          "name": "test-user-4",
          "address": "10.8.0.5",
          "privateKey": "test-user-4_privateKey",
          "publicKey": "test-user-4_publicKey",
          "presharedKey": "test-user-4_presharedKey",
          "createdAt": "created",
          "updatedAt": "updated",
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
      "publicIP": "104.18.26.120",
      "publicHostname": "example.com",
      "publicHostnames": [
        "example.com"
      ],
      "enabled": false,
      "clients": {
        "UUID_1_SRV_WG1": {
          "name": "test-user-5",
          "address": "10.9.0.2",
          "privateKey": "test-user-5_privateKey",
          "publicKey": "test-user-5_publicKey",
          "presharedKey": "test-user-5_presharedKey",
          "createdAt": "created",
          "updatedAt": "updated",
          "enabled": true
        }
      }
    }
  }
]
EOF
cp $TMPCONF $CONFIG_FILE
    ## include library
    source "../lib/awg-functions.lib.sh"
}

@test "Internal test: Verify that the configuration file is correct." {
    run jq . $CONFIG_FILE
    [ "$status" -eq 0 ]
}

@test "Function: 'get_srv_json_data_by_uuid'; test: No UUID sent" {
    run get_srv_json_data_by_uuid
    [ "$status" -eq 1 ]
}

@test "Function: 'get_srv_json_data_by_uuid'; test: Empty UUID" {
    run get_srv_json_data_by_uuid '' 
    [ "$status" -eq 1 ]
}

@test "Function: 'get_srv_json_data_by_uuid'; test: UUID's" {
    run get_srv_json_data_by_uuid "UUID_1_SRV_WG0"
    [[ "$output" != *"wg1"* ]]
    [[ "$output" == *"wg0"* ]]
    run get_srv_json_data_by_uuid "UUID_2_SRV_WG0"
    [[ "$output" != *"wg1"* ]]
    [[ "$output" == *"wg0"* ]]
    run get_srv_json_data_by_uuid "UUID_1_SRV_WG1"
    [[ "$output" != *"wg0"* ]]
    [[ "$output" == *"wg1"* ]]
}

@test "Function: 'get_srv_json_data_by_uuid'; test: UUID's does not exist" {
    run get_srv_json_data_by_uuid "UUID_3_SRV_WG3"
    [[ "$output" != *"wg1"* ]]
    [[ "$output" != *"wg0"* ]]
    [ "$status" -eq 1 ]
}
## no input provided test section
@test "Functions: 'get_srv_*'; test no input provided" {
    run get_srv_dns
        [ "$status" -eq 1 ]
    run get_srv_allowed_ips
        [ "$status" -eq 1 ]
    run get_srv_port
        [ "$status" -eq 1 ]
    run get_srv_hostName
        [ "$status" -eq 1 ]
    run get_srv_hostnames
        [ "$status" -eq 1 ]
    run get_srv_publicIP
        [ "$status" -eq 1 ]
    run get_srv_PubKey
        [ "$status" -eq 1 ]
}

@test "Functions: 'get_srv_awg_*'; test no input provided" {
    run get_srv_awg_junkCount
        [ "$status" -eq 1 ]
    run get_srv_awg_junkMin
        [ "$status" -eq 1 ]
    run get_srv_awg_junkMax
        [ "$status" -eq 1 ]
    run get_srv_awg_initJunk
        [ "$status" -eq 1 ]
    run get_srv_awg_respJunk
        [ "$status" -eq 1 ]
    run get_srv_awg_initMagic
        [ "$status" -eq 1 ]
    run get_srv_awg_respMagic
        [ "$status" -eq 1 ]
    run get_srv_awg_mtu
        [ "$status" -eq 1 ]
}

@test "Functions: 'get_user_*'; test no input provided" {
    run get_user_ip
        [ "$status" -eq 1 ]
    run get_user_PreSharedKey
        [ "$status" -eq 1 ]
    run get_user_PrivateKey
        [ "$status" -eq 1 ]
    run get_user_Name
        [ "$status" -eq 1 ]
}
## pipe test section
@test "Functions: 'get_srv_*'; test pipe input" {
    srvJSONData="$(get_srv_json_data_by_uuid 'UUID_1_SRV_WG0' )"
    
    run get_srv_dns <<< "$srvJSONData"
        [[ "$output" == "8.8.8.8" ]]
    run get_srv_allowed_ips <<< "$srvJSONData"
        [[ "$output" == "0.0.0.0/0, ::/0" ]]
    run get_srv_port <<< "$srvJSONData"
        [[ "$output" == "51820" ]]
    run get_srv_hostName <<< "$srvJSONData"
        [[ "$output" == "example.com" ]]
    run get_srv_hostnames <<< "$srvJSONData"
        [[ "$output" == *"test2-example.com"* ]]
    run get_srv_publicIP <<< "$srvJSONData"
        [[ "$output" == "104.18.26.120" ]]
    run get_srv_PubKey <<< "$srvJSONData"
        [[ "$output" == "test_public_key" ]]
}

@test "Functions: 'get_srv_awg_*';  test pipe input" {
    srvJSONData="$(get_srv_json_data_by_uuid 'UUID_1_SRV_WG0')"
    run  get_srv_awg_junkCount <<< "$srvJSONData"
        [[ "$output" == "9" ]]
    run  get_srv_awg_junkMin <<< "$srvJSONData"
        [[ "$output" == "27" ]]
    run  get_srv_awg_junkMax <<< "$srvJSONData"
        [[ "$output" == "720" ]]
    run  get_srv_awg_initJunk <<< "$srvJSONData"
        [[ "$output" == "20" ]]
    run  get_srv_awg_respJunk <<< "$srvJSONData"
        [[ "$output" == "81" ]]
    run  get_srv_awg_initMagic <<< "$srvJSONData"
        [[ "$output" == "125" ]]
    run  get_srv_awg_respMagic <<< "$srvJSONData"
        [[ "$output" == "147" ]]
    run  get_srv_awg_mtu <<< "$srvJSONData"
        [[ "$output" == "1142" ]]
}

@test "Functions: 'get_user_*'; test pipe input" {
    usrJSONData="$(get_usr_json_data_by_uuid 'UUID_1_SRV_WG0')"
    # echo "usrJSONData = '$usrJSONData'"
        [[ "${#usrJSONData}" -gt "10" ]]
    run get_user_ip <<< "$usrJSONData"
        [[ "$output" == "10.8.0.2" ]]
    run get_user_PreSharedKey <<< "$usrJSONData"
        [[ "$output" == "test-user-1_presharedKey" ]]
    run get_user_PrivateKey <<< "$usrJSONData"
        [[ "$output" == "test-user-1_privateKey" ]]
    run get_user_Name <<< "$usrJSONData"
        [[ "$output" == "test-user-1" ]]
}

## argument test section
@test "Functions: 'get_srv_*'; test argument input" {
    srvJSONData="$(get_srv_json_data_by_uuid 'UUID_1_SRV_WG1' )"
    
    run get_srv_dns  "$srvJSONData"
        [[ "$output" == "1.1.1.1" ]]
    run get_srv_allowed_ips  "$srvJSONData"
        [[ "$output" == "0.0.0.0/0, ::/0" ]]
    run get_srv_port  "$srvJSONData"
        [[ "$output" == "51821" ]]
    run get_srv_hostName  "$srvJSONData"
        [[ "$output" == "example.com" ]]
    run get_srv_hostnames  "$srvJSONData"
        [[ "$output" == *"example.com"* ]]
    run get_srv_publicIP  "$srvJSONData"
        [[ "$output" == "104.18.26.120" ]]
    run get_srv_PubKey  "$srvJSONData"
        [[ "$output" == "test_public_key2" ]]
}

@test "Functions: 'get_srv_awg_*';  test argument input" {
    srvJSONData="$(get_srv_json_data_by_uuid 'UUID_2_SRV_WG0')"
    run  get_srv_awg_junkCount  "$srvJSONData"
        [[ "$output" == "9" ]]
    run  get_srv_awg_junkMin  "$srvJSONData"
        [[ "$output" == "27" ]]
    run  get_srv_awg_junkMax  "$srvJSONData"
        [[ "$output" == "720" ]]
    run  get_srv_awg_initJunk  "$srvJSONData"
        [[ "$output" == "20" ]]
    run  get_srv_awg_respJunk  "$srvJSONData"
        [[ "$output" == "81" ]]
    run  get_srv_awg_initMagic  "$srvJSONData"
        [[ "$output" == "125" ]]
    run  get_srv_awg_respMagic  "$srvJSONData"
        [[ "$output" == "147" ]]
    run  get_srv_awg_mtu  "$srvJSONData"
        [[ "$output" == "1142" ]]
}

@test "Functions: 'get_user_*'; test argument input" {
    usrJSONData="$(get_usr_json_data_by_uuid 'UUID_4_SRV_WG0')"
    # echo "usrJSONData = '$usrJSONData'"
        [[ "${#usrJSONData}" -gt "10" ]]
    run get_user_ip  "$usrJSONData"
        [[ "$output" == "10.8.0.5" ]]
    run get_user_PreSharedKey  "$usrJSONData"
        [[ "$output" == "test-user-4_presharedKey" ]]
    run get_user_PrivateKey  "$usrJSONData"
        [[ "$output" == "test-user-4_privateKey" ]]
    run get_user_Name  "$usrJSONData"
        [[ "$output" == "test-user-4" ]]
}

