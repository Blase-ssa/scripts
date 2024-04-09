# netcat socket server
This directory contains several simple "TCP-socket" servers.
Why "TCP-socket" and not a web server? Because netcat allows to listen to a TCP socket and send a response there, and it doesn’t matter HTTP or anything else.

# Scripts
## nc_catch_srv.sh
The simplest web server. I created it in order to debug sending requests from my script to the server without involving the real server in interaction.

## nc_stat_srv.sh
Script for publishing non-secret data in json format. Correct the template to substitute the correct data. The script also requires the presence of a ".env" file in the directory. If you need to ping servers, simply rename "example.env" to ".env" and correct the server addresses.

If you plan to use netcat as a static web server, then it is better to run it in a Docker container, setting memory and processor limits.