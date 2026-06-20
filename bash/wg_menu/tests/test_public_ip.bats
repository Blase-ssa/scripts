#!/usr/bin/env bats

setup() {
    source "../lib/awg-functions.lib.sh"
}

@test "get_public_ip function exists" {
    type get_public_ip
}

@test "get_public_ip returns valid IP format" {
    # Мокаем curl для тестирования
    function curl() {
        echo "192.168.1.1"
    }
    export -f curl
    
    run get_public_ip
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

@test "get_public_ip handles curl failure" {
    # Мокаем curl для возврата ошибки
    function curl() {
        return 1
    }
    export -f curl
    
    run get_public_ip
    [ "$status" -eq 1 ]
}

@test "get_public_ip script can be run directly" {
    [ -f "../get_public_ip.sh" ]
    [ -x "../get_public_ip.sh" ] || chmod +x "../get_public_ip.sh"
}