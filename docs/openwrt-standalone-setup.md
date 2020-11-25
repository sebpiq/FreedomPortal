Setup on a self-contained OpenWrt router
==========================================

This setup embeds the captive portal (including pages, and other assets) on an OpenWrt Wi-Fi router, without depending on any other device.

**PREREQUISITES**

- **Wi-Fi router** :

    - able to support OpenWrt (https://openwrt.org/)
    - with a USB port so you can plug a USB key to extend the router's disk space
    - with enough flash memory (I am unsure of the exact amount of memory necessary)

    We have been using `GL-AR150` routers, which have all of the above, and come with OpenWrt pre-installed. Instructions are for these specific routers, but can be easily adapted to another model or another brand.

- **Internet access to your router** : in order to install dependencies, the router will need Internet access. You can for example connect its wan port to one free lan port on your home router/modem.


Getting the code and creating a configuration file
------------------------------------------------------

Download latest FreedomPortal code from [here](https://github.com/sebpiq/FreedomPortal/archive/master.zip), unzip and rename the folder to `FreedomPortal`.

Copy the file `parameters.lua.template`, name the copy `parameters.lua`.

You can optionally edit `parameters.lua` to customize your installation, but I recommend you try out the default settings first.


Preparing USB key
--------------------

Format a USB key as FAT, and call the new volume `PORTALKEY`.

Copy the `FreedomPortal` folder you downloaded before to the USB key.

Copy also your html pages in a folder called `www`. If you don't have html pages yet and just want to test out the system, you can copy the contents of `example/` under `www/` on your USB key.

You USB key should now have the following structure :

```
FreedomPortal/
    parameters.lua
    src/
    ...
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

**ATTENTION**: the instructions and configuration files are designed for GL-inet firmware version **2.25** and above. If you have an older firmware version you should upgrade it using the router's web interface, **firmware** menu. You will need an Internet connection for that.


Install FreedomPortal on the router
-------------------------------------

You are now ready to run the installation process. Navigate to the `FreedomPortal/` folder on your USB key by running the command :

```
cd /mnt/PORTALKEY/FreedomPortal
```

Once inside the folder, run the following command :

```
lua configure.lua parameters
```

Then, finalize the installation by running :

```
chmod a+x /root/FreedomPortal_configured/install.sh
/root/FreedomPortal_configured/install.sh
```

You can now reboot your router by running :

```
reboot 0
```

After the router has rebooted successfully, the captive portal should be active.