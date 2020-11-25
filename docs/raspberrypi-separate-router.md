Setup on a Raspberry Pi
==========================================

This setup installs the captive portal and DNS server on a Raspberry Pi, but relies on a separate Wi-Fi router.


Assign a static IP to your Raspberry Pi
-----------------------------------------

Connect to the admin interface of your router and assign static IP to raspberry Pi, for example `192.168.1.123`.


Install the DNS server on the Raspberry Pi
--------------------------------------------

Connect to the Raspberry Pi, update the packages, upgrade and install `dnsmasq` :

```
sudo apt update
sudo apt upgrade
sudo apt install dnsmasq
```

Update the default `dnsmasq` config file, open with :

```
sudo nano /etc/dnsmasq.conf
```

Uncomment `no-resolv`, Add `address=/#/192.168.1.123` (replace the IP with the desired IP).

```
sudo /etc/init.d/dnsmasq restart
```

Getting the code and creating a configuration file
------------------------------------------------------

Download latest FreedomPortal code from [here](https://github.com/sebpiq/FreedomPortal/archive/master.zip), unzip and rename the folder to `FreedomPortal`.

Copy the file `parameters.lua.template`, name the copy `parameters.lua`.

You can optionally edit `parameters.lua` to customize your installation, but I recommend you try out the default settings first.


Configure DNS server of your Wi-Fi network
---------------------------------------------

Connect to the admin interface of your router and change the DNS settings to point to the raspberry Pi as a DNS server. Following our example, this should be the IP `192.168.1.123`.


Troubleshooting
------------------

- If dnsmasq fails because some process is already connected to the port 53, you can check which process is the culprit with the command : 

```
sudo lsof -i :53
```

- To test the DNS resolution, you can run from your computer's command line the following command :

```
dig @192.168.1.123 some-url-to-resolve.com
```


References
------------

- How to use your Raspberry Pi as a DNS Server (And Speed Up Internet) : https://raspberrytips.com/raspberry-pi-dns-server/