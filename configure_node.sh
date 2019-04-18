#!/bin/ash
export hostname='CAM4_A'
export estudio_ip='10.100.176.43'
export estudio_netmask='255.255.255.0'
export estudio_gateway='10.100.176.1'
export estudio_ssid='GCam'
export estudio_passwd='mobilidade@123'
export camera_ssid='DIRECT-iHF0:PMW-F55_010131'
export camera_passwd='wLrwUMy'


# Update and install openwrt packages
opkg update
opkg install nginx snmpd

cd /tmp
wget https://www.dropbox.com/s/2xlnj5m721bsvzs/on.cgi /tmp/on.cgi
wget https://www.dropbox.com/s/zfkiwdrx0aad78l/reset.cgi /tmp/reset.cgi
wget https://www.dropbox.com/s/vkkdoy14wfx94i5/back.cgi /tmp/back.cgi
wget https://www.dropbox.com/s/wen0nekmfv0ps7h/index.html /tmp/index.html
wget https://www.dropbox.com/s/6a1nvcgxz5fe5m4/nginx.conf /tmp/nginx.conf

mkdir -p /www/alterassid/cgi-bin
mv /tmp/on.cgi /www/alterassid/cgi-bin
mv /tmp/reset.cgi /www/alterassid/cgi-bin
mv /tmp/back.cgi /www/alterassid/cgi-bin
mv /tmp/index.html /www/alterassid
mv /tmp/nginx.conf /etc/nginx

cd /www/alterassid/cgi-bin
chmod +x *

# System configuration
uci set system.@system[0].hostname=$hostname
uci set system.@system[0].timezone=BRT3BRST,M10.3.0/0,M2.3.0/0
uci set system.@system[0].zonename='America/Sao Paulo'
uci commit system
/etc/init.d/system reload

# Network configuration
uci set network.lan.type='bridge'
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.1.254'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.hostname=$hostname
uci set network.wan.hostname=$hostname
uci set network.estudio=interface
uci set network.estudio.proto='static'
uci set network.estudio.ipaddr=$estudio_ip
uci set network.estudio.netmask=$estudio_netmask
uci set network.estudio.gateway=$estudio_gateway
uci set network.estudio.ipv6=0
uci set network.camera=interface
uci set network.camera.proto='static'
uci set network.camera.ipaddr='10.0.0.2'
uci set network.camera.netmask='255.255.0.0'
uci commit network
/etc/init.d/network reload

# Firewall configuration
uci set firewall.openssh_server=rule
uci set firewall.openssh_server.name='ssh_from_estudio'
uci set firewall.openssh_server.src='estudio'
uci set firewall.openssh_server.target='ACCEPT'
uci set firewall.openssh_server.proto='tcp'
uci set firewall.openssh_server.dest_port='22'
uci set firewall.luci=rule
uci set firewall.luci.name='luci_from_estudio'
uci set firewall.luci.src='estudio'
uci set firewall.luci.target='ACCEPT'
uci set firewall.luci.proto='tcp'
uci set firewall.luci.dest_port='8880'
uci set firewall.alterassid=rule
uci set firewall.alterassid.name='alterassid_from_estudio'
uci set firewall.alterassid.src='estudio'
uci set firewall.alterassid.target='ACCEPT'
uci set firewall.alterassid.proto='tcp'
uci set firewall.alterassid.dest_port='8080'
uci set firewall.snmp=rule
uci set firewall.snmp.name='snmp_from_estudio'
uci set firewall.snmp.src='estudio'
uci set firewall.snmp.target='ACCEPT'
uci set firewall.snmp.proto='udp'
uci set firewall.snmp.dest_port='161'
uci add firewall zone
uci set firewall.@zone[2]=zone
uci set firewall.@zone[2].name='estudio'
uci set firewall.@zone[2].network='estudio'
uci set firewall.@zone[2].input='ACCEPT'
uci set firewall.@zone[2].output='ACCEPT'
uci set firewall.@zone[2].forward='REJECT'
uci add firewall zone
uci set firewall.@zone[3]=zone
uci set firewall.@zone[3].name='camera'
uci set firewall.@zone[3].network='camera'
uci set firewall.@zone[3].input='ACCEPT'
uci set firewall.@zone[3].output='ACCEPT'
uci set firewall.@zone[3].forward='REJECT'
uci add firewall forwarding
uci set firewall.@forwarding[1]=forwarding
uci set firewall.@forwarding[1].src='estudio'
uci set firewall.@forwarding[1].dest='camera'
uci add firewall forwarding
uci set firewall.@forwarding[2]=forwarding
uci set firewall.@forwarding[2].src='lan'
uci set firewall.@forwarding[2].dest='camera'
uci commit firewall
/etc/init.d/firewall reload

# Configure DNS / DHCP
uci set dhcp.@dnsmasq[0].localservice='0'
uci set dhcp.lan=dhcp
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcp_option='6,192.168.1.254,8.8.8.8'
uci set dhcp.lan.ignore='0'
uci set dhcp.camera=dhcp
uci set dhcp.camera.ignore='1'
uci set dhcp.estudio=dhcp
uci set dhcp.estudio.ignore='1'
uci commit dhcp
/etc/init.d/network reload
/etc/init.d/dnsmasq restart

# Wireless config
rm /etc/config/wireless
wifi detect >> /etc/config/wireless
uci commit wireless
wifi config
uci set wireless.radio0.channel='auto'
uci set wireless.radio0.disabled='0'
uci set wireless.radio1.channel='auto'
uci set wireless.radio1.disabled='0'
uci set wireless.@wifi-iface[0]=wifi-iface
uci set wireless.@wifi-iface[0].device='radio0'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].mode='sta'
uci set wireless.@wifi-iface[0].ssid=$camera_ssid
uci set wireless.@wifi-iface[0].key=$camera_passwd
uci set wireless.@wifi-iface[0].network='camera'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[1]=wifi-iface
uci set wireless.@wifi-iface[1].device='radio1'
uci set wireless.@wifi-iface[1].mode='sta'
uci set wireless.@wifi-iface[1].ssid=$estudio_ssid
uci set wireless.@wifi-iface[1].encryption='psk2'
uci set wireless.@wifi-iface[1].key=$estudio_passwd
uci set wireless.@wifi-iface[1].network='estudio'
uci set wireless.@wifi-iface[1].disabled='0'
uci commit wireless
wifi

# Web server config
uci set uhttpd.main=uhttpd
uci set uhttpd.main.listen_http='0.0.0.0:8880'
uci set uhttpd.main.listen_https='0.0.0.0:443'
uci set uhttpd.main.redirect_https='1'
uci set uhttpd.main.home='/www'
uci set uhttpd.main.rfc1918_filter='1'
uci set uhttpd.main.max_requests='3'
uci set uhttpd.main.max_connections='100'
uci set uhttpd.main.cert='/etc/uhttpd.crt'
uci set uhttpd.main.key='/etc/uhttpd.key'
uci set uhttpd.main.cgi_prefix='/cgi-bin'
uci set uhttpd.main.script_timeout='60'
uci set uhttpd.main.network_timeout='30'
uci set uhttpd.main.http_keepalive='20'
uci set uhttpd.main.tcp_keepalive='1'
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.secondary=uhttpd
uci set uhttpd.secondary.listen_http='0.0.0.0:8080'
uci set uhttpd.secondary.home='/www/alterassid'
uci set uhttpd.secondary.script_timeout='60'
uci set uhttpd.secondary.network_timeout='30'
uci commit uhttpd
/etc/init.d/uhttpd restart

reboot
