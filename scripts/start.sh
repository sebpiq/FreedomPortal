#!/bin/sh

while true
do
  node /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/bin/main.js /mnt/PORTALKEY/PortalApp/config.js >> /mnt/PORTALKEY/log/PortalApp.log 2>&1
  sleep 1
done
