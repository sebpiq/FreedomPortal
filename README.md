FreedomPortal
==============

The Freedom Portal project is an exhibition of digital artworks installed on Wi-Fi routers spread out in the public space.

These instructions explain how to setup a wifi router and :

    install a Python server (see bootstrap code there better instructions and example on how to use this will come).
    have the Python server start automatically on boot of the router, and restart if it crashed.
    Setup DNS and firewall so that all requests will redirect to that Python server.

In order to use these instructions, You need a Wi-Fi router:

    able to support openWRT (https://openwrt.org/)
    with a USB port so you can plug a USB key to extend the router's disk space
    with enough flash memory (I am unsure of the exact amount of memory necessary, but probably 8Mb or more)

We have been using GL-inet routers, which have all of the above, and come with openWRT pre-installed.


Config
========

Prepare USB key
-------------------

Format USB key, create a single partition **ext4** called **PORTALKEY** (to match the configurations in `scripts/`). The reason we need ext4, is that we need to be able to create symlinks.

Copy the source code of the web server on the usb stick as well, under `PortalApp/`.

Create a `site-packages/` directory for Python dependencies of the menu game

Create a `log/` directory for supervisord logs.


Prepare the router
--------------------

### Initialize password, connect through SSH

On first connection, go to the router's web interface to set a password which will be used to connect through SSH.

Use that password to connect through SSH.


### Deactivate default web server

We need to stop the default web server, and disable it so it won't be started at next boot.

```
/etc/init.d/uhttpd stop
/etc/init.d/lighttpd stop
/etc/init.d/uhttpd disable
/etc/init.d/lighttpd disable
```


### Install / remove packages 

For this step, the router needs Internet access.

To make some space, we will remove some unused packages. Run the following :

NB: the first and second commands might need to be ran twice, because packages we are trying to remove depend upon each other. 

```
opkg remove gl-inet luci luci-base luci-* lua lighttpd-* lighttpd
opkg remove gl-inet luci luci-base luci-* lua lighttpd-* lighttpd
opkg remove kmod-video*
opkg remove kmod-video*
opkg remove mjpg-streamer
rm -rf /usr/lib/lua
rm -rf /usr/lib/lighttpd/
rm -rf /www/*
```

Then to install the packages we need, first update repo with :

```
opkg update
```

Then install `nodejs` : 

```
opkg install nodejs 
```

Deploy Python server
----------------------

### Install Python dependencies

From the menu game folder, install dependencies with :

```
pip install --target=/mnt/PORTALKEY/site-packages -r requirements.txt
```


### Setup supervisord on boot 

Install python-supervisor with :

```
pip install supervisor
```

Copy the script for starting the portal app on startup : 

```
cp scripts/portalapp-init.d /etc/init.d/portalapp
```

make it executable : 

```
chmod +x /etc/init.d/portalapp
```

Activate at next boot by running 

```
/etc/init.d/portalapp enable
```

You can test that everything works by launching the server with 

```
/etc/init.d/portalapp start
```

Redirect all requests to the Python app
-----------------------------------------

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


Checklist testing
====================

- try to put an https address in address bar
- try to put IP address in address bar
- try to put non-https url


Checklist works
==================

```
<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>192.168.0.1:Where the WiFi comes from</title>
```

Title 32 characters max (because of SSID).


TODO
=====

- captive portal for iOS