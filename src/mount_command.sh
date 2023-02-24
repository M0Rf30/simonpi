#!/usr/bin/env bash

arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"
istatus="$(img_status)"
pstatus="$(partition_status)"
device1=$(sudo -E losetup -f)
device2=/dev/loop$((${device1##*/loop} + 1))
boot_path="${STORAGE}/${args[model]}/boot"
root_path="${STORAGE}/${args[model]}/root"

if [[ ${istatus} == "0" ]] && [[ ${pstatus} == "0" ]]; then
	check_root
	check_loop_devices "${device2}"
	mount_img "${arch_sdcard_img}" "${device1}" "${device2}"
	check_fs "${device1}" "${device2}"
	check_storage
	mount_partitions "${arch_sdcard_img}" "${device1}" "${device2}" "${boot_path}" "${root_path}"
elif [[ ${istatus} == "1" ]] && [[ ${pstatus} == "0" ]]; then
	check_root
	check_loop_devices "${device2}"
	check_fs "${device1}" "${device2}"
	check_storage
	mount_partitions "${arch_sdcard_img}" "${device1}" "${device2}" "${boot_path}" "${root_path}"
elif [[ ${pstatus} == "1" ]]; then
	return
else
	exit 1
fi
