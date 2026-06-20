# Режим работы: wireguard или amneziawg
WG_MODE=${WG_MODE:-"amneziawg"}
JSON_CONFIG_FILE=${JSON_CONFIG_FILE:-"wg_config.json"}

TMPDIR='/tmp'
TMPJSON="$TMPDIR/tmp.json"
TMPCONF="$TMPDIR/$(basename $JSON_CONFIG_FILE)"

if [[ "$WG_MODE" == "wireguard" ]]; then
    SRVCMD=${SRVCMD:-"wg-quick"}
    WGCMD=${WGCMD:-"wg"}
    CONF_PATH=${CONF_PATH:-"/etc/wireguard/"}
else
    SRVCMD=${SRVCMD:-"awg-quick"}
    WGCMD=${WGCMD:-"awg"}
    CONF_PATH=${CONF_PATH:-"/etc/amnezia/amneziawg"}
fi
