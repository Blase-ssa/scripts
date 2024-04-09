#!/usr/bin/env bash
# Script for testing HTTP requests.
# SRV_LOG - path to the log if needed;
# SRV_PORT - server port on which to listen;
# SRV_HEADER - HTTP header;
# SRV_CONTENT - Response body; 
# 
# Require: netcat tee

SRV_LOG="netcat.log"
SRV_PORT=8000
SRV_HEADER="HTTP/1.1 200 Everything Is Just Fine
Server: Apache
Content-Type: text/html; charset=UTF-8"
SRV_CONTENT="<!doctype html>
<html><body><h1>I got you!</h1></body></html>"

while true; do 
    echo -e "${SRV_HEADER}\n\n${SRV_CONTENT}\n" | nc -l $SRV_PORT -q 1 -v | tee -a $SRV_LOG
done
