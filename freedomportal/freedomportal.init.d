#!/bin/sh /etc/rc.common
# FreedomPortal openwrt initialize

# We start just before lighttpd so we can initialize things
START=49
STOP=1

start() {
  # Copy lighttpd conf file to its location
  cp {{{ config.configured_dir }}}/lighttpd.conf /etc/lighttpd/
  sleep 1
}

stop() {
  echo "stop"
}
