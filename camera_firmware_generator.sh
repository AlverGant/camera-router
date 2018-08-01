#!/bin/bash

# Retrieve current directory
install_dir=$(pwd)

# Read configurations
echo "Reading router configs...." >&2
. camera_configs.cfg

# Read functions
echo "Reading router functions...." >&2
. camera_functions.sh

# create directory for firmwares output
if [ -d "$install_dir"/firmwares ]; then
	cd "$install_dir"/firmwares && rm ./*.bin
	cd "$install_dir"/firmwares && rm ./*.tar.gz
else
	mkdir "$install_dir"/firmwares
fi

# FIRMWARE GENERATION PROCESS 
update_Ubuntu
install_Prerequisites
download_OpenWRT_source
install_Feeds
config_OpenWRT
downloadNodesTemplateConfigs
for ((i=1; i<=numberofnodes; i++)); do
	export hostname="camera-$i"
	export syslocation="${gps_coordinates[$hostname]}"
	createConfigFilesNode
	compile_Image
	check_Firmware_compile
	copy_Firmware_compile
done
echo "Firmware files are bellow"
echo "on directory $install_dir/firmwares"
cd "$install_dir"/firmwares && ls -l ./*
