FreedomPortal
==============

The FreedomPortal project is an exhibition of digital artworks installed on Wi-Fi routers spread out in the public space.

These instructions explain how to :

- create a FreedomPortal app
- deploy that app on a Wi-Fi router, so that it act as a captive portal for all clients connecting

In order to use these instructions, You need a Wi-Fi router:

- able to support openWRT (https://openwrt.org/)
- with a USB port so you can plug a USB key to extend the router's disk space
- with enough flash memory (I am unsure of the exact amount of memory necessary, but probably 8Mb or more)

We have been using GL-inet routers, which have all of the above, and come with openWRT pre-installed. Following instructions are for these specific routers, but can be easily adapted to another model.


Creating a FreedomPortal app
==============================


Deploying on a Wi-Fi router
==============================

Format USB KEY to PORTALKEY


Copying files onto the router
------------------------------

Copy unzipped FreedomPortal code to a USB key. Copy also your html pages. Insert USB key in the router.


Initialize router password, connect through SSH
------------------------------------------------

On first connection on GL-inet routers, go to the router's web interface [192.168.8.1](http://192.168.8.1) to set a password which will be used to connect through SSH.

Use that password to connect through SSH `ssh root@192.168.8.1` .


Deactivate router's web server
--------------------------------

We need to stop the default router's web server, and disable it so it won't be started at next boot.

```
/etc/init.d/uhttpd stop
/etc/init.d/uhttpd disable
```

Copy FreedomPortal code on router
------------------------------------

```
cp -r /mnt/PORTALKEY/FreedomPortal/ .
```

mkdir /var/log/freedomportal

Install / remove packages 
----------------------------

For this step, the router needs Internet access.

To make some space, we will remove some unused packages. Run the following :

NB: the first and second commands might need to run twice, because packages we are trying to remove depend upon each other. 

```
opkg remove gl-inet luci luci-base luci-*
opkg remove gl-inet luci luci-base luci-*
opkg remove kmod-video*
opkg remove kmod-video*
opkg remove mjpg-streamer
rm -rf /www/*
```

Then to install the packages we need, first update repo with :

```
opkg update
```

Then install the required packages with the following command : 

```
opkg install lighttpd-mod-alias lighttpd-mod-rewrite lighttpd-mod-redirect lua-coxpcall lua-wsapi-base luaposix
```

Configure lighttpd
--------------------

Normally, lighttpd is already enabled on start, so we only need to modify the configuration file.

Let's first backup the default configuration file :

```
mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.bak
```

and install our own config file :

```
cp FreedomPortal/scripts/lighttpd.conf /etc/lighttpd/
```


Start the client refresh daemon on boot
----------------------------------------

Copy the script for starting the daemon on startup : 

```
cp FreedomPortal/scripts/freedomportal.init.d /etc/init.d/freedomportal
```

make scripts executable : 

```
chmod +x FreedomPortal/scripts/refresh_clients.sh
chmod +x /etc/init.d/freedomportal
```

Activate at next boot by running 

```
/etc/init.d/freedomportal enable
```


Redirect all requests to the app
------------------------------------

### Redirect DNS queries to the server's IP

Add this line to `/etc/config/dhcp`

```bash
    config dnsmasq
    ...
    list address '/#/192.168.8.1'
```


### Redirect all IP addresses to server's IP

Add this to the end of `/etc/config/firewall`

```
config redirect
        option src 'lan'
        option proto 'tcp'
        option src_ip '!192.168.8.1'
        option src_dport '80'
        option dest_ip '192.168.8.1'
        option dest_port '80'
```


Setup wireless
-----------------

in `/etc/config/wireless` change the encryption option to `none` and change the `ssid`. Max length of SSID is 32 characters!


Reboot
-------

The setup is now complete! You can reboot the router by running 

```
reboot 0
```

Checklists
=============

Testing
-----------

- try to put an https address in address bar
- try to put IP address in address bar
- try to put non-https url


HTML page basics
-------------------

```
<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>192.168.0.1:Where the WiFi comes from</title>
```

Credits
==========

This project was partly funded by The Creative Exchange, a UK Arts & Humanities Research Council Knowledge Exchange Hub for the Creative Economy (UK research council reference AH/J005150/1 Creative Exchange). [thecreativeexchange.org.uk](http://thecreativeexchange.org.uk)