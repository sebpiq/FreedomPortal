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

App structure
---------------

In its simplest form, i.e. if you only want to serve static html and assets, a FreedomPortal app is a node.js app with the following structure :

```
my-app/
    config.js
    package.json
    www/
        assets/
            css/
                styles.css
            js/
                app.js
        index.html
        pageA.html
        pageB.html
```

- **config.js** : config for the FreedomPortal app.
- **package.json** : config for node.js.
- **www** : folder containing your html, css and other assets. 


Getting started
-----------------

First, you must have node.js and npm installed on your system.

Then, with your terminal create a folder and inside that folder initialize the node app :

```
mkdir my-app
cd my-app
npm init
```

Once this is done, install the FreedomPortal library : 

```
npm install --save freedom-portal
```

Finally create a config file for your FreedomPortal app. You can find an example [there](https://github.com/sebpiq/FreedomPortal/tree/master/bin/config-example.js).

Then, you can try that everything works by starting the app :

```
node ./node_modules/freedom-portal/bin/main.js /absolute/path/to/config.js
```

Go to [http://localhost/](http://localhost/) with your browser, check that your html pages and assets are served correctly.


Deploying on a Wi-Fi router
==============================

Prepare USB key
-------------------

Format a USB key, create a single partition **ext4** called **PORTALKEY** (to match the configurations in `scripts/`). The reason we need ext4, is that we need to be able to create symlinks.

Copy the source code of your FreedomPortal app on the usb stick under `PortalApp/`.

Create a `log/` directory for log files.


Initialize router password, connect through SSH
------------------------------------------------

On first connection on GL-inet routers, go to the router's web interface [192.168.8.1](http://192.168.8.1) to set a password which will be used to connect through SSH.

Use that password to connect through SSH `ssh root@192.168.8.1` .


Deactivate router's web server
--------------------------------

We need to stop the default router's web server, and disable it so it won't be started at next boot.

```
/etc/init.d/uhttpd stop
/etc/init.d/lighttpd stop
/etc/init.d/uhttpd disable
/etc/init.d/lighttpd disable
```


Install / remove packages 
----------------------------

For this step, the router needs Internet access.

To make some space, we will remove some unused packages. Run the following :

NB: the first and second commands might need to run twice, because packages we are trying to remove depend upon each other. 

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

Start the app on boot
------------------------

Copy the script for starting the portal app on startup : 

```
cp /mnt/PORTALKEY/PortalApp/node_modules/freedom-portal/scripts/portalapp-init.d /etc/init.d/portalapp
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
