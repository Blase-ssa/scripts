#!/usr/bin/env bash
##############################################################
## the script run Amnezia Wireguard server and health check ##
##############################################################
# set -x
[[ -f 'env.sh' ]] && source env.sh
[[ -f './lib/awg-functions.lib.sh' ]] && source ./lib/awg-functions.lib.sh || source awg-functions.lib.sh

# CONF_PATH=$(dirname $JSON_CONFIG_FILE)

## 1 - check tun
echo "${WGCMD}: Starting, stage 1.1 - check '/dev/net/tun' and create if not exist"
test -d /dev/net || mkdir -p /dev/net
test -e /dev/net/tun || mknod /dev/net/tun c 10 200
chmod 666 /dev/net/tun

echo "${WGCMD}: Starting, stage 1.2 - mount tmpfs for TUI"
mount -t tmpfs -o size=4M tmpfs /tmp

## 2 - check if server ready to run, if not then wait to make sure container will be alive
echo "${WGCMD}: Starting, stage 2 - check if server ready to run, if not then wait to make sure container will be alive" 
echo -e "${WGCMD}: If you are running this container for the first time, you need to run the configurator. To do this, use the command:\n docker exec -ti $(hostname) $(pwd)/awg-tui.sh"
while true; do
  [ -f "$CONF_PATH/$JSON_CONFIG_FILE" ] && break || sleep 5
done

## 3 - run the configuration
## 3.1 - apply JSON configuration file, to create interface configurations
echo "${WGCMD}: Starting, stage 3.1 - apply JSON configuration file, to create interface configurations" 
bash awg-gen-configfiles.sh

## 3.2 - get servers from JSON
echo "${WGCMD}: Starting, stage 3.2 - get servers from JSON configuration file to start the servers" 
servers=$(get_servers_list "$CONF_PATH/$JSON_CONFIG_FILE")

# 3.3 - check configuration files existence and run the servers
echo "${WGCMD}: Starting, stage 3.3 - check configuration files existence and run the servers (mode: $WG_MODE)" 
for server in $servers; do
  if [ -f "${CONF_PATH}/${server}.conf" ]; then
    echo "Starting server: $server"
    if [[ "$WG_MODE" == "wireguard" ]]; then
      echo "Using standard WireGuard: wg-quick up $server"
      wg-quick up "$server"
    else
      echo "Using AmneziaWG: amneziawg-go $server"
      awg-quick up "$server"
    fi
  else
    echo "Warning: Configuration file \"${CONF_PATH}/${server}.conf\" does not exist."
  fi
done

## 4.1 - run exporter if necessary
if [[ "$ENABLE_AWG_PROMETHEUS_METRICS" == "true" ]]; then
  python3 /opt/scripts/exporter.py &
fi
## 4.2 - copy files for external exporter
# if [[ "$ENABLE_PROMETHEUS_METRICS_CON" == "true" ]]; then
#   cp /usr/bin/wg /opt/scripts/bin/
# fi


## 5 - healthcheck
echo "${WGCMD}: Starting, stage 4 -  check tun" 
while true; do
  #/usr/bin/timeout 5s /bin/sh -c "/usr/bin/$WGCMD show | /bin/grep -q interface || exit 1"
  /usr/bin/$WGCMD show | /bin/grep -q interface || exit 1
  sleep 30
done

## exit to prevent execution of my notes
echo "${WGCMD}: Script should not go here, something went wrong!" 
exit 1
