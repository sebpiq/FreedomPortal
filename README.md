FreedomPortal
==============

The FreedomPortal project is an exhibition of digital artworks installed on Wi-Fi routers spread out in the public space.

These instructions explain how to deploy some static web pages on a Wi-Fi router, so that it act as a captive portal for all clients connecting.

In order to use these instructions, You need a Wi-Fi router:

- able to support OpenWrt (https://openwrt.org/)
- with a USB port so you can plug a USB key to extend the router's disk space
- with enough flash memory (I am unsure of the exact amount of memory necessary)

We have been using GL-inet routers, which have all of the above, and come with OpenWrt pre-installed. Instructions are for these specific routers, but can be easily adapted to another model.


Creating a FreedomPortal app
==============================


Deploying on a Wi-Fi router
==============================


Preparing USB key
--------------------

Format a USB key as FAT, and call the new volume `PORTALKEY`.

Download latest FreedomPortal code from [here](https://github.com/sebpiq/FreedomPortal/archive/master.zip), unzip and rename the folder to `FreedomPortal`, then copy to the USB key. 

Copy also your html pages in a folder called `www`. 

Create an empty `log` folder. 

You USB key should now have the following structure :

```
FreedomPortal/
log/
www/
    index.html
    css/
    ...
```

Eject USB key from your computer and insert into the router.


Initialize router password, connect through SSH
------------------------------------------------

On first connection on GL-inet routers, go to the router's web interface [192.168.8.1](http://192.168.8.1) to set a password.

Use that password to connect through SSH. Open your terminal and run the following command :

```
ssh root@192.168.8.1
```

After successfully connecting, an SSH console will be open. All the following commands will be ran inside that SSH console.


Cleaning unused packages 
----------------------------

First, let's disable the default router's web server so it won't be started at next boot. Run :

```
/etc/init.d/uhttpd disable
```

To make some space, let's remove some unused packages. Run the following :

NB: the first and second commands might need to run twice, because packages we are trying to remove depend upon each other. 

```
opkg remove gl-inet luci luci-base luci-*
opkg remove gl-inet luci luci-base luci-*
opkg remove uhttpd-* uhttpd
opkg remove kmod-video*
opkg remove kmod-video*
opkg remove mjpg-streamer
rm -rf /www/*
```


Installing requirements
--------------------------

For this step, the router needs Internet access. You can for example connect its `wan` port to one free `lan` port on your home router.

Copy FreedomPortal code from the USB stick and onto the router :

```
cp -r /mnt/PORTALKEY/FreedomPortal/ .
```

Then to install the packages we need, first update repo with :

```
opkg update
```

Then install the required packages with the following command : 

```
opkg install lighttpd lighttpd-mod-alias lighttpd-mod-rewrite lighttpd-mod-redirect lighttpd-mod-cgi lua lua-coxpcall lua-wsapi-base luaposix
```


Initialize and start FreedomPortal on boot
-------------------------------------------

Copy the script for the startup script in `/etc/init.d` folder : 

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