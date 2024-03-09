# Ports work
## Prehistory
I needed a simple script to check the availability of ports from a container where there is neither nc nor nmap.
And in general, I was satisfied with this code:
```bash
(echo >/dev/tcp/<IP>/<Port>) &>/dev/null && return true || return false
```
But I got a little carried away and wrote these scripts.

## Scripts:
|Filename|Short description|
|---|---|
|port_work.lib|Bash library to store common functions|
|portping.sh|A simple port availability check script|
|portscan.sh|A simple port scanner script|
|portknock.sh|A simple port knocker|

## Help
To get help and better description run:
```bash
bash <script name>.sh -h
```