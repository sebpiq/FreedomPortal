#!/bin/sh /etc/rc.common
# FreedomPortal openwrt initialize

# We start just before lighttpd so we can initialize things
START=49
STOP=1

start() {
  # Copy lighttpd conf file to its location,
  # Substitute with the right version number, 
  # otherwise the lighttpd startup script will override it. 
  cp /root/FreedomPortal/scripts/lighttpd.conf /etc/lighttpd/
  sed -i -- "s/{{VERSION}}/$(cat /etc/glversion)/g" /etc/lighttpd/lighttpd.conf
  sleep 1
  /root/FreedomPortal/scripts/refresh_clients.sh &
}

stop() {
  echo "stop"
}