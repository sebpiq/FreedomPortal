#!/bin/sh /etc/rc.common
# Python Portal App
# Copyright (C) 2007 OpenWrt.org

START=99
STOP=1

start() {
  sleep 10
  /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/scripts/start.sh &
}

stop() {
  echo "stop"
}
