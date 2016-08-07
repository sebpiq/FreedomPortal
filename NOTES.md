These are unorganized notes about stuff for openwrt.

/etc/config/network
======================

https://wiki.openwrt.org/doc/uci/network

netifd : Network interface daemon

https://wiki.openwrt.org/doc/techref/netifd


IPv4 Routes
-------------

Static IPv4 routes can be defined on specific interfaces using route sections. As for aliases, multiple sections can be attached to an interface.

A minimal example looks like this:

config 'route' 'name_your_route'
        option 'interface' 'lan'
        option 'target' '172.16.123.0'
        option 'netmask' '255.255.255.0'
        option 'gateway' '172.16.123.100'

    lan is the logical interface name of the parent interface
    172.16.123.0 is the network address of the route
    255.255.255.0 specifies the route netmask


/etc/config/wireless
=====================

https://wiki.openwrt.org/doc/uci/wireless


/etc/config/dhcp
==================

https://wiki.openwrt.org/doc/uci/dhcp


Setup guest WLAN
==================

https://wiki.openwrt.org/doc/recipes/guest-wlan


Failsafe mode (and reset defaults)
====================================

http://wiki.villagetelco.org/OpenWrt_Failsafe_Mode_and_Flash_Recovery


Config
========

First initialize stuff through web interface
---------------------------------------------

Setup password, activate wifi

Install / remove packages
---------------------------

Remove luci web interface

```
opkg remove luci luci-mod-admin-full luci-base luci-app-firewall luci-lib-ip luci-lib-nixio luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap
```

Packages must be installed first, cause re-configuring DNS will mess-up the package manager. First update packages :

```
opkg update
```

To enable https support :

```
opkg install uhttpd-mod-tls
```

To have embedded lua :

```
opkg install uhttpd-mod-lua
```

uhttpd : HTTP server
----------------------

https://wiki.openwrt.org/doc/howto/http.uhttpd
https://wiki.openwrt.org/doc/uci/uhttpd


Redirect DNS queries to server IP
----------------------------------

Add this line to `/etc/config/dhcp`

```bash
    config dnsmasq
    ...
    list address '/#/192.168.1.1'
```

Redirect requests to IP addresses
-----------------------------------

Add this line to `/etc/firewall.user`

```
local _lan_CIDR=$(uci -q get network.lan.netmask)
local _lan_ipaddr=$(uci -q get network.lan.ipaddr)
local _x=${_lan_CIDR##*255.}
set -- 0^^^128^192^224^240^248^252^254^ $(( (${#_lan_CIDR} - ${#_x})*2 )) ${_x%%.*}
_x=${1%%$3*}
_lan_CIDR="${_lan_ipaddr%.*}.0/"$(( $2 + (${#_x}/4) ))

iptables -t nat -F prerouting_lan_rule
iptables -t nat -A prerouting_lan_rule -p tcp -j REDIRECT --to-port 80 --src $_lan_CIDR ! --dst $_lan_ipaddr
```

Restore fresh openWRT image
-----------------------------

https://wiki.openwrt.org/toh/tp-link/tl-wr841nd#tftp_recovery_via_bootloader_for_v8_v9_v10

how to install / setup tftp server on Ubuntu : http://askubuntu.com/questions/201505/how-do-i-install-and-run-a-tftp-server#202548


Cross-compiliation
--------------------

https://blog.netbeast.co/app-openwrt/
https://blog.netbeast.co/nodejs-openwrt/


Deploy lighttpd + Python
==========================

http://www.cyberciti.biz/tips/howto-lighttpd-create-self-signed-ssl-certificates.html

install Python and pip : 
```
opkg install python
opkg install python-openssl
```
install lighttpd modules : 

```
opkg install lighttpd-mod-compress
opkg install lighttpd-mod-rewrite
```

deactivate all default configs from lighttpd modules :

```
mv /etc/lighttpd/conf.d/10-rewrite.conf /etc/lighttpd/conf.d/10-rewrite.conf.inactive
...
touch /etc/lighttpd/conf.d/dummy.conf # Create an empty conf file so lighttpd doesn't complain when starting 
```

create folder for lighttpd cache : `mkdir /var/cache`

Default init.d script for lighttpd rewrites the config file at every start, so in `/etc/init.d/lighttpd` comment out the line doing this.

Fetch virtualenv from https://github.com/pypa/virtualenv/tree/master copy it unzipped on the usb stick, then create a virtualenv with `python virtualenv.py <envfolder>`

Activate virtual env `source <envfolder>/bin/activate`, install dependencies.


Deploy cherrypy
================

```
opkg install libopenssl (?)
```

Deploy virtualenv
-------------------

Fetch virtualenv from https://github.com/pypa/virtualenv/tree/master copy it unzipped on the usb stick, then create a virtualenv with `python virtualenv.py <envfolder>`

Activate virtual env `source <envfolder>/bin/activate`, install dependencies.


Setup supervisord
--------------------

Fetch source on usb stick, install with `python setup.py install` in virtualenv.

Move `scripts/menugame-init.d` to `/etc/init.d/menugame`, make it executable `chmod +x /etc/init.d/menugame`. Modify it to point to the `supervisord` in the virtualenv and the supervisord config file.

Activate at next boot by running `/etc/init.d/menugame enable`.


Start on boot
---------------

https://wiki.openwrt.org/doc/techref/initscripts

deploy cherrypy with supervisord :

http://docs.cherrypy.org/en/latest/deploy.html#control-via-supervisord