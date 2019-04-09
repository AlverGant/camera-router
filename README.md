This project aims to establish connectivity between two Access Points, AP1 is a camera with a fixed IP/subnet and no gateway; AP2 represents your wireless infrastructure.
One dual band OpenWRT capable router (TP-Link WDR3600) or better, a Mikrotik RouterBoard RB433/RB433AH with two mini-pci radios is used as a "glue" between the two networks.

<pre>
+------+          +---------+          +------+
|      |          |         |          |      |
| AP 1 | ))  IP_A | OPENWRT | IP_B  (( | AP 2 |
|      |          |         |          |      |
+------+          +---------+          +------+
</pre>


The OpenWRT router has two radios, each of them configured as mode STATION to their corresponding AP.
Interface IP_A has a fixed IP configured within AP1 subnet.
Interface IP_B is set to DHCP and gets an IP address from AP2.

NGINX is installed on the OpenWRT router acting as a reverse proxy and effectively implementing a double-NAT, enabling the incoming HTTP connection to upgrade to WebSocket as our Web service app on AP1 requires and also rewriting some HTTP headers in order for AP_1 to think that the origin is in IP_A. Connections from AP2 targeting port 80 of IP_B gets forwarded to the camera web server on AP1.

In order to generate the firmware for all OpenWRT routers, one for each camera, first clone this repository and configure all relevant variables such as IP ranges, WiFi credentials, etc on camera_configs.cfg, then make camera_firmware_generator.sh executable via chmod +x and finally execute it.

Build environment was tested on a Ubuntu Server 14.04 an 18.04 64 bits, all dependencies will be downloaded by the script. 8 GB of RAM and 16GB of storage are requirements for the compilation.

Firmware will be generated via OpenWRT compilation process and when compiling for the first time it will take more than an hour.

This setup can be used to allow internet remote connections to a GoPro camera wirelessly.
