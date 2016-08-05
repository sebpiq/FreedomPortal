#!/bin/sh /etc/rc.common
# Python MenuGame
# Copyright (C) 2007 OpenWrt.org
 
START=99
STOP=1
 
start() {        
        supervisord -c /mnt/PORTALKEY/PortalApp/scripts/supervisord.conf
}                 
 
stop() {          
        echo stop
        # commands to kill application 
}
