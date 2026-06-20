#!/usr/bin/env bats

@test "env.sh file exists and is readable" {
    [ -f "../env.sh" ]
    [ -r "../env.sh" ]
}

@test "env.sh sets required variables" {
    source ../env.sh
    
    [ -n "$SRVCMD" ]
    [ -n "$WGCMD" ]
    [ -n "$JSON_CONFIG_FILE" ]
    [ -n "$CONF_PATH" ]
    [ -n "$TMPDIR" ]
    [ -n "$TMPJSON" ]
    [ -n "$TMPCONF" ]
    [ -n "$WG_MODE" ]

}

@test "env.sh sets correct default values" {
    source ../env.sh
    
    [ "$SRVCMD" = "awg-quick" ]
    [ "$WGCMD" = "awg" ]
    [ "$JSON_CONFIG_FILE" = "wg_config.json" ]
    [ "$CONF_PATH" = "/etc/amnezia/amneziawg" ]
    [ "$TMPDIR" = "/tmp" ]
    [ "$WG_MODE" = "amneziawg" ]
    
}

@test "env.sh sets wireguard mode" {
    export WG_MODE="wireguard"
    source ../env.sh
    
    [ "$SRVCMD" = "wg-quick" ]
    [ "$WGCMD" = "wg" ]
    [ "$JSON_CONFIG_FILE" = "wg_config.json" ]
    [ "$CONF_PATH" = "/etc/wireguard/" ]

}

