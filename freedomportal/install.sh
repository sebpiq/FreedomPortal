#! /bin/sh

######### 1) Prepare files and install packages
# Disable the default router's web server so it won't be started at next boot.
/etc/init.d/uhttpd disable

# Remove some unused packages to make space.
# NOTE : the first and second commands might need to run twice, because packages we are trying to remove depend upon each other.
opkg remove gl-inet luci luci-base luci-*
opkg remove gl-inet luci luci-base luci-*
opkg remove uhttpd-* uhttpd
opkg remove kmod-video*
opkg remove kmod-video*
opkg remove mjpg-streamer
rm -rf /www/*

# Copy FreedomPortal code from the USB stick and onto the router.
cp -r -T /mnt/PORTALKEY/FreedomPortal/ {{{ config.FreedomPortal_dir }}}

# Then install the required packages with the following command :
# NOTE : coxpcall is a dependency of `wsapi`, but shouldn't be needed in lua 5.2 anymore.
opkg update
opkg install lighttpd lighttpd-mod-alias lighttpd-mod-rewrite lighttpd-mod-redirect lighttpd-mod-cgi lua lua-coxpcall lua-wsapi-base luaposix


######### 2) Install start-up script
# Initialize and start FreedomPortal on boot
cp {{{ config.configured_dir }}}/freedomportal.init.d /etc/init.d/freedomportal

# make script executable
chmod +x /etc/init.d/freedomportal

# Activate at next boot
/etc/init.d/freedomportal enable


######### 3) Configure network settings
# Redirect DNS queries to the server's IP
uci add_list dhcp.@dnsmasq[0].address='/#/192.168.8.1'

# Redirect all IP addresses to server's IP
uci add firewall redirect
uci set firewall.@redirect[0].src='lan'
uci set firewall.@redirect[0].proto='tcp'
uci set firewall.@redirect[0].src_ip='!192.168.8.1'
uci set firewall.@redirect[0].src_dport='80'
uci set firewall.@redirect[0].dest_ip='192.168.8.1'
uci set firewall.@redirect[0].dest_port='80'

# Configure wifi, ssid, password, etc...
uci set wireless.@wifi-iface[0].ssid='{{{ config.wireless.ssid }}}'
uci set wireless.@wifi-iface[0].encryption='{{{ config.wireless.encryption }}}'
uci set wireless.@wifi-iface[0].key='{{{ config.wireless.key }}}'

# Commit all changes
uci commit
