opkg update
opkg install usbutils kmod-usb-storage
opkg install block-mount kmod-fs-ext4
opkg install wget tar ca-certificates
mkdir /mnt/storage

uci set fstab.automount=global
uci set fstab.automount.from_fstab='1'
uci set fstab.automount.anon_mount='1'
uci set fstab.autoswap=global
uci set fstab.autoswap.from_fstab='1'
uci set fstab.autoswap.anon_swap='0'
uci set fstab.@mount[0]=mount
uci set fstab.@mount[0].target='/mnt/storage'
uci set fstab.@mount[0].device='/dev/sda1'
uci set fstab.@mount[0].enabled='1'
uci set fstab.@mount[0].enabled_fsck='0'
uci commit fstab

/etc/init.d/fstab enable
/sbin/block mount

cd /mnt/storage
mkdir tftp tftp/pxelinux.cfg tftp/disks tftp/disks/ubuntu1310-64
mkdir /mnt/storage/syslinux-download
cd /mnt/storage/syslinux-download
wget https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xf syslinux-6.03.tar.gz
cd /mnt/storage/syslinux-download/syslinux-6.03/bios
cp core/pxelinux.0 /mnt/storage/tftp
cp com32/elflink/ldlinux/ldlinux.c32 /mnt/storage/tftp
cp com32/menu/vesamenu.c32 /mnt/storage/tftp
cp com32/lib/libcom32.c32 /mnt/storage/tftp
cp com32/menu/menu.c32 /mnt/storage/tftp
cp com32/libutil/libutil.c32 /mnt/storage/tftp

#vim /mnt/storage/tftp/pxelinux.cfg/default
#DEFAULT vesamenu.c32
#PROMPT 0
#MENU TITLE OpenWRT PXE-Boot Menu

#label Ubuntu
#        MENU LABEL Ubuntu Live 13.10 64-Bit
#        KERNEL disks/ubuntu/casper/vmlinuz.efi
#        APPEND boot=casper ide=nodma netboot=nfs nfsroot=192.168.150.254:/mnt/storage/tftp/disks/ubuntu1310-64/ initrd=disks/ubuntu/casper/initrd.lz
#        TEXT HELP
#                Starts the Ubuntu Live-CD - Version 13.10 64-Bit
#        ENDTEXT
ipaddress=$(uci get network.lan.ipaddr)
uci set dhcp.@dnsmasq[0].enable_tftp='1'
uci set dhcp.@dnsmasq[0].tftp_root='/mnt/storage/tftp'
uci set dhcp.linux=boot
uci set dhcp.linux.filename='mikrotikcc.elf'
uci set dhcp.linux.serveraddress=$ipaddress
uci set dhcp.linux.servername='OpenWRT'
uci commit dhcp

uci set uhttpd.secondary=uhttpd
uci set uhttpd.secondary.listen_http='0.0.0.0:8080' '[::]:8080'
uci set uhttpd.secondary.listen_https='0.0.0.0:443' '[::]:443'
uci set uhttpd.secondary.home='/mnt/storage/firmwares'

cd /mnt/storage/tftp
wget https://www.dropbox.com/s/8amhpcesd2l3qns/openwrt-ar71xx-mikrotik-vmlinux-initramfs.elf /mnt/storage/tftp
mv /mnt/storage/tftp/openwrt-ar71xx-mikrotik-vmlinux-initramfs.elf /mnt/storage/tftp/mikrotikcc.elf
/etc/init.d/network reload
/etc/init.d/dnsmasq restart
