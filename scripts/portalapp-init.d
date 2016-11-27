#!/bin/sh /etc/rc.common
# Python Portal App
# Copyright (C) 2007 OpenWrt.org
 
START=99
STOP=1
 
start() {        
  node /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/node_modules/forever/bin/forever start \
    -o /mnt/PORTALKEY/log/PortalApp.log -e /mnt/PORTALKEY/log/PortalApp.err.log -a\
    /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/bin/main.js \
    /mnt/PORTALKEY/PortalApp/config.js
}
 
stop() {
  node /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/node_modules/forever/bin/forever stopall
}