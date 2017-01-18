#!/bin/sh
# This script starts the lua script refreshing clients in openwrt,
# and restarts it if it crashed.

while true
do
  lua /root/FreedomPortal/scripts/refresh_clients.lua >> /mnt/PORTALKEY/log/refresh_clients.log 2>&1
  sleep 1
done