#!/bin/bash
function error_exit(){
	echo "$1" 1>&2
	exit 1
}

# Update ubuntu
function update_Ubuntu(){
        TODAY=$(date +%s)
        UPDATE_TIME=$(date +%s -r /var/cache/apt/pkgcache.bin)
        DELTA_TIME="$(echo "$TODAY - $UPDATE_TIME" | bc)"
        if [ "$DELTA_TIME" -ge 100000 ]; then
                sudo apt -y update
                sudo apt -y upgrade
        fi
}

# Install prereqs
function install_Prerequisites(){
	sudo apt install -y autoconf bison build-essential ccache file flex \
	g++ git gawk gettext git-core libncurses5-dev libnl-3-200 libnl-3-dev \
	libnl-genl-3-200 libnl-genl-3-dev libssl-dev ncurses-term python \
	quilt sharutils subversion texinfo unzip wget xsltproc zlib1g-dev bc
	sudo apt-get -y autoremove
}

function download_OpenWRT_source(){
	cd "$install_dir"  || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git clone git://git.archive.openwrt.org/15.05/openwrt.git # Chaos Calmer
}

function install_Feeds(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	git pull
	# update and install feeds
	./scripts/feeds update -a
	./scripts/feeds install -a
}

function downloadNodesTemplateConfigs(){
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git pull
}

function config_OpenWRT(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	cp -f "$install_dir"/"$devicetype"/diffconfig .config
	make defconfig
}

function substituteVariables(){
	cd "$build_dir"/files || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	find . -type f -print0 | while IFS= read -r -d $'\0' files
	do
		sed -i "s/\$radio0_channel/${radio_camera_channel}/g" "$files"
		sed -i "s/\$radio1_channel/${radio_estudio_channel}/g" "$files"
		sed -i "s/\$hostname/${hostname}/g" "$files"
		sed -i "s/\$camera_ssid/${camera_ssid[$hostname]}/g" "$files"
		sed -i "s/\$camera_wpa2key/${camera_wpa2key[$hostname]}/g" "$files"
		sed -i "s/\$estudio_ssid/${estudio_ssid}/g" "$files"
		sed -i "s/\$estudio_user/${estudio_user}/g" "$files"
		sed -i "s/\$estudio_passwd/${estudio_passwd}/g" "$files"
		sed -i "s/\$lan_ip/${net_config[lan_ip]}/g" "$files"
		sed -i "s/\$lan_netmask/${net_config[lan_netmask]}/g" "$files"
		sed -i "s/\$wan_protocol/'${wan_protocol}'/g" "$files"
		sed -i "s/\$estudio_ip/${estudio_ip[$hostname]}/g" "$files"
		sed -i "s/\$estudio_netmask/${net_config[estudio_netmask]}/g" "$files"
		sed -i "s/\$estudio_gateway/${net_config[estudio_gateway]}/g" "$files"
		sed -i "s/\$estudio_protocol/${net_config[estudio_protocol]}/g" "$files"
		sed -i "s/\$domain/${net_config[domain]}/g" "$files"
		sed -i "s/\$external_dns_ip/${net_config[external_dns_ip]}/g" "$files"
		sed -i "s/\$syscontact/${syscontact}/g" "$files"
		sed -i "s/\$syslocation/${syslocation}/g" "$files"
		sed -i "s/\$camera_ip/${net_config[camera_ip]}/g" "$files"
		sed -i "s/\$camera_netmask/${net_config[camera_netmask]}/g" "$files"
		sed -i "s/\$camera_iface_ip/${net_config[camera_iface_ip]}/g" "$files"
	done
}

function createConfigFilesNode(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	rm -rf files
	mkdir files
	mkdir files/etc
	mkdir files/etc/config
	mkdir files/etc/nginx
    mkdir files/www/alterassid/cgi-bin
	cd "$build_dir"/files/etc/config || error_exit "OpenWRT config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"$devicetype"/dhcp .
	cp -f "$install_dir"/"$devicetype"/firewall .
	cp -f "$install_dir"/"$devicetype"/wireless .
	cp -f "$install_dir"/"$devicetype"/snmpd .
	cp -f "$install_dir"/"$devicetype"/system .
	cp -f "$install_dir"/"$devicetype"/uhttpd .
	if [ "${net_config[estudio_protocol]}" == "dhcp" ]; then
		cp -f "$install_dir"/"$devicetype"/network_wwan_dhcp network
	fi
	if [ "${net_config[estudio_protocol]}" == "static" ]; then
		cp -f "$install_dir"/"$devicetype"/network_wwan_static network
	fi
	cd "$build_dir"/files/etc || error_exit "OpenWRT config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"$devicetype"/resolv.conf .
	cp -f "$install_dir"/"$devicetype"/rc.local .
	cp -f "$install_dir"/"$devicetype"/passwd .
	cp -f "$install_dir"/"$devicetype"/shadow .
	cd "$build_dir"/files/etc/nginx || error_exit "OpenWRT config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"$devicetype"/nginx.conf .
    cd "$build_dir"/files/www/alterassid/cgi-bin || error_exit "OpenWRT config directory cannot be found, please check write permissions on this directory"
    cp -f "$install_dir"/"$devicetype"/back.cgi .
    cp -f "$install_dir"/"$devicetype"/on.cgi .
    cp -f "$install_dir"/"$devicetype"/reset.cgi .
    cd "$build_dir"/files/www/alterassid || error_exit "OpenWRT config directory cannot be found, please check write permissions on this directory"
    cp -f "$install_dir"/"$devicetype"/index.html .
	substituteVariables
}

function compile_Image(){
	# Compile from source
	rm "$build_dir"/bin/"${target[$devicetype]}"/"$rootfs_file"
	rm "$build_dir"/bin/"${target[$devicetype]}"/"$kernel_file"
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	make -j"${nproc}" V=s
}

function check_Firmware_compile(){
        # CHECK SHA256 OF COMPILED IMAGE
        export build_successfull='0'
        export checksum_OK='0'
        echo "$build_dir"/bin/"${target[$devicetype]}"/"$rootfs_file"
        echo "$build_dir"/bin/"${target[$devicetype]}"/"$kernel_file"
        cd "$build_dir"/bin/"${target[$devicetype]}" || error_exit "firmware not found, check available disk space"
        if [ -f "$rootfs_file" ] && [ -f "$kernel_file" ]; then
                echo "Compilation Successfull"
                export build_successfull='1'
        else
                error_exit "Errors found during compilation, firmware not found, check build log on screen for errors"
        fi
        if [ $build_successfull -eq '1' ]; then
		echo "$rootfs_file"
                if grep "$rootfs_file" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "rootfs OK"
                else
                        error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
                fi
		echo "$kernel_file"
                if grep "$kernel_file" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "Checksum OK"
                        export checksum_OK='1'
		else
			error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
                fi
        fi
}

function copy_Firmware_compile(){
	cd "$build_dir"/bin/"${target[$devicetype]}" || error_exit "firmware not found, check available disk space"
	if [[ $build_successfull -eq '1' && $checksum_OK -eq '1' ]]; then
		cp "$rootfs_file" "$install_dir"/firmwares/"$hostname"_rootfs.tar.gz
		rm "$rootfs_file"
		cp "$kernel_file" "$install_dir"/firmwares/"$hostname"_kernel.bin
		rm "$kernel_file"
	else
		error_exit "Problems found trying to deliver firmware to output directory, check available disk space"
	fi
}

