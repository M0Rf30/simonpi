#!/usr/bin/env bash

arch_sdcard_img="${STORAGE}/sd-arch-${args[model]}-qemu.img"
istatus="$(img_status)"
pstatus="$(partition_status)"
boot_path="${STORAGE}/${args[model]}/boot"
root_path="${STORAGE}/${args[model]}/root"

if [[ ${istatus} == "0" ]] && [[ ${pstatus} == "0" ]]; then
  echo -e "[$(yellow_bold " WARN ")] ${arch_sdcard_img##*/} disk image not mounted"
elif [[ ${istatus} == "1" ]] && [[ ${pstatus} == "0" ]]; then
  check_root
  umount_img
elif [[ ${pstatus} == "1" ]]; then
  check_root
  umount_partitions "${arch_sdcard_img}" "${boot_path}" "${root_path}"
  umount_img
else
  exit 1
fi
