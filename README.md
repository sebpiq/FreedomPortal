Config
========


Prepare USB key
-------------------

Format USB key, create a single partition **ext4** called **PORTALKEY** (to match the configurations in `scripts/`). The reason we need ext4, is that we need to be able to create symlinks.

Copy the source code of the web server on the usb stick as well, under `PortalApp/`.

Create a `data/` directory for the menu game.

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

```
opkg remove gl-inet luci luci-base luci-* lua lighttd-* lighttd
rm -rf /usr/lib/lua
rm -rf /usr/lib/lighttpd/
```

Then to install the packages we need, first update repo with :

```
opkg update
```

Then instal `python` : 

```
opkg install python python-openssl 
```

And install `pip` with one of these 2 alternatives :

```
opkg install python-pip
```

or

```
opkg install distribute
easy_install pip
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

Copy the script for starting the menugame on startup : 

```
cp scripts/menugame-init.d /etc/init.d/menugame
```

make it executable : 

```
chmod +x /etc/init.d/menugame
```

Activate at next boot by running `/etc/init.d/menugame enable`.


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

in `/etc/config/wireless` change the encryption option to `none` and change the `ssid`. Max length of SSID is 31 characters!