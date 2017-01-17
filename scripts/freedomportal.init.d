#!/bin/sh /etc/rc.common
# FreedomPortal openwrt initialize

START=99
STOP=1

start() {
  sleep 1
  /root/FreedomPortal/scripts/freedomportal.sh &
}

stop() {
  echo "stop"
}