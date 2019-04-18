
# On RouterOS

# Export and get license
/system license output
/file print
/file edit 2 value=name=contents
# or download from browser http://192.168.88.1/webfig/#Files


/system routerboard settings set boot-device=try-ethernet-once-then-nand
/system routerboard settings set boot-protocol=dhcp
/system reboot
# Mikrotik will PXE boot and turn its LAN ports (NOT POE PORT) into a bridge with 192.168.1.1/24

# On OpenWRT
mtd erase /dev/mtd5
mtd erase /dev/mtd6
mkdir /mnt/kernel
mkdir /mnt/rootfs
mount /dev/mtdblock5 /mnt/kernel
mount /dev/mtdblock6 /mnt/rootfs

cd /tmp
wget https://www.dropbox.com/s/r7rhhes3rbwy5h9/openwrt-ar71xx-mikrotik-DefaultNoWifi-rootfs.tar.gz /tmp
wget https://www.dropbox.com/s/a10wev2tk08wodu/openwrt-ar71xx-mikrotik-vmlinux-lzma.elf /tmp

mv /tmp/openwrt-ar71xx-mikrotik-vmlinux-lzma.elf /mnt/kernel/kernel
chmod +x /mnt/kernel/kernel
umount /mnt/kernel
cd /mnt/rootfs
tar -xvzf /tmp/openwrt-ar71xx-mikrotik-DefaultNoWifi-rootfs.tar.gz
cd /
sync
umount /mnt/rootfs
sync




