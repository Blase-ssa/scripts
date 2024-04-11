#!/usr/bin/env bash
# This script was created to publish data for Prometheus.
# But it can be used to publish other data.
#
# Require: netcat 
#
set -o allexport

# server port
SRV_PORT=8001
## timeout waiting for connection to nc server in seconds
## Set to 0 to disable timeout and enable "stable algorithm"
SRV_TIMEOUT=60
# http header
SRV_HEADER="HTTP/1.1 200 Everything Is Just Fine
Server: Stat Exporter
Content-Type: text/html; charset=UTF-8"

get_fun_speed(){
  local fan_conf=`echo -e "0=0\n$(cat /etc/argononed.conf)"`
  local temp_rate=$(echo "${fan_conf}"|grep -Po '^\d+'|awk "\$0 <= $(( $(get_cpu_temp) / 1000 ))"|tail -n1)
  echo "${fan_conf}"|grep -Po "^${temp_rate}=\K\d+\$"
}

get_cpu_temp(){
  cat /sys/class/thermal/thermal_zone0/temp
}

exporter_date(){
    ## Prometheus exporter template:
    echo "# HELP rpi_thermal_video_core_temp RPI VideoCore human-readable temperature in Celsius
# TYPE rpi_thermal_video_core_temp gauge
rpi_thermal_video_core_temp{type="gpu-thermal",format="human-readable"} $(/bin/vcgencmd measure_temp| grep -Po '\d+\.\d+')

# HELP rpi_cpu_scaling_clock_speed
# TYPE rpi_cpu_scaling_clock_speed gauge
rpi_cpu_scaling_clock_speed $(vcgencmd measure_clock arm |grep -Po '=\K\d+$')

# HELP rpi_cpu_scaling_volts
# TYPE rpi_cpu_scaling_volts gauge
rpi_cpu_scaling_volts $(vcgencmd measure_volts|grep -Po '=\K\d+\.\d+')

# HELP rpi_thermal_rpi_cpu_temp RPI CPU temperature in Celsius * 1000
# TYPE rpi_thermal_rpi_cpu_temp gauge
rpi_thermal_rpi_cpu_temp{type="cpu-thermal"} $(get_cpu_temp)

# HELP rpi_hwmon_fan_output Hardware monitor fan element output
# TYPE rpi_hwmon_fan_output gauge
rpi_hwmon_fan_output{sensor="ArgonFan1"} $(get_fun_speed)
"
}

run_web_srv(){
    ## function open web socket and wait for request
    echo -e "${SRV_HEADER}\n\n${EXPORTER_DATA}\n" | nc -l $SRV_PORT -q 1 -v
}

while true; do 
    ## generate exporter data
    EXPORTER_DATA=$(exporter_date)
    
    ## start the server every ${SRV_TIMEOUT}.
    if [[ $SRV_TIMEOUT == 0 ]]; then
      ## >> Stable algorithm, but to get up-to-date data, you need to request it twice.. <<
      run_web_srv
    else
      ## >> Unstable algorithm, but up-to-date data. <<
      timeout --preserve-status ${SRV_TIMEOUT} bash -c run_web_srv
    fi
done
